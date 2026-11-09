# Yorumi theme installer for Alacritty (Windows PowerShell)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$destDir = "$env:APPDATA\alacritty\themes"
$rawBase = "https://raw.githubusercontent.com/yorumicolors/yorumi-alacritty/main"
$files = @("yorumi-ether.toml", "yorumi-abyss.toml", "yorumi-bifrost.toml", "yorumi-kraken.toml", "yorumi-kabocha.toml", "yorumi-cosmic.toml", "yorumi-ryujin.toml")

# download beside the target and move it in: a failed fetch leaves nothing behind
function Save-One([string] $name, [string] $target) {
    $part = "$target.part.$PID"
    try {
        Invoke-WebRequest -Uri "$rawBase/$name" -OutFile $part -UseBasicParsing
    } catch {
        Remove-Item -LiteralPath $part -ErrorAction SilentlyContinue
        Write-Host "yorumi: could not download $name from $rawBase" -ForegroundColor Red
        Write-Host "yorumi: if that repository is not public yet, clone it and run this script from the checkout." -ForegroundColor Red
        exit 3
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
    Write-Host "✓ Installed: $target" -ForegroundColor Green
}

Write-Host "`nSuccessfully installed Yorumi for Alacritty!" -ForegroundColor Green
Write-Host "Add one marked entry to the import array of the [general] table in"
Write-Host "%APPDATA%\alacritty\alacritty.toml - not at the top of the file and not"
Write-Host "under another table, where alacritty would read it as an option of that one:"
Write-Host ""
Write-Host "    [general]"
Write-Host "    import = ["
Write-Host "        # >>> yorumi >>>"
Write-Host "        `"%APPDATA%/alacritty/themes/yorumi-abyss.toml`","
Write-Host "        # <<< yorumi <<<"
Write-Host "    ]"
