# CryptoSeq Release Checklist

Run this before sharing a build.

```powershell
powershell -ExecutionPolicy Bypass -File tools\Test-CryptoSeqRelease.ps1
```

Then install the release preset:

```powershell
powershell -ExecutionPolicy Bypass -File tools\Install-CryptoSeqAbletonPreset.ps1 -ArchiveOtherCryptoSeqPresets
```

Manual Ableton checks:

- Load a fresh device. If Live was open during install, remove/reinsert it.
- Hybrid CRT demo: pad count 16, density 100, ratchet 0, fill off, morph 0.
- Compare CRT Split `off`, `p_pitch_q_rhythm`, `p_rhythm_q_pitch`.
- Press `export` with a MIDI clip slot selected; status should become
  `exported <n>`, the clip should contain visible MIDI notes, and the clip
  name should include mode, scene, and CRT Split.
- While playback runs, move morph. It should feel immediate.
- Send `stats` to `cryptoseq_engine_router.js` only when diagnosing lag.

Do not copy a `.maxpat` over an `.amxd`. AMXD edits must go through `tools/`.
