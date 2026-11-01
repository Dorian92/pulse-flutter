#!/usr/bin/env bash
# Ensures committed generated sources match local codegen.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter gen-l10n

if ! git diff --quiet -- lang lib/l10n; then
  echo 'Generated l10n is out of date. Run: flutter gen-l10n'
  git diff -- lang lib/l10n || true
  exit 1
fi

if grep -q 'build_runner' pubspec.yaml; then
  dart run build_runner build --delete-conflicting-outputs
  if ! git diff --quiet; then
    echo 'build_runner output is out of date.'
    git diff || true
    exit 1
  fi
fi

echo 'Generated code is up to date.'
