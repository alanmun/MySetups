;; Virtual Media Keys Simplified

;;	Media Keys
;; Map Pause/Break to Previous
Break::Send {Media_Prev}
Pause::Send {Media_Prev}
;; Map PrintScreen to Play/Pause
PrintScreen::Send {Media_Play_Pause}
;; Map Delete to Next
Delete::Send {Media_Next}
;; Map F10 to Mute
F10::Send {Volume_Mute}
;; Map F11 to Volume Down
F11::Send {Volume_Down}
;; Map F12 to Volume Up
F12::Send {Volume_Up}

;;Currently Unused (Remove the ;; if you want to use it)
;; Map F9 to Stop
;;F9::Send {Media_Stop}