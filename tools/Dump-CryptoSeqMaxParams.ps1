param(
    [string]$Path = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
)

$ErrorActionPreference = "Stop"

function Get-BalancedJsonText {
    param([string]$Text, [int]$Start)

    $depth = 0
    $inString = $false
    $escape = $false
    $end = -1

    for ($i = $Start; $i -lt $Text.Length; $i += 1) {
        $ch = $Text[$i]

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

    if ($end -lt $Start) {
        throw "Could not find balanced JSON object."
    }

    return $Text.Substring($Start, $end - $Start + 1)
}

function Get-PatcherDocument {
    param([string]$FilePath)

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    if ($extension -eq ".amxd") {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        return Get-BalancedJsonText $text 32 | ConvertFrom-Json
    }

    return Get-Content -LiteralPath $FilePath -Raw | ConvertFrom-Json
}

function Get-ValueOf {
    param($Box)

    if ($Box.saved_attribute_attributes -and $Box.saved_attribute_attributes.valueof) {
        return $Box.saved_attribute_attributes.valueof
    }
    return $null
}

$doc = Get-PatcherDocument $Path

@($doc.patcher.boxes) |
    ForEach-Object { $_.box } |
    Where-Object { $_.parameter_enable -eq 1 } |
    ForEach-Object {
        $valueof = Get-ValueOf $_
        [pscustomobject]@{
            id = $_.id
            class = $_.maxclass
            varname = $_.varname
            text = $_.text
            longname = if ($valueof) { $valueof.parameter_longname } else { "" }
            initial_enable = if ($valueof) { $valueof.parameter_initial_enable } else { "" }
            initial = if ($valueof) { $valueof.parameter_initial -join "," } else { "" }
            min = if ($valueof) { $valueof.parameter_mmin } else { "" }
            max = if ($valueof) { $valueof.parameter_mmax } else { "" }
            rect = $_.presentation_rect -join ","
        }
    } |
    Sort-Object rect,longname,id
