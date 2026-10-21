param([switch]$Apply)
$ErrorActionPreference='Stop'
$hostedConfigRoot=Join-Path (Split-Path -Parent $PSScriptRoot) 'config/hosted'
$projectRef='mqpcxptgmqzwylldiotr'
# The CLI uses its own authenticated session; no account token is read or copied.
& supabase config diff --workdir $hostedConfigRoot --project-ref $projectRef
if($LASTEXITCODE -ne 0){throw 'Sign in with supabase login, then retry.'}
if($Apply){
  & supabase config push --workdir $hostedConfigRoot --project-ref $projectRef --yes
  if($LASTEXITCODE -ne 0){throw 'Hosted Auth configuration was not applied.'}
}
