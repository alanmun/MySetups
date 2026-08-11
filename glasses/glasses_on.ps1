# glasses_on.ps1 - glasses become the only display, touchscreen goes quiet.
# Self-elevates; Disable-PnpDevice needs admin and silently no-ops without it.
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\glasses.psm1" -Force

if (-not (Test-Elevated)) {
  Start-Process powershell.exe -Verb RunAs -ArgumentList `
    '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`""
  return
}

if (Test-Flipped) {
  Write-Warning 'The lid is already folded past the hinge limit, so the keyboard and touchpad are gated off.'
  Write-Warning 'Open it back up first, then run this again.'
  Start-Sleep -Seconds 5
  return
}

try {
  Enter-GlassesMode
} catch {
  Write-Error $_
  Start-Sleep -Seconds 8
}
Start-Sleep -Seconds 2
