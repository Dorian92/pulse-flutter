#!/usr/bin/env bash
# Fixture-based phone screenshots (skipped by CI — lives under tool/, not test/).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${SCREENSHOT_DIR:-/opt/cursor/artifacts/screenshots}"
export PATH="${HOME}/development/flutter/bin:${PATH:-/usr/bin}"

mkdir -p "$OUT"
cd "$ROOT"

flutter test tool/screenshot_capture_test.dart \
  --dart-define="SCREENSHOT_DIR=$OUT"

echo "Screenshots written to $OUT"
