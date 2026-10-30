param(
  [ValidateSet('windows', 'android', 'web')]
  [string]$Target = 'windows',
  [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
$env:CI = 'true'
Set-StrictMode -Version Latest
Push-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))

try {
  $flutter = if (Get-Command flutter -ErrorAction SilentlyContinue) {
    'flutter'
  } elseif (Test-Path '.toolchains/flutter/bin/flutter.bat') {
    (Resolve-Path '.toolchains/flutter/bin/flutter.bat').Path
  } else {
    throw 'Flutter was not found on PATH or in .toolchains/flutter.'
  }

  function Invoke-Checked([string]$Command, [string[]]$Arguments) {
    Write-Host "> $Command $($Arguments -join ' ')"
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "$Command exited with code $LASTEXITCODE"
    }
  }

  if (-not $SkipChecks) {
    # The Rust core was retired from the runtime: image tools are pure Dart now,
    # so CI only needs the Flutter SDK.
    Invoke-Checked $flutter -Arguments @('--no-version-check', 'analyze')
    Invoke-Checked $flutter -Arguments @('--no-version-check', 'test')
  }

  switch ($Target) {
    'windows' { Invoke-Checked $flutter -Arguments @('--no-version-check', 'build', 'windows', '--debug') }
    'android' { Invoke-Checked $flutter -Arguments @('--no-version-check', 'build', 'apk', '--debug') }
    'web' { Invoke-Checked $flutter -Arguments @('--no-version-check', 'build', 'web', '--release', '--no-wasm-dry-run', '--base-href', '/app/') }
  }

  Write-Host "OmniConvert $Target verification passed."
} finally {
  Pop-Location
}
