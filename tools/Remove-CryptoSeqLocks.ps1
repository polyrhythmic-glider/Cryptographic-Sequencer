param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

$LockBoxIds = @(
    "obj-413", # locks label
    "obj-414", # pitch label
    "obj-415", # pitch toggle
    "obj-416", # prepend lockpitch
    "obj-417", # rhythm label
    "obj-418", # rhythm toggle
    "obj-419", # prepend lockrhythm
    "obj-420", # velocity label
    "obj-421", # velocity toggle
    "obj-422", # prepend lockvelocity
    "obj-423", # gate label
    "obj-424", # gate toggle
    "obj-425"  # prepend lockgate
)

function Get-EmbeddedJson {
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
        throw "Could not find embedded AMXD JSON patcher."
    }

    [pscustomobject]@{
        Json = $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
        Start = $start
        End = $end
    }
}

function Write-EmbeddedJson {
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

function Ensure-ObjectProperty {
    param($Object, [string]$Name, $Value)

    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
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

function Find-BoxByVarname {
    param($Patcher, [string]$Varname)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.varname -eq $Varname) {
            return $boxWrapper.box
        }
    }
    return $null
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

function Remove-LockObjects {
    param($Patcher)

    $ids = @{}
    foreach ($id in $LockBoxIds) {
        $ids[$id] = $true
    }

    $keptBoxes = New-Object System.Collections.ArrayList
    $removedBoxes = 0
    foreach ($boxWrapper in @($Patcher.boxes)) {
        $id = $boxWrapper.box.id
        if ($id -and $ids.ContainsKey($id)) {
            $removedBoxes += 1
            continue
        }
        [void]$keptBoxes.Add($boxWrapper)
    }
    $Patcher.boxes = @($keptBoxes)

    $keptLines = New-Object System.Collections.ArrayList
    $removedLines = 0
    foreach ($lineWrapper in @($Patcher.lines)) {
        $line = $lineWrapper.patchline
        $sourceId = if ($line -and $line.source) { $line.source[0] } else { "" }
        $destinationId = if ($line -and $line.destination) { $line.destination[0] } else { "" }

        if (($sourceId -and $ids.ContainsKey($sourceId)) -or
            ($destinationId -and $ids.ContainsKey($destinationId))) {
            $removedLines += 1
            continue
        }

        [void]$keptLines.Add($lineWrapper)
    }
    $Patcher.lines = @($keptLines)

    [pscustomobject]@{
        RemovedBoxes = $removedBoxes
        RemovedLines = $removedLines
    }
}

function Set-PerformanceLayoutWithoutLocks {
    param($Patcher)

    Set-Rect (Find-BoxByVarname $Patcher "cs_performance_view") @(1268.0, 0.06, 360.0, 170.0)
    Set-Text (Find-BoxById $Patcher "obj-442") "amount"
    Set-Text (Find-BoxById $Patcher "obj-445") "target"
    Set-Text (Find-BoxById $Patcher "obj-426") "morph"

    Set-Rect (Find-BoxById $Patcher "obj-401") @(1279.0, 30.0, 45.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_scene_number") @(1279.0, 51.0, 44.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-404") @(1332.0, 30.0, 62.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_ratchet_amount_number") @(1332.0, 51.0, 44.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-407") @(1390.0, 30.0, 35.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_ratchet_max_number") @(1390.0, 51.0, 36.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-410") @(1442.0, 30.0, 35.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_fill_mode_menu") @(1442.0, 51.0, 68.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-442") @(1522.0, 30.0, 58.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_fill_amount_number") @(1522.0, 51.0, 44.0, 22.0)

    Set-Rect (Find-BoxById $Patcher "obj-445") @(1279.0, 84.0, 48.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_fill_target_menu") @(1279.0, 105.0, 68.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-426") @(1360.0, 84.0, 50.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_morph_amount_dial") @(1360.0, 105.0, 30.0, 30.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_morph_amount_number") @(1395.0, 109.0, 44.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-429") @(1448.0, 84.0, 55.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_morph_scene_number") @(1448.0, 105.0, 44.0, 22.0)
    Set-Rect (Find-BoxById $Patcher "obj-432") @(1510.0, 84.0, 45.0, 20.0)
    Set-Rect (Find-BoxByVarname $Patcher "cs_morph_mode_menu") @(1510.0, 105.0, 82.0, 22.0)
}

function Update-Patcher {
    param($Document)

    $result = Remove-LockObjects $Document.patcher
    Set-PerformanceLayoutWithoutLocks $Document.patcher
    return $result
}

foreach ($targetPath in $Path) {
    if (-not (Test-Path -LiteralPath $targetPath)) {
        throw "Path not found: $targetPath"
    }

    if (-not $NoBackup) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item -LiteralPath $targetPath -Destination "$targetPath.bak-remove-locks-$timestamp" -Force
    }

    $extension = [System.IO.Path]::GetExtension($targetPath).ToLowerInvariant()
    if ($extension -eq ".amxd") {
        $bytes = [System.IO.File]::ReadAllBytes($targetPath)
        $embedded = Get-EmbeddedJson $bytes
        $result = Update-Patcher $embedded.Json
        $jsonText = $embedded.Json | ConvertTo-Json -Depth 100 -Compress
        Write-EmbeddedJson $targetPath $bytes $embedded.Start $embedded.End $jsonText
    } else {
        $document = Get-Content -LiteralPath $targetPath -Raw | ConvertFrom-Json
        $result = Update-Patcher $document
        $jsonText = $document | ConvertTo-Json -Depth 100
        Set-Content -LiteralPath $targetPath -Value $jsonText -Encoding UTF8
    }

    [pscustomobject]@{
        Path = $targetPath
        RemovedBoxes = $result.RemovedBoxes
        RemovedLines = $result.RemovedLines
    }
}
