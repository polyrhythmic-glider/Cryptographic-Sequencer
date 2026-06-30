param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd",
    [string[]]$ObjectId = @()
)

$ErrorActionPreference = "Stop"

function Get-AmxdJson {
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

    return $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
}

$bytes = [System.IO.File]::ReadAllBytes($AmxdPath)
$json = Get-AmxdJson $bytes

@($json.patcher.lines) | ForEach-Object {
    $line = $_.patchline
    if (-not $line) {
        return
    }

    $source = $line.source
    $destination = $line.destination
    $match = $ObjectId.Count -eq 0
    if ($source -and $ObjectId -contains $source[0]) {
        $match = $true
    }
    if ($destination -and $ObjectId -contains $destination[0]) {
        $match = $true
    }

    if ($match) {
        [pscustomobject]@{
            source = if ($source) { "$($source[0]):$($source[1])" } else { "" }
            destination = if ($destination) { "$($destination[0]):$($destination[1])" } else { "" }
            order = $line.order
            hidden = $line.hidden
        }
    }
}
