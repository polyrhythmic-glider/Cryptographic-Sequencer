param(
    [string]$AmxdPath = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd",
    [string]$Pattern = "shift|scene|ratchet|fill|morph|performance|scale 0 254|prepend shift"
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

@($json.patcher.boxes) | ForEach-Object {
    $box = $_.box
    $haystack = @($box.id, $box.varname, $box.text, $box.filename, $box.maxclass) -join " "
    if ($haystack -match $Pattern) {
        [pscustomobject]@{
            id = $box.id
            class = $box.maxclass
            varname = $box.varname
            text = $box.text
            filename = $box.filename
            presentation_rect = ($box.presentation_rect -join ",")
            patching_rect = ($box.patching_rect -join ",")
            initial = ($box.saved_attribute_attributes.valueof.parameter_initial -join ",")
            min = $box.saved_attribute_attributes.valueof.parameter_mmin
            max = $box.saved_attribute_attributes.valueof.parameter_mmax
        }
    }
} | Sort-Object varname,id
