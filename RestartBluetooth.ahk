ScrollLock:: ; ScrollLock, aka the SLK key, should trigger this script whenever pressed

Run ms-settings:bluetooth

Loop {
  if WinExist("Settings") {
    Sleep 250 ; Unfortunately the window loads before UI is fully ready, and it leads to tab->space->space failing 25% of the time.
    break
  }
  Sleep 50 ; Try every 50ms until window is available
}
WinActivate, Settings ; After every sleep, try to focus the settings window just in case it somehow got unfocused. Its possible that I might move my mouse and click on something after fat-fingering the SLK key, thus tab and double spacing on some other app.

Send, {Tab} ; Moves focus to the bluetooth on/off radio button
Send, {Space} ; Toggle bluetooth OFF
Sleep 1100
WinActivate, Settings
Send, {Space} ; Toggle bluetooth back ON
; Passing 10x with 1100ms here. I think the issue really was that occasionally bt needs more time to shutdown after the first space press, so the second space will be ignored as its still shutting down. 1000ms is rarely too short of a wait time afaik.

WinClose, Settings ; Try to close a window with Bluetooth in its name
Return