# Installs GUT (Godot Unit Test) into addons/gut on Windows.
# GUT is not committed (addons/gut/ is in .gitignore), so every member runs
# this script once after cloning. Running it again replaces the old copy.
#
# Usage (from the repo folder):
#   powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1
# Offline (lab without internet), with a zip you already have:
#   $env:GUT_ZIP = 'C:\path\to\Gut-9.7.1.zip'; powershell -ExecutionPolicy Bypass -File tools/install_gut.ps1
#
# This file is saved as UTF-8 with BOM so that Windows PowerShell 5.1 reads
# the Romanian letters correctly. Keep the BOM when you edit it.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
# The progress bar makes Invoke-WebRequest very slow in Windows PowerShell 5.1.
$ProgressPreference = 'SilentlyContinue'

$GutVersion = '9.7.1'
$GutUrl = "https://github.com/bitwes/Gut/archive/refs/tags/v$GutVersion.zip"

function Fail([string]$Message) {
    Write-Host "EROARE: $Message" -ForegroundColor Red
    exit 1
}

function Get-PluginVersion([string]$PluginCfg) {
    $line = Select-String -LiteralPath $PluginCfg -Pattern '^version="(.*)"' | Select-Object -First 1
    if ($null -eq $line) { return '' }
    return $line.Matches[0].Groups[1].Value
}

# The project root is the parent of the tools/ folder, wherever the script is called from.
$Root = Split-Path -Parent $PSScriptRoot
$AddonsDir = Join-Path $Root 'addons'
$Dest = Join-Path $AddonsDir 'gut'
$Staging = Join-Path $AddonsDir '.gut_new'

if (-not (Test-Path -LiteralPath (Join-Path $Root 'project.godot'))) {
    Fail "Nu găsesc project.godot în $Root. Rulează scriptul din repo-ul jocului."
}

# GitHub requires TLS 1.2; older Windows setups do not enable it by default.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$TempDir = Join-Path ([IO.Path]::GetTempPath()) ("gut_install_" + [Guid]::NewGuid().ToString('N'))
$ZipFile = Join-Path $TempDir 'gut.zip'
$ExtractDir = Join-Path $TempDir 'extract'

try {
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    Write-Host "Instalez GUT $GutVersion în addons\gut ..."
    if ($env:GUT_ZIP) {
        if (-not (Test-Path -LiteralPath $env:GUT_ZIP)) {
            Fail "Nu găsesc arhiva din GUT_ZIP: $($env:GUT_ZIP)"
        }
        Write-Host "Folosesc arhiva locală $($env:GUT_ZIP)"
        Copy-Item -LiteralPath $env:GUT_ZIP -Destination $ZipFile
    } else {
        Write-Host "Descarc $GutUrl"
        try {
            Invoke-WebRequest -Uri $GutUrl -OutFile $ZipFile -UseBasicParsing
        } catch {
            Fail "Descărcarea a eșuat. Verifică internetul și încearcă din nou. ($($_.Exception.Message))"
        }
    }

    try {
        Expand-Archive -LiteralPath $ZipFile -DestinationPath $ExtractDir -Force
    } catch {
        Fail "Nu pot dezarhiva $ZipFile. ($($_.Exception.Message))"
    }

    # The archive has one top folder (Gut-9.7.1\). Find addons\gut by its plugin.cfg.
    $PluginCfg = Get-ChildItem -LiteralPath $ExtractDir -Recurse -Filter 'plugin.cfg' |
        Where-Object { $_.Directory.Name -eq 'gut' -and $_.Directory.Parent.Name -eq 'addons' } |
        Select-Object -First 1
    if ($null -eq $PluginCfg) {
        Fail 'Arhiva nu conține addons/gut/plugin.cfg.'
    }

    $FoundVersion = Get-PluginVersion $PluginCfg.FullName
    if ($FoundVersion -ne $GutVersion) {
        Fail "Am primit GUT $FoundVersion, nu $GutVersion."
    }

    # Copy next to the destination first, then swap, so a failed copy never
    # leaves a half-installed addons\gut.
    New-Item -ItemType Directory -Path $AddonsDir -Force | Out-Null
    if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force }
    Copy-Item -LiteralPath $PluginCfg.Directory.FullName -Destination $Staging -Recurse

    if (Test-Path -LiteralPath $Dest) {
        $OldVersion = ''
        $OldCfg = Join-Path $Dest 'plugin.cfg'
        if (Test-Path -LiteralPath $OldCfg) { $OldVersion = Get-PluginVersion $OldCfg }
        if (-not $OldVersion) { $OldVersion = 'necunoscută' }
        Write-Host "addons\gut există deja (versiunea $OldVersion). Îl înlocuiesc."
        Remove-Item -LiteralPath $Dest -Recurse -Force
    }
    Move-Item -LiteralPath $Staging -Destination $Dest

    $Installed = Get-PluginVersion (Join-Path $Dest 'plugin.cfg')
    Write-Host "Gata: GUT $Installed este instalat în addons\gut." -ForegroundColor Green
    Write-Host 'Pasul următor: deschide proiectul în Godot 4.7.2. Panoul GUT apare jos, lângă Output.'
} finally {
    if (Test-Path -LiteralPath $TempDir) { Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    # Also removes a half-copied staging folder if the script stopped early.
    if (Test-Path -LiteralPath $Staging) { Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue }
}
