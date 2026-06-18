# CRYPTOSEQ ALFA 0.0

Cryptoseq e' un sequencer MIDI generativo per Ableton Live / Max for Live.

Trasforma una sorgente scelta dall'utente, per esempio testo o file, in una sequenza deterministica usando un motore ispirato a concetti crittografici. A parita' di sorgente e parametri, la sequenza resta uguale; cambiando sorgente, primi RSA o modalita', cambia il pattern.

Questa e' una build alfa privata da provare con pochi producer fidati.

## Contenuto

- `CRYPTOSEQALFA0.0.amxd`: device Max for Live frozen per Windows.

## Requisiti

- Ableton Live 12 Suite o Live con Max for Live.
- Windows x64.
- Max incluso in Ableton.

Questa build e' stata preparata e testata su Windows. Non e' una build macOS.

## Installazione

1. Copia `CRYPTOSEQALFA0.0.amxd` dove tieni i tuoi Max MIDI Effects, oppure trascinalo direttamente in una traccia MIDI di Ableton.
2. Mettilo prima di uno strumento MIDI, per esempio un synth, Drum Rack o sampler.
3. Premi Play in Ableton.
4. Attiva il controllo `play` del device.

Se Ableton mostra un avviso di file Max for Live non firmato o proveniente da un'altra macchina, conferma solo se il file ti e' stato passato direttamente dall'autore.

## Uso Rapido

- `file`: scegli un file dal computer come sorgente generativa.
- `source demo source`: sorgente testuale di default.
- `p prime` / `q prime`: cambiano il comportamento matematico del sequencer.
- `RSA e`: esponente RSA, scelto automaticamente tra valori validi.
- `mode`:
  - `melodic`: per synth, bass, lead, pad; usa root e scala.
  - `hybrid`: per Drum Rack; usa 16 pad consecutivi dalla root, senza scala.
  - `rhythm`: per percussioni singole; usa una sola nota root.
- `root note`: nota base.
- `scale`: scala usata solo in `melodic`.
- `length`: lunghezza della sequenza.
- `division`: divisione ritmica sincronizzata ad Ableton.
- `density`: densita' degli eventi ritmici.
- `generate`: rigenera la sequenza.
- `play`: avvia/ferma il sequencer interno.

## Suggerimenti Musicali

Per strumenti melodici:

1. Usa `mode melodic`.
2. Scegli una `root note`.
3. Scegli una `scale`.
4. Cambia sorgente o file per ottenere nuove frasi.

Per Drum Rack:

1. Usa `mode hybrid`.
2. Imposta `root note` sul primo pad utile del rack, spesso C1 o C3 a seconda del setup.
3. Muovi `density` per aumentare o ridurre il numero di colpi.

Per percussione singola:

1. Usa `mode rhythm`.
2. Scegli la nota della percussione con `root note`.
3. Usa `density` e `division` per trovare il groove.

## Note Alfa

- Il device e' sperimentale.
- Potresti vedere messaggi nella Max Console durante la generazione: non sono necessariamente errori.
- I file sorgente sono accettati fino a 256 MiB.
- Il comportamento e' deterministico: se salvi sorgente e parametri, puoi ritrovare la stessa sequenza.
- Questa build e' pensata per test privati, non per distribuzione pubblica.

## Feedback Utile

Quando dai feedback, segnala:

- versione di Ableton Live;
- sistema operativo;
- se stavi usando `melodic`, `hybrid` o `rhythm`;
- tipo di sorgente usata, per esempio testo, immagine, audio, PDF;
- cosa hai collegato dopo il device, per esempio synth o Drum Rack;
- eventuali messaggi rossi nella Max Console.

