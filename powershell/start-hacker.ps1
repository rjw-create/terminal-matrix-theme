<#
.SYNOPSIS
  Start script for the "Claude // Hacker" Windows Terminal profile.
.DESCRIPTION
  Shows a short cosmetic boot sequence (about 1.5 s, any key skips it), prints ACCESS GRANTED, then starts
  `claude` from PATH. The boot lines are decoration, not real status. Any extra arguments go to claude.
.PARAMETER SkipIntro
  Skip the boot sequence.
#>
param(
  [switch]$SkipIntro,
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$ClaudeArgs
)

$esc = [char]27
$green = "$esc[38;2;0;255;65m"
$dim = "$esc[38;2;47;158;68m"
$bright = "$esc[38;2;57;255;20m"
$red = "$esc[38;2;255;95;87m"
$reset = "$esc[0m"

# Sleeps in short slices and returns $true as soon as a key is pressed (the key is swallowed).
function Wait-OrSkip([int]$DelayMs) {
  $until = [DateTime]::UtcNow.AddMilliseconds($DelayMs)
  while ([DateTime]::UtcNow -lt $until) {
    try {
      if ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true); return $true }
    } catch { }   # no console input (redirected): just wait out the delay
    Start-Sleep -Milliseconds 20
  }
  return $false
}

Clear-Host
if (-not $SkipIntro) {
  $bootLines = @(
    '[ boot ] cold start: green-shell 2.0',
    '[  ok  ] phosphor warmed to 100%',
    '[  ok  ] mounting /dev/rain',
    '[  ok  ] cipher suite loaded: xor, rot13, hope',
    '[  ok  ] uplink negotiated on port 1337',
    '[  ok  ] coffee level nominal',
    '[  ok  ] operator fingerprint matched',
    '[ wait ] waking the agent ...'
  )
  # 8 lines x 180 ms = about 1.5 s in total.
  foreach ($line in $bootLines) {
    Write-Host ($dim + $line + $reset)
    if (Wait-OrSkip 180) { break }
  }
  Write-Host ''
}

Write-Host ($bright + '  +-----------------------------------+' + $reset)
Write-Host ($bright + '  |   A C C E S S   G R A N T E D     |' + $reset)
Write-Host ($bright + '  +-----------------------------------+' + $reset)
Write-Host ''

$claude = Get-Command claude -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $claude) {
  Write-Host ($red + '  claude was not found on PATH.' + $reset)
  Write-Host ($green + '  Install Claude Code (or add it to PATH), then open a new Claude // Hacker tab.' + $reset)
  Write-Host ($green + '  This tab stays open as a normal PowerShell prompt.' + $reset)
  return
}
Write-Host ($green + '  launching claude ...' + $reset)
& $claude.Source @ClaudeArgs
