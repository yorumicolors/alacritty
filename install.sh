#!/usr/bin/env bash
# Yorumi theme installer for Alacritty (Linux & macOS)
set -euo pipefail

DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes"
mkdir -p "$DEST_DIR"

RAW_BASE="https://raw.githubusercontent.com/yorumicolors/yorumi-alacritty/main"
FILES=("yorumi-ether.toml" "yorumi-abyss.toml" "yorumi-bifrost.toml" "yorumi-kraken.toml" "yorumi-kabocha.toml" "yorumi-cosmic.toml" "yorumi-ryujin.toml")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

echo "Installing Yorumi theme for Alacritty..."

for f in "${FILES[@]}"; do
  basename_f="$(basename "$f")"
  target="$DEST_DIR/$basename_f"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$f" ]]; then
    cp "$SCRIPT_DIR/$f" "$target"
  elif [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/$basename_f" ]]; then
    cp "$SCRIPT_DIR/$basename_f" "$target"
  else
    curl -fsSL "$RAW_BASE/$f" -o "$target"
  fi
  echo "✓ Installed: $target"
done

cat << 'INFO'

Successfully installed Yorumi for Alacritty!
Import the theme file in your `alacritty.toml`:
    import = ["~/.config/alacritty/themes/yorumi-abyss.toml"]
INFO
