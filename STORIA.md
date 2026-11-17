# Storia del progetto — Imposizione Stampa

Tool di imposizione stampa in un solo file HTML. Note in [NOTE.md](./NOTE.md).

## Origine

Nato il **27 luglio 2026** (unico commit: *"Strumento di imposizione stampa in una
pagina sola"*). Un `index.html` autoconsistente che, via pdf-lib + pdf.js, dispone
le pagine di un PDF per la stampa a segnature/booklet — tutto lato browser.

## Stato

Funzionante e fermo a quella versione. Non è collegato a nessun deploy: si usa
aprendo il file. Se un giorno servisse distribuirlo o usarlo senza rete, le
librerie CDN vanno incorporate nel file.

## 9 novembre 2026 — correzioni e modalita' Libro

Il tool "dava sempre noie". Difetti trovati nella modalita' a copie e corretti:
- PDF diverso dall'anteprima: nell'anteprima lo zoom era applicato due volte e lo spostamento X/Y
  ruotava insieme al contenuto. Ora un solo calcolo (`contentPlacement`) per entrambi.
- Rotazione nel PDF: le pagine PDF non venivano ruotate affatto ("fallback senza rotazione"), le
  immagini ruotavano attorno all'angolo e uscivano dalla cella. Ignorato anche il /Rotate delle pagine.
- Quando il layout ruota le celle sul foglio, il contenuto non ruotava con loro (usciva piccolo e storto).
- Nessun ritaglio: con "Riempi" o zoom > 100% le copie sbordavano sulle vicine.
- Linee di taglio rosse/blu tracciate sopra le immagini, con spaziatura fissa 5 mm anche senza segni di
  taglio (posizioni sbagliate); etichette fuori dall'area stampabile.
- TIFF/BMP/WebP accettati ma la generazione falliva (pdf-lib accetta solo JPG/PNG): ora convertiti.

Aggiunta la modalita' **Libro** (brossura / punto metallico) con prolunga sul dorso, nata dal libro
di un battesimo (37 doppie pagine 61x30,5 cm su SRA3, pagina 20x20, prolunga 5 mm).

Provato in Chrome senza finestra: 37 doppie -> 76 pagine / 19 fogli SRA3, confrontato con il PDF fatto
via script (stessa imposizione); punto metallico di un PDF di 63 pagine su A4; copie con foto ruotata
90 gradi + Riempi e con pagina PDF A5 su A3: PDF uguale all'anteprima.
