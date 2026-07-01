param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
)

$ErrorActionPreference = "Stop"

function Get-AmxdJson {
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

    return $text.Substring($start, $end - $start + 1) | ConvertFrom-Json
}

function Get-BoxLabel {
    param($Box)

    if ($Box.varname) {
        return $Box.varname
    }
    if ($Box.text) {
        return $Box.text
    }
    if ($Box.filename) {
        return $Box.filename
    }
    return $Box.maxclass
}

function Inspect-Patcher {
    param(
        $Patcher,
        [string]$Path
    )

    $ids = @{}
    foreach ($boxWrapper in @($Patcher.boxes)) {
        $box = $boxWrapper.box
        if ($box -and $box.id) {
            $ids[$box.id] = Get-BoxLabel $box
        }
    }

    foreach ($lineWrapper in @($Patcher.lines)) {
        if (-not $lineWrapper.PSObject.Properties["patchline"]) {
            [pscustomobject]@{
                Patcher = $Path
                Problem = "malformed patchline"
                ObjectId = ""
                OtherId = ""
                OtherLabel = ""
            }
            continue
        }
        $line = $lineWrapper.patchline
        if (-not $line) {
            continue
        }

        $source = $line.source
        $destination = $line.destination

        if ($source -and -not $ids.ContainsKey($source[0])) {
            [pscustomobject]@{
                Patcher = $Path
                Problem = "missing source"
                ObjectId = $source[0]
                OtherId = if ($destination) { $destination[0] } else { "" }
                OtherLabel = if ($destination -and $ids.ContainsKey($destination[0])) { $ids[$destination[0]] } else { "" }
            }
        }
        if ($destination -and -not $ids.ContainsKey($destination[0])) {
            [pscustomobject]@{
                Patcher = $Path
                Problem = "missing destination"
                ObjectId = $destination[0]
                OtherId = if ($source) { $source[0] } else { "" }
                OtherLabel = if ($source -and $ids.ContainsKey($source[0])) { $ids[$source[0]] } else { "" }
            }
        }
    }

    foreach ($boxWrapper in @($Patcher.boxes)) {
        $box = $boxWrapper.box
        if ($box -and $box.patcher) {
            Inspect-Patcher $box.patcher "$Path/$($box.id):$(Get-BoxLabel $box)"
        }
    }
}

$bytes = [System.IO.File]::ReadAllBytes($AmxdPath)
$json = Get-AmxdJson $bytes
$problems = @(Inspect-Patcher $json.patcher "root")

[pscustomobject]@{
    Path = $AmxdPath
    Boxes = @($json.patcher.boxes).Count
    Lines = @($json.patcher.lines).Count
    Problems = $problems.Count
}

$problems
