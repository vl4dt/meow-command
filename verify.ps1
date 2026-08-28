# Meow Command — agent verification gate. Run after EVERY batch of edits.
# All steps must exit 0.
#
# Sandbox-tolerant (DSH workspace-write):
#  1. Godot's default user data dir is %APPDATA%\Godot — outside the
#     workspace and denied by the sandbox, which can make --import exit
#     non-zero (editor settings save failure). We redirect APPDATA into
#     the project's gitignored .godot cache dir so all Godot state stays
#     inside the workspace.
#  2. In this sandbox, PowerShell cannot capture a native process's stdout
#     into a variable (the child's pipe writes are denied). Output-sensitive
#     steps therefore run through `cmd /c` with file redirection, and the
#     file is read back.
$ErrorActionPreference = "Stop"
$godot = "C:\Apps\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:APPDATA = Join-Path $proj ".godot\userdata"
$outfile = Join-Path $proj ".godot\verify_output.txt"

# Run a Godot invocation through cmd with file redirection (sandbox-tolerant
# capture), require exit 0 AND the expected PASS marker in the output.
function Invoke-GodotCaptured {
	param([string[]]$GodotArgs, [string]$Marker)
	$argline = ($GodotArgs | ForEach-Object { if ($_ -match ' ') { "`"$_`"" } else { $_ } }) -join " "
	& cmd /c "`"$godot`" $argline > `"$outfile`" 2>&1"
	$code = $LASTEXITCODE
	$text = if (Test-Path $outfile) { Get-Content $outfile -Raw } else { "" }
	Remove-Item $outfile -ErrorAction SilentlyContinue
	if ($code -ne 0 -or $text -notmatch $Marker) {
		throw "expected '$Marker' (exit $code)`n$text"
	}
}

Write-Host "== import ==" -ForegroundColor Cyan
& $godot --headless --path $proj --import
if ($LASTEXITCODE -ne 0) { throw "import failed" }

Write-Host "== parse check ==" -ForegroundColor Cyan
$scripts = Get-ChildItem (Join-Path $proj "scripts") -Filter *.gd
foreach ($s in $scripts) {
	& $godot --headless --path $proj --check-only --script ("res://scripts/" + $s.Name)
	if ($LASTEXITCODE -ne 0) { throw "parse check failed: $($s.Name)" }
}
foreach ($t in @("res://tools/smoke_test.gd", "res://tools/gameplay_test.gd")) {
	& $godot --headless --path $proj --check-only --script $t
	if ($LASTEXITCODE -ne 0) { throw "parse check failed: $t" }
}

# NOTE: Godot can exit 0 even when a -s script fails to load, so we also
# require the explicit PASS marker on stdout.
Write-Host "== smoke test ==" -ForegroundColor Cyan
Invoke-GodotCaptured -GodotArgs @("--headless", "--path", $proj, "-s", "res://tools/smoke_test.gd") -Marker "SMOKE RESULT: PASS"

Write-Host "== gameplay test ==" -ForegroundColor Cyan
Invoke-GodotCaptured -GodotArgs @("--headless", "--path", $proj, "-s", "res://tools/gameplay_test.gd") -Marker "GAMEPLAY RESULT: PASS"

Write-Host "== smoke run (300 frames) ==" -ForegroundColor Cyan
& $godot --headless --path $proj --quit-after 300
if ($LASTEXITCODE -ne 0) { throw "smoke run failed" }

Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
