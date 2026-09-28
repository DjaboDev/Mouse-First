#!/usr/bin/env bash
# Render assets/src/hero.html to preview.png (1920x1080 at 1.5x) with
# headless Chromium. Needs chromium and the JetBrainsMono Nerd Font.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chromium --headless=new --disable-gpu --hide-scrollbars \
  --window-size=1920,1080 --force-device-scale-factor=1.5 \
  --screenshot="$repo/preview.png" "file://$repo/assets/src/hero.html" >/dev/null 2>&1
echo "Wrote $repo/preview.png"
