<#
.SYNOPSIS
  Installs the Matrix look for Windows Terminal, PowerShell and Claude Code.
.DESCRIPTION
  1. Backs up Claude Code's settings.json and Windows Terminal's settings.json.
  2. Edits Windows Terminal's settings.json directly: adds the "Matrix Green" color scheme and sets
     colorScheme, font, cursorShape (and the rain shader path unless -NoRain) on the default profile
     and the PowerShell profiles. Previous values of exactly those keys are saved for uninstall.
  3. Copies the Claude Code theme into <claude home>\themes.
  4. Sets "theme", "spinnerVerbs", "companyAnnouncements" and "spinnerTipsOverride" in Claude
     Code's settings.json, and (unless -NoClaudeBanner) adds a SessionStart hook that shows a small
     banner. Other keys and other hooks are left alone.
  5. Adds green typed-text colors and a startup banner to your PowerShell profile(s).
  Run uninstall.ps1 to undo.
.PARAMETER NoRain
  Skip the falling-binary background shader.
.PARAMETER ClaudeTheme
  'ansi' (default) sets Claude Code's theme to the built-in dark-ansi, which uses the terminal's 16 colors
  (green with the Matrix Green scheme). 'custom' sets custom:matrix, for Claude Code versions that load
  custom themes. The theme file is installed either way.
.PARAMETER NoClaudeBanner
  Skip the Claude Code SessionStart banner hook.
#>
param(
  [switch]$NoRain,
  [switch]$NoClaudeBanner,
  [ValidateSet('ansi', 'custom')][string]$ClaudeTheme = 'ansi'
)
$ErrorActionPreference = 'Stop'

$AppName = 'terminal-matrix-theme'
$ThemeSlug = 'matrix'
$SchemeName = 'Matrix Green'
$HookMarker = 'matrix-session-banner.ps1'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Json([string]$Path) { Get-Content -Raw -Encoding UTF8 -Path $Path | ConvertFrom-Json }
function Has-Prop($Obj, [string]$Name) { $Obj.PSObject.Properties.Name -contains $Name }

if ($env:CLAUDE_CONFIG_DIR) { $ClaudeHome = $env:CLAUDE_CONFIG_DIR } else { $ClaudeHome = Join-Path $HOME '.claude' }
$ClaudeSettings = Join-Path $ClaudeHome 'settings.json'
$StateFile = Join-Path $ClaudeHome 'terminal-matrix-theme-state.json'
$ThemeDir = Join-Path $ClaudeHome 'themes'
$AssetDir = Join-Path $env:LOCALAPPDATA $AppName

# MATRIX_THEME_WT_SETTINGS overrides the Windows Terminal settings.json path, for testing on a copy.
if ($env:MATRIX_THEME_WT_SETTINGS) {
  $WtCandidates = @($env:MATRIX_THEME_WT_SETTINGS -split ';' | Where-Object { $_ })
} else {
  $WtCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
  )
}
$WtSettings = @($WtCandidates | Where-Object { Test-Path $_ })

$SrcScheme = Join-Path $PSScriptRoot 'windows-terminal\matrix-scheme.json'
$SrcShader = Join-Path $PSScriptRoot 'windows-terminal\matrix-rain.hlsl'
$SrcTheme = Join-Path $PSScriptRoot 'claude-code\themes\matrix.json'
$SrcVerbs = Join-Path $PSScriptRoot 'claude-code\spinner-verbs.json'
$SrcAnnounce = Join-Path $PSScriptRoot 'claude-code\company-announcements.json'
$SrcTips = Join-Path $PSScriptRoot 'claude-code\spinner-tips.json'
$SrcBanner = Join-Path $PSScriptRoot ('claude-code\' + $HookMarker)
$SrcProfileBlock = Join-Path $PSScriptRoot 'powershell\profile-block.ps1'
foreach ($f in @($SrcScheme, $SrcShader, $SrcTheme, $SrcVerbs, $SrcAnnounce, $SrcTips, $SrcBanner, $SrcProfileBlock)) {
  if (-not (Test-Path $f)) { throw "Missing source file: $f" }
  # Fail early if a source file is not valid JSON.
  if ($f -like '*.json') { $null = Read-Json $f }
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

# --- 2. Work out every change in memory, saving previous values first ------
$state = [ordered]@{ keys = [ordered]@{}; wt = @(); hook = $null; backups = $backups }

# 2a. Claude Code settings keys.
if ($ClaudeTheme -eq 'custom') { $ThemeValue = 'custom:' + $ThemeSlug } else { $ThemeValue = 'dark-ansi' }
$announcements = Read-Json $SrcAnnounce   # assign first: wrapping in @() would nest a top-level array
$Managed = [ordered]@{
  theme                = $ThemeValue
  spinnerVerbs         = (Read-Json $SrcVerbs)
  companyAnnouncements = [string[]]$announcements
  spinnerTipsOverride  = (Read-Json $SrcTips)
}
if (Test-Path $ClaudeSettings) {
  $settings = Read-Json $ClaudeSettings
} else {
  New-Item -ItemType Directory -Force -Path $ClaudeHome | Out-Null
  $settings = New-Object PSCustomObject
}
foreach ($name in $Managed.Keys) {
  $had = Has-Prop $settings $name
  $prev = $null
  if ($had) { $prev = $settings.$name }
  $state.keys[$name] = [ordered]@{
    had = $had
    previous = $prev
    installed = ($Managed[$name] | ConvertTo-Json -Compress -Depth 32)
  }
}

# 2b. Claude Code SessionStart hook (banner).
$ShowBannerHook = -not $NoClaudeBanner
if ($ShowBannerHook) {
  $BannerDest = Join-Path $AssetDir $HookMarker
  # Forward slashes: Claude Code may run hook commands through a POSIX shell on Windows.
  $hookCmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' + ($BannerDest -replace '\\', '/') + '"'
  $hadHooks = Has-Prop $settings 'hooks'
  $hadSessionStart = $hadHooks -and (Has-Prop $settings.hooks 'SessionStart')
  $state.hook = [ordered]@{ hadHooks = $hadHooks; hadSessionStart = $hadSessionStart }
}

# 2c. Windows Terminal settings.json.
$schemeDoc = Read-Json $SrcScheme
$ShaderDest = Join-Path $AssetDir 'matrix-rain.hlsl'
$ours = [ordered]@{
  colorScheme = $SchemeName
  font        = $schemeDoc.profile.font
  cursorShape = $schemeDoc.profile.cursorShape
}
if (-not $NoRain) { $ours['experimental.pixelShaderPath'] = $ShaderDest }
$PowerShellGuids = @('{61c54bbd-c2c6-5271-96e7-009a87ff44bf}', '{574e775e-4f2a-5b96-ac1e-a2962a402336}')

$wtPending = @()
foreach ($wtPath in $WtSettings) {
  try { $wt = Read-Json $wtPath } catch {
    Write-Host "Skipped $wtPath : it is not plain JSON (comments?). Set colorScheme '$SchemeName' by hand."
    continue
  }
  $rec = [ordered]@{ path = $wtPath; hadScheme = $false; previousScheme = $null; profiles = [ordered]@{} }

  # Scheme: add, or replace one with the same name.
  $schemes = @()
  if (Has-Prop $wt 'schemes') { $schemes = @($wt.schemes) }
  $old = @($schemes | Where-Object { $_.name -eq $SchemeName })
  if ($old.Count -gt 0) { $rec.hadScheme = $true; $rec.previousScheme = $old[0] }
  $keep = @($schemes | Where-Object { $_.name -ne $SchemeName })
  $wt | Add-Member -NotePropertyName 'schemes' -NotePropertyValue (@($keep) + $schemeDoc.scheme) -Force

  # Profiles: the default profile and the PowerShell profiles, matched by guid.
  $targets = @($PowerShellGuids)
  if (Has-Prop $wt 'defaultProfile') { $targets += [string]$wt.defaultProfile }
  if (Has-Prop $wt.profiles 'list') { $list = $wt.profiles.list } else { $list = $wt.profiles }
  foreach ($prof in @($list)) {
    if (-not (Has-Prop $prof 'guid')) { continue }
    if (-not ($targets | Where-Object { $_ -ieq [string]$prof.guid })) { continue }
    $keyRecs = [ordered]@{}
    foreach ($k in $ours.Keys) {
      $had = Has-Prop $prof $k
      $prev = $null
      if ($had) { $prev = $prof.$k }
      $keyRecs[$k] = [ordered]@{ had = $had; previous = $prev; installed = ($ours[$k] | ConvertTo-Json -Compress -Depth 32) }
      $prof | Add-Member -NotePropertyName $k -NotePropertyValue $ours[$k] -Force
    }
    $rec.profiles[[string]$prof.guid] = $keyRecs
  }
  $state.wt += $rec
  $wtPending += [pscustomobject]@{ Path = $wtPath; Obj = $wt }
}
$state.wt = @($state.wt)

# --- 3. Save state (first install only, so "previous" is never our own value) ---
if (Test-Path $StateFile) {
  $saved = Read-Json $StateFile
  foreach ($top in @('wt', 'hook')) {
    if (-not (Has-Prop $saved $top)) { $saved | Add-Member -NotePropertyName $top -NotePropertyValue $state[$top] -Force }
  }
  [System.IO.File]::WriteAllText($StateFile, ($saved | ConvertTo-Json -Depth 32), $Utf8NoBom)
} else {
  [System.IO.File]::WriteAllText($StateFile, ($state | ConvertTo-Json -Depth 32), $Utf8NoBom)
}

# --- 4. Apply ----------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $AssetDir | Out-Null

foreach ($p in $wtPending) {
  $json = $p.Obj | ConvertTo-Json -Depth 32
  $null = $json | ConvertFrom-Json   # prove it parses before writing
  [System.IO.File]::WriteAllText($p.Path, $json, $Utf8NoBom)
  Write-Host "Updated Windows Terminal settings: $($p.Path)"
}
if (-not $NoRain) {
  Copy-Item -Path $SrcShader -Destination $ShaderDest -Force
  Write-Host "Installed shader: $ShaderDest"
}

New-Item -ItemType Directory -Force -Path $ThemeDir | Out-Null
Copy-Item -Path $SrcTheme -Destination (Join-Path $ThemeDir ($ThemeSlug + '.json')) -Force
Write-Host "Installed Claude theme: $(Join-Path $ThemeDir ($ThemeSlug + '.json'))"

foreach ($name in $Managed.Keys) {
  $settings | Add-Member -NotePropertyName $name -NotePropertyValue $Managed[$name] -Force
}
if ($ShowBannerHook) {
  Copy-Item -Path $SrcBanner -Destination $BannerDest -Force
  $entry = [pscustomobject]@{
    matcher = 'startup'
    hooks   = @([pscustomobject]@{ type = 'command'; command = $hookCmd })
  }
  if (-not (Has-Prop $settings 'hooks')) { $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue (New-Object PSCustomObject) }
  if (-not (Has-Prop $settings.hooks 'SessionStart')) {
    $settings.hooks | Add-Member -NotePropertyName 'SessionStart' -NotePropertyValue @($entry)
  } elseif (-not ((@($settings.hooks.SessionStart) | ConvertTo-Json -Depth 32) -like "*$HookMarker*")) {
    $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + $entry
  }
  Write-Host "Added SessionStart banner hook: $BannerDest"
}
$json = $settings | ConvertTo-Json -Depth 32
$null = $json | ConvertFrom-Json
[System.IO.File]::WriteAllText($ClaudeSettings, $json, $Utf8NoBom)
Write-Host "Updated $ClaudeSettings : set $($Managed.Keys -join ', ')"

# --- 5. PowerShell profile(s): green typed text and banner -----------------
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
$block = ([System.IO.File]::ReadAllText($SrcProfileBlock, $Utf8NoBom)).TrimEnd() -replace "`r?`n", "`r`n"
$blockPattern = '(\r\n)?' + [regex]::Escape($MarkStart) + '[\s\S]*?' + [regex]::Escape($MarkEnd)
foreach ($pp in $ProfilePaths) {
  # Decode without stripping a BOM so the file round-trips byte for byte.
  if (Test-Path $pp) { $text = $Utf8NoBom.GetString([System.IO.File]::ReadAllBytes($pp)) } else { $text = $null }
  if ($null -ne $text) {
    $b = "$pp.bak-$Stamp"
    Copy-Item -Path $pp -Destination $b
    Write-Host "Backed up: $b"
    if ($text.Contains($MarkStart)) {
      # Refresh an older copy of the block in place.
      $new = [regex]::Replace($text, $blockPattern, { param($m) $m.Groups[1].Value + $block })
    } else {
      $new = $text + "`r`n" + $block
    }
  } else {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pp) | Out-Null
    $new = $block
  }
  [System.IO.File]::WriteAllBytes($pp, $Utf8NoBom.GetBytes($new))
  Write-Host "Wrote Matrix block (typed-text colors and banner) in: $pp"
}

Write-Host ''
Write-Host 'Done. Windows Terminal reloads settings.json on save; if a tab still looks old, open a new tab.'
Write-Host 'Claude Code picks up the theme, verbs and banner in a new session.'
