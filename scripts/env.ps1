# Dot-source this file to use the workspace's toolchain in the current terminal.
$bachatProjectRoot=Split-Path -Parent $PSScriptRoot
$bachatToolsRoot=[System.IO.Path]::GetFullPath((Join-Path $bachatProjectRoot '../../.tools'))
$bachatFlutterBin=Join-Path $bachatToolsRoot 'flutter/bin'
if(Test-Path (Join-Path $bachatFlutterBin 'flutter.bat')){
  $env:PATH="$bachatFlutterBin;$env:PATH"
  $env:PUB_CACHE=Join-Path $bachatToolsRoot 'pub-cache'
  $env:GRADLE_USER_HOME=Join-Path $bachatToolsRoot 'gradle-cache'
}
if(Test-Path (Join-Path $bachatToolsRoot 'android-sdk')){
  $env:ANDROID_HOME=Join-Path $bachatToolsRoot 'android-sdk'
  $env:ANDROID_SDK_ROOT=$env:ANDROID_HOME
}
$bachatJdk='C:/Program Files/Android/Android Studio/jbr'
if(Test-Path $bachatJdk){$env:JAVA_HOME=$bachatJdk}
