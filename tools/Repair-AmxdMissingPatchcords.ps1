param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd",
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"

function Get-AmxdPatch {
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
    [pscustomobject]@{
        Json = $jsonText | ConvertFrom-Json
        Start = $start
        End = $end
    }
}

function Remove-MissingPatchcords {
    param($Patcher)

    $ids = @{}
    foreach ($boxWrapper in @($Patcher.boxes)) {
        $box = $boxWrapper.box
        if ($box -and $box.id) {
            $ids[$box.id] = $true
        }
    }

    $kept = New-Object System.Collections.ArrayList
    $removed = 0
    foreach ($lineWrapper in @($Patcher.lines)) {
        $line = $lineWrapper.patchline
        $remove = $false

        if ($line) {
            $source = $line.source
            $destination = $line.destination
            if ($source -and -not $ids.ContainsKey($source[0])) {
                $remove = $true
            }
            if ($destination -and -not $ids.ContainsKey($destination[0])) {
                $remove = $true
            }
        }

        if ($remove) {
            $removed += 1
        } else {
            [void]$kept.Add($lineWrapper)
        }
    }

    $Patcher.lines = @($kept)

    foreach ($boxWrapper in @($Patcher.boxes)) {
        $box = $boxWrapper.box
        if ($box -and $box.patcher) {
            $removed += Remove-MissingPatchcords $box.patcher
        }
    }

    return $removed
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

    $chunkLength = [uint32]($out.Length - 32)
    [Array]::Copy([BitConverter]::GetBytes($chunkLength), 0, $out, 28, 4)
    [System.IO.File]::WriteAllBytes($Path, $out)
}

$bytes = [System.IO.File]::ReadAllBytes($AmxdPath)
$patch = Get-AmxdPatch $bytes
$removed = Remove-MissingPatchcords $patch.Json.patcher

if ($removed -gt 0) {
    if (-not $NoBackup) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backup = "$AmxdPath.bak-patchcords-$timestamp"
        Copy-Item -LiteralPath $AmxdPath -Destination $backup -Force
    } else {
        $backup = ""
    }

    $jsonText = $patch.Json | ConvertTo-Json -Depth 100
    Write-AmxdPatch $AmxdPath $bytes $patch.Start $patch.End $jsonText
} else {
    $backup = ""
}

[pscustomobject]@{
    Path = $AmxdPath
    RemovedPatchcords = $removed
    Backup = $backup
}
