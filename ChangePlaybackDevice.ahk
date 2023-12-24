#SingleInstance force

^!F9::
    Run, mmsys.cpl
    WinWait,Sound
    ControlSend,SysListView321,{Down 2}
    ControlClick,&Set Default
    ControlClick,OK
    return
^!F10::
    Run, mmsys.cpl
    WinWait,Sound
    ControlSend,SysListView321,{Down 4}
    ControlClick,&Set Default
    ControlClick,OK
    return