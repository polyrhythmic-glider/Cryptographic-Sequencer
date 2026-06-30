# Max Adapter

Questa cartella contiene la parte Max for Live del progetto.

Il patcher principale e' `patchers/cryptoseq-midi-ui.maxpat`. I blocchi riusabili sono astrazioni Max esterne nella stessa cartella:

- `cryptoseq_auto_setup.maxpat`: inoltra i comandi all'external e manda un `setup` ritardato dopo i cambi parametro.
- `cryptoseq_clock.maxpat`: clock sincronizzato a Live, counter, modulo lunghezza e messaggi `step`.
- `cryptoseq_engine.maxpat`: patch motore che contiene external `cryptoseq`, auto-setup, clock, gate di performance e MIDI out.
- `cryptoseq_live_scale.maxpat`: aspetta `live.thisdevice`, legge gli intervalli della scala Live e produce `livescale ...`.
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

## Flusso eventi e MIDI

L'external emette sempre messaggi nel formato:

```text
event step active note velocity accent duration gate value
```

Nel patcher UI questo stream viene usato in due modi:

- `setup`, `generate`, `dump` e `bang` possono emettere l'intero pattern per aggiornare la visualizzazione;
- `step <n>` emette un solo evento e viene usato dal clock per il playback MIDI.
- il pulsante `export` manda un `dump`, raccoglie gli eventi correnti e scrive una clip MIDI nel clip slot evidenziato di Ableton Live.

`cryptoseq_engine.maxpat` separa questi due percorsi. Gli eventi bulk vanno al monitor della sequenza ma non al MIDI. Per il playback, `cryptoseq_clock.maxpat` emette il messaggio interno `playstep <n>`; l'external risponde con `playevent ...`, e solo quel ramo raggiunge `cryptoseq_midi_out.maxpat`. Questa e' la protezione che evita raffiche di note quando si muovono controlli come `scene`, `p`, `q`, density o morph. Il messaggio pubblico `step <n>` resta disponibile e continua a emettere un normale `event ...` per test e debug.

Lo step timing segue Live tramite `metro 16n @active 1`. Il layer MIDI calcola la durata delle note da divisione, `duration` e `gate` senza interrogare direttamente la Live API durante il playback; questo evita errori `Live API is not initialized` quando il device viene caricato.

Per esportare come clip MIDI: seleziona/clicca un clip slot MIDI vuoto nella stessa traccia o nella destinazione desiderata, poi premi `export` nel device. Se lo slot e' vuoto, viene creata una clip lunga quanto il pattern; se contiene gia' una clip, le note selezionate vengono rimpiazzate dal pattern CryptoSeq.

## Funzioni 0.2

`scene <0..127>` cambia il seed di generazione insieme a source, `p`, `q`, `e` e indice dello step. Serve per ottenere variazioni parallele della stessa sorgente senza cambiare file o primi.

Il layer MIDI supporta ratchet/fill senza cambiare il formato evento dell'external:

- `ratchetamount <0..100>`: probabilita'/quantita' di ratchet.
- `ratchetmax <1..8>`: massimo numero di ripetizioni interne allo step.
- `fillamount <0..100>`: intensita' del fill.
- `fillmode off|end|accent|velocity|all`: sceglie dove o perche' il fill entra.
- `filltarget density|ratchet|velocity|gate|all`: sceglie cosa il fill puo' modificare.

Il morph A/B genera un secondo pattern usando una scena B e fonde i risultati in modo deterministico:

- `morphamount <0..100>`;
- `morphscene <0..127>`;
- `morphmode all|pitch|rhythm|velocity`;
- `morph <amount> [scene_b] [mode]` come scorciatoia.

Con `morphamount 100` e `morphmode all`, il risultato corrisponde alla scena B. Con valori intermedi, note, velocity, durata e gate vengono interpolati in modo deterministico; `active` e `accent` restano discreti e usano una maschera deterministica.

Nel pannello performance della UI i controlli sono:

- `scene`: scena principale A, `0..127`;
- `ratchet %`: quantita'/probabilita' di ratchet;
- `max`: massimo numero di ripetizioni interne allo step;
- `fill amount`: intensita' del fill;
- `fill mode`: strategia di fill, tra `off`, `end`, `accent`, `velocity`, `all`;
- `fill target`: dimensione modificata dal fill, tra `density`, `ratchet`, `velocity`, `gate`, `all`;
- `morph %`: percentuale di fusione verso il pattern B;
- `scene B`: scena usata per generare il pattern B;
- `mode`: modo del morph, tra `all`, `pitch`, `rhythm`, `velocity`.

`scaleintervals` accetta una lista di intervalli cromatici, per esempio `scaleintervals 0 2 4 5 7 9 11`. La patch Max for Live usa questo messaggio per ereditare la scala globale di Ableton Live: `cryptoseq_live_scale.maxpat` aspetta che `live.thisdevice` segnali l'inizializzazione del device, poi legge gli intervalli Live e li passa al bridge JavaScript. La root resta un controllo locale del device.

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

## Cosa possiamo fare fuori da Max

- Testare il core C.
- Testare il model dell'adapter Max.
- Definire messaggi, stato e formato eventi.
- Preparare il codice sorgente dell'external.

## Cosa va verificato in Max/Ableton

- Il device `.amxd` si carica senza `Device file broken`.
- L'oggetto `cryptoseq` viene trovato dal package installato.
- Il clock Live fa avanzare gli step e produce note MIDI.
- Cambiare parametri rigenera la visualizzazione senza suonare l'intero pattern.
- I controlli 0.2 sono visibili nel pannello performance e modificano la sequenza in modo riproducibile.

## Build Windows con Max SDK

Prerequisiti:

- CMake 3.25 o superiore disponibile nel `PATH`.
- Visual Studio 2022 o Visual Studio Build Tools con workload Desktop development with C++.
- Cycling '74 Max SDK disponibile localmente, per esempio in `C:\dev\max-sdk`.

L'SDK Cycling '74 corrente scarica `max-sdk-base` durante la configurazione CMake. Quel pacchetto contiene header, librerie e target importato `Max::Max` usati da questo progetto.

Configura e compila da Developer PowerShell o Developer Command Prompt:

```powershell
cmake -S . -B build-max -G "Visual Studio 17 2022" -A x64 `
  -DCRYPTOSEQ_BUILD_MAX_EXTERNAL=ON `
  -DMAX_SDK_ROOT="C:\dev\max-sdk"

cmake --build build-max --config Release --target cryptoseq_max_external
```

Il target CMake si chiama `cryptoseq_max_external`, ma l'oggetto Max generato si chiama `cryptoseq.mxe64`.

Se CMake non riesce a scaricare `max-sdk-base`, clonalo localmente e passa `MAX_SDK_BASE_ROOT`:

```powershell
git clone https://github.com/Cycling74/max-sdk-base.git C:\dev\max-sdk-base

cmake -S . -B build-max -G "Visual Studio 17 2022" -A x64 `
  -DCRYPTOSEQ_BUILD_MAX_EXTERNAL=ON `
  -DMAX_SDK_ROOT="C:\dev\max-sdk" `
  -DMAX_SDK_BASE_ROOT="C:\dev\max-sdk-base"
```

Se `MAX_SDK_ROOT` viene omesso, CMake controlla anche le variabili ambiente `MAX_SDK_ROOT` e `MAXSDK_ROOT`.

## Installare l'external in Max

Durante lo sviluppo, metti il file compilato dove Max puo' trovare gli external. Una struttura package semplice e':

```text
Documents\Max 8\Packages\Cryptographic-Sequencer\externals\cryptoseq.mxe64
```

Riavvia Max dopo la copia, oppure aggiorna file browser/search path di Max. Poi crea un object box chiamato:

```text
cryptoseq
```

## Checklist patch Max minimale

Questo repository include due patch pronte da aprire:

- `patchers/cryptoseq-test.maxpat`: smoke test minimale per eventi/MIDI.
- `patchers/cryptoseq-midi-ui.maxpat`: UI 0.2 suonabile con file source, menu dei primi, controlli specifici per modalita', monitor della sequenza, pannello performance, knob length, shift, toggle poly melodico e divisione. La UI e' armata automaticamente; in presentation non ci sono bottoni generate/play.

La patch UI invia un `setup` debounced poco dopo i cambi parametro, cosi' il playback non continua a usare una sequenza vecchia. `setup` aggiorna anche il monitor della sequenza, ma `cryptoseq_engine.maxpat` tiene chiuso il gate MIDI per quegli eventi bulk. Il playback e' armato al caricamento, quindi il device segue il clock di Live senza bottoni generate/play separati nella UI. Inoltre mantiene `p` e `q` diversi e invia `rsa p q e` in modo atomico dopo aver filtrato il menu `e` su esponenti stile RSA coprimi con `phi(n) = (p - 1)(q - 1)`.

I controlli esposti in UI sono parametri Live con `parameter_initial_enable = 1`: in Ableton il doppio click torna al valore di default del device appena aperto. I valori non vengono piu' forzati da messaggi hardcoded su `loadbang`; al caricamento il patcher aspetta il ripristino dei parametri Live e poi sincronizza verso il motore i valori correnti dei controlli. In questo modo un set salvato con impostazioni specifiche del device deve riaprirsi con le stesse impostazioni.

Il controllo length della UI e' un knob da 1 a 128 step. Anche i messaggi manuali `length` in questo percorso UI sono limitati a 1..128.

L'helper MIDI legge la divisione selezionata, poi applica `duration` e `gate` dell'evento alla durata nota inviata a `makenote`. Lo scheduling degli step resta sincronizzato a Live nel clock Max; il JS MIDI non interroga direttamente la Live API durante il playback.

La UI ha cinque aree di presentation:

- anteprima source, con bottone file e input drag/drop;
- pannello RSA, con controlli p/q/e e visualizzazione formula `n`, `phi(n)`, `gcd(e, phi)`;
- pannello mode, con controlli nascosti o mostrati per melodic, hybrid e rhythm, incluso toggle `poly` solo per melodic;
- monitor della sequenza, pilotato dall'output reale `event` dell'external;
- pannello performance 0.2, con `scene`, `ratchet amount`, `ratchet max`, `fill mode`, `fill target`, `morph amount`, `morph scene B` e `morph mode`.

Crea una patch Max con un oggetto `cryptoseq` e collega il suo outlet a `print cryptoseq`.

Il messaggio `source` accetta sia un singolo simbolo sia piu' atomi uniti come testo.

Invia questi messaggi:

```text
source demo source
rsa 251 257 65537
length 16
mode melodic
root 60
melodyrange 60 84
generate
```

Formato atteso nella console Max:

```text
event step active note velocity accent duration gate value
```

Controlli manuali richiesti dentro Max o Ableton Live:

- L'object box `cryptoseq` si crea senza "no such object".
- `generate` emette 16 messaggi `event`.
- `step 0` emette solo il primo evento.
- `dump` e `bang` emettono la sequenza generata corrente.
- Nel device UI, muovere un parametro aggiorna il monitor ma non deve suonare tutte le note.
