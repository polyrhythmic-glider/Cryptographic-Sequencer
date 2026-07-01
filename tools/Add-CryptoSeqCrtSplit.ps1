param(
    [string[]]$Path = @(
        "adapters\max\patchers\cryptoseq-midi-ui.maxpat",
        "release\CRYPTOSEQALFA0.1\CryptoSeqALFA0.1-modular.amxd",
        "release\max-for-live\CryptoSeqALFA0.1-modular.amxd"
    ),
    [switch]$NoBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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

    return [pscustomobject]@{
        Json = ($text.Substring($start, $end - $start + 1) | ConvertFrom-Json)
        Start = $start
        End = $end
    }
}

function Write-AmxdPatch {
    param(
        [string]$Path,
        [byte[]]$OriginalBytes,
        [int]$Start,
        [int]$End,
        [string]$JsonText
    )

    $prefix = New-Object byte[] $Start
    [Array]::Copy($OriginalBytes, 0, $prefix, 0, $prefix.Length)

    $suffixStart = $End + 1
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

    [Array]::Copy([BitConverter]::GetBytes([uint32]($out.Length - 32)), 0, $out, 28, 4)
    [System.IO.File]::WriteAllBytes($Path, $out)
}

function Add-Or-Set {
    param($Object, [string]$Name, $Value)

    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Get-Patcher($Document) {
    if ($Document.PSObject.Properties["patcher"]) {
        return $Document.patcher
    }
    return $Document
}

function Find-Box {
    param($Patcher, [string]$Id)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.id -eq $Id) {
            return $boxWrapper.box
        }
    }
    return $null
}

function New-Box {
    param([string]$Id, $Props)

    $box = [ordered]@{ id = $Id }
    foreach ($key in $Props.Keys) {
        $box[$key] = $Props[$key]
    }
    return [pscustomobject]@{ box = [pscustomobject]$box }
}

function Add-BoxIfMissing {
    param($Patcher, $BoxWrapper)

    if ($null -eq (Find-Box $Patcher $BoxWrapper.box.id)) {
        $Patcher.boxes += $BoxWrapper
    }
}

function Set-BoxProps {
    param($Box, $Props)

    if ($null -eq $Box) {
        return
    }

    foreach ($key in $Props.Keys) {
        Add-Or-Set $Box $key $Props[$key]
    }
}

function Has-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestinationId, [int]$DestinationInlet)

    foreach ($lineWrapper in @($Patcher.lines)) {
        if (-not $lineWrapper.PSObject.Properties["patchline"]) {
            continue
        }
        $line = $lineWrapper.patchline
        if ($line -and $line.source -and $line.destination -and
            $line.source[0] -eq $SourceId -and [int]$line.source[1] -eq $SourceOutlet -and
            $line.destination[0] -eq $DestinationId -and [int]$line.destination[1] -eq $DestinationInlet) {
            return $true
        }
    }
    return $false
}

function Add-LineIfMissing {
    param(
        $Patcher,
        [string]$SourceId,
        [int]$SourceOutlet,
        [string]$DestinationId,
        [int]$DestinationInlet,
        [bool]$Hidden = $true
    )

    if (Has-Line $Patcher $SourceId $SourceOutlet $DestinationId $DestinationInlet) {
        return
    }

    $line = [ordered]@{
        source = @($SourceId, $SourceOutlet)
        destination = @($DestinationId, $DestinationInlet)
    }
    if ($Hidden) {
        $line["hidden"] = 1
    }
    $Patcher.lines += [pscustomobject]@{ patchline = [pscustomobject]$line }
}

function Set-MenuItems {
    param($Box, [string[]]$Items)

    $menuItems = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $Items.Count; $i += 1) {
        if ($i -gt 0) {
            [void]$menuItems.Add(",")
        }
        [void]$menuItems.Add($Items[$i])
    }
    Add-Or-Set $Box "items" @($menuItems)
}

function Set-ParameterDefault {
    param(
        $Box,
        [string]$LongName,
        [object[]]$Initial,
        [double]$Min,
        [double]$Max
    )

    Add-Or-Set $Box "parameter_enable" 1
    if (-not $Box.PSObject.Properties["saved_attribute_attributes"] -or $null -eq $Box.saved_attribute_attributes) {
        Add-Or-Set $Box "saved_attribute_attributes" ([pscustomobject]@{})
    }
    if (-not $Box.saved_attribute_attributes.PSObject.Properties["valueof"] -or $null -eq $Box.saved_attribute_attributes.valueof) {
        Add-Or-Set $Box.saved_attribute_attributes "valueof" ([pscustomobject]@{})
    }

    $valueof = $Box.saved_attribute_attributes.valueof
    Add-Or-Set $valueof "parameter_initial" $Initial
    Add-Or-Set $valueof "parameter_initial_enable" 1
    Add-Or-Set $valueof "parameter_longname" $LongName
    Add-Or-Set $valueof "parameter_shortname" $LongName
    Add-Or-Set $valueof "parameter_mmin" $Min
    Add-Or-Set $valueof "parameter_mmax" $Max
    Add-Or-Set $valueof "parameter_type" 0
    Add-Or-Set $valueof "parameter_unitstyle" 0
}

function Move-PresentationControlsBeforePanels {
    param($Patcher)

    $panelClasses = @("jsui", "fpic")
    $controlClasses = @("button", "toggle", "dial", "number", "flonum", "umenu", "comment", "message", "live.dial", "live.numbox", "live.menu", "live.text")
    $controls = @($Patcher.boxes | Where-Object { $_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass })
    $panels = @($Patcher.boxes | Where-Object { $_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass })
    $middle = @($Patcher.boxes | Where-Object {
        -not ($_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass) -and
        -not ($_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass)
    })
    $Patcher.boxes = @($controls + $middle + $panels)
}

function Update-Patcher {
    param($Patcher)

    $items = @("off", "p_pitch_q_rhythm", "p_rhythm_q_pitch", "p_melody_q_drums")

    Add-BoxIfMissing $Patcher (New-Box "obj-530" ([ordered]@{
        maxclass = "comment"
        text = "CRT split"
        patching_rect = @(1740.0, 846.0, 70.0, 18.0)
        presentation = 1
        presentation_rect = @(930.0, 137.0, 62.0, 20.0)
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-531" ([ordered]@{
        maxclass = "umenu"
        varname = "cs_crt_split_menu"
        numinlets = 1
        numoutlets = 3
        outlettype = @("int", "", "")
        patching_rect = @(1740.0, 866.0, 190.0, 22.0)
        presentation = 1
        presentation_rect = @(995.0, 137.0, 190.0, 22.0)
        parameter_enable = 1
    }))
    Add-BoxIfMissing $Patcher (New-Box "obj-532" ([ordered]@{
        maxclass = "newobj"
        text = "prepend crtsplit"
        patching_rect = @(2040.0, 850.0, 130.0, 22.0)
        numinlets = 1
        numoutlets = 1
        outlettype = @("")
    }))

    Set-BoxProps (Find-Box $Patcher "obj-530") ([ordered]@{
        maxclass = "comment"
        text = "CRT split"
        patching_rect = @(1740.0, 846.0, 70.0, 18.0)
        presentation = 1
        presentation_rect = @(930.0, 137.0, 62.0, 20.0)
    })
    $menu = Find-Box $Patcher "obj-531"
    Set-BoxProps $menu ([ordered]@{
        maxclass = "umenu"
        varname = "cs_crt_split_menu"
        numinlets = 1
        numoutlets = 3
        outlettype = @("int", "", "")
        patching_rect = @(1740.0, 866.0, 190.0, 22.0)
        presentation = 1
        presentation_rect = @(995.0, 137.0, 190.0, 22.0)
    })
    Set-MenuItems $menu $items
    Set-ParameterDefault $menu "CRT split" @(0) 0 3
    Set-BoxProps (Find-Box $Patcher "obj-532") ([ordered]@{
        maxclass = "newobj"
        text = "prepend crtsplit"
        patching_rect = @(2040.0, 850.0, 130.0, 22.0)
        numinlets = 1
        numoutlets = 1
        outlettype = @("")
    })

    Add-LineIfMissing $Patcher "obj-531" 1 "obj-532" 0 $true
    Add-LineIfMissing $Patcher "obj-532" 0 "obj-2" 0 $true
    Add-LineIfMissing $Patcher "obj-520" 0 "obj-531" 0 $true
    Move-PresentationControlsBeforePanels $Patcher
}

foreach ($target in $Path) {
    $resolved = Resolve-Path -LiteralPath $target
    $extension = [System.IO.Path]::GetExtension($resolved.Path).ToLowerInvariant()
    $bytes = [System.IO.File]::ReadAllBytes($resolved.Path)
    $isAmxd = $bytes.Length -gt 32 -and [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq "ampf"

    if (-not $NoBackup) {
        Copy-Item -LiteralPath $resolved.Path -Destination "$($resolved.Path).bak-crt-split-$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
    }

    if ($isAmxd) {
        $device = Get-DeviceJson $bytes
        Update-Patcher (Get-Patcher $device.Json)
        $jsonText = $device.Json | ConvertTo-Json -Depth 100
        Write-AmxdPatch $resolved.Path $bytes $device.Start $device.End $jsonText
    } elseif ($extension -eq ".maxpat") {
        $document = Get-Content -Raw -LiteralPath $resolved.Path | ConvertFrom-Json
        Update-Patcher (Get-Patcher $document)
        $document | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $resolved.Path -Encoding UTF8
    } else {
        throw "Unsupported file type: $target"
    }

    Write-Output "Patched CRT Split UI: $($resolved.Path)"
}
