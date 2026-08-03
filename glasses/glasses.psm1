#requires -version 5.1
using namespace System.IO

function Get-Config {
  param([string]$Path = "$PSScriptRoot\config.json")
  if (!(Test-Path $Path)) { throw "config.json not found at $Path" }
  Get-Content $Path -Raw | ConvertFrom-Json
}

function Get-YogaModeDevice {
  $cfg = Get-Config
  $dev = Get-PnpDevice -Class System -ErrorAction SilentlyContinue |
         Where-Object { $_.FriendlyName -eq $cfg.YogaModeFriendly } |
         Select-Object -First 1
  if (-not $dev -and $cfg.YogaModeFallbackInstance) {
    $dev = Get-PnpDevice -InstanceId $cfg.YogaModeFallbackInstance -ErrorAction SilentlyContinue
  }
  $dev
}

function Get-TouchscreenDevice {
  $cfg = Get-Config
  # try the real class name on WinPS 5.1
  $candidates = Get-PnpDevice -Class HIDClass -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match $cfg.TouchscreenHint }
  if (-not $candidates) {
    # fallback: search all devices if class query fails on this build
    $candidates = Get-PnpDevice -ErrorAction SilentlyContinue |
      Where-Object { $_.FriendlyName -match $cfg.TouchscreenHint }
  }
  # strongly prefer the literal "HID-compliant touch screen"
  $exact = $candidates | Where-Object { $_.FriendlyName -match '(?i)^HID-?compliant touch screen$' } | Select-Object -First 1
  if ($exact) { return $exact }
  # else, prefer enabled device
  $enabled = $candidates | Where-Object { $_.Status -eq 'OK' } | Select-Object -First 1
  if ($enabled) { return $enabled } else { return ($candidates | Select-Object -First 1) }
}


function Disable-IfPresent { param($Device) if ($Device) { Disable-PnpDevice -InstanceId $Device.InstanceId -Confirm:$false -ErrorAction SilentlyContinue } }
function Enable-IfPresent  { param($Device) if ($Device) { Enable-PnpDevice  -InstanceId $Device.InstanceId -Confirm:$false -ErrorAction SilentlyContinue } }

function Switch-Display {
  param([ValidateSet('/external','/internal')] [string]$Mode)
  Start-Process "$env:SystemRoot\System32\DisplaySwitch.exe" -ArgumentList $Mode -WindowStyle Hidden
}

function InternalPanelIsActive {
  $cfg = Get-Config
  $ids = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue |
         Select-Object -ExpandProperty InstanceName
  if ($ids) { return [bool]($ids -match $cfg.InternalPanelRegex) } else { return $false }
}

function Get-StatePath { Join-Path $PSScriptRoot 'state.json' }

function Get-LastMode {
  $p = Get-StatePath
  if (Test-Path $p) { (Get-Content $p -Raw | ConvertFrom-Json).Mode } else { $null }
}

function Set-LastMode { param([ValidateSet('on','off')]$Mode)
  @{ Mode = $Mode; When = (Get-Date) } | ConvertTo-Json | Set-Content (Get-StatePath)
}

function Glasses-On {
  $ymc = Get-YogaModeDevice
  $ts  = Get-TouchscreenDevice
  Disable-IfPresent $ymc
  Disable-IfPresent $ts
  Set-LastMode 'on'
}

function Glasses-Off {
  $ymc = Get-YogaModeDevice
  $ts  = Get-TouchscreenDevice
  Enable-IfPresent $ymc
  Enable-IfPresent $ts
  Set-LastMode 'off'
}
