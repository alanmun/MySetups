# glasses_on.ps1
Import-Module "$PSScriptRoot\glasses.psm1" -Force
Switch-Display '/external'
Start-Sleep 2
Glasses-On
Write-Host "glasses mode on."
