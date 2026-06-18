# Max Adapter

Questa cartella contiene la parte Max for Live del progetto.

Su Linux possiamo compilare e testare `cryptoseq_max_model`, che non dipende dalla Max SDK. Questo model rappresenta lo stato e i comandi dell'oggetto Max:

- `source`
- `sourcefile`
- `rsa`
- `p`
- `q`
- `e`
- `length`
- `root`
- `melodyrange`
- `padcount`
- `mode`
- `scale`
- `rhythm`
- `generate`
- `dump`
- `step`

`sourcefile` legge file binari fino a 256 MiB. Se il file supera questo limite, l'external lo rifiuta e stampa un errore nella Max Console; se il caricamento riesce, stampa il numero di byte caricati. I file sono hashati a blocchi, quindi non vengono caricati interamente in RAM.

I modi sono pensati cosi:

- `melodic`: strumenti melodici; usa root, scala e range low/high.
- `hybrid`: Drum Rack; usa timing/velocity ritmici e un numero controllabile di pad consecutivi dalla root, senza scala.
- `rhythm`: percussione singola; usa una sola nota root, senza scala.

`density` e' disponibile in tutte e tre le modalita' e controlla quanti step sono attivi.

Il file `src/cryptoseq_max_external.c` e' l'external Max reale. Richiede gli header della Cycling '74 Max SDK (`ext.h`, `ext_obex.h`) e va compilato su macOS o Windows.

Output previsto dall'external:

```text
event step active note velocity accent duration gate value
```

Esempio di messaggi Max:

```text
source "demo source"
rsa 251 257 65537
length 16
mode hybrid
root 60
padcount 16
generate
step 0
dump
```

I messaggi separati `p`, `q` ed `e` restano supportati per test manuali, ma la UI usa `rsa p q e` per evitare stati intermedi invalidi.

## Cosa possiamo fare su Linux

- Testare il core C.
- Testare il model dell'adapter Max.
- Definire messaggi, stato e formato eventi.
- Preparare il codice sorgente dell'external.

## Cosa resta da fare in Max/Ableton

- Compilare l'external con la Max SDK.
- Verificare caricamento dell'oggetto `cryptoseq` in Max.
- Creare una patch Max for Live che usa l'external.
- Collegare gli eventi generati a MIDI note, gate, velocity e clock Live.
- Impacchettare l'external nel device o in un Max package.

## Windows build with the Max SDK

Prerequisites:

- CMake 3.25 or newer available on `PATH`.
- Visual Studio 2022 or Visual Studio Build Tools with the Desktop development with C++ workload.
- Cycling '74 Max SDK available locally, for example in `C:\dev\max-sdk`.

The current Cycling '74 SDK fetches `max-sdk-base` during CMake configure. That package contains the Max headers, libraries, and imported target `Max::Max` used by this project.

Configure and build from a Developer PowerShell or Developer Command Prompt:

```powershell
cmake -S . -B build-max -G "Visual Studio 17 2022" -A x64 `
  -DCRYPTOSEQ_BUILD_MAX_EXTERNAL=ON `
  -DMAX_SDK_ROOT="C:\dev\max-sdk"

cmake --build build-max --config Release --target cryptoseq_max_external
```

The target is named `cryptoseq_max_external`, but the built Max object is named `cryptoseq.mxe64`.

If CMake cannot fetch `max-sdk-base`, clone it locally and pass `MAX_SDK_BASE_ROOT`:

```powershell
git clone https://github.com/Cycling74/max-sdk-base.git C:\dev\max-sdk-base

cmake -S . -B build-max -G "Visual Studio 17 2022" -A x64 `
  -DCRYPTOSEQ_BUILD_MAX_EXTERNAL=ON `
  -DMAX_SDK_ROOT="C:\dev\max-sdk" `
  -DMAX_SDK_BASE_ROOT="C:\dev\max-sdk-base"
```

If `MAX_SDK_ROOT` is omitted, CMake also checks the `MAX_SDK_ROOT` and `MAXSDK_ROOT` environment variables.

## Installing the external in Max

For development, place the built file where Max can find externals. A simple package layout is:

```text
Documents\Max 8\Packages\Cryptographic-Sequencer\externals\cryptoseq.mxe64
```

Restart Max after copying the file, or refresh Max's file browser/search path. Then create an object box named:

```text
cryptoseq
```

## Minimal Max test patch checklist

This repository includes two ready-to-open patches:

- `patchers/cryptoseq-test.maxpat`: minimal event/MIDI smoke test.
- `patchers/cryptoseq-midi-ui.maxpat`: first playable UI with file source, prime menus, mode, scale, length, division, and play controls.

The UI patch auto-generates shortly after control changes so playback does not keep using a stale sequence. It also keeps `p` and `q` different and sends `rsa p q e` atomically after filtering the `e` menu to RSA-style exponents that are coprime with `phi(n) = (p - 1)(q - 1)`.

The MIDI helper reads the selected division and Live tempo when available, then applies the event `gate` value to the note length sent to `makenote`.

Create a Max patch with one `cryptoseq` object and connect its outlet to `print cryptoseq`.

The `source` message accepts either a single symbol or multiple atoms joined as text.

Send these messages:

```text
source demo source
rsa 251 257 65537
length 16
mode melodic
root 60
melodyrange 60 84
generate
```

Expected output format in the Max console:

```text
event step active note velocity accent duration gate value
```

Manual checks still required inside Max or Ableton Live:

- The object box `cryptoseq` instantiates without "no such object".
- `generate` emits 16 `event` messages.
- `step 0` emits only the first event.
- `dump` and `bang` emit the current generated sequence.
