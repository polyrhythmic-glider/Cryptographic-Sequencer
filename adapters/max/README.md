# Max Adapter

Questa cartella contiene la parte Max for Live del progetto.

Su Linux possiamo compilare e testare `cryptoseq_max_model`, che non dipende dalla Max SDK. Questo model rappresenta lo stato e i comandi dell'oggetto Max:

- `source`
- `p`
- `q`
- `length`
- `root`
- `mode`
- `generate`
- `dump`
- `step`

Il file `src/cryptoseq_max_external.c` è lo scheletro dell'external Max reale. Richiede gli header della Cycling '74 Max SDK (`ext.h`, `ext_obex.h`) e va compilato su macOS o Windows.

Output previsto dall'external:

```text
event step active note velocity accent duration gate value
```

Esempio di messaggi Max:

```text
source "demo source"
p 251
q 257
length 16
mode hybrid
root 60
generate
step 0
dump
```

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
