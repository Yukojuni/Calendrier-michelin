#!/usr/bin/env bash
# Build de la version web sur Netlify : installe Flutter (version fixée) puis compile.
# Variables d'environnement Netlify (Site configuration > Environment variables) :
#   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY  -> congés partagés. Sans elles : stockage local.
set -euo pipefail
FLUTTER_VERSION="3.47.9"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"
flutter config --no-analytics >/dev/null
flutter --version

DEFINES=()
if [ -n "${SUPABASE_URL:-}" ] && [ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]; then
  DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY")
  echo "Supabase activé"
else
  echo "Supabase non configuré : stockage local"
fi
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run "${DEFINES[@]}"
