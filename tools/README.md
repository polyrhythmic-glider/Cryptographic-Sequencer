# Pipeline AMXD CryptoSeq

Usa `Update-CryptoSeqAmxd.ps1` per gli interventi diretti sul device Ableton,
`Patch-CryptoSeqAmxdControls.ps1` per i controlli di performance, e
`Set-CryptoSeqParameterPersistence.ps1` quando vengono aggiunti o modificati
parametri Live che devono avere default e salvataggio affidabili:

```powershell
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode Inspect
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchAutostart
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchUiFinish
powershell -ExecutionPolicy Bypass -File tools/Patch-CryptoSeqAmxdControls.ps1 -Path "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
powershell -ExecutionPolicy Bypass -File tools/Set-CryptoSeqParameterPersistence.ps1 -Path "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
```

Regole:

- Un `.amxd` non e' JSON puro. E' un contenitore binario `ampf` con chunk
  `ptch`: i byte `0..31` sono header, il byte `32` e' l'inizio del JSON del
  patcher.
- Non eseguire mai `ConvertFrom-Json` sull'intero `.amxd`, ne' sull'intero
  chunk `ptch` se ci sono byte dopo il JSON. Gli script estraggono solo
  l'oggetto JSON bilanciato che parte da offset `32`.
- Le patch dirette su `.amxd` devono aggiornare la lunghezza del chunk `ptch`
  quando cambia la dimensione del file. Il valore a offset `28` e' un uint32
  little-endian uguale a `final_file_length - 32`.
- Non fidarti del fatto che la lunghezza punti solo al JSON: preserva eventuali
  byte dopo l'oggetto JSON e poi aggiorna la lunghezza del chunk.
- Gli script fanno backup prima di scrivere, a meno che venga passato
  `-NoBackup`.
- Non copiare mai un `.maxpat` sopra un `.amxd`.

Regola per default e salvataggio:

- I valori di default dei controlli devono stare in
  `saved_attribute_attributes.valueof.parameter_initial`, con
  `parameter_initial_enable = 1`. Questo e' cio' che permette il reset con
  doppio click.
- Un `loadbang` non deve inviare valori di default ai controlli salvabili,
  perche' puo' sovrascrivere il ripristino del progetto Ableton.
- Se serve inizializzare il motore, usa un delay di sync che manda al motore i
  valori correnti dei controlli, non messaggi hardcoded.

`Set-CryptoSeqParameterPersistence.ps1` applica questa regola:

- rende persistenti anche i menu RSA `p`, `q` ed `e`;
- imposta i default usati da Live per il doppio click;
- scollega i vecchi setter hardcoded da `loadbang`;
- aggiunge un sync ritardato dei valori correnti verso il motore.
