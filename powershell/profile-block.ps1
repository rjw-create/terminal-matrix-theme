# >>> terminal-matrix-theme >>>
# Green startup banner. Set MATRIX_THEME_NO_BANNER=1 to skip it. It is also skipped when the shell
# was started with -Command, -File or -EncodedCommand, so scripts stay quiet.
if (-not $env:MATRIX_THEME_NO_BANNER) {
  try {
    $matrixArgs = @([Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-(c|command|f|file|e|ec|encodedcommand)$' })
    if ($matrixArgs.Count -eq 0) {
      & {
        param($esc)
        $art = @'
        1010                              0010
      00011000                          10000100
     0011  0010                        0010  0001
     111    111           00  00       111    110
      01   0101           10  01       1111   00
       11  001             1111         011  00
        10010      011100111011111000   00000
          1011   0011100111110110000100  100
           00  01000101111001111100011100  01
     00    10 1101010001001100111011110000 10    10
      101   100101011011100000010110000001   0001
        010  1110011100010000010011000010  010
     01101110 10101011  1001001001  010100 1100011
    110    11   0101110111000001100101   11    011
    01      001    0100100010101110    000      01
   00         01    10  11  01  10     10         00
  01           0    1   0    1   1     1           10
'@
        Write-Host ("$esc[38;2;57;255;20m" + $art + "$esc[0m")
        Write-Host ("$esc[38;2;0;255;65m" + '  ACCESS GRANTED // TERMINAL ONLINE' + "$esc[0m")
        Write-Host ''
      } ([char]27)
    }
  } catch { }
}
# Green typed text for PSReadLine. Does nothing if PSReadLine is not available.
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
  try {
    & {
      param($esc)
      Set-PSReadLineOption -Colors @{
        Default            = "$esc[38;2;0;255;65m"
        Command            = "$esc[38;2;57;255;20m"
        Parameter          = "$esc[38;2;102;255;102m"
        Operator           = "$esc[38;2;180;255;77m"
        Variable           = "$esc[38;2;0;255;156m"
        String             = "$esc[38;2;125;255;79m"
        Number             = "$esc[38;2;0;255;0m"
        Member             = "$esc[38;2;140;255;107m"
        Type               = "$esc[38;2;0;255;156m"
        Keyword            = "$esc[38;2;204;255;0m"
        ContinuationPrompt = "$esc[38;2;0;255;65m"
        Comment            = "$esc[38;2;31;191;47m"
        Error              = "$esc[38;2;255;77;77m"
      }
    } ([char]27)
  } catch { }
}
# >>> terminal-matrix-theme prompt >>>
# ACCESS GRANTED prompt (ACCESS DENIED in red after a failed command). install.ps1 -NoPrompt leaves it out.
function global:prompt {
  $matrixOk = $?   # must be read first, before anything else resets it
  $matrixCode = $global:LASTEXITCODE
  $esc = [char]27
  if ($matrixOk) { $tag = "$esc[38;2;57;255;20mACCESS GRANTED" } else { $tag = "$esc[38;2;255;95;87mACCESS DENIED" }
  $where = $executionContext.SessionState.Path.CurrentLocation.Path
  $global:LASTEXITCODE = $matrixCode   # keep the real exit code for scripts that check it
  "$tag$esc[38;2;47;158;68m :: $where$esc[0m`n$esc[38;2;0;255;65m>$esc[0m "
}
# <<< terminal-matrix-theme prompt <<<
# <<< terminal-matrix-theme <<<
