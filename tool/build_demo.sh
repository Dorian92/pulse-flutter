#!/usr/bin/env bash
# Stitch fixture screenshots into a short demo GIF + MP4 (no live network).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEMO_DIR="$ROOT/docs/demo"
ARTIFACT_DIR="${PULSE_DEMO_ARTIFACT_DIR:-/opt/cursor/artifacts/demo}"
mkdir -p "$DEMO_DIR" "$ARTIFACT_DIR"

FRAMES=(
  "$ROOT/docs/screenshots/01_markets_dark_fixture.png"
  "$ROOT/docs/screenshots/02_markets_light_fixture.png"
  "$ROOT/docs/screenshots/04_markets_search_active_fixture.png"
  "$ROOT/docs/screenshots/11_coin_detail_chart_fixture.png"
  "$ROOT/docs/screenshots/09_settings_tab_fixture.png"
  "$ROOT/docs/screenshots/10_markets_serbian_locale_fixture.png"
)

CONCAT_LIST="$(mktemp)"
trap 'rm -f "$CONCAT_LIST"' EXIT

for frame in "${FRAMES[@]}"; do
  if [[ ! -f "$frame" ]]; then
    echo "Missing frame: $frame" >&2
    exit 1
  fi
  printf "file '%s'\n" "$frame" >>"$CONCAT_LIST"
  printf "duration 2.5\n" >>"$CONCAT_LIST"
done
# Repeat last frame so ffmpeg concat demuxer keeps final image.
printf "file '%s'\n" "${FRAMES[-1]}" >>"$CONCAT_LIST"

LABEL="Pulse demo — fixture data only (not live markets)"
FILTER="scale=1080:-2:flags=lanczos,drawtext=text='${LABEL}':fontcolor=white:fontsize=22:box=1:boxcolor=black@0.55:boxborderw=8:x=(w-text_w)/2:y=h-th-24"

MP4="$DEMO_DIR/pulse_demo.mp4"
GIF="$DEMO_DIR/pulse_demo.gif"

ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" \
  -vf "$FILTER" \
  -movflags +faststart \
  -pix_fmt yuv420p \
  "$MP4"

ffmpeg -y -i "$MP4" \
  -vf "fps=8,scale=540:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  "$GIF"

cp -f "$MP4" "$ARTIFACT_DIR/"
cp -f "$GIF" "$ARTIFACT_DIR/"

echo "Demo written to $MP4 and $GIF (copied to $ARTIFACT_DIR)"
