Name          : EDASMINT.S
End of file   :   27,137
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            ORG    $B100
;=================================================
; EDASM Command Interpreter
; This module references of a number
; of routines and tables of EdAsm.Ed
;
EIStart     EQU    *
            LDX    #3
LB102       LDA    LB296,X         ;Mark pages $B1-$B8
            STA    BitMap+20,X     ; & $BF as used
            LDA    LB29D,X
            STA    PrtError,X
            DEX
            BPL    LB102
;
; Setup RESET vector
;
            LDX    #2
LB113       LDA    LB29A,X
            STA    SOFTEV,X
            DEX
            BPL    LB113
;
; Setup ctrl-Y command
;
            LDA    #$4C
            STA    USRADR
            LDA    #>EIWrmStrt
            STA    USRADR+1
            LDA    #<EIWrmStrt
            STA    USRADR+2
;
            LDA    TxtBgn+1        ;R5
            STA    TxtEnd+1        ;R7
            LDA    #$01
            STA    TxtBgn
            STA    TxtEnd          ;=$0801
;
            LDA    #>X9900
            STA    HiMem           ;HiMem for Editor=$9900
            LDA    #<X9900
            STA    HiMem+1
;
            SEC
            SBC    TxtBgn+1
            STA    FreeMem+1       ;=$99-$08
            LDA    #$00
            STA    FreeMem
            JSR    LB741           ;Load EdAsm.Ed
;
            LDA    #$00
            STA    ExitFlag
            BIT    RDBANK2
            JSR    LB3A4
            BIT    RDBANK2
            JSR    XDD41           ;Init tab table etc
            JSR    LB85D           ;Empty text buffer
            JSR    ClearScr
;
            LDY    #0
LB164       LDA    X9F83,Y         ;Display copyrights
            BEQ    LB16F
            JSR    PrChar
            INY
            BNE    LB164
;
; Check for the presence of the EdAsm.AutoST file
;
LB16F       LDA    #CR
            STA    SavCmdB
            JSR    LB836           ;Set curr pfx to EdAsm's dir
            LDA    #>X9D14         ;Is EdAsm.AutoST present?
            STA    Reg4
            LDA    #<X9D14
            STA    Reg4+1
            LDA    #TXTtype
            JSR    CkAttrF
            BCS    LB195           ;Not Found
            BNE    LB195           ;Found but wrong type
;
            LDX    #>XAD00         ;1024-byte I/O buffer
            LDY    #<XAD00
            JSR    OpenDFile       ;Open it
            JSR    LB866           ;Set prefix to curr pfx
            JMP    LB9D6           ;Proceed to read and exec its cmds
;
LB195       JSR    LB866
;
; ($B198) Reset/Ctrl-Y Entry Point
;
EIWrmStrt   EQU    *               ;ENTRY
            LDA    #$00
            STA    PtrMode         ;Disable printer
            BIT    ExecMode
            BPL    EIMainLoop      ;No
            ASL    ExecMode
            LDA    RdExeRN
            STA    CloseRN
            JSR    ClsFile
;
; $B1AB
;
EIMainLoop  EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $82
            DW     *
;
            JSR    X9E55           ;Date/Time Conversion
            JSR    XA788           ;Setup/reset I/O Hooks
            JSR    PrtCR
;
            LDY    #0              ;Display Date/Time
LB1BC       LDA    DateTime,Y
            JSR    PrChar
            INY
            CPY    #16
            BCC    LB1BC
;
            LDA    #0
            STA    MulCmdF
LB1CB       EQU    *               ;ENTRY
            BIT    RDBANK2
            JSR    XA788           ;Setup/Reset I/O Hooks
;
            LDA    #0
            STA    PrintF          ;Default to List
            STA    HelpF
            JSR    PrtCR
LB1DA       LDA    SwapMode        ;Do we have a split txt buf?
            BEQ    LB1E3           ;No
            ORA    #'0'            ;=$31/$32
            JSR    PrChar
;
LB1E3       LDA    #$FF
            STA    InvFlg
            LDA    CmdDelim
            STA    Prompt
            JSR    LB2BD           ;Get next cmd
;
LB1EE       TXA                    ;Do we have a cmd pending?
            BEQ    EIMainLoop      ;No
            LDA    InBuf
            CMP    #'*'            ;Ignore the cmd
            BEQ    LB1DA
            CMP    #CTRLR          ;Repeat List cmd?
            BNE    LB202
            JSR    LB2A1           ;Yes
            JMP    LB1EE
;
; Search Editor's command table
;
LB202       LDA    #>XDE18         ;Ptr to start of
            STA    LB286+1
            LDA    #<XDE18         ; Editor's cmd table
            STA    LB286+2
            JSR    X9AA5           ;Set R12 to point @ $BD00 buf
;
; Command parser
;
LB20F       LDX    #0              ;Index fr BO InBuf
LB211       EQU    *               ;ENTRY
            JSR    GetNBChar       ;Get a char and store in $12
            CPX    #1
            BNE    LB226
            CMP    #'/'            ;Help
            BEQ    LB220
            CMP    #'?'
            BNE    LB226
;
LB220       LDA    #$80            ;Flag help
            STA    HelpF
            BNE    LB211           ;always
;
; NB: Command Text is stored as a string of hi-ASCII
;
LB226       JSR    GetToken        ;Get token/char fr cmd table
            BPL    LB250           ;It's a token
;
            AND    #$7F
            CMP    Z12             ;Char fr InBuf (cmd line)
            BEQ    LB211           ;Got a match
            CMP    #'a'-1
            BCC    LB23D
            AND    #$DF            ;Convert to ucase
            CMP    Z12             ; and try again
            BEQ    LB211           ;Got a match
            BNE    LB226           ;No hit, try next token fr cmd table
;
LB23D       CMP    #','
            BEQ    LB226
            CMP    #'-'
            BEQ    LB226
;
; Not this command
;
LB245       JSR    GetToken        ;Get token fr cmd table
            BNE    LB245           ;Skip cmd text
            JSR    GetToken        ;Get token fr cmd table
            JMP    LB20F           ;Start fr BO InBuf
;
LB250       BIT    HelpF           ;Display Help?
            BPL    LB257
            JMP    DoHelp          ;Yes
;
; (A)-index (even #) into JMP table
; Use helper functions to parse a
; command line for user's parms
;
LB257       TAY                    ;Got the cmd now
            INY
            LDA    X9D21,Y         ;Get its jmp addr
            PHA                    ;Hibyte
            DEY
            LDA    X9D21,Y         ;JMP via RTS
            PHA                    ;LoByte
            RTS
;=================================================
; Get char fr input buffer
; Input
; ( X)-index into input buffer
; InBuf - user entry
; Output
;  (A)-char converted to ucase as required
;  (X)=(X)+1
;
GetChar     EQU    *
            LDA    InBuf,X
            AND    #$7F
            INX
            CMP    #'z'+1
            BCS    LB273
            CMP    #'a'
            BCC    LB273
            AND    #$DF
LB273       RTS
;=================================================
; ($B274) Get a non-blank char ignoring preceding spaces
; Output
;  (A)-char fr InBuf
;  (Z12)-char fr InBuf
;
GetNBChar   EQU    *               ;ENTRY
            JSR    GetChar         ;Get char fr InBuf
            CMP    #SPACE
            BEQ    GetNBChar       ;skip spaces
            STA    Z12
            RTS
;=================================================
; ($B27E) Get token fr cmd table ($DE18)
;
GetToken    EQU    *
            INC    LB286+1
            BNE    LB286
            INC    LB286+2
LB286       EQU    *               ;ENTRY
            LDA    IRQV+1          ;self-modifying code
LB289       RTS                    ;ENTRY
;=================================================
; Print EI's Error Messages
;
; (X)-index into message table $9CA0
;
LB28A       EQU    *               ;ENTRY
            LDX    #$31            ;Unknown cmd
            BNE    LB290
LB28E       EQU    *               ;ENTRY
            LDX    #$00            ;cmd syntax
LB290       EQU    *               ;ENTRY
            JSR    X9C98           ;Editor's Err Msg Printer
            JMP    EIMainLoop
;=================================================
LB296       DB     $00,$00,$7F,$81 ;mem bits
LB29A       DW     EIWrmStrt       ;RESET vector
            DB     $14             ;poweredup byte
;=================================================
LB29D       EQU    *
            JSR    PrErrMsg2
            RTS
;=================================================
; Restore the most recent LIST cmd into InBuf
;
LB2A1       EQU    *
            LDX    #-1
LB2A3       INX
            LDA    SavCmdB,X
            STA    InBuf,X
            CMP    #CR
            BNE    LB2A3
            RTS
;=================================================
; Save List cmd for later use (via ctrl-R)
;
LB2AF       EQU    *
            LDX    #0
LB2B1       LDA    InBuf,X
            STA    SavCmdB,X
            INX
            CMP    #CR
            BNE    LB2B1
            RTS
;=================================================
; Get the next cmd. If we are processing a multiple
; cmd line, then get it from the ExecLineB. Else
; read a command from the EXEC (txt) file
;
; Output
;  (X)-index eol
;
LB2BD       EQU    *
            BIT    MulCmdF         ;Multiple cmds?
            BMI    LB305           ;Yes
            BIT    ExecMode
            BPL    LB2F7           ;No
            JSR    PRODOS8
            DB     $CA
            DW     RdExecP
            BNE    LB2E5           ;(A)=error code
;
            LDA    #'+'            ;Show we have just read a cmd
            JSR    PrChar          ; line fr the EXEC file
            LDY    #0
LB2D4       LDA    InBuf,Y
            JSR    PrChar
            INY
            CPY    LBA9E
            BCC    LB2D4
;
            LDX    LBA9E           ;Empty Line?
            BNE    LB2FA           ;No
LB2E5       ASL    ExecMode        ;msb off
            LDX    RdExeRN
            STX    CloseRN
            JSR    ClsFile2
            CMP    #$4C            ;EOF?
            BEQ    LB2F7           ;yep
            JMP    PrErrMsg
;
LB2F7       JSR    XA70B           ;Get user's cmd
LB2FA       LDA    InBuf,X
            STA    ExecLineB,X
            DEX
            BNE    LB2FA
            BEQ    LB318           ;always
;
; Move next cmd forward and copy it to InBuf as well
;
LB305       LDX    BufIndex
            LDY    #0
LB309       LDA    ExecLineB,X
            STA    ExecLineB,Y
            STA    InBuf,Y
            INY
            INX
            CMP    #CR
            BNE    LB309
;
LB318       LDX    #0
LB31A       LDA    InBuf,X
            CMP    CmdDelim        ;Is it the cmd delimiter?
            BEQ    LB32B           ;Yes
            CMP    #CR
            BEQ    LB328
            INX
            BNE    LB31A
LB328       STA    MulCmdF         ;Flag there are no more multiple cmds
            RTS
;
LB32B       LDA    #$80
            STA    MulCmdF         ;Flag we have a multiple cmd line
            LDA    #CR
            STA    InBuf,X         ;Terminate the cmd
            INX
            STX    BufIndex        ;Save index to 1st char of next cmd
            DEX
            RTS
;=================================================
; $B339
;
PrtCR       EQU    *               ;ENTRY
            LDA    #CR
            BNE    PrChar
RingBell    EQU    *               ;ENTRY
            LDA    #BEL
            BNE    PrChar
ClearScr    EQU    *
            LDA    #FF             ;Form Feed
PrChar      EQU    *               ;ENTRY
            ORA    #$80
            CMP    #BS+$80
            BNE    LB34F
            DEC    PrColumn
            BPL    LB34F
            INC    PrColumn        ;Reset to 0
LB34F       CMP    #SPACE+$80      ;ctrl-chars?
            BCC    LB355           ;Yes, non-printable
            INC    PrColumn
LB355       CMP    #CR+$80
            BNE    LB35F
            PHA
            LDA    #0
            STA    PrColumn
            PLA
;
LB35F       BIT    RDROM2
            JSR    COUT
            BIT    RDBANK2
            AND    #$7F
            RTS
;=================================================
; Monitor rtns
;
LB36B       EQU    *               ;ENTRY
            BIT    RDROM2
            JSR    VTABZ
            BIT    RDBANK2
            RTS
;
LB375       EQU    *               ;ENTRY
            BIT    RDROM2
            JSR    BELL1
            BIT    RDBANK2
            RTS
;
LB37F       EQU    *               ;ENTRY
            BIT    RDROM2
            JSR    PRBLNK
            BIT    RDBANK2
            RTS
;
LB389       EQU    *               ;ENTRY
            BIT    RDROM2
            JSR    PRNTAX
            BIT    RDBANK2
            RTS
;
LB393       EQU    *               ;ENTRY
            BNE    LB39E
            BIT    RDROM2
            JSR    SETKBD
            JSR    SETVID
LB39E       BIT    RDROM2
            JMP    MONZ
;=================================================
; Perform some checks and inits
;
LB3A4       EQU    *
            LDA    #0
            STA    MulCmdF
            STA    PrColumn
            LDY    #2
LB3AC       STA    DevCtlS,Y
            DEY
            BPL    LB3AC
;
            LDA    #$FF
            STA    TruncF          ;trunc flag $FF=OFF, $00=ON
            STA    CaseMode        ;case flag msb=1 - ucase
            LDA    #':'            ;Default cmd delimiter
            STA    CmdDelim        ; for EXEC files
            JSR    XA75B           ;Chk for presence of 80-col card
            JSR    XA78A           ;(X)=$C3/$00-init/Reset I/O hooks
            LDA    VideoSlt        ;=$C3 if 80-col card present in slot 3
            AND    #%00000011
            STA    DevCtlS         ;=3
            RTS
;
            ASC    '29-MAR-84'
            ASC    '56:28          '
;=================================================
; EI's CSW entry point
; (A) = char to be printed
;
LB3D9       EQU    *               ;ENTRY
            CMP    #'a'-1+$80
            BCC    LB3E8           ;Is char a-z?
            CMP    #'z'+1+$80
            BCS    LB3E8
            BIT    MACHID          ;Is ][?
            BMI    LB3E8           ;No, //e or //c or /// emulation
            AND    #$1F            ;a-z -> $01-$1A
LB3E8       CMP    #$9D            ;ctrl-] - clrEOL
            BNE    LB3F6
            TYA
            PHA
            JSR    CLREOL
            PLA
            TAY
            LDA    #$9D
            RTS
;
LB3F6       CMP    #FF+$80         ; ctlr-L - form feed?
            BNE    LB404
            TYA
            PHA
            JSR    HOME
            PLA
            TAY
            LDA    #FF+$80
            RTS
;
LB404       BIT    RDROM2
            JMP    COUT1           ;Call Monitor's ROM rtn
;=================================================
; Command Interpreter's Error messages
;
LB40A       ASC    'PATH/FILENAME  MISSING' ;ENTRY
            DB     CR
LB420       ASC    'SYNTAX'        ;ENTRY
            DB     CR
LB427       ASC    'BAD            FORMAT' ;ENTRY
            DB     CR
LB432       ASC    'MEMORY         FULL' ;ENTRY
            DB     CR
LB43E       ASC    'BAD            RANGE' ;ENTRY
            DB     CR
LB448       ASC    'INVALID        PARAMETER ' ;ENTRY
            DB     CR
LB45B       ASC    'ALL            OR SOME?(A/S)?' ;ENTRY
            DB     CR
LB46E       ASC    'FILE           NOT FOUND'
            DB     CR
LB47D       ASC    'FILE           TYPE MISMATCH'
            DB     CR
LB490       ASC    'WRITE          PROTECTED'
            DB     CR
LB4A0       ASC    'FILE           LOCKED'
            DB     CR
LB4AC       ASC    'BAD            PATH/FILE NAME'
            DB     CR
LB4BF       ASC    'FILE           SIZE MISMATCH'
            DB     CR
LB4D2       ASC    'FILE           TOO LARGE'
            DB     CR
LB4E1       ASC    'DISK           FULL'
            DB     CR
LB4EB       ASC    'DISK           I/O FAILURE'
            DB     CR
LB4FC       ASC    'PRODOS         ERROR=$'
;
HexStr      DW     $5858
            DB     CR
LB50D       ASC    'DIRECTORY      NOT FOUND' ;ENTRY
            DB     CR
LB521       ASC    '               THE FILE IS LOCKED.  DESTROY ANYWAY (Y/N)?' ;ENTRY
            DB     CR
LB54D       ASC    'PATH           NOT FOUND'
            DB     CR
LB55C       ASC    'DUPLICATE      FILE NAME'
            DB     CR
LB570       ASC    'DIRECTORY      FULL'
            DB     CR
LB57F       ASC    'PLEASE         RE-MOUNT '
            DB     $80
LB590       ASC    'PRESS          RETURN TO CONTINUE '
            DB     $80
LB5AA       ASC    'ASSEMBLER      NOT ONLINE'
            DB     CR
;=================================================
; ($B5BF) Command interpreter's error message table
; Each entry consists of 3 bytes
;
ErrTable    EQU    *
            DB     $10             ;error code
            DW     LB4D2           ;msg ptr
            DB     $11
            DW     LB47D
            DB     $12
            DW     LB4BF
            DB     $27
            DW     LB4EB
            DB     $2A
            DW     LB4EB
            DB     $2B
            DW     LB490
            DB     $48
            DW     LB4E1
            DB     $46
            DW     LB46E
            DB     $40
            DW     LB4AC
            DB     $4B
            DW     LB4AC
            DB     $4E
            DW     LB4A0
            DB     $44
            DW     LB54D
            DB     $45
            DW     LB50D
            DB     $47
            DW     LB55C
            DB     $49
            DW     LB570
            DB     $FC
            DW     LB5AA
            DB     $FD
            DW     LB590
            DB     $FE
            DW     LB57F
            DB     $FF
            DW     LB4FC
;=================================================
; ($B5F8)
; Input
;  (A)=error code
;
FatalErr    EQU    *               ;ENTRY
            TAX                    ;error code
            PLA                    ;dump RTS addr
            PLA
            TXA
            JMP    PrErrMsg
;=================================================
;
LB5FF       JSR    ClsFile2        ;ENTRY
;
; ($B602) Print Error Message and return to CI mainloop
;  (A) - error code
;
PrErrMsg    EQU    *               ;ENTRY
            JSR    PrErrMsg2
            JMP    EIWrmStrt
;=================================================
; ($B608)
; Input
;  (A)=error code
;
PrErrMsg2   LDX    #$39
LB60A       DEX
            DEX
            DEX
            BMI    LB649           ;Not found
            CMP    ErrTable,X      ;Is this the error code?
            BNE    LB60A           ;keep searching
;
            INX
            LDA    ErrTable,X      ;msg ptr
            STA    Z12             ;Reg9
            INX
            LDA    ErrTable,X
            STA    Z12+1
;
LB620       EQU    *               ;ENTRY
            LDA    #'E'
            JSR    PrChar
            LDA    #'R'
            JSR    PrChar
            JSR    PrChar
            JSR    RingBell
            LDA    #':'
            JSR    PrChar
            LDA    #SPACE
            JSR    PrChar
;
            LDY    #0
LB63C       LDA    (Z12),Y         ;Reg9
            BMI    LB648
            JSR    PrChar
            INY
            CMP    #CR
            BNE    LB63C
LB648       RTS
;
; Error code not in our table
; Just show a generic error message
;
LB649       STA    ErrCode         ;error code
            JSR    Cnv2Hex
            STA    HexStr+1
            STX    HexStr
            LDA    #$FF            ;Show err msg w/errcode in hex
            JMP    PrErrMsg2
;=================================================
LB659       EQU    *               ;ENTRY
            LDA    #CR
            CMP    Z12
            BEQ    LB662
            JMP    LB28E           ;cmd syntax
;
; 3 of the commands get some special treament viz
; ASM, END and LIST
;
LB662       LDA    #$00
            STA    Z00+1
            JSR    GetToken        ;Get token fr Cmd table
            STA    Z00
            BEQ    LB6E6           ;ASM cmd
;
            CMP    #$5C            ;END cmd
            BEQ    LB6A4
            CMP    #$26            ;LIST cmd?
            BNE    LB67A
            JSR    LB2AF           ;Yes, make a copy of cmd
            LDA    Z00
LB67A       LDY    Z00
            CPY    #$5D            ;']' - sentinel value
            BCC    LB682
; $D680
            LDY    #0
LB682       LDA    XDFA2,Y
            STA    Z04             ;Set SW16 R2 w/JMP addr-1
            INY
            LDA    XDFA2,Y
            STA    Z04+1
            STA    RDBANK2
            BIT    PtrMode         ;Is Printer on?
            BPL    LB697           ;No
            JSR    XD610           ;Init printer
;
; The last instruction of the Sweet16 code below
; will take us to the addr stored in R2 since
; R15 is SW16's PC
;
LB697       JSR    NEWSW16
            SET    R0,CR
            DCR    R5
            STI    R5
            LD     R2
            SET    R12,XBD00
            ST     R15
;=================================================
; END cmd
;
LB6A4       EQU    *
            LDA    SwapMode        ;Do we have a split txt buf?
            BNE    LB6EA           ;Yes, so can't quit
            JSR    XA872           ;Load Quit Code
            LDX    #$00            ;Slot #
            JSR    XA78A           ;Init I/O Hooks
;
            LDA    ROMIN2
            LDA    ROMIN2
            LDA    #$60            ;RTS
            STA    USRADR
            LDA    #>BASCLD
            STA    SOFTEV
            LDA    #<BASCLD        ;Vector @ $E000 -> $F128
            STA    SOFTEV+1
            LDA    #$45
            STA    PWREDUP
            JSR    SETKBD
            JSR    SETVID
            JSR    HOME
            JSR    PRODOS8
            DB     $65
            DW     QuitP
;
LB6D9       EQU    *
            STA    InBuf+$FF
            JMP    BASCLD          ;Do a Monitor cold Start
;
QuitP       DB     $04
            DB     $00             ;If quit type $EE,
            DW     $0000           ; addr of launch pathname
            DB     $00             ; reserved
            DW     $0000
;=================================================
; Prepare for Assembly
;
LB6E6       EQU    *
            LDA    SwapMode        ;Do we have a split txt buf?
            BEQ    LB6EF           ;No
LB6EA       EQU    *               ;ENTRY
            LDX    #$41            ;Multi-buffer
            JMP    LB290
;
LB6EF       LDA    TxtEnd+1        ;Is edit buffer empty?
            CMP    TxtBgn+1
            BNE    LB6FB
            LDA    TxtEnd
            CMP    TxtBgn
            BEQ    LB700           ;Yes
LB6FB       LDX    #$47            ;'Buffer'
            JMP    LB290
;
LB700       LDA    #SPACE
            LDX    #16
LB704       STA    DateTime,X      ;Prepare data area
            DEX
            BPL    LB704
;
            JSR    PRODOS8
            DB     $82             ;Get time
            DW     *
            JSR    X9E55           ;Date/Time Conversion
;
; The assembler uses the Editor's first 3 tabs
; if the 1st tab col of user-defined tab
; table is < 12. Otherwise, a modified tab
; table is passed to the assembler
;
            LDY    #2
LB715       LDX    UserTabT        ;Get 1st tab col
            CPX    #12
            BCC    LB729
            LDA    UserTabT,Y
; DB $B9,$68,$00
            CLC
            ADC    #17
LB721       STA    TabTable,Y      ;Tabs table passed to the assembler
            DEY
            BPL    LB715
            BMI    DoAsmbly        ;always
;
LB729       LDA    X9D11,Y         ;Editor's default tab table
            BNE    LB721           ;always
;
DoAsmbly    LDA    #$00
            STA    PtrMode         ;Disable Printer
            JSR    LoadAsm
            LDA    RDBANK2
            JSR    X7800           ;xfer control to Assembler
            JSR    LB741           ;Re-load EdAsm.Ed
            JMP    EIMainLoop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set prefix to EdAsm's Launch dir
; Load the Editor's modules into mem
; Relocator module loaded @ $8900-$98FF to
; $D000 LC Bank2
; Return to caller if successful else crash into Monitor
;
LB741       EQU    *
            JSR    LB836           ;Set prefix to EdAsm's Dir
            BCC    LoadDEd
            LDA    #$FE            ;Re-mount...
            JSR    PrErrMsg2
;
; Print EDASM's launch dir. This directory contains
; the files EDASM.SYSTEM, EDASM.ED and EDASM.ASM
; $BE79-BA(65 bytes incl leading and trailing /'s)
;
            LDY    #0
            LDX    EdAsmDir        ;len byte
LB750       LDA    EdAsmDir+1,Y
            JSR    PrChar
            INY
            DEX
            BNE    LB750
;
            JSR    PrtCR
            LDA    #$FD            ;Press return...
            JSR    PrErrMsg2
;
WaitK1      LDA    KBD
            BPL    WaitK1
            BIT    KBDSTROBE
            CMP    #CR+$80
            BNE    WaitK1
            JSR    PrtCR
            JMP    LB741           ;try again
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the file EDASM.ED
;
; $9900-$A8FF - Editor overlay
; $D000-$DFFF - Editor code
;
LoadDEd     LDA    #>LoadAdrEd
            STA    ReadDBuf
            LDA    #<LoadAdrEd
            STA    ReadDBuf+1
            LDA    #$00
            STA    ReadLen         ;$2000
            LDA    #$20
            STA    ReadLen+1
            LDX    #>EdStr
            LDY    #<EdStr
            JSR    LoadMod
            BCS    LB7BF
;
            LDA    #>LoadAdrEd
            STA    A1              ;start addr
            LDA    #<LoadAdrEd
            STA    A1+1
            LDA    #>LoadAdrEd+$1000-1
            STA    A2              ;end addr
            LDA    #<LoadAdrEd+$1000-1
            STA    A2+1
            LDA    #$FF
            STA    BitMap+20       ;Reserve pages $A0-$A7
            LDA    #%00011111      ;Mark pages $98-$9A
            STA    BitMap+19       ; as free
;
; ($B7AB) Move code btwn $8900-$98FF to the LC Bank2
; Also referenced by Editor to move Quit Code
; back to LC Bank2
;
Mv2LCB2     EQU    *               ;ENTRY
            LDA    #>XD000         ;dest addr
            STA    A4
            LDA    #<XD000
            STA    A4+1
            LDA    ROMIN2
            LDA    ROMIN2
            LDY    #$00
            JSR    MOVE            ;Monitor rtn
            RTS
;
; Error loading Editor's Modules
;
LB7BF       STA    ErrCode         ;A=err code
            TSX
            STX    StackP2
            LDX    #$80
            TXS
            LDA    RDROM2
            JSR    SETKBD
            JSR    SETVID
            JSR    HOME
            JSR    PRERR
            JMP    MON             ;Crash!
;=================================================
; Load the file EDASM.ASM
; $7800-$9EFF - Assembler overlay
; $D000-$DFFF (bank2) - Assembler tables,
;  Sorting,print symbol tables
;=================================================
LoadAsm     EQU    *
            JSR    LB836           ;Set prefix to EdAsm's Boot Dir
            BCC    LB7E6
            JSR    LB83D           ;Set to user's prefix
            LDA    #$FC            ;err code
            JMP    PrErrMsg
;
LB7E6       LDA    #$00            ;Setup the bit map
            STA    BitMap+20       ;Mark pages $98-$A7
            STA    BitMap+19       ; as free
;
            LDA    #$00
            STA    ReadLen         ;=$4000
            LDA    #$40
            STA    ReadLen+1
            LDA    #>LoadAdrAsm
            STA    ReadDBuf
            LDA    #<LoadAdrAsm
            STA    ReadDBuf+1
            LDX    #>AsmStr
            LDY    #<AsmStr
            JSR    LoadMod
            BCC    LB822
;
            CMP    #$45            ;vol not mounted
            BEQ    LB817
            CMP    #$46            ;file not found
            BEQ    LB817
            CMP    #$44            ;non-existent file
            BNE    LB819
;
LB817       LDA    #$FC
LB819       JSR    PrErrMsg2
            JSR    LB741           ;Load Editor's Modules
            JMP    EIWrmStrt
;
; Assembler's modules successfully loaded
;
LB822       LDA    #>LoadAdrAsm
            STA    A1              ;start addr
            LDA    #<LoadAdrAsm
            STA    A1+1
            LDA    #>LoadAdrAsm+$1000-1
            STA    A2
            LDA    #<LoadAdrAsm+$1000-1
            STA    A2+1            ;end addr
            JSR    Mv2LCB2         ;Set dest addr and do move
            RTS
;=================================================
; Set prefix to EdAsm's Boot Dir
;
LB836       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $C6
            DW     SPfxEdAsm
            RTS
;
; Set prefix to user's prefix
;
LB83D       JSR    PRODOS8
            DB     $C6
            DW     SPfx1P
            RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ($B844) Load EdAsm's modules
; EdAsm.Ed or EdAsm.Asm are loaded into memory
; Input
;  (X,Y) - ptr to filename
;
LoadMod     EQU    *               ;ENTRY
            LDA    #$FF
            STA    ExitFlag
            STX    Reg4            ;ptr to file name
            STY    Reg4+1
            LDA    #BINtype
            JSR    OpenNRd
            PHP                    ;Save error status
            LSR    ExitFlag        ;Set/reset msb with the Carry-bit
            PHA
            JSR    LB83D           ;Set to user's prefix
            PLA
            PLP
            RTS
;=================================================
; Effectively "emptying" the textedit buffer
;
LB85D       LDA    TxtBgn
            STA    TxtEnd
            LDA    TxtBgn+1
            STA    TxtEnd+1
            RTS
;=================================================
; Set default prefix to the user's prefix
;
LB866       JSR    PRODOS8
            DB     $C6
            DW     SPfx1P
            BNE    LB86F
            RTS
;
LB86F       EQU    *               ;ENTRY
            CMP    #$40            ;Invalid pathname
            BEQ    LB876
            JMP    ErrHndlr
;
LB876       JMP    PrErrMsg
;=================================================
; EI's error handler
; Input
;  ExitFlag - $00,$FF,$8x
;
ErrHndlr    EQU    *
            BIT    ExitFlag
            BPL    LB880
            SEC
            RTS
;
LB880       JMP    FatalErr
;=================================================
; ($B883) Check attributes of file (if it exists)
; Input
;  (A)-filetype
; Output
;  (A) - error code if not found/wrong filetype
;  C=1 - Not found
;  C=0, Z=0 - Found but wrong filetype
;  C=0, Z=1 - Found
;
CkAttrF     EQU    *               ;ENTRY
            STA    FileType        ;ftype
            JSR    SetupFN
            LDA    #>FileNameB
            STA    GFIPath
            STA    PathNameP
            LDA    #<FileNameB
            STA    GFIPath+1
            STA    PathNameP+1
            JSR    PRODOS8
            DB     $C4
            DW     GFInfoP
            BEQ    LB8A7
;
            CMP    #$46            ;file not found
            BEQ    LB8B1           ;C=1, (A)=$46 Z=1
            JMP    ErrHndlr
;
LB8A7       LDA    GFIftype
            CMP    FileType
            BEQ    LB8B0           ;C=0, Z=1
            LDA    #$11            ;File type mismatch (C=0,Z=0, (A)=$11)
LB8B0       CLC
LB8B1       RTS
;=================================================
; ($B8B2) Setup file name
; Input
;  (Reg4)=ptr to the filename
;
SetupFN     EQU    *               ;ENTRY
            LDY    #0
LB8B4       LDA    (Reg4),Y
            BEQ    LB8C7           ;null-terminated
            AND    #$7F
            CMP    #SPACE
            BEQ    LB8C7           ;Ignore rest of text
            STA    FileNameB+1,Y
            STA    TxBuf2+1,Y
            INY
            BPL    LB8B4
LB8C7       STY    FileNameB       ;len byte of filename
            STY    TxBuf2
            RTS
;=================================================
; ($B8CE) Open the file for reading. All files BIN/TXT files
; are opened for reading and writing using this rtn
; Input
;  (X,Y)- ptr to 1024-byte buffer of PRODOS to use
;  PathNameP - Pathname of file to be opened
;
OpenDFile   EQU    *               ;ENTRY
            STX    IOBufP
            STY    IOBufP+1
            JSR    PRODOS8
            DB     $C8
            DW     OpenPB
            BCC    LB8DF
            JMP    ErrHndlr
;
LB8DF       LDA    OpenRN
            STA    ReadRN
            STA    WriteRN
            STA    GeofRN
            STA    CloseRN
            RTS
;=================================================
; ($B8EF)
;
ClsFile     EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $CC
            DW     CloseP
            BEQ    LB8FA
            JMP    ErrHndlr
;
LB8FA       STA    CloseRN         ;zero ref #
            RTS
;=================================================
; ($B8FE)
; (A)-error code
; Preserved (A)
;
ClsFile2    EQU    *               ;ENTRY
            PHA
            JSR    ClsFile
            PLA
            RTS
;=================================================
LB904       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $C3
            DW     SFInfoP
            RTS
;
LB90B       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $C1
            DW     DestroyP
            RTS
;
LB912       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $C2
            DW     RenameP
            RTS
;
LB919       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $C0
            DW     CreateP
            RTS
;
LB920       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $CB
            DW     WritePB
            RTS
;
LB927       EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $D0
            DW     SeofP
            RTS
;=================================================
; Used by EXIT cmd to transfer control
; to a SYSTEM program
;
LB92E       EQU    *               ;ENTRY
            LDA    ROMIN2
            LDA    ROMIN2
            JMP    L2000
;=================================================
; ($B937) Open and read the entire file (modules)
; into memory. We must check the file size
; Input
;  (A)-filetype
;  (Reg4) - ptr to filename
;  ReadDBuf - Mem location to read into
;
; Output
;  C=1 - error
;  (A) - error code
;  C=0 - file loaded successfully
;
OpenNRd     EQU    *               ;ENTRY
            JSR    CkAttrF         ;Check file's attributes
            BCS    LB965           ;Not found
            BNE    LB964           ;Found but wrong type
;
            LDX    #>XA900         ;1024-byte I/O buffer
            LDY    #<XA900
            JSR    OpenDFile
            JSR    CkSizeF
            BCS    LB961           ;too big
;
            LDA    fileEOF
            STA    ReadLen
            LDA    fileEOF+1
            STA    ReadLen+1
            JSR    PRODOS8
            DB     $CA
            DW     ReadPB
            BCS    LB961
            JMP    ClsFile         ;C=0, (A)=0
;
LB961       JSR    ClsFile2        ;(A)=errcode
LB964       SEC
LB965       RTS
;=================================================
; ($B966) Check size of file to be read
; Output
;  (A)=error code
;  C=1 - file too large
;
CkSizeF     EQU    *               ;ENTRY
            JSR    PRODOS8
            DB     $D1
            DW     GeofP
            BCS    LB99A
;
            LDA    fileEOF+2       ;More than 64K
            BNE    LB997           ;File is too large
            INC    ReadLen
            BNE    LB97B
            INC    ReadLen+1
;
LB97B       LDA    fileEOF         ;Is  file's EOF>=ReadLen?
            CMP    ReadLen
            LDA    fileEOF+1
            SBC    ReadLen+1
            PHP
            LDA    ReadLen
            BNE    LB990
            DEC    ReadLen+1
LB990       DEC    ReadLen
            PLP
            BCS    LB997           ;yes
            RTS
LB997       LDA    #$10            ;err code
            SEC
LB99A       RTS
;=================================================
; ($B99B)
; Input
;  (A) - byte value to be converted
; Output
;  (X,A) - Hex Digits
;
Cnv2Hex     EQU    *               ;ENTRY
            PHA                    ;Convert to 2 HEX digits
            LSR                    ;Shift upper nybble
            LSR
            LSR
            LSR
            JSR    LB9A5
            TAX                    ;Save in X
            PLA
LB9A5       AND    #$0F
            ORA    #'0'
            CMP    #'9'+1
            BCC    LB9AF
            ADC    #$06
LB9AF       RTS
;=================================================
; EXEC command
; Ref pg 62 for lots of info on use of EXEC files
;
LB9B0       EQU    *               ;ENTRY
            SET    R4,XBD80
            RTN
;
LB9B4       EQU    *
            BIT    ExecMode        ;exec mode?
            BPL    LB9C3           ;No
            ASL    ExecMode
            LDA    RdExeRN         ;Close the old EXEC file first
            STA    CloseRN
            JSR    ClsFile
LB9C3       LDA    #TXTtype
            JSR    CkAttrF
            BCC    LB9CD           ;Found
;
LB9CA       JMP    PrErrMsg        ;Not Found
;
LB9CD       BNE    LB9CA           ;Wrong type
;
            LDX    #>XAD00         ;1024-byte I/O buf for ProDOS8
            LDY    #<XAD00
            JSR    OpenDFile
;
; Set to read file in new line mode
;
LB9D6       EQU    *
            LDA    OpenRN
            STA    NewLineRN
            STA    RdExeRN
            JSR    PRODOS8
            DB     $C9
            DW     NewLinePB
            BCS    LB9CA
            LDA    #$80            ;Flag we are in exec mode
            STA    ExecMode
            JMP    LB1CB
;=================================================
; Used by the SWAP command
;
LB9EE       DS     4,0             ;TxtBgn,TxtEnd for file1 ;ENTRY
LB9F2       DS     65,SPACE        ;Pathname buf for file1
LBA33       DS     4,0             ;TxtBgn,TxtEnd for file2 ;ENTRY
LBA37       DS     65,SPACE        ;Pathname buf for file2
;
LBA78       DS     8,0             ;SW16 subrtn ret addr stack ;ENTRY
;
FreeMem     DW     $0000           ;# of free mem pages ;ENTRY
;
; ($BA82) Open Parameter Block. Use to open all files.
; The ptr to the pathname and file I/O buffer must be set
;
OpenPB      DB     $03
PathNameP   DW     $0000
IOBufP      DW     $0000           ;1024-byte buffer
OpenRN      DB     $A0             ;ENTRY
;
; $BA88
;
ReadPB      DB     $04
ReadRN      DB     $B0
ReadDBuf    DW     $A0A0           ;Data Buffer ;ENTRY
ReadLen     DW     $A0A0           ;ENTRY
LBA8E       DW     $A0A0           ;ENTRY
;
; $BA90
;
WritePB     DB     $04
WriteRN     DB     $B2             ;ENTRY
            DW     $D5C9           ;ENTRY
            DW     $D0A0           ;ENTRY
            DW     $A0A0
;
; Used by EXEC file
;
RdExecP     DB     $04
RdExeRN     DB     $A0
            DW     InBuf
            DW     255
LBA9E       DW     $A0C0           ;# of chars actually read
;
NewLinePB   DB     $03             ;ENTRY
NewLineRN   DB     $A0             ;ENTRY
            DB     $7F             ;ignore msb
            DB     CR              ;newline char
;
; Use by the CATALOG/CAT cmd
;
LBAA4       DB     $04             ;ENTRY
            DB     $00             ;ENTRY
            DW     XA8D1
            DW     $0000           ;ENTRY
            DW     $0000
;
; Use to skip last 5 bytes of a dir block
;
LBAAC       DB     $04             ;ENTRY
            DB     $00             ;ENTRY
            DW     XA8D1+$20
            DW     $0005           ;# of bytes
            DW     $0000
;
SeofP       DB     $02
LBAB5       DB     $C0             ;ENTRY
LBAB6       DS     3,0             ;ENTRY
;
SPfx1P      DB     $01
            DW     CurrPfxB
;
;
LBABC       DB     $01             ;ENTRY
            DW     CurrPfxB
;
; Set prefix to dir from which EdAsm.System was launched
;
SPfxEdAsm   DB     $01
            DW     EdAsmDir
;
GeofP       DB     $02
GeofRN      DB     $A0
fileEOF     DS     3,$A0
;
GFInfoP     DB     10
GFIPath     DW     $A0A0           ;ENTRY
LBACA       DB     $A0             ;ENTRY
GFIftype    DB     $D6             ;ENTRY
LBACC       DW     $D5C9           ;ENTRY
LBACE       DB     $A0             ;ENTRY
LBACF       DW     $A0A0           ;ENTRY
LBAD1       DW     $A0A0           ;ENTRY
            DW     $CFA0
            DW     $A0FF
            DW     $A0A0
; $DAD9
SFInfoP     DB     $07
LBADA       DW     $A0A0           ;ENTRY
LBADC       DB     $A0             ;ENTRY
LBADD       DB     $A0             ;ENTRY
LBADE       DW     $A0C5           ;ENTRY
            DB     $A0
            DW     $A0A0
LBAE3       DW     $0000           ;ENTRY
            DW     $0000
;
CreateP     DB     $07
LBAE8       DW     $A0A0           ;ENTRY
LBAEA       DB     $C3             ;ENTRY
LBAEB       DB     $04             ;ENTRY
LBAEC       DW     $0000           ;ENTRY
LBAEE       DB     $01             ;ENTRY
            DW     $0000
            DW     $0000
;
DestroyP    DB     $01
LBAF4       DW     $C5A0           ;ENTRY
;
CloseP      DB     $01
CloseRN     DB     $A0             ;ENTRY
;
RenameP     DB     $02
            DW     FileNameB
LBAFB       DW     $0000           ;ENTRY
;
; Online
;
LBAFD       DB     $02             ;ENTRY
LBAFE       DB     $00             ;ENTRY
            DW     XA900
;
LBB01       DB     $02
            DW     $A0AA
            DW     $A0A0
;
ExitFlag    DB     $00             ;Used by the Error Handler
;
EdStr       ASC    'EDASM.ED'
            DB     $00
AsmStr      ASC    'EDASM.ASM'
            DB     $00
BIStr       EQU    *               ;ENTRY
            ASC    'BASIC.SYSTEM'
            DB     $00
;
; The random bytes below are generated by DS statement
;
LBB27       EQU    *               ;ENTRY
            DB     $D1,$A0,$35,$3E,$CF,$D5,$D4,$CE
            DB     $C1,$CD,$45,$21,$51,$A2,$23,$3F
            DB     $CF,$D5,$D4,$D4,$C9,$D4,$CC,$45
            DB     $21
;
; $BB40
;
FileNameB   EQU    *
            DB     $32,$A2,$5A,$3E,$C3,$C1,$D4,$CC
            DB     $CF,$CF,$50,$20,$EF,$A0,$6D,$3F
            DB     $CE,$C5,$D8,$D4,$C3,$C1,$54,$21
            DB     $6D,$A2,$67,$3E,$C3,$C1,$D4,$C5
            DB     $CE,$C4,$C5,$44,$21,$0D,$A1,$72
            DB     $3E,$C3,$C1,$D4,$C1,$D3,$43,$21
            DB     $96,$A3,$88,$3E,$C3,$C1,$D4,$CF
            DB     $D5,$54,$21,$16,$A1,$C4,$42,$D4
;
; $BB80
;
CurrPfxB    EQU    *               ;ENTRY
            DB     $D3,$D4,$CB,$C5,$59,$21,$11,$DD
            DB     $94,$3E,$C3,$C1,$D4,$C6,$CF,$CF
            DB     $54,$21,$2A,$A1,$A0,$3E,$C3,$C1
            DB     $D4,$CF,$D5,$D4,$31,$20,$1E,$A1
            DB     $CF,$3E,$C3,$C1,$D4,$C6,$D8,$C9
            DB     $54,$21,$9E,$A1,$28,$46,$D3,$D0
            DB     $C1,$C3,$C1,$54,$21,$54,$A5,$76
            DB     $45,$C6,$CF,$CF,$D4,$CC,$C7,$48
            DB     $01,$3E,$00,$2A,$41,$CD,$CF,$D6
            DB     $C6,$CF,$CF,$54,$20,$5E,$A1,$17
            DB     $3F,$C3,$C1,$D4,$C6,$CF,$CF,$D4
            DB     $52,$21,$F4,$A1,$4C,$41,$C1,$C3
            DB     $C3,$48,$21,$AE,$A5,$BC,$3F,$D4
            DB     $CF,$D4,$CC,$C2,$CC,$CB,$53,$21
            DB     $2D,$A2,$8C,$40,$C8,$C5,$D8,$C4
            DB     $C5,$43,$21,$0F,$A5,$22,$42,$D5
;
; $BC00 - Buf to save the most recent List cmd
;
SavCmdB     EQU    *
            DB     $D3,$C5,$C4,$C2,$CC,$CB,$53,$21
            DB     $16,$A2,$00,$00,$C6,$D2,$C5,$C5
            DB     $C2,$CC,$CB,$53,$21,$00,$A2,$5F
            DB     $40,$C3,$C1,$D4,$C9,$D4,$CC,$31
            DB     $20,$A3,$A1,$31,$3F,$CF,$D5,$D4
            DB     $C9,$D4,$CC,$C5,$CC,$50,$20,$34
            DB     $A2,$3D,$3F,$CF,$D5,$D4,$C9,$D4
            DB     $CC,$32,$21,$3F,$A2,$49,$3F,$CF
            DB     $D5,$D4,$C9,$D4,$CC,$33,$21,$50
            DB     $A2,$57,$3F,$CF,$D5,$D4,$C9,$D4
            DB     $CC,$C5,$CC,$51,$20,$45,$A2,$5A
            DB     $42,$CF,$D5,$D4,$CE,$CC,$50,$20
            DB     $5C,$A2,$79,$3F,$C3,$D2,$C5,$C1
            DB     $C4,$31,$21,$7E,$A2,$84,$3F,$CE
            DB     $C5,$D8,$D4,$CF,$C6,$46,$20,$7C
            DB     $A2,$00,$00,$C3,$D2,$C5,$C1,$C4
;
; $BC80
;
ExecLineB   EQU    *
            DB     $32,$21,$90,$A2,$57,$4B,$CE,$C5
            DB     $D8,$D4,$C3,$58,$21,$9C,$A2,$9A
            DB     $3F,$D0,$D2,$C5,$C6,$C9,$58,$20
            DB     $9E,$A2,$A5,$3F,$D0,$D2,$C5,$C7
            DB     $C5,$54,$21,$E1,$A2,$B0,$3F,$D0
            DB     $D2,$C5,$D3,$C5,$54,$21,$BD,$A2
            DB     $D3,$3F,$D0,$D2,$C5,$D3,$C5,$D4
            DB     $31,$21,$BE,$A2,$C8,$3F,$D0,$C6
            DB     $D8,$CE,$D5,$CC,$4C,$60,$AF,$A2
            DB     $D5,$40,$D0,$C6,$D8,$D8,$C9,$54
            DB     $60,$BA,$A2,$DF,$3F,$D0,$D2,$C5
            DB     $CD,$CF,$D6,$45,$20,$C2,$A2,$F9
            DB     $3F,$D0,$D2,$C5,$C6,$C5,$CE,$44
            DB     $21,$D3,$A2,$4E,$42,$D3,$D4,$D2
            DB     $D3,$C5,$D4,$D0,$C6,$58,$21,$EF
            DB     $A2,$05,$40,$D0,$D2,$C5,$D3
CIEnd       EQU    *