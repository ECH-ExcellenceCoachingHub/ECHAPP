<#
  Puts the ECH Labs WebGL build inside the Flutter web app, so it is served at
      https://www.elearning.excellencecoachinghub.com/lab/
  with every normal deploy of the site (Flutter copies frontend/web/** into build/web/**).

    .\tools\labs\build-labs.ps1 -Step webgl      # (re)build the web lab
    .\tools\labs\bundle-web-labs.ps1             # copy it to frontend/web/lab
    cd frontend; flutter build web --release     # then deploy build/web as usual

  Backend (Render) setting:  LAB_WEB_URL=https://www.elearning.excellencecoachinghub.com/lab
#>
param(
  [string]$WebGLBuild = (Join-Path $PSScriptRoot '..\..\labs-unity\Builds\WebGL'),
  [string]$Dest = (Join-Path $PSScriptRoot '..\..\frontend\web\lab')
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $WebGLBuild 'index.html'))) { throw "No WebGL build at $WebGLBuild. Run: tools\labs\build-labs.ps1 -Step webgl" }
if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
New-Item -ItemType Directory -Force $Dest | Out-Null
Copy-Item (Join-Path $WebGLBuild '*') -Destination $Dest -Recurse -Force
$size = (Get-ChildItem $Dest -Recurse | Measure-Object Length -Sum).Sum / 1MB
Write-Host ("ECH Labs web build copied to {0} ({1:N1} MB) → served at /lab/" -f $Dest, $size) -ForegroundColor Green
