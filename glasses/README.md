# glasses mode

Drive the XREAL glasses as the only display and silence the touchscreen, so the
lid can be laid back out of the way.

```powershell
.\glasses_on.ps1          # glasses only, touchscreen off  (self-elevates)
.\glasses_off.ps1         # internal panel back, touchscreen on
.\find-hinge-limit.ps1    # beeps when the lid crosses the point of no return
```

## Read this before trying to "fix" it again

**The original goal — fold the lid a full 360 so the screen hides under the
keyboard, then keep typing on the internal keyboard — is not achievable on this
machine.** Measured on a Yoga 9 14IAP7 (LENOVO 82LU, BIOS HNCN51WW), 2026-08-04.

The embedded controller gates the internal keyboard **and** touchpad off in
firmware once the hinge passes roughly 180 degrees. No Windows component sits in
that path, so no script can prevent it. Every candidate was ruled out by
measurement, each with a positive control proving the key detector actually
worked (`GetAsyncKeyState` polling, verified live with the lid open):

| What was tried | Result while flipped |
| --- | --- |
| Baseline | keyboard + touchpad DEAD |
| `ACPI\YMC2017` (Lenovo Yoga Mode Control) disabled, toggled correctly while open | DEAD |
| `ACPI\CIND0C60` (GPIO Laptop or Slate Indicator) disabled | **impossible** — `Disable-PnpDevice` returns `Not supported` |
| SmartSense + LenovoFnAndFunctionKeys + LITSSVC all stopped | DEAD |
| Sensor hub restored to healthy, everything stock | DEAD |

### Do not disable the Yoga Mode Control device

It is the component that gates the keyboard back **on** when the hinge comes back
under 180 degrees, and it only acts on a transition. Disable it and the next flip
strands your input — there is nothing left to un-gate it, and re-enabling it
afterwards does not help because no transition occurs. Recovery is sleep/resume
or a lid-close and sign back in. The old `Glasses-On` did exactly this, which is
why the mode never worked.

### The sensor hub matters

`Intel(R) Integrated Sensor Solution` had been disabled by hand
(`CM_PROB_DISABLED`, `ConfigFlags=1`), along with `SensorService` (start type
`Disabled`) — the usual way people kill auto-rotation on a Yoga. With the sensor
hub off, **flipping the laptop at all was a one-way trip**: the EC gated input off
and nothing brought it back without a sleep/resume.

Re-enabling both fixed that. Flip out and back now self-recovers:

```
while flipped   : KEYBOARD=DEAD  TOUCHPAD=DEAD
after flip-back : KEYBOARD=ALIVE TOUCHPAD=ALIVE
```

If auto-rotation ever becomes annoying again, turn it off with the rotation lock
(Win+A) rather than by disabling the sensor hub.

## What is actually here

- `glasses.psm1` — touchscreen enable/disable, display switching, slate-mode
  helpers. Runs under `Set-StrictMode -Version Latest`, so a missing config key
  throws instead of silently reading `$null`.
- `config.json` — `TouchscreenParentId` is the ACPI parent of the whole Wacom
  stack; disabling it takes out touch, pen and the touchscreen's mouse emulation
  (all nine `HID\WACF2200&COLxx` children) in one shot.

`monitor.ps1`, `run_hidden.vbs`, `state.json` and the `GlassesAutoToggle`
scheduled task were removed. That watcher keyed off display topology, so any time
the internal panel came back it re-enabled YMC — `monitor.log` showed every
`glasses_on` followed by a `glasses_off` 7-16 seconds later, on every attempt
going back to 2025.

## Bugs that were in the old version

1. `Get-TouchscreenDevice` read `$cfg.TouchscreenHint`, which did not exist in
   `config.json` (it defined `TouchscreenIds`). `-match $null` matches every
   string, so the candidate set was all ~41 HID devices. It only ever worked
   because an exact-name fallback happened to hit `HID-compliant touch screen`;
   had that missed, the next fallback would have disabled the first enabled HID
   device found — plausibly the touchpad.
2. `Disable-PnpDevice` / `Enable-PnpDevice` need elevation, and every call was
   wrapped in `-ErrorAction SilentlyContinue`. Run from a normal shell,
   `glasses_on.ps1` did nothing at all and still printed `glasses mode on.`
