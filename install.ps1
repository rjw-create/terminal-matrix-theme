<#
.SYNOPSIS
  Installs the Matrix look for Windows Terminal and Claude Code.
.DESCRIPTION
  1. Backs up Claude Code's settings.json and Windows Terminal's settings.json.
  2. Copies the Windows Terminal fragment (color scheme + PowerShell profile tweaks)
     into the per-user fragments folder. Windows Terminal's own settings.json is not edited.
  3. Copies the Claude Code theme into <claude home>\themes.
  4. Sets "theme", "spinnerVerbs", "companyAnnouncements" and "spinnerTipsOverride" in Claude
     Code's settings.json, leaving other keys alone.
  5. Adds green typed-text colors to your PowerShell profile(s).
  6. Unless -NoRain is given, installs a falling-binary pixel shader and points the PowerShell
     profiles at it (Windows Terminal experimental.pixelShaderPath).
  Run uninstall.ps1 to undo.
.PARAMETER NoRain
  Skip the falling-binary background shader.
#>
param([switch]$NoRain)
$ErrorActionPreference = 'Stop'

$AppName = 'terminal-matrix-theme'
$ThemeSlug = 'matrix'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($env:CLAUDE_CONFIG_DIR) { $ClaudeHome = $env:CLAUDE_CONFIG_DIR } else { $ClaudeHome = Join-Path $HOME '.claude' }
$ClaudeSettings = Join-Path $ClaudeHome 'settings.json'
$StateFile = Join-Path $ClaudeHome 'terminal-matrix-theme-state.json'
$ThemeDir = Join-Path $ClaudeHome 'themes'
$FragmentDir = Join-Path $env:LOCALAPPDATA ('Microsoft\Windows Terminal\Fragments\' + $AppName)

$WtSettings = @(
  (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
  (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
  (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)

$SrcFragment = Join-Path $PSScriptRoot 'windows-terminal\matrix-fragment.json'
$SrcTheme = Join-Path $PSScriptRoot 'claude-code\themes\matrix.json'
$SrcVerbs = Join-Path $PSScriptRoot 'claude-code\spinner-verbs.json'
$SrcAnnounce = Join-Path $PSScriptRoot 'claude-code\company-announcements.json'
$SrcTips = Join-Path $PSScriptRoot 'claude-code\spinner-tips.json'
$SrcShader = Join-Path $PSScriptRoot 'windows-terminal\matrix-rain.hlsl'
$AssetDir = Join-Path $env:LOCALAPPDATA $AppName
foreach ($f in @($SrcFragment, $SrcTheme, $SrcVerbs, $SrcAnnounce, $SrcTips, $SrcShader)) {
  if (-not (Test-Path $f)) { throw "Missing source file: $f" }
  # Fail early if a source file is not valid JSON.
  if ($f -notlike '*.hlsl') { $null = Get-Content -Raw -Encoding UTF8 -Path $f | ConvertFrom-Json }
}

# --- 1. Backups -----------------------------------------------------------
$backups = @()
foreach ($f in (@($ClaudeSettings) + $WtSettings)) {
  if (Test-Path $f) {
    $b = "$f.bak-$Stamp"
    Copy-Item -Path $f -Destination $b
    $backups += $b
    Write-Host "Backed up: $b"
  }
}

# --- 2. Windows Terminal fragment ----------------------------------------
New-Item -ItemType Directory -Force -Path $FragmentDir | Out-Null
$FragmentDest = Join-Path $FragmentDir 'matrix-fragment.json'
if ($NoRain) {
  Copy-Item -Path $SrcFragment -Destination $FragmentDest -Force
} else {
  # The shader lives in a stable per-user folder; the installed fragment gets its absolute path.
  New-Item -ItemType Directory -Force -Path $AssetDir | Out-Null
  $ShaderDest = Join-Path $AssetDir 'matrix-rain.hlsl'
  Copy-Item -Path $SrcShader -Destination $ShaderDest -Force
  Write-Host "Installed shader: $ShaderDest"
  $frag = Get-Content -Raw -Encoding UTF8 -Path $SrcFragment | ConvertFrom-Json
  foreach ($prof in $frag.profiles) {
    $prof | Add-Member -NotePropertyName 'experimental.pixelShaderPath' -NotePropertyValue $ShaderDest -Force
  }
  [System.IO.File]::WriteAllText($FragmentDest, ($frag | ConvertTo-Json -Depth 10), $Utf8NoBom)
}
Write-Host "Installed fragment: $FragmentDest"

# --- 3. Claude Code theme -------------------------------------------------
New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
Copy-Item -Path $SrcTheme -Destination (Join-Path $ThemeDir ($ThemeSlug + '.json')) -Force
Write-Host "Installed Claude theme: $(Join-Path $ThemeDir ($ThemeSlug + '.json'))"

# --- 4. Claude Code settings.json (merge only our four keys) --------------
# Assign first, then cast: wrapping the pipeline in @() would nest a top-level JSON array.
$announcements = Get-Content -Raw -Encoding UTF8 -Path $SrcAnnounce | ConvertFrom-Json
$Managed = [ordered]@{
  theme                = ('custom:' + $ThemeSlug)
  spinnerVerbs         = (Get-Content -Raw -Encoding UTF8 -Path $SrcVerbs | ConvertFrom-Json)
  companyAnnouncements = [string[]]$announcements
  spinnerTipsOverride  = (Get-Content -Raw -Encoding UTF8 -Path $SrcTips | ConvertFrom-Json)
}
if (Test-Path $ClaudeSettings) {
  $settings = Get-Content -Raw -Encoding UTF8 -Path $ClaudeSettings | ConvertFrom-Json
} else {
  New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null
  $settings = New-Object PSCustomObject
}

# Remember each key's previous value so uninstall can put it back.
$state = [ordered]@{ keys = [ordered]@{}; backups = $backups }
foreach ($name in $Managed.Keys) {
  $had = $settings.PSObject.Properties.Name -contains $name
  $prev = $null
  if ($had) { $prev = $settings.$name }
  $state.keys[$name] = [ordered]@{
    had = $had
    previous = $prev
    installed = ($Managed[$name] | ConvertTo-Json -Compress -Depth 32)
  }
}
# Do not overwrite the saved "previous" values if install is run twice.
if (-not (Test-Path $StateFile)) {
  [System.IO.File]::WriteAllText($StateFile, ($state | ConvertTo-Json -Depth 32), $Utf8NoBom)
}

foreach ($name in $Managed.Keys) {
  $settings | Add-Member -NotePropertyName $name -NotePropertyValue $Managed[$name] -Force
}
$json = $settings | ConvertTo-Json -Depth 32
$null = $json | ConvertFrom-Json   # prove it parses before writing
[System.IO.File]::WriteAllText($ClaudeSettings, $json, $Utf8NoBom)
Write-Host "Updated $ClaudeSettings : set $($Managed.Keys -join ', ')"

# --- 5. PowerShell profile(s): green typed text via PSReadLine ------------
# MATRIX_THEME_PROFILE_PATHS (semicolon separated) overrides the target list, for testing on copies.
$MarkStart = '# >>> terminal-matrix-theme >>>'
$MarkEnd = '# <<< terminal-matrix-theme <<<'
if ($env:MATRIX_THEME_PROFILE_PATHS) {
  $ProfilePaths = @($env:MATRIX_THEME_PROFILE_PATHS -split ';' | Where-Object { $_ })
} else {
  $ProfilePaths = @($PROFILE.CurrentUserCurrentHost)
  if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $ProfilePaths += (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
  }
  $ProfilePaths = @($ProfilePaths | Select-Object -Unique)
}
$block = ([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'powershell\profile-block.ps1'), $Utf8NoBom)).TrimEnd() -replace "`r?`n", "`r`n"
foreach ($pp in $ProfilePaths) {
  # Decode without stripping a BOM so the file round-trips byte for byte.
  if (Test-Path $pp) { $text = $Utf8NoBom.GetString([System.IO.File]::ReadAllBytes($pp)) } else { $text = $null }
  if ($null -ne $text -and $text.Contains($MarkStart)) {
    Write-Host "Profile already has the Matrix block, left alone: $pp"
    continue
  }
  if ($null -ne $text) {
    $b = "$pp.bak-$Stamp"
    Copy-Item -Path $pp -Destination $b
    Write-Host "Backed up: $b"
    $new = $text + "`r`n" + $block
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pp) | Out-Null
    $new = $block
  }
  [System.IO.File]::WriteAllBytes($pp, $Utf8NoBom.GetBytes($new))
  Write-Host "Added PSReadLine colors block to: $pp"
}

Write-Host ''
Write-Host 'Done. Windows Terminal reloads fragments automatically; if the PowerShell tab is not green, reopen the window.'
Write-Host 'Claude Code picks up the theme and verbs in a new session.'
