INCLUDELIB kernel32.lib
INCLUDE winutil.inc

.CODE
main PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h    ; 20h for shadow space

    ; Initialize Console
    CALL InitConsole

    ; Pause & Exit
    MOV RCX, 0
    CALL PauseAndExit

    ; Epilog (future proofing)
    ADD RSP, 20h
    MOV RSP, RBP
    POP RBP
    RET
main ENDP
END