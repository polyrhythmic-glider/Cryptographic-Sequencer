param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Prop($Object, [string]$Name, $Value) {
    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function New-Box($Id, $Props) {
    $box = [ordered]@{ id = $Id }
    foreach ($key in $Props.Keys) {
        $box[$key] = $Props[$key]
    }
    return [pscustomobject]@{ box = [pscustomobject]$box }
}

function New-ObjectBox($Id, $Text, $Rect) {
    return New-Box $Id ([ordered]@{
        maxclass = "newobj"; text = $Text; numinlets = 1; numoutlets = 1
        outlettype = @(""); patching_rect = $Rect
    })
}

function New-Line($Source, [int]$SourceOutlet, $Destination, [int]$DestinationInlet, [bool]$Hidden = $true) {
    return [pscustomobject]@{
        patchline = [pscustomobject]@{
            source = @($Source, $SourceOutlet)
            destination = @($Destination, $DestinationInlet)
            hidden = $Hidden
        }
    }
}

function Get-BoxById($Patcher, [string]$Id) {
    return ($Patcher.boxes | ForEach-Object { $_.box } | Where-Object { $_.id -eq $Id } | Select-Object -First 1)
}

function Get-BoxByVar($Patcher, [string]$VarName) {
    return (
        $Patcher.boxes |
            ForEach-Object { $_.box } |
            Where-Object { $_.PSObject.Properties["varname"] -and $_.varname -eq $VarName } |
            Select-Object -First 1
    )
}

function Add-BoxIfMissing($Patcher, $BoxObject) {
    if (-not (Get-BoxById $Patcher $BoxObject.box.id)) {
        $Patcher.boxes += $BoxObject
    }
}

function Remove-Line($Patcher, [string]$Source, [Nullable[int]]$SourceOutlet, [string]$Destination, [Nullable[int]]$DestinationInlet) {
    $Patcher.lines = @($Patcher.lines | Where-Object {
        $line = $_.patchline
        $remove = $line.source[0] -eq $Source -and $line.destination[0] -eq $Destination
        if ($remove -and $null -ne $SourceOutlet) {
            $remove = [int]$line.source[1] -eq $SourceOutlet
        }
        if ($remove -and $null -ne $DestinationInlet) {
            $remove = [int]$line.destination[1] -eq $DestinationInlet
        }
        -not $remove
    })
}

function Add-LineIfMissing($Patcher, $LineObject) {
    $line = $LineObject.patchline
    $exists = $Patcher.lines | Where-Object {
        $_.patchline.source[0] -eq $line.source[0] -and
        [int]$_.patchline.source[1] -eq [int]$line.source[1] -and
        $_.patchline.destination[0] -eq $line.destination[0] -and
        [int]$_.patchline.destination[1] -eq [int]$line.destination[1]
    }
    if (-not $exists) {
        $Patcher.lines += $LineObject
    }
}

function Get-DeviceJson {
    param([byte[]]$Bytes)

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

    if ($end -lt $start) {
        throw "Could not find embedded JSON patcher."
    }

    $jsonText = $text.Substring($start, $end - $start + 1)
    return [pscustomobject]@{
        JsonText = $jsonText
        Json = ($jsonText | ConvertFrom-Json)
        Start = $start
        End = $end
    }
}

function Update-Patcher($Patcher) {
    $fillMenu = Get-BoxByVar $Patcher "cs_fill_mode_menu"
    if ($fillMenu) {
        $fillMenu.items = @("off", ",", "end", ",", "accent", ",", "velocity", ",", "all")
    }

    $shiftDial = Get-BoxByVar $Patcher "cs_shift_dial"
    if ($shiftDial) {
        Add-Prop $shiftDial "size" 255
    }
    $shiftDefault = Get-BoxById $Patcher "obj-217"
    if ($shiftDefault) {
        $shiftDefault.text = "127"
    }
    Remove-Line $Patcher "obj-214" $null "obj-220" 0
    Add-BoxIfMissing $Patcher (New-ObjectBox "obj-451" "scale 0 254 -127 127" @(1478.0, 158.0, 130.0, 22.0))
    $shiftMapper = Get-BoxById $Patcher "obj-451"
    if ($shiftMapper) {
        $shiftMapper.text = "scale 0 254 -127 127"
        $shiftMapper.patching_rect = @(1478.0, 158.0, 130.0, 22.0)
    }
    Add-LineIfMissing $Patcher (New-Line "obj-214" 0 "obj-451" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-451" 0 "obj-220" 0 $true)

    $labels = @{
        "obj-414" = "pitch"; "obj-417" = "rhythm"; "obj-420" = "velocity"; "obj-423" = "gate"
    }
    foreach ($id in $labels.Keys) {
        $box = Get-BoxById $Patcher $id
        if ($box) { $box.text = $labels[$id] }
    }

    Add-BoxIfMissing $Patcher (New-Box "obj-442" ([ordered]@{
        maxclass = "comment"; text = "fill amount"; presentation = 1; hidden = 0
        numinlets = 1; numoutlets = 0
        patching_rect = @(1780.0, 751.0, 75.0, 18.0)
        presentation_rect = @(1534.0, 31.0, 75.0, 18.0)
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-443" ([ordered]@{
        maxclass = "number"; varname = "cs_fill_amount_number"; presentation = 1; hidden = 0
        parameter_enable = 0; numinlets = 1; numoutlets = 2; outlettype = @("", "bang")
        patching_rect = @(1780.0, 771.0, 44.0, 20.0)
        presentation_rect = @(1534.0, 51.0, 44.0, 20.0)
        minimum = 0; maximum = 100
    }))
    Add-BoxIfMissing $Patcher (New-ObjectBox "obj-444" "prepend fillamount" @(1780.0, 800.0, 135.0, 22.0))
    Add-BoxIfMissing $Patcher (New-Box "obj-445" ([ordered]@{
        maxclass = "comment"; text = "fill target"; presentation = 1; hidden = 0
        numinlets = 1; numoutlets = 0
        patching_rect = @(1860.0, 751.0, 75.0, 18.0)
        presentation_rect = @(1584.0, 31.0, 75.0, 18.0)
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-446" ([ordered]@{
        maxclass = "umenu"; varname = "cs_fill_target_menu"; presentation = 1; hidden = 0
        parameter_enable = 0; numinlets = 1; numoutlets = 3; outlettype = @("int", "", "")
        items = @("density", ",", "ratchet", ",", "velocity", ",", "gate", ",", "all")
        patching_rect = @(1860.0, 771.0, 88.0, 22.0)
        presentation_rect = @(1584.0, 51.0, 82.0, 22.0)
    }))
    Add-BoxIfMissing $Patcher (New-ObjectBox "obj-447" "prepend filltarget" @(1860.0, 800.0, 130.0, 22.0))
    Add-BoxIfMissing $Patcher (New-Box "obj-448" ([ordered]@{
        maxclass = "message"; text = "0"; numinlets = 2; numoutlets = 1; outlettype = @("")
        patching_rect = @(2160.0, 910.0, 35.0, 22.0)
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-449" ([ordered]@{
        maxclass = "message"; text = "clear, append density, append ratchet, append velocity, append gate, append all, setsymbol all"
        numinlets = 2; numoutlets = 1; outlettype = @("")
        patching_rect = @(2160.0, 940.0, 520.0, 22.0)
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-450" ([ordered]@{
        maxclass = "dial"; varname = "cs_morph_amount_dial"; presentation = 1; hidden = 0
        parameter_enable = 0; numinlets = 1; numoutlets = 1; outlettype = @("int"); size = 101
        patching_rect = @(1470.0, 866.0, 36.0, 36.0)
        presentation_rect = @(1238.0, 135.0, 30.0, 30.0)
    }))

    $fillDefault = Get-BoxById $Patcher "obj-438"
    if ($fillDefault) {
        $fillDefault.text = "clear, append off, append end, append accent, append velocity, append all, setsymbol off"
    }

    Add-LineIfMissing $Patcher (New-Line "obj-443" 0 "obj-444" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-444" 0 "obj-2" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-446" 1 "obj-447" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-447" 0 "obj-2" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-79" 0 "obj-448" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-448" 0 "obj-443" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-79" 0 "obj-449" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-449" 0 "obj-446" 0 $true)
    Add-LineIfMissing $Patcher (New-Line "obj-450" 0 "obj-427" 0 $true)
}

$resolved = Resolve-Path -LiteralPath $Path
$bytes = [System.IO.File]::ReadAllBytes($resolved)
if ($bytes.Length -lt 40 -or [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne "ampf") {
    throw "Not an AMXD ampf container: $Path"
}

$chunkName = [System.Text.Encoding]::ASCII.GetString($bytes, 24, 4)
if ($chunkName -ne "ptch") {
    throw "Unsupported AMXD chunk marker '$chunkName'"
}

$device = Get-DeviceJson $bytes
$patch = $device.Json
if ($patch.PSObject.Properties["patcher"]) {
    Update-Patcher $patch.patcher
} elseif ($patch.PSObject.Properties["boxes"]) {
    Update-Patcher $patch
} else {
    throw "AMXD payload does not look like a Max patcher JSON document"
}
$newJson = $patch | ConvertTo-Json -Depth 100 -Compress
$newBytes = [System.Text.Encoding]::UTF8.GetBytes($newJson)

$backup = "$resolved.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $resolved -Destination $backup
$suffixStart = $device.End + 1
$suffixLength = $bytes.Length - $suffixStart
$out = New-Object byte[] (32 + $newBytes.Length + $suffixLength)
[Array]::Copy($bytes, 0, $out, 0, 32)
[Array]::Copy($newBytes, 0, $out, 32, $newBytes.Length)
if ($suffixLength -gt 0) {
    [Array]::Copy($bytes, $suffixStart, $out, 32 + $newBytes.Length, $suffixLength)
}
$chunkLengthBytes = [BitConverter]::GetBytes([uint32]($out.Length - 32))
[Array]::Copy($chunkLengthBytes, 0, $out, 28, 4)
[System.IO.File]::WriteAllBytes($resolved, $out)

Write-Host "Patched $resolved"
Write-Host "Backup $backup"
