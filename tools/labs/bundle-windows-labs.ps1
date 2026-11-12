<#
  Bundles ECH Labs (Unity Windows build) into the Flutter Windows app so the MSIX ships it.

    cd frontend; flutter build windows --release
    ..\tools\labs\bundle-windows-labs.ps1
    dart run msix:create

  The Flutter app (LabLauncher.windowsExe) looks for  <app folder>\labs\ECHLabs.exe .
  The IL2CPP debug-symbol folder (…_BackUpThisFolder_ButDontShipItWithYourGame) is never shipped.
#>
param(
  [string]$UnityBuild = (Join-Path $PSScriptRoot '..\..\labs-unity\Builds\Windows'),
  [string]$FlutterRelease = (Join-Path $PSScriptRoot '..\..\frontend\build\windows\x64\runner\Release')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $UnityBuild 'ECHLabs.exe'))) { throw "No Unity build at $UnityBuild. Run: tools\labs\build-labs.ps1 -Step windows" }
if (-not (Test-Path $FlutterRelease)) { throw "No Flutter release build at $FlutterRelease. Run: flutter build windows --release" }

$dest = Join-Path $FlutterRelease 'labs'
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Force $dest | Out-Null
Get-ChildItem $UnityBuild | Where-Object { $_.Name -notlike '*_BackUpThisFolder_ButDontShipItWithYourGame' -and $_.Name -notlike '*_BurstDebugInformation_DoNotShip' } |
  ForEach-Object { Copy-Item $_.FullName -Destination $dest -Recurse -Force }

$size = (Get-ChildItem $dest -Recurse | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("ECH Labs bundled into {0} ({1:N0} MB)" -f $dest, $size) -ForegroundColor Green
