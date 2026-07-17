#!/usr/bin/env bash
set -euo pipefail
APP="LangSwitcher"
DERIVED=".build_release/DerivedData"
APP_SRC="${DERIVED}/Build/Products/Release/${APP}.app"
APP_DEST="/Applications/${APP}.app"

echo "▶ Building…"
xcodebuild -project "${APP}.xcodeproj" -scheme "${APP}" -configuration Release \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES \
  build 2>&1 | grep -E "error:|Build succeeded|Build FAILED" || true

[ -d "$APP_SRC" ] || { echo "✗ Build failed"; exit 1; }

echo "▶ Installing to ${APP_DEST}…"
if pgrep -x "${APP}" > /dev/null 2>&1; then pkill -x "${APP}" || true; sleep 0.5; fi

/usr/bin/tccutil reset Accessibility com.langswitcher.LangSwitcher 2>/dev/null || true
mkdir -p "${APP_DEST}"
rsync -a --delete "${APP_SRC}/" "${APP_DEST}/"   # rsync (not rm+cp) preserves bundle identity

echo "▶ Launching ${APP}…"
open "${APP_DEST}"
echo "✓ ${APP} installed and running"
