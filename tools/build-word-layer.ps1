<#
.SYNOPSIS
  Draws the faint word layer (programming and hacker terms on black) as a PNG.
.DESCRIPTION
  The image tiles top-to-bottom without a seam, because the rain shader scrolls it upward and wraps it.
  It uses a fixed random seed, so running it again gives the same image. Uses System.Drawing only.
.PARAMETER OutPath
  Where to write the PNG. Defaults to windows-terminal\assets\hacker-words.png in this repo.
.PARAMETER WidthPx
  Image width in pixels.
.PARAMETER HeightPx
  Image height in pixels.
.PARAMETER Count
  How many words to place.
#>
param(
  [string]$OutPath = (Join-Path $PSScriptRoot '..\windows-terminal\assets\hacker-words.png'),
  [int]$WidthPx = 1920,
  [int]$HeightPx = 1080,
  [int]$Count = 44
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Terms = @(
  'NULL POINTER', 'STACK TRACE', 'HEAP OVERFLOW', 'RACE CONDITION', 'SEGFAULT', 'KERNEL PANIC',
  'ROOT SHELL', 'PACKET SNIFFER', 'MUTEX LOCK', 'BIT SHIFT', 'CHECKSUM', 'HANDSHAKE',
  'LOOPBACK', 'DAEMON', 'SUDO', 'REGEX'
)

$rng = New-Object System.Random 1337
$bmp = New-Object System.Drawing.Bitmap $WidthPx, $HeightPx
$g = [System.Drawing.Graphics]::FromImage($bmp)
try {
  $g.Clear([System.Drawing.Color]::Black)
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $placed = New-Object System.Collections.Generic.List[System.Drawing.RectangleF]

  for ($i = 0; $i -lt $Count; $i++) {
    $term = $Terms[$i % $Terms.Count]
    $sizePx = 14 + $rng.Next(0, 10)
    $font = New-Object System.Drawing.Font('Consolas', [single]$sizePx, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $box = $g.MeasureString($term, $font)
    # Try a few spots and keep the first that does not overlap a word already placed (with a margin).
    for ($try = 0; $try -lt 40; $try++) {
      $x = $rng.Next(0, [int]($WidthPx - $box.Width))
      $y = $rng.Next(0, $HeightPx)
      $r = New-Object System.Drawing.RectangleF(($x - 30), ($y - 20), ($box.Width + 60), ($box.Height + 40))
      $clash = $false
      foreach ($p in $placed) {
        # Compare against the copy one image height above and below too, because the image wraps.
        foreach ($dy in @(-$HeightPx, 0, $HeightPx)) {
          $q = New-Object System.Drawing.RectangleF($p.X, ($p.Y + $dy), $p.Width, $p.Height)
          if ($r.IntersectsWith($q)) { $clash = $true }
        }
      }
      if (-not $clash) { break }
    }
    if ($clash) { $font.Dispose(); continue }
    $placed.Add($r)

    # Mid greens only; the shader and backgroundImageOpacity dim them further.
    $green = 90 + $rng.Next(0, 70)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, $green, [int]($green * 0.25)))
    # Draw again one image height up when the word runs off the bottom, so the tile wraps cleanly.
    $g.DrawString($term, $font, $brush, [single]$x, [single]$y)
    if ($y + $box.Height -gt $HeightPx) { $g.DrawString($term, $font, $brush, [single]$x, [single]($y - $HeightPx)) }
    $brush.Dispose()
    $font.Dispose()
  }

  $dir = Split-Path -Parent $OutPath
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  Write-Host "Wrote $($placed.Count) words to $OutPath"
} finally {
  $g.Dispose()
  $bmp.Dispose()
}
