#requires -version 5.1
# Glasses mode: drive the XREAL glasses as the only display and silence the
# touchscreen, so the lid can be laid back out of the way.
#
# This module deliberately does NOT touch the Lenovo Yoga Mode Control device.
# See README.md - disabling it cannot keep the internal keyboard alive past
# 180 deg, and it strands input until sleep/resume.

# StrictMode makes a missing config key throw instead of silently reading $null.
# The original code read $cfg.TouchscreenHint, which did not exist, and
# '-match $null' matches every string - so it searched all ~41 HID devices.
Set-StrictMode -Version Latest

function Get-Config {
  param([string]$Path = "$PSScriptRoot\config.json")
  if (!(Test-Path $Path)) { throw "config.json not found at $Path" }
  Get-Content $Path -Raw | ConvertFrom-Json
}

function Test-Elevated {
  ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 1 = laptop mode, 0 = folded past ~180 deg. Driven by the GPIO Laptop or Slate
# Indicator (ACPI\CIND0C60), which cannot be disabled - Disable-PnpDevice
# returns "Not supported".
function Get-SlateMode {
  try { [int](Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -ErrorAction Stop).ConvertibleSlateMode }
  catch { -1 }
}

function Test-Flipped { (Get-SlateMode) -eq 0 }

# The ACPI parent of the whole Wacom stack. Disabling it takes out touch, pen and
# the touchscreen's mouse emulation (all nine HID\WACF2200&COLxx children) at once.
function Get-TouchscreenDevice {
  $cfg = Get-Config

  $dev = Get-PnpDevice -InstanceId $cfg.TouchscreenParentId -ErrorAction SilentlyContinue
  if ($dev) { return $dev }

  # Fall back to a name search only if the instance ID has changed.
  Get-PnpDevice -Class HIDClass -ErrorAction SilentlyContinue |
    Where-Object { $_.FriendlyName -match $cfg.TouchscreenHint } |
    Select-Object -First 1
}

function Disable-Touchscreen {
  if (-not (Test-Elevated)) { throw 'Disable-Touchscreen requires an elevated session.' }
  $dev = Get-TouchscreenDevice
  if (-not $dev) { throw 'Touchscreen device not found - check TouchscreenParentId in config.json.' }
  if ($dev.Status -ne 'OK') { Write-Verbose "Touchscreen already disabled ($($dev.Status))."; return }
  # ErrorAction Stop on purpose: the original code swallowed every failure here,
  # so an unelevated run printed success while doing nothing at all.
  Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
}

function Enable-Touchscreen {
  if (-not (Test-Elevated)) { throw 'Enable-Touchscreen requires an elevated session.' }
  $dev = Get-TouchscreenDevice
  if (-not $dev) { throw 'Touchscreen device not found - check TouchscreenParentId in config.json.' }
  Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
}

function Switch-Display {
  param([ValidateSet('/external','/internal','/extend','/clone')][string]$Mode)
  Start-Process "$env:SystemRoot\System32\DisplaySwitch.exe" -ArgumentList $Mode -WindowStyle Hidden -Wait
}

function Get-ActiveMonitor {
  Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue |
    ForEach-Object {
      [pscustomobject]@{
        InstanceName = $_.InstanceName
        Name         = (-join [char[]]($_.UserFriendlyName | Where-Object { $_ -gt 0 }))
      }
    }
}

function Test-InternalPanelActive {
  $cfg = Get-Config
  $ids = (Get-ActiveMonitor).InstanceName
  if ($ids) { [bool]($ids -match $cfg.InternalPanelRegex) } else { $false }
}

function Test-GlassesConnected {
  $cfg = Get-Config
  [bool](Get-PnpDevice -Class Monitor -PresentOnly -ErrorAction SilentlyContinue |
         Where-Object { $_.InstanceId -notmatch $cfg.InternalPanelRegex -and $_.InstanceId -notmatch 'DEFAULT_MONITOR' })
}

function Enter-GlassesMode {
  if (-not (Test-Elevated)) { throw 'Enter-GlassesMode requires an elevated session.' }
  if (-not (Test-GlassesConnected)) { Write-Warning 'No external display detected - plug the glasses in first.' }

  Disable-Touchscreen
  Switch-Display '/external'
  Write-Host 'Glasses mode ON  - glasses are the only display, touchscreen disabled.' -ForegroundColor Green
  Write-Host 'Lay the lid back only as far as the hinge limit (run find-hinge-limit.ps1).' -ForegroundColor DarkGray
  Write-Host 'Past that the EC kills the keyboard and touchpad in firmware.' -ForegroundColor DarkGray
}

function Exit-GlassesMode {
  if (-not (Test-Elevated)) { throw 'Exit-GlassesMode requires an elevated session.' }
  Switch-Display '/internal'
  Enable-Touchscreen
  Write-Host 'Glasses mode OFF - internal panel and touchscreen restored.' -ForegroundColor Green
}

Export-ModuleMember -Function Get-Config, Test-Elevated, Get-SlateMode, Test-Flipped,
  Get-TouchscreenDevice, Disable-Touchscreen, Enable-Touchscreen, Switch-Display,
  Get-ActiveMonitor, Test-InternalPanelActive, Test-GlassesConnected,
  Enter-GlassesMode, Exit-GlassesMode
