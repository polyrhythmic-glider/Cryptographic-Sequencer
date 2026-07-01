# CryptoSeq Starter Presets

These are small starting points for testing the first release. Set them in the
device UI, then save an Ableton preset if the result is useful.

## Drum Rack CRT Demo

Use when checking that CRT Split is audible and visible.

```text
mode hybrid
root C3
pad count 16
density 100
division 16n
ratchet % 0
max 1
fill off
morph 0
CRT split off / p_pitch_q_rhythm / p_rhythm_q_pitch
```

Expected: the active pads and rhythm change when switching CRT Split modes.

## Minimal Rhythm

Use for timing and lag checks.

```text
mode rhythm
root C1
length 16
density 35
division 16n
ratchet % 0
fill off
morph 0
CRT split off
```

Expected: stable single-lane percussion without scale involvement.

## Melodic Safe

Use for a simple synth or piano.

```text
mode melodic
root C3
scale major
low note C3
high note C5
length 16
density 55
division 16n
ratchet % 0
fill off
morph 0
CRT split off
```

Expected: notes stay in range and follow the selected scale.

## Morph Scene Check

Use when checking that morph is immediate.

```text
mode melodic
root C3
scale minor
length 16
density 65
scene 0
scene B 1
morph mode all
morph 0..100
CRT split off
```

Expected: morph responds immediately while playback continues.
