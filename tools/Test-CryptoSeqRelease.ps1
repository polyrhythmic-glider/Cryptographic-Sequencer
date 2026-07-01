param(
    [string]$ReleaseAmxd = "release\CRYPTOSEQALFA0.1\CryptoSeqALFA0.1-modular.amxd"
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param([string]$Label, [scriptblock]$Body)

    Write-Host "== $Label"
    & $Body
}

function Assert-NoBarePatchlines {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        $json = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        $bad = @($json.patcher.lines | Where-Object {
            -not $_.PSObject.Properties["patchline"]
        })
        if ($bad.Count -ne 0) {
            throw "$path has $($bad.Count) malformed patchline entries"
        }
        Write-Host "$path patchlines OK"
    }
}

Invoke-Step "build core/model" {
    cmake --build build --config Release
}

Invoke-Step "test core/model" {
    ctest --test-dir build -C Release --output-on-failure
}

if (Test-Path -LiteralPath "build-max-vs") {
    Invoke-Step "build Max external" {
        cmake --build build-max-vs --config Release --target cryptoseq_max_external
    }
}

Invoke-Step "inspect release AMXD" {
    powershell -ExecutionPolicy Bypass -File tools\Inspect-AmxdPatchcords.ps1 -AmxdPath $ReleaseAmxd
}

Invoke-Step "inspect maxpat patchlines" {
    Assert-NoBarePatchlines @(
        "adapters\max\patchers\cryptoseq-midi-ui.maxpat",
        "release\CRYPTOSEQALFA0.1\patchers\cryptoseq-midi-ui.maxpat",
        "release\max-for-live\patchers\cryptoseq-midi-ui.maxpat",
        "release\CRYPTOSEQALFA0.1\Cryptographic-Sequencer\patchers\cryptoseq-midi-ui.maxpat",
        "release\Cryptographic-Sequencer-MaxPackage\Cryptographic-Sequencer\patchers\cryptoseq-midi-ui.maxpat"
    )
}

Write-Host "Release checks OK"
