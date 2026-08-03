#Requires AutoHotkey v2.0

; Makes the focused browser the system default, so links opened by other apps
; land in the browser (and profile) already in front of you.

; ---------------- config ----------------
; Browser Tamer ids are per-machine: Chrome names its profile folders in creation
; order, so the same "Professional" profile is "Profile 1" on one box and
; "Profile 2" on another. Key each machine by its computer name -- `echo
; %COMPUTERNAME%` in cmd, or `$env:COMPUTERNAME` in PowerShell. Anything not
; listed falls back to defaultIds, so an unconfigured machine still works.

machineIds := Map()
machineIds.CaseSense := "Off"
machineIds["YOGITOP"] := {chrome: "chrome.Profile 1", firefox: "firefox.Profile0"} ; laptop

defaultIds := {chrome: "chrome.Profile 2", firefox: "firefox.Profile0"} ; desktop, and any machine not listed above

ids       := machineIds.Has(A_ComputerName) ? machineIds[A_ComputerName] : defaultIds
chromeId  := ids.chrome
firefoxId := ids.firefox

btExe := "bt.exe"
lastSet := ""

; Deleting and recreating a Chrome profile renumbers the folders, which would
; otherwise leave this script quietly making the wrong profile the default. Warn
; on startup instead of failing silently.
chromeDir := StrReplace(chromeId, "chrome.")
if !DirExist(EnvGet("LOCALAPPDATA") "\Google\Chrome\User Data\" chromeDir)
    TrayTip("Chrome has no '" chromeDir "' folder on " A_ComputerName "."
        . "`nAdd this machine to SetDefaultBrowser.ahk.", "SetDefaultBrowser")

; ---------------- hidden gui + shell hook ----------------
myGui := Gui()
myGui.Opt("+AlwaysOnTop +ToolWindow -Caption")
myGui.Show("Hide")
myGui.Move(0, 0, 0, 0)

WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
DllCall("RegisterShellHookWindow", "Ptr", myGui.Hwnd)
OnMessage(WM_SHELLHOOK, ShellProc)

ShellProc(wParam, lParam, msg, hwnd) {
    global btExe, chromeId, firefoxId, lastSet
    static HSHELL_WINDOWACTIVATED := 4

    if (wParam = HSHELL_WINDOWACTIVATED) {
        try {
            pid  := WinGetPID("ahk_id " lParam)
            proc := ProcessGetName(pid)
        } catch {
            return
        }
        target := ""
        if (proc = "chrome.exe") {
            target := chromeId
        } else if (proc = "firefox.exe") {
            target := firefoxId
        }
        if (target != "" && target != lastSet) {
            command := Format('"{1}" browser set default "{2}"', btExe, target)
            Run(command, "", "Hide")
            lastSet := target
        }
    }
}

while true
    Sleep 100000
