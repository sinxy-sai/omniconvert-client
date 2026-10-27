[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string]$Version,
  [string]$BuildDir = "build/windows/x64/runner/Release",
  [string]$OutputDir = "."
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$buildPath = (Resolve-Path (Join-Path $root $BuildDir)).Path
$outputPath = (New-Item -ItemType Directory -Force -Path (Join-Path $root $OutputDir)).FullName
$makensis = Get-Command makensis -ErrorAction SilentlyContinue
if (-not $makensis) {
  $defaultMakensis = Join-Path ${env:ProgramFiles(x86)} 'NSIS\makensis.exe'
  if (Test-Path $defaultMakensis) {
    $makensis = Get-Item $defaultMakensis
  }
}
$makensisPath = if ($makensis -is [System.Management.Automation.CommandInfo]) { $makensis.Source } else { $makensis.FullName }
if (-not $makensisPath) { throw "makensis was not found on PATH. Install NSIS before packaging." }
$exe = Join-Path $buildPath "omniconvert.exe"
if (-not (Test-Path $exe)) { throw "Flutter release executable not found: $exe" }

$zip = Join-Path $outputPath "OmniConvert-$Version-windows-x64.zip"
$setup = Join-Path $outputPath "OmniConvert-$Version-windows-x64-setup.exe"
if (Test-Path $zip) { Remove-Item -Force $zip }
if (Test-Path $setup) { Remove-Item -Force $setup }
Compress-Archive -Path (Join-Path $buildPath "*") -DestinationPath $zip

$nsi = Join-Path $PSScriptRoot "installer.nsi"
& $makensisPath "/DAPP_VERSION=$Version" "/DSOURCE_DIR=$buildPath" "/DOUTPUT_FILE=$setup" $nsi
if ($LASTEXITCODE -ne 0) { throw "NSIS failed with exit code $LASTEXITCODE" }
if (-not (Test-Path $zip)) { throw "Portable package was not produced: $zip" }
if (-not (Test-Path $setup)) { throw "Installer was not produced: $setup" }
Write-Host "Created $zip"
Write-Host "Created $setup"
