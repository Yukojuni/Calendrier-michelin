#!/usr/bin/env bash
# Build de la version web sur Netlify : installe Flutter (version fixée) puis compile.
set -euo pipefail
FLUTTER_VERSION="3.47.9"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
