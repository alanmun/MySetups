Import-Module "$PSScriptRoot\glasses.psm1" -Force

# load config + safe default
$cfg = Get-Config
$poll = 5
if ($cfg -and $cfg.PollSeconds) { $poll = [int]$cfg.PollSeconds }

# silent logfile (no console spam)
$log = Join-Path $PSScriptRoot 'monitor.log'
function Log([string]$msg){ ("[{0}] {1}" -f (Get-Date -Format o), $msg) | Out-File -FilePath $log -Append -Encoding utf8 }

Log "monitor start (poll=$poll)"
while ($true) {
  try {
    $internal = InternalPanelIsActive
    $last     = Get-LastMode

    if (-not $internal -and $last -ne 'on') {
      Glasses-On
      Log "glasses_on applied (internal panel off)"
    }
    elseif ($internal -and $last -ne 'off') {
      Glasses-Off
      Log "glasses_off applied (internal panel on)"
    }
  } catch {
    Log ("error: " + $_.Exception.Message)
  }
  Start-Sleep -Seconds $poll
}
