# Yorumi theme installer for Alacritty (Windows PowerShell)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destDir = "$env:APPDATA\alacritty\themes"
if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$rawBase = "https://raw.githubusercontent.com/yorumicolors/yorumi-alacritty/main"
$files = @("yorumi-ether.toml", "yorumi-abyss.toml", "yorumi-bifrost.toml", "yorumi-kraken.toml", "yorumi-kabocha.toml", "yorumi-cosmic.toml", "yorumi-ryujin.toml")

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
        $url = "$rawBase/$f"
        Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing
    }
    Write-Host "✓ Installed: $target" -ForegroundColor Green
}

Write-Host "`nSuccessfully installed Yorumi for Alacritty!" -ForegroundColor Green
Write-Host "Import the theme file in %APPDATA%\alacritty\alacritty.toml:"
Write-Host "    import = [`"%APPDATA%/alacritty/themes/yorumi-abyss.toml`"]"
