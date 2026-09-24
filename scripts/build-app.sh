#!/bin/bash
# SwiftPM でビルドした実行ファイルを FreeSlots.app に包んで署名する。
#
# カレンダーの許可はアプリの署名にひもづくので、ad-hoc 署名（既定）だと
# ビルドし直すたびに許可を求められることがある。Apple Development 証明書があれば
#   SIGN_IDENTITY="Apple Development: ..." ./scripts/build-app.sh
# のように指定すると許可が引き継がれる。
set -euo pipefail

cd "$(dirname "$0")/.."

swift build -c release
BIN_DIR=$(swift build -c release --show-bin-path)

APP=build/FreeSlots.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/FreeSlots" "$APP/Contents/MacOS/FreeSlots"
cp Resources/Info.plist "$APP/Contents/Info.plist"

codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"

echo "==> $APP"
