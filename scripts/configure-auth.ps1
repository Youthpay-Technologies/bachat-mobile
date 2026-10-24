param(
  [switch]$Apply,
  [ValidateSet('development', 'release')][string]$Environment = 'development'
)
$ErrorActionPreference='Stop'
$authConfigFolder=if($Environment -eq 'release'){'release'}else{'hosted'}
$hostedConfigRoot=Join-Path (Split-Path -Parent $PSScriptRoot) "config/$authConfigFolder"
$projectRef='mqpcxptgmqzwylldiotr'
function Invoke-Supabase {
  param([string[]]$CliArguments)
  $installedCli=Get-Command supabase -ErrorAction SilentlyContinue
  if($installedCli){ & $installedCli.Source @CliArguments }
  else { & npx --yes supabase@2.120.0 @CliArguments }
}
# The CLI uses its own authenticated session; no account token is read or copied.
Invoke-Supabase -CliArguments @('config','diff','--workdir',$hostedConfigRoot,'--project-ref',$projectRef)
if($LASTEXITCODE -ne 0){throw 'Sign in with npx supabase@2.120.0 login, then retry.'}
if($Apply){
  Invoke-Supabase -CliArguments @('config','push','--workdir',$hostedConfigRoot,'--project-ref',$projectRef,'--yes')
  if($LASTEXITCODE -ne 0){throw 'Hosted Auth configuration was not applied.'}
}
