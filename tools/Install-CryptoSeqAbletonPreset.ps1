param(
    [string]$PresetDir = "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect",
    [string]$PackageDir = "C:\Users\asus\Documents\Max 8\Packages\Cryptographic-Sequencer",
    [string]$SourceAmxd = ".\release\CRYPTOSEQALFA0.1\CryptoSeqALFA0.1-modular.amxd",
    [string]$PresetName = "CryptoSeqALFA0.1-modular.amxd",
    [switch]$ArchiveOtherCryptoSeqPresets
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Copy-RequiredFile {
    param([string]$Source, [string]$Destination)

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Missing source file: $Source"
    }

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

$resolvedPresetDir = Resolve-Path -LiteralPath $PresetDir
$resolvedSourceAmxd = Resolve-Path -LiteralPath $SourceAmxd
$targetAmxd = Join-Path $resolvedPresetDir $PresetName
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path (Resolve-Path -LiteralPath ".") "backups\ableton-presets-$timestamp"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

if (Test-Path -LiteralPath $targetAmxd) {
    Copy-Item -LiteralPath $targetAmxd -Destination (Join-Path $backupRoot $PresetName) -Force
}

if ($ArchiveOtherCryptoSeqPresets) {
    $archiveDir = Join-Path $backupRoot "archived-visible-presets"
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

    Get-ChildItem -LiteralPath $resolvedPresetDir -Filter "CryptoSeq*.amxd" -File |
        Where-Object { $_.Name -ne $PresetName } |
        ForEach-Object {
            Move-Item -LiteralPath $_.FullName -Destination (Join-Path $archiveDir $_.Name) -Force
        }
}

Copy-Item -LiteralPath $resolvedSourceAmxd -Destination $targetAmxd -Force

$javascriptDir = Join-Path $PackageDir "javascript"
$patchersDir = Join-Path $PackageDir "patchers"
$externalsDir = Join-Path $PackageDir "externals"

$jsFiles = @(
    "cryptoseq_clip_export.js",
    "cryptoseq_engine_router.js",
    "cryptoseq_live_scale.js",
    "cryptoseq_midi.js",
    "cryptoseq_mode_view.js",
    "cryptoseq_performance_view.js",
    "cryptoseq_rsa_view.js",
    "cryptoseq_sequence_view.js",
    "cryptoseq_source_view.js",
    "cryptoseq_ui.js"
)

foreach ($file in $jsFiles) {
    $source = Join-Path ".\adapters\max\javascript" $file
    if (Test-Path -LiteralPath $source) {
        Copy-RequiredFile $source (Join-Path $javascriptDir $file)
    }
}

$patcherFiles = @(
    "cryptoseq-midi-ui.maxpat",
    "cryptoseq_clock.maxpat",
    "cryptoseq_engine.maxpat",
    "cryptoseq_live_scale.maxpat",
    "cryptoseq_midi_out.maxpat"
)

foreach ($file in $patcherFiles) {
    $source = Join-Path ".\adapters\max\patchers" $file
    if (Test-Path -LiteralPath $source) {
        Copy-RequiredFile $source (Join-Path $patchersDir $file)
    }
}

$externalSource = ".\build\adapters\max\Release\cryptoseq.mxe64"
if (-not (Test-Path -LiteralPath $externalSource)) {
    $externalSource = ".\release\CRYPTOSEQALFA0.1\Cryptographic-Sequencer\externals\cryptoseq.mxe64"
}
if (Test-Path -LiteralPath $externalSource) {
    Copy-RequiredFile $externalSource (Join-Path $externalsDir "cryptoseq.mxe64")
}

[pscustomobject]@{
    InstalledPreset = $targetAmxd
    SourcePreset = $resolvedSourceAmxd.Path
    BackupRoot = $backupRoot
    ArchivedOtherPresets = [bool]$ArchiveOtherCryptoSeqPresets
    PackageDir = $PackageDir
}
