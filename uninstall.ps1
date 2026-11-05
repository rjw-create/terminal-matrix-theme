<#
.SYNOPSIS
  Removes exactly what install.ps1 added.
.DESCRIPTION
  Restores the Windows Terminal settings.json keys install set (and removes the Matrix Green
  scheme), deletes the rain shader, banner script and Claude Code theme file, puts the four Claude
  Code keys (theme, spinnerVerbs, companyAnnouncements, spinnerTipsOverride) back to their previous
  values, removes the SessionStart banner hook, and removes the marked block from PowerShell
  profiles. Anything you changed after install is left alone.
  The timestamped .bak-* backups made by install.ps1 are left in place.
#>
$ErrorActionPreference = 'Stop'

$AppName = 'terminal-matrix-theme'
$ThemeSlug = 'matrix'
$SchemeName = 'Matrix Green'
$HookMarker = 'matrix-session-banner.ps1'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Json([string]$Path) { Get-Content -Raw -Encoding UTF8 -Path $Path | ConvertFrom-Json }
function Has-Prop($Obj, [string]$Name) { $Obj.PSObject.Properties.Name -contains $Name }

if ($env:CLAUDE_CONFIG_DIR) { $ClaudeHome = $env:CLAUDE_CONFIG_DIR } else { $ClaudeHome = Join-Path $HOME '.claude' }
$ClaudeSettings = Join-Path $ClaudeHome 'settings.json'
$StateFile = Join-Path $ClaudeHome 'terminal-matrix-theme-state.json'
$ThemeFile = Join-Path $ClaudeHome ('themes\' + $ThemeSlug + '.json')
$FragmentDir = Join-Path $env:LOCALAPPDATA ('Microsoft\Windows Terminal\Fragments\' + $AppName)
$AssetDir = Join-Path $env:LOCALAPPDATA $AppName

# An older version of this tool installed a Windows Terminal fragment; clean it up if present.
if (Test-Path $FragmentDir) {
  Remove-Item -Recurse -Force -Path $FragmentDir
  Write-Host "Removed old fragment folder: $FragmentDir"
}
if (Test-Path $AssetDir) {
  Remove-Item -Recurse -Force -Path $AssetDir
  Write-Host "Removed shader/banner folder: $AssetDir"
}
if (Test-Path $ThemeFile) {
  Remove-Item -Force -Path $ThemeFile
  Write-Host "Removed Claude theme: $ThemeFile"
}

if (Test-Path $StateFile) {
  $state = Read-Json $StateFile

  # --- Windows Terminal settings.json ---
  if (Has-Prop $state 'wt') {
    foreach ($rec in @($state.wt)) {
      if (-not (Test-Path $rec.path)) { continue }
      $wt = Read-Json $rec.path
      $schemes = @()
      if (Has-Prop $wt 'schemes') { $schemes = @($wt.schemes) }
      $schemes = @($schemes | Where-Object { $_.name -ne $SchemeName })
      if ($rec.hadScheme) { $schemes = @($schemes) + $rec.previousScheme }
      $wt | Add-Member -NotePropertyName 'schemes' -NotePropertyValue $schemes -Force

      if (Has-Prop $wt.profiles 'list') { $list = $wt.profiles.list } else { $list = $wt.profiles }
      foreach ($pg in $rec.profiles.PSObject.Properties) {
        $prof = @($list) | Where-Object { (Has-Prop $_ 'guid') -and ([string]$_.guid -ieq $pg.Name) } | Select-Object -First 1
        if ($null -eq $prof) { continue }
        foreach ($k in $pg.Value.PSObject.Properties) {
          $key = $k.Name
          $r = $k.Value
          if (-not (Has-Prop $prof $key)) { continue }
          if (($prof.$key | ConvertTo-Json -Compress -Depth 32) -ne $r.installed) {
            Write-Host "Left $key on profile $($pg.Name) alone (changed after install)."
            continue
          }
          if ($r.had) { $prof | Add-Member -NotePropertyName $key -NotePropertyValue $r.previous -Force }
          else { $prof.PSObject.Properties.Remove($key) }
        }
      }
      $json = $wt | ConvertTo-Json -Depth 32
      $null = $json | ConvertFrom-Json
      [System.IO.File]::WriteAllText($rec.path, $json, $Utf8NoBom)
      Write-Host "Restored Windows Terminal settings: $($rec.path)"
    }
  }

  # --- Claude Code settings.json ---
  if (Test-Path $ClaudeSettings) {
    $settings = Read-Json $ClaudeSettings
    foreach ($entry in $state.keys.PSObject.Properties) {
      $name = $entry.Name
      $rec = $entry.Value
      if (-not (Has-Prop $settings $name)) { continue }
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

    # SessionStart banner hook: remove only entries that point at our script.
    if ((Has-Prop $settings 'hooks') -and (Has-Prop $settings.hooks 'SessionStart')) {
      $rest = @(@($settings.hooks.SessionStart) | Where-Object { -not (($_ | ConvertTo-Json -Depth 32) -like "*$HookMarker*") })
      if ($rest.Count -ne @($settings.hooks.SessionStart).Count) {
        if ($rest.Count -gt 0) {
          $settings.hooks.SessionStart = $rest
        } else {
          $settings.hooks.PSObject.Properties.Remove('SessionStart')
          $hadHooks = $true
          if ((Has-Prop $state 'hook') -and $null -ne $state.hook) { $hadHooks = [bool]$state.hook.hadHooks }
          if ((-not $hadHooks) -and @($settings.hooks.PSObject.Properties).Count -eq 0) {
            $settings.PSObject.Properties.Remove('hooks')
          }
        }
        Write-Host 'Removed SessionStart banner hook.'
      }
    }
    $json = $settings | ConvertTo-Json -Depth 32
    $null = $json | ConvertFrom-Json
    [System.IO.File]::WriteAllText($ClaudeSettings, $json, $Utf8NoBom)
    Write-Host "Updated $ClaudeSettings"
  }
  Remove-Item -Force -Path $StateFile
} else {
  Write-Host 'No install state file found; Claude Code and Windows Terminal settings left unchanged.'
}

# --- PowerShell profiles ---
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
Write-Host 'Uninstalled. Backups (*.bak-*) made by install.ps1 remain next to each settings file.'
