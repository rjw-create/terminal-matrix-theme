# >>> terminal-matrix-theme >>>
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
# <<< terminal-matrix-theme <<<
