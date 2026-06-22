# CRYPTOSEQALFA0.1

Windows alpha build of the Cryptoseq Max for Live MIDI sequencer.

This folder is for hand distribution to trusted testers. It does not replace `CRYPTOSEQALFA0.0`.

## What Is Included

- `externals/cryptoseq.mxe64`: Windows x64 Max external.
- `javascript/*.js`: UI, MIDI, source, RSA, mode, and sequence helpers.
- `patchers/cryptoseq-midi-ui.maxpat`: editable Max patcher source for the 0.1 device.

## New In 0.1

- Four-part UI: source preview, RSA formula, mode controls, sequence monitor.
- File button plus drag/drop file input.
- Wide prime range up to 65521, with `p != q` and automatic valid `e`.
- Length knob from 1 to 128 steps.
- Density active in all modes.
- Melodic mode uses root/scale/range; hybrid uses Drum Rack pads from root; rhythm uses one root trigger.

The source preview is intentionally lightweight in this alpha: it detects common image/audio/video/file extensions and draws a compact visual fingerprint. It does not decode the actual image or waveform yet.

## Modular Patcher Variant

`CryptoSeqALFA0.1-modular.amxd` keeps the same behavior but makes the editable Max patcher more readable:

- patchcords are hidden in the top-level editor;
- the patch opens in presentation mode;
- implementation objects are arranged into labelled blocks: init/defaults, UI router, source/parameter adapters, engine/clock, event monitor/MIDI out.

The next deeper cleanup is to extract these labelled blocks into true reusable Max abstractions or bpatchers.

## Install As A Max Package

Copy the whole `Cryptographic-Sequencer` package folder from this release into:

```text
Documents\Max 8\Packages\
```

Then restart Ableton Live / Max and open:

```text
Cryptographic-Sequencer\patchers\cryptoseq-midi-ui.maxpat
```

To make a shareable `.amxd`, open the patcher as a Max MIDI Effect, save it as a device, then use Max for Live Freeze so the JS files and external are embedded.

## Quick Test

1. Put the device on a MIDI track before an instrument or Drum Rack.
2. Load or drag a file into the source area.
3. Leave `p=251`, `q=257`, `mode=hybrid`, `length=16`.
4. Press `generate`, then `play`.
5. Watch the sequence monitor and confirm MIDI notes are emitted.

If Max reports `cryptoseq: No such object`, it cannot find `externals\cryptoseq.mxe64`. If it reports missing JS files, keep the package folder structure intact or freeze the device again.
