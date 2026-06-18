# Cryptoseq Max for Live Release Staging

This folder stages the Max for Live device and package files used while preparing alpha builds.

Current useful contents:

- `CryptoSeqRangeUI.amxd`: development device with melodic note range controls and mode-specific UI visibility.
- `externals/cryptoseq.mxe64`: Windows x64 Max external built from this repo.
- `javascript/cryptoseq_ui.js`: UI helper script.
- `javascript/cryptoseq_midi.js`: event-to-MIDI helper script.
- `patchers/cryptoseq-midi-ui.maxpat`: editable source patcher.

Older `.amxd` files in this folder are kept only as development snapshots. Do not distribute them as the current alpha.

## Single-file `.amxd`

For local development, the device works when Max can find these dependencies through a package or search path.

For sharing, use Max for Live's freeze workflow:

1. Open the `.amxd` in Max from Ableton.
2. Make sure the device works with `cryptoseq.mxe64` available.
3. Use Max's device freeze option so dependencies are collected into the `.amxd`.
4. Save the frozen device under a release name.
5. Test the frozen `.amxd` from a clean Ableton set.

Important: the C external is platform-specific. `cryptoseq.mxe64` is Windows x64 only. A macOS release needs a separately built Max external for macOS.

## Verifying Freeze

To test whether the frozen `.amxd` is really self-contained, do not just rename the package inside `Documents/Max 8/Packages`. Max may still scan that folder.

Move the package completely outside Max's package search path, for example:

```text
Documents/Max 8/Packages/Cryptographic-Sequencer
```

to:

```text
Documents/Cryptographic-Sequencer_DISABLED
```

Then restart Ableton/Max and open only the frozen `.amxd`.

The freeze worked if:

- `cryptoseq` loads without `no such object` or `could not load external`.
- `cryptoseq_ui.js` and `cryptoseq_midi.js` load without missing-file errors.
- Playback still emits notes.
- Max's File Dependencies view does not rely on the removed package folder.

Warnings like "you have multiple files in your search path with the name cryptoseq_ui.js" mean Max can see duplicate copies. Keep one copy in `javascript/` for package releases, or rely on the frozen device's embedded copy for single-file releases.

## Package Distribution

If freezing does not include the external reliably, distribute a Max package instead:

```text
Cryptographic-Sequencer/
  externals/cryptoseq.mxe64
  javascript/cryptoseq_ui.js
  javascript/cryptoseq_midi.js
  patchers/CryptoSeq.amxd
```

Then place the package in:

```text
Documents/Max 8/Packages/
```

## Source Files

`sourcefile` accepts binary files up to 256 MiB. Files above that limit are rejected by the external. Files are hashed in chunks, so they are not loaded into one large RAM buffer.

## Mode-Specific Controls

- `melodic`: uses root, scale, low note, high note, and density. Notes are constrained to the selected scale inside the selected range.
- `hybrid`: uses root as first Drum Rack pad plus pad count and density. Scale is ignored.
- `rhythm`: uses root as the single trigger note plus density. Scale is ignored.

The UI sends `rsa p q e` atomically after prime changes, debounces auto-generation after bursts of parameter changes, and makes MIDI note length follow Live tempo, selected division, event duration, and event gate.
