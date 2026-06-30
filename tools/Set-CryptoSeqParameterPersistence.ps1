param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
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

    $jsonText = $text.Substring($start, $end - $start + 1)
    return [pscustomobject]@{
        Json = ($jsonText | ConvertFrom-Json)
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

function Set-ParameterDefault {
    param(
        $Box,
        [string]$LongName,
        [object[]]$Initial,
        [double]$Min,
        [double]$Max
    )

    if ($null -eq $Box) {
        return
    }

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

function Set-MenuItems {
    param($Box, [string[]]$Items)

    if ($null -eq $Box) {
        return
    }

    $menuItems = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $Items.Count; $i += 1) {
        if ($i -gt 0) {
            [void]$menuItems.Add(",")
        }
        [void]$menuItems.Add($Items[$i])
    }
    Add-Or-Set $Box "items" @($menuItems)
}

function Get-MenuIndex {
    param($Box, [string]$Value)

    $index = 0
    foreach ($item in @($Box.items)) {
        if ($item -eq ",") {
            continue
        }
        if ($item.ToString() -eq $Value) {
            return $index
        }
        $index += 1
    }
    return 0
}

function Get-MenuItemCount {
    param($Box)

    $count = 0
    foreach ($item in @($Box.items)) {
        if ($item -ne ",") {
            $count += 1
        }
    }
    return $count
}

function New-Box {
    param([string]$Id, $Props)

    $box = [ordered]@{ id = $Id }
    foreach ($key in $Props.Keys) {
        $box[$key] = $Props[$key]
    }
    return [pscustomobject]@{ box = [pscustomobject]$box }
}

function Has-Box {
    param($Patcher, [string]$Id)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.id -eq $Id) {
            return $true
        }
    }
    return $false
}

function Add-BoxIfMissing {
    param($Patcher, $BoxWrapper)

    if (-not (Has-Box $Patcher $BoxWrapper.box.id)) {
        $Patcher.boxes += $BoxWrapper
    }
}

function Remove-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestinationId, [int]$DestinationInlet)

    $kept = New-Object System.Collections.ArrayList
    $removed = 0
    foreach ($lineWrapper in @($Patcher.lines)) {
        if (-not $lineWrapper.PSObject.Properties["patchline"]) {
            [void]$kept.Add($lineWrapper)
            continue
        }
        $line = $lineWrapper.patchline
        $remove = $false
        if ($line -and $line.source -and $line.destination -and
            $line.source[0] -eq $SourceId -and [int]$line.source[1] -eq $SourceOutlet -and
            $line.destination[0] -eq $DestinationId -and [int]$line.destination[1] -eq $DestinationInlet) {
            $remove = $true
        }

        if ($remove) {
            $removed += 1
        } else {
            [void]$kept.Add($lineWrapper)
        }
    }
    $Patcher.lines = @($kept)
    return $removed
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
        [Nullable[int]]$Order = $null
    )

    if (Has-Line $Patcher $SourceId $SourceOutlet $DestinationId $DestinationInlet) {
        return
    }

    $patchline = [pscustomobject]@{
        source = @($SourceId, $SourceOutlet)
        destination = @($DestinationId, $DestinationInlet)
        hidden = $true
    }
    if ($null -ne $Order) {
        Add-Or-Set $patchline "order" $Order
    }
    $Patcher.lines += [pscustomobject]@{ patchline = $patchline }
}

function Apply-Persistence {
    param($Document)

    $patcher = Get-Patcher $Document
    $changes = New-Object System.Collections.ArrayList

    $pMenu = Find-Box $patcher "obj-10"
    $qMenu = Find-Box $patcher "obj-13"
    $eMenu = Find-Box $patcher "obj-16"

    if ($pMenu) {
        Add-Or-Set $pMenu "varname" "cs_p_menu"
        Set-ParameterDefault $pMenu "p prime" @(Get-MenuIndex $pMenu "251") 0 ([Math]::Max(0, (Get-MenuItemCount $pMenu) - 1))
    }
    if ($qMenu) {
        Add-Or-Set $qMenu "varname" "cs_q_menu"
        Set-ParameterDefault $qMenu "q prime" @(Get-MenuIndex $qMenu "257") 0 ([Math]::Max(0, (Get-MenuItemCount $qMenu) - 1))
    }
    if ($eMenu) {
        Add-Or-Set $eMenu "varname" "cs_e_menu"
        Set-MenuItems $eMenu @("3", "17", "257")
        Set-ParameterDefault $eMenu "RSA e" @(0) 0 2
    }
    [void]$changes.Add("RSA menus set as Live parameters")

    $defaults = @(
        @{ id = "obj-20"; name = "root note"; value = @(36); min = 0; max = 72 },
        @{ id = "obj-24"; name = "mode"; value = @(1); min = 0; max = 2 },
        @{ id = "obj-28"; name = "scale"; value = @(0); min = 0; max = 5 },
        @{ id = "obj-32"; name = "length knob"; value = @(15); min = 0; max = 127 },
        @{ id = "obj-36"; name = "division"; value = @(2); min = 0; max = 3 },
        @{ id = "obj-40"; name = "density"; value = @(50); min = 0; max = 100 },
        @{ id = "obj-47"; name = "play"; value = @(0); min = 0; max = 1 },
        @{ id = "obj-80"; name = "low note"; value = @(36); min = 0; max = 84 },
        @{ id = "obj-83"; name = "high note"; value = @(60); min = 0; max = 84 },
        @{ id = "obj-86"; name = "pad count"; value = @(4); min = 0; max = 6 },
        @{ id = "obj-214"; name = "shift knob"; value = @(127); min = 0; max = 254 },
        @{ id = "obj-220"; name = "shift"; value = @(0); min = -127; max = 127 },
        @{ id = "obj-221"; name = "poly"; value = @(0); min = 0; max = 1 },
        @{ id = "obj-402"; name = "scene"; value = @(0); min = 0; max = 127 },
        @{ id = "obj-405"; name = "ratchet amount"; value = @(0); min = 0; max = 100 },
        @{ id = "obj-408"; name = "ratchet max"; value = @(1); min = 1; max = 8 },
        @{ id = "obj-411"; name = "fill mode"; value = @(0); min = 0; max = 4 },
        @{ id = "obj-427"; name = "morph amount"; value = @(0); min = 0; max = 100 },
        @{ id = "obj-430"; name = "morph scene"; value = @(1); min = 0; max = 127 },
        @{ id = "obj-433"; name = "morph mode"; value = @(0); min = 0; max = 3 },
        @{ id = "obj-443"; name = "fill amount"; value = @(0); min = 0; max = 100 },
        @{ id = "obj-446"; name = "fill target"; value = @(4); min = 0; max = 4 },
        @{ id = "obj-450"; name = "morph knob"; value = @(0); min = 0; max = 100 }
    )
    foreach ($entry in $defaults) {
        Set-ParameterDefault (Find-Box $patcher $entry.id) $entry.name $entry.value $entry.min $entry.max
    }
    [void]$changes.Add("parameter double-click defaults refreshed")

    foreach ($dest in @("obj-23", "obj-27", "obj-31", "obj-35", "obj-39", "obj-43",
            "obj-217", "obj-224", "obj-435", "obj-436", "obj-437", "obj-438",
            "obj-439", "obj-440", "obj-441", "obj-448", "obj-449")) {
        [void](Remove-Line $patcher "obj-79" 0 $dest 0)
    }
    [void]$changes.Add("loadbang default setters disconnected")

    Add-BoxIfMissing $patcher (New-Box "obj-520" ([ordered]@{
        maxclass = "newobj"; text = "delay 300"; numinlets = 1; numoutlets = 1
        outlettype = @("bang"); patching_rect = @(2140.0, 990.0, 70.0, 22.0)
    }))
    Add-LineIfMissing $patcher "obj-1" 0 "obj-520" 0 $null

    $syncTargets = @(
        "obj-10", "obj-13", "obj-16", "obj-20", "obj-24", "obj-28",
        "obj-32", "obj-36", "obj-40", "obj-80", "obj-83", "obj-86",
        "obj-214", "obj-402", "obj-405", "obj-408", "obj-411",
        "obj-427", "obj-430", "obj-433", "obj-443", "obj-446", "obj-450"
    )
    for ($i = 0; $i -lt $syncTargets.Count; $i += 1) {
        if (Find-Box $patcher $syncTargets[$i]) {
            Add-LineIfMissing $patcher "obj-520" 0 $syncTargets[$i] 0 $i
        }
    }
    [void]$changes.Add("delayed current-parameter sync added")

    return $changes
}

$resolved = Resolve-Path -LiteralPath $Path
$bytes = [System.IO.File]::ReadAllBytes($resolved)
$isAmxd = $bytes.Length -gt 32 -and [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq "ampf"

if (-not $NoBackup) {
    $backup = "$resolved.bak-persistence-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $resolved -Destination $backup -Force
} else {
    $backup = ""
}

if ($isAmxd) {
    $device = Get-DeviceJson $bytes
    $changes = Apply-Persistence $device.Json
    $json = $device.Json | ConvertTo-Json -Depth 100 -Compress
    Write-AmxdPatch $resolved $bytes $device.Start $device.End $json
    [pscustomobject]@{ Path = $resolved; Backup = $backup; Changes = $changes }
} else {
    $doc = Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json
    $changes = Apply-Persistence $doc
    $doc | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $resolved -Encoding UTF8
    [pscustomobject]@{ Path = $resolved; Backup = $backup; Changes = $changes }
}
