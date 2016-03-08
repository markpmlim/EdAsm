Name          : EQUATES.S
End of file   :      391
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;=================================================
; zero page usage by EdAsm Interpreter
; Since SW16 is used, the first 32 zero page
; locations must be treated with care
;
Z00         EQU    $00             ;Reg0
Z04         EQU    $04             ;Reg2
Z12         EQU    $12             ;Reg9-Ptr to Msg/Save Char
ErrCode     EQU    $72             ;error code
BufIndex    EQU    $76             ;Index into InBuf
MulCmdF     EQU    $77             ;multiple cmds if msb on
HelpF       EQU    $7C             ;Display Help Menu-$80