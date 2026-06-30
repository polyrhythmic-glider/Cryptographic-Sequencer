param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-Or-Set($Object, [string]$Name, $Value) {
    if ($Object.PSObject.Properties[$Name]) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function New-Box($Id, $Props) {
    $box = [ordered]@{ id = $Id }
    foreach ($key in $Props.Keys) {
        $box[$key] = $Props[$key]
    }
    return [pscustomobject]@{ box = [pscustomobject]$box }
}

function New-Line($Source, [int]$SourceOutlet, $Destination, [int]$DestinationInlet, [bool]$Hidden = $true) {
    return [pscustomobject]@{
        patchline = [pscustomobject]@{
            source = @($Source, $SourceOutlet)
            destination = @($Destination, $DestinationInlet)
            hidden = $Hidden
        }
    }
}

function Get-Patcher($Document) {
    if ($Document.PSObject.Properties["patcher"]) {
        return $Document.patcher
    }
    return $Document
}

function Has-Box($Patcher, [string]$Id) {
    return [bool]($Patcher.boxes | Where-Object { $_.box.id -eq $Id } | Select-Object -First 1)
}

function Add-BoxIfMissing($Patcher, $Box) {
    if (-not (Has-Box $Patcher $Box.box.id)) {
        $Patcher.boxes += $Box
    }
}

function Add-LineIfMissing($Patcher, $Line) {
    $line = $Line.patchline
    $exists = $Patcher.lines | Where-Object {
        if (-not $_.PSObject.Properties["patchline"]) {
            return $false
        }
        $_.patchline.source[0] -eq $line.source[0] -and
        [int]$_.patchline.source[1] -eq [int]$line.source[1] -and
        $_.patchline.destination[0] -eq $line.destination[0] -and
        [int]$_.patchline.destination[1] -eq [int]$line.destination[1]
    }
    if (-not $exists) {
        $Patcher.lines += $Line
    }
}

function Get-DeviceJson {
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
        throw "Could not find embedded AMXD JSON."
    }

    $jsonText = $text.Substring($start, $end - $start + 1)
    return [pscustomobject]@{
        Json = ($jsonText | ConvertFrom-Json)
        Start = $start
        End = $end
    }
}

function Patch-Export($Document) {
    $patcher = Get-Patcher $Document

    Add-BoxIfMissing $patcher (New-Box "obj-460" ([ordered]@{
        maxclass = "button"; numinlets = 1; numoutlets = 1; outlettype = @("bang")
        parameter_enable = 0; patching_rect = @(310.0, 134.0, 24.0, 24.0)
        presentation = 1; presentation_rect = @(255.0, 134.0, 24.0, 24.0)
    }))
    Add-BoxIfMissing $patcher (New-Box "obj-461" ([ordered]@{
        maxclass = "comment"; text = "export"; numinlets = 1; numoutlets = 0
        patching_rect = @(340.0, 137.0, 50.0, 20.0)
        presentation = 1; presentation_rect = @(286.0, 136.0, 50.0, 20.0)
    }))
    Add-BoxIfMissing $patcher (New-Box "obj-462" ([ordered]@{
        maxclass = "newobj"; text = "js cryptoseq_clip_export.js"
        numinlets = 1; numoutlets = 1; outlettype = @("")
        patching_rect = @(2220.0, 760.0, 175.0, 22.0)
    }))
    Add-BoxIfMissing $patcher (New-Box "obj-463" ([ordered]@{
        maxclass = "message"; text = "dump"; numinlets = 2; numoutlets = 1; outlettype = @("")
        patching_rect = @(2220.0, 700.0, 45.0, 22.0)
    }))
    Add-BoxIfMissing $patcher (New-Box "obj-464" ([ordered]@{
        maxclass = "newobj"; text = "delay 100"; numinlets = 2; numoutlets = 1; outlettype = @("bang")
        patching_rect = @(2280.0, 700.0, 70.0, 22.0)
    }))
    Add-BoxIfMissing $patcher (New-Box "obj-465" ([ordered]@{
        maxclass = "message"; text = "exportclip"; numinlets = 2; numoutlets = 1; outlettype = @("")
        patching_rect = @(2280.0, 730.0, 75.0, 22.0)
    }))

    Add-LineIfMissing $patcher (New-Line "obj-460" 0 "obj-463" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-463" 0 "obj-219" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-460" 0 "obj-464" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-464" 0 "obj-465" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-465" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-219" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-2" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-38" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-98" 0 "obj-462" 0 $true)
}

$resolved = Resolve-Path -LiteralPath $Path
$bytes = [System.IO.File]::ReadAllBytes($resolved)
$isAmxd = $bytes.Length -gt 32 -and [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq "ampf"

if ($isAmxd) {
    $device = Get-DeviceJson $bytes
    Patch-Export $device.Json
    $json = $device.Json | ConvertTo-Json -Depth 100 -Compress
    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $suffixStart = $device.End + 1
    $suffixLength = $bytes.Length - $suffixStart
    $backup = "$resolved.bak-export-$(Get-Date -Format yyyyMMdd-HHmmss)"
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
    Patch-Export $doc
    $doc | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $resolved -Encoding UTF8
    Write-Host "Patched maxpat: $resolved"
}
