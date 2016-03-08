Name          : COMMONEQUS.S
End of file   :    6,161
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            CHR    ";"
;=================================================
; Equates used by EdAsm's modules
;
; ASCII keycodes
;
CTRLA       EQU    $01
CTRLB       EQU    $02
CTRLC       EQU    $03
CTRLD       EQU    $04
CTRLE       EQU    $05
CTRLF       EQU    $06
BEL         EQU    $07
BS          EQU    $08
TAB         EQU    $09
FF          EQU    $0C
CR          EQU    $0D
CTRLN       EQU    $0E
CTRLO       EQU    $0F
CTRLQ       EQU    $11
CTRLR       EQU    $12
CTRLS       EQU    $13
CTRLT       EQU    $14
CTRLU       EQU    $15
CTRLV       EQU    $16
CTRLW       EQU    $17
CTRLX       EQU    $18             ;cancel
ESCAPE      EQU    $1B
SPACE       EQU    $20
UNDERSCORE  EQU    $5F
DEL         EQU    $7F
;=================================================
; filetypes
;
TXTtype     EQU    $04
BINtype     EQU    $06
DIRtype     EQU    $0D
RELtype     EQU    $FE
SYStype     EQU    $FF
;=================================================
; Apple ][ Standard Zero page
;
WNDWDTH     EQU    $21
CH          EQU    $24
CV          EQU    $25
BASL        EQU    $28
InvFlg      EQU    $32
Prompt      EQU    $33
CSWL        EQU    $36             ;Output hook
KSWL        EQU    $38             ;Input hook
A1          EQU    $3C
A2          EQU    $3E
A4          EQU    $42
;=================================================
; These zpage locations are referenced by 2 or
; more of EdAsm's modules
;
LoMem       EQU    $0A             ;=$0801
TxtBgn      EQU    $0A             ;Reg5
TxtEnd      EQU    $0E             ;Reg7
HiMem       EQU    $0C             ;=$9900 Not used by EDASM.ASM
StackP      EQU    $49             ;Save area for H/W stack ptr
VideoSlt    EQU    $50             ;=$Cs where s=1-3 (if 80-col video card present)
FileType    EQU    $51             ;filetype
ExecMode    EQU    $53             ;Exec mode
PtrMode     EQU    $54             ;=$80,$00 - Printer ON/OFF
TabChar     EQU    $5F             ;Set by Editor
PrColumn    EQU    $61             ;curr print col
UserTabT    EQU    $68             ;$68-$71 User defined Table table
PrintF      EQU    $73             ;-1=Print Cmd 0=List Cmd
StackP2     EQU    $73             ;Save area for H/W stack ptr on fatal err
SwapMode    EQU    $74             ;Split-buf mode 0-normal,1=buf1,2=buf2
CaseMode    EQU    $75             ;ucase/lcase
CmdDelim    EQU    $78             ;Cmd Delimiter/Separator
TruncF      EQU    $79             ;=$FF-truncate comments
;=================================================
X2000       EQU    $2000           ;Load & Exec addr of SYS Files
LoadAdrEd   EQU    $8900           ;Load Addr of Editor Module
;=================================================
; 1024-byte I/O buffers for ProDOS8
;
XA900       EQU    $A900
XAD00       EQU    $AD00
;=================================================
; Edasm Global Page
; Used to pass parameters btwn EdAsm's
; modules viz Editor, Assembly & Linker
; The EI must be resident all the times
; EdAsm Interpreter's Global Page
; Used to pass parameters btwn EdAsm's
; modules viz Editor, Assembly & Linker
; The EI must be resident all the times
;
XBD00       EQU    $BD00           ;General Purpose 128-byte buffers
XBD80       EQU    $BD80           ; used by Edasm's modules
XBE00       EQU    $BE00           ;$BE00-$BE3F (curr Pathname)
DevCtlS     EQU    $BE40           ;($BE40-$BE61) Init to $C3 if 80-col card present
TabTable    EQU    $BE60           ;$BE60-$BE62
DateTime    EQU    $BE64           ;$BE64-$73
EdAsmDir    EQU    $BE79           ;Where EDASM lives
PrtError    EQU    $BEFC           ;EdAsm Interpreter error message rtn
;=================================================
; Apple ][
;
Stack       EQU    $0100
InBuf       EQU    $0200
TxBuf2      EQU    $0280
SOFTEV      EQU    $03F2           ;RESET vector
PWREDUP     EQU    $03F4
USRADR      EQU    $03F8           ;ctrl-Y vector
;=================================================
; ProDOS 8 Global Page
;
PRODOS8     EQU    $BF00
LASTDEV     EQU    $BF30
BitMap      EQU    $BF58
P8DATE      EQU    $BF90
P8TIME      EQU    $BF92
MACHID      EQU    $BF98
SLTBYT      EQU    $BF99           ;Slot ROM map
CMDADR      EQU    $BF9C           ;last MLI call return address
MINIVERS    EQU    $BFFC           ;minimum interpreter version
IVERSION    EQU    $BFFD           ;interpreter version
;=================================================
; Soft Switches
;
KBD         EQU    $C000
CLR80VID    EQU    $C00C
KBDSTROBE   EQU    $C010
BUTN3       EQU    $C060
BUTN2       EQU    $C063
RDBANK2     EQU    $C080           ;Read only RAM bank 2; no write
ROMIN2      EQU    $C081           ;Read ROM/Write RAM bank 2 (RR)
RDROM2      EQU    $C082           ;Read ROM; no write
LCBANK2     EQU    $C083           ;Read/Write RAM bank 2 (RR)
BASICINT    EQU    $C300
XC30B       EQU    $C30B           ;card identification
XC30C       EQU    $C30C
;
XD000       EQU    $D000           ;LC Bank2 - SW16 or Asm's Print Symbol Table
BASCLD      EQU    $E000           ;AppleSoft ColdStart
;=================================================
; Apple ][ Monitor Entry Points
;
SWEET16     EQU    $F689           ;Original IntegerBASIC ROM entry point
PRNTAX      EQU    $F941
PRBLNK      EQU    $F948
INIT        EQU    $FB2F
BELL1       EQU    $FBDD
VTABZ       EQU    $FC24
HOME        EQU    $FC58
CLREOL      EQU    $FC9C
WAIT        EQU    $FCA8
RDKEY       EQU    $FD0C
RDCHAR      EQU    $FD35
GETLN       EQU    $FD6A           ;input line w/prompt
CROUT       EQU    $FD8E           ;issue carriage return
COUT        EQU    $FDED           ;output char via user's I/O
COUT1       EQU    $FDF0           ;output via video screen
MOVE        EQU    $FE2C
SETNORM     EQU    $FE84
SETKBD      EQU    $FE89
SETVID      EQU    $FE93
PRERR       EQU    $FF2D
MON         EQU    $FF65
MONZ        EQU    $FF69
IRQV        EQU    $FFFE
;=================================================
;
; SW16 registers when using 6502 instructions
;
Reg0        EQU    $00             ;Doubles as the Accumulator
Reg1        EQU    $02
Reg2        EQU    $04
Reg3        EQU    $06
Reg4        EQU    $08
Reg5        EQU    $0A             ;Points @ 1st char of curr edited file
Reg6        EQU    $0C             ;HiMem
Reg7        EQU    $0E             ;Points @ last char of curr edited file
Reg8        EQU    $10
Reg9        EQU    $12
Reg10       EQU    $14
Reg11       EQU    $16
Reg12       EQU    $18             ;Subroutine return stack pointer
Reg13       EQU    $1A             ;Result of a comparison instruction
Reg14       EQU    $1C             ;Status Register
Reg15       EQU    $1E             ;Program Counter
;=================================================
; Sweet16 registers
; These labels are for the EdAsm assembler
; For Merlin8, Rn are pre-defined and
; do not need to be declared.
;
R0          EQU    0
R1          EQU    1
R2          EQU    2
R3          EQU    3
R4          EQU    4
R5          EQU    5
R6          EQU    6
R7          EQU    7
R8          EQU    8
R9          EQU    9
R10         EQU    10
R11         EQU    11
R12         EQU    12              ;Subroutine return stack pointer
R13         EQU    13              ;Result of a comparison instruction
R14         EQU    14              ;Status Register
R15         EQU    15              ;Program Counter
;=================================================
; Lifted from ProDOS v1.7
; xdos parameters:
;
c.pCnt      EQU    $0              ; (count)
c.devNum    EQU    $1              ; (value)
c.refNum    EQU    $1              ; (value)
c.intNum    EQU    $1              ; (value)
c.path      EQU    $1              ;&2 (pointer) 
c.isNewl    EQU    $2              ; (mask)
c.dataBuf   EQU    $2              ;&3 (value)
c.bufAdr    EQU    $2              ;&3 (address)
c.intAdr    EQU    $2              ;&3 (address)
c.mark      EQU    $2              ;->4 (value)
c.eof       EQU    $2              ;->4 (value)
c.attr      EQU    $3              ; (flags) 
c.newl      EQU    $3              ; (character)
c.bufPtr    EQU    $3              ;&4 (pointer)
c.newPath   EQU    $3              ;&4 (pointer)
c.fileId    EQU    $4              ; (value) 
c.reqCnt    EQU    $4              ;&5 (value)
c.blkNum    EQU    $4              ;&5 (address)
c.outRef    EQU    $5
c.auxId     EQU    $5              ;&6 (value) 
c.transCnt  EQU    $6              ;&7 (value)
c.fKind     EQU    $7              ; (value) 
c.date      EQU    $8              ;&9 (value) 
c.outBlk    EQU    $8              ;&9 (count)
c.time      EQU    $a              ;&b (value) 
c.modDate   EQU    $a              ;&b (value)
c.modTime   EQU    $c              ;&d (value)
c.creDate   EQU    $e              ;&f (value)
c.creTime   EQU    $10             ;&11 (value)