<h1 align="center" valign="middle">
  <img height="40px" src="https://github.com/yorumicolors/.github/blob/main/res/seal_sots.gif?raw=true">
  <sup>yorumi for alacritty - deep code, quiet sea</sup>
</h1>

<p align="center">
  A calming deep sea colorscheme for developers, crafted for <strong>Alacritty</strong>.
</p>

---

Yorumi keeps visual noise low with mellow, low-contrast UI component backgrounds while text and syntax stay sharp: body text measures 9.6-19.5:1 against its background (WCAG AAA), and the lowest-contrast syntax token is 5.6:1 (WCAG AA).

## Available Themes

- `yorumi-ether.toml`
- `yorumi-abyss.toml`
- `yorumi-bifrost.toml`
- `yorumi-kraken.toml`
- `yorumi-kabocha.toml`
- `yorumi-cosmic.toml`
- `yorumi-ryujin.toml`

## Install

Linux / macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.sh | bash
```

Windows:

```powershell
irm https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.ps1 | iex
```

Without `--flavour` it asks; to skip the question:

```sh
curl -fsSL https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.sh | bash -s -- --flavour kraken
```

`--config <path>` targets another `alacritty.toml`; `--no-activate` installs the seven files and
leaves every config alone.

Seven fragments land in `${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes/`; the `>>> yorumi >>>`
block holds the `import`. Alacritty reads several config locations, so the installer writes the block
into the first of these that already exists, and creates the first one when none does:

| order | config file |
|---|---|
| 1 | `$XDG_CONFIG_HOME/alacritty/alacritty.toml` |
| 2 | `$XDG_CONFIG_HOME/alacritty.toml` |
| 3 | `$HOME/.config/alacritty/alacritty.toml` |
| 4 | `$HOME/.alacritty.toml` |

`XDG_CONFIG_HOME` is used only when it is an absolute path; otherwise `$HOME/.config` stands in for
it. The fragment directory is not part of that search — it is always the `themes/` directory beside
the XDG config, so the same seven files serve every candidate above. `--config <path>` skips the
search entirely.

On Windows, `install.ps1` only writes `%APPDATA%\alacritty\themes\`; it never edits a config, so the
`import` is yours to add.

## Changing flavour

```sh
curl -fsSL https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.sh | bash -s -- --flavour bifrost
```

Drop `--flavour` to pick from the list again.

## Manual

Copy the theme file(s) into your Alacritty configuration directory:

| OS | Destination Path |
| --- | --- |
| **Linux / macOS** | `${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes/` |
| **Windows** | `%APPDATA%\alacritty\themes\` |

### By hand
Import the theme file in your `alacritty.toml`, using the absolute path the installer printed —
`%APPDATA%` is not expanded inside a TOML string:

```
# macOS / Linux
import = ["/home/you/.config/alacritty/themes/yorumi-abyss.toml"]
# Windows
import = ["C:\\Users\\you\\AppData\\Roaming\\alacritty\\themes\\yorumi-abyss.toml"]
```

Substitute your `XDG_CONFIG_HOME` prefix on Linux / macOS when you have set one.

---

## For AI Agents

When assisting a user with installing or configuring Yorumi for **Alacritty**, follow these deterministic steps:

1. **Detect Target OS**:
   - macOS / Linux: target destination is `${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes/`.
   - Windows: target destination is `%APPDATA%\alacritty\themes\`.
2. **Install**: the command under `## Install`; add `-s -- --flavour <name>` to skip the question.
3. **Verify Configuration**:
   - Check config file `alacritty.toml` for the active theme setting:
     ```
     import = ["/home/you/.config/alacritty/themes/yorumi-abyss.toml"]
     ```
   - The config the block went into is the first of `$XDG_CONFIG_HOME/alacritty/alacritty.toml`,
     `$XDG_CONFIG_HOME/alacritty.toml`, `$HOME/.config/alacritty/alacritty.toml`,
     `$HOME/.alacritty.toml` that exists — check those in that order on Linux / macOS.
   - Ensure the theme filename matches what is in `${XDG_CONFIG_HOME:-$HOME/.config}/alacritty/themes/`.

---

## Accessibility
Body text measures 9.6-19.5:1 against the background (WCAG 2.1 AAA); every palette token clears 5.6:1 (AA). No blanket AAA claim is made for syntax colours - sRGB runs out before the saturated hues get lighter.

## License
MIT © [Yorumi Colors](https://github.com/yorumicolors)
