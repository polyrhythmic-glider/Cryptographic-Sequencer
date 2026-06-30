# Max Adapter

Questa cartella contiene la parte Max for Live del progetto.

Il patcher principale e' `patchers/cryptoseq-midi-ui.maxpat`. I blocchi riusabili sono astrazioni Max esterne nella stessa cartella:

- `cryptoseq_auto_setup.maxpat`: inoltra i comandi all'external e manda un `setup` ritardato dopo i cambi parametro.
- `cryptoseq_clock.maxpat`: clock sincronizzato a Live, counter, modulo lunghezza e messaggi `step`.
- `cryptoseq_engine.maxpat`: patch motore che contiene external `cryptoseq`, auto-setup, clock, gate e MIDI out.
- `cryptoseq_live_scale.maxpat`: osserva `live_set scale_intervals` e produce `livescale ...`.
- `cryptoseq_midi_out.maxpat`: converte gli eventi CryptoSeq in note MIDI.

Su Linux possiamo compilare e testare `cryptoseq_max_model`, che non dipende dalla Max SDK. Questo model rappresenta lo stato e i comandi dell'oggetto Max:

- `source`
- `sourcefile`
- `rsa`
- `p`
- `q`
- `e`
- `length`
- `shift`
- `scene`
- `root`
- `melodyrange`
- `padcount`
- `mode`
- `scale`
- `scaleintervals`
- `rhythm`
- `lock`
- `lockpitch`
- `lockrhythm`
- `lockvelocity`
- `lockgate`
- `morph`
- `morphamount`
- `morphscene`
- `morphmode`
- `setup`
- `generate`
- `dump`
- `step`

`sourcefile` legge file binari fino a 256 MiB. Se il file supera questo limite, l'external lo rifiuta e stampa un errore nella Max Console; se il caricamento riesce, stampa il numero di byte caricati. I file sono hashati a blocchi, quindi non vengono caricati interamente in RAM.

I modi sono pensati cosi:

- `melodic`: strumenti melodici; usa root, scala e range low/high.
- `hybrid`: Drum Rack; usa timing/velocity ritmici e un numero controllabile di pad consecutivi dalla root, senza scala. La root e' il primo pad e resta ancorata allo step-root quando la density e' maggiore di zero.
- `rhythm`: percussione singola; usa una sola nota root, senza scala.

`density` e' disponibile in tutte e tre le modalita' e controlla quanti step sono attivi.

## Funzioni 0.2

`scene <0..127>` cambia il seed di generazione insieme a source, `p`, `q`, `e` e indice dello step. Serve per ottenere variazioni parallele della stessa sorgente senza cambiare file o primi.

Il layer MIDI supporta ratchet/fill senza cambiare il formato evento dell'external:

- `ratchetamount <0..100>`: probabilita'/quantita' di ratchet.
- `ratchetmax <1..8>`: massimo numero di ripetizioni interne allo step.
- `fillmode off|end|accent|velocity`: aumenta la probabilita' di ratchet rispettivamente mai, sugli ultimi step della frase, sugli accenti forti, o sulle velocity alte.

I pattern lock lavorano nel model Max dopo la rigenerazione:

- `lock pitch 0|1` oppure `lockpitch 0|1`;
- `lock rhythm 0|1` oppure `lockrhythm 0|1`;
- `lock velocity 0|1` oppure `lockvelocity 0|1`;
- `lock gate 0|1` oppure `lockgate 0|1`.

Quando un lock e' attivo, il model conserva l'ultimo pattern generato e copia quei campi sul nuovo pattern dopo cambi di source, RSA, scene o morph.

Il morph A/B genera un secondo pattern usando una scena B e fonde i risultati in modo deterministico:

- `morphamount <0..100>`;
- `morphscene <0..127>`;
- `morphmode all|pitch|rhythm|velocity`;
- `morph <amount> [scene_b] [mode]` come scorciatoia.

Con `morphamount 100` e `morphmode all`, il risultato corrisponde alla scena B. Con valori intermedi, una maschera deterministica derivata dai valori generati decide quali step o campi arrivano dal pattern B.

`scaleintervals` accetta una lista di intervalli cromatici, per esempio `scaleintervals 0 2 4 5 7 9 11`. La patch Max for Live usa questo messaggio per ereditare la scala globale di Ableton Live: come Sting 2, osserva `live_set` con `live.path live_set` e `live.observer scale_intervals`, poi passa la lista al bridge JavaScript. La root resta un controllo locale del device.

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
scene 0
shift 0
mode hybrid
root 60
padcount 16
ratchetamount 30
ratchetmax 4
fillmode end
morph 0 1 all
setup
generate
step 0
dump
```

I messaggi separati `p`, `q` ed `e` restano supportati per test manuali, ma la UI usa `rsa p q e` per evitare stati intermedi invalidi.

`shift <n>` ruota circolarmente la sequenza di `n` posizioni verso destra. Gli eventi che escono dalla fine rientrano all'inizio nello stesso ordine; gli indici `step` emessi restano coerenti con la nuova posizione. La UI 0.1 mostra anche il valore numerico dello shift accanto al controllo.

Il toggle `poly` e' un layer MIDI della UI melodica: non cambia la sequenza generata dal core, ma quando la modalita' e' `melodic` trasforma ogni nota attiva in una triade deterministica. In `hybrid` e `rhythm` viene ignorato per non rompere Drum Rack e percussioni.

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
- `patchers/cryptoseq-midi-ui.maxpat`: playable 0.1 UI with file source, prime menus, mode-specific controls, sequence monitor, length knob, shift, melodic poly toggle, and division. The UI is armed automatically; there are no generate/play buttons in presentation.

The UI patch sends a silent, debounced `setup` shortly after control changes so playback does not keep using a stale sequence and does not dump a burst of events. Playback is armed on load, so the device follows the Live clock without separate generate/play UI buttons. It also keeps `p` and `q` different and sends `rsa p q e` atomically after filtering the `e` menu to RSA-style exponents that are coprime with `phi(n) = (p - 1)(q - 1)`.

The UI length control is a knob from 1 to 128 steps. Manual `length` messages in this UI path are also clamped to 1..128.

The MIDI helper reads the selected division and Live tempo when available, then applies the event `gate` value to the note length sent to `makenote`.

The 0.1 UI has four presentation areas:

- source preview, with file button and drag/drop input;
- RSA panel, with p/q/e controls and `n`, `phi(n)`, `gcd(e, phi)` formula display;
- mode panel, with controls hidden or shown for melodic, hybrid, and rhythm, including the melodic-only `poly` toggle;
- sequence monitor, driven by the actual `event` output from the external.

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
