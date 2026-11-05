<#
.SYNOPSIS
  Installs the Matrix look for Windows Terminal and Claude Code.
.DESCRIPTION
  1. Backs up Claude Code's settings.json and Windows Terminal's settings.json.
  2. Copies the Windows Terminal fragment (color scheme + PowerShell profile tweaks)
     into the per-user fragments folder. Windows Terminal's own settings.json is not edited.
  3. Copies the Claude Code theme into <claude home>\themes.
  4. Sets "theme" and "spinnerVerbs" in Claude Code's settings.json, leaving other keys alone.
  Run uninstall.ps1 to undo.
#>
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
foreach ($f in @($SrcFragment, $SrcTheme, $SrcVerbs)) {
  if (-not (Test-Path $f)) { throw "Missing source file: $f" }
  # Fail early if a source file is not valid JSON.
  $null = Get-Content -Raw -Path $f | ConvertFrom-Json
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
Copy-Item -Path $SrcFragment -Destination (Join-Path $FragmentDir 'matrix-fragment.json') -Force
Write-Host "Installed fragment: $(Join-Path $FragmentDir 'matrix-fragment.json')"

# --- 3. Claude Code theme -------------------------------------------------
New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
Copy-Item -Path $SrcTheme -Destination (Join-Path $ThemeDir ($ThemeSlug + '.json')) -Force
Write-Host "Installed Claude theme: $(Join-Path $ThemeDir ($ThemeSlug + '.json'))"

# --- 4. Claude Code settings.json (merge only our two keys) ---------------
$verbs = Get-Content -Raw -Path $SrcVerbs | ConvertFrom-Json
if (Test-Path $ClaudeSettings) {
  $settings = Get-Content -Raw -Path $ClaudeSettings | ConvertFrom-Json
} else {
  New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null
  $settings = New-Object PSCustomObject
}

$state = [ordered]@{
  hadTheme = $false; previousTheme = $null
  hadSpinnerVerbs = $false; previousSpinnerVerbs = $null
  backups = $backups
}
if ($settings.PSObject.Properties.Name -contains 'theme') {
  $state.hadTheme = $true
  $state.previousTheme = $settings.theme
}
if ($settings.PSObject.Properties.Name -contains 'spinnerVerbs') {
  $state.hadSpinnerVerbs = $true
  $state.previousSpinnerVerbs = $settings.spinnerVerbs
}
# Do not overwrite the saved "previous" values if install is run twice.
if (-not (Test-Path $StateFile)) {
  [System.IO.File]::WriteAllText($StateFile, ($state | ConvertTo-Json -Depth 32), $Utf8NoBom)
}

$settings | Add-Member -NotePropertyName 'theme' -NotePropertyValue ('custom:' + $ThemeSlug) -Force
$settings | Add-Member -NotePropertyName 'spinnerVerbs' -NotePropertyValue $verbs -Force
$json = $settings | ConvertTo-Json -Depth 32
$null = $json | ConvertFrom-Json   # prove it parses before writing
[System.IO.File]::WriteAllText($ClaudeSettings, $json, $Utf8NoBom)
Write-Host "Updated $ClaudeSettings : theme = custom:$ThemeSlug, spinnerVerbs = append ($($verbs.verbs.Count) verbs)"

Write-Host ''
Write-Host 'Done. Windows Terminal reloads fragments automatically; if the PowerShell tab is not green, reopen the window.'
Write-Host 'Claude Code picks up the theme and verbs on the next session (or immediately; it watches these files).'
