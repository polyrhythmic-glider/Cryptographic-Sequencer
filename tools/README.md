# Pipeline AMXD CryptoSeq

Usa `Update-CryptoSeqAmxd.ps1` per gli interventi diretti sul device Ableton,
`Patch-CryptoSeqAmxdControls.ps1` per i controlli di performance, e
`Set-CryptoSeqParameterPersistence.ps1` quando vengono aggiunti o modificati
parametri Live che devono avere default e salvataggio affidabili. Usa
`Add-CryptoSeqCrtSplit.ps1` quando va aggiunto o ripristinato il controllo
CRT Split nei patcher/AMXD di release. Usa
`Install-CryptoSeqAbletonPreset.ps1` per reinstallare il preset visibile in
Ableton e allineare il package Max. Usa `Test-CryptoSeqRelease.ps1` prima di
consegnare una build:

```powershell
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode Inspect
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchAutostart
powershell -ExecutionPolicy Bypass -File tools/Update-CryptoSeqAmxd.ps1 -Mode PatchUiFinish
powershell -ExecutionPolicy Bypass -File tools/Patch-CryptoSeqAmxdControls.ps1 -Path "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
powershell -ExecutionPolicy Bypass -File tools/Add-CryptoSeqCrtSplit.ps1
powershell -ExecutionPolicy Bypass -File tools/Set-CryptoSeqParameterPersistence.ps1 -Path "C:\Users\asus\Documents\Ableton\User Library\Presets\MIDI Effects\Max MIDI Effect\CryptoSeqALFA0.1-modular.amxd"
powershell -ExecutionPolicy Bypass -File tools/Test-CryptoSeqRelease.ps1
powershell -ExecutionPolicy Bypass -File tools/Install-CryptoSeqAbletonPreset.ps1 -ArchiveOtherCryptoSeqPresets
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
- Nella cartella Ableton `Max MIDI Effect` deve restare un solo preset
  CryptoSeq visibile: `CryptoSeqALFA0.1-modular.amxd`. I backup `.amxd` nella
  stessa cartella vengono mostrati dal browser di Ableton come device diversi
  e possono far caricare versioni vecchie.
- Se il preset Ableton attivo e' stato modificato a mano in Max, trattalo come
  sorgente di verita' per il layout UI: ispezionalo, poi copia l'intero `.amxd`
  attivo sopra gli `.amxd` di release. Non rilanciare `Install-*` prima di
  averlo promosso, altrimenti la release vecchia sovrascrive il lavoro manuale.

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

`Install-CryptoSeqAbletonPreset.ps1` applica la release corrente alla macchina
di test:

- copia `release/CRYPTOSEQALFA0.1/CryptoSeqALFA0.1-modular.amxd` nella User
  Library di Ableton;
- se richiesto con `-ArchiveOtherCryptoSeqPresets`, sposta fuori dal browser
  Ableton tutte le altre copie `CryptoSeq*.amxd`;
- riallinea `javascript/`, `patchers/` ed eventuale external nel package Max;
- salva i backup dentro `backups/ableton-presets-<timestamp>`.

Se cambia solo un file JavaScript e vuoi preservare il layout `.amxd` attivo,
copia solo quel JS nel package Max invece di reinstallare il preset.
