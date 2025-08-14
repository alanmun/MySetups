#Requires AutoHotkey v2.0

chromeId  := "chrome.Profile 2" ; Professional
firefoxId := "firefox.Profile0" ; Chill
btExe     := "bt.exe"
lastSet   := ""

; create a hidden gui (needed for shell hook registration)
myGui := Gui()
myGui.Opt("+AlwaysOnTop +ToolWindow -Caption")
myGui.Show("Hide")           ; start hidden
myGui.Move(0, 0, 0, 0)       ; set size to 0x0 at (0,0)

; shell hook registration
WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
DllCall("RegisterShellHookWindow", "Ptr", myGui.Hwnd)
OnMessage(WM_SHELLHOOK, ShellProc)

ShellProc(wParam, lParam, msg, hwnd) {
    global btExe, chromeId, firefoxId, lastSet

    if (wParam = 4) { ; HSHELL_WINDOWACTIVATED
        try {
            pid := WinGetPID("ahk_id " lParam)
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
            command := Format("{1} browser set default {2}", btExe, target)
            Run(command, "", "Hide")
            lastSet := target
        }
    }
}

while true
    Sleep 100000