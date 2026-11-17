# Note — Imposizione Stampa

Strumento di **imposizione stampa in una pagina sola**: un unico
`index.html` che monta le pagine di un PDF per la stampa (booklet/segnature).

## Come funziona

- Si apre `index.html` in un browser. Usa **pdf-lib** e **pdf.js** (caricati da
  CDN: unpkg/cdnjs) per leggere e ricomporre il PDF lato client. Nessun server,
  nessun backend, i file non escono dal browser.
- Repository pubblico: https://github.com/nadirfly/imposizione-stampa (le versioni scaricabili sono nelle Release).

## Due modalita' (schede in alto)

- **Copie su foglio**: tante copie di un documento su un foglio (step & repeat), con guida al taglio.
  Posizione, scala e rotazione del contenuto le calcola una sola funzione, `contentPlacement()`,
  usata sia dall'anteprima sia dal PDF: non duplicare quel calcolo (prima erano due e non coincidevano).
  Rotazioni nel PDF con `pdfDrawCentered()` (ruota attorno al centro); ogni copia e' ritagliata alla sua
  cella (`pdfClip`); le linee guida rosse/blu si tracciano solo fuori dalle copie.
- **Libro**: pagine singole o doppie pagine (album) su fogli piegati a meta'. Brossura (fogli piegati uno
  a uno e impilati: fronte [4k+4|4k+1], retro [4k+2|4k+3]) o punto metallico (annidati).
  **Prolunga sul dorso**: ogni pagina e' piu' larga di G verso la piega e il contenuto e' spostato di G
  verso l'esterno; nella striscia c'e' la continuazione della pagina accanto, cosi' dopo la brossura le
  foto a cavallo delle due pagine non perdono il centro. La funzione `slot()` decide cosa va in ogni
  meta' foglio; anteprima, simulazione "libro aperto" e PDF usano tutti `slot()`.

## App macOS (.dmg)

`app/` contiene il guscio nativo Swift (WebView + CUPS): `main.swift`, `build.sh`, `release.sh`, `vendor/` (pdf-lib e
pdf.js incorporati, funziona offline). `index.html` resta il sorgente unico; `build.sh` ne fa una copia con le librerie locali.
- Compilare: `./app/build.sh` -> `dist/Imposizione-Stampa.dmg` (firma ad hoc: su altri Mac si apre con tasto destro > Apri).
- Nell'app `savePdf()` passa dal guscio (pannello Salva); "Stampa su stampante" e "Stampa cartella di foto..." mandano il PDF a CUPS (`lp`)
  con `PageSize` del PPD e `fit-to-page=false`. Il menu stampanti si riempie con `lpstat -e` (nomi reali).
- D700: formati rotolo dal PPD di `EPSON_SL_D700` (4x6, 5x7, 8x10, 8x12, A4). Il colore resta al pilota Epson.
- Versione in `VERSION`; repo GitHub per gli aggiornamenti in `app/repo.txt` (owner/nome, deve essere pubblico).
  `./app/release.sh 1.1.0 "note"` compila, tagga, spinge e crea la Release col .dmg; l'app avvisa al prossimo avvio.
- Prova senza finestra: finto `window.webkit.messageHandlers.native` in Chrome (Playwright-core) che risponde come Swift.

## Prove

Si provano con Playwright + Chrome senza finestra (caricamento file, download del PDF), poi il PDF si
controlla con `pdftoppm`. Le prove fatte il 09/11/2026 sono descritte in STORIA.md.

## Note

- È un tool "usa e getta" di bottega, autoconsistente. Se serve offline, le due
  librerie da CDN andrebbero incorporate.
- Da non confondere con `intercalari-cartella-firma` (quello è il generatore
  Python degli intercalari; questo è imposizione generica di un PDF esistente).

*Storia in [STORIA.md](./STORIA.md).*
