INCLUDELIB kernel32.lib
INCLUDE winutil.inc

; Prototypes
SetConsoleTitleW PROTO

.DATA
ALIGN 16

; Strings
TextConsoleTitle_LEN    EQU     18  ; Text to Unicode 2
TextConsoleTitle        WORD    54h, 65h, 78h, 74h, 20h, 74h, 6Fh, 20h, 55h, 6Eh, 69h, 63h, 6Fh, 64h, 65h, 20h
                        WORD    32h, 00h
TextCredit_LEN          EQU     26  ;  by FireController#1847
TextCredit              WORD    20h, 62h, 79h, 20h, 46h, 69h, 72h, 65h, 43h, 6Fh, 6Eh, 74h, 72h, 6Fh, 6Ch, 6Ch
                        WORD    65h, 72h, 23h, 31h, 38h, 34h, 37h, 0Dh, 0Ah, 00h
TextPrompt_LEN          EQU     17  ; Text to Decode: 
TextPrompt              WORD    54h, 65h, 78h, 74h, 20h, 74h, 6Fh, 20h, 44h, 65h, 63h, 6Fh, 64h, 65h, 3Ah, 20h
                        WORD    00h
TextDecodeAgain_LEN     EQU     83  ; Type '1' and then press enter to decode again, otherwise type '0' and press enter.
TextDecodeAgain         WORD    54h, 79h, 70h, 65h, 20h, 27h, 31h, 27h, 20h, 61h, 6Eh, 64h, 20h, 74h, 68h, 65h
                        WORD    6Eh, 20h, 70h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h, 72h, 20h, 74h, 6Fh
                        WORD    20h, 64h, 65h, 63h, 6Fh, 64h, 65h, 20h, 61h, 67h, 61h, 69h, 6Eh, 2Ch, 20h, 6Fh
                        WORD    74h, 68h, 65h, 72h, 77h, 69h, 73h, 65h, 20h, 74h, 79h, 70h, 65h, 20h, 27h, 30h
                        WORD    27h, 20h, 61h, 6Eh, 64h, 20h, 70h, 72h, 65h, 73h, 73h, 20h, 65h, 6Eh, 74h, 65h
                        WORD    72h, 2Eh, 00h
TextUnknownOption_LEN   EQU     18  ; Unknown option.
TextUnknownOption       WORD    55h, 6Eh, 6Bh, 6Eh, 6Fh, 77h, 6Eh, 20h, 6Fh, 70h, 74h, 69h, 6Fh, 6Eh, 2Eh, 0Dh
                        WORD    0Ah, 00h
TextHexBuffer           QWORD   2 DUP (?)

.CODE
; Decode Procedure
Decode PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 28h    ; 20h for shadow space, 8h for 1 stack argument

    ; Prompt for input
    M_WRITECONSOLE TextNewline, TextNewline_LEN
    M_WRITECONSOLE TextPrompt, TextPrompt_LEN
    M_READCONSOLE
    M_WRITECONSOLE TextNewline, TextNewline_LEN
    M_UTF16LE_REMOVECRLF StdInBuffer, StdInCharsWritten

    ; Put "h, " into TextHexBuffer
    MOV DWORD PTR [TextHexBuffer + 8], 002C0068h
    MOV DWORD PTR [TextHexBuffer + 12], 00000020h

    ; Work our way through the string in the StdBuffer
    ; four bytes at a type.
    LEA RDX, StdInBuffer
    MOV R8, 0
decode_loop::
    ; Load next WORD and convert it
    XOR RCX, RCX
    MOV CX, WORD PTR [RDX]
    PUSH RDX
    PUSH R8
    CALL HexToUTF16LE
    MOV QWORD PTR [TextHexBuffer], RAX

    ; Add a newline every 15 lines
    POP R8
    CMP R8, 16
    JNE decode_loop_skip_newline
    M_WRITECONSOLE TextNewline, TextNewline_LEN
    XOR R8, R8
decode_loop_skip_newline::
    PUSH R8

    ; Check if the first two chars are zero
    ; If they are, delete them and print
    CMP WORD PTR [TextHexBuffer], 30h
    JNE decode_loop_zeronotok
    CMP WORD PTR [TextHexBuffer + 2], 30h
    JNE decode_loop_zeronotok
    MOV DWORD PTR [TextHexBuffer], 0
    M_WRITECONSOLE TextHexBuffer + 2, 6
    JMP decode_loop_afterzero
decode_loop_zeronotok::
    ; Otherwise, just print
    M_WRITECONSOLE TextHexBuffer, 8
decode_loop_afterzero::
    ; Then loop
    POP R8
    POP RDX
    INC R8
    ADD RDX, 2h
    CMP WORD PTR [RDX], 0
    JNZ decode_loop

    ; Print ", 00h"
    MOV DWORD PTR [TextHexBuffer], 00300030h
    MOV DWORD PTR [TextHexBuffer + 4], 00680000h
    M_WRITECONSOLE TextHexBuffer, 4

    ; Insert newline
    M_WRITECONSOLE TextNewline, TextNewline_LEN

    ; Prompt for repeat decode
    M_WRITECONSOLE TextNewline, TextNewline_LEN
    M_WRITECONSOLE TextDecodeAgain, TextDecodeAgain_LEN
    M_READCONSOLE

    ; Epilog
    ADD RSP, 28h
    MOV RSP, RBP
    POP RBP
    
    ; Should repeat? Otherwise return.
    CMP StdInBuffer[0], 31h
    JE Decode
    RET
Decode ENDP

; Main Procedure
main PROC
    ; Prolog
    PUSH RBP
    MOV RBP, RSP
    SUB RSP, 20h    ; 20h for shadow space

    ; Initialize the console
    CALL InitConsole

    ; Set the console's title
    LEA RCX, TextConsoleTitle
    CALL SetConsoleTitleW
    ; No error check. If it errors, it's fine.

    ; Write initial phrasing
    M_WRITECONSOLE TextConsoleTitle, TextConsoleTitle_LEN
    M_WRITECONSOLE TextCredit, TextCredit_LEN

    ; Go to the menu
    CALL Decode

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