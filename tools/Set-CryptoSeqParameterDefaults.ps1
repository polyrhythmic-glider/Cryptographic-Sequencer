param(
    [Parameter(Mandatory = $true)]
    [string]$Path
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

function Add-Or-Set($Object, [string]$Name, $Value) {
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

function Set-ParameterDefault($Box, [string]$LongName, [double]$Default, [double]$Min, [double]$Max) {
    Add-Or-Set $Box "parameter_enable" 1
    Add-Or-Set $Box "saved_attribute_attributes" ([pscustomobject]@{})
    Add-Or-Set $Box.saved_attribute_attributes "valueof" ([pscustomobject]@{})

    $valueof = $Box.saved_attribute_attributes.valueof
    Add-Or-Set $valueof "parameter_initial" @($Default)
    Add-Or-Set $valueof "parameter_initial_enable" 1
    Add-Or-Set $valueof "parameter_longname" $LongName
    Add-Or-Set $valueof "parameter_shortname" $LongName
    Add-Or-Set $valueof "parameter_mmin" $Min
    Add-Or-Set $valueof "parameter_mmax" $Max
    Add-Or-Set $valueof "parameter_type" 0
    Add-Or-Set $valueof "parameter_unitstyle" 0
}

function Find-Box($Patcher, [string]$Id) {
    return ($Patcher.boxes | ForEach-Object { $_.box } | Where-Object { $_.id -eq $Id } | Select-Object -First 1)
}

function Apply-Defaults($Document) {
    $patcher = Get-Patcher $Document
    $defaults = @(
        @{ id = "obj-20"; name = "root note"; value = 36; min = 0; max = 72 },
        @{ id = "obj-24"; name = "mode"; value = 1; min = 0; max = 2 },
        @{ id = "obj-28"; name = "scale"; value = 0; min = 0; max = 5 },
        @{ id = "obj-32"; name = "length knob"; value = 15; min = 0; max = 127 },
        @{ id = "obj-36"; name = "division"; value = 2; min = 0; max = 3 },
        @{ id = "obj-40"; name = "density"; value = 50; min = 0; max = 100 },
        @{ id = "obj-80"; name = "low note"; value = 36; min = 0; max = 84 },
        @{ id = "obj-83"; name = "high note"; value = 60; min = 0; max = 84 },
        @{ id = "obj-86"; name = "pad count"; value = 4; min = 0; max = 6 },
        @{ id = "obj-47"; name = "play"; value = 0; min = 0; max = 1 },
        @{ id = "obj-214"; name = "shift knob"; value = 127; min = 0; max = 254 },
        @{ id = "obj-220"; name = "shift"; value = 0; min = -127; max = 127 },
        @{ id = "obj-221"; name = "poly"; value = 0; min = 0; max = 1 },
        @{ id = "obj-402"; name = "scene"; value = 0; min = 0; max = 127 },
        @{ id = "obj-405"; name = "ratchet amount"; value = 0; min = 0; max = 100 },
        @{ id = "obj-408"; name = "ratchet max"; value = 1; min = 1; max = 8 },
        @{ id = "obj-411"; name = "fill mode"; value = 0; min = 0; max = 4 },
        @{ id = "obj-427"; name = "morph amount"; value = 0; min = 0; max = 100 },
        @{ id = "obj-430"; name = "morph scene"; value = 1; min = 0; max = 127 },
        @{ id = "obj-433"; name = "morph mode"; value = 0; min = 0; max = 3 },
        @{ id = "obj-443"; name = "fill amount"; value = 0; min = 0; max = 100 },
        @{ id = "obj-446"; name = "fill target"; value = 4; min = 0; max = 4 },
        @{ id = "obj-450"; name = "morph knob"; value = 0; min = 0; max = 100 }
    )

    foreach ($entry in $defaults) {
        $box = Find-Box $patcher $entry.id
        if ($box) {
            Set-ParameterDefault $box $entry.name $entry.value $entry.min $entry.max
        }
    }
}

$resolved = Resolve-Path -LiteralPath $Path
$bytes = [System.IO.File]::ReadAllBytes($resolved)
$isAmxd = $bytes.Length -gt 32 -and [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq "ampf"

if ($isAmxd) {
    $device = Get-DeviceJson $bytes
    Apply-Defaults $device.Json
    $json = $device.Json | ConvertTo-Json -Depth 100 -Compress
    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $suffixStart = $device.End + 1
    $suffixLength = $bytes.Length - $suffixStart
    $backup = "$resolved.bak-params-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $resolved -Destination $backup

    $out = New-Object byte[] (32 + $jsonBytes.Length + $suffixLength)
    [Array]::Copy($bytes, 0, $out, 0, 32)
    [Array]::Copy($jsonBytes, 0, $out, 32, $jsonBytes.Length)
    if ($suffixLength -gt 0) {
        [Array]::Copy($bytes, $suffixStart, $out, 32 + $jsonBytes.Length, $suffixLength)
    }
    $chunkLengthBytes = [BitConverter]::GetBytes([uint32]($out.Length - 32))
    [Array]::Copy($chunkLengthBytes, 0, $out, 28, 4)
    [System.IO.File]::WriteAllBytes($resolved, $out)
    Write-Host "Patched AMXD: $resolved"
    Write-Host "Backup: $backup"
} else {
    $doc = Get-Content -LiteralPath $resolved -Raw | ConvertFrom-Json
    Apply-Defaults $doc
    $doc | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $resolved -Encoding UTF8
    Write-Host "Patched maxpat: $resolved"
}
