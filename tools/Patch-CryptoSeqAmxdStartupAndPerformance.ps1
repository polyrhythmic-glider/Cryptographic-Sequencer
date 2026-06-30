param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd",
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

function Get-AmxdPatch {
    param([byte[]]$Bytes)

    $text = [System.Text.Encoding]::UTF8.GetString($Bytes)
    $start = 32
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

    [pscustomobject]@{
        Json = $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
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

function Find-BoxByVarname {
    param($Patcher, [string]$Varname)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.varname -eq $Varname) {
            return $boxWrapper.box
        }
    }
    return $null
}

function Find-BoxById {
    param($Patcher, [string]$Id)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.id -eq $Id) {
            return $boxWrapper.box
        }
    }
    return $null
}

function Ensure-ObjectProperty {
    param($Object, [string]$Name, $Value)

    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Set-Rect {
    param($Box, [double[]]$Rect)

    if ($Box -ne $null) {
        Ensure-ObjectProperty $Box "presentation_rect" $Rect
    }
}

function Set-Text {
    param($Box, [string]$Text)

    if ($Box -ne $null) {
        Ensure-ObjectProperty $Box "text" $Text
    }
}

function Set-ParameterDefaults {
    param(
        $Box,
        [object[]]$Initial,
        [double]$Min,
        [double]$Max,
        [string]$LongName,
        [string]$ShortName
    )

    if ($Box -eq $null) {
        return
    }

    Ensure-ObjectProperty $Box "parameter_enable" 1
    if (-not $Box.PSObject.Properties["saved_attribute_attributes"] -or $Box.saved_attribute_attributes -eq $null) {
        Ensure-ObjectProperty $Box "saved_attribute_attributes" ([pscustomobject]@{})
    }
    if (-not $Box.saved_attribute_attributes.PSObject.Properties["valueof"] -or
        $Box.saved_attribute_attributes.valueof -eq $null) {
        Ensure-ObjectProperty $Box.saved_attribute_attributes "valueof" ([pscustomobject]@{})
    }

    $valueof = $Box.saved_attribute_attributes.valueof
    Ensure-ObjectProperty $valueof "parameter_initial" $Initial
    Ensure-ObjectProperty $valueof "parameter_initial_enable" 1
    Ensure-ObjectProperty $valueof "parameter_longname" $LongName
    Ensure-ObjectProperty $valueof "parameter_shortname" $ShortName
    Ensure-ObjectProperty $valueof "parameter_mmin" $Min
    Ensure-ObjectProperty $valueof "parameter_mmax" $Max
    if (-not $valueof.PSObject.Properties["parameter_type"]) {
        Ensure-ObjectProperty $valueof "parameter_type" 0
    }
    if (-not $valueof.PSObject.Properties["parameter_unitstyle"]) {
        Ensure-ObjectProperty $valueof "parameter_unitstyle" 0
    }
}

function Remove-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestinationId, [int]$DestinationInlet)

    $kept = New-Object System.Collections.ArrayList
    $removed = 0
    foreach ($lineWrapper in @($Patcher.lines)) {
        $line = $lineWrapper.patchline
        $remove = $false
        if ($line -and
            $line.source -and $line.destination -and
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

function Test-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestinationId, [int]$DestinationInlet)

    foreach ($lineWrapper in @($Patcher.lines)) {
        $line = $lineWrapper.patchline
        if ($line -and
            $line.source -and $line.destination -and
            $line.source[0] -eq $SourceId -and [int]$line.source[1] -eq $SourceOutlet -and
            $line.destination[0] -eq $DestinationId -and [int]$line.destination[1] -eq $DestinationInlet) {
            return $true
        }
    }
    return $false
}

function Add-Line {
    param($Patcher, [string]$SourceId, [int]$SourceOutlet, [string]$DestinationId, [int]$DestinationInlet, [bool]$Hidden)

    if (Test-Line $Patcher $SourceId $SourceOutlet $DestinationId $DestinationInlet) {
        return
    }

    $line = [pscustomobject]@{
        patchline = [pscustomobject]@{
            source = @($SourceId, $SourceOutlet)
            destination = @($DestinationId, $DestinationInlet)
        }
    }
    if ($Hidden) {
        Ensure-ObjectProperty $line.patchline "hidden" $true
    }

    $lines = New-Object System.Collections.ArrayList
    foreach ($lineWrapper in @($Patcher.lines)) {
        [void]$lines.Add($lineWrapper)
    }
    [void]$lines.Add($line)
    $Patcher.lines = @($lines)
}

$bytes = [System.IO.File]::ReadAllBytes($AmxdPath)
$patch = Get-AmxdPatch $bytes
$patcher = $patch.Json.patcher
$changes = New-Object System.Collections.ArrayList

# Shift: keep dial as raw 0..254, but display/send the logical -127..127 value.
$shiftDial = Find-BoxByVarname $patcher "cs_shift_dial"
$shiftNumber = Find-BoxByVarname $patcher "cs_shift_number"
Set-ParameterDefaults $shiftDial @(127) 0 254 "shift knob" "shift knob"
Set-ParameterDefaults $shiftNumber @(0) -127 127 "shift" "shift"
[void]$changes.Add("shift defaults set")

$removed = 0
$removed += Remove-Line $patcher "obj-214" 0 "obj-307" 0
$removed += Remove-Line $patcher "obj-307" 0 "obj-303" 0
Add-Line $patcher "obj-451" 0 "obj-303" 0 $false
[void]$changes.Add("shift routing repaired; removed raw display lines: $removed")

# Conservative startup defaults for controls that Live restores.
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_length_number") @(16) 1 128 "length" "length"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_density_dial") @(50) 0 100 "density" "density"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_density_number") @(50) 0 100 "density value" "density value"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_scene_number") @(0) 0 127 "scene" "scene"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_ratchet_amount_number") @(0) 0 100 "ratchet amount" "ratchet amount"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_ratchet_max_number") @(1) 1 8 "ratchet max" "ratchet max"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_fill_amount_number") @(0) 0 100 "fill amount" "fill amount"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_fill_mode_menu") @(0) 0 4 "fill mode" "fill mode"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_fill_target_menu") @(4) 0 4 "fill target" "fill target"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_morph_amount_number") @(0) 0 100 "morph amount" "morph amount"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_morph_amount_dial") @(0) 0 100 "morph knob" "morph knob"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_morph_scene_number") @(1) 0 127 "morph scene" "morph scene"
Set-ParameterDefaults (Find-BoxByVarname $patcher "cs_morph_mode_menu") @(0) 0 3 "morph mode" "morph mode"
[void]$changes.Add("startup defaults set")

# Give the performance panel a compact layout while staying inside the current M4L strip.
Set-Rect (Find-BoxByVarname $patcher "cs_performance_view") @(1268.0, 0.06, 360.0, 170.0)
Set-Text (Find-BoxById $patcher "obj-442") "amount"
Set-Text (Find-BoxById $patcher "obj-445") "target"
Set-Text (Find-BoxById $patcher "obj-426") "morph"

Set-Rect (Find-BoxById $patcher "obj-401") @(1279.0, 30.0, 45.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_scene_number") @(1279.0, 51.0, 44.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-404") @(1332.0, 30.0, 62.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_ratchet_amount_number") @(1332.0, 51.0, 44.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-407") @(1390.0, 30.0, 35.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_ratchet_max_number") @(1390.0, 51.0, 36.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-410") @(1442.0, 30.0, 35.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_fill_mode_menu") @(1442.0, 51.0, 68.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-442") @(1522.0, 30.0, 58.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_fill_amount_number") @(1522.0, 51.0, 44.0, 22.0)

Set-Rect (Find-BoxById $patcher "obj-445") @(1279.0, 84.0, 48.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_fill_target_menu") @(1279.0, 105.0, 68.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-426") @(1360.0, 84.0, 50.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_morph_amount_dial") @(1360.0, 105.0, 30.0, 30.0)
Set-Rect (Find-BoxByVarname $patcher "cs_morph_amount_number") @(1395.0, 109.0, 44.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-429") @(1448.0, 84.0, 55.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_morph_scene_number") @(1448.0, 105.0, 44.0, 22.0)
Set-Rect (Find-BoxById $patcher "obj-432") @(1510.0, 84.0, 45.0, 20.0)
Set-Rect (Find-BoxByVarname $patcher "cs_morph_mode_menu") @(1510.0, 105.0, 82.0, 22.0)
[void]$changes.Add("performance layout compacted")

if (-not $NoBackup) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backup = "$AmxdPath.bak-startup-layout-$timestamp"
    Copy-Item -LiteralPath $AmxdPath -Destination $backup -Force
} else {
    $backup = ""
}

$jsonText = $patch.Json | ConvertTo-Json -Depth 100 -Compress
Write-AmxdPatch $AmxdPath $bytes $patch.Start $patch.End $jsonText

[pscustomobject]@{
    Path = $AmxdPath
    Backup = $backup
    Changes = $changes
}
