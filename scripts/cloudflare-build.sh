#!/usr/bin/env bash
# Cloudflare Pages build for the SwarnaLekh Flutter web PWA.
#
# Pages' build image ships Node, not Flutter, so we fetch an SDK per build.
# apps/mobile/.env is gitignored and never reaches CI, so the dart-defines are
# rebuilt here from Pages environment variables and handed to Flutter through
# the same --dart-define-from-file path that scripts/flutter_with_env.sh uses
# locally, keeping local and deployed builds configured identically.
#
# Safe to run on a dev machine: it reuses a Flutter already on PATH and writes
# its generated env to a scratch file rather than touching apps/mobile/.env.
set -euo pipefail

FLUTTER_REF="${FLUTTER_REF:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
export FLUTTER_SUPPRESS_ANALYTICS=true

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/apps/mobile"

if ! command -v flutter >/dev/null 2>&1; then
  if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
    echo "==> Fetching Flutter ($FLUTTER_REF)"
    git clone --depth 1 --branch "$FLUTTER_REF" \
      https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
  # The SDK lands outside the repo checkout; without this Flutter's own git
  # calls can trip Git's dubious-ownership guard on the build container.
  git config --global --add safe.directory "$FLUTTER_HOME" || true
fi

flutter --version

# API_BASE_URL is the only dart-define the app actually reads (see
# apps/mobile/lib/core/network/api_client.dart). It already defaults to the
# production API in Dart, so this stays optional rather than required.
API_BASE_URL="${API_BASE_URL:-https://swarnalekh-erp-api.vercel.app/api/v1}"

# Deliberately not apps/mobile/.env — that is the developer's own file. The
# .local suffix keeps this generated copy inside the existing gitignore rule.
ENV_FILE="$MOBILE_DIR/.env.cloudflare.local"
printf 'API_BASE_URL=%s\n' "$API_BASE_URL" >"$ENV_FILE"
echo "==> Building against API_BASE_URL=$API_BASE_URL"

cd "$MOBILE_DIR"
flutter pub get
flutter build web --release --dart-define-from-file="$ENV_FILE"

echo "==> Build output: $MOBILE_DIR/build/web"
