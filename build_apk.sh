#!/usr/bin/env bash
# Construye el APK de Fútbol Survivor sin gradle (dl.google.com bloqueado).
# Pipeline: import -> export-pack (ZIP) -> fusión manual en el template APK
# preservando resources.arsc STORED -> zipalign -> apksigner.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TPL="/root/.local/share/godot/export_templates/4.2.2.stable/android_release.apk"
KEYSTORE="/opt/debug.keystore"
WORK="/tmp/fs_build"
OUT="$ROOT/build/futbol-survivor.apk"

rm -rf "$WORK"; mkdir -p "$WORK" "$ROOT/build"

echo "==> 1/5 Importando assets"
godot --headless --path "$ROOT" --import >/dev/null 2>&1 || true

echo "==> 2/5 Exportando recursos (ZIP)"
godot --headless --path "$ROOT" --export-pack "Android" "$WORK/game.zip" >/dev/null 2>&1

echo "==> 3/5 Fusionando en template APK"
python3 - "$TPL" "$WORK/game.zip" "$WORK/unsigned.apk" << 'PYEOF'
import sys, zipfile, shutil
tpl, gamezip, out = sys.argv[1:4]
src = zipfile.ZipFile(tpl)
game = zipfile.ZipFile(gamezip)

with zipfile.ZipFile(out, "w") as dst:
    # 1) copiar todo el template preservando método de compresión
    for info in src.infolist():
        data = src.read(info.filename)
        ni = zipfile.ZipInfo(info.filename, date_time=info.date_time)
        ni.compress_type = info.compress_type          # resources.arsc queda STORED
        ni.external_attr = info.external_attr
        ni.internal_attr = info.internal_attr
        ni.create_system = info.create_system
        dst.writestr(ni, data)
    # 2) inyectar recursos del juego bajo assets/<path>, STORED
    for info in game.infolist():
        data = game.read(info.filename)
        ni = zipfile.ZipInfo("assets/" + info.filename, date_time=(1980,1,1,0,0,0))
        ni.compress_type = zipfile.ZIP_STORED
        dst.writestr(ni, data)
print("   fusionado OK")
PYEOF

echo "==> 4/5 zipalign"
zipalign -p -f 4 "$WORK/unsigned.apk" "$WORK/aligned.apk"

echo "==> 5/5 Firmando"
apksigner sign --ks "$KEYSTORE" --ks-pass pass:android \
  --key-pass pass:android --ks-key-alias androiddebugkey \
  --out "$OUT" "$WORK/aligned.apk"

apksigner verify "$OUT" && echo "==> APK firmado OK: $OUT"
ls -la "$OUT"
