# CryptoSeq AMXD pipeline

Use `Update-CryptoSeqAmxd.ps1` for direct edits to the Ableton device:

```powershell
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode Inspect
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchAutostart
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchUiFinish
```

Rules:

- Direct `.amxd` patches must update the internal `ptch` chunk length when the file length changes.
- The script backs up before writing unless `-NoBackup` is passed.
- Length-changing UI edits belong in Max, then the device must be saved/frozen by Max.
- Do not copy a `.maxpat` over an `.amxd`.

The current autostart patch is length-preserving:

- `delay 50` -> `delay 99`
- `obj-218` load order `7` -> `9`

This keeps the hidden start message after the setup burst without changing the AMXD chunk size.

`PatchUiFinish` is allowed to change file length because it rewrites the `ptch` chunk length:

- adds editable value boxes for `length`, `density`, and `shift`;
- expands the source image layer to the full source panel;
- sets `forceaspect 0` on the source image so the image fills the panel.
