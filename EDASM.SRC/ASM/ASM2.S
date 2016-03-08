Name          : ASM2.S
End of file   :   64,420
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            ORG    $7800
            REP    50
; EdAsm Interpreter will transfer control here
;
Assembler   EQU    *               ;ENTRY
ColdStrt    JMP    ExecAsm
;
; Patch the addr @ this offset with $60 (RTS)
; if user wants to use the letters A,X,Y as labels
;
            DW     IsAXY           ;Points to subrtn checking A,X,Y as labels
;
DateStr     ASC    '30-APR-85      22:46'
;
ResetEnt    JSR    GoMon           ;Comes here when Apple RESET key is pressed
;
ExecAsm     JSR    SaveZP
            TSX
            STX    EIStack         ;Save EdAsm Interpreter's H/W stack
            SEI                    ;Disable H/W interrupts
            JSR    SetupVec
            JSR    InitASM
            JSR    DoPass1
            JSR    DoPass2
            JSR    PollKbd
;
; The ProDOS version of EdAsm does not
; support memory resident source file(s).
;
CleanUp     LDA    DskSrcF         ;Assembling a mem resident src file?
            BPL    FlushObj        ;Yes (Never taken)
;
            LDX    FCTIndex
            CPX    #InclFile
            BCC    CleanUp2
            BEQ    CleanUp1
            LDX    #MacFile        ;Close Macro file (if any)
            JSR    ClsFile
;
CleanUp1    LDX    #InclFile       ;Close INCLUDE file (if any)
            JSR    ClsFile
;
CleanUp2    LDX    #ChnFile        ;Close CHAIN file (if any)
            JSR    ClsFile
;
FlushObj    JSR    L99DF           ;Flush obj code
;
ListSymTbl  BIT    CancelF         ;Suppress symbol table listing?
            BPL    ListErrs        ;Yes
;
            LDA    EndSymT+1       ;Need to preserve this
            STA    SavSTE          ; during calcn # of free pages
            JSR    DoPass3         ;Output symbol table etc
            JSR    PollKbd
AbortAsm    LDA    SavSTE
            STA    EndSymT+1       ;Restore
;
ListErrs    LDA    NbrErrs         ;Any errors encountered?
            ORA    NbrErrs+1
            BEQ    TellUser
            JSR    PrSummry        ;Yes
;
TellUser    JSR    PrtEndAsm       ;Tell user assembly process is ending
;
EndAsm      JSR    PrtFF           ;Do a form feed
            BIT    DskListF        ;Listing to file?
            BPL    ExitASM         ;No
            LDX    #LstFile
            JSR    ClsFileX
;
ExitASM     LDX    EIStack
            TXS
            JSR    SaveZP
            JSR    SetupVec
            RTS
            REP    50
;
; Comes here whenever EdAsm.Asm has to do an orderly
; exit as a result of errors which make continuation
; of the assembly process non-feasible
;
; (A)=keycode if PollKbd called prior to
; transfer of control
;
CanclAsm    INC    CancelF         ;Flag we have to stop
            BEQ    ForceAbort
            CMP    #CTRLB          ;This code may not be executed
            BCC    ListSymTbl
            BCS    ExitASM         ;Always
;
ForceAbort  BIT    AbortF          ;Was it user abort?
            BMI    AbortNow        ;Yes
;
            LDA    #BEL            ;Ring, ring
            JSR    VidOut
            JSR    VidOut
            JSR    PrtCR
            BIT    KBDSTROBE
            LDX    #>AbortTxt-ASEndTxt
            JSR    L986A
WaitK1      LDA    KBD             ;Wait for keystroke
            BPL    WaitK1
            BIT    KBDSTROBE
;
AbortNow    JSR    CountErr        ;Increment # of errors
            JMP    CleanUp
            REP    50
;
SetupVec    LDA    SOFTEV
            LDX    ResetEnt+1
            STA    ResetEnt+1
            STX    SOFTEV
            LDA    SOFTEV+1
            LDX    ResetEnt+2
            STA    ResetEnt+2
            STX    SOFTEV+1
            LDA    SOFTEV+1
            EOR    #$A5
            STA    PWREDUP
            RTS
            REP    50
;
; Comes here when Apple // RESET key
; is pressed during an assembly
;
GoMon       LDA    RDROM2
            TSX
            STX    StackP
            LDX    #$80
            TXS
            JMP    MONZ
            REP    50
;
; We are at the end of an assembly session so print
; 1) # of warnings & errors if any
; 2) success if no errs
; 3) total # of lines assembled
; 4) Date
; 5) # of free pages
;
PrtEndAsm   JSR    PutCR
            LDA    #0
            STA    BCDNbr+2
            LDA    NbrWarns
            STA    BCDNbr
            LDA    NbrWarns+1
            STA    BCDNbr+1
            ORA    NbrWarns
            BEQ    PrtErrs
            JSR    PrtDecS         ;Print BCD as dec str
            LDX    #>WarnTxt-ASEndTxt;# of warnings in assembly
            JSR    MsgPrtr
;
PrtErrs     LDA    NbrErrs+1
            STA    BCDNbr+1
            LDA    NbrErrs
            STA    BCDNbr
            ORA    NbrErrs+1
            BEQ    GudAsm          ;No errs
            JSR    PrtDecS
            LDX    #>ASErrTxt-ASEndTxt;# of errors in assembly
            JSR    MsgPrtr
            JMP    PrtCrMsg
;
GudAsm      LDX    #>SuccTxt-ASEndTxt
            JSR    MsgPrtr
PrtCrMsg    LDX    #>CreatTxt-ASEndTxt
            JSR    MsgPrtr
;
            LDX    #0
PrtLoop     LDA    DateStr,X
            JSR    PutC
            INX
            CPX    #$10            ;16-1
            BCC    PrtLoop
;
            JSR    PutCR
            LDX    #>TotLnTxt-ASEndTxt
            JSR    MsgPrtr
            LDA    TotLines
            STA    BCDNbr
            LDA    TotLines+1
            STA    BCDNbr+1
            LDA    TotLines+2
            STA    BCDNbr+2
            JSR    PrtDecS         ;Covert BCD into dec str & print
            JSR    PutCR
            LDX    #>FSPCTxt-ASEndTxt
            JSR    MsgPrtr
;
            LDX    EndSymT+1       ;Mem Page of Top of Symbol Table
            INX
            LDA    #0
            STA    BCDNbr
            STA    BCDNbr+1
            STA    BCDNbr+2
;
; Count # of free mem pages btwn ends of
; Symbol table & Relocation Dictionary.
; The symbol table is build upwards from LoMem while
; the Relocation Dict is build downwards from MemTop.
;
PrtLoop1    CPX    RLDEnd+1
            BEQ    PrtFreeMem
            JSR    L81A3
            INX
            BNE    PrtLoop1
;
PrtFreeMem  JSR    PrtDecS         ;Print dec
            JSR    PutCR
doRTS       RTS
            REP    50
; Message Printer
; Entry:
;  (X)=offset to message
;
MsgPrtr     LDA    ASEndTxt,X
            CMP    #SPACE
            BCC    ChkEndMsg
            JSR    PutC
            INX
            BNE    MsgPrtr
ChkEndMsg   TAX                    ;end of msg?
            BNE    doRTS
            JMP    PutCR           ;yes
            REP    50
;
SummaryStr  STR    'YRAMMUS        RORRE'
;
; Print summary of errors
; ErrTIdx = index into Save Error Info table
;
PrSummry    LDA    #0
            STA    ErrTIdx         ;Index into err table
            JSR    PrtFF           ;Do a Form Feed
            JSR    PutCR
;
            LDX    #$0D
PrtLoop2    LDA    SummaryStr,X
            JSR    PutC
            DEX
            BPL    PrtLoop2
;
; Print out errors encountered
;
PrtAsmErr   LDA    ErrTIdx
            CMP    ErrNbr4
            BCC    PrtErrLin
            RTS
;
PrtErrLin   TAY                    ;Move index into Y-reg
            LDA    ErrInfoT+3,Y
            STA    BCDNbr
            LDA    ErrInfoT+2,Y
            STA    BCDNbr+1        ;line #
            LDA    #0
            STA    BCDNbr+2
            LDA    ErrInfoT+1,Y
            TAX                    ;Index into ErrMsgT
            JSR    PrtErrMsg
            LDA    #'O'            ;'OF '
            JSR    PutC
            LDA    #'F'
            JSR    PutC
            LDA    #SPACE
            JSR    PutC
;
            LDA    ErrInfoT,Y      ;bug? instr should be removed
            LDX    #$06
PrtLoop3    LDA    FileTxt,X
            JSR    PutC
            DEX
            BPL    PrtLoop3
;
            LDA    ErrInfoT,Y      ;file #
            JSR    PrByte
            JSR    PutCR
            INY
            INY
            INY
            INY
            STY    ErrTIdx
            JSR    PollKbd
            BCS    StopPrt         ;Abort
            JMP    PrtAsmErr       ;next
;
StopPrt     PLA                    ;Dump RTS addr
            PLA
            JMP    EndAsm
            REP    50
;
; Error Handler/Reporter
; Register we have an assembler syntax error or warning
; NB. (ErrorF) is reset before a line is assembled
; Ref pg 217 for List of Assembler Errors
; Entry:
;   (X)     = error token
; Ret:
;  (ErrorF) = $80 if error; unchanged if warning
;   (Y)     = unchanged
; Once an error is issued on a line, secondary errors are not
; reported. However, it's possible for the line to be
; flagged with more than 1 warning.
;
RegAsmEW    BIT    ErrorF          ;Has this line been flagged?
            BPL    NewErrWarn      ;No
doRTS1      RTS
;
NewErrWarn  TXA
            LSR                    ;Is err token odd?
            BCC    FlagErr         ;No, considered as an error
;
            SEC                    ;Yes, treat as a warning
            SED
            LDA    #0
            ADC    NbrWarns
            STA    NbrWarns
            LDA    NbrWarns+1
            ADC    #0
            STA    NbrWarns+1
            CLD
            BIT    LstWarns        ;Suppress warnings?
            BPL    doRTS1          ;Yes
;
            JSR    DoAlert         ;Alert user
            JMP    doPause
;
; Flag as an error
;
FlagErr     DEC    ErrorF          ;Is err due to idfer not found during pass2?
            BEQ    SkipIt          ;Yes
            JSR    SaveErrInfo     ;No, save err info for this line
SkipIt      LDA    #$80            ;Flag no more errs will be
            STA    ErrorF          ; reported for curr srcline
            JSR    DoAlert
FlagErrZ    JSR    CountErr        ;Increment # of errors
;
doPause     LDX    #$06            ;(X) used below in delay
            JSR    IsVideo         ;Output thru video?
            BNE    PutCR           ;No
;
DelayLup    LDA    #0
            STA    RDROM2
            JSR    WAIT
            STA    RDBANK2
            DEX
            BNE    DelayLup
;
PutCR       LDA    #CR
            JMP    PutC
            REP    50
;
; Print *****, sound the bell and then print
; an error message
; (X)=error token
; (Y) preserved
; NB:Fall thru to the PrtErrMsg code
;
DoAlert     JSR    PutCR
            TYA                    ;save (Y)
            PHA                    ;on stack
            LDA    WinLeft         ;Make sure any display
            STA    PrtCol          ; is inside our window
;
            LDY    #5
            LDA    #'*'            ;print 5 ;'s
PrtLoop4    JSR    PutC
            DEY
            BNE    PrtLoop4
;
            PLA
            TAY                    ;restore (Y)
            LDA    PrSlot          ;If slot # is 0,
            BEQ    RingBell        ; use std Apple ][ video
            CMP    VidSlot         ;Is 80-col card?
            BEQ    RingBell        ;Yes
;
            BIT    RDROM2
            JSR    BELL1           ;Apple Monitor rtn
            BIT    RDBANK2
            JMP    PrtBlnk
;
RingBell    LDA    #BEL            ;video output
            JSR    PutC
PrtBlnk     LDA    #SPACE
            JSR    PutC
            REP    50
;
; Print Error or Warnings
; ($7A6B)
; Entry:
;  (X)=error token
;  bits
;   7
;  6-1  index into a table of ptrs to Error/Warning Messages
;   0   on=counted as warning, off=counted as error
;
; Range for index $00-$48
;
PrtErrMsg   TXA
            AND    #%01111110      ;Isolate the index
            TAX
            CPX    #>ErrMsgTE-ErrMsgT+1
            BCC    PrtEM1
            BRK
PrtEM1      LDA    ErrMsgT,X
            STA    MsgP
            LDA    ErrMsgT+1,X
            STA    MsgP+1
            TYA
            PHA
;
            LDY    #0
PrtEMLoop   LDA    (MsgP),Y
            CMP    #SPACE
            BCC    L7A8E           ;Skip embedded 0,1,CR
            JSR    PutC
            INY
            BNE    PrtEMLoop
;
L7A8E       LSR                    ;C=0 if a null-terminated line
            PHP                    ;Save Carry for later
            LDA    VidSlot         ;slot #0?
            BNE    SkipIt2         ;No
;
            LDA    #CR
            JSR    MonCOUT         ;Std Apple II 40-col video
            LDA    WinLeft
            STA    PrtCol
SkipIt2     PLP
            PLA
            TAY
;
            LDX    #$0E            ;' ERROR IN LINE'
            BCC    PrtLoop5        ;null-terminated line
            LDX    #$08
PrtLoop5    LDA    InLinTxt-1,X    ;' IN LINE'
            JSR    PutC
            DEX
            BNE    PrtLoop5
            NOP
            JMP    PrtDecS
            REP    50
;
; Increment # of errors
;
CountErr    SEC
            SED
            LDA    #0
            ADC    NbrErrs
            STA    NbrErrs
            LDA    NbrErrs+1
            ADC    #0
            STA    NbrErrs+1
            CLD
            RTS
            REP    50
;
; (Y) & (X) preserved
; Save info for first 8/16 errors encountered
; X=error token
;
SaveErrInfo LDA    VidSlot         ;Is slot #0?
            BNE    NotStd          ;No
            LDA    #8*4            ;std 40-col video
            BNE    Is2Many         ;always
NotStd      LDA    #16*4           ;File/Printer/80-col
Is2Many     CMP    ErrNbr4
            BCC    doRTS2          ;Too many errs
            BEQ    doRTS2
;
; Use table @ $A0B2 for storing error info
;
            TYA
            PHA
            LDY    ErrNbr4         ;multiple of 4
            LDA    FileNbr         ;file #
            STA    ErrInfoT,Y
            TXA                    ;errtoken
            AND    #%01111110      ;Isolate the index
            STA    ErrInfoT+1,Y
            LDA    BCDNbr+1        ;line #
            STA    ErrInfoT+2,Y
            LDA    BCDNbr
            STA    ErrInfoT+3,Y
            INY
            INY
            INY
            INY
            STY    ErrNbr4
            PLA
            TAY
doRTS2      RTS
            REP    50
; Bit table
;
Bit01       DB     $01             ;not used
Bit02       DB     $02
Bit08       DB     $08
Bit10       DB     $10
Bit40       DB     $40
            REP    50
;
; Save zero page locations $60-$F1
;
SaveZP      LDX    #$92
            BIT    LCBANK2         ;2 successive writes
            BIT    LCBANK2
SavLoop     LDA    Z60-1,X
            LDY    SvZPArea-1,X
            STY    Z60-1,X
            STA    SvZPArea-1,X
            DEX
            BNE    SavLoop
            BIT    RDBANK2
            RTS
            REP    50
;
; ($7B13) Init Assembler module
;
InitASM     LDA    #>ColdStrt
            STA    HighMem
            STA    MemTop
            LDA    #<ColdStrt
            STA    HighMem+1
            STA    MemTop+1
;
            LDA    VideoSlt        ;=$Cs - value set by EI
            AND    #%00000011      ;1 or 3
            STA    VidSlot
            BEQ    Not80           ;No 80-col card
            LDA    CSWL
            STA    IOHooks
;
Not80       LDA    #40             ;40-col window
            STA    WinRight
            LDA    #ChnFile
            STA    FCTIndex
;
            LDY    #0              ;Zero all these
            STY    WinLeft
            STY    AbortF
            STY    NbrErrs
            STY    NbrErrs+1
            STY    NbrWarns
            STY    NbrWarns+1
;
            JSR    ZeroLnCnt
            STY    MacroF          ;0=Macros disabled
            STY    ErrNbr4
            STY    ErrorF
            STY    DummyF
            STY    SubTitle        ;Delimiter=0
            STY    SubTtlF
            STY    PageNbr
            STY    PageNbr+1
            STY    PhyPL
            STY    ftypeT+2        ;SRC
            STY    ftypeT+4        ;INCLUDE
            STY    ftypeT+6        ;MACRO
            STY    PrSlot          ;40-col monitor output
            STY    DskListF        ;Memory
            STY    X6502F          ;No Rockwell ops
            DEY                    ;-1
            STY    SW16F           ;SW16 opcodes are valid
            STY    CancelF         ;=$FF
            DEY                    ;-2
            STY    LineCnt
            INY                    ;-1 again
            STY    ListingF        ;LST ON
            LDA    #60
            STA    LogPL
;
; Compute mem locations of various data buffers
;
            LDA    #0
            STA    DskSrcF
            STA    IDskSrcF
            STA    XA074           ;Make sure all these
            STA    XA074+2         ; point @ mem locations
            STA    XA074+4         ; at the  start of a
            STA    XA06A+4         ; mem page ie $xx00
;
            LDA    LoMem+1         ;If (A)=$08 then
            CLC
            ADC    #1              ; reserved 1 mem page below
            STA    XA074+3         ; SRC file data buf=$0900 (SBuf)
            SEC                    ;Reserved 1 mempage below
            ADC    SBufSize
            STA    XA074+5         ; INCL file data buf=$0E00 (IBuf)
            ADC    IBufSize
            STA    XA074+1         ;Start of SymTbl=$1E00
            SEC
            SBC    #1
            STA    XA06A+5         ;=$1D00 Points last mempg of IBuf
;
            LDA    SBufSize
            STA    XA056+3         ;Only hi-byte set i.e. (XA056+2)=?
            LDA    IBufSize
            STA    XA056+5
            STY    GenF            ;=$FF suppress of obj code generation
;
            LDA    #0
            LDX    #6
ZeroLoop    STA    RefNbrT,X
            DEX
            BPL    ZeroLoop
;
            LDY    #64-5           ;".OBJx" - 5 chars
            LDA    #SPACE
BlnkLoop    STA    ObjPNB,Y        ;Fill w/spaces
            DEY
            BPL    BlnkLoop
;
            LDA    #>ChnPNB
            STA    SrcPathP
            LDA    #<ChnPNB
            STA    SrcPathP+1
            JSR    GetSrcPN        ;Get passed src PN
;
            LDY    #63
CpyLoop     LDA    ChnPNB,Y        ; and make a duplicate
            STA    L9EDC,Y
            DEY
            BPL    CpyLoop
;
            LDA    LoMem
            STA    TxtEnd          ;No file in mem
            LDA    LoMem+1
            STA    TxtEnd+1
            LDA    XA074           ;Start of symbol table
            LDY    XA074+1
            STA    StrtSymT        ;=$1E00
            STA    EndSymT
            STY    StrtSymT+1
            STY    EndSymT+1
            JSR    GetObjPN        ;Setup obj filename
            LDA    GenF            ;Suppress generation of obj code?
            CMP    #$FF
            BNE    InitA1          ;No
            LDA    #%10001111      ;Flag it (N=1,V=0)
            STA    GenF
;
InitA1      JSR    PrtSetup
            LDA    MemTop          ;Start w/empty Rel Dict
            STA    RLDEnd
            LDA    MemTop+1
            STA    RLDEnd+1
;
            LDY    #0
            TYA
ZeroLoop1   STA    HeaderT,Y       ;Zero table of header nodes
            INY
            BNE    ZeroLoop1
            RTS
            REP    50
;
; Init Line Counters & set file cnt to 1
; X, Y regs not used
; (A)=0
;
ZeroLnCnt   LDA    #0
            STA    TotLines
            STA    TotLines+1
            STA    TotLines+2
            STA    FileNbr
            INC    FileNbr         ;=1
            BIT    LCBANK2
            BIT    LCBANK2
            STA    BCDNbr
            STA    BCDNbr+1
            STA    BCDNbr+2
            RTS
            REP    50
;
; Open/ReOpen initial SRC file for input
;
OpenSrc1    LDA    DskSrcF         ;Are we assembling a disk src file?
            BMI    CpySrcPN        ;Yes
;
; This code fragment is never executed by ProDOS EdAsm.Asm
;
            LDA    LoMem           ;Point @ BO src file in mem
            STA    SrcP
            LDA    LoMem+1
            STA    SrcP+1
            BNE    InitFlags       ;always
;
CpySrcPN    LDY    #63
CpyLoop1    LDA    L9EDC,Y         ;Get PN fr its saved area
            STA    ChnPNB,Y
            DEY
            BPL    CpyLoop1
;
            LDX    #ChnFile
            JSR    Open4RW         ;Open SRC file for reading
            JSR    L92F0           ;Print file messages
;
; Set defaults
;
InitFlags   LDA    #-1
            STA    LstUnAsm
            STA    LstExpMac
            STA    LstWarns
            STA    LstASym
;
            LDA    #0
            STA    MacroF
            STA    msbF            ;OFF
            STA    LstCyc
            STA    LstGCode
            STA    Lst6Cols
            STA    LstVSym
            STA    ZE8             ;Not used in another part of this module
            STA    CondAsmF
            STA    PC
            STA    PC+1
            STA    ObjPC           ;This will be used as len of code
            STA    ObjPC+1         ; image when output is to REL file
            JSR    ZeroLnCnt       ;Further inits
            INC    BCDNbr          ;=1
            STA    NewF            ;Zero this
;
            LDA    #'0'
            LDY    #3
ZeroLup     STA    DecimalS,Y      ;Line counter
            DEY
            BPL    ZeroLup
            RTS
            REP    50
;
; Copy the SRC pathname passed by EdAsm Interpreter
; using $BD80 buf (only 65 bytes used).
; Since EdAsm uses only disk source files, DskSrcF
; once set will always be $80.
;
GetSrcPN    LDY    #-1
            LDX    #0
            SEC                    ;Flag we are using disk src files
            ROR    DskSrcF         ;=$80
MovLoop     INY
            LDA    AsmParmB,Y      ;Get a char
            BEQ    GoodPN          ;eos
            CMP    #SPACE+1
            BCC    MovLoop         ;Ignore space
            JSR    ToUpper
            STA    ChnPNB+1,X
            INX
            CPY    #63
            BNE    MovLoop
;
            INY                    ;=64
            LDA    AsmParmB,Y
            BEQ    GoodPN          ;Must be null-terminated!
;
ParmErr     LDX    #$14            ;ASM parm err
            JSR    RegAsmEW
            JMP    CanclAsm
;
GoodPN      STY    ChnPNB          ;Set len byte
            INY
            STY    ParmBIdx        ;Index past delimiter
doRTS3      RTS
            REP    50
;
; Get the OBJ pathname (if any)
; Check for suppression of obj code by looking for
; '@' in place of object file name pg 76, 96
;
GetObjPN    LDY    ParmBIdx
            LDA    AsmParmB,Y      ;NB. delimiter is $00
            CMP    #'@'
            BEQ    doRTS3          ;Ret to flag code suppression
            LDX    #%11000000      ;V=1 - Default to Disk store
            STX    GenF            ;N=1 - & suppress objcode generation
            AND    #$FF            ;End of buf?
            BEQ    MkObjPN         ;Yes, no obj pathname passed
;
            LDX    #0
MovLoop1    JSR    ToUpper
            STA    ObjPNB+1,X
            INX
SkipLoop    INY
            LDA    AsmParmB,Y      ;Look for null-terminator
            BEQ    GoodObjPN       ;Got it
            CMP    #SPACE+1
            BCC    SkipLoop        ;Invalid char (skip?)
            CPX    #64
            BCC    MovLoop1
ParmErr2    JMP    ParmErr         ;err
;
GoodObjPN   STY    ParmBIdx        ;Save index
            STX    ObjPNB          ;len byte
            JMP    doRTS4
;
; No OBJ PN was passed so setup default
; object file name using src filename
;
MkObjPN     LDY    ChnPNB          ;len byte
            STY    ObjPNB
CpyLoop2    LDA    ChnPNB,Y
            STA    ObjPNB,Y
            DEY
            BPL    CpyLoop2
;
            LDY    ObjPNB
            CPY    #63
            BCS    ParmErr2        ;err
            CPY    #13+1           ;Unprefixed filename?
            BCC    Add0            ;Yes
;
; Passed a full PN/prefix
;
            LDA    #'/'            ;Look for trailing /
            LDX    #0
ScanLoop    CMP    ObjPNB,Y        ;Do we have one?
            BEQ    L7D12           ;yep
            DEY
            INX
            CPX    #13+1
            BCC    ScanLoop
            BCS    ParmErr2        ;always
;
L7D12       CPX    #0              ;Got a prefix char?
            BEQ    ParmErr2        ;No, err
;
Add0        LDY    ObjPNB          ;Append '.0' to filename
            LDA    #'.'
            INY
            STA    ObjPNB,Y
            LDA    #'0'
            INY
            STA    ObjPNB,Y
            STY    ObjPNB          ;len byte
doRTS4      RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup printing to file/printer
; The DevCtlS is set using the EdAsm Interpreter
;
PrtSetup    LDY    #0
            LDA    DevCtlS,Y       ;Get slot #
            STA    PrSlot          ;Valid value: 1-7
            BNE    ValROM
            RTS
;
ValROM      JSR    Chk4ROM         ;Is there a slot ROM?
            BEQ    IsDevOL         ;Yes
            JMP    ParmErr         ;Err
;
IsDevOL     LDA    PrSlot          ;0000 xSSS
            ASL
            ASL
            ASL
            ASL                    ;xSSS 0000
            AND    #%01110000      ;Specific unit # is
            STA    OLUnit          ; DSSS 0000; D=0 => drive 1
            LDA    #>OLDataB       ;Only 16 bytes used
            STA    OLBufAdr
            LDA    #<OLDataB
            STA    OLBufAdr+1
            JSR    PRODOS8
            DB     $C5
            DW     OnlinePB
            BNE    ChkErr
;
; There is a disk device at this slot
; Listing to a file requires two extra buffers of
; size 1280 bytes (5 mem pages) - pg 80
; (MemTop)=$7800 if no disk file listing
; (MemTop)=$7300 if there is disk file listing
; If macros are used, more mem will be required
;
AdjMem      LDA    #>LstDBuf
            STA    HighMem
            STA    MemTop
            LDA    #<LstDBuf
            STA    HighMem+1
            STA    MemTop+1
            LDA    #<X6E00
            STA    FBufTbl+MacFile+1
            LDA    #$40            ;Flag as listing
            STA    DskListF        ; to a file
            BNE    ParseDCS        ;Proceed to parse rest of DevCtlS
;
; No disk drive @ this slot
; EdAsm may not work correctly w/ProDOS 8 v2.03
; The online call above returns an error code of
; $2F (devoffline) instead of those below.
;
ChkErr      CMP    #$28            ;No device connected
            BEQ    GotPrtr         ;Likely to be a printer
            CMP    #$45            ;Vol not mounted
            BEQ    AdjMem
            CMP    #$27            ;I/O error
            BEQ    AdjMem
            CMP    #$2E            ;Vol switched
            BEQ    AdjMem
            JSR    DOSErrs         ;Don't come back
;
GotPrtr     LDA    PrSlot          ;1-7
            ORA    #$C0            ;$Cs
            STA    CSWL+1
            LDA    #$00
            STA    CSWL
;
; The code below will parse the device control string
;
ParseDCS    LDY    #1              ;On fall thru will skip
ParseLoop   INY                    ;null char @ offset 1
            LDA    DevCtlS,Y
            BEQ    SendCR          ;null-terminated
            CMP    #SPACE
            BEQ    ParseLoop       ;Skip spaces
            CMP    #'L'
            BNE    IsPL
            JSR    Dec2Int         ;Get logical page len
            STA    LogPL
            JMP    ParseLoop
;
IsPL        CMP    #'P'
            BNE    IsFileLst
            JSR    Dec2Int
            STA    PhyPL           ;Physical page len
            JMP    ParseLoop
;
IsFileLst   BIT    DskListF        ;Are we doing a txt file listing?
            BVS    Lst2File        ;Yes
;
; Init printer
; The dev-ctl-string should not exceed 32 chars
;
InitPrtr    STA    RDROM2
            JSR    COUT            ;output via user's I/O hooks
            STA    RDBANK2
            INY
            LDA    DevCtlS,Y
            BNE    InitPrtr
            BEQ    SendCR          ;null-char marks eos
;
; Output listing to file
; Parse dev-ctl string for the name of LST file
;
Lst2File    LDX    #0
ParseLoop2  LDA    DevCtlS,Y       ;max 32 chars
            BEQ    OpnLstFile      ;eos
            CMP    #SPACE
            BEQ    SkipIt3         ;Skip spaces
            STA    LstPNB+1,X      ;name of LST file
            INX
SkipIt3     INY
            BNE    ParseLoop2
;
OpnLstFile  STX    LstPNB          ;Set len byte
            LDA    #TXTtype
            LDX    #LstFile        ;Create new LST file for output
            STA    ftypeT,X
            JSR    Open4RW         ; after killing old LST one
;
            ASL    DskListF        ;=$80
            LDA    #0
            STA    LstDBIdx
            LDX    #LstFile
            LDA    RefNbrT,X
            STA    WrLstRN
;
SendCR      LDA    #CR
            JSR    PutC
            RTS
            REP    50
;
; Look for a 2-byte dec string
; and convert into integer
;
Dec2Int     INY
            LDA    DevCtlS,Y
            EOR    #'0'
            CMP    #9+1
            BCS    ParmErr3
            TAX                    ;index
            INY
            LDA    DevCtlS,Y
            EOR    #'0'
            CMP    #9+1
            BCS    ParmErr3
            ADC    Tens2Tbl,X
            RTS
ParmErr3    JMP    ParmErr
;=================================================
; $7E14
OBJ0TXT     ASC    '.OBJ0'
            REP    50
;
; X=# of chars to print
;
L7E19       LDY    #0
L7E1B       LDA    (Msg2P),Y       ;print txt msg
            JSR    PutC
            INY
            DEX
            BNE    L7E1B
            RTS
            REP    50
;
ToUpper     CMP    #'a'
            BCC    NotAlfa
            CMP    #'z'+1
            BCS    NotAlfa
            AND    #$DF
NotAlfa     RTS
            REP    50
; Create the symbol table
; Source code handling, lexical
; syntactic and semantic analysis
;
DoPass1     LDA    #0
            STA    RelCodeF
            STA    SymNbr          ;# of ENTRY/EXTRN
            STA    PassNbr
            LDA    #BINtype        ;Default obj file type
            STA    ftypeT
            JSR    OpenSrc1        ;Open initial src file
;
; Assemble each src line
; This should be our parser
;
Pass1Lup    JSR    GSrcLin         ;Any more?
            BCC    L7E46           ;Yes
            RTS
;
; Init vars before assembling each src line
;
L7E46       LDY    #0
            LDA    SrcP
            STA    Src2P           ;BO of curr srcline
            LDA    SrcP+1
            STA    Src2P+1         ;Not used in pass 1
            STY    ErrorF          ;0
            JSR    PollKbd         ;Abort?
            BCC    L7E5A
            JMP    CanclAsm        ;Yes
;
L7E5A       BIT    CondAsmF        ;Assembling alt block?
            BMI    L7E62           ;Yes, proceed to scan for alt block
            BVC    ChkCommLin      ;If V=1, then we going to assemble
            ASL    CondAsmF        ; alt block so set flag to $80
;
; The start of the altenate block is indicated by an ELSE
; pseudo opcode in the mnemonic field
; NB. FIN/ELSE directives will set/reset CondAsmF to $00
; so that subsequent src lines will not be ignored
; In other words, src lines will only be asssembled iff
; CondAsmF is set/reset to $00
;
L7E62       JSR    L80F7           ;Do we have FIN/ELSE directive?
            BCS    ChkCommLin      ;Yes
            JMP    L7F04           ;No, ignore curr src line
;
; Assemble curr src line
;
ChkCommLin  LDA    (SrcP),Y        ;Get 1st char
            CMP    #'*'            ;Is it a pure comment line?
            BEQ    L7E74           ;Yes
            CMP    #'              ;'
            BNE    ChkLabel        ;no
L7E74       JMP    L7F04           ;ignore
;
ChkLabel    EOR    #SPACE
            STA    LabelF          ;0 => no label
            BEQ    L7EDD
;
; This part of code checks for an idfer in the LABEL field
; Should be part of Lexer (Static semantic analysis)
;
            JSR    RsvdId          ;Chk for A,X,Y as 1st char of label
            JSR    FindSym
            BCS    NewLabel        ;No such label
            TAX                    ;Sym found but has it been defined?
            BMI    L7E94           ;No
;
            LDX    #$02            ;Duplicate idfer
            JSR    RegAsmEW
            LDA    #$00
            STA    LabelF          ;Flag no label field
            JMP    L7EC8           ;(Y)-indexing lobyte?
;
L7E94       STA    SymFByte        ;Symbol's curr flag byte
            DEY                    ;Index flag byte again
            AND    #entry+fwdrefd  ;0000 1001
            BIT    DummyF          ;Are we in a DSECT?
            BMI    L7E9F           ;Yes
            ORA    #relative
L7E9F       STA    (SymP),Y        ;save modified status of flag byte
            INY
            LDA    PC              ;Value associated w/symbol
            STA    (SymP),Y
            INY
            LDA    PC+1
            STA    (SymP),Y
            JMP    L7EC8
;
; New label
;
NewLabel    LDA    #$00
            STA    SymFByte
            LDX    #relative       
            BIT    DummyF          ;Are we in a DUMMY section?
            BPL    L7EBA           ;No
;
            LDX    #$00            ;abs
L7EBA       STX    RelExprF
            LDA    #$00            ;Initial flag byte to be
            JSR    AddNode         ; stored into Node
            BCC    L7EC8           ;(Y)-indexing hibyte
            LDX    #$0E            ;Invalid identifier
            JSR    RegAsmEW
;
L7EC8       DEY
            DEY                    ;Indexing flag byte of symtbl entry
            TYA
            CLC
            ADC    SymP
            STA    SymFBP          ;Point @ the symbol's flag byte
            LDA    #0
            ADC    SymP+1
            STA    SymFBP+1
;
; This part handles the mnemonic/psuedo opcode field
;
            LDY    #0              ;Start w/1st char
            JSR    L81F0           ;Skip over non-blanks
            BNE    L7EE5           ;Got a CR
;
L7EDD       JSR    NxtField        ;We got at least 1 space so skip over them
            JSR    HndlMnem
            BCC    L7EF0           ;No errs
;
L7EE5       LDX    #$04            ;undefined opcode
            JSR    RegAsmEW
            LDA    #3
            STA    Length
            BNE    L7F01           ;always
;
L7EF0       CMP    #$FF            ;1st flag byte
            BEQ    L7F04           ;Proceed to next line rec
            BIT    ZAB             ;SW16 opcodes?
            BVC    L7EFE           ;No
            BIT    SW16F           ;Are SW16 ops valid?
            BPL    L7EFE
            DEC    SW16F           ;When (SW16F)=0, code gen problems may arise
;
; Looks like the above code which checks for SW16
; validity will come here no matter what.
; To avoid (SW16F) decrementing to 0, use SW16 directive
; to set its value to $01.
;
L7EFE       JSR    GInstLen        ;Determine len of inst
L7F01       JSR    AdvPC           ; so we can adjust PC
;
L7F04       JSR    NextRec         ;Adv to next src line record
            JSR    L81A3           ;Let user know we are doing something
            JMP    Pass1Lup
            REP    50
;
DoPass2     INC    PassNbr         ;Flag we are in 2nd pass
            LDA    #'*'
            STA    RepChar
            LDA    #-1
            STA    ListingF
            JSR    PutCR
            JSR    OpenSrc1        ;Re-open initial src file
            LDA    GenF
            CMP    #$80            ;Write obj code into mem?
            BNE    Pass2Lup        ;No
;
            LDA    CurrORG         ;These 4 inst serves no purpose since
            STA    ObjPC           ; its contents are changed when an
            LDA    CurrORG+1       ; OBJ/ORG directive is declared
            STA    ObjPC+1         ; Renamed as CodeLen if REL file
            ASL    GenF            ;$00 - Remove suspension
;
; Assemble each src line
;
Pass2Lup    JSR    GSrcLin         ;Any more src lines to assembled?
            BCC    L7F33
            RTS
;
; Init before each line is scanned/parsed
;
L7F33       LDY    #-1
            STY    ZAB             ;=$FF
            INY                    ;=0
            STY    Length
            STY    ErrorF
            STY    LstCodeF
            STY    NumCycles
            LDA    SrcP
            STA    Src2P           ;Save a copy of ptr
            LDA    SrcP+1
            STA    Src2P+1         ; to curr srcline
;
            BIT    CondAsmF        ;Assembling alt block?
            BMI    L7F50           ;Yes, proceed to scan for alt blk
            BVC    L7F57           ;If V=1, then we will be assembling
            ASL    CondAsmF        ; alt block so set flag to $80
;
L7F50       LSR    ZAB             ;Clear msb (=$7F)
            JSR    L80F7           ;Do we have a FIN/ELSE?
            BCC    L7F77           :No, skip assembling src line
;
; Assemble curr src line
; Should be the lexical analyser/scanner
;
L7F57       LDA    (SrcP),Y        ;Pure comment line?
            CMP    #'*'
            BEQ    L7F77
            CMP    #'              ;'
            BEQ    L7F77           ;Yes, ignore curr src line
;
; Ignore the label field and go directly to
; the mnemonic field
;
            JSR    L81F0           ;Skip over non-blanks
            BNE    L7F6E           ;Got a cr
            JSR    NxtField        ;Skip over 1 or more blanks
            JSR    HndlMnem
            BCC    L7F7A
;
L7F6E       LDX    #$04            ;undefined opcode
            JSR    RegAsmEW
L7F73       LDX    #3
            STX    Length
L7F77       JMP    L806F
;
L7F7A       STA    ZAB             ;1st flag byte after mnem/directive byte
            BIT    Bit80           ;Directives?
            BEQ    CodeGen         ;No
            CMP    #$83            ;1000 0011
            BNE    L7F88
            JMP    L807A           ;Skip listing & storing generated code
;
L7F88       CMP    #$81            ;1000 0001
            BNE    L7F77
            STA    LstCodeF        ;$81 - these control directives
            LDA    ValExpr         ; have expr result field which
            STA    ERfield         ; is printed to right of PC field
            LDA    ValExpr+1
            STA    ERfield+1
            JMP    L806F           ;list code, store generated code
;
Bit80       DB     $80
;
; Prepare to generate code
;
CodeGen     JSR    GInstLen        ;Determine instr's len
            LDA    #$27            ;0010 0111
            STA    LstCodeF
            LDX    #0
            LDA    ModWrdL
            BIT    Bit40           ;sw16 opcode?
            BEQ    L7FCB           ;No
            LDA    SW16F
            BNE    L7FB5
            LDX    #$42+1          ;odd-warning
            JSR    RegAsmEW        ;sw16 opcode
;
; This part is for SW16 ops
;
            LDX    #$00
L7FB5       LDA    SubTIdx
            TAY
            LDA    OpcodeT,Y       ;Get SW opcode
L7FBB       CMP    #$10            ;Non-reg ops?
            BCC    GenNow          ;Yes
;
            JSR    IsSW16Reg
            BNE    L7F73           ;No
            LDA    OpcodeT,Y       ;Get sw16 reg opcode
            ORA    ValExpr         ;=Rn
            BNE    GenNow          ;always
;
; This part of the code is for 6502 ops and is used
; by the Code Generator to compute the index to the
; actual opcode within the OpcodeTable
; NB: Highly dependent on the 3 bytes following
; a mnemonic entry & arrangement data in the various
; tables like AModTbl, OpcodeT etc. See comments
; b4 MnemTbl for more info
; (A)=1st flag byte after a mnenmonic entry
;
L7FCB       AND    #%00000101      ;zp,Y/JMP/JSR/(zp)
            ORA    ModWrdH
            BEQ    L7FED           ;single byte ops (A)=0
            LDA    LenTIdx         ;Index into inst len table
            BPL    L7FD6           ;always!
L7FD5       BRK
L7FD6       CMP    #9              ;0-8 (first 9 modes of AModTbl)
            BCC    L7FED
            CMP    #12             ;(abs,X)
            BNE    L7FE5
            JSR    Is65C02         ;Are 65C02 opcodes allowed?
            BCS    L8002           ;No
            BCC    L7FE7
L7FE5       BCS    L7FD5           ;CRASHED!
;
; On fall thru, (A)=9-11 => (abs), acc, zp,Y addr modes
;
L7FE7       AND    #%00000011      ;(A) -> 1-3
            BNE    L7FED
;
            LDA    #2              ;JMP (abs,X)
;
; Single byte & branch ops don't have sub-tables
; Instead the (SubTIdx) is just the index into
; the opcode table. For these ops, (A) must be
; to 0
;
L7FED       CLC
            ADC    SubTIdx         ;Calc the index into opcode table
            TAY
            LDA    CycTimes,Y
            STA    NumCycles
            LDA    OpcodeT,Y       ;get opcode
            BIT    X6502F          ;R 65C02 ops allowed?
            BMI    GenNow          ;Yes
;
            JSR    IsC02Op         ;Is the opcode valid?
            BCC    GenNow          ;Yes
;
L8002       LDX    #$48            ;65C02 addr mode/opcode
            JSR    RegAsmEW
            JMP    L7F73
;
; Code Generation
; Relocation Dictionary entries are created for
; 1) all 6502 opcodes except branch & single byte ops
; 2) DFB,DDB,DW pseudo ops
; 3) SW16 pseudo ops
;
GenNow      STA    GMC,X           ;X=0 -> save opcode
            INX
            STX    GMCIdx
            LDA    ModWrdL
            BIT    Bit08           ;branch instr?
            BNE    L8038           ;Yes
;
            TXA                    ;X=1 on fall thru
            CMP    Length          ;Single byte ops?
            BCS    L8025           ;Yes
            LDA    ValExpr
            STA    GMC,X
            INX
            LDA    ValExpr+1
            STA    GMC,X
            INX                    ;unnecessary inst
;
L8025       LDX    Length
            DEX
            BEQ    L806F           ;Single byte ops
            LDA    RelExprF        ;Is expr's val abs?
            BEQ    L806F           ;Yes
;
            LDA    #1              ;offset
            LDY    #0              ;Little Endian (Reverse)
            JSR    AddRLDEnt       ;Make an RLD entry
            JMP    L806F
;
; Branch instructions
;
L8038       LDA    ValExpr         ;Branch target addr to
            STA    ERfield         ; be printed to right of
            LDA    ValExpr+1       ; branch object code
            STA    ERfield+1
            LDA    LstCodeF
            ORA    #$80
            STA    LstCodeF
            JSR    CalcDisp
;
            LDX    GMCIdx
            LDA    ModWrdL
            AND    #$10            ;BRL/BSL?
            TAY
            BNE    L8063           ;yes
;
; 6502/C02
;
            LDA    ValExpr         ;(Y)=0
            BPL    L8058           ;Forward branch
            INC    ValExpr+1       ;=0
L8058       LDA    ValExpr+1       ;(ValExpr) has displacement byte
            BEQ    L8063
            LDX    #$26            ;branch range err
            JSR    RegAsmEW
;
            LDX    GMCIdx
L8063       LDA    ValExpr
            STA    GMC,X
            TYA                    ;6502 branch instr?
            BEQ    L806F           ;Yes
            INX
            LDA    ValExpr+1       ;SW16 BSL/BRL
            STA    GMC,X
;
L806F       JSR    PrtAsmLn
            JSR    StorGMC
            LDA    Length
            JSR    AdvPC
;
L807A       JSR    PollKbd
            BCS    L8088
            JSR    NextRec
            JSR    L81A3
            JMP    Pass2Lup        ;Assemble next srcline
L8088       JMP    CanclAsm
            REP    50
;
; Chk if instruction is to be printed
; C=0 - Yes
; C=1 - No
;
RVLsting    CLC
            LDA    ErrorF          ;Was an error reported for this srcline?
            BNE    doRTS5          ;Yes
            BIT    CondAsmF        ;Has this line been assembled?
            BPL    L8098           ;Yes
            BIT    LstUnAsm        ;Print unasm src block?
            BPL    L80A4           ;No
L8098       BIT    MacroF          ;Is line a result of mac exp?
            BPL    L80A0           ;No
            BIT    LstExpMac       ;List such lines?
            BPL    L80A4           ;No
L80A0       BIT    ListingF        ;Is listing ON?
            BMI    doRTS5          ;Yes
L80A4       SEC
doRTS5      RTS
            REP    50
;
; Print Assembled Line
;
PrtAsmLn    JSR    RVLsting
            BCS    doRTS6          ;No
            JSR    ListCode        ;Print generated code
            JSR    LstSrcLn        ;Print src stmt
doRTS6      RTS
            REP    50
;
; Store generated machine code
;
StorGMC     LDY    Length          ;# of bytes
            BEQ    doRTS7
;
            LDY    #0
L80B8       LDA    GMC,Y
            BIT    GenF            ;Is code generation suppressed?
            BMI    doRTS7          ;Yes
            BVS    L80C5           ;Write to disk
            STA    (ObjPC),Y       ;Write to mem
            BVC    L80C8           ;Always
L80C5       JSR    Wr1Byte
L80C8       INY
            CPY    Length
            BNE    L80B8           ;Next byte
;
            BIT    GenF            ;Did we do a mem store?
            BVS    doRTS7          ;No, a disk store
            TYA
            JSR    AdvObjPC
doRTS7      RTS
            REP    50
;
; ($80D6) (A)=byte to store in mem/disk
;
StorByt     BIT    GenF            ;Suppress code generation?
            BMI    doRTS8          ;Yes
            BVS    L80F1           ;Write to Disk
            LDY    #0
            STA    (ObjPC),Y
            INC    ObjPC
            BNE    L80E6
            INC    ObjPC+1
;
L80E6       LDA    ObjPC           ;Are we out of mem?
            CMP    HighMem
            LDA    ObjPC+1
            SBC    HighMem+1
            BCS    L80F4           ;Yes
doRTS8      RTS
;
L80F1       JMP    Wr1Byte
;
L80F4       JMP    L8282           ;err
            REP    50
;
; ($80F7) Do we have a FIN/ELSE statement?
; Scan curr line for conditional block directives FIN/ELSE
; C=0 - no
; C=1 - yes
; (SrcP) & Y-reg preserved
;
L80F7       STY    SavIndY         ;Index into field of src line
            LDA    SrcP
            PHA
            LDA    SrcP+1
            PHA
            JSR    L81F0           ;Look ahead for a space
            BNE    L812D           ;None found
;
            JSR    SkipSpcs        ;Skip until non-blank
            JSR    AdvSrcP         ;Now pointing @ pseudo code field
;
            LDX    #3              ;Y=0
L810C       JSR    ChrGot
            CMP    FINTxt,Y
            BNE    L811A
            INY
            DEX
            BNE    L810C
            BEQ    L812A           ;Got a hit
;
L811A       LDY    #0
            LDX    #4
L811E       JSR    ChrGot
            CMP    ELSETxt,Y
            BNE    L812D
            INY
            DEX
            BNE    L811E
L812A       SEC                    ;got a hit
            BCS    L812E           ;always
;
L812D       CLC
L812E       PLA
            STA    SrcP+1
            PLA
            STA    SrcP
            LDY    SavIndY
            RTS
;
FINTxt      ASC    'FIN'
ELSETxt     ASC    'ELSE'
            REP    50
; Add an entry to the relocation entry dictionary table
; Entry:
; (CodeLen) - zeroed whenever the initial srcfile is read
; A=offset
; X=1,2; 1 - 8-bits, 2 - 16-bits
; Y=order of bytes 0=DW(low-hi), 1=DDB(hi-low)
; On 6502, normal order is lower 8 bits of a 16-bit
; value is stored in 1st byte and upper 8-bits in 2nd
; byte (pg 103). However, according to page 229,
; normal order is DDB.
; The Relocation Dictionary is build downwards from
; high mem towards the End of Symbol Table
; The initial start of the RLD is @ MemTop
; & is build downwards towards LoMem
; Each entry is 4 bytes
;
AddRLDEnt   BIT    RelCodeF        ;Gen REL code?
            BMI    L8143           ;yes
            RTS
;
L8143       PHA
            LDA    RLDEnd          ;Chk if there is enough mem
            SEC
            SBC    #4              ; for 1 RLD entry (4 bytes)
            STA    RLDEnd
            LDA    RLDEnd+1
            SBC    #0
            STA    RLDEnd+1
;
            LDA    EndSymT
            CMP    RLDEnd
            LDA    EndSymT+1
            SBC    RLDEnd+1
            BCC    L8163
            LDX    #$12            ;Sym/RLD table full!
            JSR    RegAsmEW
            JMP    CanclAsm
;
L8163       DEX                    ;Do we have a 2-byte operand?
            TXA                    ;NB. Acc=0 on fall thru.
            BNE    L8170           ;Yes
;
            LDX    Ret816F         ;Are we using hi-8 bits?
            DEX
            BMI    L8178           ;No, lo-8 bits with (A)=$00
            LDA    #$40            ;Yes
            BNE    L8178           ;always
;
; Bits of the RLD flag byte are defined as follows:
; $80 - sizeof relocatable field
; $40 - Upper/Lower 8 if a 16-bit value
; $20 - Normal/reversed 2-byte field
; $10 - Field is EXTRN 16-bit reference
; $01 - "Not EO RLD" (Clear => EO RLD)
;
L8170       TYA                    ;Y=0 or 1
            ASL
            ASL
            ASL
            ASL
            ASL                    ;-> $00(Reverse) or $20 (Normal)
            ORA    #$80            ;Sizeof relocatable field=2 bytes
;
L8178       ORA    #$01            ;Flag 'Not EO RLD' => more entries
            LDY    GblAbsF
            BEQ    L8180           ;ZDEF/ZREF
            ORA    #$10            ;EXTRN 16-bit reference
;
; RLD entries are build downwards from high mem
;
L8180       LDY    #3
            STA    (RLDEnd),Y      ;Set RLD flagbyte
            PLA                    ;Restore offset
            CLC
            ADC    CodeLen         ;Calc the offset in image
            DEY                    ;Y=2
            STA    (RLDEnd),Y
            LDA    #0
            ADC    CodeLen+1
            DEY                    ;Y=1
            STA    (RLDEnd),Y
            DEY                    ;Y=0
;
; Set 4-th byte of an RLD entry. First we check if the symbol refers
; to an 8-bit or 16-bit address. If it's a 16-bit address
; then 4-th byte takes a valid value which is an ESD number.
;
            LDA    GblAbsF         ;ZDEF/ZREF?
            BNE    L81A0           ;No => DEF/EXTRN (A)=ESD #
;
; The operand refers to an 8-bit value. Check if
; #<addr16 or #>addr16. If the former, return a 0
; else return the low 8-bit value of the 16-bit
; address in 4-th byte of the RLD entry.
;
            LDA    #0
            LDX    Ret816F         ;-1,0,1
            DEX
            BMI    L81A0           ;It's #<addr16 (low)
            LDA    Lower8          ;Lower 8 bits of 16-bit value
L81A0       STA    (RLDEnd),Y
            RTS
            REP    50
;
; Incr line #s, show user we have assembled
; a chunk of code by printing a dot
;
L81A3       BIT    NewF            ;Assembling new file?
            BPL    L81AF           ;No
;
            LDA    #0
            STA    BCDNbr          ;line # for new file
            STA    BCDNbr+1
            STA    NewF
;
L81AF       SED
            CLC
            LDA    TotLines
            ADC    #1
            STA    TotLines
            BCC    L81C7
            LDA    TotLines+1
            ADC    #0
            STA    TotLines+1
            BCC    L81C7
            LDA    TotLines+2
            ADC    #0
            STA    TotLines+2
;
L81C7       CLC
            LDA    BCDNbr
            ADC    #1
            STA    BCDNbr
            BCC    L81E4
            LDA    BCDNbr+1
            ADC    #0
            STA    BCDNbr+1
;
            CLD
            LDA    PassNbr
            BEQ    L81DF
            BIT    ListingF        ;listing ON?
            BMI    L81E4           ;yes
;
L81DF       LDA    #'.'+$80        ;show a dot
            JSR    VidOut
L81E4       CLD
doRTS9      RTS
;=================================================
; ($81E6) Skip Blanks
; Ret:
; Z=1 blank
; Z=0 non-blank
; (A)=char
; (Y)=index
;
SkipSpcs    LDA    (SrcP),Y
            CMP    #SPACE
            BNE    doRTS9          ;Return
            INY
            BNE    SkipSpcs        ;skip blanks
;
; On fall thru, search starts fr 2nd char of field
;
L81EF       INY
L81F0       LDA    (SrcP),Y
            CMP    #SPACE
            BEQ    doRTS9          ;Got a blank (Z=1) & ret
            CMP    #CR
            BNE    L81EF
            LDY    #0              ;Index 1st char of field
            LDA    #CR             ;Got CR (Z=0) & ret
            RTS
            REP    50
;
; ($81FF) Ret Z=1 of space/CR
; White space chars are <sp> and CR for ProDOS
;
WhiteSpc    LDA    (SrcP),Y
            CMP    #SPACE
            BEQ    doRet
            CMP    #CR
doRet       RTS
            REP    50
;
; This subrtn is part of Scanner
; There are 2 entry points viz ChrGet and ChrGot
; On entry:
;   (Y)    = index into the src line
;   (SrcP) = Pointing somewhere within source line
; Ret:
; (A) - char (converted to uppercase if alphabetic)
; C=1 if char is non-alphabetic
; C=0 if char is alphabetic (A-Z, a-z)
; Z=1 if char is numeric digit (0-9)
; Z=0 if char is non-numeric
; V=1 if char is hexdec digit (0-9, A-F, a-f)
; V=0 if char is non-hexdec
; (X) - unchanged
; (Y) - incr by 1 if 1st entry point else unchanged
;
ChrGet      INY
ChrGot      LDA    (SrcP),Y        ;Get char fr src line
            STY    ZPSaveY         ;Save (Y) temporarily
            TAY                    ;Use char as an index as well as saving it in (Y)
            BPL    L8211           ;Must be std ASCII or
;
            BRK                    ;else crash
;
L8211       LDA    CharMap1,Y      ;Get flag byte
            PHA                    ;Save for later use
            TYA                    ;Get back char
            LDY    ZPSaveY         ;restore Y
            PLP                    ;Now set up Status reg - neat
            BPL    doRet2          ;If (A)=$61-$7A (a-z)
            AND    #$DF            ; convert to upper case
doRet2      RTS
            REP    50
;
; This subrtn is part of Scanner
; Same logic as above except CharMap2 is used
; Entry:
;  (Y) = index into src line
; Ret:
;  (A)=char (uppercase if alphabetic)
;  C=0 - alphanumeric char
;  C=1 - non-alphanumeric char
;  V=0 - non-hexdec char
;  V=1 - hexdec char
;  (X) - unchanged
;
ChrGet2     INY
ChrGot2     LDA    (SrcP),Y
            STY    ZPSaveY
            TAY
            BPL    L8227
;
            BRK                    ;source file must be std ASCII
;
L8227       LDA    CharMap2,Y      ;Get the bit flags
            PHA
            TYA
            LDY    ZPSaveY
            PLP                    ; and pop into Status reg
            BPL    doRet3
            AND    #$DF
doRet3      RTS
            REP    50
;
; On entry
; (Y)=index into src line
; Ret:
; (Y)=0
; src ptr pointing @ 1st char of the field
; (X) - unchanged
;
NxtField    LDA    (SrcP),Y
            CMP    #SPACE
            BNE    L823D
            INY
            BNE    NxtField
;
L823D       CLC
            TYA
            ADC    SrcP
            STA    SrcP
            LDA    #0
            TAY                    ;(Y)=0
            ADC    SrcP+1
            STA    SrcP+1
            RTS
            REP    50
;
; Set SrcP to beginning of next assembly src line
; Source Lines are terminated with a CR
; (X)-unchanged
; Ret with (Y)=0 & src ptr pointing @ 1st char of line
;
NextRec     LDY    #0
L824D       LDA    (SrcP),Y
            INY                    ;NB: skip past char
            CMP    #CR             ; b4 comparision
            BNE    L824D
;
; On fall thru, Y=# to advance
;
AdvSrcP     CLC
            TYA
            ADC    SrcP
            STA    SrcP
            LDA    #0
            TAY                    ;=0
            ADC    SrcP+1
            STA    SrcP+1
            RTS
            REP    50
;
; A=# to advance
;
AdvPC       CLC
            ADC    PC
            STA    PC
            BCC    doRet4
            INC    PC+1
doRet4      RTS
            REP    50
;
; A=# to advance
;
AdvObjPC    CLC
            ADC    ObjPC           ;code buf
            STA    ObjPC
            BCC    L8275
            INC    ObjPC+1
L8275       JMP    L828A
            REP    50
;
; Not referenced
;
L8278       LDA    MemTop
            CMP    ObjPC
            LDA    MemTop+1
            SBC    ObjPC+1
            BCC    L828A
;
L8282       LDX    #$36            ;Obj buf overflow
            JSR    RegAsmEW
            JMP    CanclAsm
;
L828A       LDA    ObjPC           ;Should not be >= HiMem
            CMP    HighMem         ; which was passed by Editor
            LDA    ObjPC+1
            SBC    HighMem+1
            BCS    L8282
            RTS
;=================================================
; ($8295)
; This subrtn is called periodically within a loop
; to check if user wants
;   1) to stop the assembly - Abort Mode
;   2) a pause during a listing - Pause Mode
;   3) turn listing on/off
;   4) to shift listing left/right for 40-col display
; Ret:
;   C=1 if ctrl-C pressed
;
PollKbd     LDA    KBD
            BMI    L829C
L829A       CLC
            RTS
;
L829C       STA    KBDSTROBE
            CMP    #CTRLC+$80
            BNE    L82A7
            DEC    AbortF          ;Pending
            SEC
            RTS
;
L82A7       LDX    PassNbr         ;doing pass 1?
            BEQ    L829A           ;Yes
            CMP    #BS+$80
            BNE    L82B9
;
; EdAsm.ASM allows an 80-col listing to be viewed on a 40-col video screen
; Move the 40-col window one column to left edge of the 80-col listing
;
            LDA    WinLeft
            BEQ    L829A
L82B3       DEC    WinLeft
            DEC    WinRight
            BNE    L829A           ;always
;
L82B9       CMP    #CTRLU+$80      ;RArrow
            BNE    L82C9
;
; Move the 40-col window one column to right edge of the 80-col listing
;
L82BD       INC    WinLeft
            INC    WinRight
            LDA    WinLeft
            CMP    #40
            BCS    L82B3
            BCC    L829A           ;always
;
L82C9       CMP    #SPACE+$80
            BEQ    WaitK3
            CMP    #CTRLO+$80
            BNE    L82D6
            SEC
            ROR    ListingF        ;Turn on listing
            CLC
            RTS
;
L82D6       CMP    #CTRLN+$80
            BNE    L829A
            LSR    ListingF        ;Turn off listing
            CLC
            RTS
;
WaitK3      LDA    KBD             ;Get another keypress
            BPL    WaitK3          ; before continuing
            CLC
            RTS
;=================================================
Wait4CR     BIT    KBDSTROBE
            JSR    PrtCR
            LDX    #>ContTxt-ASEndTxt
            JSR    L986A
WaitK4      LDA    KBD
            BPL    WaitK4
            BIT    KBDSTROBE
            CMP    #CR+$80
            BNE    WaitK4
            JSR    PrtCR
            RTS
;=================================================
; Compute relative addr of a branch op
; Ret:
;   Val=Val-PC-Len
;
CalcDisp    SEC
            LDA    ValExpr
            SBC    Length
            TAX
            LDA    ValExpr+1
            SBC    #0
;
            TAY
            TXA
            SEC
            SBC    PC
            STA    ValExpr
            TYA
            SBC    PC+1
            STA    ValExpr+1
            RTS
;=================================================
; (A) = opcode
; Check if (A) is NCR 65C02 opcode
; C=1 - yes
; (X)-unchanged
;
IsC02Op     LDY    #0
L8319       CMP    L8327,Y
            BCC    doRet5
            BEQ    doRet5
            INY
            CPY    #$12
            BCC    L8319
            CLC
doRet5      RTS
; Rockwell opcodes
L8327       DB     $04,$0C,$14,$1A,$1C,$34,$3C,$3A,$5A
            DB     $64,$74,$7A,$80,$89,$9C,$9E,$DA,$FA
;=================================================
; Process mnemonic/pseudo opcode field
; Ret
; $AB) - 1st flag byte if not a directive
;      - may be changed to $83 if data directives
;      - $80 if macro invocation
; (A)=($AB)
; C=0 - succ
; C=1 - fail
;
HndlMnem    LDA    #$80
            STA    ZAB
            JSR    ChrGot
            BCC    L8348           ;alphabetic char
            CMP    #'.'            ;If a DOT directive
            BNE    L83AC
            LDA    #'A'-1          ; use ASCII @ in place of dot
L8348       SEC
            SBC    #'A'-1
            ASL
            TAX
            LDA    Tbl1stLet,X
            STA    MnemP
            LDA    Tbl1stLet+1,X
            BEQ    L839C           ;No such opcode/directive w/this 1st letter
            STA    MnemP+1
L8359       JSR    ChrGot          ;Note:msb of char=0
            EOR    (MnemP),Y       ;Effectively comparing 7 bits
            ASL                    ;C=1 if last char of opcode was compared
            BNE    L837E           ;No hit
L8361       INY                    ;Z=1 => 7 bits comparison above matched
            BCC    L8359           ;Continue to cmp next char
;
; On fall thru, if C=1 then that was last char/byte of
; mnemonic entry & we have got a match
;
            JSR    WhiteSpc        ;sp/cr?
            BNE    L8386           ;no
            LDA    (MnemP),Y       ;Get 1st flag byte
            STA    ZAB
            BPL    L837C           ;Not a directive
;
; This part of the code handles directives by doing a jump via RTS
; (ZAB) has the directive's only flag byte which may be modified
; by the directive handler
;
            STY    SavIndY         ;Save index into Mnemonics table
            INY
            LDA    (MnemP),Y       ;Get RTS addr-1 (hibyte)
            PHA
            INY
            LDA    (MnemP),Y
            PHA                    ;lobyte
            LDY    SavIndY         ;Restore index
            RTS
L837C       CLC                    ;6502/SW16 opcode
            RTS
;
L837E       LDA    (MnemP),Y       ;Skip rest of entry
            BMI    L8385           ;Last byte of entry has msb=1
            INY
            BNE    L837E
;
L8385       INY
L8386       SEC                    ;Add 3 more bytes
            INY
            INY
            TYA
            ADC    MnemP           ; to skip
            STA    MnemP
            BCC    L8392
            INC    MnemP+1
;
L8392       LDY    #0              ;Try next entry with
            JSR    ChrGot
            EOR    (MnemP),Y
            ASL
            BEQ    L8361           ; the same first letter
;
; Not mnemonics/pseudo code/directive
; Assume it's a macro invocation
;
L839C       LDA    MacroF          ;Are macros allowed?
            BEQ    L83AC           ;No
            BMI    L83A4           ;Invocation fr a macro defn file -> err
            BPL    L83AE           ;No, so it's ok
;
L83A4       LDX    #$18            ;Macro nesting
L83A6       JSR    RegAsmEW
            JMP    DrtvDone
L83AC       SEC                    ;Flag it's an err
            RTS
;
L83AE       BIT    DskSrcF         ;Are we assembling fr disk?
            BPL    L83A4           ;No
            JSR    L9DF8           ;Incr line #?
            JSR    LD3B4           ;Save ptr to next src line
            LDX    #MacFile
            JSR    L9D51           ;Save curr line # of src line
            JSR    SetPNBuf        ;Use macro PN buf
            LDA    MacroPNB        ;Len of maclib prefix
            STA    MacPNLen
            BEQ    L83CD           ;No prefix was declared
;
            JSR    L83F4           ;Form fullpathname of macro defn file
            JMP    L83D0
;
L83CD       JSR    GetPNStr        ;Get macro defn filename into MacroPNB buf
L83D0       CMP    #SPACE+1        ;Is it a space/cr?
            BCC    L83DD           ;Yes
;
            LDA    MacPNLen
            STA    MacroPNB        ;Reset the len maclib prefix
            LDX    #$34
            BNE    L83A6           ;Invalid delimiter error
;
L83DD       JSR    AdvSrcP         ;Point @ BO string parmlist
            LDX    #$40
            STX    MacroF          ;Flag a macro had been invoked
            LDX    FCTIndex
            JSR    Open4RW         ;Open Macro defn file for reading
            LDA    MacPNLen
            STA    MacroPNB        ;Set back to maclib name (neat trick)
            JSR    L841A           ;Parsed passed STR parms
            JMP    DrtvDone
;=================================================
; Append macro name to MacroLib subdir/prefix
; to create a full pathname to macro defn file
;
L83F4       LDX    MacroPNB        ;Get len byte of maclib prefix
            LDY    #0              ;Starting fr 1st char of filename
L83F9       JSR    WhiteSpc        ;Get a char fr src line
            BEQ    L8416           ;sp/cr?
            JSR    ToUpper
            CMP    #SPACE
            BCS    L8408
L8405       JMP    L92D6           ;error
;
L8408       INX
            STA    MacroPNB,X
            INY
            CPX    #64
            BCC    L83F9
            JSR    WhiteSpc
            BNE    L8405           ;If not cr/space, too many
L8416       STX    MacroPNB        ;Set len byte
            RTS
;=================================================
; String parameters in the operand field of the
; asm statement containing the macro name are parsed
; and stored into a 128-byte buf. To pass a comma,
; use $2C or $AC.
; Pg 115
; C=0 parsing successful
;
L841A       LDA    #0
            STA    MParmCnt        ;# of string parms passed
            LDX    #127
            LDA    #0
L8422       STA    MacStrBuf,X     ;zero buf
            DEX
            BPL    L8422
;
            LDY    #0
            JSR    NxtField        ;Point @ operand field
            JSR    WhiteSpc
            BEQ    doRet6          ;sp/cr
;
L8432       LDA    (SrcP),Y        ;Get char fr passed string parm
            CMP    #CR
            BEQ    L8446           ;done
            CMP    #','            ;If not a delimiter,
            BNE    L8440           ; just copy it into our buf
            LDA    #0              ;Replace w/0 as delimiter
            INC    MParmCnt
L8440       STA    MacStrBuf,Y
            INY
            BNE    L8432           ;Next char
;
L8446       LDA    #0              ;Place 0 as last delimiter
            STA    MacStrBuf,Y
            INC    MParmCnt
            LDA    MParmCnt
            CMP    #10
            BCC    doRet6          ;Any # of str parms can be passed
            LDA    #9              ; but only 9 will be processed
            STA    MParmCnt
doRet6      RTS
;=================================================
; ($8458) We must determine the address mode of opcode
; Ret:
; Length of instruction opcode
;=================================================
GInstLen    STA    ModWrdL         ;1st flag byte
            INY
            LDA    (MnemP),Y       ;2nd flag byte - addr mode bits
            STA    ModWrdH         ; of this mnemonic
            INY
            LDA    (MnemP),Y
            STA    SubTIdx         ;Index into sub-table of opcode table
            DEY
            DEY                    ;Moveback to 1st flag byte
            JSR    NxtField        ;Point @ operand field
;
            LDA    #0
            STA    LenTIdx
            STA    ValExpr         ;val of operand if any
            STA    ValExpr+1
;
            LDA    ModWrdL
            BIT    ModWrdL
            BMI    L84CE           ;Directives/SET
            BIT    Bit20
            BNE    L84D4           ;Implied
            BIT    Bit08
            BNE    L84D9           ;Branch opcodes
;
; There are now thirteen X6502 addr modes to consider
;
            JSR    GAdrMod         ;Get an index to addr mode table
            BCS    L84FE           ;error
;
; Checks the returned/parsed addr mode against permitted modes
;
ChkAMod     STA    LenTIdx         ;=0-12
            TAX
            LDA    AModTbl,X       ;Get the parsed addr mode
;
            CPX    #8
            BCC    L849B
;
; When (X)=8-12, the addressing modes are:
; (zp), (abs), acc, zp,Y & (abs,X)
;
            AND    ModWrdL         ;1st flag byte
            AND    #%00000111      ;Retain only these bits
            CMP    AModTbl,X       ;Is addr mode valid?
            BEQ    L8502           ;Yes
            BNE    L849F           ;=> Further checks
;
; X=0-7 The bits of ModWrdH (2nd flag byte) are completely defined
;
L849B       BIT    ModWrdH         ;Is the returned mode valid?
            BNE    L8502           ;Yes
;
L849F       CPX    #11             ;Was mode parsed as zp,Y?
            BNE    L84A7           ;No
            LDA    #5              ;Force the mode as
            BNE    ChkAMod         ; abs,Y (for LDA/STA)
;
L84A7       CPX    #1              ;Was mode parsed as zp?
            BNE    L84B5           ;nope
            LDA    ModWrdL
            AND    #%00010000      ;JMP/JSR?
            BEQ    BadMode         ;No
            LDA    #0              ;Allow for JMP/JSR zp but
            BEQ    ChkAMod         ; convert 'em to JMP/JSR abs (always)
;
L84B5       CPX    #8              ;Was mode parsed as (zp)?
            BNE    BadMode         ;No
            LDA    ModWrdL
            AND    #%00010000      ;JMP?
            BEQ    BadMode         ;No
            LDA    #9
            BNE    ChkAMod         ;Convert to JMP (abs) (always)
;
BadMode     LDX    #$1C            ;addr mode error
            JSR    RegAsmEW
            LDA    #$00
            STA    LenTIdx         ;Assume abs mode addressing
            BEQ    L84FE           ;always
;
L84CE       BVS    L8513           ;=> SET directive
            LDA    #$00            ;zero len
            BEQ    L8511           ; for directives
;---
L84D4       LDA    #1              ;Single byte opcodes
            BNE    L8511           ;always
;
Bit20       DB     $20
;
;--- Branch opcodes (both 65C02/SW16)
;
L84D9       LDA    #$00            ;There are no sub-tables for such
            STA    LenTIdx         ; opcodes so set this index to 0
            LDX    #2              ;len of instr
            LDA    ModWrdL
            AND    #$10            ;BSL/BRL?
            BEQ    L84E6           ;No
            INX                    ;=3
L84E6       STX    Length
            JSR    EvalExpr
            LDA    PassNbr
            BEQ    L8513
            BCC    L8513
            LDA    NxtToken
            CMP    #$34+$80        ;Invalid delimiter
            BNE    L84FE
            TAX
            JSR    RegAsmEW
            JMP    L8513
;
L84FE       LDA    #3              ;len of instruction
            BNE    L8511           ;always
; X=0-12
L8502       LDA    ModWrdL
            BIT    Bit40           ;sw16?
            BEQ    L850E           ;no
            LDA    L851F,X         ;Get instr len
            BNE    L8511           ;always
;
L850E       LDA    InstLenT,X      ;Get instr len
L8511       STA    Length
L8513       LDA    Length
            RTS
            REP    50
;
; (X)=index into addr mode table
; Not only this, it can be used to index an opcode within
; a sub-table of opcodes (eg ADCOps) by adding it to SubTIdx
; This table is highly dependent on the meaning of the
; bits of the 2 mnemonic flag bytes
;
InstLenT    DB     $03             ;abs
            DB     $02             ;zp
            DB     $02             ;#
            DB     $02             ;zp,X
            DB     $03             ;abs,X
            DB     $03             ;abs,Y
            DB     $02             ;(zp),Y
            DB     $02             ;(zp,X)
            DB     $02             ;(zp)
;
; This sub-table is used by SW16 opcodes
;
L851F       DB     $03             ;(abs) - CPIM
            DB     $01             ;acc - SW16 Reg ops
            DB     $02             ;zp,Y
            DB     $03             ;(abs,X)
;
; bit flags used to check the validity of
; the parsed addressing mode
;
AModTbl     DB     $01             ;abs
            DB     $02             ;zp
            DB     $04             ;imm
            DB     $08             ;zp,X
            DB     $10             ;abs,X
            DB     $20             ;abs,Y
            DB     $40             ;(zp),y
            DB     $80             ;(zp,X)
            DB     $03             ;(zp)
;
            DB     $01             ;(abs)
            DB     $02             ;acc
            DB     $04             ;zp,Y
            DB     $01             ;(abs,X)
;=================================================
L8530       LDX    #$34            ;invalid delimiter
            JSR    RegAsmEW
            SEC
            RTS
            REP    50
;
; This subrtn will parse the addressing mode of the
; operand of a 6502 mnemonic/SW16 psuedo opcode
; Ret
;  (A)=index (0-12) use to get addr mode fr a table
;  C=0 - succ
;  C=1 - syntax error
;
; To trace this rtn, re-assemble the code by doing
; an ORG $5800 for the tables and code @ $D000 (ASM1.S)
; Under the EI interpreter, xload EDASM.ASM2,A$5800
; xload bugbyter,a$1000
; Enter MONitor and type 1000G
;
GAdrMod     LDX    #0              ;X=index into the 2 tables
            LDY    #0              ;Position @ start of operand
L853B       JSR    ChrGot          ;Y=index into operand text
            ORA    #$80
            CMP    AModTkns,X
            BEQ    L855E           ;Got a hit
;
            LDA    AModTkns,X      ;Get a token
            BPL    L8570           ;Not a char
;
            CMP    #SPACE+$80
            BNE    L8554
;
; Token is $A0
;
            LDA    #CR             ;Is char a cr?
            CMP    (SrcP),Y
            BEQ    L8563           ;Yes, eol
;
; On fall thru, if token is $A0 and CR not found
;
L8554       LDA    AModCmds,X
            BEQ    L855E           ;=> next token & src char
            BMI    L8583           ;Error token
            TAX                    ;Index to next token fr $D7D7 table to be
            BNE    L853B           ; used to cmp against SAME char of src code
;
; No fall thru here
; Proceed to get next token of $D7D7 table
; and next char of src to be compared
;
L855E       INX                    ;next token
            INY                    ;next src char
            JMP    L853B
;
; Got a CR
;
L8563       INX                    ;Prepare to look at next token
            DEY                    ;Index prev src char
            LDA    AModTkns,X
            BEQ    L856C           ;$A0+cr followed by $00
            BPL    L858B           ;$A0+cr followed by +ve byte value (always)
;
L856C       LDX    #$0A            ;expr syntax err- never reported! (LDA #$0A)
            BNE    L8583           ;always - bug?
;
L8570       BNE    L858B           ;token > 0
;
; Got a $00 token
;
            STX    SavIndX         ;Save X
            JSR    EvalExpr
            LDX    SavIndX
            BCC    L8554           ;No errs during evaluation
            LDA    NxtToken
            AND    #$7F
            CMP    #$34            ;Invalid delimiter
            BNE    L8589
;
; (A) = error token
;
L8583       TAX                    ;(X) overwritten! Is it a bug?
            PHA                    ;Save error token
            JSR    RegAsmEW
            PLA
L8589       SEC
            RTS
;
L858B       LSR                    ;If odd then
            BCC    L8590
            CLC                    ; ret to caller w/mod2 which
            RTS                    ; is an index to Adr Mode Table
;
L8590       ASL                    ;Even, get back token first
            JSR    L8598           ;Now, execute helper function
            BCC    L855E           ;Loop back to process next src char
            BCS    L8554           ;Go get index to next token
            REP    50
;
; Calls help subroutines (functions).
; Only 3 defined so far.
; Entry
;   (A)=2,4,6 - index into subrtn table
;
; The helper functions with return the required values
; primarily the C bit
;
L8598       STX    SavIndX
            TAX                    ;Token is an index
            CPX    #7              ;Only 3 subrtns currently
            BCC    L85A0
            BRK
;
L85A0       LDA    L85AE-1,X       ;Prepare for JMP
            PHA
            LDA    L85AE-2,X       ;lobyte
            PHA
            JSR    ChrGot          ;Get curr char
L85AB       LDX    SavIndX
            RTS                    ;Do the JMP now
;
L85AE       DW     IsZPMod-1
            DW     IsAccMod-1
            DW     Is65C02-1
            REP    50
;
; Checks if expr is a 8-bit or 16-bit value
; For addressing modes involving zp
; Ret:
;  C=0 - Yes
;  C=1 - No
;
IsZPMod     LDA    ExprAccF
            AND    #%11101111      ;Clear EXTeRNal symbol bit
            ORA    ValExpr+1       ;Is hi-byte of expr zero?
            BEQ    L85CF           ;Yes => 8-bit
            LDA    ExprAccF
            AND    #%00010000      ;Is EXTeRNal symbol bit set?
            BEQ    L85C6           ;No
            LDA    Ret816F         ;EXTRN but is lo-byte being returned?
            BEQ    L85C8           ;Yes
L85C6       SEC                    ;16-bit
            RTS
;
L85C8       LDX    #$44+1          ;odd-warning
            JSR    RegAsmEW        ; (EXTRN used as ZXTRN)
            LDX    SavIndX
L85CF       DEY                    ;Move back
            CLC
            RTS
            REP    50
;
; Check a single 'A' in the operand field
; i.e. checking for accumulator mode
; Entry:
; (A)=char to check
; Ret:
;   C=0 - Yes
;   C=1 - No
;
IsAccMod    CMP    #'A'
            BNE    L85DD
            INY                    ;Look 1 char ahead
            JSR    WhiteSpc        ;Is the next char sp/cr?
            BEQ    L85CF           ;Yes, we have a single 'A' in operand field
            DEY                    ;No, just move back
L85DD       SEC
            RTS
            REP    50
;
; Check if 65C02 opcodes are valid
; Only Status reg is changed
; Ret:
; C=0 - Yes
; C=1 - No
; NB. If X6502F off, LDA (ZP) is still considered
; valid. It is equivalent to LDA ZP
;
Is65C02     BIT    X6502F          ;Are X6502 opcodes allowed?
            BMI    L85CF           ;Yes
            BPL    L85DD           ;always
            REP    50
;
; Evaluate expressions. No check for numeric overflow
; Support for +,-,;,/ and bitwise AND ^, OR |,EOR !
; Ref pg 89 for Expression Syntax adopted for Assembler
;
; Expression := [byteopr] Term [opr Term]...]
; byteopr   := >, <
;
; Meaning of:
; ExprAccF - Expression's accumulated flag bits
; NxtToken - Use to chk for eo expr(sp/cr), comma, )
;            Error if -ve
; SavSEF   - prev subexpr's RelExprF
; RelExprF - non-zero if subexpr is evaluated fr a relocatable addr
;          - zero, it's fr an abs addr
; Ret
; (A)=
; C=0 - no errors parsing
; C=1 - err during eval
;
; NB. If relocatable code is generated, only +,- can be used
;
EvalExpr    LDA    #$00
            STA    RelExprF        ;Assume expr's val is absolute not relative
            STA    ExprAccF
            STA    NxtToken
            STA    GblAbsF         ;Assume ZDEF/ZREF
            JSR    SkipSpcs
;
; Check for the presence of the byte operators
; Set (Ret816F)
; (-1) - 16-bits; 0 - low 8-bits, 1 - hi 8-bits
;
            LDA    #-1             ;Default is to ret a 16-bit value
            STA    Ret816F
            LDA    (SrcP),Y
            CMP    #'<'            ;EDASM not MERLIN!
            BNE    L8601
            INY
            INC    Ret816F         ;=0
            BEQ    L8606           ;Proceed to set to 1
L8601       CMP    #'>'
            BNE    L8608
            INY
L8606       INC    Ret816F         ;0-lobyte, 1-hibyte
;
L8608       CMP    #'-'            ;unary ops
            BEQ    L8610
            CMP    #'+'
            BNE    L8618           ;Get on with it
;
L8610       LDA    #0
            STA    ValExpr         ;Returned value
            STA    ValExpr+1
            BEQ    L8628           ;always
;
L8618       JSR    EvalTerm        ;The leading term is treated differently
            LDA    NxtToken        ;Err?
            BMI    L869C           ;Yes
;
            LDA    Accum
            STA    ValExpr         ;Partial result
            LDA    Accum+1
            STA    ValExpr+1
L8627       INY                    ;Eval [opr term]
L8628       LDA    (SrcP),Y
            LDX    #6
L862C       CMP    Operators,X
            BEQ    L8636
            DEX
            BPL    L862C           ;Chk next operator
            BMI    L8662           ;No hit
;
L8636       CPX    #2              ;+/-?
            BCC    L864E           ;Yes
;
; Perform additional checks for the operators
; /,;,&,^,| which cannot operate on rel expr/sub-expr
;
            LDA    RelExprF        ;Is it a relative subexpr?
            BEQ    L864E           ;No, abs
            LDA    PassNbr
            BEQ    L864E
            BIT    RelCodeF        ;REL code output?
            BPL    L864E           ;No, BIN
L8646       LDX    #$08            ;rel exprn op
            JSR    L87FB
            JMP    L869C
;
L864E       BIT    RelCodeF
            BPL    L865C           ;BIN
            BIT    Ret816F         ;Are we returning a 16-bit value?
            BMI    L865C           ;Yes
            LDA    #$10            ;Was an EXTeRNal symbol used
            BIT    ExprAccF        ; during evaln?
            BNE    L8646           ;Yes
L865C       JSR    EvalSExpr       ;Eval new sub expr
            JMP    L8627           ;Next [opr term]
;
L8662       LDX    Ret816F         ;-1,0,1
            BMI    L8674           ;Return 16-bit value
            BEQ    L8670           ;Return val of lobyte
;
            LDA    ValExpr         ;Save lobyte
            STA    Lower8          ; here and
            LDA    ValExpr+1       ; return val of hibyte
            STA    ValExpr         ; by storing it here
L8670       LDA    #0
            STA    ValExpr+1
;
L8674       JSR    GNToken         ;Chk for comma, ) and cr/space
            ORA    NxtToken        ;In case of err
            STA    NxtToken
L867B       LDA    NxtToken
            DEY                     ;Index prev char
            CMP    #$80            ;C=1 if err
            RTS
            REP    50
;
; We are going to process a new subexpression
; after the operator
; X=0-6
;
EvalSExpr   LDA    RelExprF
            STA    SavSEF          ;Save it
            LDA    #$00            ;Assume absolute value
            STA    RelExprF
            LDA    L888E,X         ;Get JMP addr-1 hibyte
            PHA
            LDA    L8895,X         ;lo byte
            PHA
            INY
            JSR    EvalTerm
            LDA    NxtToken
            BNE    L869A
            RTS                    ;Combine the 2 subexprs
;
L869A       PLA                    ;Dump JMP addr
            PLA
L869C       LDY    #0
            DB     $24
L869F       INY
            JSR    ChrGot2         ;alphanumeric char?
            BCC    L869F           ;Yes, skip
            JSR    GNToken         ;Is it cr/space,comma,)
            BNE    L869F           ;No
            BEQ    L867B           ;always
            REP    50
;
; Entry:
;  (A)=char to check
; Ret:
; Z=1, (A)=0 if space/cr (white space)
;      (A)=1 if char is ,
;      (A)=2 if char is )
; Z=0, (A)=err token
; (Y)-unchanged
;
GNToken     JSR    WhiteSpc
            PHP                    ;Save Z bit
            TAX                    ;Save char in X-reg
            LDA    #$00
            PLP                    ;Was is a cr/space?
            BEQ    doRet7          ;Yes
            LDA    #$01
            CPX    #','
            BEQ    doRet7
            LDA    #$02
            CPX    #')'
            BEQ    doRet7
            LDA    #$34+$80        ;err token
doRet7      RTS
            REP    50
;
; Process a term where
;   Term := Constant, Identifier
; If a term is an idfer, look up its value
; Ret:
;  (Y)=index src line?
;  (Accum)= Term's 16-bit value
; NB. Y-reg seems to have a dual purpose. To index the
; src line and to index an entry of the symbol table
; Its returned value must be monitored and adjust correctly
; Todo: Need to check this more closely.
;
EvalTerm    JSR    AdvSrcP         ;On ret, (Y)=0
            STY    Accum
            STY    Accum+1
            JSR    ChrGot          ;Get 1st char
            BCC    L8716           ;Alphabetic char => idfer
            BEQ    L86D6           ;Numeric char
            JMP    L8781           ;Not alphanumeric
;
; Decimal constant
;
L86D6       LDA    (SrcP),Y        ;Get numeric char
            SEC
            SBC    #'0'            ;$30-$39 -> 0-9
            CLC
            ADC    Accum
            STA    Accum
            BCC    L86E6
            INC    Accum+1
            BEQ    L870E           ;Overflow
L86E6       JSR    ChrGet          ;Look 1 char ahead
            BEQ    Mul10           ;If numeric, continue
            DEY                    ;else move back and ret
            RTS
;
; The next char is numeric so the
; accumulated result must be x 10
; before we loop back to process it
; Logic: 2R x 2 x 2 + 2R = 10R
;
Mul10       JSR    Mul2            ;2R
            BCS    L870E
            LDA    Accum+1         ;save temporarily
            PHA
            LDA    Accum
            JSR    Mul2            ;2R x 2
            BCS    L870D
            JSR    Mul2            ;4R x 2
            BCS    L870D
            ADC    Accum           ;+ 2R
            STA    Accum
            PLA
            ADC    Accum+1
            STA    Accum+1
            BCC    L86D6           ;Loop back to process the next char
            PHA                    ;overflow
L870D       PLA
L870E       JMP    L87F9           ;error
;=
Mul2        ASL    Accum
            ROL    Accum+1
            RTS
;
; Identifier
;
L8716       JSR    RsvdId          ;Chk single A,X,Y
            BCC    L871C
            RTS                    ;error
;
L871C       JSR    FindSym
            BCS    L8757           ;Idfer's not in symbol table
            TAX                    ;Save idfer's flag byte
            CLC
            BMI    L8757           ;Idfer's undefined
            AND    #external       ;0001 0000 Is it declared as an EXTeRNal?
            BIT    ExprAccF
            BEQ    L8734           ;Ifder is not EXTeRNal
            STX    SavFByt         ;Save flag byte here while
            LDX    #$40            ; we report Duplicate EXT/ENT
            JSR    RegAsmEW
            LDX    SavFByt         ;Get flagbyte back
L8734       TXA                    ; into (A)
L8735       AND    #external+fwdrefd;0001 0001
            ORA    ExprAccF
            STA    ExprAccF
            TXA                    ;Test old flag byte
            AND    #external       ;0001 0000
            BEQ    L874A           ;No, not EXTeRNal
            LDA    PassNbr
            BEQ    L8754
            LDA    (SymP),Y        ;LoByte of value field
            STA    GblAbsF         ;0=>ZDEF/ZREF
            BNE    L8754           ;Its ENTRY/EXTRN
;
L874A       LDA    (SymP),Y        ;Get value of symbolic idfer
            STA    Accum           ; & ret it here
            INY
            LDA    (SymP),Y
            STA    Accum+1
            DEY
L8754       DEY
            DEY
            RTS
;
; Identifer is undefined
; (A)-symbol's flag byte
; (Y)-indexing symbol's value field if symbol was found
; (Y)=0 if symbol not found
;
L8757       LDX    PassNbr
            BEQ    L876F           ;Its pass 1
            BIT    Bit02           ;Is No-such-label error?
            BEQ    L8764           ;No
            INC    ErrorF          ;Flag as err since its pass 2
            BNE    L8769           ;=1
L8764       ORA    #nosuchlabel    ;0000 0010
            DEY
            STA    (SymP),Y        ;Modified flag byte
L8769       LDX    #$00            ;Undefined idfer
            DEY                    ;what's this for?
            JMP    L87FB           ;Go report it
;
L876F       TAX                    ;(A)=flag byte
            LDA    #fwdrefd        ;0000 0001
            BCC    L8735           ;Symbol was found but undefined
            ORA    ExprAccF        ;Symbol not found
            STA    ExprAccF
            LDA    #undefined+fwdrefd;symbol's flag byte
            JSR    AddNode
            DEY
            DEY
            DEY                    ;Indexing last char of symbolicname?
            RTS
;
; 1st char is non-alphanumeric
; Is it an ASCII char const?
;
L8781       CMP    #'''            ;Opening single quote?
            BNE    L879E           ;No
            STY    Accum+1         ;Zero the hibyte
            INY
            LDA    (SrcP),Y        ;Get char within quotes
            CMP    #CR
            BNE    L8791
            JMP    L880F
;
L8791       ORA    msbF
            STA    Accum
            INY
            LDA    (SrcP),Y        ;Look for a
            CMP    #$27            ; closing single quote
            BEQ    doRet8          ;Got one
            DEY                    ;Move back
doRet8      RTS
;
; Program counter reference
;
L879E       CMP    #'*'            ;Do we have a star?
            BNE    L87AF
;
            LDA    #relative       ;Flag symbol's val is relative
            STA    RelExprF        ; & not an absolute addr
            LDA    PC
            STA    Accum
            LDA    PC+1
            STA    Accum+1
            RTS
;
; Checks for bin/octal/hexdec const
;
L87AF       CMP    #'%'            ;binary
            BNE    L87B9
            LDA    #'2'
            LDX    #$01
            BNE    L87CB           ;always
;
L87B9       CMP    #'$'            ;hexdec
            BNE    L87C3
            LDA    #$C0            ;'@'+$80
            LDX    #$04
            BNE    L87CB           ;always
;
L87C3       CMP    #'@'            ;octal
            BNE    L880F
            LDA    #'8'
            LDX    #$03
L87CB       STA    RadixCh         ;=$32,$38,$C0
            STX    BitsDig         ;=$01,$03,$04
;
; Conversion starts here
;
L87CF       JSR    ChrGet          ;Is next char hexdec?
            BVC    L8808           ;No
            CMP    #'9'+1
            BCC    L87DA
            SBC    #$07            ;'A'-'F' ($41-$46) -> $3A-$3F
L87DA       CMP    RadixCh
            BCS    L8808           ;Not valid
            LDX    BitsDig
            CPX    #$03
            BEQ    L87E8           ;Octal
            BCS    L87E9           ;HexDec
;
            ASL                    ;binary
            ASL
L87E8       ASL
L87E9       ASL
            ASL
            ASL
            ASL
;
; binary x000 0000, octal xxx0 0000 hex xxxx 0000
; (X)=# of shifts (% - 1, @ - 3, $ - 4)
;
L87ED       ASL
            ROL    Accum
            ROL    Accum+1
            BCS    L87F9           ;Overflow
            DEX
            BNE    L87ED
            BEQ    L87CF           ;Process another numeral
;
L87F9       LDX    #$06            ;overflow
L87FB       STX    NxtToken
            JSR    RegAsmEW
            LDA    #$80
            ORA    NxtToken
            STA    NxtToken        ;$80,$86,$88,$8A
            NOP
            RTS
;
L8808       DEY                    ;Move back
            JSR    ChrGot
            BVC    L880F           ;Char is not hexdec
            RTS
;
L880F       LDX    #$0A            ;expr syntax
            JMP    L87FB
;
; ; operator
;
ExprMUL     JSR    AdvSrcP
            STY    ValExpr+2       ;zero these
            STY    ValExpr+3
            LDY    #16             ;# of times
L881D       LDA    ValExpr
            LSR
            BCC    L882E
;
            CLC
            LDX    #-2
L8825       LDA    ValExpr+4,X     ;$A1-$A2
            ADC    Accum+2,X       ;$AF-$B0
            STA    ValExpr+4,X
            INX
            BNE    L8825
;
L882E       LDX    #3
L8830       ROR    ValExpr,X
            DEX
            BPL    L8830
            DEY
            BNE    L881D
            RTS
;
; / operator
;
ExprDIV     JSR    AdvSrcP
            STY    ValExpr+2
            STY    ValExpr+3       ;zero these
            LDY    #16
L8842       ASL    ValExpr         ;dividend
            ROL    ValExpr+1
            ROL    ValExpr+2
            ROL    ValExpr+3
            SEC
            LDA    ValExpr+2
            SBC    Accum           ; divisor
            TAX
            LDA    ValExpr+3
            SBC    Accum+1
            BCC    L885C
            STX    ValExpr+2
            STA    ValExpr+3
            INC    ValExpr
L885C       DEY
            BNE    L8842
            RTS
;
; - operator
;
ExprSUB     LDA    RelExprF
            EOR    SavSEF          ;prev subexpr's RelExprF
            STA    RelExprF
            LDA    Accum+1         ;Do 1's complement
            EOR    #$FF
            STA    Accum+1
            LDA    Accum
            EOR    #$FF
            SEC                    ;Proceed to add 1
            BCS    L887C           ; giving 2's complement
;
; + operator
;
ExprADD     LDA    SavSEF          ;Get prev subexpr's RelExprF
            ORA    RelExprF
            STA    RelExprF
            CLC
            LDA    Accum
L887C       ADC    ValExpr
            STA    ValExpr
            LDA    Accum+1
            ADC    ValExpr+1
            STA    ValExpr+1
            RTS
;
Operators   DB     $2B             ;+
            DB     $2D             ;-
            DB     $2A             ;;
            DB     $2F             ;/
            DB     $21             ;! EOR
            DB     $5E             ;^ AND
            DB     $7C             ;| OR
;
; This table of JMP (via RTS) addresses is split into 2 parts
;
L888E       DB     <ExprADD-1      ;hibyte
            DB     <ExprSUB-1
            DB     <ExprMUL-1
            DB     <ExprDIV-1
            DB     <ExprEOR-1
            DB     <ExprAND-1
            DB     <ExprORA-1
L8895       DB     >ExprADD-1      ;lobyte
            DB     >ExprSUB-1
            DB     >ExprMUL-1
            DB     >ExprDIV-1
            DB     >ExprEOR-1
            DB     >ExprAND-1
            DB     >ExprORA-1
;
; | operator bitwise OR
;
ExprORA     LDA    Accum
            ORA    ValExpr
            STA    ValExpr
            LDA    Accum+1
            ORA    ValExpr+1
            STA    ValExpr+1
            RTS
;
; ^ operator bitwise AND
;
ExprAND     LDA    Accum
            AND    ValExpr
            STA    ValExpr
            LDA    Accum+1
            AND    ValExpr+1
            STA    ValExpr+1
            RTS
;
; ! operator - bitwise EOR
;
ExprEOR     LDA    Accum
            EOR    ValExpr
            STA    ValExpr
            LDA    Accum+1
            EOR    ValExpr+1
            STA    ValExpr+1
            RTS
            REP    50
;
; Part of symbol table handler
; ($88C3) Find the key
; HeaderT-table of ptrs to singly list of keys with same hash value
; Ret:
;   C=1 - Symbol not in table
;   (Y)=0
;   C=0 - Symbol in table
;   (A) = flag byte
;   (Y)-indexing lobyte value field/indexing next char of src line
;
; PrvSymP would be set correctly for existing chains
;
FindSym     JSR    HashFn          ;Hash the label
            LDY    HeaderT+1,X     ;(X)=hashed value x 2
            BEQ    L8908           ;Empty slot => Not Found!
;
;  Get ptr to 1st node in singly linked list (chain)
;
            LDA    HeaderT,X
FindLoop    STA    SymP
            STY    SymP+1
            STA    PrvSymP
            STY    PrvSymP+1
;
            LDY    #0
            LDA    (SymP),Y
            STA    NxtSymP         ;Point to next node
            INY
            LDA    (SymP),Y        ; in chain
            STA    NxtSymP+1       ;If NIL ($0000) end of chain
;
            LDA    #2              ;Skip past link pointer
            CLC
            ADC    SymP            ; to point @ the symbolic name
            STA    SymP
            BCC    L88EC           ;This will allow us to use the
            INC    SymP+1          ;same (Y) index for SrcP & SymP
;
L88EC       LDY    #-1             ;Prepare to get 1st char of src line
L88EE       JSR    ChrGet2
            ORA    #$80
            CMP    (SymP),Y
            BEQ    L88EE           ;Got a match, try next char
            AND    #$7F            ;Match last char of symbolic name
            CMP    (SymP),Y        ;Do we have a complete match?
            BNE    L8902           ;No
            JSR    ChrGet2         ;Maybe but is next char alphanumeric?
            BCS    L890A           ;No, probably a CR/SPACE => total match
;
L8902       LDA    NxtSymP         ;On fall thru, a partial match
            LDY    NxtSymP+1       ;End of this chain?
            BNE    FindLoop        ;No, continue with next node in chain
L8908       SEC                    ;Flag symbolic name not found
            RTS
;
L890A       LDA    (SymP),Y        ;Get symbol's flag byte
            BMI    L891A           ;Not defined yet
;
            AND    #%10111111      ;Set it to referenced
            STA    (SymP),Y
            PHA                    ;Save flag byte
            AND    #relative       ;Retain this bit
            ORA    RelExprF
            STA    RelExprF
            PLA                    ;Restore
;
L891A       CLC                    ;Flag symbolic name found
            INY                    ;Indexing value field
            RTS                    ; or 1st char in next src line?
            REP    50
;
; HashFn
; The Header Table can have at most 128 entries. Each
; entry is a 2-byte pointer (called a HEADER NODE) to a
; singly linked list of nodes (chain of nodes).
; Only the first 3 chars of a symbolic name are used
; by this hashing function.
; Ret:
; Y - preserved
; (X)=8-bit value which is used to index HeaderT
;
HashFn      TYA
            PHA                    ;save (Y)
            LDA    #0
            STA    HashIdx         ;zero the hash value
            JSR    ChrGot2         ;1st char of label
            AND    #%00000011      ;0000 00xx
            LSR
            ROL    HashIdx
            LSR
            ROL    HashIdx         ;0000 00xx
;
            LDA    HashIdx
            PHA                    ;save temporarily
            LDA    #0
            STA    HashIdx
            JSR    ChrGet2         ;Is 2nd char alphanumeric?
            BCC    L8947           ;yes
;
; one-char label
;
            PLA                    ;Discard hashed value
            PLA                    ;restore Y-reg
            TAY
            PHA
            LDA    (SrcP),Y        ;Get char again ($41-$5A)
            AND    #%00011111      ;$01-$1A (note: A,X,Y may be missing)
            ASL
            ASL
            JMP    L897D
;
L8947       AND    #%00000111      ;0000 0yyy
            LSR
            ROL    HashIdx
            LSR
            ROL    HashIdx
            LSR
            ROL    HashIdx         ;=0000 0yyy
            ASL    HashIdx         ;=0000 yyy0
            ASL    HashIdx         ;=000y yy00
            PLA                    ;(A)=0000 00xx
            EOR    HashIdx
            PHA                    ;(A)=000y yyxx
            LDA    #$00
            STA    HashIdx
            JSR    ChrGet2         ;Is 3rd char alphanumeric?
            BCC    L8968           ;Yes
            PLA                    ;2-char label field
            ASL
            ASL                    ;0yyy xx00
            BPL    L897D           ;always
;
; 3rd char
;
L8968       AND    #%00000111      ;0000 0zzz
            ASL
            ASL
            ASL
            ASL
            ASL
            ASL
            ROR    HashIdx         ;(HashIdx)=z000 0000
            ASL
            ROR    HashIdx         ;(HashIdx)=zz00 0000
            ASL
            ROR    HashIdx         ;(HashIdx)=zzz0 0000
            LSR    HashIdx         ;(HashIdx)=0zzz 0000
            PLA                    ;(A)=000y yyxx
            EOR    HashIdx
;
L897D       ASL                    ;x2 to make hash value into an index
            STA    HashIdx         ; 0,2,4,...,254
            TAX
            PLA                    ;restore (Y)
            TAY
            RTS
            REP    50
;
RsvdId      JSR    IsAXY           ;Chk if reserved idfer
            BCC    doRet9          ;No
            LDX    #$1E            ;Reserved idfer err
            JMP    RegAsmEW
            REP    50
;
; Chk for a single 'A','X','Y' in label/operand field
; C=1 - Yes
; (X) & (Y) - unchanged
;
IsAXY       JSR    ChrGot2         ;Patch here if we want the letters
            CMP    #'X'            ; A,X,Y to be used as labels/operands
            BEQ    L899F
            CMP    #'A'
            BCC    doRet9
            BEQ    L899F
            CMP    #'Y'
            BNE    L89A7
L899F       JSR    ChrGet2         ;Is next char alphanumeric?
            DEY                    ;Backup to 1st char
            BCC    doRet9          ;Yes
            SEC
            RTS
L89A7       CLC
doRet9      RTS
            REP    50
;
; ($89A9) Add a node
; Entry:
;  (A)=initial value of flag byte of the Symbol
;      ref pg 231 of manual for details
; Ret:
;  C=0 - succ
; (Y)=index last byte of entry (Hi-byte)
;  C=1 - fail
; The bits of the flag byte are defined as follows:
; $80 - undefined
; $40 - unreferenced
; $20 - relative to beginning of module
; $10 - External
; $08 - Entry
; $04 - macro (not implemented)
; $02 - No such label
; $01 - forward referenced
; Layout of Node
;   ptr to next node in chain (set to NIL)
;   symbolicname (variable in length)
;   flag byte
;   16-bit value
; NB. 1) msb of all chars of symbolic name
;		 except the last one are on
;     2) The size of a node structure is not fixed.
; Symbolic names with the same hash value (collision)
; are connected together in a singly linked list.
;
AddNode     PHA                    ;Save flag byte
            LDY    #0
            JSR    ChrGot
            BCC    L89B4
            SEC
            PLA
            RTS
;
L89B4       LDX    HashIdx         ;Is there already a chain
            LDA    HeaderT+1,X     ; associated with this value?
            BNE    L89C8           ;Yes
            LDA    #>HeaderT       ;Start a new singly linked list
            CLC
            ADC    HashIdx         ;=$xx
            STA    PrvSymP         ;Point @ $BCxx
            LDA    #<HeaderT
            ADC    #0
            STA    PrvSymP+1
;
; NB: We assume PrvSymP have been set correctly
; if it's not a new chain. In order to set this ptr
; correctly for an existing chain, FindSym should
; be called before AddNode.
;
L89C8       TYA                    ;A=Y=0
            STA    (EndSymT),Y
            LDA    EndSymT
            STA    (PrvSymP),Y
            TYA                    ;A=0
            INY                    ;Y=1
            STA    (EndSymT),Y     ;Set link field to NIL ($0000)
            LDA    EndSymT+1
            STA    (PrvSymP),Y     ;Point @ new entry
;
            DEY                    ;=0
            LDA    #2              ;Skip past
            CLC
            ADC    EndSymT
            STA    EndSymT         ; the link field so that
            BCC    L89E3           ; Y reg can be used to
            INC    EndSymT+1       ; index both SrcP & EndSymT
;
; Labels are stored in the symbol table with
; msb on except last char.
; On fall thru, Y=0 for both SrcP and EndSymT.
;
L89E3       JSR    ChrGot
L89E6       ORA    #$80            ;msb on
            STA    (EndSymT),Y
            JSR    ChrGet2         ;Is char alphanumeric?
            BCC    L89E6           ;Yes
            DEY
            LDA    (EndSymT),Y
            AND    #$7F            ;Remove msb for last char
            STA    (EndSymT),Y
            INY                    ;Skip past last char
            PLA                    ;Get flag byte that was passed
            CMP    #undefined+fwdrefd
            BEQ    L8A00
            ORA    RelExprF        ;relative if bit20=1
            ORA    #unrefd         ;Mark as unreferenced
;
L8A00       STA    (EndSymT),Y     ;Set flag byte
            INY
            LDA    PC              ; Set addr associated
            STA    (EndSymT),Y
            INY
            LDA    PC+1            ; w/this symbol
            STA    (EndSymT),Y
;
            LDA    EndSymT
            STA    SymP            ;Point @ symbolic name
            LDA    EndSymT+1
            STA    SymP+1
            TYA
            SEC                    ;Add 1 to point @
            ADC    EndSymT
            STA    EndSymT         ; next availmem
            BCC    L8A1E
            INC    EndSymT+1
;
L8A1E       LDA    EndSymT
            CMP    RLDEnd          ;Chk we still got some mem left
            LDA    EndSymT+1
            SBC    RLDEnd+1
            BCC    doRtn3
;
            LDX    #$12            ;sym/rld table full!
            JSR    RegAsmEW
            JMP    CanclAsm
doRtn3      RTS
            REP    50