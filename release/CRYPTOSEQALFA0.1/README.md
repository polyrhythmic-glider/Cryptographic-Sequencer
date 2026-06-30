# Cryptographic-Sequencer
Sequencer generativo deterministico basato su hashing multimediale e trasformazioni modulari ispirate a RSA, con doppia implementazione: Max for Live e modulo hardware ESP32.

Il progetto ha l'obiettivo di realizzare un sequencer musicale generativo deterministico che, a partire da una sorgente multimediale e da due numeri primi scelti dall'utente, genera sequenze melodiche o ritmiche.

La sorgente viene trasformata tramite hashing in una sequenza numerica di lunghezza controllabile. I valori ottenuti vengono elaborati attraverso una trasformazione modulare ispirata a RSA e infine mappati su strutture musicali discrete: scale, metriche, step, durate, accenti, velocity, gate e CV.

Il progetto prevede due implementazioni principali:

Max for Live device, per generare sequenze MIDI sincronizzate con Ableton Live.
Modulo hardware ESP32, per generare sequenze standalone tramite MIDI, gate, trigger e/o CV.

Il sistema non e' pensato come strumento di sicurezza crittografica, ma come strumento di composizione generativa ispirato a concetti crittografici.

## Roadmap 0.2

Obiettivo generale: trasformare il device da generatore deterministico a sequencer artistico e performativo, mantenendo la riproducibilita' dei risultati. Ogni nuova funzione deve quindi essere controllabile dal musicista, ma anche ricostruibile a parita' di sorgente e parametri.

### 1. Salt / Scene

Aggiungere un parametro `scene` alla generazione della sequenza.

- Il valore `scene` deve entrare nell'input dell'hash insieme a sorgente, `p`, `q`, `e` e indice dello step.
- Lo scopo musicale e' ottenere variazioni parallele della stessa sorgente senza cambiare file o primi.
- La UI deve esporre `Scene` come controllo intero `0..127`.
- Cambiare scena deve rigenerare la sequenza in modo deterministico.

### 2. Ratchet / Fill

Aggiungere ripetizioni interne allo step generate in modo deterministico.

- Il numero di ratchet puo' dipendere da `value`, `accent` o `velocity`.
- Servono controlli per quantita' e massimo numero di ripetizioni.
- UI suggerita: `Ratchet Amount`, `Ratchet Max`, `Fill Mode`.
- `Fill Mode` puo' agire soprattutto sugli ultimi step della frase o della battuta.
- Il playback deve restare sincronizzato a Live: le ripetizioni devono stare dentro la durata dello step.

### 3. Morph A/B

Generare due pattern A e B usando `scene` o salt diversi.

- Aggiungere un controllo `Morph 0..100`.
- Il morph decide quanti step o quanti parametri prendere dal pattern B.
- La scelta deve essere deterministica, usando una maschera derivata da hash.
- Modalita' previste: morph completo, `pitch only`, `rhythm only`, `velocity only`.
- Il morph non deve comportarsi come crossfade casuale: a parita' di parametri deve produrre sempre la stessa sequenza.

# Core C

La repository contiene un primo core C portabile, separato dagli adapter Max for Live ed ESP32. Il core implementa solo la pipeline deterministica:

1. hash SHA-256 della sorgente;
2. espansione hash a contatore;
3. trasformazione modulare ispirata a RSA;
4. mapping musicale in eventi.

La struttura attuale e':

```text
core/
  include/
    cryptoseq.h
  src/
    cryptoseq.c
    cryptoseq_hash.c
    cryptoseq_internal.h
  examples/
    print_sequence.c
  tests/
    test_core.c
adapters/
  max/
    include/
      cryptoseq_max_model.h
    src/
      cryptoseq_max_model.c
      cryptoseq_max_external.c
    tests/
      test_max_model.c
```

Il core e' C99, non usa allocazione dinamica e non dipende da Max, Ableton, ESP-IDF, Arduino, filesystem o MIDI. Gli adapter futuri dovranno occuparsi di I/O, UI, clock, MIDI, gate, trigger e CV.

L'adapter Max e' diviso in due parti:

- `cryptoseq_max_model`: model testabile su Linux, senza Max SDK;
- `cryptoseq_max_external.c`: ponte verso la Max SDK, da compilare su macOS o Windows.

## Build, test e demo

Build standard:

```bash
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
./build/cryptoseq_print_sequence
```

Su Linux questa build compila e testa anche il model dell'adapter Max. Non compila l'external Max reale, perche' gli header e il formato binary target della Max SDK sono specifici dell'ambiente Max/macOS/Windows.

### Windows Max external build

La compilazione dell'external Max reale e' opzionale e mantiene la separazione architetturale esistente:

- `core/` resta il motore deterministico di generazione;
- `cryptoseq_max_model` resta il layer di stato e comandi Max senza dipendenza dalla Max SDK;
- `cryptoseq_max_external.c` e' il bridge specifico per la Cycling '74 Max SDK.

Prerequisiti:

- CMake 3.25 o superiore nel `PATH`, necessario per il target Max external.
- Visual Studio 2022 oppure Visual Studio Build Tools con workload C++ desktop.
- Cycling '74 Max SDK disponibile localmente, per esempio in `C:\dev\max-sdk`.

La SDK Cycling '74 corrente puo' scaricare `max-sdk-base` durante la configurazione CMake. Quel package fornisce header, librerie e target importato `Max::Max`.

Da Developer PowerShell o Developer Command Prompt:

```powershell
cmake -S . -B build-max -G "Visual Studio 17 2022" -A x64 `
  -DCRYPTOSEQ_BUILD_MAX_EXTERNAL=ON `
  -DMAX_SDK_ROOT="C:\dev\max-sdk"

cmake --build build-max --config Release --target cryptoseq_max_external
```

Se CMake non riesce a scaricare `max-sdk-base`, clonalo localmente e aggiungi `-DMAX_SDK_BASE_ROOT="C:\dev\max-sdk-base"` al comando di configurazione.

Il target produce `cryptoseq.mxe64`, esporta `ext_main` e registra in Max la classe `cryptoseq`.

Durante lo sviluppo, copia l'external compilato nella cartella `externals` di un package Max:

```text
Documents\Max 8\Packages\Cryptographic-Sequencer\externals\cryptoseq.mxe64
```

La repository include patch Max gia' apribili:

```text
adapters\max\patchers\cryptoseq-test.maxpat
adapters\max\patchers\cryptoseq-midi-ui.maxpat
```

Riavvia Max, poi crea un oggetto chiamato `cryptoseq` oppure apri una delle patch. Un test manuale minimale deve collegare l'outlet a `print cryptoseq` e inviare:

```text
source demo source
rsa 251 257 65537
length 16
shift 0
mode hybrid
root 60
setup
generate
```

I messaggi attesi dall'outlet usano questo formato:

```text
event step active note velocity accent duration gate value
```

`sourcefile` accetta file binari fino a 256 MiB. I file oltre questo limite vengono rifiutati e l'external segnala l'errore nella Max Console. L'external Max calcola l'hash a blocchi, quindi un file grande non viene copiato in un unico grande buffer RAM.

Intenzione musicale delle modalita' nella UI Max:

- `melodic`: strumenti melodici; root, scala e range di note determinano le altezze.
- `melodic` espone anche controlli `low note` e `high note`; le note generate restano dentro quel range.
- `hybrid`: Drum Rack; usa ritmo, velocity e un numero controllabile di pad a partire dalla root, senza mapping di scala. Il pad viene scelto dal valore generato, non dall'ordine lineare degli step.
- `rhythm`: singola corsia percussiva; una sola root note, senza mapping di scala.

Il menu scala della modalita' melodica puo' usare le scale interne del device oppure `live`. L'opzione `live` prova a seguire gli intervalli della scala globale di Ableton Live solo dopo l'inizializzazione di `live.thisdevice`, poi passa la lista al bridge JavaScript come `scaleintervals`. Viene ereditato il pattern intervallare; la root note resta un controllo locale di CryptoSeq.

La UI Max for Live usa un controllo lunghezza `1..128`, invia `rsa p q e` in modo atomico quando cambiano i primi e invia un `setup` debounced dopo raffiche di modifiche. Quel `setup` rigenera il pattern e aggiorna la visualizzazione; nel patcher UI gli eventi di setup/dump sono separati dal gate MIDI, quindi cambiare parametro non deve suonare tutte le note. Il playback MIDI passa solo dagli eventi prodotti dal clock `step`.

I controlli del device sono parametri Live con default espliciti: in Ableton il doppio click riporta il parametro al valore iniziale del sequencer. Il patcher non usa piu' messaggi di default hardcoded su `loadbang` per i parametri salvabili; dopo il caricamento sincronizza verso il motore i valori correnti dei controlli, cosi' un progetto Live salvato con impostazioni specifiche puo' riaprirsi con le stesse impostazioni.

Il controllo `shift` ruota la sequenza generata di `n` posizioni senza cambiare hash della sorgente o valori RSA. Gli eventi che superano la fine del pattern rientrano all'inizio nello stesso ordine, e gli indici `step` emessi vengono riscritti sulle nuove posizioni. La UI 0.1 mostra anche il valore numerico dello shift accanto al controllo.

Il toggle `poly` e' un layer di uscita MIDI melodica. Non modifica la sequenza deterministica del core; quando la modalita' e' `melodic`, ogni nota attiva viene emessa come triade deterministica. In `hybrid` e `rhythm` viene ignorato, cosi' Drum Rack e percussione singola restano monofonici.

### Flusso eventi nella UI Max for Live

L'external `cryptoseq` ha un solo formato di uscita, `event step active note velocity accent duration gate value`. Lo stesso formato viene usato per due scopi diversi:

- aggiornare la visualizzazione del pattern dopo `setup`, `generate`, `dump` o `bang`;
- suonare il singolo step corrente quando il clock Live manda `step <n>`.

Nel patcher `cryptoseq_engine.maxpat` questi due flussi sono separati. Gli eventi bulk aggiornano il monitor della sequenza ma restano chiusi rispetto al MIDI. Per il playback, il clock usa il messaggio interno `playstep <n>`: l'external risponde con `playevent ...`, che il motore inoltra sia al monitor sia al MIDI. Questa separazione evita raffiche di note quando si cambia un parametro, mentre l'API pubblica `step <n>` continua a emettere il normale `event ...` per test e debug.

Lo step timing e' affidato a `metro 16n @active 1`, quindi segue il transport di Live. Il layer MIDI calcola la durata delle note da divisione, `duration` e `gate`; non interroga direttamente la Live API durante il playback, cosi' evita errori di inizializzazione durante il caricamento del device.

### Funzioni 0.2 implementate

`scene <0..127>` entra nel seed dello step insieme a digest della sorgente, `p`, `q`, `e` e indice. A parita' di file e primi, scene diverse producono variazioni parallele e riproducibili.

Il ratchet/fill e' implementato nel layer MIDI, quindi non cambia il formato evento dell'external:

- `ratchetamount <0..100>` controlla la probabilita'/quantita' di ripetizioni interne allo step;
- `ratchetmax <1..8>` limita il numero massimo di ripetizioni;
- `fillmode off|end|accent|velocity` concentra il fill sugli ultimi step, sugli accenti o sulle velocity alte.

Il morph A/B e' deterministico e usa una seconda scena come pattern B:

- `morphamount <0..100>`;
- `morphscene <0..127>`;
- `morphmode all|pitch|rhythm|velocity`;
- `morph <amount> [scene_b] [mode]`.

Con `morphamount 100` e `morphmode all`, il pattern risultante coincide con la scena B. Con valori intermedi, note, velocity, durata e gate vengono interpolati in modo deterministico; i campi discreti come `active` e `accent` usano ancora una maschera deterministica.

Nel pannello performance della UI:

- `scene`: variazione principale A, da `0` a `127`;
- `ratchet %`: quantita'/probabilita' di ripetizioni interne allo step;
- `max`: limite massimo di ripetizioni per step;
- `fill amount`: intensita' del fill, da `0` a `100`;
- `fill mode`: area o criterio del fill (`off`, `end`, `accent`, `velocity`, `all`);
- `fill target`: dimensione modificata dal fill (`density`, `ratchet`, `velocity`, `gate`, `all`);
- `morph %`: percentuale di fusione tra pattern A e pattern B;
- `scene B`: scena usata per generare il pattern B;
- `mode`: campo del morph da applicare (`all`, `pitch`, `rhythm`, `velocity`).

La UI del patcher Max for Live e' divisa in cinque aree di presentation:

- anteprima della sorgente con pulsante e caricamento file;
- controlli RSA piu' display formula/stato per `n`, `phi(n)` e `gcd(e, phi)`;
- controlli specifici per `melodic`, `hybrid` e `rhythm`, incluso il toggle `poly` solo melodico;
- visualizzazione read-only della sequenza, guidata dal vero stream `event`;
- pannello performance 0.2 con `scene`, ratchet/fill e morph A/B.

Il progetto Max usa ora astrazioni riutilizzabili per la logica di servizio: `cryptoseq_auto_setup.maxpat`, `cryptoseq_clock.maxpat`, `cryptoseq_engine.maxpat`, `cryptoseq_live_scale.maxpat` e `cryptoseq_midi_out.maxpat`. Il patcher principale mantiene i controlli visibili del device e richiama questi moduli invece di incorporare direttamente le loro reti di oggetti.

Build consigliata per misurare performance:

```bash
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release
cmake --build build-release
./build-release/cryptoseq_print_sequence
```

## API principale

L'header pubblico e' `core/include/cryptoseq.h`.

Le funzioni principali sono:

```c
cs_status_t cs_generate_from_bytes(
    const uint8_t *source_bytes,
    size_t source_len,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
);

cs_status_t cs_source_digest(
    const uint8_t *source_bytes,
    size_t source_len,
    uint8_t digest[CS_SHA256_DIGEST_SIZE]
);

cs_status_t cs_generate_values_from_digest(
    const uint8_t source_digest[CS_SHA256_DIGEST_SIZE],
    const cs_params_t *params,
    uint32_t *values,
    size_t value_capacity
);

cs_status_t cs_map_values(
    const uint32_t *values,
    size_t value_count,
    const cs_params_t *params,
    cs_event_t *events,
    size_t event_capacity
);
```

`cs_generate_from_bytes` e' il percorso semplice. Per Max for Live ed ESP32 e' spesso preferibile separare le fasi:

1. calcolare o ricevere `h_S`;
2. generare e salvare la sequenza numerica `C`;
3. rimappare `C` quando cambiano scala, densita', gate o modalita'.

Questo evita di ricalcolare hash e trasformazione modulare quando cambia solo il mapping musicale.

## Limiti della prima implementazione

I limiti sono definiti nell'header pubblico:

```c
#define CS_MAX_SOURCE_BYTES ((size_t)256u * 1024u * 1024u)
#define CS_MAX_SEQUENCE_LENGTH ((size_t)4096u)
#define CS_MAX_PRIME_VALUE 65521u
#define CS_MAX_SCALE_LENGTH ((size_t)24u)
#define CS_MAX_DURATION_COUNT ((size_t)32u)
#define CS_MAX_RHYTHM_DIVISOR 1024u
#define CS_MAX_ACCENT_LEVELS 16u
```

Questi limiti sono intenzionali:

- `p` e `q` restano sotto `2^16`, quindi `n = p*q` resta gestibile con aritmetica a 32 bit e moltiplicazioni intermedie a 64 bit;
- la sequenza massima di 4096 step e' ampia per uso musicale e prevedibile su hardware embedded;
- la sorgente diretta e' limitata a 256 MiB per permettere foto e file multimediali comuni senza accettare input enormi;
- per sorgenti piu' grandi si puo' calcolare il digest SHA-256 fuori dal core o aggiungere un'API streaming.

## Ottimizzazioni

Il core e' pensato per generare o rigenerare la sequenza prima del playback. Durante l'esecuzione musicale il sistema dovrebbe leggere solo l'evento dello step corrente.

### Precalcolo e caching

- `cs_source_digest` permette di calcolare `h_S` una sola volta.
- `cs_generate_values_from_digest` permette di generare e salvare la sequenza numerica `C`.
- `cs_map_values` permette di rimappare `C` quando cambiano scala, densita', gate o modalita', senza rifare hash ed esponenziazione modulare.
- `cs_generate_from_bytes` valida i parametri prima di calcolare l'hash della sorgente, cosi' evita lavoro inutile quando l'input e' invalido.

### Hashing per step

- Per ogni step il seed SHA-256 fisso viene preimpacchettato come `h_S || p || q || e`.
- Nel loop cambia solo l'indice `i`, codificato in big-endian su 64 bit.
- Questo riduce il numero di chiamate a `cs_sha256_update` e il lavoro ripetuto per ogni step.

### Aritmetica modulare

- `p` e `q` sono limitati a `CS_MAX_PRIME_VALUE`, quindi `n = p*q` resta in `uint32_t`.
- Le moltiplicazioni modulari usano intermedi a 64 bit per evitare overflow.
- La riduzione del digest SHA-256 modulo `n` procede a blocchi da 32 bit invece che byte per byte.
- `pow_mod` usa square-and-multiply, adatto all'esponente standard `65537`.

### Mapping degli eventi

- Lo switch `melody`, `rhythm`, `hybrid` e' fuori dai loop principali.
- Il loop interno chiama direttamente la funzione di mapping corretta.
- Gli eventi vengono scritti in buffer forniti dal chiamante, senza allocazioni dinamiche.

### Vincoli embedded-friendly

- Il core non usa heap.
- La source diretta e' limitata a 256 MiB.
- La sequenza e' limitata a 4096 step.
- I limiti sono esposti nell'header pubblico, quindi gli adapter Max for Live ed ESP32 possono validarli prima di chiamare il core.

L'obiettivo non e' la massima sicurezza crittografica, ma un motore deterministico rapido e stabile per generazione musicale.

# Formulazione matematica del Cryptographic Sequencer

> Questa versione evita formule troppo lunghe in una sola riga. Le espressioni principali sono spezzate in passaggi intermedi, cosi' risultano piu' leggibili nei renderer Markdown che supportano LaTeX/MathJax, per esempio GitHub, Obsidian o VS Code con estensioni Markdown Math.

---

## 1. Obiettivo

Il **Cryptographic Sequencer** e' un sistema di generazione musicale deterministica che trasforma una sorgente multimediale in una sequenza melodica o ritmica mediante:

1. hashing della sorgente;
2. espansione dell'hash a lunghezza controllata;
3. trasformazione modulare ispirata a RSA;
4. mapping dei valori numerici su strutture musicali discrete.

L'obiettivo non e' realizzare un sistema crittografico sicuro, ma usare concetti crittografici come motore generativo per la composizione algoritmica.

---

## 2. Input del sistema

Sia:

$$
S
$$

una sorgente multimediale, ad esempio:

- immagine;
- audio;
- video;
- file binario generico.

Il sistema riceve inoltre due numeri primi scelti dall'utente:

$$
p, q \in \mathbb{P}
$$

Sono inoltre definiti i parametri musicali:

$$
L \in \mathbb{N}
$$

dove $L$ e' la lunghezza della sequenza da generare.

Indichiamo con:

$$
\mathcal{K}
$$

la scala musicale scelta, e con:

$$
\mathcal{M}
$$

la metrica scelta.

Indichiamo inoltre con:

$$
r
$$

la risoluzione ritmica, cioe' il numero di suddivisioni della griglia musicale.

Infine:

$$
mode \in \{\mathrm{melody}, \mathrm{rhythm}, \mathrm{hybrid}\}
$$

indica la modalita' di funzionamento del sequencer.

---

## 3. Parametri RSA-inspired

A partire dai primi $p$ e $q$, si definisce il modulo:

$$
n = p \cdot q
$$

Si definisce poi la funzione di Eulero:

$$
\varphi(n) = (p - 1)(q - 1)
$$

Si sceglie un esponente:

$$
e \in \mathbb{N}
$$

tale che:

$$
\gcd(e, \varphi(n)) = 1
$$

Nel caso pratico si puo' usare un valore standard, ad esempio:

$$
e = 65537
$$

se la condizione di coprimalita' e' soddisfatta.

La trasformazione modulare principale e':

$$
R(m_i) = m_i^e \bmod n
$$

Il valore trasformato viene indicato come:

$$
c_i = R(m_i)
$$

quindi:

$$
c_i = m_i^e \bmod n
$$

---

## 4. Hashing della sorgente multimediale

La sorgente $S$ viene convertita in una rappresentazione binaria:

$$
bytes(S)
$$

Si definisce una funzione hash crittografica:

$$
H: \{0,1\}^{*} \rightarrow \{0,1\}^{b}
$$

dove $b$ e' la dimensione dell'output in bit.

Per esempio, nel caso di SHA-256:

$$
b = 256
$$

L'hash diretto della sorgente e':

$$
h_S = H(bytes(S))
$$

Questo digest compatto rappresenta la sorgente multimediale nella pipeline generativa.

---

## 5. Espansione hash a lunghezza controllata

Per ottenere una sequenza di lunghezza arbitraria $L$, si usa una modalita' a contatore.

Per ogni indice:

$$
i \in \{0, 1, \dots, L-1\}
$$

si calcola:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel scene \parallel i)
$$

dove $\parallel$ indica la concatenazione.

Ogni hash $h_i$ viene convertito in un intero. Nel seguito questa conversione e' indicata con $\mathrm{int}(h_i)$:

$$
u_i = \mathrm{int}(h_i)
$$

Poi viene ridotto modulo $n$:

$$
m_i = u_i \bmod n
$$

La sequenza numerica di partenza e':

$$
M = (m_0, m_1, \dots, m_{L-1})
$$

Applicando la trasformazione RSA-inspired si ottiene:

$$
C = (c_0, c_1, \dots, c_{L-1})
$$

dove:

$$
c_i = m_i^e \bmod n
$$

La sequenza $C$ e' il materiale numerico generativo del sequencer.

---

## 6. Proprieta' di determinismo

Il sistema e' deterministico rispetto alla tupla:

$$
\Theta =
(S, p, q, e, scene, L, \mathcal{K}, \mathcal{M}, r, mode)
$$

Questo significa che, a parita' di parametri, il risultato e' sempre lo stesso:

$$
\Theta = \Theta'
\Rightarrow
F(\Theta) = F(\Theta')
$$

La funzione globale del sequencer puo' essere indicata come:

$$
F:
(S, p, q, e, scene, L, \mathcal{K}, \mathcal{M}, r, mode)
\rightarrow
\mathcal{E}
$$

dove $\mathcal{E}$ e' la sequenza musicale finale.

---

## 7. Mapping melodico

Sia la scala musicale:

$$
\mathcal{K} = (k_0, k_1, \dots, k_{s-1})
$$

dove $s$ e' il numero di gradi della scala.

Per esempio, in una scala maggiore:

$$
\mathcal{K}_{maj} = (0, 2, 4, 5, 7, 9, 11)
$$

dove i valori rappresentano intervalli in semitoni rispetto alla fondamentale.

Sia:

$$
\rho
$$

la nota fondamentale, espressa come numero MIDI.

Il grado della scala associato allo step $i$ e':

$$
d_i = c_i \bmod s
$$

La componente intervallare e':

$$
k_{d_i}
$$

L'ottava puo' essere determinata da:

$$
o_i =
o_{min} +
\left(
\left\lfloor \frac{c_i}{s} \right\rfloor
\bmod N_o
\right)
$$

dove:

- $o_{min}$ e' l'ottava minima;
- $N_o$ e' il numero di ottave disponibili.

La nota MIDI generata e':

$$
note_i =
\rho + k_{d_i} + 12 \cdot o_i
$$

### Velocity

La velocity MIDI puo' essere definita come:

$$
vel_i =
v_{min} +
\left(
c_i \bmod (v_{max} - v_{min} + 1)
\right)
$$

con:

$$
1 \leq v_{min} \leq vel_i \leq v_{max} \leq 127
$$

### Durata

Sia:

$$
\mathcal{D} = (\delta_0, \delta_1, \dots, \delta_{d-1})
$$

l'insieme delle durate disponibili, ad esempio:

$$
\mathcal{D}
=
\left(
\frac{1}{16},
\frac{1}{8},
\frac{1}{4},
\frac{1}{2}
\right)
$$

La durata dello step $i$ e':

$$
dur_i = \mathcal{D}_{c_i \bmod d}
$$

### Gate length

Il gate length puo' essere calcolato come valore normalizzato:

$$
gate_i =
g_{min}
+
\frac{c_i \bmod Q_g}{Q_g - 1}
\cdot
(g_{max} - g_{min})
$$

dove:

$$
0 < g_{min} \leq gate_i \leq g_{max} \leq 1
$$

---

## 8. Mapping ritmico

Nel caso ritmico, la sequenza $C$ viene mappata su una griglia temporale.

Sia:

$$
T = L
$$

il numero totale di step.

Ogni step puo' essere attivo o inattivo.

Una definizione semplice e':

$$
active_i =
\begin{cases}
1 & \text{se } c_i \bmod D < \tau \\
0 & \text{altrimenti}
\end{cases}
$$

dove:

- $D$ e' un divisore di riferimento;
- $\tau$ e' una soglia di densita'.

La densita' ritmica attesa cresce al crescere di $\tau$.

### Accento

Il livello di accento puo' essere definito come:

$$
accent_i = c_i \bmod A
$$

dove $A$ e' il numero di livelli di accento.

Per esempio, con:

$$
A = 4
$$

si ottiene:

$$
accent_i \in \{0, 1, 2, 3\}
$$

### Velocity ritmica

La velocity dello step ritmico puo' essere ottenuta combinando valore numerico e accento:

$$
vel_i =
v_{base}
+
\alpha \cdot accent_i
+
(c_i \bmod \beta)
$$

Il valore finale viene limitato all'intervallo MIDI:

$$
vel_i = \min(127, \max(1, vel_i))
$$

---

## 9. Mapping ibrido

Nella modalita' ibrida, ogni valore $c_i$ genera contemporaneamente:

- altezza;
- attivazione ritmica;
- durata;
- velocity;
- gate;
- accento.

L'evento musicale completo puo' essere rappresentato come:

$$
E_i =
(i, active_i, note_i, dur_i, vel_i, gate_i, accent_i)
$$

La sequenza musicale completa e':

$$
\mathcal{E} =
(E_0, E_1, \dots, E_{L-1})
$$

---

## 10. Funzione complessiva del sistema

La funzione globale del sequencer puo' essere scritta come composizione di tre funzioni:

$$
F = Map \circ R \circ ExpandHash
$$

La funzione di espansione hash produce:

$$
ExpandHash(S, p, q, e, scene, L)
=
(m_0, m_1, \dots, m_{L-1})
$$

La trasformazione RSA-inspired produce:

$$
R(M)
=
(m_0^e \bmod n,
m_1^e \bmod n,
\dots,
m_{L-1}^e \bmod n)
$$

Il mapping musicale produce:

$$
Map(C, \mathcal{K}, \mathcal{M}, r, mode)
=
\mathcal{E}
$$

Quindi:

$$
\mathcal{E}
=
F(S, p, q, e, scene, L, \mathcal{K}, \mathcal{M}, r, mode)
$$

---

## 11. Sintesi compatta, versione compatibile

Per evitare problemi di rendering, la formulazione compatta viene scritta in passaggi separati.

### Hash della sorgente

$$
h_S = H(bytes(S))
$$

### Parametri RSA-inspired

$$
n = p \cdot q
$$

$$
\varphi(n) = (p - 1)(q - 1)
$$

$$
\gcd(e, \varphi(n)) = 1
$$

### Espansione dello step

Per ogni step:

$$
i = 0, 1, \dots, L - 1
$$

si calcola l'hash espanso:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel scene \parallel i)
$$

L'hash viene convertito in un intero:

$$
u_i = \mathrm{int}(h_i)
$$

Poi viene ridotto modulo $n$:

$$
m_i = u_i \bmod n
$$

Infine si applica la trasformazione RSA-inspired:

$$
c_i = m_i^e \bmod n
$$

### Sequenza numerica generata

$$
C = (c_0, c_1, \dots, c_{L-1})
$$

### Mapping musicale

La sequenza numerica viene trasformata in eventi musicali:

$$
\mathcal{E} = Map(C, \mathcal{K}, \mathcal{M}, r, mode)
$$

### Formula finale

La formulazione complessiva puo' essere letta cosi':

$$
\mathcal{E} = Map(C, \mathcal{K}, \mathcal{M}, r, mode)
$$

con:

$$
C = (c_i)_{i=0}^{L-1}
$$

e:

$$
c_i = m_i^e \bmod n
$$

dove:

$$
m_i = u_i \bmod n
$$

$$
u_i = \mathrm{int}(h_i)
$$

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel scene \parallel i)
$$

$$
h_S = H(bytes(S))
$$

Quindi il risultato finale e':

$$
\mathcal{E} = (E_0, E_1, \dots, E_{L-1})
$$

cioe' una sequenza musicale deterministica generata da una sorgente multimediale e controllata da parametri crittografici e musicali.

---

## 12. Pseudocodice

```text
Input:
    S        sorgente multimediale
    p, q     numeri primi
    e        esponente RSA-inspired
    L        lunghezza sequenza
    K        scala musicale
    METER    metrica
    r        suddivisione ritmica
    mode     melody, rhythm oppure hybrid

Output:
    E        sequenza di eventi musicali

Procedure:

1. h_S <- Hash(bytes(S))

2. n   <- p * q
3. phi <- (p - 1) * (q - 1)

4. if gcd(e, phi) != 1:
       return error

5. for i = 0 to L - 1:

       h_i <- Hash(h_S || p || q || e || i)

       u_i <- int(h_i)

       m_i <- u_i mod n

       c_i <- pow_mod(m_i, e, n)

       if mode == melody:
           E_i <- melodic_mapping(c_i, K)

       if mode == rhythm:
           E_i <- rhythmic_mapping(c_i, METER, r)

       if mode == hybrid:
           E_i <- hybrid_mapping(c_i, K, METER, r)

6. return E
```

---

## 13. Complessita' computazionale

Sia:

- $L$ la lunghezza della sequenza;
- $|S|$ la dimensione della sorgente in byte;
- $b$ la dimensione dell'hash;
- $n$ il modulo RSA-inspired;
- $\ell = \log_2(n)$ la dimensione in bit del modulo.

### Hashing

Se si ricalcola l'hash dell'intera sorgente per ogni step:

$$
O(L \cdot |S|)
$$

Questa soluzione e' semplice ma inefficiente per file grandi.

Una strategia migliore consiste nel calcolare prima un digest della sorgente:

$$
h_S = H(bytes(S))
$$

e poi usare:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel scene \parallel i)
$$

In questo caso il costo diventa:

$$
O(|S| + L \cdot b)
$$

Questa forma e' piu' adatta a implementazioni hardware su ESP32.

### Esponenziazione modulare

L'esponenziazione modulare tramite square-and-multiply ha costo circa:

$$
O(\log(e) \cdot M(\ell))
$$

dove $M(\ell)$ e' il costo della moltiplicazione tra interi di $\ell$ bit.

Per uso musicale ed embedded, e' consigliabile usare primi piccoli o medi, compatibili con aritmetica a 32 o 64 bit.

### Mapping musicale

Il mapping musicale ha costo lineare:

$$
O(L)
$$

Il costo e' trascurabile rispetto a hashing ed esponenziazione modulare.

---

## 14. Ottimizzazioni suggerite

### 14.1 Pre-hashing della sorgente

Si consiglia di usare:

$$
h_S = H(bytes(S))
$$

e poi:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel scene \parallel i)
$$

Questo riduce drasticamente il costo computazionale su file grandi.

### 14.2 Precalcolo della sequenza

La sequenza dovrebbe essere generata prima del playback:

$$
\mathcal{E} = F(\Theta)
$$

Durante l'esecuzione musicale il sistema dovrebbe solo leggere lo step corrente:

$$
E_i
$$

Questo evita ricalcoli in tempo reale e migliora la stabilita' del timing MIDI, gate e CV.

### 14.3 Limitazione dei primi su ESP32

Per la versione hardware, si consiglia:

$$
p, q < 2^{16}
$$

oppure, al massimo:

$$
p, q < 2^{32}
$$

a seconda delle librerie numeriche disponibili.

L'uso di primi molto grandi non e' necessario, perche' l'obiettivo e' generativo e non crittografico.

### 14.4 Caching

E' possibile memorizzare:

$$
h_S = H(bytes(S))
$$

e la sequenza:

$$
C = (c_0, c_1, \dots, c_{L-1})
$$

Se cambia solo il mapping musicale, ad esempio scala o metrica, non e' necessario ricalcolare hash e trasformazione RSA-inspired.

Si puo' ricalcolare solo:

$$
Map(C, \mathcal{K}, \mathcal{M}, r, mode)
$$

---

## 15. Nota sulla sicurezza

Il sistema e' ispirato a RSA, ma non deve essere presentato come implementazione sicura di RSA.

In particolare:

- i primi possono essere piccoli;
- la sorgente e' usata a scopo generativo;
- l'obiettivo e' produrre sequenze musicali;
- non e' previsto l'uso per cifrare dati sensibili;
- non viene garantita sicurezza crittografica.

Una formulazione corretta e':

> Il sistema usa una trasformazione modulare ispirata a RSA come motore deterministico per la generazione musicale.


