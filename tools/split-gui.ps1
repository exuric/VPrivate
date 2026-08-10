# Regenerates guis/larp.lua.0 and guis/larp.lua.1 from guis/larp.lua (the master).
# Run this after editing guis/larp.lua, then commit all three files.
$root = Split-Path -Parent $PSScriptRoot
$master = Join-Path $root 'guis\larp.lua'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($master)
$bytes = $utf8.GetBytes($text)
$half = [math]::Floor($bytes.Count / 2)
$splitAt = -1
for ($i = $half; $i -lt $bytes.Count; $i++) {
	if ($bytes[$i] -eq 10) { $splitAt = $i; break }
}
if ($splitAt -lt 0) { throw 'no newline found near halfway point' }
$partA = $utf8.GetString($bytes[0..($splitAt - 1)])
$partB = $utf8.GetString($bytes[($splitAt + 1)..($bytes.Count - 1)])
[System.IO.File]::WriteAllText((Join-Path $root 'guis\larp.lua.0'), $partA, $utf8)
[System.IO.File]::WriteAllText((Join-Path $root 'guis\larp.lua.1'), $partB, $utf8)
Write-Host "master $($bytes.Count) bytes -> partA $($utf8.GetBytes($partA).Count) / partB $($utf8.GetBytes($partB).Count)"
$combined = $partA + "`n" + $partB
if ($combined -eq $text) { Write-Host 'REASSEMBLY MATCH: OK' } else { throw 'reassembly mismatch' }