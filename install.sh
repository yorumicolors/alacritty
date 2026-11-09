#!/usr/bin/env bash
# Yorumi theme installer for Alacritty (Linux & macOS)
set -euo pipefail

# ── flavour, target config, and whether to activate ────────────────────────
FLAVOUR=""
FLAVOURS="ether abyss bifrost kraken kabocha cosmic ryujin"
CONFIG=""
ACTIVATE=1

die() { echo "yorumi: $*" >&2; exit 1; }

# Print the real file $1's bytes belong in, following any final-component
# symlink chain. Plain readlink: -f is GNU, and this must also work on macOS
# and in Git Bash. Nothing is written here, so a bad link leaves the file alone.
resolve_config() {
  local cfg="$1" link hops=0
  while [ -L "$cfg" ]; do
    hops=$((hops + 1))
    if [ "$hops" -gt 40 ]; then
      echo "yorumi: $1 is a symbolic link loop; configuration unchanged" >&2
      return 1
    fi
    if ! link=$(readlink "$cfg"); then
      echo "yorumi: cannot read the symbolic link $cfg; configuration unchanged" >&2
      return 1
    fi
    case "$link" in
      /*) cfg="$link" ;;
      *) cfg="$(dirname "$cfg")/$link" ;;
    esac
  done
  if [ "$hops" -gt 0 ] && [ ! -e "$cfg" ]; then
    echo "yorumi: $1 points at $cfg, which does not exist; configuration unchanged" >&2
    return 1
  fi
  printf '%s\n' "$cfg"
}

# replace $1 (already resolved) with $2 atomically: the temp is a safely named
# sibling of the real file, so the rename never crosses a filesystem, and a
# failed write leaves $1 exactly as it was. cp -p carries the mode, owner and
# timestamps of an existing config onto the temp, as before.
commit() {
  local tmp mode
  # Fail closed before copying: cp -p would clone an immutable (uchg) or
  # otherwise unwritable config's flags onto the temp, which could then be
  # neither written nor removed. An append-open writes no bytes, and it only
  # runs for a file that already exists.
  if [ -e "$1" ] && ! : 2>/dev/null >> "$1"; then
    echo "yorumi: $1 is not writable (read-only or protected); configuration unchanged" >&2
    return 1
  fi
  if ! tmp=$(mktemp "$1.yorumi-tmp.XXXXXX"); then
    echo "yorumi: cannot create a temporary file next to $1" >&2
    return 1
  fi
  if [ -e "$1" ]; then
    cp -p "$1" "$tmp" || { rm -f "$tmp"; return 1; }
  else
    # a fresh config keeps the mode a `: >` under this umask would have given it
    mode=$(umask)
    chmod "$(printf '%o' "$(( 0666 & ~0$mode ))")" "$tmp" || { rm -f "$tmp"; return 1; }
  fi
  if cat "$2" > "$tmp" && mv "$tmp" "$1"; then
    return 0
  fi
  rm -f "$tmp"
  return 1
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

if [[ "${XDG_CONFIG_HOME:-}" = /* ]]; then
  _YORUMI_XDG="$XDG_CONFIG_HOME"
else
  _YORUMI_XDG="$HOME/.config"
fi
_YORUMI_CFG=""
for _c in \
  "$_YORUMI_XDG/alacritty/alacritty.toml" \
  "$_YORUMI_XDG/alacritty.toml" \
  "$HOME/.config/alacritty/alacritty.toml" \
  "$HOME/.alacritty.toml"; do
  if [ -e "$_c" ]; then _YORUMI_CFG="$_c"; break; fi
done
[ -z "$_YORUMI_CFG" ] && _YORUMI_CFG="$_YORUMI_XDG/alacritty/alacritty.toml"
DEFAULT_CONFIG="$_YORUMI_CFG"

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


DEST_DIR="$_YORUMI_XDG/alacritty/themes"
mkdir -p "$DEST_DIR"
DEST_DIR="$(cd "$DEST_DIR" && pwd -P)"

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
# `import` is an option of the `general` table: appended, it would belong to
# whatever table came last, and a second one inside `[general]` is a duplicate
# key. Placement: the marked entry is the last element of that table's import
# array, added to `[general]` when the table has none, and a `[general]` table
# is only ever created at the end of a config that has none — above the root
# keys it would re-parent them.
#
# A TOML scanner makes the edit, not line regexes: delimiters count only outside
# strings and comments, `["general"]` is `general`, a missing trailing comma is
# added, CRLF survives, and every marker block is removed before one is written.
# Nested or unpaired markers, and anything the scanner cannot read (duplicate
# `[general]`, inline table, non-list or escaped-key `import`), are refused with
# the line number, and the config is left untouched.

write_block() {
  CONFIG="${CONFIG:-$DEFAULT_CONFIG}"
  CONFIG_REAL=$(resolve_config "$CONFIG") || exit 1
  mkdir -p "$(dirname "$CONFIG_REAL")" || die "cannot create $(dirname "$CONFIG_REAL")"

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT

  # a missing config is a fresh one: the scanner reads an empty file rather
  # than an unopenable name, so that case still gets the whole block
  CONFIG_IN="$CONFIG_REAL"
  [ -e "$CONFIG_REAL" ] || CONFIG_IN=/dev/null

  # YR_PATH travels in the environment: -v would eat backslashes in the path,
  # and awk builds the TOML string, so no directory name can end it early.
  # YR_CFG stays the path the user named so diagnostics point at it.
  if ! YR_CFG="$CONFIG" YR_PATH="$DEST_DIR/yorumi-$FLAVOUR.toml" awk '
    BEGIN {
      CFG = ENVIRON["YR_CFG"]
      DQ = sprintf("%c", 34); SQ = sprintf("%c", 39); BS = sprintf("%c", 92)
      PAD = "    "
      MK_B = "# >>> yorumi >>>"
      MK_E = "# <<< yorumi <<<"
      GS = "general" SUBSEP
      GI = "general" SUBSEP "import"
      GIS = GI SUBSEP
      for (i = 1; i < 32; i++) ORD[sprintf("%c", i)] = i
      ORD[sprintf("%c", 127)] = 127
      PATHQ = toml_string(ENVIRON["YR_PATH"])
      n = 0
    }

    # addresses are (line, column) pairs: the cursor is cl/cp, so a `[`, `]` or
    # `,` inside a filename or a comment is data and never a delimiter
    function fail(msg) {
      printf "yorumi: %s:%d: %s\n", CFG, ((cl in OMAP) ? OMAP[cl] : cl), msg > "/dev/stderr"
      exit 1
    }

    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

    function emit(i) { printf "%s%s\n", S[i], (CR[i] ? "\r" : "") }
    function emitln(s, crf) { printf "%s%s\n", s, (crf ? "\r" : "") }
    function indent_of(i,   s) { s = S[i]; sub(/[^ \t].*$/, "", s); return s }

    # quotes, backslashes and control bytes escaped, so a directory name cannot
    # end the string or the line it sits on
    function toml_string(s,   out, i, c) {
      out = DQ
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == BS) out = out BS BS
        else if (c == DQ) out = out BS DQ
        else if (c == "\n") out = out BS "n"
        else if (c == "\r") out = out BS "r"
        else if (c == "\t") out = out BS "t"
        else if (c in ORD) out = out sprintf("%su%04X", BS, ORD[c])
        else out = out c
      }
      return out DQ
    }

    # cursor on an opening quote, left after the closing one; only the
    # triple-quoted forms may cross a line
    function scan_string(   q, ml, c) {
      q = substr(S[cl], cp, 1)
      ml = (substr(S[cl], cp + 1, 1) == q && substr(S[cl], cp + 2, 1) == q)
      cp += ml ? 3 : 1
      while (cl <= n) {
        if (cp > length(S[cl])) {
          if (!ml) fail("a string is not closed on this line")
          cl++; cp = 1
          continue
        }
        c = substr(S[cl], cp, 1)
        if (q == DQ && c == BS) { cp += 2; continue }
        if (c != q) { cp++; continue }
        if (!ml) { cp++; return }
        if (substr(S[cl], cp + 1, 1) == q && substr(S[cl], cp + 2, 1) == q) { cp += 3; return }
        cp++
      }
      fail("a string is not closed")
    }

    function skip_inline(   c, depth) {
      depth = 0
      while (cl <= n) {
        if (cp > length(S[cl])) { cl++; cp = 1; continue }
        c = substr(S[cl], cp, 1)
        if (c == "#") { cp = length(S[cl]) + 1; continue }
        if (c == DQ || c == SQ) { scan_string(); continue }
        if (c == "{") { depth++; cp++; continue }
        if (c == "}") { depth--; cp++; if (depth == 0) return; continue }
        cp++
      }
      fail("an inline table is not closed")
    }

    # the import array: nested brackets, strings and comments are stepped over,
    # and the last element character is remembered so a missing `,` is added
    # instead of assumed
    function scan_array(   c, depth) {
      depth = 0; LL = 0; LC = 0
      while (cl <= n) {
        if (cp > length(S[cl])) { cl++; cp = 1; continue }
        c = substr(S[cl], cp, 1)
        if (c == "#") { cp = length(S[cl]) + 1; continue }
        if (c == DQ || c == SQ) { scan_string(); LL = cl; LC = cp - 1; continue }
        if (c == "[") { depth++; cp++; continue }
        if (c == "]") {
          depth--
          if (depth == 0) { CLOSE_L = cl; CLOSE_C = cp; cp++; return }
          LL = cl; LC = cp; cp++; continue
        }
        if (c == "{") { skip_inline(); LL = cl; LC = cp - 1; continue }
        if (c != " " && c != "\t") { LL = cl; LC = cp }
        cp++
      }
      fail("the import array is not closed")
    }

    function scan_value(   c) {
      c = substr(S[cl], cp, 1)
      if (c == "[") { scan_array(); return "array" }
      if (c == "{") { skip_inline(); return "inline" }
      if (c == DQ || c == SQ) { scan_string(); return "string" }
      while (cp <= length(S[cl])) {
        c = substr(S[cl], cp, 1)
        if (c == " " || c == "\t" || c == "," || c == "]" || c == "}" || c == "#") break
        cp++
      }
      return "other"
    }

    # `a`, `"a.b"` and `a.b` all become SUBSEP-joined paths
    function read_keypath(   key, np, c, p, part, sl) {
      key = ""; np = 0
      while (1) {
        while (cp <= length(S[cl]) && ((c = substr(S[cl], cp, 1)) == " " || c == "\t")) cp++
        c = substr(S[cl], cp, 1)
        if (c == DQ || c == SQ) {
          sl = cl; p = cp + 1
          scan_string()
          if (cl != sl) fail("a string used as a key cannot span lines")
          part = substr(S[sl], p, cp - 1 - p)
          if (c == DQ && index(part, BS)) {
            fail("an escaped quoted key is not supported here; write the key without escapes")
          }
        } else if (c ~ /[A-Za-z0-9_-]/) {
          part = ""
          while (cp <= length(S[cl]) && (c = substr(S[cl], cp, 1)) ~ /[A-Za-z0-9_-]/) { part = part c; cp++ }
        } else break
        np++
        key = (np == 1) ? part : key SUBSEP part
        while (cp <= length(S[cl]) && ((c = substr(S[cl], cp, 1)) == " " || c == "\t")) cp++
        if (substr(S[cl], cp, 1) != ".") break
        cp++
      }
      return (np ? key : "")
    }

    function parse_header(   l, aot, path) {
      l = cl
      cp++
      aot = 0
      if (substr(S[cl], cp, 1) == "[") { aot = 1; cp++ }
      path = read_keypath()
      if (path == "") { cl = l; fail("empty table header") }
      while (cp <= length(S[cl]) && ((substr(S[cl], cp, 1) == " ") || (substr(S[cl], cp, 1) == "\t"))) cp++
      if (substr(S[cl], cp, 1) != "]") { cl = l; fail("the table header is not closed on this line") }
      cp++
      if (aot) {
        if (substr(S[cl], cp, 1) != "]") { cl = l; fail("the array-of-tables header is not closed on this line") }
        cp++
      }
      while (cp <= length(S[cl]) && ((substr(S[cl], cp, 1) == " ") || (substr(S[cl], cp, 1) == "\t"))) cp++
      if (cp <= length(S[cl]) && substr(S[cl], cp, 1) != "#") { cl = l; fail("unexpected text after the table header") }
      cp = length(S[cl]) + 1

      TBL = path
      if (path == "general") {
        if (aot) { cl = l; fail("[[general]] is an array of tables; alacritty reads one [general] table") }
        if (GLINE) { cl = l; fail("a second [general] table; the first is at line " GLINE) }
        GLINE = l
      } else if (path == GI || index(path, GIS) == 1) {
        cl = l; fail("import is a table here instead of a list of paths")
      }
    }

    function parse_keyval(   l, path, full, kind, c, vl, vc, vel, vec) {
      l = cl
      path = read_keypath()
      if (path == "") { cl = l; fail("expected a key or a [table] header") }
      while (cp <= length(S[cl]) && ((c = substr(S[cl], cp, 1)) == " " || c == "\t")) cp++
      if (substr(S[cl], cp, 1) != "=") { cl = l; fail("expected = after the key") }
      cp++
      while (cp <= length(S[cl]) && ((c = substr(S[cl], cp, 1)) == " " || c == "\t")) cp++
      if (cp > length(S[cl]) || substr(S[cl], cp, 1) == "#") { cl = l; fail("the key has no value") }
      vl = cl; vc = cp
      kind = scan_value()
      vel = cl; vec = cp
      while (cp <= length(S[cl]) && ((c = substr(S[cl], cp, 1)) == " " || c == "\t")) cp++
      if (cp <= length(S[cl]) && substr(S[cl], cp, 1) != "#") { cl = l; fail("unexpected text after the value") }
      cp = length(S[cl]) + 1

      full = (TBL == "") ? path : TBL SUBSEP path
      if ((TBL == "general" && index(path, "import" SUBSEP) == 1) || (TBL == "" && index(path, GIS) == 1)) {
        cl = l; fail("import is a table here instead of a list of paths")
      }
      if (TBL == "" && (path == "general" || index(path, GS) == 1)) {
        if (path == "general" && kind != "inline") { cl = l; fail("general is not a table") }
        if (path == "general") GINLINE = l
        GDDEF = l
      }
      if (full != GI && !(TBL == "" && path == "import")) return
      if (SEEN[full]) { cl = l; fail("import is defined twice; the first is at line " SEEN[full]) }
      SEEN[full] = l
      ICNT++
      IST[ICNT, "path"] = full; IST[ICNT, "kind"] = kind
      IST[ICNT, "line"] = l
      IST[ICNT, "vl"] = vl; IST[ICNT, "vc"] = vc
      IST[ICNT, "vel"] = vel; IST[ICNT, "vec"] = vec
      if (kind == "array") {
        IST[ICNT, "cl"] = CLOSE_L; IST[ICNT, "cc"] = CLOSE_C
        IST[ICNT, "ll"] = LL; IST[ICNT, "lc"] = LC
      }
    }

    function parse(   c, k) {
      TBL = ""; GLINE = 0; GINLINE = 0; GDDEF = 0; ICNT = 0
      cl = 1; cp = 1
      while (cl <= n) {
        if (cp > length(S[cl])) { cl++; cp = 1; continue }
        c = substr(S[cl], cp, 1)
        if (c == " " || c == "\t") { cp++; continue }
        if (c == "#") { cp = length(S[cl]) + 1; continue }
        if (c == "[") { parse_header(); continue }
        parse_keyval()
      }
      if (GLINE && GDDEF) {
        cl = GDDEF
        fail("general is defined twice: a [general] table at line " GLINE " and a key at line " GDDEF)
      }
      if (GINLINE) {
        cl = GINLINE
        fail("general is written as an inline table; this installer will not rewrite one")
      }
      for (k = 1; k <= ICNT; k++) {
        if (IST[k, "kind"] == "inline" || IST[k, "kind"] == "other") {
          cl = IST[k, "line"]
          fail("import is not a list of paths")
        }
      }
    }

    # markers are comments on a line of their own: every block is removed, and
    # a file whose markers nest or dangle is refused before a byte is written
    function find_markers(   c, t) {
      cl = 1; cp = 1; nb = 0
      while (cl <= n) {
        if (cp > length(S[cl])) { cl++; cp = 1; continue }
        c = substr(S[cl], cp, 1)
        if (c == "#") {
          t = trim(S[cl])
          if (t == MK_B || t == MK_E) { nb++; MT[nb] = cl; MH[nb] = t }
          cp = length(S[cl]) + 1
          continue
        }
        if (c == DQ || c == SQ) { scan_string(); continue }
        cp++
      }
    }

    function check_markers(   k, openl) {
      openl = 0; nblk = 0
      for (k = 1; k <= nb; k++) {
        if (MH[k] == MK_B) {
          if (openl) { cl = MT[k]; fail("this marker opens inside the block that starts at line " openl) }
          openl = MT[k]
        } else {
          if (!openl) { cl = MT[k]; fail("this closing marker has no opening marker before it") }
          nblk++; BK_S[nblk] = openl; BK_E[nblk] = MT[k]
          openl = 0
        }
      }
      if (openl) { cl = openl; fail("this opening marker is never closed") }
    }

    function strip_blocks(   i, j, m) {
      m = 0; j = 1
      for (i = 1; i <= n; i++) {
        if (j <= nblk && i == BK_S[j]) { i = BK_E[j]; j++; continue }
        m++; TMP[m] = S[i]; TMPCR[m] = CR[i]; OMAP[m] = i
      }
      for (i = 1; i <= m; i++) { S[i] = TMP[i]; CR[i] = TMPCR[i] }
      n = m
    }

    function insert_after(gl,   i, crf) {
      crf = CR[gl]
      for (i = 1; i <= gl; i++) emit(i)
      emitln("import = [", crf)
      emitln(PAD MK_B, crf)
      emitln(PAD PATHQ ",", crf)
      emitln(PAD MK_E, crf)
      emitln("]", crf)
      for (i = gl + 1; i <= n; i++) emit(i)
    }

    function append_table(   i, crf) {
      crf = (n ? CR[n] : 0)
      for (i = 1; i <= n; i++) emit(i)
      if (n && trim(S[n]) != "") emitln("", crf)
      emitln("[general]", crf)
      emitln("import = [", crf)
      emitln(PAD MK_B, crf)
      emitln(PAD PATHQ ",", crf)
      emitln(PAD MK_E, crf)
      emitln("]", crf)
    }

    # the entry goes last, before the `]`; a `]` with text before it on the same
    # line is split there, so the markers stay comments on their own lines
    function splice_array(k,   i, ind, pad, whole, crf, ll, lc, cll, clc) {
      ll = IST[k, "ll"]; lc = IST[k, "lc"]
      cll = IST[k, "cl"]; clc = IST[k, "cc"]
      crf = CR[cll]
      if (ll && substr(S[ll], lc, 1) != ",") {
        S[ll] = substr(S[ll], 1, lc) "," substr(S[ll], lc + 1)
        if (ll == cll && lc < clc) clc++
      }
      ind = indent_of(cll)
      pad = ind PAD
      whole = (trim(substr(S[cll], 1, clc - 1)) == "")
      for (i = 1; i < cll; i++) emit(i)
      if (!whole) emitln(substr(S[cll], 1, clc - 1), crf)
      emitln(pad MK_B, crf)
      emitln(pad PATHQ ",", crf)
      emitln(pad MK_E, crf)
      if (whole) {
        for (i = cll; i <= n; i++) emit(i)
      } else {
        emitln(substr(S[cll], clc), crf)
        for (i = cll + 1; i <= n; i++) emit(i)
      }
    }

    # `import = "one.toml"` is a list of one: kept as written, made a list
    function expand_string(k,   i, ind, pad, crf, vl, vc, vel, vec, tail, kl) {
      vl = IST[k, "vl"]; vc = IST[k, "vc"]
      vel = IST[k, "vel"]; vec = IST[k, "vec"]
      kl = IST[k, "line"]
      crf = CR[kl]
      ind = indent_of(vl)
      pad = ind PAD
      tail = substr(S[vel], vec)
      for (i = 1; i < kl; i++) emit(i)
      if (vel == kl) {
        emitln(substr(S[vl], 1, vc - 1) "[" substr(S[vl], vc, vec - vc) ",", crf)
      } else {
        emitln(substr(S[vl], 1, vc - 1) "[" substr(S[vl], vc), crf)
        for (i = kl + 1; i < vel; i++) emit(i)
        emitln(substr(S[vel], 1, vec - 1) ",", crf)
      }
      emitln(pad MK_B, crf)
      emitln(pad PATHQ ",", crf)
      emitln(pad MK_E, crf)
      emitln(ind "]" tail, crf)
    }

    function render(   gk, i) {
      gk = 0
      for (i = 1; i <= ICNT; i++) if (IST[i, "path"] == GI) gk = i
      if (gk) {
        if (IST[gk, "kind"] == "string") expand_string(gk)
        else splice_array(gk)
        return
      }
      if (GLINE) { insert_after(GLINE); return }
      if (ICNT) {
        if (IST[1, "kind"] == "string") expand_string(1)
        else splice_array(1)
        return
      }
      if (GDDEF) { cl = GDDEF; fail("general is defined by a key here, so there is no table to add import to") }
      append_table()
    }

    { S[NR] = $0; n = NR }

    END {
      for (i = 1; i <= n; i++) {
        CR[i] = 0
        if (length(S[i]) && substr(S[i], length(S[i])) == "\r") {
          CR[i] = 1
          S[i] = substr(S[i], 1, length(S[i]) - 1)
        }
      }
      find_markers()
      check_markers()
      strip_blocks()
      parse()
      render()
    }
  ' "$CONFIG_IN" > "$work/out"; then
    echo "yorumi: $CONFIG was not touched; fix the line above and run this again." >&2
    exit 1
  fi

  if ! cmp -s "$CONFIG_REAL" "$work/out"; then
    if [ -e "$CONFIG_REAL" ] && ! : 2>/dev/null >> "$CONFIG_REAL"; then
      echo "yorumi: $CONFIG_REAL is not writable (read-only or protected); configuration unchanged" >&2
      return 1
    fi
    [ -e "$CONFIG_REAL.yorumi-backup" ] || [ ! -s "$CONFIG_REAL" ] || cp "$CONFIG_REAL" "$CONFIG_REAL.yorumi-backup"
    commit "$CONFIG_REAL" "$work/out"
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
