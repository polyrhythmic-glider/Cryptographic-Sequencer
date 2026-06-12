# Cryptographic-Sequencer
Sequencer generativo deterministico basato su hashing multimediale e trasformazioni modulari ispirate a RSA, con doppia implementazione: Max4Live e modulo hardware ESP32.

Il progetto ha l’obiettivo di realizzare un sequencer musicale generativo deterministico che, a partire da una sorgente multimediale e da due numeri primi scelti dall’utente, genera sequenze melodiche o ritmiche.

La sorgente viene trasformata tramite hashing in una sequenza numerica di lunghezza controllabile. I valori ottenuti vengono elaborati attraverso una trasformazione modulare ispirata a RSA e infine mappati su strutture musicali discrete: scale, metriche, step, durate, accenti, velocity, gate e CV.

Il progetto prevede due implementazioni principali:

Max4Live device, per generare sequenze MIDI sincronizzate con Ableton Live.
Modulo hardware ESP32, per generare sequenze standalone tramite MIDI, gate, trigger e/o CV.

Il sistema non è pensato come strumento di sicurezza crittografica, ma come strumento di composizione generativa ispirato a concetti crittografici.

# Formulazione matematica del Cryptographic Sequencer

> Questa versione evita formule troppo lunghe in una sola riga. Le espressioni principali sono spezzate in passaggi intermedi, così risultano più leggibili nei renderer Markdown che supportano LaTeX/MathJax, per esempio GitHub, Obsidian o VS Code con estensioni Markdown Math.

---

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

dove $L$ è la lunghezza della sequenza da generare.

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

la risoluzione ritmica, cioè il numero di suddivisioni della griglia musicale.

Infine:

$$
mode \in \{\mathrm{melody}, \mathrm{rhythm}, \mathrm{hybrid}\}
$$

indica la modalità di funzionamento del sequencer.

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

Nel caso pratico si può usare un valore standard, ad esempio:

$$
e = 65537
$$

se la condizione di coprimalità è soddisfatta.

La trasformazione modulare principale è:

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

dove $b$ è la dimensione dell'output in bit.

Per esempio, nel caso di SHA-256:

$$
b = 256
$$

L'hash diretto della sorgente è:

$$
h_S = H(bytes(S))
$$

Questo digest compatto rappresenta la sorgente multimediale nella pipeline generativa.

---

## 5. Espansione hash a lunghezza controllata

Per ottenere una sequenza di lunghezza arbitraria $L$, si usa una modalità a contatore.

Per ogni indice:

$$
i \in \{0, 1, \dots, L-1\}
$$

si calcola:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
$$

dove $\parallel$ indica la concatenazione.

Ogni hash $h_i$ viene convertito in un intero. Nel seguito questa conversione è indicata con $\mathrm{int}(h_i)$:

$$
u_i = \mathrm{int}(h_i)
$$

Poi viene ridotto modulo $n$:

$$
m_i = u_i \bmod n
$$

La sequenza numerica di partenza è:

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

La sequenza $C$ è il materiale numerico generativo del sequencer.

---

## 6. Proprietà di determinismo

Il sistema è deterministico rispetto alla tupla:

$$
\Theta =
(S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
$$

Questo significa che, a parità di parametri, il risultato è sempre lo stesso:

$$
\Theta = \Theta'
\Rightarrow
F(\Theta) = F(\Theta')
$$

La funzione globale del sequencer può essere indicata come:

$$
F:
(S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
\rightarrow
\mathcal{E}
$$

dove $\mathcal{E}$ è la sequenza musicale finale.

---

## 7. Mapping melodico

Sia la scala musicale:

$$
\mathcal{K} = (k_0, k_1, \dots, k_{s-1})
$$

dove $s$ è il numero di gradi della scala.

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

Il grado della scala associato allo step $i$ è:

$$
d_i = c_i \bmod s
$$

La componente intervallare è:

$$
k_{d_i}
$$

L'ottava può essere determinata da:

$$
o_i =
o_{min} +
\left(
\left\lfloor \frac{c_i}{s} \right\rfloor
\bmod N_o
\right)
$$

dove:

- $o_{min}$ è l'ottava minima;
- $N_o$ è il numero di ottave disponibili.

La nota MIDI generata è:

$$
note_i =
\rho + k_{d_i} + 12 \cdot o_i
$$

### Velocity

La velocity MIDI può essere definita come:

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

La durata dello step $i$ è:

$$
dur_i = \mathcal{D}_{c_i \bmod d}
$$

### Gate length

Il gate length può essere calcolato come valore normalizzato:

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

Ogni step può essere attivo o inattivo.

Una definizione semplice è:

$$
active_i =
\begin{cases}
1 & \text{se } c_i \bmod D < \tau \\
0 & \text{altrimenti}
\end{cases}
$$

dove:

- $D$ è un divisore di riferimento;
- $\tau$ è una soglia di densità.

La densità ritmica attesa cresce al crescere di $\tau$.

### Accento

Il livello di accento può essere definito come:

$$
accent_i = c_i \bmod A
$$

dove $A$ è il numero di livelli di accento.

Per esempio, con:

$$
A = 4
$$

si ottiene:

$$
accent_i \in \{0, 1, 2, 3\}
$$

### Velocity ritmica

La velocity dello step ritmico può essere ottenuta combinando valore numerico e accento:

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

Nella modalità ibrida, ogni valore $c_i$ genera contemporaneamente:

- altezza;
- attivazione ritmica;
- durata;
- velocity;
- gate;
- accento.

L'evento musicale completo può essere rappresentato come:

$$
E_i =
(i, active_i, note_i, dur_i, vel_i, gate_i, accent_i)
$$

La sequenza musicale completa è:

$$
\mathcal{E} =
(E_0, E_1, \dots, E_{L-1})
$$

---

## 10. Funzione complessiva del sistema

La funzione globale del sequencer può essere scritta come composizione di tre funzioni:

$$
F = Map \circ R \circ ExpandHash
$$

La funzione di espansione hash produce:

$$
ExpandHash(S, p, q, e, L)
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
F(S, p, q, e, L, \mathcal{K}, \mathcal{M}, r, mode)
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
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
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

La formulazione complessiva può essere letta così:

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
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
$$

$$
h_S = H(bytes(S))
$$

Quindi il risultato finale è:

$$
\mathcal{E} = (E_0, E_1, \dots, E_{L-1})
$$

cioè una sequenza musicale deterministica generata da una sorgente multimediale e controllata da parametri crittografici e musicali.

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

## 13. Complessità computazionale

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

Questa soluzione è semplice ma inefficiente per file grandi.

Una strategia migliore consiste nel calcolare prima un digest della sorgente:

$$
h_S = H(bytes(S))
$$

e poi usare:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
$$

In questo caso il costo diventa:

$$
O(|S| + L \cdot b)
$$

Questa forma è più adatta a implementazioni hardware su ESP32.

### Esponenziazione modulare

L'esponenziazione modulare tramite square-and-multiply ha costo circa:

$$
O(\log(e) \cdot M(\ell))
$$

dove $M(\ell)$ è il costo della moltiplicazione tra interi di $\ell$ bit.

Per uso musicale ed embedded, è consigliabile usare primi piccoli o medi, compatibili con aritmetica a 32 o 64 bit.

### Mapping musicale

Il mapping musicale ha costo lineare:

$$
O(L)
$$

Il costo è trascurabile rispetto a hashing ed esponenziazione modulare.

---

## 14. Ottimizzazioni suggerite

### 14.1 Pre-hashing della sorgente

Si consiglia di usare:

$$
h_S = H(bytes(S))
$$

e poi:

$$
h_i = H(h_S \parallel p \parallel q \parallel e \parallel i)
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

Questo evita ricalcoli in tempo reale e migliora la stabilità del timing MIDI, gate e CV.

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

L'uso di primi molto grandi non è necessario, perché l'obiettivo è generativo e non crittografico.

### 14.4 Caching

È possibile memorizzare:

$$
h_S = H(bytes(S))
$$

e la sequenza:

$$
C = (c_0, c_1, \dots, c_{L-1})
$$

Se cambia solo il mapping musicale, ad esempio scala o metrica, non è necessario ricalcolare hash e trasformazione RSA-inspired.

Si può ricalcolare solo:

$$
Map(C, \mathcal{K}, \mathcal{M}, r, mode)
$$

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
