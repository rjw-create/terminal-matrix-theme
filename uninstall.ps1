<#
.SYNOPSIS
  Removes exactly what install.ps1 added.
.DESCRIPTION
  Deletes the Windows Terminal fragment and the Claude Code theme file, puts "theme" back to
  its previous value and removes "spinnerVerbs" (or restores the previous one) in Claude
  Code's settings.json. Other keys, including any changes made since install, are untouched.
  The timestamped .bak-* backups made by install.ps1 are left in place.
#>
$ErrorActionPreference = 'Stop'

$AppName = 'terminal-matrix-theme'
$ThemeSlug = 'matrix'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ($env:CLAUDE_CONFIG_DIR) { $ClaudeHome = $env:CLAUDE_CONFIG_DIR } else { $ClaudeHome = Join-Path $HOME '.claude' }
$ClaudeSettings = Join-Path $ClaudeHome 'settings.json'
$StateFile = Join-Path $ClaudeHome 'terminal-matrix-theme-state.json'
$ThemeFile = Join-Path $ClaudeHome ('themes\' + $ThemeSlug + '.json')
$FragmentDir = Join-Path $env:LOCALAPPDATA ('Microsoft\Windows Terminal\Fragments\' + $AppName)

if (Test-Path $FragmentDir) {
  Remove-Item -Recurse -Force -Path $FragmentDir
  Write-Host "Removed fragment folder: $FragmentDir"
}
if (Test-Path $ThemeFile) {
  Remove-Item -Force -Path $ThemeFile
  Write-Host "Removed Claude theme: $ThemeFile"
}

if ((Test-Path $ClaudeSettings) -and (Test-Path $StateFile)) {
  $state = Get-Content -Raw -Path $StateFile | ConvertFrom-Json
  $settings = Get-Content -Raw -Path $ClaudeSettings | ConvertFrom-Json
  $names = $settings.PSObject.Properties.Name

  if (($names -contains 'theme') -and ($settings.theme -eq ('custom:' + $ThemeSlug))) {
    if ($state.hadTheme) {
      $settings.theme = $state.previousTheme
      Write-Host "Restored theme = $($state.previousTheme)"
    } else {
      $settings.PSObject.Properties.Remove('theme')
      Write-Host 'Removed theme key (it was not set before install).'
    }
  }
  if ($names -contains 'spinnerVerbs') {
    if ($state.hadSpinnerVerbs) {
      $settings.spinnerVerbs = $state.previousSpinnerVerbs
      Write-Host 'Restored previous spinnerVerbs.'
    } else {
      $settings.PSObject.Properties.Remove('spinnerVerbs')
      Write-Host 'Removed spinnerVerbs key.'
    }
  }
  $json = $settings | ConvertTo-Json -Depth 32
  $null = $json | ConvertFrom-Json
  [System.IO.File]::WriteAllText($ClaudeSettings, $json, $Utf8NoBom)
  Remove-Item -Force -Path $StateFile
  Write-Host "Updated $ClaudeSettings"
} else {
  Write-Host 'No install state file found; Claude Code settings.json left unchanged.'
}

Write-Host ''
Write-Host 'Uninstalled. Windows Terminal settings.json was never edited, so nothing to restore there.'
Write-Host 'Backups (*.bak-*) made by install.ps1 remain next to each settings file.'
