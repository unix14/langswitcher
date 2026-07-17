#!/usr/bin/env bash
set -euo pipefail
APP="LangSwitcher"
VERSION="1.4"
RELEASES_DIR="releases"
DMG="${RELEASES_DIR}/${APP}-${VERSION}.dmg"
BUILD_DIR=".build_release"
DERIVED="${BUILD_DIR}/DerivedData"

mkdir -p "${RELEASES_DIR}"

xcodebuild -project "${APP}.xcodeproj" -scheme "${APP}" -configuration Release \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES \
  build 2>&1 | grep -E "error:|warning:|Build succeeded|Build FAILED" || true

APP_PATH="${DERIVED}/Build/Products/Release/${APP}.app"
[ -d "$APP_PATH" ] || { echo "✗ Build failed"; exit 1; }

STAGE="${BUILD_DIR}/dmg_stage"
rm -rf "${STAGE}"; mkdir -p "${STAGE}"
cp -R "${APP_PATH}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

[ -f "${DMG}" ] && rm "${DMG}"
hdiutil create -volname "${APP} ${VERSION}" -srcfolder "${STAGE}" -ov -format UDZO -fs HFS+ "${DMG}"
rm -rf "${STAGE}"

echo "✓ ${DMG} created ($(du -sh "${DMG}" | cut -f1))"
