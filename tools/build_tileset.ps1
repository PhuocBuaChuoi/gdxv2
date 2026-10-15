# Build atlas PNG + TileSet (T7.01). Chay lai bat cu khi nao doi design tiles.
# Dung: powershell -ExecutionPolicy Bypass -File tools/build_tileset.ps1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Godot = Join-Path $Root "godot_engine\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $Godot)) {
  Write-Host "Khong thay binary local, thu lenh 'godot' trong PATH..."
  $Godot = "godot"
}
Write-Host "[1/3] Import resources (editor headless, de PNG load duoc)..."
& $Godot --headless --path "$Root" --editor --quit
Write-Host "[2/3] Generate atlas PNG (lan 1 de file ton tai cho import)..."
& $Godot --headless --path "$Root" -s res://tools/gen_neon_tileset.gd
Write-Host "[3/3] Import lai + generate TileSet (.tres)..."
& $Godot --headless --path "$Root" --editor --quit
& $Godot --headless --path "$Root" -s res://tools/gen_neon_tileset.gd
exit $LASTEXITCODE
