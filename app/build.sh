#!/bin/bash
# Compila "Imposizione Stampa.app" e il .dmg. Uso: ./app/build.sh   ->  dist/Imposizione-Stampa.dmg
# index.html resta il sorgente unico: qui se ne fa una copia con le librerie locali (offline).
set -euo pipefail
cd "$(dirname "$0")/.."
NAME="Imposizione Stampa"
APP="dist/$NAME.app"
rm -rf "$APP" dist/dmg dist/Imposizione-Stampa.dmg
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/web" dist

swiftc -O app/main.swift -o "$APP/Contents/MacOS/ImposizioneStampa" -framework Cocoa -framework WebKit

cp app/vendor/*.js "$APP/Contents/Resources/web/"
python3 - <<'PY'
import re
s = open("index.html", encoding="utf-8").read()
s = s.replace("https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js", "pdf-lib.min.js")
s = s.replace('<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>',
              '<script src="pdf.min.js"></script>\n<script src="pdf.worker.min.js"></script>')  # worker come script: niente Worker da file://
s = s.replace("https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js", "pdf.worker.min.js")
assert "http" not in re.findall(r'<script src="([^"]+)"', s).__str__()
open("dist/Imposizione Stampa.app/Contents/Resources/web/index.html", "w", encoding="utf-8").write(s)
PY

cat > "$APP/Contents/Info.plist" <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Imposizione Stampa</string>
<key>CFBundleDisplayName</key><string>Imposizione Stampa</string>
<key>CFBundleIdentifier</key><string>it.bottega.imposizione-stampa</string>
<key>CFBundleExecutable</key><string>ImposizioneStampa</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>__VERSION__</string>
<key>CFBundleVersion</key><string>__VERSION__</string>
<key>ImposizioneRepo</key><string>__REPO__</string>
<key>LSMinimumSystemVersion</key><string>12.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PL

VERSION=$(tr -d "[:space:]" < VERSION); REPO=$(tr -d "[:space:]" < app/repo.txt)
sed -i "" "s#__VERSION__#$VERSION#g; s#__REPO__#$REPO#g" "$APP/Contents/Info.plist"

codesign --force --deep --sign - "$APP"   # firma ad hoc: basta per girare sul tuo Mac

mkdir -p dist/dmg
cp -R "$APP" dist/dmg/
ln -s /Applications dist/dmg/Applications
hdiutil create -volname "$NAME" -srcfolder dist/dmg -ov -format UDZO dist/Imposizione-Stampa.dmg >/dev/null
rm -rf dist/dmg
echo "Pronto: dist/Imposizione-Stampa.dmg"
