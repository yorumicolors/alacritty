#!/usr/bin/env bash
# Yorumi theme installer for Alacritty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

die() { echo "yorumi: $*" >&2; exit 1; }

# replace $1 with $2 atomically, keeping the original file mode
commit() {
  local tmp="$1.yorumi-tmp.$$"
  if [ -e "$1" ]; then cp -p "$1" "$tmp"; else : > "$tmp"; fi
  if cat "$2" > "$tmp"; then mv "$tmp" "$1"; else rm -f "$tmp"; return 1; fi
}

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
    --flavour|-f)
      [ -n "${2:-}" ] || { echo "--flavour needs a flavour name. One of: $FLAVOURS" >&2; exit 2; }
      FLAVOUR="$2"; shift 2 ;;
    --config|-c)
      [ -n "${2:-}" ] || { echo "--config needs a path" >&2; exit 2; }
      CONFIG="$2"; shift 2 ;;
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
    part="$target.part.$$"
    if ! curl -fsSL "$RAW_BASE/$f" -o "$part"; then
      rm -f "$part"
      echo "yorumi: could not download $f from $RAW_BASE" >&2
      echo "yorumi: if that repository is not public yet, clone it and run ./install.sh from the checkout." >&2
      exit 3
    fi
    mv "$part" "$target"
  fi
  echo "✓ Installed: $target"
done

# ── activation: the key has a home, and the end of the file is not it ─────
# `import` is an option of the `general` table. Appending it to a config whose
# last table is `[env]` makes it an env var — "invalid type: sequence, expected
# a string" — and a second `import` inside `[general]` is a duplicate key. So:
# add our file to the import array that is already there, or create one.
#
# A config with no `[general]` table gets one appended at the end of the file,
# never at the top: a `[general]` header above the user's root-level keys would
# re-parent them into it (`colors.primary.background = …` becomes
# `general.colors.primary.background`, which alacritty ignores), and nothing
# follows an appended table, so nothing can be re-parented.
BEGIN="# >>> yorumi >>>"
END="# <<< yorumi <<<"

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  mkdir -p "$(dirname "$CONFIG")" || die "cannot create $(dirname "$CONFIG")"
  [ -e "$CONFIG" ] || : > "$CONFIG"

  counts=$(awk -v b="$BEGIN" -v e="$END" '
    function trim(x) { sub(/^[ \t]+/, "", x); sub(/[ \t]+$/, "", x); return x }
    { t = trim($0)
      if (t == b) { nb++; depth++ }
      else if (t == e) { ne++; if (depth > 0) depth--; else bad = 1 }
    }
    END { printf "%d %d %d\n", nb + 0, ne + 0, bad + 0 }' "$CONFIG")
  begins=${counts%% *}
  rest=${counts#* }
  ends=${rest% *}
  order=${rest#* }
  if [ "$begins" != "$ends" ] || [ "$order" != 0 ]; then
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

      # our entry is removed wherever it sits; the branches below add it back
      # as the LAST element of the import array, so it cannot be shadowed by a
      # sibling import and a second copy cannot survive
      k = 0; skip = 0; skipblank = 0
      for (i = 1; i <= n; i++) {
        t = trim(L[i])
        if (t == b) { skip = 1; continue }
        if (skip && t == e) { skip = 0; skipblank = 1; continue }
        if (skip) continue
        if (skipblank && t == "") { skipblank = 0; continue }
        skipblank = 0
        k++; K[k] = L[i]
      }
      n = k
      for (i = 1; i <= k; i++) L[i] = K[i]

      # where does `import` belong: [general], or the root of a legacy file
      gs = 0
      for (i = 1; i <= n; i++) if (L[i] ~ /^[ \t]*\[[ \t]*[\047"]?general[\047"]?[ \t]*\][ \t]*(#.*)?$/) { gs = i; break }
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
          for (i = 1; i <= n; i++) print L[i]
          if (n) print ""
          print "[general]"
          print "import = ["
          print "    " b
          while ((getline line < bf) > 0) print "    " line
          close(bf); print "    " e
          print "]"
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
    [ -e "$CONFIG.yorumi-backup" ] || [ ! -s "$CONFIG" ] || cp "$CONFIG" "$CONFIG.yorumi-backup"
    commit "$CONFIG" "$work/out"
    echo "✓ Block written to $CONFIG ($FLAVOUR)"
  else
    echo "✓ Block already current in $CONFIG ($FLAVOUR)"
  fi
}

if [ "$ACTIVATE" -eq 1 ]; then
  write_block
  cat <<INFO

Successfully installed the Yorumi files for Alacritty.

The palette is active through one marked entry in the \`import\` array of
\`[general]\` inside $CONFIG. Any imports already there stay; every run
rewrites only this entry:

    [general]
    import = [
        # >>> yorumi >>>
        "$DEST_DIR/yorumi-$FLAVOUR.toml",
        # <<< yorumi <<<
    ]
INFO
else
  echo "• Activation skipped (--no-activate); the files are installed."
fi
