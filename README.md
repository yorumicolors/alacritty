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
curl -fsSL https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.sh | bash -s -- --flavour kraken
```

Windows:

```powershell
irm https://raw.githubusercontent.com/yorumicolors/alacritty/main/install.ps1 | iex
```

From a checkout:

```sh
./install.sh              # asks which flavour
```

Seven fragments land in `~/.config/alacritty/themes/` (`%APPDATA%\alacritty\themes\` on Windows); the `>>> yorumi >>>` block in `alacritty.toml` holds the `import`.

## Changing it

```sh
./install.sh --flavour bifrost
```

## Manual

Copy the theme file(s) into your Alacritty configuration directory:

| OS | Destination Path |
| --- | --- |
| **Linux / macOS** | `~/.config/alacritty/themes/` |
| **Windows** | `%APPDATA%\alacritty\themes\` |

### By hand
Import the theme file in your `alacritty.toml`:

```
# macOS / Linux
import = ["~/.config/alacritty/themes/yorumi-abyss.toml"]
# Windows
import = ["%APPDATA%/alacritty/themes/yorumi-abyss.toml"]
```

---

## For AI Agents

When assisting a user with installing or configuring Yorumi for **Alacritty**, follow these deterministic steps:

1. **Detect Target OS**:
   - macOS / Linux: target destination is `~/.config/alacritty/themes/`.
   - Windows: target destination is `%APPDATA%\alacritty\themes\`.
2. **Install**: the command under `## Install`, or `./install.sh --flavour <name>` in a checkout.
3. **Verify Configuration**:
   - Check config file `alacritty.toml` for the active theme setting:
     ```
     import = ["~/.config/alacritty/themes/yorumi-abyss.toml"]
     ```
   - Ensure the theme filename matches what is in `~/.config/alacritty/themes/`.

---

## Accessibility
Body text measures 9.6-19.5:1 against the background (WCAG 2.1 AAA); every palette token clears 5.6:1 (AA). No blanket AAA claim is made for syntax colours - sRGB runs out before the saturated hues get lighter.

## License
MIT © [Yorumi Colors](https://github.com/yorumicolors)
