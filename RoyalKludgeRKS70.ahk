; This script enhances my experience on the 75% RKS70 KB. This keyboard doesn't have a fn row so I came up with this solution, the built in soln by the manufacturers was awful

!1::  ; Alt + 1 for the monitor function
Run, explorer shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}  ; CLSID for "This PC"
return

!2::  ; Alt + 2 for the home function
Run, "https://www.youtube.com"  ; Replace with your homepage URL or action
return

!3::  ; Alt + 3 for mail
Run, "mailto:"  ; Opens the default mail client to compose a new mail
return

!4::  ; Alt + 4 for calculator
Run, Calc.exe  ; Opens the calculator
return

!5::  ; Alt + 5 for music player
Run, spotify.exe  ; Opens Windows Media Player, replace with your preferred player
return

!6::  ; Alt + 6 for stop music
Send, {Media_Stop}
return

!7::  ; Alt + 7 for previous track
Send, {Media_Prev}
return

!8::  ; Alt + 8 for play/pause
Send, {Media_Play_Pause}
return

!9::  ; Alt + 9 for next track
Send, {Media_Next}
return

!0::  ; Alt + 10 for mute
Send, {Volume_Mute}
return

!-::  ; Alt + - for volume down
Send, {Volume_Down}
return

!=::  ; Alt + = for volume up
Send, {Volume_Up}
return
