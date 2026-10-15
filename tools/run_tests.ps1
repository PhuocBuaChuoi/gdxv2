# Chay toan bo test tu dong bang Godot headless.
# Dung: powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
# Exit code 0 = xanh, 1 = co fail. Moi PR phai xanh truoc khi merge.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Godot = Join-Path $Root "godot_engine\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $Godot)) {
  Write-Host "Khong thay binary local, thu lenh 'godot' trong PATH..."
  $Godot = "godot"
}
# Import truoc de texture/atlas (.png/.svg) load duoc headless ke ca tren clone moi.
# (Khong gate tren buoc nay — suite tu quyet dinh xanh/do.)
& $Godot --headless --path "$Root" --editor --quit
& $Godot --headless --path "$Root" -s res://tests/test_runner.gd
exit $LASTEXITCODE