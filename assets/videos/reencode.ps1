$ErrorActionPreference = "Stop"

$ffmpegPath = "C:\Users\Shawn\Downloads\ffmpeg-8.0.1-essentials_build\ffmpeg-8.0.1-essentials_build\bin\ffmpeg.exe"
$ffmpeg = $null
if (Test-Path $ffmpegPath) {
  $ffmpeg = $ffmpegPath
} else {
  $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($cmd) {
    $ffmpeg = $cmd.Source
  }
}
if (-not $ffmpeg) {
  Write-Error "ffmpeg not found in PATH. Install ffmpeg and re-run this script."
  exit 1
}

$videoFiles = @(
  "monastery.mp4",
  "desert_oasis.mp4",
  "mountain_bell.mp4",
  "vault_door.mp4"
)

foreach ($file in $videoFiles) {
  if (-not (Test-Path $file)) {
    Write-Warning "Missing video: $file (skipping)"
    continue
  }

  $backup = "$file.bak"
  if (-not (Test-Path $backup)) {
    Copy-Item $file $backup
  }

  $temp = "$file.tmp.mp4"

  & $ffmpeg -y `
    -i $file `
    -c:v libx264 -profile:v baseline -level 3.1 -pix_fmt yuv420p `
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" `
    -c:a aac -b:a 128k -movflags +faststart `
    $temp

  if (Test-Path $temp) {
    Move-Item -Force $temp $file
    Write-Host "Re-encoded: $file"
  } else {
    Write-Warning "Re-encode failed: $file"
  }
}
