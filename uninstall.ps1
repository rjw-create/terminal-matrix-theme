<#
.SYNOPSIS
  Removes exactly what install.ps1 added.
.DESCRIPTION
  Deletes the Windows Terminal fragment, the rain shader and the Claude Code theme file, and puts the
  four keys install set (theme, spinnerVerbs, companyAnnouncements, spinnerTipsOverride) back to their
  previous values (or removes them) in Claude Code's settings.json. Other keys, including any changes made since install, are untouched.
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
$AssetDir = Join-Path $env:LOCALAPPDATA $AppName

if (Test-Path $FragmentDir) {
  Remove-Item -Recurse -Force -Path $FragmentDir
  Write-Host "Removed fragment folder: $FragmentDir"
}
if (Test-Path $AssetDir) {
  Remove-Item -Recurse -Force -Path $AssetDir
  Write-Host "Removed shader folder: $AssetDir"
}
if (Test-Path $ThemeFile) {
  Remove-Item -Force -Path $ThemeFile
  Write-Host "Removed Claude theme: $ThemeFile"
}

if ((Test-Path $ClaudeSettings) -and (Test-Path $StateFile)) {
  $state = Get-Content -Raw -Encoding UTF8 -Path $StateFile | ConvertFrom-Json
  $settings = Get-Content -Raw -Encoding UTF8 -Path $ClaudeSettings | ConvertFrom-Json

  foreach ($entry in $state.keys.PSObject.Properties) {
    $name = $entry.Name
    $rec = $entry.Value
    if (-not ($settings.PSObject.Properties.Name -contains $name)) { continue }
    # Only touch a key that still holds the value install wrote; anything you changed since stays.
    $current = $settings.$name | ConvertTo-Json -Compress -Depth 32
    if ($current -ne $rec.installed) {
      Write-Host "Left $name alone (it was changed after install)."
      continue
    }
    if ($rec.had) {
      $settings | Add-Member -NotePropertyName $name -NotePropertyValue $rec.previous -Force
      Write-Host "Restored previous $name."
    } else {
      $settings.PSObject.Properties.Remove($name)
      Write-Host "Removed $name (it was not set before install)."
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

$MarkStart = '# >>> terminal-matrix-theme >>>'
$MarkEnd = '# <<< terminal-matrix-theme <<<'
if ($env:MATRIX_THEME_PROFILE_PATHS) {
  $ProfilePaths = @($env:MATRIX_THEME_PROFILE_PATHS -split ';' | Where-Object { $_ })
} else {
  $ProfilePaths = @($PROFILE.CurrentUserCurrentHost)
  $ProfilePaths += (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
  $ProfilePaths = @($ProfilePaths | Select-Object -Unique)
}
$pattern = '(\r\n)?' + [regex]::Escape($MarkStart) + '[\s\S]*?' + [regex]::Escape($MarkEnd)
foreach ($pp in $ProfilePaths) {
  if (-not (Test-Path $pp)) { continue }
  $text = $Utf8NoBom.GetString([System.IO.File]::ReadAllBytes($pp))
  if (-not $text.Contains($MarkStart)) { continue }
  $new = [regex]::Replace($text, $pattern, '')
  if ($new.Length -eq 0) {
    Remove-Item -Force -Path $pp   # install created this file just for the block
    Write-Host "Removed profile that only held the Matrix block: $pp"
  } else {
    [System.IO.File]::WriteAllBytes($pp, $Utf8NoBom.GetBytes($new))
    Write-Host "Removed Matrix block from: $pp"
  }
}

Write-Host ''
Write-Host 'Uninstalled. Windows Terminal settings.json was never edited, so nothing to restore there.'
Write-Host 'Backups (*.bak-*) made by install.ps1 remain next to each settings file.'
