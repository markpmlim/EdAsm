Name          : RELOCATOR.S
End of file   :    7,244
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;---------------------------------------------------------;
; EDASM.SYSTEM - loaded into mem at $2000-$2FFE (len $FFF)
; The 1st part of the code is the relocator ($2000-$23FF)
; The 2nd part of the code is the EdAsm Interpreter
; ($2400-2FFE) which is relocated to $B100-$BCFE (len $0BFF).
; The EI is always in memory whether in assembly/edit mode
;---------------------------------------------------------;
            SYS
;
            ORG    $2000
;
L2000       LDX    #$F0
            TXS
            LDX    #255
            LDA    #0
L2007       STA    Stack,X         ;Zero entire stack
            DEX
            BNE    L2007
;
            LDY    #19
            LDA    #$00            ;Mark pages $20-$BF
L2011       STA    BitMap+4,Y      ; as free
            DEY
            BPL    L2011
;
            LDA    #<$2000         ;Starting fr $2000
            STA    TxtBgn+1        ; downto $0800
            LDY    #3
L201D       LDX    #8
L201F       LDA    BitMap,Y        ; scan for the
L2022       LSR
            BCS    L202D           ; first non-free page
            DEC    TxtBgn+1
            DEX
            BNE    L2022
            DEY
            BNE    L201D
;
L202D       LDA    #$01
            STA    TxtBgn          ;=$0801 (normally)
;
            JSR    PRODOS8
            DB     $82             ;Get the date/time
L2035       DW     L2035           ;No parms needed
;
            LDA    ROMIN2          ;Read ROM
            LDA    ROMIN2          ;Write-enabled RAM LC Bank2
            LDA    P8DATE
            ORA    P8DATE+1
            PHP                    ;save Z-bit
L2044       STA    CLR80VID        ;Disable 80-col display mode
            JSR    SETNORM
L204A       JSR    INIT
            JSR    SETVID
            JSR    SETKBD
            JSR    HOME
            PLP
            BNE    L20B6
;
; No clock card
;
            LDY    #$00
            JSR    SendBanr
            LDA    #0
            STA    CH
            JSR    L21DE           ;enter DD
L2065       LDA    #3
            STA    CH
            JSR    L22C1           ;enter MMM
            BCC    L2074
L206E       JSR    L21FB
            JMP    L2065
;
; Year
;
L2074       LDA    #7
            STA    CH
            JSR    L2238           ;enter year digit 1
            BCC    L2084
L207D       JSR    L22AF
            BCC    L2074
            BCS    L206E
;
L2084       JSR    RDKEY
            CMP    #BS+$80
            BNE    L2092
            JSR    L2259
            BCC    L2084
            BCS    L207D
L2092       CMP    #CR+$80
            BEQ    L209E
            LDA    #BEL+$80
            JSR    COUT
            JMP    L2084
;
L209E       LDA    L21CF
            LDX    L21CE
            CPX    #$08
            ROL
            STA    P8DATE+1
            TXA
            ASL
            ASL
            ASL
            ASL
            ASL
            ORA    Day
            STA    P8DATE
;
L20B6       JSR    PRODOS8         ;Get prefix
            DB     $C7
            DW     CurrPfxP
            LDA    CurrPfxB
            BNE    L20E1
;
; No current prefix
;
            LDA    LASTDEV
            STA    OLUnit
            JSR    PRODOS8
            DB     $C5
            DW     OnLineP
;
            LDA    CurrPfxB+1
            AND    #$0F            ;Get len byte of volname
            CLC
            ADC    #2
            STA    CurrPfxB
            TAY
            LDA    #'/'            ;Prepend and append volname
            STA    CurrPfxB+1      ; with a slash
            STA    CurrPfxB,Y
;
; The code below assumes the TxBuf2 area has been
; setup properly by ProDOS8
;
L20E1       LDX    TxBuf2          ;Do we have a trailing /?
            INX
L20E5       DEX
            BEQ    L20FC           ;No trailing /
            LDA    #'/'
            EOR    TxBuf2,X
            ASL
            BNE    L20E5           ;No, keep looking
;
            DEX                    ;Got a trailing /, so remove
            STX    TxBuf2          ; it by just adjusting len byte
;
            JSR    PRODOS8         ;Make this the default prefix
            DB     $C6
            DW     SDefPfxP
            BNE    ShowErr
;
; Get the prefix to Edasm's directory
;
L20FC       JSR    PRODOS8         ;Get prefix
            DB     $C7
            DW     PFX3P
            BNE    ShowErr
            JSR    L2342           ;Backup ProDOS Quit code
;
; Setup to relocate the EdAsm Interpreter
; to its final location @ $B100
;
            LDA    #>L2400         ;EI's load addr
            STA    A1              ;start=$2400
            LDA    #<L2400
            STA    A1+1
            LDA    #$27
            STA    A2              ;end=$2E27
            LDA    #$2E
            STA    A2+1
            LDA    #>EIStart
            STA    A4              ;dest
            LDA    #<EIStart
            STA    A4+1
            LDA    #<EIStart-1     ;Jump to $B100 after MOVE completed
            PHA
            LDA    #>EIStart-1
            PHA
            LDY    #0
            LDA    ROMIN2          ;read ROM
            LDA    ROMIN2          ;write-enabled LC Bank2 RAM
            JMP    MOVE
;=================================================
; Use this to set the default prefix
;
SDefPfxP    DB     $01
            DW     TxBuf2
;
; Use this parameter block to get the current prefix
;
CurrPfxP    DB     $01
            DW     CurrPfxB
;
; EdAsm's Dir is where the 3 files EdAsm.Ed,
; Edasm.Asm and Edasm.System resides
;
PFX3P       DB     $01
            DW     EdAsmDir
;
OnLineP     DB     $02
OLUnit      DB     $60
            DW     CurrPfxB+1
;=================================================
ShowErr     STA    ErrCode
            TSX
            STX    StackP2
            LDX    #$80
L2144       TXS
L2145       STA    CLR80VID
            JSR    SETNORM
            JSR    INIT
            LDA    RDROM2          ;read ROM, write-protect RAM LC Bank2
            JSR    SETKBD
            JSR    SETVID
            JSR    HOME
            JSR    PRERR           ;PRINT "ERR=XX"
            LDA    ErrCode
            JSR    $FDD3           ;unsupported mon entry point
            JMP    MON
;
SendBanr    LDA    Banner,Y
            BPL    L2171
            JSR    COUT
            INY
            JMP    SendBanr
L2171       RTS
;
            MSB    ON
Banner      DB     $8D,$8D,$8D
            ASC    "  PRODOS  EDITOR-ASSEMBLER //"
            DB     $8D,$8D,$8D,$8D,$8D,$8D
            ASC    "ENTER THE DATE AND PRESS RETURN"
            DB     $8D,$8D
            ASC    "DD-MMM-YY"
            DB     0
            MSB    OFF
TensT       DB     00,10,20,30,40,50,60,70,80,90
Day         DB     $00
L21CE       DB     $00
L21CF       DB     $00
L21D0       DB     $00
L21D1       DB     $00
MMM         DS     3,0
;
L21D5       LDA    #BEL+$80
            JSR    COUT
L21DA       LDA    #$00
            STA    CH
L21DE       JSR    RDKEY
            CMP    #'0'+$80
            BCC    L21D5
            CMP    #'3'+1+$80
            BCS    L21D5
            JSR    COUT
            AND    #$0F
            TAX
            LDA    TensT,X
            STA    Day
            STA    L21D0
            JMP    L220D
;
L21FB       LDA    L21D0
            STA    Day
            LDA    #1
            STA    CH
            JMP    L220D           ;enter 2nd digit for DD
;
L2208       LDA    #BEL+$80
            JSR    COUT
L220D       JSR    RDKEY
            CMP    #BS+$80
            BEQ    L21DA
            CMP    #'0'+$80
            BCC    L2208
            CMP    #'9'+1+$80
            BCS    L2208
            JSR    COUT
            AND    #$0F
            CLC
            ADC    Day
            STA    Day
            BEQ    L21D5
            CMP    #31+1           ;at most 31
            BCS    L21D5           ;err
            RTS
; Year
L222F       LDA    #BEL+$80
            JSR    COUT
L2234       LDA    #7
            STA    CH
L2238       JSR    RDKEY
            CMP    #BS+$80
            BEQ    L2289
            CMP    #'0'+$80
            BCC    L222F
            CMP    #'9'+1+$80
            BCS    L222F
            JSR    COUT
            AND    #$0F
            TAX
            LDA    TensT,X
            STA    L21CF
            STA    L21D1
            JMP    L226B
;
L2259       LDA    L21D1
            STA    L21CF
            LDA    #$08
            STA    CH
            JMP    L226B
;
L2266       LDA    #BEL+$80
            JSR    COUT
L226B       JSR    RDKEY
            CMP    #BS+$80
            BEQ    L2234
            CMP    #'0'+$80
            BCC    L2266
            CMP    #'9+1+$80
            BCS    L2266
            JSR    COUT
            AND    #$0F
            CLC
            ADC    L21CF
            STA    L21CF
            BEQ    L222F
            CLC
L2289       RTS
;
L228A       DB     $A0
            MSB    ON
Months      ASC    "JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
            MSB    OFF
;
L22AF       LDA    #5              ;3rd letter of MMM
            STA    CH
            JMP    L22DF
;
L22B6       SEC
            RTS
;
; Month entry
;
L22B8       LDA    #BEL+$80
            JSR    COUT
L22BD       LDA    #3              ;1st letter of MMM
            STA    CH
L22C1       JSR    ToUCase
            CMP    #BS+$80
            BEQ    L22B6
            JSR    PRUCase
            BCS    L22C1
            STA    MMM
L22D0       JSR    ToUCase
            CMP    #BS+$80
            BEQ    L22BD
            JSR    PRUCase
            BCS    L22D0
            STA    MMM+1
L22DF       JSR    ToUCase
            CMP    #BS+$80
            BNE    L22EC
            JSR    COUT
            JMP    L22D0
;
L22EC       JSR    PRUCase
            BCS    L22DF
            STA    MMM+2
;
            LDX    #$00
            STX    L21CE
L22F9       LDY    #$00
            INC    L21CE
            STX    L228A
L2301       LDA    MMM,Y
            CMP    Months,X
            BNE    L2311
            INX
            INY
            CPY    #$03
            BCC    L2301
            BEQ    L2322           ;match
L2311       LDX    L228A
            INX
            INX
            INX
            CPX    #48             ;bug? (should be 36)
            BCC    L22F9
;
            LDA    #3
            STA    CH
            JMP    L22B8           ;re-enter
L2322       CLC
            RTS
;
; Display char (in A) as uppercase letter
;
PRUCase     CMP    #'A'+$80
            BCC    BELL
            CMP    #'Z'+1+$80
            BCS    BELL
            JSR    COUT
            CLC
            RTS
BELL        LDA    #BEL+$80
            JSR    COUT
            SEC
            RTS
;
ToUCase     JSR    RDKEY
            CMP    #$E0            ;should be "a" ($E1)
            BCC    L2341
            AND    #$DF
L2341       RTS
;=================================================
; Move ProDOS Quit code fr LCBank2 to main 48K mem
; first. Save code as EdAsm.Swap
;
L2342       LDA    RDBANK2         ;read and write-protect RAM LC Bank2
            LDA    RDBANK2
            LDA    #>XD000
            STA    A1              ;start=$D000
            LDA    #<XD000
            STA    A1+1
            LDA    #>X3000
            STA    A2              ;dest=$3000
            LDA    #<X3000
            STA    A2+1
;
            LDY    #0
L235A       LDA    (A1),Y
            STA    (A2),Y
            INY
            BNE    L235A
            INC    A1+1
            INC    A2+1
            LDA    A1+1
            CMP    #<XD000+$1000   ;$D000-$DFFF
            BCC    L235A           ;Next mem page
;
            LDA    ROMIN2          ;read ROM
            LDA    ROMIN2          ;write enable LC Bank2 RAM
            JSR    PRODOS8
            DB     $C8
            DW     OpenSwapP
            BEQ    L237A
            RTS
;
L237A       LDA    SwapRN
            STA    WrSwapRN
            STA    ClsSwapRN
            JSR    PRODOS8
            DB     $CB
            DW     WrSwapP
            JSR    PRODOS8
            DB     $CC
            DW     ClsSwapP
            RTS
;=================================================
; These ProDOS parameter blocks are used for EDASM.SWAP
;
X3000       EQU    $3000
X4000       EQU    $4000           ;addr of 1024-byte file buffer
;
OpenSwapP   DB     $03
            DW     SwapFileS
            DW     X4000
SwapRN      DB     $00
;
SwapFileS   STR    'EDASM.SWAP'
;
WrSwapP     DB     $04
WrSwapRN    DB     $B0
            DW     X3000           ;Data buffer
            DW     $1000           ;# of bytes to write
            DW     $0000
;
ClsSwapP    DB     $01
ClsSwapRN   DB     $C2
;=================================================
            STR    '               (c) COPYRIGHT 1983 BY'
            STR    '               JOHN O. ARKLEY'
            STR    '               ALL RIGHTS RESERVED'
;DS \,$EA
            DS     $2400-*,$EA
L2400       EQU    *