# glasses_off.ps1 - back to the internal panel, touchscreen re-enabled.
$ErrorActionPreference = 'Stop'

Import-Module "$PSScriptRoot\glasses.psm1" -Force

if (-not (Test-Elevated)) {
  Start-Process powershell.exe -Verb RunAs -ArgumentList `
    '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`""
  return
}

try {
  Exit-GlassesMode
} catch {
  Write-Error $_
  Start-Sleep -Seconds 8
}
Start-Sleep -Seconds 2
