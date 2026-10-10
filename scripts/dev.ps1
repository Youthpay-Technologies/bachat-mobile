param([string]$Device='web-server',[int]$Port=8080)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'env.ps1')
$flutterCommand='flutter'
Set-Location $projectRoot
$config=Join-Path $projectRoot 'config/dev.local.json'
if(!(Test-Path $config)){Copy-Item config/env.example.json $config;Write-Host 'Created config/dev.local.json. Fill its Supabase values for sign-in.'}
$runArguments=@('--no-version-check','run','-d',$Device,"--dart-define-from-file=$config")
if($Device -eq 'web-server'){$runArguments+=@('--web-hostname','127.0.0.1','--web-port',"$Port")}
& $flutterCommand @runArguments
