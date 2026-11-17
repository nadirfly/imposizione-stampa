#!/bin/bash
# Pubblica una nuova versione: ./app/release.sh 1.1.0 "cosa cambia"
# Aggiorna VERSION, compila il .dmg, fa commit + tag e crea la Release su GitHub con il .dmg allegato.
# Gli utenti con l'app installata vedono l'avviso di aggiornamento al prossimo avvio.
set -euo pipefail
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { echo "uso: $0 <versione> [note]"; exit 1; }
V="$1"; NOTE="${2:-Versione $1}"
[ -s app/repo.txt ] || { echo "app/repo.txt e' vuoto: scrivi owner/nome del repo GitHub"; exit 1; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "Ci sono modifiche non committate: fai prima il commit."; exit 1; }
echo "$V" > VERSION
./app/build.sh
git add VERSION && { git diff --cached --quiet || git commit -m "Versione $V" -q; }
git tag "v$V" && git push origin HEAD "v$V"
gh release create "v$V" "dist/Imposizione-Stampa.dmg#Imposizione-Stampa.dmg" --title "Imposizione Stampa $V" --notes "$NOTE"
