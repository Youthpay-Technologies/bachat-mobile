# Run from a network-enabled development session, then commit the font assets
# and pubspec.yaml together. Font downloads finish before the manifest changes.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$brandProjectRoot = Split-Path -Parent $PSScriptRoot
$brandFontDirectory = Join-Path $brandProjectRoot 'assets/fonts'
$brandDownloadDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("bachat-fonts-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $brandDownloadDirectory | Out-Null

$brandFontDownloads = @{
    'InstrumentSans.ttf' = 'https://raw.githubusercontent.com/google/fonts/main/ofl/instrumentsans/InstrumentSans%5Bwdth,wght%5D.ttf'
    'InstrumentSans-OFL.txt' = 'https://raw.githubusercontent.com/google/fonts/main/ofl/instrumentsans/OFL.txt'
    'InstrumentSerif-Regular.ttf' = 'https://raw.githubusercontent.com/google/fonts/main/ofl/instrumentserif/InstrumentSerif-Regular.ttf'
    'InstrumentSerif-Italic.ttf' = 'https://raw.githubusercontent.com/google/fonts/main/ofl/instrumentserif/InstrumentSerif-Italic.ttf'
    'InstrumentSerif-OFL.txt' = 'https://raw.githubusercontent.com/google/fonts/main/ofl/instrumentserif/OFL.txt'
}

foreach ($brandDownload in $brandFontDownloads.GetEnumerator()) {
    Invoke-WebRequest -Uri $brandDownload.Value -OutFile (Join-Path $brandDownloadDirectory $brandDownload.Key)
}

# Reject a proxy error page or a renamed HTML response before bundling it.
foreach ($brandFontFile in Get-ChildItem -LiteralPath $brandDownloadDirectory -Filter '*.ttf') {
    $brandFontBytes = [System.IO.File]::ReadAllBytes($brandFontFile.FullName)
    if ($brandFontBytes.Length -lt 1024 -or $brandFontBytes[0] -ne 0 -or $brandFontBytes[1] -ne 1) {
        throw "The download for $($brandFontFile.Name) is not a TrueType font."
    }
}

Get-ChildItem -LiteralPath $brandDownloadDirectory -File | Copy-Item -Destination $brandFontDirectory
$brandManifestPath = Join-Path $brandProjectRoot 'pubspec.yaml'
$brandManifest = [System.IO.File]::ReadAllText($brandManifestPath)
if (-not $brandManifest.Contains('family: Instrument Sans')) {
    $brandFontManifest = @'
  fonts:
    - family: Instrument Sans
      fonts:
        - asset: assets/fonts/InstrumentSans.ttf
    - family: Instrument Serif
      fonts:
        - asset: assets/fonts/InstrumentSerif-Regular.ttf
        - asset: assets/fonts/InstrumentSerif-Italic.ttf
          style: italic
'@
    $brandManifest = [regex]::Replace($brandManifest, '(?m)^  fonts:[ \t]*\r?$', $brandFontManifest.TrimEnd())
    [System.IO.File]::WriteAllText($brandManifestPath, $brandManifest)
}

Write-Output 'Instrument Sans and Instrument Serif are bundled. Run Flutter checks before committing.'
Write-Output "Download staging directory: $brandDownloadDirectory"
