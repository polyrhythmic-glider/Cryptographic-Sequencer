# Cryptographic-Sequencer
Sequencer generativo deterministico basato su hashing multimediale e trasformazioni modulari ispirate a RSA, con doppia implementazione: Max4Live e modulo hardware ESP32.

Il progetto ha l’obiettivo di realizzare un sequencer musicale generativo deterministico che, a partire da una sorgente multimediale e da due numeri primi scelti dall’utente, genera sequenze melodiche o ritmiche.

La sorgente viene trasformata tramite hashing in una sequenza numerica di lunghezza controllabile. I valori ottenuti vengono elaborati attraverso una trasformazione modulare ispirata a RSA e infine mappati su strutture musicali discrete: scale, metriche, step, durate, accenti, velocity, gate e CV.

Il progetto prevede due implementazioni principali:

Max4Live device, per generare sequenze MIDI sincronizzate con Ableton Live.
Modulo hardware ESP32, per generare sequenze standalone tramite MIDI, gate, trigger e/o CV.

Il sistema non è pensato come strumento di sicurezza crittografica, ma come strumento di composizione generativa ispirato a concetti crittografici.

# Formulazione matematica del Cryptographic Sequencer

> Nota di formattazione: questa versione usa blocchi matematici con `\Large` per rendere le formule più leggibili nei renderer Markdown compatibili con LaTeX/MathJax. Se il renderer non supporta `\Large`, le formule verranno comunque mostrate normalmente.

## 1. Obiettivo

Il **Cryptographic Sequencer** è un sistema di generazione musicale deterministica che trasforma una sorgente multimediale in una sequenza melodica o ritmica mediante:

1. hashing della sorgente;
2. espansione dell'hash a lunghezza controllata;
3. trasformazione modulare ispirata a RSA;
4. mapping dei valori numerici su strutture musicali discrete.

L'obiettivo non è realizzare un sistema crittografico sicuro, ma usare concetti crittografici come motore generativo per la composizione algoritmica.

---

## 2. Input del sistema

Sia:

$$
{\Large
S
}
$$

una sorgente multimediale, ad esempio:

- immagine;
- audio;
- video;
- file binario generico.

Il sistema riceve inoltre:

$$
{\Large
p, q \in \mathbb{P}
}
$$

dove $p$ e $q$ sono due numeri primi scelti dall'utente.

Sono inoltre definiti i parametri musicali:

$$
{\Large
L \in \mathbb{N}
}
$$

lunghezza della sequenza da generare;

$$
{\Large
\mathcal{K}
}
$$

scala musicale scelta;

$$
{\Large
\mathcal{M}
}
$$

metrica scelta;

$$
{\Large
r
}
$$

risoluzione ritmica, cioè numero di suddivisioni per unità metrica;

$$
{\Large
BPM
}
$$

tempo musicale, nel caso di funzionamento non sincronizzato esternamente.

Il sistema può operare in tre modalità principali:

$$
{\Large
mode \in \{\text{melody}, \text{rhythm}, \text{hybrid}\}
}
$$

---

## 3. Parametri RSA-inspired

A partire dai primi $p$ e $q$, si definisce:

$$
{\Large
n = p \cdot q
}
$$

e:

$$
{\Large
\varphi(n) = (p - 1)(q - 1)
}
$$

Si sceglie poi un esponente:

$$
{\Large
e \in \mathbb{N}
}
$$

tale che:

$$
{\Large
\gcd(e, \varphi(n)) = 1
}
$$

Nel caso pratico si può usare un valore standard, ad esempio:

$$
{\Large
e = 65537
}
$$

se la condizione di coprimalità è soddisfatta.

La trasformazione modulare principale è:

$$
{\Large
R(m_i) = m_i^e \bmod n
}
$$

dove $m_i$ è un valore numerico derivato dalla sorgente multimediale.

Il valore trasformato viene indicato come:

$$
{\Large
c_i = R(m_i)
}
$$

quindi:

$$
{\Large
c_i = m_i^e \bmod n
}
$$

---

## 4. Hashing della sorgente multimediale

La sorgente $S$ viene convertita in una rappresentazione binaria:

$$
{\Large
bytes(S)
}
$$

Si definisce una funzione hash crittografica:

$$
{\Large
H: \{0,1\}^{*} \rightarrow \{0,1\}^{b}
}
$$

dove $b$ è la dimensione dell'output in bit.

Esempi possibili:

$$
{\Large
b = 256
}
$$

nel caso di SHA-256.

L'hash diretto della sorgente è:

$$
{\Large
h = H(bytes(S))
}
$$

Tuttavia, un singolo hash produce una lunghezza fissa. Per ottenere una sequenza musicale di lunghezza arbitraria $L$, si usa una modalità a contatore.

---

## 5. Espansione hash a lunghezza controllata

Per ogni indice della sequenza:

$$
{\Large
i \in \{0, 1, \dots, L-1\}
}
$$

si calcola:

$$
{\Large
h_i = H(bytes(S) \parallel p \parallel q \parallel e \parallel i)
}
$$

dove $\parallel$ indica la concatenazione.

Ogni $h_i$ viene convertito in un intero:

$$
{\Large
u_i = \text{int}(h_i)
}
$$

Per renderlo compatibile con il modulo RSA-inspired, si calcola:

$$
{\Large
m_i = u_i \bmod n
}
$$

La sequenza numerica di partenza è quindi:

$$
{\Large
M = (m_0, m_1, \dots, m_{L-1})
}
$$

Applicando la trasformazione modulare si ottiene:

$$
{\Large
C = (c_0, c_1, \dots, c_{L-1})
}
$$

dove:

$$
{\Large
c_i = m_i^e \bmod n
}
$$

Questa sequenza $C$ è il materiale numerico generativo del sequencer.

---

## 6. Proprietà di determinismo

Il sistema è deterministico rispetto alla tupla:

$$
{\Large
\Theta = (S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
}
$$

Questo significa che, a parità di parametri, la sequenza generata è sempre la stessa:

$$
{\Large
F(\Theta) = F(\Theta')
\quad \text{se} \quad
\Theta = \Theta'
}
$$

Dove $F$ è la funzione complessiva del sequencer.

In forma estesa:

$$
{\Large
F:
(S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
\rightarrow
\text{sequenza musicale}
}
$$

Una piccola modifica a $S$, $p$, $q$, $e$ o $L$ può produrre una sequenza completamente diversa a causa dell'effetto valanga della funzione hash.

---

## 7. Mapping melodico

Sia la scala musicale:

$$
{\Large
\mathcal{K} = (k_0, k_1, \dots, k_{s-1})
}
$$

dove $s$ è il numero di gradi della scala.

Per esempio, in una scala maggiore:

$$
{\Large
\mathcal{K}_{maj} = (0, 2, 4, 5, 7, 9, 11)
}
$$

dove i valori rappresentano intervalli in semitoni rispetto alla fondamentale.

Sia:

$$
{\Large
\rho
}
$$

la nota fondamentale espressa come numero MIDI.

Il grado della scala associato allo step $i$ è:

$$
{\Large
d_i = c_i \bmod s
}
$$

La componente di altezza relativa è:

$$
{\Large
k_{d_i}
}
$$

L'ottava può essere determinata da una seconda funzione sui valori generati. Per esempio:

$$
{\Large
o_i = o_{min} + \left( \left\lfloor \frac{c_i}{s} \right\rfloor \bmod N_o \right)
}
$$

dove:

- $o_{min}$ è l'ottava minima;
- $N_o$ è il numero di ottave disponibili.

La nota MIDI generata è quindi:

$$
{\Large
note_i = \rho + k_{d_i} + 12 \cdot o_i
}
$$

In alternativa, se $\rho$ include già l'ottava assoluta, si può usare:

$$
{\Large
note_i = \rho + k_{d_i} + 12 \cdot \Delta o_i
}
$$

dove $\Delta o_i$ è uno spostamento di ottava.

### Velocity

La velocity MIDI può essere definita come:

$$
{\Large
vel_i = v_{min} + (c_i \bmod (v_{max} - v_{min} + 1))
}
$$

con:

$$
{\Large
1 \leq v_{min} \leq vel_i \leq v_{max} \leq 127
}
$$

### Durata

Sia:

$$
{\Large
\mathcal{D} = (\delta_0, \delta_1, \dots, \delta_{d-1})
}
$$

l'insieme delle durate disponibili, ad esempio:

$$
{\Large
\mathcal{D} = \left(\frac{1}{16}, \frac{1}{8}, \frac{1}{4}, \frac{1}{2}\right)
}
$$

La durata dello step $i$ è:

$$
{\Large
dur_i = \mathcal{D}_{c_i \bmod d}
}
$$

### Gate length

Il gate length può essere calcolato come valore normalizzato:

$$
{\Large
gate_i = g_{min} + \frac{c_i \bmod Q_g}{Q_g - 1}(g_{max} - g_{min})
}
$$

dove:

$$
{\Large
0 < g_{min} \leq gate_i \leq g_{max} \leq 1
}
$$

---

## 8. Mapping ritmico

Nel caso ritmico, la sequenza $C$ viene mappata su una griglia temporale.

Sia:

$$
{\Large
T = L
}
$$

il numero totale di step.

Ogni step può essere attivo o inattivo.

Una prima definizione semplice è:

$$
{\Large
active_i =
\begin{cases}
1 & \text{se } c_i \bmod D < \tau \\
0 & \text{altrimenti}
\end{cases}
}
$$

dove:

- $D$ è un divisore di riferimento;
- $\tau$ è una soglia di densità.

La densità ritmica attesa cresce al crescere di $\tau$.

### Accento

Il livello di accento può essere definito come:

$$
{\Large
accent_i = c_i \bmod A
}
$$

dove $A$ è il numero di livelli di accento.

Per esempio, con:

$$
{\Large
A = 4
}
$$

si ottiene:

$$
{\Large
accent_i \in \{0, 1, 2, 3\}
}
$$

### Velocity ritmica

La velocity dello step ritmico può essere ottenuta combinando valore numerico e accento:

$$
{\Large
vel_i = v_{base} + \alpha \cdot accent_i + (c_i \bmod \beta)
}
$$

dove:

- $v_{base}$ è la velocity minima;
- $\alpha$ controlla il peso dell'accento;
- $\beta$ introduce una variazione locale.

Il valore finale deve essere limitato all'intervallo MIDI:

$$
{\Large
vel_i \in [1, 127]
}
$$

quindi:

$$
{\Large
vel_i = \min(127, \max(1, vel_i))
}
$$

---

## 9. Mapping ibrido

Nella modalità ibrida, ogni valore $c_i$ genera contemporaneamente:

- altezza;
- attivazione ritmica;
- durata;
- velocity;
- gate;
- accento.

L'evento musicale completo può essere rappresentato come:

$$
{\Large
E_i = (i, active_i, note_i, dur_i, vel_i, gate_i, accent_i)
}
$$

La sequenza musicale completa è:

$$
{\Large
\mathcal{E} = (E_0, E_1, \dots, E_{L-1})
}
$$

---

## 10. Funzione complessiva del sistema

La funzione globale del sequencer può essere scritta come composizione di funzioni:

$$
{\Large
F = Map \circ R \circ ExpandHash
}
$$

dove:

$$
{\Large
ExpandHash(S, p, q, e, L) = (m_0, m_1, \dots, m_{L-1})
}
$$

$$
{\Large
R(M) = (m_0^e \bmod n, m_1^e \bmod n, \dots, m_{L-1}^e \bmod n)
}
$$

$$
{\Large
Map(C, \mathcal{K}, \mathcal{M}, r, mode) = \mathcal{E}
}
$$

Quindi:

$$
{\Large
\mathcal{E}
=
F(S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
}
$$

---

## 11. Pseudocodice matematico

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

1. n   <- p * q
2. phi <- (p - 1) * (q - 1)

3. if gcd(e, phi) != 1:
       return error

4. for i = 0 to L - 1:

       h_i <- Hash(bytes(S) || p || q || e || i)

       u_i <- int(h_i)

       m_i <- u_i mod n

       c_i <- pow_mod(m_i, e, n)

       if mode == melody:
           E_i <- melodic_mapping(c_i, K)

       if mode == rhythm:
           E_i <- rhythmic_mapping(c_i, METER, r)

       if mode == hybrid:
           E_i <- hybrid_mapping(c_i, K, METER, r)

5. return E
```

---

## 12. Complessità computazionale

Sia:

- $L$ la lunghezza della sequenza;
- $|S|$ la dimensione della sorgente in byte;
- $b$ la dimensione dell'hash;
- $n$ il modulo RSA-inspired;
- $\ell = \log_2(n)$ la dimensione in bit del modulo.

### Hashing

Se si ricalcola l'hash dell'intera sorgente per ogni step:

$$
{\Large
O(L \cdot |S|)
}
$$

Questa soluzione è semplice ma inefficiente per file grandi.

Una strategia migliore consiste nel calcolare prima un digest della sorgente:

$$
{\Large
h_S = H(bytes(S))
}
$$

e poi usare:

$$
{\Large
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
}
$$

In questo caso il costo diventa:

$$
{\Large
O(|S| + L \cdot b)
}
$$

Questa forma è più adatta a implementazioni hardware su ESP32.

### Esponenziazione modulare

L'esponenziazione modulare tramite square-and-multiply ha costo circa:

$$
{\Large
O(\log(e) \cdot M(\ell))
}
$$

dove $M(\ell)$ è il costo della moltiplicazione tra interi di $\ell$ bit.

Per uso musicale e embedded, è consigliabile usare primi piccoli o medi, compatibili con aritmetica a 32 o 64 bit.

### Mapping musicale

Il mapping musicale ha costo lineare:

$$
{\Large
O(L)
}
$$

Il costo è trascurabile rispetto a hashing ed esponenziazione modulare.

---

## 13. Ottimizzazioni suggerite

### 13.1 Pre-hashing della sorgente

Invece di usare:

$$
{\Large
h_i = H(bytes(S) \parallel p \parallel q \parallel e \parallel i)
}
$$

si può usare:

$$
{\Large
h_S = H(bytes(S))
}
$$

e poi:

$$
{\Large
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
}
$$

Questo riduce drasticamente il costo computazionale su file grandi.

---

### 13.2 Precalcolo della sequenza

La sequenza dovrebbe essere generata prima del playback:

$$
{\Large
\mathcal{E} = F(\Theta)
}
$$

Durante l'esecuzione musicale il sistema dovrebbe solo leggere:

$$
{\Large
E_i
}
$$

allo step corrente.

Questo evita ricalcoli in tempo reale e migliora la stabilità del timing MIDI, gate e CV.

---

### 13.3 Limitazione dei primi su ESP32

Per la versione hardware, si consiglia:

$$
{\Large
p, q < 2^{16}
}
$$

oppure, al massimo:

$$
{\Large
p, q < 2^{32}
}
$$

a seconda delle librerie numeriche disponibili.

L'uso di primi molto grandi non è necessario, perché l'obiettivo è generativo e non crittografico.

---

### 13.4 Caching

È possibile memorizzare:

$$
{\Large
h_S = H(bytes(S))
}
$$

e la sequenza:

$$
{\Large
C = (c_0, c_1, \dots, c_{L-1})
}
$$

Se solo il mapping musicale cambia, ad esempio scala o metrica, non è necessario ricalcolare hash e RSA-inspired transform.

Si può ricalcolare solo:

$$
{\Large
Map(C, \mathcal{K}, \mathcal{M}, r, mode)
}
$$

---

## 14. Colli di bottiglia attesi

### Max4Live

Possibili colli di bottiglia:

- calcolo hash di file grandi;
- uso di JavaScript per interi grandi;
- rigenerazione durante playback;
- aggiornamento grafico della griglia;
- scheduling MIDI se il calcolo avviene nel thread sbagliato.

Soluzione consigliata:

- separare generazione e playback;
- usare `js` o `node.script` solo per generare la sequenza;
- usare oggetti Max per lo scheduling;
- aggiornare l'interfaccia solo quando necessario.

### ESP32

Possibili colli di bottiglia:

- lettura microSD;
- hashing di file grandi;
- esponenziazione modulare;
- aggiornamento display;
- timing MIDI;
- generazione in tempo reale;
- memoria RAM limitata.

Soluzione consigliata:

- leggere i file a blocchi;
- calcolare un hash sorgente $h_S$;
- generare la sequenza offline rispetto al playback;
- usare interi a 32/64 bit;
- ridurre la frequenza di aggiornamento del display;
- mantenere lo scheduler musicale leggero e indipendente.

---

## 15. Nota sulla sicurezza

Il sistema è ispirato a RSA, ma non deve essere presentato come implementazione sicura di RSA.

In particolare:

- i primi possono essere piccoli;
- la sorgente è usata a scopo generativo;
- l'obiettivo è produrre sequenze musicali;
- non è previsto l'uso per cifrare dati sensibili;
- non viene garantita sicurezza crittografica.

Una formulazione corretta è:

> Il sistema usa una trasformazione modulare ispirata a RSA come motore deterministico per la generazione musicale.

---

## 16. Sintesi

La formulazione compatta del sistema è:
$$
\mathcal{E}
=
Map
\left(
(c_i)_{i=0}^{L-1},
\mathcal{K},
\mathcal{M},
r,
mode
\right)
$$

$$
c_i =
\left(
\mathrm{int}{h_i}
\left(
H(h_S \parallel p \parallel q \parallel e \parallel i)
\right)
\bmod n
\right)^e
\bmod n
$$

generata da una sorgente multimediale e controllata da parametri crittografici e musicali.
