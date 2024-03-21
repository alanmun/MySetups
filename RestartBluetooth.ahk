ScrollLock:: ; ScrollLock, aka the SLK key, should trigger this script whenever pressed

Send, #a
Sleep 900
Send, {Space} ; Toggle bluetooth OFF
Sleep 1400
Send, {Space} ; Toggle bluetooth back ON
Send, {Esc}    