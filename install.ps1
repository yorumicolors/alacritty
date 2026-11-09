# Yorumi theme installer for Alacritty (Windows PowerShell)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destDir = "$env:APPDATA\alacritty\themes"
$rawBase = "https://raw.githubusercontent.com/yorumicolors/alacritty/main"
$files = @("yorumi-ether.toml", "yorumi-abyss.toml", "yorumi-bifrost.toml", "yorumi-kraken.toml", "yorumi-kabocha.toml", "yorumi-cosmic.toml", "yorumi-ryujin.toml")

# download beside the target and move it in: a failed fetch leaves nothing behind
function Save-One([string] $name, [string] $target) {
    $url = "$rawBase/$name"
    $part = "$target.part.$PID"
    try {
        Invoke-WebRequest -Uri $url -OutFile $part -UseBasicParsing
    } catch {
        Remove-Item -LiteralPath $part -ErrorAction SilentlyContinue
        throw "yorumi: download failed for $url (target $target): $($_.Exception.Message)"
    }
    Move-Item -LiteralPath $part -Destination $target -Force
}

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$scriptDir = $PSScriptRoot

Write-Host "Installing Yorumi theme for Alacritty..." -ForegroundColor Cyan

foreach ($f in $files) {
    $basename = Split-Path $f -Leaf
    $target = Join-Path $destDir $basename
    $localPath = if ($scriptDir) { Join-Path $scriptDir $f } else { $null }
    $localFlat = if ($scriptDir) { Join-Path $scriptDir $basename } else { $null }

    if ($localPath -and (Test-Path $localPath)) {
        Copy-Item -Path $localPath -Destination $target -Force
    } elseif ($localFlat -and (Test-Path $localFlat)) {
        Copy-Item -Path $localFlat -Destination $target -Force
    } else {
        Save-One $f $target
    }
    Write-Host "Installed: $target" -ForegroundColor Green
}

Write-Host "`nSuccessfully installed Yorumi for Alacritty!" -ForegroundColor Green
# %APPDATA% is not expanded in a TOML string: print the resolved paths, with
# backslashes escaped the way a TOML basic string needs them
$configPath = Join-Path (Split-Path $destDir -Parent) 'alacritty.toml'
if (Test-Path -LiteralPath $configPath) {
    $configPath = (Resolve-Path -LiteralPath $configPath).Path
}
$themePath = (Join-Path $destDir 'yorumi-ether.toml') -replace '\\', '\\'
Write-Host "No import was added. Add one marked entry to the import array of the [general]"
Write-Host "table in $configPath - not at the top of the file and not under another table,"
Write-Host "where alacritty would read it as an option of that one:"
Write-Host ""
Write-Host "    [general]"
Write-Host "    import = ["
Write-Host "        # >>> yorumi >>>"
Write-Host "        `"$themePath`","
Write-Host "        # <<< yorumi <<<"
Write-Host "    ]"
Write-Host ""
Write-Host "That names yorumi-ether.toml; the seven files are installed, so any of them works."
