#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/apps/mobile"
ENV_FILE="${MOBILE_ENV_FILE:-$MOBILE_DIR/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  ENV_FILE="$MOBILE_DIR/.env.example"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing mobile env file. Create apps/mobile/.env from apps/mobile/.env.example." >&2
  exit 1
fi

cd "$MOBILE_DIR"
exec flutter "$@" --dart-define-from-file="$ENV_FILE"
