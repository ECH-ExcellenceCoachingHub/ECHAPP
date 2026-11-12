<#
  ECH Labs — one-command Unity pipeline (no manual Editor work).

  .\tools\labs\build-labs.ps1                 # setup → textures → prefabs → scenes → bake → QA screenshots
  .\tools\labs\build-labs.ps1 -Step compile   # just open/compile the project (first run imports packages)
  .\tools\labs\build-labs.ps1 -Step qa        # re-render QA screenshots only
  .\tools\labs\build-labs.ps1 -Step windows   # player builds: windows | webgl | android | quest | ios
  .\tools\labs\build-labs.ps1 -Step test      # Unity EditMode tests + headless .NET tests
#>
param(
  [ValidateSet('all', 'compile', 'setup', 'prefabs', 'scenes', 'bake', 'qa', 'windows', 'webgl', 'android', 'quest', 'ios', 'test')]
  [string]$Step = 'all',
  [string]$Room = ''
)
$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$project = Join-Path $repo 'labs-unity'
$logs = Join-Path $project 'Logs'
New-Item -ItemType Directory -Force $logs | Out-Null

function Find-Unity {
  $version = (Get-Content (Join-Path $project 'ProjectSettings\ProjectVersion.txt') | Select-String 'm_EditorVersion:').ToString().Split(':')[1].Trim()
  $candidates = @(
    "C:\Program Files\Unity\Hub\Editor\$version\Editor\Unity.exe",
    "D:\Unity\Hub\Editor\$version\Editor\Unity.exe",
    "D:\Program Files\Unity\Hub\Editor\$version\Editor\Unity.exe"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  $any = Get-ChildItem 'C:\Program Files\Unity\Hub\Editor' -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
  if ($any) { Write-Warning "Unity $version not found, using $($any.Name)"; return Join-Path $any.FullName 'Editor\Unity.exe' }
  throw "Unity $version is not installed. Install it with Unity Hub (modules: Android, Windows IL2CPP, Web)."
}

$unity = Find-Unity
function Run-Unity([string]$name, [string[]]$extra) {
  $log = Join-Path $logs "$name.log"
  Write-Host "▶ $name" -ForegroundColor Cyan
  $uargs = @('-batchmode', '-projectPath', $project, '-logFile', $log) + $extra
  $p = Start-Process -FilePath $unity -ArgumentList $uargs -Wait -PassThru -NoNewWindow
  $errors = Select-String -Path $log -Pattern 'error CS\d+|Exception:|\[ECHLabs\].*FAILED' -ErrorAction SilentlyContinue | Select-Object -First 15
  if ($p.ExitCode -ne 0 -or $errors) {
    $errors | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
    if ($p.ExitCode -ne 0) { throw "$name failed (exit $($p.ExitCode)). Log: $log" }
  }
  Select-String -Path $log -Pattern '\[ECHLabs\]' | ForEach-Object { Write-Host "  $($_.Line.Trim())" }
}
function Exec([string]$name, [string]$method, [string[]]$more = @()) { Run-Unity $name (@('-executeMethod', $method) + $more + @('-quit')) }

switch ($Step) {
  'compile' { Run-Unity 'compile' @('-quit') }
  'setup'   { Exec 'setup' 'ECHLabs.EditorTools.ProjectSetup.Run' }
  'prefabs' { Exec 'prefabs' 'ECHLabs.EditorTools.PrefabFactory.BuildAll' }
  'scenes'  { Exec 'scenes' 'ECHLabs.EditorTools.SceneBuilder.BuildAll' }
  'bake'    { if ($Room) { Exec 'bake' 'ECHLabs.EditorTools.LightingBaker.BakeAll' @('-room', $Room) } else { Exec 'bake' 'ECHLabs.EditorTools.LightingBaker.BakeAll' } }
  'qa'      { Exec 'qa' 'ECHLabs.EditorTools.ScreenshotQA.Run'; Write-Host "QA renders: $project\QA" -ForegroundColor Green }
  'windows' { Exec 'build-windows' 'ECHLabs.EditorTools.BuildCli.Windows' @('-buildTarget', 'Win64') }
  'webgl'   { Exec 'build-webgl' 'ECHLabs.EditorTools.BuildCli.WebGL' @('-buildTarget', 'WebGL') }
  'android' { Exec 'build-android' 'ECHLabs.EditorTools.BuildCli.AndroidLibrary' @('-buildTarget', 'Android') }
  'quest'   { Exec 'build-quest' 'ECHLabs.EditorTools.BuildCli.Quest' @('-buildTarget', 'Android') }
  'ios'     { Exec 'build-ios' 'ECHLabs.EditorTools.BuildCli.iOS' @('-buildTarget', 'iOS') }
  'test'    {
    dotnet test (Join-Path $project 'DotnetTests')
    Run-Unity 'tests' @('-runTests', '-testPlatform', 'EditMode', '-testResults', (Join-Path $logs 'editmode-results.xml'))
  }
  'all' {
    Run-Unity 'compile' @('-quit')
    Exec 'setup' 'ECHLabs.EditorTools.ProjectSetup.Run'
    node (Join-Path $repo 'tools\asset-pipeline\fetch-cc0.mjs')
    Exec 'prefabs' 'ECHLabs.EditorTools.PrefabFactory.BuildAll'
    Exec 'textures' 'ECHLabs.EditorTools.MaterialLibrary.ApplyDownloadedTextures'
    Exec 'scenes' 'ECHLabs.EditorTools.SceneBuilder.BuildAll'
    Exec 'bake' 'ECHLabs.EditorTools.LightingBaker.BakeAll'
    Exec 'qa' 'ECHLabs.EditorTools.ScreenshotQA.Run'
    Write-Host "Done. QA renders: $project\QA" -ForegroundColor Green
  }
}
