# Cryptographic-Sequencer
Sequencer generativo deterministico basato su hashing multimediale e trasformazioni modulari ispirate a RSA, con doppia implementazione: Max4Live e modulo hardware ESP32.

Il progetto ha l’obiettivo di realizzare un sequencer musicale generativo deterministico che, a partire da una sorgente multimediale e da due numeri primi scelti dall’utente, genera sequenze melodiche o ritmiche.

La sorgente viene trasformata tramite hashing in una sequenza numerica di lunghezza controllabile. I valori ottenuti vengono elaborati attraverso una trasformazione modulare ispirata a RSA e infine mappati su strutture musicali discrete: scale, metriche, step, durate, accenti, velocity, gate e CV.

Il progetto prevede due implementazioni principali:

Max4Live device, per generare sequenze MIDI sincronizzate con Ableton Live.
Modulo hardware ESP32, per generare sequenze standalone tramite MIDI, gate, trigger e/o CV.

Il sistema non è pensato come strumento di sicurezza crittografica, ma come strumento di composizione generativa ispirato a concetti crittografici.
