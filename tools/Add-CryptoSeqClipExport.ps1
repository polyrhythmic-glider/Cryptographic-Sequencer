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

function Find-Box($Patcher, [string]$Id) {
    foreach ($boxWrapper in @($Patcher.boxes)) {
        if ($boxWrapper.box.id -eq $Id) {
            return $boxWrapper.box
        }
    }
    return $null
}

function Add-BoxIfMissing($Patcher, $Box) {
    if (-not (Has-Box $Patcher $Box.box.id)) {
        $Patcher.boxes += $Box
    }
}

function Set-BoxProps($Box, $Props) {
    if ($null -eq $Box) {
        return
    }
    foreach ($key in $Props.Keys) {
        Add-Or-Set $Box $key $Props[$key]
    }
}

function Copy-ExistingRect($Box, $Props, [string]$Name) {
    if ($null -ne $Box -and $Box.PSObject.Properties[$Name]) {
        if ($Name -eq "presentation_rect" -and [double]$Box.$Name[0] -gt 1000.0) {
            return
        }
        $Props[$Name] = @($Box.$Name)
    }
}

function Get-LinePayload($LineWrapper) {
    if ($LineWrapper.PSObject.Properties["patchline"]) {
        return $LineWrapper.patchline
    }
    return $LineWrapper
}

function Line-Matches($LineWrapper, [string]$Source, [int]$SourceOutlet, [string]$Destination, [int]$DestinationInlet) {
    $line = Get-LinePayload $LineWrapper
    if (-not $line.source -or -not $line.destination) {
        return $false
    }

    return $line.source[0] -eq $Source -and
        [int]$line.source[1] -eq $SourceOutlet -and
        $line.destination[0] -eq $Destination -and
        [int]$line.destination[1] -eq $DestinationInlet
}

function Add-LineIfMissing($Patcher, $Line) {
    $line = Get-LinePayload $Line
    $exists = $Patcher.lines | Where-Object {
        Line-Matches $_ $line.source[0] ([int]$line.source[1]) $line.destination[0] ([int]$line.destination[1])
    }
    if (-not $exists) {
        $next = New-Object System.Collections.ArrayList
        foreach ($lineWrapper in @($Patcher.lines)) {
            [void]$next.Add($lineWrapper)
        }
        [void]$next.Add([pscustomobject]@{ patchline = $line })
        $Patcher.lines = @($next)
    }
}

function Remove-Line($Patcher, [string]$Source, [int]$SourceOutlet, [string]$Destination, [int]$DestinationInlet) {
    $kept = New-Object System.Collections.ArrayList
    foreach ($lineWrapper in @($Patcher.lines)) {
        if (Line-Matches $lineWrapper $Source $SourceOutlet $Destination $DestinationInlet) {
            continue
        }
        [void]$kept.Add($lineWrapper)
    }
    $Patcher.lines = @($kept)
}

function Move-PresentationControlsBeforePanels($Patcher) {
    $panelClasses = @("jsui", "fpic")
    $controlClasses = @("button", "toggle", "dial", "number", "flonum", "umenu", "comment", "message", "live.dial", "live.numbox", "live.menu", "live.text")
    $controls = @($Patcher.boxes | Where-Object { $_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass })
    $panels = @($Patcher.boxes | Where-Object { $_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass })
    $middle = @($Patcher.boxes | Where-Object {
        -not ($_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $controlClasses -contains $_.box.maxclass) -and
        -not ($_.box.PSObject.Properties["presentation"] -and $_.box.presentation -eq 1 -and $panelClasses -contains $_.box.maxclass)
    })
    $Patcher.boxes = @($controls + $middle + $panels)
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
    $buttonProps = [ordered]@{
        maxclass = "button"; numinlets = 1; numoutlets = 1; outlettype = @("bang")
        parameter_enable = 0; patching_rect = @(310.0, 134.0, 24.0, 24.0)
        presentation = 1; presentation_rect = @(204.0, 133.593223571777344, 24.0, 24.0)
        hidden = 0
    }
    $labelProps = [ordered]@{
        maxclass = "comment"; text = "export"; numinlets = 1; numoutlets = 0
        patching_rect = @(340.0, 137.0, 50.0, 20.0)
        presentation = 1; presentation_rect = @(230.0, 135.593223571777344, 50.0, 20.0)
        hidden = 0
    }
    $statusProps = [ordered]@{
        maxclass = "comment"; text = "export ready"; numinlets = 1; numoutlets = 0
        patching_rect = @(2410.0, 760.0, 95.0, 20.0)
        presentation = 1; presentation_rect = @(204.0, 157.0, 95.0, 12.0)
        hidden = 0
    }

    $button = Find-Box $patcher "obj-460"
    $label = Find-Box $patcher "obj-461"
    $status = Find-Box $patcher "obj-466"
    Copy-ExistingRect $button $buttonProps "presentation_rect"
    Copy-ExistingRect $button $buttonProps "patching_rect"
    Copy-ExistingRect $label $labelProps "presentation_rect"
    Copy-ExistingRect $label $labelProps "patching_rect"
    Copy-ExistingRect $status $statusProps "presentation_rect"
    Copy-ExistingRect $status $statusProps "patching_rect"
    Add-BoxIfMissing $patcher (New-Box "obj-460" $buttonProps)
    Add-BoxIfMissing $patcher (New-Box "obj-461" $labelProps)
    Add-BoxIfMissing $patcher (New-Box "obj-466" $statusProps)
    Set-BoxProps (Find-Box $patcher "obj-460") $buttonProps
    Set-BoxProps (Find-Box $patcher "obj-461") $labelProps
    Set-BoxProps (Find-Box $patcher "obj-466") $statusProps
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
        maxclass = "newobj"; text = "delay 250"; numinlets = 2; numoutlets = 1; outlettype = @("bang")
        patching_rect = @(2280.0, 700.0, 70.0, 22.0)
    }))
    Set-BoxProps (Find-Box $patcher "obj-464") ([ordered]@{ text = "delay 250" })
    Add-BoxIfMissing $patcher (New-Box "obj-465" ([ordered]@{
        maxclass = "message"; text = "exportclip"; numinlets = 2; numoutlets = 1; outlettype = @("")
        patching_rect = @(2280.0, 730.0, 75.0, 22.0)
    }))

    Remove-Line $patcher "obj-460" 0 "obj-463" 0
    Remove-Line $patcher "obj-463" 0 "obj-219" 0
    Remove-Line $patcher "obj-460" 0 "obj-464" 0
    Remove-Line $patcher "obj-464" 0 "obj-465" 0
    Remove-Line $patcher "obj-465" 0 "obj-462" 0
    Remove-Line $patcher "obj-219" 0 "obj-462" 0
    Remove-Line $patcher "obj-2" 0 "obj-462" 0
    Remove-Line $patcher "obj-38" 0 "obj-462" 0
    Remove-Line $patcher "obj-98" 0 "obj-462" 0
    Remove-Line $patcher "obj-462" 0 "obj-466" 0

    Add-LineIfMissing $patcher (New-Line "obj-460" 0 "obj-463" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-463" 0 "obj-219" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-460" 0 "obj-464" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-464" 0 "obj-465" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-465" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-219" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-2" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-38" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-98" 0 "obj-462" 0 $true)
    Add-LineIfMissing $patcher (New-Line "obj-462" 0 "obj-466" 0 $true)
    Move-PresentationControlsBeforePanels $patcher
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
