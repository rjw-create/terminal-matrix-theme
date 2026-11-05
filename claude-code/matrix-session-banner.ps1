# Claude Code SessionStart hook. Prints one JSON object whose systemMessage field
# Claude Code shows to the user. Plain ASCII, no escape codes.
$lines = @(
  '  00            11',
  ' 0  0   1100   1  1',
  ' 1  0  001000  0  1',
  '  01 1111101000 10',
  '    111111101010',
  '  10 0110011010 10',
  ' 0    11 1000 11    1',
  '0      0  10  0      0',
  '',
  'ACCESS GRANTED // CLAUDE ONLINE'
)
$msg = $lines -join "`n"
Write-Output (@{ systemMessage = $msg } | ConvertTo-Json -Compress)
