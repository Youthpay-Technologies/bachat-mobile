param([string]$Device='web-server',[int]$Port=8080)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'env.ps1')
$flutterCommand='flutter'
Set-Location $projectRoot
$runArguments=@('--no-version-check','run','-d',$Device)
if($Device -eq 'web-server'){$runArguments+=@('--web-hostname','127.0.0.1','--web-port',"$Port")}
& $flutterCommand @runArguments
