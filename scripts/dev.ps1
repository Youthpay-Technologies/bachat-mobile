param([string]$Device='web-server',[int]$Port=8080)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$toolsRoot=Join-Path (Split-Path -Parent $projectRoot) '../.tools'
$localFlutter=Join-Path $toolsRoot 'flutter/bin/flutter.bat'
$flutterCommand=if(Test-Path $localFlutter){$localFlutter}else{'flutter'}
if(Test-Path $toolsRoot){$env:PUB_CACHE=Join-Path $toolsRoot 'pub-cache';$env:GRADLE_USER_HOME=Join-Path $toolsRoot 'gradle-cache';$env:ANDROID_HOME=Join-Path $toolsRoot 'android-sdk'}
Set-Location $projectRoot
$config=Join-Path $projectRoot 'config/dev.local.json'
if(!(Test-Path $config)){Copy-Item config/env.example.json $config;Write-Host 'Created config/dev.local.json. Fill its Supabase values for sign-in.'}
$runArguments=@('--no-version-check','run','-d',$Device,"--dart-define-from-file=$config")
if($Device -eq 'web-server'){$runArguments+=@('--web-hostname','127.0.0.1','--web-port',"$Port")}
& $flutterCommand @runArguments
