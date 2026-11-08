#!/usr/bin/env bash
# Yorumi theme installer for Alacritty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

# No default flavour. Ask, or fail where nobody can answer.
ask_flavour() {
  # a real open, not a -r test: /dev/tty exists even when nothing is attached
  if ! { exec 3<>/dev/tty; } 2>/dev/null; then
    echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
    exit 2
  fi
  i=0
  {
    echo "Yorumi flavours:"
    for f in $FLAVOURS; do i=$((i + 1)); echo "  $i) $f"; done
  } >&3
  while :; do
    printf 'flavour (1-%s or a name): ' "$i" >&3
    answer=""
    IFS= read -r answer <&3 || {
      exec 3>&-
      echo "no flavour given. pass --flavour <name>: $FLAVOURS" >&2
      exit 2
    }
    [ -z "$answer" ] && continue
    case "$answer" in
      *[!0-9]*) candidate="$answer" ;;
      *) candidate=""
         n=0
         for f in $FLAVOURS; do n=$((n + 1)); [ "$n" -eq "$answer" ] && candidate="$f"; done ;;
    esac
    case " $FLAVOURS " in
      *" $candidate "*) FLAVOUR="$candidate"; exec 3>&-; return 0 ;;
    esac
    printf 'not a flavour: %s\n' "$answer" >&3
  done
}

DEFAULT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/alacritty.toml"

while [ $# -gt 0 ]; do
  case "$1" in
    --flavour|-f)  FLAVOUR="${2:-}"; shift 2 ;;
    --config|-c)   CONFIG="${2:-}";  shift 2 ;;
    --no-activate) ACTIVATE=0; shift ;;
    -h|--help)
      echo "usage: ./install.sh [--flavour <name>] [--config <path>] [--no-activate]"
      echo "flavours: $FLAVOURS"
      exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -n "$FLAVOUR" ]; then
  case " $FLAVOURS " in
    *" $FLAVOUR "*) ;;
    *) echo "unknown flavour '$FLAVOUR'. One of: $FLAVOURS" >&2; exit 2 ;;
  esac
fi

[ -z "$FLAVOUR" ] && [ "$ACTIVATE" -eq 1 ] && ask_flavour


DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes"
mkdir -p "$DEST_DIR"

RAW_BASE="https://raw.githubusercontent.com/yorumicolors/yorumi-alacritty/main"
FILES=("yorumi-ether.toml" "yorumi-abyss.toml" "yorumi-bifrost.toml" "yorumi-kraken.toml" "yorumi-kabocha.toml" "yorumi-cosmic.toml" "yorumi-ryujin.toml")

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
fi

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

Successfully installed the Yorumi files for Alacritty.

Activate it — one marked entry inside the `import` array of `[general]`. Any
imports already there stay; every run rewrites only this entry:

    [general]
    import = [
        # >>> yorumi >>>
        "~/.config/alacritty/themes/yorumi-abyss.toml",
        # <<< yorumi <<<
    ]
INFO

# ── activation: the key has a home, and the end of the file is not it ─────
# `import` is an option of the `general` table. Appending it to a config whose
# last table is `[env]` makes it an env var — "invalid type: sequence, expected
# a string" — and a second `import` inside `[general]` is a duplicate key. So:
# add our file to the import array that is already there, or create one.
BEGIN="# >>> yorumi >>>"
END="# <<< yorumi <<<"

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  mkdir -p "$(dirname "$CONFIG")"
  [ -e "$CONFIG" ] || : > "$CONFIG"

  begins=$(grep -c -x -F -e "$BEGIN" "$CONFIG" || true)
  ends=$(grep -c -x -F -e "$END" "$CONFIG" || true)
  if [ "$begins" != "$ends" ]; then
    echo "yorumi: $CONFIG has $begins '$BEGIN' and $ends '$END' markers." >&2
    echo "yorumi: the config was not touched; fix or delete those lines, then run this again." >&2
    exit 1
  fi

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  printf '"%s/yorumi-%s.toml",\n' "$DEST_DIR" "$FLAVOUR" > "$work/body"

  awk -v b="$BEGIN" -v e="$END" -v bf="$work/body" '
    { L[NR] = $0 }
    function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x); return x }
    END {
      n = NR

      # an existing region is replaced where it sits
      for (i = 1; i <= n; i++) if (trim(L[i]) == b) { at = i; break }
      if (at) {
        ind = L[at]; sub(/[^ \t].*$/, "", ind)
        for (i = 1; i < at; i++) print L[i]
        print ind b
        while ((getline line < bf) > 0) print ind line
        close(bf); print ind e
        for (i = at + 1; i <= n && trim(L[i]) != e; i++) ;
        for (i = i + 1; i <= n; i++) print L[i]
        exit
      }

      # where does `import` belong: [general], or the root of a legacy file
      gs = 0
      for (i = 1; i <= n; i++) if (L[i] ~ /^[ \t]*\[general\][ \t]*(#.*)?$/) { gs = i; break }
      ks = 0
      if (gs) {
        ge = n
        for (i = gs + 1; i <= n; i++) if (L[i] ~ /^[ \t]*\[/) { ge = i - 1; break }
        for (i = gs + 1; i <= ge; i++) if (L[i] ~ /^[ \t]*import[ \t]*=/) { ks = i; break }
      } else {
        for (i = 1; i <= n; i++) {
          if (L[i] ~ /^[ \t]*\[/) break
          if (L[i] ~ /^[ \t]*import[ \t]*=/) { ks = i; break }
        }
      }

      if (!ks) {
        if (gs) {
          for (i = 1; i <= gs; i++) print L[i]
          print "import = ["
          print "    " b
          while ((getline line < bf) > 0) print "    " line
          close(bf); print "    " e
          print "]"
          for (i = gs + 1; i <= n; i++) print L[i]
        } else {
          print "[general]"
          print "import = ["
          print "    " b
          while ((getline line < bf) > 0) print "    " line
          close(bf); print "    " e
          print "]"
          if (n) print ""
          for (i = 1; i <= n; i++) print L[i]
        }
        exit
      }

      open = index(L[ks], "[")
      if (!open) {                       # `import = "one.toml"`: an array now
        v = L[ks]; sub(/^[^=]*=[ \t]*/, "", v); gsub(/^"|"[ \t]*$/, "", v)
        for (i = 1; i < ks; i++) print L[i]
        print "import = ["
        print "    \"" v "\","
        print "    " b
        while ((getline line < bf) > 0) print "    " line
        close(bf); print "    " e
        print "]"
        for (i = ks + 1; i <= n; i++) print L[i]
        exit
      }
      rest = substr(L[ks], open + 1)
      if (index(rest, "]")) {            # `import = ["a.toml"]`: one line
        inner = substr(rest, 1, index(rest, "]") - 1)
        for (i = 1; i < ks; i++) print L[i]
        print "import = ["
        m = split(inner, p, ",")
        for (j = 1; j <= m; j++) { el = trim(p[j]); if (el != "") print "    " el "," }
        print "    " b
        while ((getline line < bf) > 0) print "    " line
        close(bf); print "    " e
        print "]"
        for (i = ks + 1; i <= n; i++) print L[i]
        exit
      }
      depth = 0; cl = 0                # a multi-line array: add before its `]`
      for (i = ks; i <= n; i++) {
        s = L[i]
        for (k = 1; k <= length(s); k++) {
          c = substr(s, k, 1)
          if (c == "[") depth++
          else if (c == "]") depth--
        }
        if (depth <= 0) { cl = i; break }
      }
      for (i = 1; i < cl; i++) print L[i]
      print "    " b
      while ((getline line < bf) > 0) print "    " line
      close(bf); print "    " e
      for (i = cl; i <= n; i++) print L[i]
    }
  ' "$CONFIG" > "$work/out"

  if ! cmp -s "$CONFIG" "$work/out"; then
    [ -e "$CONFIG.yorumi-backup" ] || cp "$CONFIG" "$CONFIG.yorumi-backup"
    cp "$work/out" "$CONFIG"
    echo "✓ Block written to $CONFIG ($FLAVOUR)"
  else
    echo "✓ Block already current in $CONFIG ($FLAVOUR)"
  fi
}

if [ "$ACTIVATE" -eq 1 ]; then
  write_block
else
  echo "• Activation skipped (--no-activate); the files are installed."
fi
