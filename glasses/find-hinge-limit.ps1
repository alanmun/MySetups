# find-hinge-limit.ps1 - find how far the lid can go before the EC kills input.
#
# Open the lid slowly past flat. The moment you hear the HIGH beep, the embedded
# controller has gated the internal keyboard and touchpad off in firmware -
# nothing in Windows can stop that. Back off slightly and that is your working
# limit for glasses mode.
#
# Needs no elevation and changes nothing.

$ErrorActionPreference = 'Continue'
Import-Module "$PSScriptRoot\glasses.psm1" -Force

function Beep2($f, $d) { try { [Console]::Beep($f, $d) } catch {} }

$seconds = 90
Write-Host ""
Write-Host "Open the lid slowly past flat." -ForegroundColor Cyan
Write-Host "  HIGH beep = crossed the limit, keyboard and touchpad are now dead" -ForegroundColor Yellow
Write-Host "  LOW beep  = back under the limit, input restored" -ForegroundColor Yellow
Write-Host "  Running for ${seconds}s. Ctrl+C to stop early." -ForegroundColor DarkGray
Write-Host ""

$prev = Get-SlateMode
Write-Host ("start: {0}" -f $(if ($prev -eq 1) { 'laptop mode, input alive' } else { 'already past the limit' }))

$end = (Get-Date).AddSeconds($seconds)
$crossings = 0
while ((Get-Date) -lt $end) {
  $now = Get-SlateMode
  if ($now -ne $prev) {
    $crossings++
    if ($now -eq 0) {
      Beep2 1400 220
      Write-Host ("  [{0:HH:mm:ss}] CROSSED THE LIMIT - keyboard and touchpad gated OFF" -f (Get-Date)) -ForegroundColor Red
    } else {
      Beep2 500 220
      Write-Host ("  [{0:HH:mm:ss}] back under the limit - input restored" -f (Get-Date)) -ForegroundColor Green
    }
    $prev = $now
  }
  Start-Sleep -Milliseconds 100
}

Write-Host ""
Write-Host "Done. $crossings crossing(s) seen." -ForegroundColor Green
if ((Get-SlateMode) -eq 0) {
  Write-Host "Lid is still past the limit - open it back up to get your keyboard back." -ForegroundColor Yellow
}
