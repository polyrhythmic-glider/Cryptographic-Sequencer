param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd",
    [ValidateSet("Inspect", "PatchAutostart", "PatchUiFinish")]
    [string]$Mode = "Inspect",
    [switch]$NoBackup
)

# AMXD safety rule:
# A Max for Live .amxd is an `ampf` binary container, not plain JSON. The
# current device format stores the patcher in a `ptch` chunk whose JSON starts
# at byte offset 32, after the binary header. Length-changing edits must rewrite
# only that embedded patcher JSON and then update the uint32 chunk length at
# offset 28. Do not pipe the whole .amxd file to ConvertFrom-Json, and do not
# copy a .maxpat over an .amxd.

$ErrorActionPreference = "Stop"

function Read-DeviceBytes {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Device not found: $Path"
    }

    return [System.IO.File]::ReadAllBytes($Path)
}

function Get-AsciiHeader {
    param([byte[]]$Bytes)

    $take = [Math]::Min(16, $Bytes.Length)
    $chars = for ($i = 0; $i -lt $take; $i += 1) {
        $b = $Bytes[$i]
        if ($b -ge 32 -and $b -le 126) { [char]$b } else { "." }
    }

    return -join $chars
}

function Get-DeviceJson {
    param([byte[]]$Bytes)

    # Extract only the balanced JSON patcher object after the binary AMXD
    # header. Some devices may have non-JSON suffix bytes after the patcher,
    # so parsing the whole `ptch` byte range is intentionally avoided.
    $text = [System.Text.Encoding]::UTF8.GetString($Bytes)
    $start = 32
    if ($Bytes.Length -le $start -or [char]$Bytes[$start] -ne "{") {
        throw "Embedded patcher JSON does not start at AMXD offset 32."
    }

    $depth = 0
    $inString = $false
    $escape = $false
    $end = -1
    for ($i = $start; $i -lt $text.Length; $i += 1) {
        $ch = $text[$i]

        if ($escape) {
            $escape = $false
            continue
        }

        if ($inString) {
            if ($ch -eq "\") {
                $escape = $true
            } elseif ($ch -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($ch -eq '"') {
            $inString = $true
        } elseif ($ch -eq "{") {
            $depth += 1
        } elseif ($ch -eq "}") {
            $depth -= 1
            if ($depth -eq 0) {
                $end = $i
                break
            }
        }
    }

    if ($start -lt 0 -or $end -lt $start) {
        throw "Could not find embedded JSON patcher."
    }

    $jsonText = $text.Substring($start, $end - $start + 1)
    $json = $jsonText | ConvertFrom-Json

    return [pscustomobject]@{
        Text = $text
        JsonText = $jsonText
        Json = $json
        Start = $start
        End = $end
        SuffixLength = $text.Length - $end - 1
    }
}

function Backup-Device {
    param([string]$Path, [string]$Tag)

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$Path.$Tag-$timestamp"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    return $backup
}

function Assert-AmxdLooksValid {
    param([string]$Path, [byte[]]$Bytes)

    $header = Get-AsciiHeader $Bytes
    if (-not $header.StartsWith("ampf")) {
        throw "Unexpected AMXD header: $header"
    }

    if ($Bytes.Length -lt 32) {
        throw "AMXD file is too small."
    }

    $ptch = [System.Text.Encoding]::ASCII.GetString($Bytes, 24, 4)
    if ($ptch -ne "ptch") {
        throw "Unexpected AMXD patch chunk marker at offset 24: $ptch"
    }

    $chunkLength = [BitConverter]::ToUInt32($Bytes, 28)
    $expectedChunkLength = [uint32]($Bytes.Length - 32)
    if ($chunkLength -ne $expectedChunkLength) {
        throw "Patch chunk length mismatch: header=$chunkLength expected=$expectedChunkLength"
    }

    $device = Get-DeviceJson $Bytes
    $boxes = @($device.Json.patcher.boxes).Count
    $lines = @($device.Json.patcher.lines).Count

    return [pscustomobject]@{
        Path = $Path
        Length = $Bytes.Length
        Header = $header
        JsonStart = $device.Start
        JsonEnd = $device.End
        JsonSuffixLength = $device.SuffixLength
        PatchChunkLength = $chunkLength
        Boxes = $boxes
        Lines = $lines
    }
}

function Write-AmxdWithUpdatedPatchChunk {
    param(
        [string]$Path,
        [byte[]]$OriginalBytes,
        [string]$JsonText
    )

    $device = Get-DeviceJson $OriginalBytes
    $prefix = New-Object byte[] $device.Start
    [Array]::Copy($OriginalBytes, 0, $prefix, 0, $prefix.Length)

    $suffixStart = $device.End + 1
    $suffixLength = $OriginalBytes.Length - $suffixStart
    $suffix = New-Object byte[] $suffixLength
    if ($suffixLength -gt 0) {
        [Array]::Copy($OriginalBytes, $suffixStart, $suffix, 0, $suffixLength)
    }

    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($JsonText)
    $out = New-Object byte[] ($prefix.Length + $jsonBytes.Length + $suffix.Length)
    [Array]::Copy($prefix, 0, $out, 0, $prefix.Length)
    [Array]::Copy($jsonBytes, 0, $out, $prefix.Length, $jsonBytes.Length)
    if ($suffix.Length -gt 0) {
        [Array]::Copy($suffix, 0, $out, $prefix.Length + $jsonBytes.Length, $suffix.Length)
    }

    $chunkLength = [uint32]($out.Length - 32)
    $chunkBytes = [BitConverter]::GetBytes($chunkLength)
    [Array]::Copy($chunkBytes, 0, $out, 28, 4)

    [System.IO.File]::WriteAllBytes($Path, $out)
}

function Patch-AutostartLengthPreserving {
    param([string]$Path, [byte[]]$Bytes)

    $text = [System.Text.Encoding]::UTF8.GetString($Bytes)
    $beforeLength = $Bytes.Length
    $changes = @()

    if ($text.Contains('"text":  "delay 50"')) {
        $text = $text.Replace('"text":  "delay 50"', '"text":  "delay 99"')
        $changes += "delay 50 -> delay 99"
    }

    $firstObj218 = $text.IndexOf('"obj-218"')
    $secondObj218 = if ($firstObj218 -ge 0) { $text.IndexOf('"obj-218"', $firstObj218 + 1) } else { -1 }
    if ($secondObj218 -ge 0) {
        $lineStart = [Math]::Max(0, $secondObj218 - 300)
        $lineEnd = [Math]::Min($text.Length, $secondObj218 + 300)
        $lineBlock = $text.Substring($lineStart, $lineEnd - $lineStart)
        $patchedBlock = $lineBlock.Replace('"order":  7,', '"order":  9,')
        if ($patchedBlock -ne $lineBlock) {
            $text = $text.Substring(0, $lineStart) + $patchedBlock + $text.Substring($lineEnd)
            $changes += "obj-218 load order 7 -> 9"
        }
    }

    $afterBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    if ($afterBytes.Length -ne $beforeLength) {
        throw "Refusing to write: patch changed device length ($beforeLength -> $($afterBytes.Length))."
    }

    [System.IO.File]::WriteAllBytes($Path, $afterBytes)
    return $changes
}

function Has-Box {
    param($Patcher, [string]$Id)

    foreach ($entry in $Patcher.boxes) {
        if ($entry.box.id -eq $Id) {
            return $true
        }
    }
    return $false
}

function Add-Box {
    param($Patcher, $Box)

    if (-not (Has-Box $Patcher $Box.id)) {
        $Patcher.boxes += [pscustomobject]@{ box = $Box }
    }
}

function Get-Box {
    param($Patcher, [string]$Id)

    foreach ($entry in $Patcher.boxes) {
        if ($entry.box.id -eq $Id) {
            return $entry.box
        }
    }
    return $null
}

function Set-Prop {
    param($Object, [string]$Name, $Value)

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Has-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestId, [int]$DestInlet)

    foreach ($line in $Patcher.lines) {
        $src = $line.patchline.source
        $dst = $line.patchline.destination
        if ($src[0] -eq $SourceId -and [int]$src[1] -eq $SourceOutlet -and
            $dst[0] -eq $DestId -and [int]$dst[1] -eq $DestInlet) {
            return $true
        }
    }
    return $false
}

function Add-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestId, [int]$DestInlet)

    if (-not (Has-Line $Patcher $SourceId $SourceOutlet $DestId $DestInlet)) {
        $Patcher.lines += [pscustomobject]@{
            patchline = [pscustomobject]@{
                source = @($SourceId, $SourceOutlet)
                destination = @($DestId, $DestInlet)
            }
        }
    }
}

function Patch-UiFinish {
    param([string]$Path, [byte[]]$Bytes)

    $device = Get-DeviceJson $Bytes
    $doc = $device.Json
    $p = $doc.patcher

    # Full source image: fpic is the real image layer, jsui draws labels/border above it.
    $sourceView = $p.boxes | Where-Object { $_.box.varname -eq "cs_source_view" } | Select-Object -First 1
    $sourceImage = $p.boxes | Where-Object { $_.box.varname -eq "cs_source_image" } | Select-Object -First 1
    if ($sourceView -and $sourceImage) {
        $sourceImage.box.presentation = 1
        $sourceImage.box.presentation_rect = @($sourceView.box.presentation_rect)
        $sourceImage.box.patching_rect = @($sourceView.box.patching_rect)
        $sourceImage.box.autofit = 1
        $sourceImage.box.forceaspect = 0
    }

    # Editable value boxes for the three dial-style controls. These stay as
    # plain number boxes because they render reliably in the M4L presentation
    # next to the compact dial layout.
    Add-Box $p ([pscustomobject]@{
        id = "obj-300"; maxclass = "number"; varname = "cs_length_number"
        presentation = 1; parameter_enable = 0; numinlets = 1; numoutlets = 2
        outlettype = @("", "bang"); patching_rect = @(1600.0, 100.0, 42.0, 22.0)
        presentation_rect = @(1086.0, 135.0, 44.0, 20.0)
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-301"; maxclass = "newobj"; numinlets = 1; numoutlets = 1
        outlettype = @(""); patching_rect = @(1650.0, 100.0, 95.0, 22.0); text = "prepend length"
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-302"; maxclass = "number"; varname = "cs_density_number"
        presentation = 1; parameter_enable = 0; numinlets = 1; numoutlets = 2
        outlettype = @("", "bang"); patching_rect = @(1600.0, 150.0, 42.0, 22.0)
        presentation_rect = @(1205.0, 135.0, 44.0, 20.0)
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-303"; maxclass = "number"; varname = "cs_shift_number"
        presentation = 1; parameter_enable = 0; numinlets = 1; numoutlets = 2
        outlettype = @("", "bang"); patching_rect = @(1600.0, 200.0, 42.0, 22.0)
        presentation_rect = @(568.0, 70.0, 38.0, 20.0)
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-304"; maxclass = "newobj"; numinlets = 2; numoutlets = 1
        outlettype = @("int"); patching_rect = @(1545.0, 100.0, 35.0, 22.0); text = "+ 1"
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-305"; maxclass = "newobj"; numinlets = 1; numoutlets = 1
        outlettype = @(""); patching_rect = @(1585.0, 100.0, 75.0, 22.0); text = "prepend set"
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-306"; maxclass = "newobj"; numinlets = 1; numoutlets = 1
        outlettype = @(""); patching_rect = @(1545.0, 150.0, 75.0, 22.0); text = "prepend set"
    })
    Add-Box $p ([pscustomobject]@{
        id = "obj-307"; maxclass = "newobj"; numinlets = 1; numoutlets = 1
        outlettype = @(""); patching_rect = @(1545.0, 200.0, 75.0, 22.0); text = "prepend set"
    })

    Add-Line $p "obj-32" 0 "obj-304" 0
    Add-Line $p "obj-304" 0 "obj-305" 0
    Add-Line $p "obj-305" 0 "obj-300" 0
    Add-Line $p "obj-300" 0 "obj-301" 0
    Add-Line $p "obj-301" 0 "obj-2" 0
    Add-Line $p "obj-40" 0 "obj-306" 0
    Add-Line $p "obj-306" 0 "obj-302" 0
    Add-Line $p "obj-302" 0 "obj-42" 0
    Add-Line $p "obj-214" 0 "obj-307" 0
    Add-Line $p "obj-307" 0 "obj-303" 0
    Add-Line $p "obj-303" 0 "obj-216" 0

    foreach ($id in @("obj-300", "obj-302", "obj-303")) {
        $box = Get-Box $p $id
        if ($box) {
        Set-Prop $box "maxclass" "number"
        Set-Prop $box "presentation" 1
        Set-Prop $box "hidden" 0
        Set-Prop $box "parameter_enable" 0
        foreach ($prop in @(
            "minimum",
            "maximum",
            "parameter_mmin",
            "parameter_mmax",
            "parameter_initial",
            "saved_attribute_attributes"
        )) {
            if ($box.PSObject.Properties.Name -contains $prop) {
                $box.PSObject.Properties.Remove($prop)
            }
        }
        }
    }

    $lengthBox = Get-Box $p "obj-300"
    if ($lengthBox) {
        Set-Prop $lengthBox "presentation_rect" @(1086.0, 135.0, 44.0, 20.0)
    }
    $densityBox = Get-Box $p "obj-302"
    if ($densityBox) {
        Set-Prop $densityBox "presentation_rect" @(1205.0, 135.0, 44.0, 20.0)
    }
    $shiftBox = Get-Box $p "obj-303"
    if ($shiftBox) {
        Set-Prop $shiftBox "presentation_rect" @(568.0, 70.0, 38.0, 20.0)
    }

    # In the saved M4L device presentation, earlier boxes appear in front.
    # Keep every presentation control/label before the large jsui surfaces.
    $panelClasses = @("jsui", "fpic")
    $controlClasses = @(
        "button",
        "toggle",
        "dial",
        "number",
        "flonum",
        "umenu",
        "comment",
        "message",
        "live.dial",
        "live.numbox",
        "live.menu",
        "live.text"
    )
    $panels = @($p.boxes | Where-Object {
        $_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass
    })
    $controls = @($p.boxes | Where-Object {
        $_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass
    })
    $middle = @($p.boxes | Where-Object {
        -not ($_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass) -and
        -not ($_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass)
    })
    $p.boxes = @($controls + $middle + $panels)

    $newJson = $doc | ConvertTo-Json -Depth 100
    Write-AmxdWithUpdatedPatchChunk $Path $Bytes $newJson
    return "value boxes + full source image"
}

$bytes = Read-DeviceBytes $AmxdPath
$before = Assert-AmxdLooksValid $AmxdPath $bytes

Write-Host "AMXD: $($before.Path)"
Write-Host "Header: $($before.Header)"
Write-Host "Length: $($before.Length)"
Write-Host "Patch chunk length: $($before.PatchChunkLength)"
Write-Host "Boxes/lines: $($before.Boxes)/$($before.Lines)"

if ($Mode -eq "Inspect") {
    exit 0
}

if (-not $NoBackup) {
    $backup = Backup-Device $AmxdPath "pipeline-backup"
    Write-Host "Backup: $backup"
}

if ($Mode -eq "PatchAutostart") {
    $changes = Patch-AutostartLengthPreserving $AmxdPath $bytes
    $afterBytes = Read-DeviceBytes $AmxdPath
    $after = Assert-AmxdLooksValid $AmxdPath $afterBytes

    if ($after.Length -ne $before.Length) {
        throw "Post-check failed: length changed ($($before.Length) -> $($after.Length))."
    }

    if ($changes.Count -eq 0) {
        Write-Host "Autostart patch already applied."
    } else {
        Write-Host "Changes: $($changes -join '; ')"
    }
    Write-Host "Post-check: OK"
}

if ($Mode -eq "PatchUiFinish") {
    $change = Patch-UiFinish $AmxdPath $bytes
    $afterBytes = Read-DeviceBytes $AmxdPath
    $after = Assert-AmxdLooksValid $AmxdPath $afterBytes

    Write-Host "Changes: $change"
    Write-Host "New length: $($after.Length)"
    Write-Host "New patch chunk length: $($after.PatchChunkLength)"
    Write-Host "New boxes/lines: $($after.Boxes)/$($after.Lines)"
    Write-Host "Post-check: OK"
}
