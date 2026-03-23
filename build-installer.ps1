param(
    [string]$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Build Nutricion Hogar Bambi ===" -ForegroundColor Cyan

# 1) Leer version desde version.txt
$versionFile = Join-Path $PSScriptRoot "version.txt"
if (-not (Test-Path $versionFile)) {
    throw "No se encontro version.txt en $PSScriptRoot"
}
$version = (Get-Content $versionFile -Raw).Trim()
if (-not $version) { throw "version.txt esta vacío" }
Write-Host "Version: $version"

# 2) Actualizar version en NutricionBambi.iss
$issPath = Join-Path $PSScriptRoot "NutricionBambi.iss"
if (-not (Test-Path $issPath)) {
    throw "No se encontro NutricionBambi.iss en $PSScriptRoot"
}

$issContent = Get-Content $issPath -Raw
$pattern = '#define MyAppVersion "[^"]+"'
$replacement = "#define MyAppVersion `"$version`""
$issContent = [System.Text.RegularExpressions.Regex]::Replace(
    $issContent,
    $pattern,
    $replacement
)
Set-Content -Path $issPath -Value $issContent -Encoding UTF8
Write-Host "Actualizada MyAppVersion en NutricionBambi.iss" -ForegroundColor Green

# 2b) Actualizar version en app_version.dart (front)
$appVersionPath = Join-Path $PSScriptRoot "Nutricion-flutter\lib\app\app_version.dart"
if (Test-Path $appVersionPath) {
    $dartContent = Get-Content $appVersionPath -Raw
    $dartPattern = "const String appVersion = '[^']+';"
    $dartReplacement = "const String appVersion = '$version';"
    $dartContent = [System.Text.RegularExpressions.Regex]::Replace(
        $dartContent,
        $dartPattern,
        $dartReplacement
    )
    Set-Content -Path $appVersionPath -Value $dartContent -Encoding UTF8
    Write-Host "Actualizada appVersion en app_version.dart" -ForegroundColor Green
}

# 3) Build Flutter (front)
$flutterDir = Join-Path $PSScriptRoot "Nutricion-flutter"
if (-not (Test-Path $flutterDir)) { throw "No se encontro carpeta Nutricion-flutter" }

Push-Location $flutterDir
try {
    flutter build windows --release
} finally {
    Pop-Location
}

# 4) Build backend (PyInstaller)
$backendDir = Join-Path $PSScriptRoot "backend"
if (-not (Test-Path $backendDir)) { throw "No se encontro carpeta backend" }

Push-Location $backendDir
try {
    pyinstaller --onefile --noconsole --name nutricion_backend run_backend.py
} finally {
    Pop-Location
}

# 5) Compilar instalador con Inno Setup
if (-not (Test-Path $InnoSetupPath)) {
    throw "No se encontro Inno Setup en $InnoSetupPath. Pasa la ruta con -InnoSetupPath si esta en otro sitio."
}

& "$InnoSetupPath" $issPath

Write-Host "=== Build completo. Revisa la carpeta Output ===" -ForegroundColor Cyan
