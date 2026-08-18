$ErrorActionPreference = 'Stop'
$files = @(
	'main.lua',
	'guis/larp2.lua',
	'libraries/entity.lua',
	'libraries/hash.lua',
	'libraries/prediction.lua',
	'games/universal.lua',
	'games/6872274481.lua',
	'games/8444591321.lua'
)
$tmp = Join-Path $env:TEMP 'larp_manifest'
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Path $tmp | Out-Null
$lines = foreach ($f in $files) {
	$out = Join-Path $tmp ($f -replace '/', '_')
	cmd /c "git cat-file blob `":$f`" > `"$out`""
	$h = (Get-FileHash -Algorithm SHA512 -LiteralPath $out).Hash.ToLower()
	"$f $h"
}
Set-Content -Path 'profiles\manifest.txt' -Value ($lines -join "`n") -Encoding ASCII -NoNewline
Remove-Item -Recurse -Force $tmp
Write-Output 'manifest.txt written'