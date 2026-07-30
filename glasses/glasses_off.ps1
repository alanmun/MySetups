# glasses_off.ps1
Import-Module "$PSScriptRoot\glasses.psm1" -Force
Glasses-Off
Switch-Display '/internal'
Write-Host "glasses mode off."
