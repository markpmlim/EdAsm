Name          : LINK.S
End of file   :   91,112
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;
; Initial code disassembled with the ORCA.DisAsm
; Source files for the Linker is of type REL
; The Linker can produce BIN, REL or SYS object files
;
; Init the Linker
;
AsmLinker   EQU    *
            ldx    #0
            stx    AsmLinker
            php                    ;Save status reg
            pla
            sta    Z9C             ; here
            sei                    ;No interrupts
;
            lda    #0
ZeroLoop    sta    Stack,x         ;Zero stack area
            inx
            bne    ZeroLoop
;
            dex
            txs                    ;=$FF
            lda    Z9C
            pha                    ;Restore status reg
            plp
;
            lda    #$00
            sta    MINIVERS        ;minimum interpreter version
            lda    #$10
            sta    IVERSION        ;interpreter version
            lda    #%00000011      ;Pages 6-7
            sta    BitMap          ; are reserved
;
; Setup memory management
;
            lda    #%10101000
            and    #%00000111
            tax                    ;(X)=0
            ldy    #0
            tya                    ;(A)=0
NeverLoop   ora    BitsT,y         ;Loop never executed?
            iny
            dex
            bpl    NeverLoop
;
            eor    #$FF            ;(A)=%01111111
            ldx    #$15
            and    BitMap,x        ;Mark page $A8
            sta    BitMap,x        ;  as free
;
            lda    #$00
            dex
ZeroLup     sta    BitMap,x        ;Pages $08-$A7
            dex                    ; are free
            bne    ZeroLup
;
; Init various flags & variables
;
            lda    #$80            ;Set the following
            sta    MapFileF        ; flags to ON
            sta    SortLMF
            sta    XRefF
            sta    ERefF
;
            lda    #$00            ;Set the following
            sta    PageF           ;flags to OFF
            sta    OptDF
            sta    OptionsF
            sta    FTypeF
            sta    NumSortF
            sta    Origin          ;Zero this
            sta    Origin+1
;
            lda    #1
            sta    LineCnt
            sta    PageCnt
;
; Try to open a default command (TXT)
; file named "EDASM.AUTOLINK"
;
            ldy    AutoLnkS
CpyLoop     lda    AutoLnkS,y
            sta    PathNameB,y
            dey
            bpl    CpyLoop
;
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     OpCmdFP
            beq    DoPhase0
            cmp    #$46            ;fileNotFound
            bne    NoGood
            beq    FNF
;
OtherErr    jsr    PrtError        ;(A)=err code, don't come back
;
FNF         ldy    #$00            ;Print Banner & prompt
            jsr    DspMsg          ; for command filename
            lda    #'?'+$80
            sta    Prompt
            jsr    GetLine         ;Use monitor's input rtn to get filename
            stx    PathNameB       ;Save len byte
            lda    InBuf           ;Did user choose to abort
            cmp    #CTRLC+$80      ; the linking process?
            bne    CpyLoop2
            jmp    Abort           ;Yes
;
CpyLoop2    lda    InBuf,x         ;Copy the filename
            and    #$7F            ; typed in & ensure all
            sta    PathNameB+1,x   ; its chars are std ASCII
            dex
            bpl    CpyLoop2
;
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     OpCmdFP
            beq    DoPhase0
;
            cmp    #$40            ;badPathSyntax
            beq    OtherErr
            cmp    #$44            ;pathNotFound
            beq    OtherErr
            cmp    #$45            ;volNotFound
            beq    OtherErr
            cmp    #$46            ;fileNotFound
            beq    OtherErr
;
NoGood      jsr    ErrHndlr        ;Don't come back
;=================================================
; Phase 0: Setup environment for the Linker
; Each record in the Command File is a CR-terminated text line (msb off)
; Each text line is either
;   a command to the Linker or
;   the pathname of a source file of type REL
; Directives/Commands to the Linker must be preceded by
; at least 1 space while pathnames have no leading space(s)
;
DoPhase0    EQU    *
            lda    OpCmdFP+c.outRef;Copy this to the fields
            sta    SMCmdFP+c.refNum; of other ProDOS parameter
            sta    NLCmdFP+c.refNum; blocks b4 we start to read
            sta    RdCmdFP+c.refNum; the CMD file line by line
;
; Ensure that all future READ operations on the Command
; File is terminated by a CR or an EOF
;
            jsr    PRODOS8         ;NEWLINE
            DB     $C9
            DW     NLCmdFP
            bne    NoGood
;
            lda    #BINtype        ;Default OBJECT filetype
            sta    TrgtFTyp
            ldy    #$03            ;Display "Phase0: Commands..."
            jsr    DspMsg
            jsr    DspCR
;
; This loop only processes directives & ignores the pathnames
;
Phs0Loop    jsr    PollKbd
            jsr    Read1Cmd        ;Is 1st char is a CR/SPACE?
            bne    NotCmd          ;No, it's a PN of a src (REL) file
            jsr    DspLineB        ;Show cmd
            cmp    #CR
            bne    Phs01           ;1st char not CR => SPACE
            jmp    CmdFileErr      ;CR => null cmd line
;
Phs01       jsr    SkipSpcs
            jsr    ChkDrtv         ;Is it a directive?
            bcs    Phs0Loop        ;Not valid, ignore
;
            pha                    ;Index into JMP table
            jsr    WhiteSpc
            jsr    AdvCP           ;Ensure cp is @ 1st char of directive
            pla
            jsr    HndlDrtv        ;Process directive
            jmp    Phs0Loop
;
; If 1st char is not CR/SPACE, then it is a pathname of a src file
;
NotCmd      bit    MapFileF        ;Output a LinkMAP? (default ON)
            bpl    EndPhs0         ;No
            jsr    OpLnkMap        ;Open LinkMap file for output
EndPhs0     jmp    DoPhase1
;=================================================
; JMP via an RTS to parse the operand
; field of a directive
;
HndlDrtv    tax
            lda    L36F0,x         ;Directive JMP table
            pha
            lda    L36EA,x
            pha
            rts
;=================================================
; BIN command/directive
; Input
;  FTypeF=0    OBJECT file type not set
; Output
;  FTypeF=1
;  TrgtFTyp=BIN
; NB. Only one BIN/REL/SYS directive
; may be declared
;
CmdBin      lda    FTypeF          ;Has the OBJ type been set?
            beq    CmdBin1         ;No
            jmp    DupCmdErr
;
CmdBin1     lda    #$01
            sta    FTypeF          ;Flag it's set
            lda    #BINtype
            sta    TrgtFTyp
            jsr    GetOutFN        ;Get Link OBJ/MAP filenames
            rts
;=================================================
; REL command/directive
; Input
;  FTypeF=0
; Output
;  FTypeF=$80
;  TrgtFTyp=REL
;
CmdRel      lda    FTypeF
            beq    CmdRel1
            jmp    DupCmdErr
;
CmdRel1     lda    #$80
            sta    FTypeF
            lda    #RELtype
            sta    TrgtFTyp
            jsr    GetOutFN
            rts
;=================================================
; SYS command/directive
; Input
;  FTypeF=0
; Output
;  FTypeF=$02
;  TrgtFTyp=SYS
;
CmdSys      lda    FTypeF
            beq    CmdSys1
            jmp    DupCmdErr
CmdSys1     lda    #$02
            sta    FTypeF
            lda    #SYStype
            sta    TrgtFTyp
            jsr    GetOutFN
            rts
;=================================================
; ORG command/directive
; Input
; Output
;  Origin=Value of Expression
; Only 1 ORG may be declared and it must be b4 the src pathnames
;
CmdOrg      lda    Origin          ;Already set?
            ora    Origin+1
            beq    CmdOrg1
            jmp    DupCmdErr       ;Yes, duplicate cmd
;
CmdOrg1     jsr    SkipSpcs
            jsr    ChrGot
            beq    BadOrg          ;sp/cr
            jsr    EvalExpr
            lda    Value16         ;Chk it's valid
            sta    Origin
            lda    Value16+1
            beq    BadOrg          ; < $0100
            sta    Origin+1
            ora    Origin
            beq    BadOrg          ; $0000
            rts
BadOrg      jmp    CmdSynErr       ;syntax err
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ALN Command/Directive
; Align Origin @ start of next mempage
; Output
;  Origin=$xx00
;
; This directive is usually used after a pathname
; and may be used repeatedly
;
CmdAln      lda    Origin          ;ORG must be set first either by a
            ora    Origin+1        ; directive or via src filename
            bne    CmdAln1
            jmp    CmdOrderErr     ;Wrong cmd order
;
CmdAln1     lda    Origin          ;Align @ the beginning
            beq    doRTS
            inc    Origin+1        ; of the next mempage
            lda    #$00
            sta    Origin
doRTS       rts
;=================================================
; OPT command/directive. Only allowed to be used once
; Default
;     OPT +M,+E,+S,+X,-N,-D,-P
; Input
;  OptionsF
; Output
;  OptionsF=1 - If Directive not declared
;
;  One/Some/All of the following flags may be set
;  M)apFileF - Output LinkMAP file (default ON)
;  E)RefF    - Add ENTRY records (default ON)
;  S)ortLMF  - Sort LoadMap table (default ON)
;  X)RefF    - Cross-referenced (default ON)
;  N)umSortF - Sort LoadMap numerically (default OFF)
;  O)ptDF    - not used (default OFF)
;  P)ageF    - Pagination (default OFF)
;
CmdOptn     EQU    *
            lda    OptionsF        ;First time directive is declared?
            beq    CmdOptn1        ;Yes
            jmp    DupCmdErr       ;Duplicate cmd
;
CmdOptn1    inc    OptionsF        ;Flag we have encountered this cmd
            jsr    SkipSpcs
;
GetOptFlg   jsr    ChrGot          ;chrgot
            beq    doRTS1          ;cr/space
            cmp    #'+'            ;ON switch flag?
            bne    IsOptnOff       ;No
            lda    #$80            ;ON
            sta    Switch
            bne    WhchOptn        ;always
;
IsOptnOff   cmp    #'-'
            bne    BadOptn
;
            lda    #$00            ;OFF
            sta    Switch
WhchOptn    jsr    ChrGet          ;Get char after switch flag
            beq    BadOptn         ;It's a cr/space
            ldx    #0
OptnLoop    cmp    OptionsT,x
            beq    GotOptn         ;Got a hit
            inx
            cpx    #7
            bcc    OptnLoop        ;Next
BadOptn     jmp    OptnErr         ;Invalid option/option syntax
;
GotOptn     lda    Switch
            sta    OptFlagT,x      ;$A2-$A8
NxtOptn     jsr    ChrGet          ;Get char
            beq    doRTS1          ;cr/space
            cmp    #','            ;delimiter
            bne    NxtOptn
            iny                    ;Skip comma
            jmp    GetOptFlg       ;Loop back for another option
doRTS1      rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Parse for the pathnames of the OBJ file and
; LinkMap txt file. Full and partial pathname
; are accepted. If there is no operand field
; following the BIN/REL/SYS directive/cmd then
; the default filenames are used.
;
; Output
;  LinkObjS buf
;
GetOutFN    jsr    SkipSpcs
CpyLoop3    jsr    ChrGot
            beq    GotWS           ;cr/space
            jsr    ChkChar         ;Is char valid?
            bne    IsCR            ;No
            iny
            sta    LinkObjS,y
            bne    CpyLoop3
;
IsCR        cmp    #CR             ;Is it a CR?
GotWS       php                    ;Save compare status
            cpy    #0              ;Is there an operand?
            beq    Chk4CR          ;No
            sty    LinkObjS        ;Len byte
Chk4CR      plp
            beq    doRTS2          ;Yes, it's a CR, so done
            cmp    #','            ;Check for the delimiter
            bne    FNF2            ;Not found
;
            ldx    #0
            iny                    ;Skip the comma
ChkLoop     jsr    ChrGot
            beq    GotCR           ;cr/space
            jsr    ChkChar         ;Is char valid?
            bne    FNF2            ;No, err
            inx
            iny
            sta    LinkMapS,x
            bne    ChkLoop
;
GotCR       cpx    #0              ;If no user-defined LinkMap
            beq    doRTS2          ; file use default
            stx    LinkMapS        ;Len byte
doRTS2      rts
;
FNF2        lda    #$40            ;fileNotFound
            jsr    ErrHndlr        ;Don't come back
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Check if a char is valid
; Valid chars are: / . 0-9 A-Z
; Input
;  (A)=ascii char
; Output
;  Z=1 if char is valid
;
ChkChar     cmp    #'/'
            beq    doRTS3
            cmp    #'.'
            beq    doRTS3
            jsr    IsDecChar       ;Is it a decimal digit?
            bcc    CharOK          ;Yes
            cmp    #'A'
            bcc    doRTS3
            cmp    #'Z'+1
            bcc    CharOK
            cmp    #'A'
            rts
;
CharOK      sta    Prompt
            cmp    Prompt          ;Ensure Z=1
doRTS3      rts
;=================================================
; Set PathName buf to OBJECT file
;
MovObjFN    EQU    *
            ldy    LinkObjS        ;len byte
MovLoop     lda    LinkObjS,y
            sta    PathNameB,y
            dey
            bpl    MovLoop
            rts
            REP    50
; Set PathName buf to LinkMap text file
;
MovMapFN    EQU    *
            ldy    LinkMapS        ;Get its len byte
MovLoop2    lda    LinkMapS,y
            sta    PathNameB,y
            dey
            bpl    MovLoop2
            rts
            REP    50
; Open for LinkMap text file for writing
; Input
; Output
;
OpLnkMap    EQU    *
            jsr    MovMapFN        ;Set PN to LinkMap's
            jsr    PRODOS8         ;DESTROY
            DB     $C1
            DW     DestryP
;
            jsr    PRODOS8         ;CREATE
            DB     $C0
            DW     CrLnkMapP
            bne    GotErr
;
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     Open2P
            beq    FileOpn
GotErr      jsr    ErrHndlr        ;Don't come back
;
FileOpn     lda    Open2P+c.outRef
            sta    WrMapFP+c.refNum
            lda    #0
            sta    WrMapFIdx       ;# of bytes to write
            sta    WrMapFIdx+1     ;HOB=Always 0
            rts
;=================================================
; Using info fr the ESD (if any) of the src files,
; build 3 arrays called ENTRY, EXTRN & SymbolicName
; tables.
;  EntRecP - Point to an element of the ENTRY table of 24-byte records
;  XtnRecP - Point to an element of the EXTRN table of 8-byte records
;  SymP    - Point to an element of the SymbolicName table of 16-byte records
;  ModNbr  - src file # assigned during processing
;  CurrORG - starting PC of current src file
;
DoPhase1    ldy    #$04            ;Building ENTRY/EXTERN tables
            jsr    DspMsg
            jsr    DspCR
            ldy    #$04
            jsr    StorMsgY        ;Store same msg to LinkMap
;
            lda    #>EntTbl
            sta    EntRecP         ;ENTRY table @ $4700
            lda    #<EntTbl
            sta    EntRecP+1
            lda    #>XtnTbl        ;XTRN table @ $7100
            sta    XtnRecP
            lda    #<XtnTbl
            sta    XtnRecP+1
            lda    #>SymTbl        ;SymbolicName table @ $9200
            sta    SymP
            lda    #<SymTbl
            sta    SymP+1
;
            lda    #0
            sta    ModNbr          ;module #
            lda    Origin
            sta    CurrORG
            lda    Origin+1
            sta    CurrORG+1
            jmp    Phs11
;
; Process a src file. The only directive allowed
; is ALN which instructs the Linker to adjust
; the PC to the start of next mem page
;
Phs1Loop    EQU    *
            jsr    PollKbd
            jsr    Read1Cmd
            bne    Phs11           ;Not a cr/space => we've a PN
            cmp    #CR
            beq    GoPhase2        ;Empty line -> no more cmds
            jsr    IsALN           ;Is it Align directive?
            bcc    GotAln          ;Yes -> align mem
            jmp    DoBreak         ;Abort!
;
GotAln      beq    AlignMem        ;ALN option
            jmp    CmdOrderErr     ;No, invalid cmd order
;
AlignMem    lda    CurrORG         ;Already @ a mempage bdry?
            beq    Phs1Loop        ;Yes
            inc    CurrORG+1       ;Next mempage
            lda    #$00
            sta    CurrORG
            beq    Phs1Loop        ;always
;
GoPhase2    jmp    DoPhase2
;
; The name of a src file is already in CmdLine buffer
; Open the src file and setup some variables
; using the info fr the opened src file.
;
;  CmdLineB - Pathname of src file
;  EntRecP  - ptr to a rec of ENTRY table
;  XtnRecP  - ptr to a rec of EXTRN table
;  SymP     - ptr to a rec of SymbolicName table
;
;  Origin   - ORG of 1st src file (if not) set by an ORG directive
;  CurrORG  - Starting PC assigned to curr src file
;  SMSrcFP+c.mark - file posn of source file
;  SrcP      - pointer into a chunk of source file
;
;  Z80 - End of chunk of RLD data read
;  Z82 - Start of RLD data read
;
Phs11       jsr    DspLineB
            jsr    OpenSrc         ;Open src file and get info
            bcc    Phs12
            jsr    ErrHndlr        ;Don't come back
;
Phs12       lda    Origin          ;Was it set?
            ora    Origin+1
            bne    OrgSet          ;Yes
;
            lda    SrcORG          ;Use the ORG as recorded
            sta    Origin          ; in the 1st src file
            sta    CurrORG         ; as our origin & use it as
            lda    SrcORG+1        ; the starting PC as well
            sta    Origin+1        ;NB. Once set, it will remain unchanged
            sta    CurrORG+1       ; throughout linking process
;
OrgSet      lda    #2
            clc
            adc    SrcCodeLen      ;Len of code image
            sta    SMSrcFP+c.mark  ;Set file posn to src file's
            lda    #0              ; relocation dictionary (RLD)
            adc    SrcCodeLen+1
            sta    SMSrcFP+c.mark+1; which is just after the code image
            lda    OpSrcFP+c.outRef
            sta    SMSrcFP+c.refNum
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMSrcFP
            bne    GotErr2
;
            jsr    L3348           ;Read max chunk of RLD/ESD
            bcc    FinalData       ;=> The entire RLD/ESD was read
            cmp    #$10            ;Did we encounter an EOF?
            beq    MoreData        ;No, more data chunks
GotErr2     jsr    ErrHndlr        ;(A)=$4C, so let EI take care of it
;
; A fixed chunk (of 5K) had been read so there may be more
; data to be read. There seems to be no provision dealing
; with files in which the END of RLD is not within
; the first 5K of RLD/ESD data i.e. the RLD is very big.
; The code below doesn't seem to be able to handle this
; situation.  Is there a bug here?
; The code below will never be executed if sizeof RLD+ESD < 5K
;
MoreData    jsr    GetEndRLD       ;Scan for end of RLD
            lda    SrcP+1          ;Is SrcP still at the BO
            cmp    #<SrcDBuf       ; the srcfile data buffer?
            bne    L2353           ;No
            lda    SrcP            ;(Should SrcP be compared to $2000?)
            cmp    #>SrcDBuf       ; which is EO SrcDBuf+1
            bne    L2353
BigESD      jmp    RldEsdErr       ;Src file's ESD too large
;
; This code is only executed if the size of the RLD is less
; than the size of the SrcDBuf located @ $0C00 (which is 5K)
; SrcP is pointing @ EO RLD
; The code below is definitely buggy.
;
L2353       lda    #>SrcDBuf       ;Start addr
            clc
            adc    RWFileP+c.transCnt;Actual # of bytes read
            sta    Z80             ;Point @ EO data chunk + 1
            lda    #<SrcDBuf
            adc    RWFileP+c.transCnt+1; (or EO file data buf + 1=$2000)
            sta    Z80+1           ;END addr
;
            lda    #>SrcDBuf
            sta    Z82             ;DEST addr
            lda    #<SrcDBuf
            sta    Z82+1
;
; Calc the size of ESD data in FileData buf
;
            lda    Z80
            sec
            sbc    SrcP            ;Pointing @ EO RLD
            sta    RWFileP+c.transCnt;=len of ESD already in buf + 1 (EO RLD marker)
            lda    Z80+1           ;(should SrcP be incr 1 more?)
            sbc    SrcP+1
            sta    RWFileP+c.transCnt;Bug! Should be sta RWFileP+c.transCnt+1
;
; Move ESD block forward in filedata buf (incl EO RLD marker)
;
            jsr    MovData
            lda    #>SrcDBuf       ;Prepare to append more ESD data
            clc
            adc    RWFileP+c.transCnt; fr src file by reading 'em 
            sta    RWFileP+c.dataBuf; into this starting location
            lda    #<SrcDBuf
            adc    RWFileP+c.transCnt;Bug! Should be adc RWFileP+c.transCnt+1
            sta    RWFileP+c.dataBuf+1
;
; Calculate # of bytes to be read in
; order to fill the rest of FileData
; buf with more ESD records
;
            lda    #>FileDBSiz
            sec
            sbc    RWFileP+c.transCnt
            sta    RWFileP+c.reqCnt;=$1400-(# of bytes of
            lda    #<FileDBSiz
            sbc    RWFileP+c.transCnt+1; data currently in mem)
            sta    RWFileP+c.reqCnt+1
            jsr    ReadCode        ;Attempt to read another chunk
            bcc    FinalData       ;Last chunk so that's ok
            cmp    #$10            ;More to go?
            beq    BigESD          ;Yes, ESD too large
            bne    GotErr2         ;Always-error
;
; Last chunk of RLD/ESD data had been read
; The code below seems ok
;
FinalData   jsr    GetEndRLD       ;Point to end of RLD
            lda    OpSrcFP+c.outRef;Close src file
            jsr    ClsFile
            inc    SrcP            ;Skip the EO RLD marker which
            bne    Bump1           ; is a $00 to point @ appended ESD
            inc    SrcP+1
;
Bump1       ldy    ModNbr          ;Current file module #
            lda    XtnRecP         ;Ptr to 1st EXTRN record
            sta    SrcModTLo,y     ;for this module
            lda    XtnRecP+1
            sta    SrcModTHi,y
;
; Add records to the SymbolicName, ENTRY/EXTRN
; tables using information from ESD
;
ScanESD     jsr    PollKbd
;
            ldy    #15             ;FOR Y= 15 to 1
            lda    #SPACE
BlnkLoop    sta    (EntRecP),y
            sta    (SymP),y
            dey
            bne    BlnkLoop
;
; Y=0 on fall thru
; NB: All chars of SymbolicName record will have their msb off
; The SymbolicName record is a p-string (may be a
; truncation of the original symbolic name in ESD)
;
MakeRecs    lda    (SrcP),y        ;Get 1st char of symbolicname
            bne    MkRecs1
            jmp    DoneESD         ;EO ESD => Done processing this file
MkRecs1     php                    ;save msb
            and    #$7F
            iny
            sta    (EntRecP),y     ;Copy char to both ENTRY and
            sta    (SymP),y        ; SymbolicName records
            plp                    ;Is msb off?
            bpl    CkSymTyp        ;Yes, last char of symbolic name
            cpy    #15             ;max len of linker symbol
            bcc    MakeRecs        ;Next char
;
; Only first 15 chars are copied. We skip the rest of chars.
; However, we still need to locate the eo the symbolicname
; in order to get @ the symbol-type flag etc.
;
SkipLoop    lda    (SrcP),y        ;Get symbolicname's char
            iny
            tax                    ;Is this the last char?
            bmi    SkipLoop        ;No
;
CkSymTyp    tya
            ldy    #0
            sta    (EntRecP),y     ;Set the len byte
            sta    (SymP),y
            tay
            lda    (SrcP),y
            sta    ESDRec          ;Symbol-type flag
            iny
            lda    (SrcP),y        ;If EXTRN, this is the symbol #
            sta    ESDRec+1        ; referred to by an RLD entry
            iny
            lda    (SrcP),y        ;Hibyte of addr if
            sta    ESDRec+2        ; symbol-type is ENTRY
;
            lda    ESDRec          ;Chk symbol-type
            and    #%00001000      ;Is it EXTRN symbol-type?
            bne    DoEntry         ;No, it's ENTRY symbol-type
;
            ldx    #XtnRecP
            bit    Z9E             ;Include code fr this file?
            bpl    DoXtrn          ;Yes
            jmp    NxtEntryZ       ;No recs will be added to the 3 tables
;
; Process an EXTRN symbol-type rec in ESD of a src file
;
DoXtrn      lda    #0              ;Zero the curr ENTRY slot
            ldy    #24
ZeroLup2    sta    (EntRecP),y     ; which was partially
            dey                    ; filled with the symbolicname
            bpl    ZeroLup2
;
; Create a EXTRN record in table @ $7100
; Each record is 8 bytes
; Initial Layout of each record is as follows:
; offset  Description
; 0        DW ptr to a record in SymbolicName table ($9200)
;          ptr to another EXTRN rec if the SymbolicName
;          matched with that in one of the ENTRY recs
; 2        DW Ptr to an ENTRY record; NIL initially
; 4        DB file # of src file (also called module #)
; 5        DB FlagByte
; 6        DB symbol # referred to by an RLD record
; 7        DB 0
;
            ldy    #0
            lda    SymP
            sta    (XtnRecP),y     ;Ptr to the corr record of
            lda    SymP+1          ; symbolicname table @ $9200
            iny
            sta    (XtnRecP),y
            iny                    ;=2
            lda    #$00
            sta    (XtnRecP),y     ;Set to NIL
            iny
            sta    (XtnRecP),y
            iny                    ;=4
            lda    ModNbr          ;file # of the src module
            sta    (XtnRecP),y
            lda    ESDRec          ;symbol-type flag byte
            ora    #%11000000      ;Set undefined, unref'd bits
            iny                    ;=5
            sta    (XtnRecP),y
            iny                    ;=6
            lda    ESDRec+1
            sta    (XtnRecP),y     ;Symbol # referred to by an RLD record
            iny                    ;=7
            lda    #$00
            sta    (XtnRecP),y     ;hibyte=0 - Not used
            jsr    ScanEntTbl      ;Is this symbol already in ENTRY table?
            bne    ChkSymTbl       ;No
            jsr    L2668           ;Yes, add this EXTRN rec to singly-link list
            jmp    DoneXtrn        ;Add this EXTRN rec to its table
;
ChkSymTbl   jsr    L2629           ;Is symbol already in SymbolicName table?
            bne    AddSymName      ;No => add the SymbolicName rec to its table
;
            ldy    #0
            lda    Z88             ;Set this link to point
            sta    (XtnRecP),y     ; to SymbolicName record
            iny
            lda    Z88+1           ; already in table
            sta    (XtnRecP),y
            jmp    DoneXtrn        ;=> Don't add new SymbolicName rec to its table
;
; We are adding a new SymbolicName rec to the its table
; This is done by incrementing SymP by the appropiate
; # of bytes i.e. SymP++ (in C Syntax)
;
AddSymName  jsr    IncrSymP        ;Adv to next empty slot of SymbolicName table
            lda    SymP+1          ;Is SymbolicName table full?
            cmp    #<XA8E0         ;(Linker's HiMem)
            bcc    DoneXtrn
            bne    SymTblFull
            lda    SymP
            cmp    #>XA8E0
            bcc    DoneXtrn
SymTblFull  jmp    TableFull       ;Yes
;
; Do a XtnP++ to point @ the next empty slot in EXTRN table
;
DoneXtrn    jsr    IncrXtnP
            jmp    NxtEntryZ       ;Prepare to process next rec in appended ESD
;
; Process an ENTRY symbol-type record in ESD of src file
; The 1st field is already done
; Layout of 24-byte records in ENTRY table @ $4700
; offset
;   0    STR up to 16 chars including len byte
;  16    DB file # of src file (start fr 0)
;  17    DB symbol-type
;  18    DW relocated addr
;  20    DW 0 (Ptr to EXTRN record) - first/head
;  22    DW 0 (Ptr to EXTRN record) - last/tail
;
DoEntry     bit    Z9E             ;Include code fr this file?
            bmi    DoEntry1        ;No
;
            lda    ESDRec+2        ;Hibyte of addr as recorded in src file
            cmp    SrcORG+1        ;Origin as recorded in src file
            bcc    DoEntry1
            lda    L3806+1         ;addr+1 of last byte of code image
            sec
            sbc    ESDRec+2        ;Hibyte of addr
            bmi    DoEntry1        ;Is addr to be relocated btwn
            bne    CalcAddr
            lda    ESDRec+1        ; addrs of 1st & last byte of image?
            cmp    L3806
            bcs    DoEntry1        ;Out of range
;
; Calc relocated addr of the instruction
; First do an equivalent to a subtraction
; to obtain the inst' offset wrt
; the src file's origin
;
CalcAddr    lda    ESDRec+1
            clc
            adc    NegSrcOrg       ;2's complement of
            sta    ESDRec+1
            lda    ESDRec+2
            adc    NegSrcOrg+1     ; src file's Origin
            sta    ESDRec+2        ;Got the offset
;
            lda    ESDRec+1        ;Calc the relocated addr
            clc
            adc    CurrORG
            sta    ESDRec+1
            lda    ESDRec+2
            adc    CurrORG+1
            sta    ESDRec+2
;
DoEntry1    ldy    #16
            lda    ModNbr          ;src file #
            sta    (EntRecP),y
            iny
            lda    ESDRec          ;symbol type
            ora    #%01000000      ;Set not-referenced bit
            sta    (EntRecP),y
            iny
            lda    ESDRec+1        ;Relocated addr lo
            sta    (EntRecP),y
            iny
            lda    ESDRec+2        ;Relocated addr hi
            sta    (EntRecP),y
;
            lda    #0              ;FOR Y=20 TO 24
ZeroLup1    iny
            cpy    #24
            sta    (EntRecP),y     ;Set both links to NIL
            bcc    ZeroLup1
;
            ldy    #0
            tya                    ;Zero len byte so that search will
            sta    (EntRecP),y     ;not include this ENTRY rec
            jsr    ScanEntTbl      ;Is this symbol already in ENTRY table?
            php                    ;Save for later
            lda    (SymP),y        ;Get a copy of len byte
            sta    (EntRecP),y     ; & restore it
            plp
            bne    NxtEntry        ;Not in ENTRY table
            jsr    StorDupSym      ;Record duplicate symbol
;
; Do a EntP++ to point @ the next empty slot in ENTRY table
;
NxtEntry    jsr    IncrEntP
;
NxtEntryZ   jsr    NxtESDRec       ;Point @ next rec in appended ESD
            lda    $01,x           ;(X)=$8A,$8C => (A)=$60,$00 (hi-byte of table?)
            cmp    GoShowMsgZ,x    ;Locations $360D+$8A=$3697 or $3699
            beq    TableFull       ;A bug here & in the table
            jmp    ScanESD         ;Scan next ESD record 
;
TableFull   ldy    #$0A            ;symtbl full
            jsr    GoShowMsg
;
; We have finishing processing the ESD of the curr file
; Do some housekeeping b4 processing the next file
; NB. If a src PN is preceded by an asterik,
; its SymbolicNames will be referenced but no
; object code will be incorporated into the
; final OBJ file.
;
DoneESD     EQU    *
            bit    Z9E             ;Was src PN preceded by a ;?
            bmi    NxtSrc          ;Yes => its code will not be incorporated in OBJ file
;
            lda    SrcCodeLen
            clc
            adc    CurrORG         ;Starting PC for 
            sta    CurrORG         ; the next src file
            lda    SrcCodeLen+1
            adc    CurrORG+1
            sta    CurrORG+1
;
NxtSrc      inc    ModNbr
            lda    ModNbr
            cmp    #50             ;max # of src files
            bcs    TooMany
            jmp    Phs1Loop        ;Process next src file
;
TooMany     ldy    #$0B            ;Too many src files
            jsr    GoShowMsg
;=================================================
; Get the end of RLD
; Each record in the Relocation Dictionary is 4 bytes long
; Input
;  SrcP - ptr to beginning of RLD chunk
; Output
;  (Y)=0
;  SrcP - End of RLD if found
;  Z=1
; X - not used
;
; Possible bug here. The code should check that SrcP
; should not exceed upper limit of SrcDBuf ($2000)
; unless it's assumed that RLD is always < 5K. For
; this case, since each RLD record is 4 bytes, the max #
; of RLD records in a src file = (5x1024)/4 -1 = 1279
; This rtn should be re-written to handle files with huge RLDs
; When the EO RLD is not found, it should check that 
; SrcP == (SrcDBuf+FileDBSiz) by returning a flag to the caller
; 
RLDEntSiz   EQU    4               ;size of an RLD entry
GetEndRLD   EQU    *
            ldy    #0
ScanLoop    lda    (SrcP),y        ;Get RLD-flag byte
            and    #$01            ;Is it EO RLD?
            beq    doRTS4          ;Yes
            lda    #RLDEntSiz      ;Point @ next RLD record
            clc
            adc    SrcP
            sta    SrcP
            lda    #0
            adc    SrcP+1
            sta    SrcP+1
            jmp    ScanLoop        ;Continue scanning
doRTS4      rts
;=================================================
; Phase 2 of the Linking process
; This rtn will attempt to resolve EXTRN's by checking
; if its symbolic name is in the ENTRY table
; NB. After phase 1, some recs in EXTRN table are
; already in a singly-linked list. Their SymbolicName
; fields would have been changed to point to another
; EXTRN rec or is set to NIL if they happen to be
; the last node of the list.
; The msb of their flagbyte would be 0 (symbol is defined)
;
DoPhase2    EQU    *
            lda    #0
            ldy    #0
            sta    (EntRecP),y     ;Zero the len byte of ENTRY record
            ldy    #5              ; and flag byte of EXTRN record
            sta    (XtnRecP),y     ;These recs are empty slots
            ldy    #$05            ;Resolving REF/EXTRN...
            jsr    DspMsg
            jsr    DspCR
            ldy    #$05
            jsr    StorMsgY        ;Store same msg
;
            lda    #>XtnTbl
            sta    XtnRecP         ;Point to start
            lda    #<XtnTbl
            sta    XtnRecP+1       ; of EXTRN table
            lda    #0
            sta    XtnNbr          ;EXTRN cnt (or EXTRN #)
;
; Phase2 main loop
;
Phs2Loop    jsr    PollKbd
            ldy    #5
            lda    (XtnRecP),y     ;Get flag byte
            beq    DonePhs2        ;Done w/all recs in EXTRN table
            and    #%10000000      ;Is symbol undefined?
            beq    L25AD           ;No, skip this EXTRN rec
;
            ldy    #0
            lda    (XtnRecP),y     ;Get ptr to its symbolicname
            sta    SymP
            iny
            lda    (XtnRecP),y
            sta    SymP+1
            jsr    ScanEntTbl      ;Is symbol already in ENTRY table?
            bne    L2598           ;No
            jsr    L2668           ;Add to singly-linked nodes of EXTRN recs
            jmp    L25AD           ;Prepare to process next record
;
; The EXTRN symbol was not found in ENTRY table
;
L2598       ldy    #5
            lda    (XtnRecP),y     ;Get flag byte fr EXTRN record
            ora    #%00000010      ;No such label
            sta    (XtnRecP),y
            bit    FTypeF          ;Is OBJECT file of type REL?
            bpl    L25AA           ;No
;
            jsr    L25C6           ;Modify SymbolicName & update EXTRN recs
            jmp    L25AD
;
L25AA       jsr    L2856           ;Report undefined symbol
;
L25AD       jsr    IncrXtnP        ;Next EXTRN record
            jmp    Phs2Loop        ;Loop back
;
; We have finished scanning through all EXTRN recs
;
DonePhs2    bit    FTypeF          ;Is OBJECT file of type REL?
            bpl    GoPhase3        ;No
;
; Write a tempESD file for unreferenced ENTRY
; & unresolved EXTRN recs
;
            jsr    L26DE           ;Open tempESD file for writing
            jsr    L2763           ;Use info fr unresolved EXTRNs &
            jsr    L2719           ; unreferenced ENTRYs to write file
            jsr    L27AC           ;Mark EO ESD and close tempESD file
;
GoPhase3    jmp    DoPhase3
            REP    50
;
; An EXTRN Symbol cannot be found in ENTRY table
; Modify its EXTRN rec & related SymbolicName rec
; Input
;  XtnRecP - Ptr to a record of EXTRN table
;  XtnNbr  - EXTRN count
; Output
;  SymP - Ptr to a record of SymbolicName table
;  (Y)=0
; The structure of SymbolicName table will be modified.
; Only 2 bytes are used viz.
; offset 0 - len byte -> EXTRN #
; offset 1 - 1st char whose msb is off -> msb on
;
L25C6       EQU    *
            ldy    #0
            lda    (XtnRecP),y     ;Get ptr to the SymbolicName rec
            sta    SymP
            iny
            lda    (XtnRecP),y
            sta    SymP+1
            ldy    #1              ;Skip its len byte
            lda    (SymP),y        ;Is msb of 1st char off?
            bpl    L25DD           ;Yes
            dey
            lda    (SymP),y        ;No, get EXTRN #
            jmp    L25EA
;
L25DD       inc    XtnNbr          ;EXTRN #
            bne    L25E4
            jmp    ExtrnErr        ;>255 EXTRN's in REL output ESD
;
L25E4       ora    #$80            ;Set 1st char's msb to 1
            sta    (SymP),y
            lda    XtnNbr          ;EXTRN #
L25EA       ldy    #7
            sta    (XtnRecP),y
            ldy    #0
            sta    (SymP),y        ;Overwrite len byte w/EXTRN #
            rts
            REP    50
;
; Check if a SymbolicName is present in
; one of the recs of ENTRY table ($4700)
; Input
;  SymP - ptr to a SymbolicName rec
;
; Output
;  Z=1 - Yes
;  Z88 - Ptr to the ENTRY record
; (Y)=0
; Uses a brute force method to search for the key
; The search is conducted record by record until
; no more records are left to be processed
;
ScanEntTbl  EQU    *
            lda    #>EntTbl        ;Start search fr BO ENTRY table
            sta    Z88
            lda    #<EntTbl
            sta    Z88+1
;
ScanEntLup  ldy    #0
            lda    (SymP),y        ;Get len byte of symbolicname
            cmp    (Z88),y
            bne    NoHit           ;Definitely no match
            cmp    #15+1
            bcc    DoCmp
            lda    #15             ;At most 15 chars to be compared
DoCmp       tax
CmpLoop     iny
            lda    (SymP),y        ;Compare symbolic name
            cmp    (Z88),y
            bne    NoHit           ;No match
            dex
            bne    CmpLoop
;
            ldy    #0              ;Z=1 ==> hit
            rts
;
NoHit       lda    #24             ;Pointer size = 24 bytes
            ldx    #Z88            ;Ptr to be adjusted
            jsr    IncRecPZ        ;Adv to next ENTRY record (Z88++)
            ldy    #0
            lda    (Z88),y         ;Get symbol's len byte fr ENTRY rec
            bne    ScanEntLup      ;No EOT, so try again
            ldy    #0
            lda    #1              ;Z=0 ==> Not found
            rts
;=================================================
; Search if EXTRN symbol's name is in SymbolicName table ($9200)
; Input
; Output
; On return
; (Y)=0
; Z=1 match
; (Z88) - ptr to symbolicname record
;
L2629       EQU    *
            lda    #>SymTbl        ;SymbolicName table
            sta    Z88
            lda    #<SymTbl
            sta    Z88+1
            jmp    L2657
;
L2634       ldy    #0
            lda    (SymP),y        ;Get len byte
            cmp    (Z88),y
            bne    L2650
            cmp    #16
            bcc    L2642
;
            lda    #15
L2642       tax
L2643       iny
            lda    (SymP),y
            cmp    (Z88),y
            bne    L2650           ;No match
            dex
            bne    L2643
;
            ldy    #0              ;Z=1
            rts
;
L2650       lda    #16             ;Pointer size
            ldx    #Z88
            jsr    IncRecPZ        ;Adv to next SymbolicName record
;
L2657       lda    Z88             ;Is EOT?
            cmp    SymP            ;NB. This rec has yet to be "added"
            bne    L2634
            lda    Z88+1           ; to the SymbolicName table
            cmp    SymP+1
            bne    L2634           ;No, keep searching
;
            ldy    #0
            lda    #1              ;Z=0
            rts
;=================================================
; Modify the ENTRY and EXTRN records by setting up
; the necessary links.
; If more than one EXTRN records refer to the ENTRY
; rec, then we setup a singly-linked list to link
; all the EXTRN recs. The field "first" will 
; point to the first EXTRN rec & the field "last"
; point to the last EXTRN rec in the singly-linked list
; 
; Input
;  (XtnRecP) - Ptr to a EXTRN record
;  (Z88)     - Ptr to an ENTRY record
; Output
;
; Prepare to add a new node (in the form of an EXTRN rec)
; to the singly-linked list.  The link to a SymbolicName
; rec in the EXTRN rec is now called "next" (variant rec
; in Pascal, union in C)
;
L2668       EQU    *
            ldy    #0
            lda    #$00            
            sta    (XtnRecP),y     ;Set "next" link to NIL
            iny
            sta    (XtnRecP),y
            iny                    ;2
            lda    Z88             ;Ptr to ENTRY record whose symbolicname
            sta    (XtnRecP),y     ; matches that of the XtnRecP
            iny                    ;3
            lda    Z88+1
            sta    (XtnRecP),y
;
            ldy    #5
            lda    (XtnRecP),y     ;Get symbol-type flag byte
            and    #$7F            ;Now symbol is defined
            sta    (XtnRecP),y
            and    #%00000001      ;Has the meaning of bit0 changed?
            ldy    #17
            eor    (Z88),y         ;Symbol-type flag byte of ENTRY rec
            and    #%00000001
            beq    L2690           ;Yes
            jsr    L287B           ;size mismatch
;
L2690       ldy    #17
            lda    (Z88),y
            and    #%01000000      ;unreferenced?
            beq    L26B2           ;No => already referenced
            eor    (Z88),y         ;Clear unreferenced bit
            sta    (Z88),y         ; but retain the other bits
;
; The ENTRY rec is referenced the 1st time
; so create a singly-linked list by
; setting the first and last link to point
; to the same EXTRN rec
;
            ldy    #20             ;first link
            lda    XtnRecP
            sta    (Z88),y         ;Ptr to EXTRN record
            iny
            lda    XtnRecP+1
            sta    (Z88),y         ;Store in ENTRY rec
;
            iny                    ;last link
            lda    XtnRecP         ;Ptr to same EXTRN record
            sta    (Z88),y
            iny                    ;23
            lda    XtnRecP+1
            sta    (Z88),y
            rts
;
; The ENTRY symbol has been referenced more than once
; We add the new node to the end of the singly-linked list
;
L26B2       ldy    #22
            lda    (Z88),y         ;Get ptr to "last" EXTRN record
            sta    Z82             ;Save it for later (prev)
            lda    XtnRecP
            sta    (Z88),y         ;Set the "last" link to point
            iny                    ;23
            lda    (Z88),y         ; to this EXTRN record
            sta    Z82+1
            lda    XtnRecP+1       ; which now the last node 
            sta    (Z88),y         ;in the singly-linked list
;
            ldy    #0
            lda    XtnRecP         ;(Z82) - previously the "last" EXTRN record
            sta    (Z82),y         ;Replace its "next" link (which was NIL)
            iny
            lda    XtnRecP+1       ; with ptr to this EXTRN record
            sta    (Z82),y
            rts
            REP    50
;
; Copy to pathame buf
;
L26D1       ldy    TempESD         ;len byte
L26D4       lda    TempESD,y
            sta    PathNameB,y
            dey
            bpl    L26D4
            rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Open a temporary binary ESD file for output
; This rtn will be called if there are unresolved
; EXTRN symbols
;
; Output
;  (Z86) - ptr to tmpESD data buffer
; Write1P+c.refNum  - EXTRN # used to write tempESD file
;
L26DE       EQU    *
            jsr    L26D1           ;Set PN to "EDASM.TEMPESD"
            jsr    PRODOS8         ;DESTROY
            DB     $C1
            DW     DestryP
;
            lda    #0
            sta    CreateP+c.auxId ;auxtype
            sta    CreateP+c.auxId+1
            lda    #BINtype
            sta    CreateP+c.fileId
            jsr    PRODOS8         ;CREATE
            DB     $C0
            DW     CreateP
            beq    L26FF
            jsr    ErrHndlr        ;Don't come back
;
L26FF       jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     Open3P
            beq    L270A
            jsr    ErrHndlr        ;Don't come back
;
L270A       lda    Open3P+c.outRef
            sta    Write1P+c.refNum;write RN for tempESD file
L2710       lda    #>X9100         ;Reset to BO data buf
            sta    Z86             ; b4 next ESD rec is created
            lda    #<X9100
            sta    Z86+1
            rts
            REP    50
;
; Scan through the ENTRY table for recs whose
; SymboliName remained unreferenced. Output info
; to tempESD file
; Input
; Output
;
L2719       EQU    *
            lda    #>EntTbl
            sta    Z8E             ;Point @ BO ENTRY table
            lda    #<EntTbl
            sta    Z8E+1           ;=> re-cycled zp loc
;
L2721       jsr    PollKbd
            ldy    #17
            lda    (Z8E),y         ;Get ENTRY record's flag byte
            bit    ERefF           ;Include ENTRY records in tempESD file?
            bmi    L2733           ;Yes
            and    #$40            ;Is its SymbolicName still unreferenced?
            bne    L2733           ;Yes
            jmp    L2755
;
L2733       jsr    L27DE           ;Copy symbolicname to tmpESD area
            tya                    ;Save len of symbolicname name
            pha
            ldy    #17
            lda    (Z8E),y         ;Get ENTRY record's flag byte again
            and    #%00111111      ;Clear undefined/unreferenced bits
            sta    ESDRec
            iny
            lda    (Z8E),y
            sta    ESDRec+1        ;Relocated addr
            iny
            lda    (Z8E),y
            sta    ESDRec+2
            pla
            tay                    ;Restore Y
            jsr    L2818           ;Add ENTRY data to tempESD data buf
            jsr    L27C1           ;Write out to tempESD file
;
L2755       lda    #24             ;Pointer size
            ldx    #Z8E
            jsr    IncRecPZ        ;Next ENTRY record
            ldy    #0
            lda    (Z8E),y         ;Is EOT?
            bne    L2721           ;No
            rts
            REP    50
;
; Scan through the EXTRN table for recs whose
; SymboliName remained undefined. Output info
; to tempESD file
; Input
; Output
;
L2763       EQU    *
            lda    #>XtnTbl
            sta    XtnRecP
            lda    #<XtnTbl
            sta    XtnRecP+1
;
L276B       jsr    PollKbd
            ldy    #5
            lda    (XtnRecP),y     ;flag byte
            beq    L27AB
            and    #$80            ;Undefined?
            beq    L27A5           ;No
;
            ldy    #0
            lda    (XtnRecP),y     ;Ptr to symbolicname
            sta    SymP
            iny
            lda    (XtnRecP),y
            sta    SymP+1
            ldy    #1              ;Unnecessary instruction
            lda    (SymP),y        ;Get its 1st char
            bpl    L27A5
            and    #$7F
            sta    (SymP),y        ;reset its msb
;
            lda    #SPACE
L278F       iny
            cmp    (SymP),y        ;Look for 1st trailing blank
            beq    L2799           ;Got it
            cpy    #15
            bcc    L278F
;
            iny                    ;No trailing blanks
L2799       dey
            tya                    ;len of symbolicname
            ldy    #0
            sta    (SymP),y        ;Overwrite the EXTRN # with len byte
            jsr    L27FC           ;Create a ESD rec (variable in size)
            jsr    L27C1           ;Write ESD data to file
L27A5       jsr    IncrXtnP        ;Next EXTRN record
            jmp    L276B
L27AB       rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;  (Z86) - ptr to tmpESD buffer
; Output
;
L27AC       EQU    *
            lda    #$00            ;Marks eo ESD
            tay
            sta    (Z86),y
            inc    Z86
            bne    L27B7
            inc    Z86+1
L27B7       jsr    L27C1           ;Flush the tempESD file
            lda    Write1P+c.refNum;Close tempESD file
            jsr    ClsFile
            rts
;=================================================
; Write out data to tempESD binary file
; Input
;  (Z86)-ptr to record in tempESD table
; Output
;
L27C1       EQU    *
            lda    Z86
            sec
            sbc    #>X9100         ;Start of buffer
            sta    Write1P+c.reqCnt;writelen
            lda    Z86+1
            sbc    #<X9100
            sta    Write1P+c.reqCnt+1
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write1P
            beq    L27DB
            jsr    ErrHndlr        ;Don't come back
L27DB       jmp    L2710
            REP    50
;
; Copy symbolicname to tmpESD data buffer
; Input
;  (SymP) - ptr to symbolicname record
;  (Z86)  - ptr to tempESD buffer ($9100)
; Output
; (Y)     - len of symbolicname
;
L27DE       EQU    *
            ldy    #0
            lda    (SymP),y        ;Get len byte of symbolicname
            cmp    #16
            bcc    L27E8
;
; Transfer a p-string to the temp ESD data buf
; The chars of the resulting string will
; have msbs on except the last one
;
            lda    #15
L27E8       tax                    ;Make into a counter
L27E9       iny
            lda    (SymP),y        ;Get char
            ora    #$80            ;Set msb on
            dey
            sta    (Z86),y
            iny
            dex
            bne    L27E9
;
            dey
            and    #$7F
            sta    (Z86),y         ;msb of last char is off
            iny                    ;len of symbolicname
            rts
            REP    50
;
; Make a ESD record for output (of unresolved EXTRNS)
; Input
;  XtnRecP - ptr to record in EXTRN table
;  Z86     - ptr to record in tempESD table
; Output
;
L27FC       EQU    *
            jsr    L27DE           ;Copy symbolicname
            tya                    ;len of symbolicname
            pha
            ldy    #5
            lda    (XtnRecP),y
            and    #%00111101
            sta    ESDRec          ;flag byte
            ldy    #7
            lda    (XtnRecP),y     ;EXTRN #
            sta    ESDRec+1
            lda    #0
            sta    ESDRec+2        ;Not used
            pla
            tay
;
; Common code for appending an ESD rec using
; info fr a rec of EXTRN/ENTRY table
; (Y) = len of symbolicname
;
L2818       EQU    *
            lda    ESDRec
            sta    (Z86),y
            iny
            lda    ESDRec+1
            sta    (Z86),y
            iny
            lda    ESDRec+2
            sta    (Z86),y
            iny
            tya                    ;total size of ESD rec
            ldx    #Z86
            jsr    IncRecPZ        ;Adv the ptr
            rts
            REP    50
; Input
; Output
; Store duplicate ENTRY symbol associated messages
;
StorDupSym  jsr    StorERR
            ldy    #$12            ;dup ENTRY symbol
            jsr    StorMsg
            jsr    StorName
            ldy    #$13            ;of module #
            jsr    StorMsg
            jsr    StorRFNbr
            ldy    #$14            ;in module #
            jsr    StorMsg
            ldy    #16
            lda    (EntRecP),y     ;REL file #
            ldy    #0              ;zero ten's digit
            jsr    L3079           ;Store 2-byte ASC char in LinkMap
            jsr    StorCR
            rts
            REP    50
; Input
; Output
; Store undefined EXTERN symbol associated messages
;
L2856       jsr    StorERR
            ldy    #$15            ;undef EXTRN symbol
            jsr    StorMsg
            lda    SymP            ;ptr to symbolicname
            sta    Z88
            lda    SymP+1
            sta    Z88+1
            jsr    StorName        ;Store symbolic name
;
            ldy    #$14            ;in mod #
            jsr    StorMsg
            ldy    #4
            lda    (XtnRecP),y     ;Get src file #
            ldy    #0              ;Zero ten's digit
            jsr    L3079           ;Convert to 2-byte ASCII char
            jsr    StorCR
            rts
            REP    50
; Input
; Output
L287B       jsr    StorERR
            ldy    #$1D            ;mismatch REF-DEF size
            jsr    StorMsg
            jsr    StorName
            ldy    #$14            ;in mode #
            jsr    StorMsg
            ldy    #4
            lda    (XtnRecP),y     ;Get REL file #
            ldy    #0              ;Zero ten's digit
            jsr    L3079           ;Convert
            jsr    StorCR
            rts
            REP    50
; Store "ERR:" to LinkMap file
; Input
; Output
;
StorERR     lda    #'E'
            jsr    StorChar
            lda    #'R'
            jsr    StorChar
            jsr    StorChar
            lda    #':'
            jmp    StorChar
            REP    50
; Store to LinkMap file
; Input
; Output
;
StorMsgY    bit    MapFileF        ;Store in file LinkMAP
            bpl    L28CD           ;No, ret
            jsr    StorMsg
            jmp    StorCR
            REP    50
; ($28B4) Write Message to LinkMap file
; Input
; Output
; (Y)-index into message sub-tables
;
StorMsg     lda    MsgTLo,y
            sta    MsgP
            lda    MsgTHi,y
            sta    MsgP+1
            ldy    #0
L28C0       lda    (MsgP),y
            cmp    #'\'            ;eol
            beq    L28CD
            jsr    StorChar
            iny
            jmp    L28C0           ;next char
L28CD       rts
;=================================================
; Phase 3 of the Linking process
; Relocate the object code. The RLD of each src file
; is used to relocate the code from each file. Code
; fr src files whose names are preceded by an ; in
; the cmd file are not included in the OBJECT file.
; Mem reserved for the SymbolicName table is re-used
; as a data buf. 256 bytes of the code image of
; a src file are read into this area first b4
; being move forward into previous mem page
; for patching.
;
; Input
; Output
;  ModNbr  - # of src files
;  CurrORG - Starting PC for curr src file
;  (Z96)
;  (LwrBound)
;  (UprBound,9C)
;
DoPhase3    EQU    *
            ldy    #$06            ;Relocating objcode...
            jsr    DspMsg
            jsr    DspCR
            ldy    #$06
            jsr    StorMsgY
;
            lda    #0
            sta    ModNbr
            sta    Z96             ;EO REL-type OBJECT file
            sta    Z96+1
;
            lda    Origin
            sta    CurrORG         ;Starting PC
            lda    Origin+1
            sta    CurrORG+1
            jsr    MovObjFN        ;Set to "EDASM.LINKOBJ"
            jsr    PRODOS8         ;DESTROY
            DB     $C1
            DW     DestryP
;
            lda    Origin
            sta    CreateP+c.auxId
            lda    Origin+1
            sta    CreateP+c.auxId+1;auxtype
            lda    TrgtFTyp        ;filetype of OBJECT file
            sta    CreateP+c.fileId
            jsr    PRODOS8         ;CREATE
            DB     $C0
            DW     CreateP
            bne    L2919
;
            jsr    PRODOS8         ;OPEN the OBJECT file
            DB     $C8
            DW     Open3P
            beq    L291C
;
L2919       jsr    ErrHndlr        ;Don't come back
;
L291C       lda    Open3P+c.outRef ;OBJECT file
            sta    Write1P+c.refNum;RN to write OBJECT file
            bit    FTypeF          ;What is the OBJECT file type?
            bpl    L294A           ;=>BIN/SYS
;
            lda    #$00            ;REL OBJECT file
            sta    X9100
            sta    X9100+1
            sta    Write1P+c.reqCnt+1;Write 2 zeroes for
            lda    #$02            ; the code image len
            sta    Write1P+c.reqCnt
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write1P
            beq    L2941
            jsr    ErrHndlr        ;Don't come back
;
L2941       lda    WrMapFP+c.refNum
            jsr    ClsFile
            jsr    OpTmpRLD        ;Open a tempRLD file 4 writing
;
L294A       jsr    L343B           ;Set file posn to BO cmd file
;
; Skip all directives at the BO cmd file
; to get at the src pathnames
;
L294D       jsr    Read1Cmd        ;Get a src filename
            bne    Phs3Loop        ;Not cr/space => pathname
            cmp    #CR
            bne    L294D           ;A leading space, skip to the directive
            jmp    CmdOrderErr     ;Invalid cmd order
;
; Mainloop for phase 3
;
Phs3Loop    jsr    DspLineB        ;Show PN of the curr src
            jsr    OpenSrc         ;Open it 4 reading 
            bit    Z9E             ;Is src PN preceded by ;?
            bpl    L296C           ;No
;
            lda    OpSrcFP+c.outRef;Close it
            jsr    ClsFile
            jmp    L2B55           ;Skip reading fr it
;
L296C       lda    #2
            clc
            adc    SrcCodeLen      ;Set file posn to BO
            sta    SMSrcFP+c.mark
            lda    #0
            adc    SrcCodeLen+1
            sta    SMSrcFP+c.mark+1; Relocation Dictionary
;
            lda    OpSrcFP+c.outRef
            sta    SMSrcFP+c.refNum
            sta    RdCodeImgP+c.refNum
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMSrcFP
            beq    L2991
L298E       jsr    ErrHndlr        ;Don't come back
;
L2991       jsr    L3348           ;Have we read entire RLD?
            bcc    L2999           ;Yes
            jsr    ErrHndlr        ;Don't come back
;
L2999       lda    #2              ;Set file posn to BO
            sta    SMSrcFP+c.mark  ; code image of src file
            lda    #0
            sta    SMSrcFP+c.mark+1
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMSrcFP
            bne    L298E
;
            lda    #0
            sta    LwrBound
            sta    LwrBound+1
            sta    UprBound
            sta    UprBound+2
            jsr    Rd1PgImg        ;Read the first $100 bytes of code image
;
; Loop to process all recs in the RLD of curr src file
;
L29B8       jsr    PollKbd
            ldy    #0
            lda    (SrcP),y        ;Get flag byte fr RLD record
            sta    RLDFlags
            bne    L29C7
            jmp    L2B13           ;EO RLD => done w/this src file
;
; The code below doesn't check for overflow
; What happens if field offset is a #
; > $6EFF?
;
L29C7       ldy    #1
            lda    (SrcP),y
            sta    Z80             ;Field offset in code image
            clc
            adc    #>X9100
            sta    Z86
            iny
            lda    (SrcP),y
            sta    Z80+1
            adc    #<X9100
            sta    Z86+1           ;$9100-$FFFF?
;
; Check if the field offset is within the "window"
; bounds LwrBound and UprBound. Since no effort is made
; to check the lower bound, it is assumed that the
; field offset is past this when (Z80) < UprBound
; It is also assumed that all records (in the RLD) have been
; arranged with field offsets in ascending order
;
L29DB       lda    Z80             ;Is field offset < upper bounds?
            cmp    UprBound
            lda    Z80+1
            sbc    UprBound+2
            bcc    L29EB           ;Yes, within the "window"
            jsr    L2AA0           ;No, read another page of code
            jmp    L29DB           ; and check again
;
; The ptr Z86 could be calculated by
; (Z86)=(Z80) - (LwrBound) + $9100
;
L29EB       sec
            lda    Z86
            sbc    LwrBound
            sta    Z86             ;Z86 -= LwrBound
            lda    Z86+1           ;If there is no overflow above,
            sbc    LwrBound+1
            sta    Z86+1           ; then $9100 =< (Z86) =< $91FF
;
            bit    FTypeF          ;REL OBJECT file?
            bpl    L2A0E           ;No => BIN/SYS
;
            ldy    #2
            lda    Z80             ;Field offset
            clc
            adc    Z96             ;Len of Code Image of
            pha
            lda    Z80+1           ; REL OBJECT file excluding
            adc    Z96+1           ; that of curr src file
            sta    (SrcP),y        ;Patch field offset of RLD record
            dey                    ;Y=1
            pla
            sta    (SrcP),y
;
L2A0E       bit    RLDFlags        ;Is size of relocatable field 2?
            bmi    L2A54           ;Yes
;
            ldy    #0              ;Get original addr (lo/hi) 
            lda    (Z86),y         ; byte fr the code image
            bit    RLDFlags        ;Is it hi-8 of addr?
            bvs    L2A31           ;Yes
;
; (A) has the lo-8 of the addr (fr a > byte operator)
; Since only the lobyte is used to patch the code
; any value for the hibyte can be used. So let's
; use 0 as RelAdrHi
;
            sta    RelAdr
            lda    #$00
            sta    RelAdr+1
            jsr    L30D9           ;Calc/get relocated addr
            ldy    #0
            lda    RelAdr          ;Use the lo 8-bit to
            sta    (Z86),y         ; patch the code image
            jmp    L2A96           ;Skip code below
;
; (A) has the hi-8 of the addr (fr a < byte operator)
; For this case, we need both the low & high bytes
; of the original addr if relocation rec is not
; flagged as EXTRN symbol-type
;
L2A31       sta    RelAdr+1        ;hi-byte
            ldy    #3
            lda    (SrcP),y        ;lo 8-bits/EXTRN symbol #
            sta    RelAdr
            lda    RLDFlags        ;Get RLD flag byte
            and    #$10            ;EXTRN symbol-type?
            beq    L2A47           ;No
;
            lda    #$00
            sta    RelAdr          ;Overwrite EXTRN symbol #
;
; On fall thru, the relocated addr will not be
; calculated but obtained fr an ENTRY rec if
; it is available.
;
L2A47       jsr    L30D9           ;Calc/get the relocated addr
            ldy    #0
            lda    RelAdr+1
            sta    (Z86),y         ;Patch code image
            jmp    L2A96           ;Skip code below
;
; Size of relocatable field is 2
; Get relocated addr fr the RLD rec
;
L2A54       ldy    #0
            lda    RLDFlags        ;Get RLD rec's flag byte
            and    #$20            ;Normal/Reversed order?
            bne    L2A7B
            lda    (Z86),y         ;Little Endian (reversed order)
            sta    RelAdr          
            iny
            lda    (Z86),y
            sta    RelAdr+1
            jsr    L30D9           ;Calc/get relocated addr
;
            ldy    #0
            lda    RelAdr
            sta    (Z86),y         ;Patch the code
            iny
            lda    RelAdr+1
            sta    (Z86),y
            jmp    L2A96           ;=>next RLD
;
; Handle a Big Endian
;
L2A7B       lda    (Z86),y
            sta    RelAdr+1        ;hiaddr
            iny
            lda    (Z86),y
            sta    RelAdr          ;loaddr
            jsr    L30D9           ;Calc/get relocated addr
            ldy    #0
            lda    RelAdr+1
            sta    (Z86),y         ;Patch the code
            iny
            lda    RelAdr
            sta    (Z86),y
;
L2A96       lda    #4              ;Pointer size
            ldx    #SrcP
            jsr    IncRecPZ        ;Adv SrcP to next RLD rec
            jmp    L29B8           ; loop back to process it
            REP    50
;
; Flush object code if neccessary. Move buffered
; code forward into "window" so that another page
; of code image can be read into the $9200 data buffer
; The variables LwrBound & UprBound gives a "window"
; into the code image.
; Normally (UprBound - LwrBound) = $100 except when
; the last (partial) page of code is read. In this
; case (UprBound - LwrBound) < $100 
; Input
;  LwrBound -
;  UprBound -
; Output
;  UprBound -
;
L2AA0       EQU    *
            lda    UprBound        ;Do we need to flush OBJECT code b4
            ora    UprBound+2      ; b4 we "move" our window forward?
            beq    L2AA9           ;No, we are still @ BO of src file
            jsr    L2AD8           ;Yes
;
L2AA9       ldy    #0              ;Move buffered Code Image
L2AAB       lda    X9200,y         ; forward into our "window"
            sta    X9100,y         ; @ $9100-$91FF so we can
            iny
            bne    L2AAB
            jsr    Rd1PgImg        ; load another page @ $9200
;
            lda    UprBound
            sta    LwrBound
            lda    UprBound+2
            sta    LwrBound+1
            inc    UprBound+2      ; Incr by 1 page
;
            lda    UprBound
            cmp    SrcCodeLen      ;Has the entire code
            lda    UprBound+2
            cmp    SrcCodeLen+1    ; image been read?
            bcc    L2AD7           ;No
;
            lda    SrcCodeLen
            sta    UprBound        ;This may no longer be
            lda    SrcCodeLen+1
            sta    UprBound+2      ; 1 mempage > LwrBound
L2AD7       rts
            REP    50
; Write object code @ $9100
; Input
; Output
;
L2AD8       EQU    *
            sec
            lda    UprBound
            sbc    LwrBound
            sta    Write1P+c.reqCnt;# of bytes to write
            lda    UprBound+2
            sbc    LwrBound+1
            sta    Write1P+c.reqCnt+1; usually $100 bytes
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write1P
            beq    L2AD7
;
L2AEF       jsr    ErrHndlr        ;Don't come back
;
; Read $100 bytes of data into buf starting @ $9200
; fr src file. The symbolicname table @ $9200 is
; re-used as a Read data buf
; Output
;  Z=1
; (A) = $4C if EOF or
;     = $00 read succeeded
;
Rd1PgImg    EQU    *
            lda    #0
            sta    RdCodeImgP+c.reqCnt
            lda    #1
            sta    RdCodeImgP+c.reqCnt+1
            lda    #>X9200         ;Read Data Buf
            sta    RdCodeImgP+c.dataBuf
            lda    #<X9200
            sta    RdCodeImgP+c.dataBuf+1
            jsr    PRODOS8         ;READ
            DB     $CA
            DW     RdCodeImgP
            beq    L2AD7           ;If no errs, just ret
;
            cmp    #$4C            ;EOF?
            bne    L2AEF           ;No -> err handler
            rts
;
; Skip rest of code image
;
L2B13       EQU    *
            lda    UprBound
            cmp    SrcCodeLen
            bne    L2B21
            lda    UprBound+2
            cmp    SrcCodeLen+1
            beq    L2B27           ;Done w/this src file
L2B21       jsr    L2AA0           ;Keep flushing objcode N reading code image
            jmp    L2B13           ; until we are done
;
L2B27       jsr    L2AD8           ;Append rest of OBJECT code
            lda    RdCodeImgP+c.refNum
            jsr    ClsFile
            jsr    Add2TmpRLD      ;Append patched RLD @ SrcDBuf
;
            ldx    ModNbr
            lda    CurrORG         ;Starting posn counter
            sta    OrgAdrLo,x      ; for this src file
            lda    CurrORG+1
            sta    OrgAdrHi,x
            jsr    L2BA2           ;adj pc?
;
            lda    CurrORG+1
            sta    EndAdrHi,x
            lda    CurrORG
            sta    EndAdrLo,x
            bne    L2B52
            dec    EndAdrHi,x      ;End posn counter
L2B52       dec    EndAdrLo,x      ; for this src file
;
L2B55       inc    ModNbr          ;Next src module
L2B58       jsr    Read1Cmd        ;Is it a pathname?
            bne    L2B9C           ;Yes, prepare to loop back
            cmp    #CR
            beq    DonePhs3        ;Empty line => Finish all cmds
            jsr    IsALN           ;Is it Align directive?
            bcc    L2B69           ;Possible
            jmp    DoBreak         ;Don't comeback
;
L2B69       beq    L2B6E           ;Align option
            jmp    CmdOrderErr     ;cmd order err
;
L2B6E       lda    CurrORG         ;Already aligned @ start of mempage?
            beq    L2B58           ;Yes, read another cmd line
;
            ldx    #0
            txa
L2B75       sta    X9100,x
            inx
            bne    L2B75
;
            lda    #0
            sec
            sbc    CurrORG
            sta    Write1P+c.reqCnt;# of zero bytes to fill
            sta    SrcCodeLen      ; Re-used
            lda    #0
            sta    Write1P+c.reqCnt+1
            sta    SrcCodeLen+1    ;Used by $2BA2
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write1P
            bne    L2B9F
;
            jsr    L2BA2           ;Adj PC
            jmp    L2B58           ;Read next cmd line
;
L2B9C       jmp    Phs3Loop        ;Loop back to process new src file
;
L2B9F       jsr    ErrHndlr        ;Don't come back
            REP    50
; Adjust file posn
; Input
; Output
; (Z96) - curr val of code image len
;
L2BA2       lda    SrcCodeLen
            clc
            adc    CurrORG
            sta    CurrORG         ;CurrORG += SrcCodeLen
            lda    SrcCodeLen+1
            adc    CurrORG+1
            sta    CurrORG+1
            bit    FTypeF          ;REL OBJECT file?
            bpl    L2BC4           ;No -> exit
;
            clc
            lda    SrcCodeLen
            adc    Z96
            sta    Z96             ;Z96 += SrcCodeLen
            lda    SrcCodeLen+1
            adc    Z96+1
            sta    Z96+1
L2BC4       rts
;
; Prepare to exit Phase 3
;
DonePhs3    bit    FTypeF          ;REL OBJECT file?
            bpl    L2BD8           ;No
;
            ldy    #0
            sty    SrcDBuf
            sty    Write2P+c.reqCnt+1
            iny                    ;=1
            sty    Write2P+c.reqCnt;# of bytes to write=1
            jsr    L31C1           ;Marks EO RLD file
;
L2BD8       bit    FTypeF          ;Is REL OBJECT file?
            bmi    DoPhase4        ;Yes
            jmp    L2C8E
;=================================================
; Phase 4 of the Linking process done only if
; the OBJECT file is of type REL
; Contents of TempRLD and TempESD files are appended
; to the relocatable OBJECT file
; Input
; Output
;
DoPhase4    ldy    #$07
            jsr    DspMsg
            jsr    DspCR
            lda    Write2P+c.refNum;RN of tempRLD file
            sta    SMarkP+c.refNum
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMarkP          ;Set file posn to BO tempRLD file
            beq    L2BF8
            jsr    ErrHndlr        ;Don't come back
;
L2BF8       jsr    L2C5A           ;Append tempRLD to REL OBJECT file
            lda    Write2P+c.refNum
            jsr    ClsFile         ;Now close tempRLD file
            jsr    PollKbd
            jsr    L26D1           ;Set PN to TempESD
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     Open2P
            beq    L2C12
            jsr    ErrHndlr        ;Don't come back
;
L2C12       lda    Open2P+c.outRef
            sta    Write2P+c.refNum
            jsr    L2C5A           ;Append TempESD to REL OBJECT file
            lda    Write2P+c.refNum
            jsr    ClsFile         ;Now close tempESD
;
            lda    Open3P+c.outRef
            sta    SMarkP+c.refNum ;Posn to BO REL OBJECT file
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMarkP
            beq    L2C32
            jsr    ErrHndlr        ;Don't come back
;
L2C32       lda    Z96             ;Write the CodeImage Len
            sta    X9100
            lda    Z96+1           ; of REL OBJECT file
            sta    X9100+1
            lda    #0
            sta    Write1P+c.reqCnt+1
            lda    #2
            sta    Write1P+c.reqCnt;2 bytes only
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write1P
            beq    L2C51
            jsr    ErrHndlr        ;Don't come back
;
L2C51       jsr    PollKbd
            jsr    L31CD           ;Open LinkMap file for appending
            jmp    L2C8E
            REP    50
;
; ($2C5A) Read entire contents of tempRLD/tempESD
; and append it to the OBJECT file (which is of
; type REL)
; Input
; Output
;
L2C5A       lda    Write2P+c.refNum;RN of tempRLD/tempESD file
            sta    RWFileP+c.refNum
            jsr    L334E           ;Read data chunk fr file
            php                    ;Save for later
            bcc    L2C6D
            cmp    #$10
            beq    L2C6D           ;Not EOF
            jsr    ErrHndlr        ;Don't come back
;
L2C6D       lda    Open3P+c.outRef ;OBJECT file's RN
            sta    RWFileP+c.refNum;Write same data chunk
            lda    RWFileP+c.transCnt
            sta    RWFileP+c.reqCnt
            lda    RWFileP+c.transCnt+1
            sta    RWFileP+c.reqCnt+1;to the OBJECT file
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     RWFileP
            beq    L2C8A
            jsr    ErrHndlr        ;Don't come back
L2C8A       plp                    ;Has last chunk been read?
            bcs    L2C5A           ;No, do another chunk
            rts
;
L2C8E       EQU    *
            lda    Open3P+c.outRef ;Finally, close OBJECT file
            jsr    ClsFile
            bit    FTypeF          ;Was it relocatable OBJECT file?
            bpl    L2C9D           ;No
;
            ldy    #$07            ;Phase 4...
            jsr    StorMsgY
L2C9D       bit    MapFileF        ;Output to LinkMap?
            bmi    L2CA4           ;Yes
            jmp    L2E10
;
L2CA4       bit    SortLMF         ;Sort LoadMap table?
            bmi    DoPhase5        ;Yes
            jmp    L2E10
;=================================================
; Phase 5 of the Linking process
; Sort Relocated Adr table
; First create a LoadMap table of 4-byte records
; The LoadMap table starts @ $9100
; Layout of each record is:
;   DW ptr to an ENTRY table rec
;   DW relocated addr stored in the ENTRY table rec
;
; Output:
;  (EntRecP) - ptr to a rec in ENTRY table
;  (Z86)     - ptr to a rec in LoadMap table
;  (Z80)     - ptr to EO LoadMap table
;
DoPhase5    ldy    #$08
            jsr    DspMsg
            jsr    DspCR
            ldy    #$08
            jsr    StorMsgY
;
            lda    #>EntTbl        ;ENTRY table is still in mem
            sta    EntRecP         ;Set up a ptr to its beginning
            lda    #<EntTbl
            sta    EntRecP+1
            lda    #>X9100         ;4-byte records in LoadMap table
            sta    Z86
            lda    #<X9100
            sta    Z86+1
            lda    #0              ;Total # of records in
            sta    NumRecs         ; ENTRY table to be sorted
            sta    NumRecs+1
;
; The code below builds the unsorted LoadMap table
;
L2CCE       jsr    PollKbd
            ldy    #0
            lda    (EntRecP),y     ;EO ENTRY table?
            beq    L2D03           ;Yes
;
            lda    EntRecP
            sta    (Z86),y         ;Points to record in ENTRY table
            iny
            lda    EntRecP+1
            sta    (Z86),y
;
            ldy    #18
            lda    (EntRecP),y     ;Get relocated addr associated with
            pha
            iny
            lda    (EntRecP),y     ; the SymbolicName of the ENTRY rec
            ldy    #3
            sta    (Z86),y         ; and store in LoadMap record
            pla
            dey
            sta    (Z86),y
;
            lda    #4              ;Pointer size
            ldx    #Z86
            jsr    IncRecPZ        ;Adv to next LoadMap rec
            jsr    IncrEntP        ;Adv to next ENTRY record
            inc    NumRecs         ;rec count
            bne    L2D00
            inc    NumRecs+1
L2D00       jmp    L2CCE           ;Continue to build LoadMap table
;
; Initial LoadMap table has been build
;
L2D03       ldy    #0
            tya                    ;(A)=0
            sta    (Z86),y         ;Mark EO LoadMap table
            iny
            sta    (Z86),y         ;with a NIL ptr
;
            lda    Z86
            sta    Z80             ;(Z80)=EO LoadMap table
            lda    Z86+1
            sta    Z80+1
            jsr    SortLM          ;Sort it
            jmp    L2E10
            REP    50
; Sort the Load (addr) Map
; Shell-Metzner Sort
; Input
; Output
;
SortLM      EQU    *
            lda    NumRecs         ;Jump=# of elements N
            sta    Jump
            lda    NumRecs+1
            sta    Jump+1
;
; While Jump <> 0
;
WhileLoop   lsr    Jump+1          ;Jump=Jump div 2
            ror    Jump
            lda    Jump
            ora    Jump+1
            bne    L2D2C
            rts
;
L2D2C       sec
            lda    NumRecs
            sbc    Jump
            sta    EndIdx
            lda    NumRecs+1
            sbc    Jump+1
            sta    EndIdx+1
;
            ldx    #0
            stx    StrtIdx+1
            inx
            stx    StrtIdx
ForLoop     jsr    PollKbd
;
; FOR JJJ := 1 to NumRecs-Jump
;
            lda    StrtIdx
            sta    JJJ
            lda    StrtIdx+1
            sta    JJJ+1
;
; REPEAT
;
RptLoop     clc
            lda    JJJ
            adc    Jump
            sta    III             ;I=J+Jump
            lda    JJJ+1
            adc    Jump+1
            sta    III+1
;
            ldx    #3
L2D5A       lda    JJJ,x
            sta    J.TH,x
            dex
            bpl    L2D5A
;
; Mulby4 and add to X9100-4
; Calc indices to the elements to be compared
; (J.TH) - Ptr to j-th element
; (I.TH) - Ptr to i-th element
;
            ldx    #2
L2D63       asl    J.TH,x          ;x4
            rol    J.TH+1,x
            asl    J.TH,x
            rol    J.TH+1,x
;
            clc
            lda    #>X9100-4
            adc    J.TH,x
            sta    J.TH,x
            lda    #<X9100-4
            adc    J.TH+1,x
            sta    J.TH+1,x
            dex
            dex
            beq    L2D63
;
            bit    NumSortF
            bpl    L2D98
;
; Sort load addresses numerically in ascending order
;
            ldy    #3
            lda    (J.TH),y        ;Get load addr (Hibyte)
            cmp    (I.TH),y
            beq    L2D8D
            bcs    L2D94           ;Greater than
L2D8A       jmp    NextJ           ;Less than
L2D8D       dey
            lda    (I.TH),y        ;Get load addr (lobyte)
            cmp    (J.TH),y
            bcs    L2D8A           ;Less than
L2D94       ldy    #3
            bne    L2DD3           ;Always -> Swap the records
;
; Sort SymbolicName alphabetically
; IF ENTRY[J].name > ENTRY[I].name then SWAP(Ary[J], Ary[I])
; The 1st field of an ENTRY rec is a 16-byte p-string
;
L2D98       ldy    #0
            lda    (J.TH),y        ;Get ptr to j-th 
            tax                    ; ENTRY rec
            iny
            lda    (J.TH),y
            sta    EntRPJ+1
            stx    EntRPJ
            lda    (I.TH),y
            tax
            dey                    ;=0
            lda    (I.TH),y        ;Get ptr to i-th 
            sta    EntRPI          ; ENTRY rec
            stx    EntRPI+1
            lda    (EntRPJ),y      ;Get len byte of symbolic name
            cmp    (EntRPI),y
            beq    L2DB8
            bcc    L2DB8
;
            lda    (EntRPI),y      ;The len of this symbolic name is shorter
L2DB8       tax                    ;# of chars to compare
            iny                    ;=1
L2DBA       lda    (EntRPJ),y      ;Get char fr symbolic name
            cmp    (EntRPI),y
            bne    L2DCF           ;Not match
            iny
            cpy    #16             ;At most 15 chars will be compared
            bcs    NextJ           ;All chars matched
            dex
            bne    L2DBA
            lda    #SPACE
            cmp    (EntRPJ),y
            beq    NextJ
            sec                    ;Flag we have to do a swap
L2DCF       bcc    NextJ           ;C=0 -> 1st symbolic name < 2nd
;
; Swap the records in LoadMap
; Too costly to swap those in ENTRY table
;
            ldy    #3
L2DD3       lda    (J.TH),y        ;Swap the ptrs as
            tax
            lda    (I.TH),y
            sta    (J.TH),y        ; well as the corr addrs
            txa
            sta    (I.TH),y
            dey
            bpl    L2DD3
;
            sec
            lda    JJJ             ;J > Jump
            sbc    Jump
            sta    JJJ
            lda    JJJ+1
            sbc    Jump+1          ;J := J - Jump
            sta    JJJ+1           ;Is J > Jump?
            bmi    NextJ           ;No, less than
            ora    JJJ
            beq    NextJ           ;No, J=Jump
            jmp    RptLoop
;
; UNTIL JJJ =< Jump
;
NextJ       inc    StrtIdx
            bne    L2DFC
            inc    StrtIdx+1
;
L2DFC       lda    StrtIdx+1       ;Finis w/FOR loop
            cmp    EndIdx+1
            bcc    L2E0D
            beq    L2E07
L2E04       jmp    WhileLoop       ;No
L2E07       lda    EndIdx
            cmp    StrtIdx
            bcc    L2E04
L2E0D       jmp    ForLoop
;-----
L2E10       bit    MapFileF        ;Write LinkMap?
            bmi    DoPhase6        ;Yes
            jmp    OK2Exit
;=================================================
; Phase 6 of the Linking process
; Makes use of LoadMap table to store info
; into the LinkMap txtfile
;
DoPhase6    ldy    #$09
            jsr    DspMsg
            jsr    DspCR
            ldy    #$09
            jsr    StorMsg
            jsr    StorCR
            jsr    L343B           ;Reset to BO cmd line file
            jsr    StorCR
            jsr    StorCR
            lda    #0
            sta    ModNbr
            sta    L380F           ;counter
            sta    PageF           ;Don't output to printer
;
L2E3A       jsr    PollKbd
            jsr    Read1Cmd
            bne    L2E4F           ;If non-blank & not cr, it's a PN
            cmp    #CR             ;Is 1st char a CR?
            bne    L2E49           ;No, a leading space, ignore it
            jmp    L2ED3           ;No more directives
L2E49       jsr    StorCmd         ;Just store cmd in LinkMap file
            jmp    L2E3A           ;Get another command
;
; Got the Pathname of a src file
;
L2E4F       jsr    StorCR
            jsr    StorCR
            ldy    #$18            ;MOD ORG etc
            jsr    StorMsg
            ldy    #$19            ;# ADR ADR etc
            jsr    StorMsg
            jsr    StorCR
            jmp    L2E76           ;-> proceed to start storing info
;
; Loop to get the PN of another src file
;
L2E65       jsr    PollKbd
            jsr    Read1Cmd
            bne    L2E76           ;Not cr/space
            cmp    #CR
            beq    L2ED3           ;No more commands => done
            jsr    L2F43           ;Set module's Addr Range
            beq    L2E88           ;always
;
; Start writing info into LinkMap file
;
L2E76       jsr    StorSpc
            lda    ModNbr
            jsr    StorByte
            jsr    StorSpc
            jsr    StorSpc
;
            ldx    L380F           ;Get src file index
L2E88       lda    OrgAdrHi,x      ;Start Addr
            jsr    StorByte
            lda    OrgAdrLo,x      ; of this src module
            jsr    StorByte
;
            lda    #'-'
            jsr    StorChar
            lda    EndAdrHi,x      ;Its End Addr
            jsr    StorByte
            lda    EndAdrLo,x
            jsr    StorByte
            jsr    StorSpc
            jsr    StorSpc
;
            ldy    #0
L2EAD       jsr    ChrGot          ;Store PN
            cmp    #CR
            beq    L2EBA
            jsr    StorChar
            iny
            bne    L2EAD
;
L2EBA       jsr    StorCR
            cpx    L380F
            bne    L2ED0
;
            sed
            lda    ModNbr
            clc
            adc    #1
            sta    ModNbr
            cld
            inc    L380F
L2ED0       jmp    L2E65           ;Loop back for next module
;
L2ED3       bit    XRefF           ;Did user ask for xferencing?
            bpl    ExitPhs6        ;No
;
            lda    #$80
            sta    PageF
            jsr    L2FE4           ;Store header details etc...
            bit    SortLMF         ;Did we sort the LoadMap table?
            bpl    L2F09           ;No
;
; Use Sorted LoadMap table
;
            lda    #>X9100
            sta    Z86
            lda    #<X9100         ;Points to BO LoadMap table
            sta    Z86+1
L2EEA       jsr    PollKbd
            ldy    #0
            lda    (Z86),y         ;Get ptr to ENTRY record
            sta    Z88
            iny
            lda    (Z86),y
            sta    Z88+1           ; and store it here
            ora    Z88             ;EO ENTRY table?
            beq    ExitPhs6        ;Yes
;
            jsr    L2F74           ;Write details of ENTRY rec into LinkMap
            lda    #4              ;Pointer size
            ldx    #Z86            ; Z86++
            jsr    IncRecPZ        ;Next LoadMap record
            jmp    L2EEA
;
; Use ENTRY table instead of LoadMap table
;
L2F09       lda    #>EntTbl        ;Points to BO of ENTRY table
            sta    Z88
            lda    #<EntTbl
            sta    Z88+1
;
L2F11       jsr    PollKbd
            ldy    #0
            lda    (Z88),y         ;EOT?
            beq    ExitPhs6        ;Yes
            jsr    L2F74           ;Store details of ENTRY rec into LinkMap
            ldx    #Z88
            lda    #24             ;Pointer size
            jsr    IncRecPZ        ;Next ENTRY record
            jmp    L2F11           ;Continue until EO ENTRY Table
            REP    50
; Prepare to exit Linker
; Input
; Output
;
ExitPhs6    EQU    *
            lda    #FF
            jsr    StorChar
            jsr    StorCR
            lda    WrMapFP+c.refNum;Close LinkMap txt file
            sta    CloseP+c.refNum
            jsr    PRODOS8         ;CLOSE
            DB     $CC
            DW     CloseP
            beq    OK2Exit
            jsr    ErrHndlr        ;Don't come back
;
OK2Exit     jmp    DoExit          ;Do an orderly exit
            REP    50
; Get ORG and END addrs of the module
; Z=0, (X)=0
;
L2F43       EQU    *
            ldy    #$05            ;Write 5 blanks to LinkMap
            jsr    StorSpcsY
            ldx    L380F           ;Get src file index (1-49)
            dex                    ;Index previous src module
            ldy    EndAdrHi,x
            lda    EndAdrLo,x
            tax
            inx
            bne    L2F57
            iny
L2F57       stx    OrgAdrLo
            sty    OrgAdrHi
;
            ldx    L380F
            ldy    OrgAdrHi,x
            lda    OrgAdrLo,x
            tax
            bne    L2F6A
            dey
L2F6A       dex
            stx    EndAdrLo
            sty    EndAdrHi
            ldx    #$00
            rts
            REP    50
; Store info from ENTRY record
; Input
; Output
;
L2F74       EQU    *
            jsr    L300B           ;Store space/?
            jsr    StorAdr         ;Relocated addr
            jsr    StorRFNbr       ;File #
            jsr    StorSpc
            jsr    StorName        ;Symbolicname
            jsr    StorSpc
            jsr    L3029           ;list of references
            jsr    StorCR
            rts
            REP    50
;
; Store a byte as a couple of ASC Hex digits
; Input
;  (A)=byte
;
StorByte    EQU    *
            pha
            lsr    a
            lsr    a
            lsr    a
            lsr    a
            jsr    StorHex
            pla
            and    #$0F
            jsr    StorHex
            rts
            REP    50
; Store char into LinkMap buf. If char is CR,
; the text line will be written out to file
; Input
;  WrMapFIdx - Write Map file buf index
; Output
; A,X preserved
; Y may not be used
;
StorChar    and    #$7F
            sta    Z9C             ;Save A,X regs
            stx    Z9C+1
            ldx    WrMapFIdx
            sta    MapFDB,x        ;store in buf
            inc    WrMapFIdx       ;incr # of chars/buf index
            cmp    #CR
            bne    L2FBD
;
; Flush it
;
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     WrMapFP
            beq    L2FBA
            jsr    ErrHndlr        ;Don't come back
;
L2FBA       sta    WrMapFIdx       ;Zero write buf index
L2FBD       ldx    Z9C+1
            lda    Z9C
            rts
            REP    50
;
; Convert a 8-bit binary value into its
; ASCII representation of 1's and 0's
; Input
; Output
;
L2FC2       EQU    *
            ldx    #8
L2FC4       asl    a               ;Get bit into Carry
            pha
            lda    #$00
            rol    a               ;Catch the bit
            adc    #'0'            ;'0' or '1'
            jsr    StorChar
            pla
            dex
            bne    L2FC4           ;Next bit
            rts
            REP    50
; ($2FD3) Store a CR to LinkMap file
; Input
; Output
;
StorCR      lda    #CR
            jsr    StorChar
            inc    LineCnt
            lda    LineCnt
            cmp    #60
            bne    L2FE3
            jsr    L2FE4           ;Write subtitle
L2FE3       rts
            REP    50
; Store subtitle into LinkMap file
; Input
; Output
;
L2FE4       lda    #FF             ;Output a formfeed char
            jsr    StorChar
            lda    #3
            sta    LineCnt
            sed
            clc
            lda    #1
            adc    PageCnt
            sta    PageCnt
            cld
            bit    PageF
            bpl    L3004
;
            ldy    #$1A            ;Write 'ADR M# SYMBOL...' string
            jsr    StorMsg         ; to LinkMap txt file
            lda    PageCnt
            jsr    StorByte
;
L3004       jsr    StorCR
            jsr    StorCR
            rts
            REP    50
; Input
; Output
;
L300B       EQU    *
            ldy    #17
            lda    (Z88),y         ;Get flag byte
            and    #%01000000      ;Was symbol referenced?
            beq    StorSpc         ;Yes, use a space
            lda    #'?'
            bne    L3019           ;Use a Qn mark
            REP    50
; Store a space into LinkMap txt file buffer
;
StorSpc     EQU    *
            lda    #SPACE
L3019       jsr    StorChar
            rts
            REP    50
; Input
;  (A)=$00-$0F
; Output
;
StorHex     EQU    *
            ora    #'0'
            cmp    #'9'+1
            bcc    L3025
            adc    #$06
L3025       jsr    StorChar
            rts
            REP    50
; Store list of references to the relocated addr
; $40 set -> not referenced by any module
; Input
; Output
;
L3029       EQU    *
            ldy    #17
            lda    (Z88),y         ;Get flag byte
            and    #%01000000
            beq    L3037
            ldy    #$16            ;unreferenced
            jsr    StorMsg
            rts
;
L3037       lda    Z88             ;Ptr to ENTRY record
            sta    XtnRecP
            lda    Z88+1
            sta    XtnRecP+1
;
            ldy    #20
L3041       lda    (XtnRecP),y     ;Ptr to linked list
            pha
            iny
            lda    (XtnRecP),y     ; of EXTRN records
            sta    XtnRecP+1
            pla
            sta    XtnRecP
            ora    XtnRecP+1
            beq    L3072           ;NIL => end of linked list
;
            ldy    #4
            lda    (XtnRecP),y     ;(A)=# to be converted
            ldy    #0              ;ten's digit
            jsr    L3079
            jsr    StorSpc
            lda    WrMapFIdx       ;# of bytes in Map file's data buf
            ldy    #0
            cmp    #77             ; must not exceed this number
            bcc    L3041           ;Next node
;
            jsr    StorCR
            ldy    #26             ;# of spaces
            jsr    StorSpcsY
            ldy    #0
            jmp    L3041           ;Next Node in linked list
L3072       rts
            REP    50
; Store REL file # as a 2-byte ASC char in LinkMap file
; Input
; Output
;
StorRFNbr   ldy    #16
            lda    (Z88),y         ;REL file #
            ldy    #0
L3079       cmp    #10
            bcc    L3084
            sec
            sbc    #10
            iny                    ;ten's digit
            jmp    L3079
;
L3084       pha                    ;unit's digit
            tya
            ora    #'0'
            jsr    StorChar
            pla
            ora    #'0'
            jsr    StorChar
            rts
            REP    50
; Store ENTRY record's name
; Input
;  (Z88) - ptr to ENTRY record
; Output
;
StorName    EQU    *
            ldy    #0
            lda    (Z88),y         ;len byte
            cmp    #16
            bcc    L309C
;
            lda    #15             ;At most 15
L309C       tax
L309D       iny
            lda    (Z88),y         ;symbolname
            jsr    StorChar
            dex
            bne    L309D
;
            sty    SymLen          ;# of chars stored so far
            sec
            lda    #16
            sbc    SymLen
            tay                    ;# of spaces to store
;
; Enter here with (Y)=# of space to store
;
StorSpcsY   EQU    *
            lda    #SPACE
            jsr    StorChar
            dey
            bne    StorSpcsY
            rts
            REP    50
; Store Relocated address in LinkMap file
; Input
;  (Z88)-ptr to ENTRY record
; Output
;
StorAdr     EQU    *
            ldy    #19
            lda    (Z88),y         ;Relocated Addr
            jsr    StorByte
            dey
            lda    (Z88),y         ;of this ENTRY record
            jsr    StorByte
            jsr    StorSpc
            rts
            REP    50
; Store cmd line incl terminating CR
; Input
;  (cp)
; Output
;
StorCmd     EQU    *
            ldy    #0
L30CC       lda    (cp),y
            and    #$7F
            jsr    StorChar
            iny
            cmp    #CR
            bne    L30CC
            rts
            REP    50
; If an RLD entry of src file flag its an 
; (a) ENTRY symbol, calc relocated addr
; (b) EXTRN symbol, get relocated addr
;     fr its associated ENTRY rec &
;     we must modify the 
;     RLD & EXTRN recs
; Input
;  RLDFlags
; Output
;  RelAdr - value of relocated addr
;
L30D9       EQU    *
            lda    RLDFlags
            and    #$10            ;Is EXTERN symbol?
            bne    L3105           ;Yes
;
            lda    RelAdr          ;This is equiv to a subtraction
            clc
            adc    NegSrcOrg       ;2's complement of
            sta    RelAdr
            lda    RelAdr+1
            adc    NegSrcOrg+1     ; origin in src file
            sta    RelAdr+1
;
            lda    RelAdr
            clc
            adc    CurrORG
            sta    RelAdr
            lda    RelAdr+1
            adc    CurrORG+1
            sta    RelAdr+1
            rts
;
; EXTRN symbol
;
L3105       ldy    ModNbr          ;Get ptr to the
            lda    SrcModTLo,y     ; first EXTRN rec
            sta    XtnRecP         ; of curr src file
            lda    SrcModTHi,y
            sta    XtnRecP+1
;
; Search thru the EXTRN recs for the EXTRN symbol #
; NB. A hit is guaranteed during the search
; through the sub-array of EXTRN recs
;
            lda    #0
            sta    RelAdr
            sta    RelAdr+1
            ldy    #3              ;Get the EXTRN symbol #
            lda    (SrcP),y        ; fr RLD record of src file
L311E       ldy    #6
            cmp    (XtnRecP),y
            beq    L312A           ;Matched
            jsr    IncrXtnP
            jmp    L311E           ;Try next EXTRN rec
;
L312A       ldy    #5
            lda    (XtnRecP),y     ;symbol type
            and    #%10111111      ;Clear unreferenced bit
            sta    (XtnRecP),y
            and    #$80            ;Is the symbolicname still undefined?
            bne    L316D           ;Yes
;
            ldy    #2
            lda    (XtnRecP),y     ;Get ptr to associated
            sta    Z82             ; ENTRY record
            iny
            lda    (XtnRecP),y
            sta    Z82+1
;
            ldy    #18
            lda    (Z82),y         ;Get relocated addr fr ENTRY record
            sta    RelAdr          ;lo
            iny
            lda    (Z82),y
            sta    RelAdr+1        ;hi
;
            bit    FTypeF          ;Is it OBJECT file relocatable?
            bpl    L3179           ;No, just ret
;
; The OBJECT file is of type REL
; We need to patch the curr RLD rec
;
            ldy    #0              ;Get flag byte fr
            lda    (SrcP),y        ; RLD rec of src file
            and    #%11101111      ;Mark symbol is no
            sta    (SrcP),y        ; longer EXTRN-type since
            ldy    #3              ; symbolicname is defined
            and    #%11000000
            cmp    #$40            ;lo 8 bits?
            bne    L3166           ;=>hi 8 bits
;
            lda    RelAdr          ; Use lo 8-bits to patch
            DB     $2C
L3166       lda    #0              ;Use 0 to patch
            sta    (SrcP),y        ;  the RLD record
            jmp    L3179           ;Done
;
; The symbolicname had not been defined
;
L316D       bit    FTypeF
            bpl    L3179
;
; If the target OBJECT file is REL then
; patch the RLD entry of the src file
; Once again we assume the RLD is < 5K
; since the patched RLD was written out only
; when processing of the src file is complete
;
            ldy    #7              ;Get the EXTRN # that
            lda    (XtnRecP),y     ; was assigned by the Linker
            ldy    #3              ; & replace that in the RLD rec which
            sta    (SrcP),y        ; was assigned by the Assembler
L3179       rts
            REP    50
; Setup to open and write a TempRLD binary file
; Input
; Output
; Write2P+c.refNum - RN to write tempRLD file
;
OpTmpRLD    EQU    *
            ldy    TempRLD
L317D       lda    TempRLD,y
            sta    PathNameB,y
            dey
            bpl    L317D
;
            jsr    PRODOS8         ;DESTROY
            DB     $C1
            DW     DestryP
            lda    #BINtype
            sta    CreateP+c.fileId
            jsr    PRODOS8         ;CREATE
            DB     $C0
            DW     CreateP
            beq    L319C
            jsr    ErrHndlr        ;Don't come back
;
L319C       jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     Open2P
            beq    L31A7
            jsr    ErrHndlr        ;Don't come back
;
L31A7       lda    Open2P+c.outRef
            sta    Write2P+c.refNum;write RN of tempRLD file
            rts
            REP    50
; Append patched RLD of curr src file to the tempRLD file
; Input
; Output
;
Add2TmpRLD  EQU    *
            bit    FTypeF          ;Is OBJECT file of type REL?
            bpl    L31CC           ;No
;
            sec
            lda    SrcP
            sbc    #>SrcDBuf
            sta    Write2P+c.reqCnt;writelen
            lda    SrcP+1
            sbc    #<SrcDBuf
            sta    Write2P+c.reqCnt+1
;
; Write to tempRLD file
;
L31C1       EQU    *
            jsr    PRODOS8         ;WRITE
            DB     $CB
            DW     Write2P
            beq    L31CC
            jsr    ErrHndlr        ;Don't come back
L31CC       rts
            REP    50
; Open the LinkMap file and set the
; file posn to its EOF
; 
; Input
; Output
;
L31CD       EQU    *
            jsr    MovMapFN        ;Set PN to LinkMap
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     Open2P
            beq    L31DB
            jsr    ErrHndlr        ;Don't come back
;
L31DB       lda    Open2P+c.outRef
            sta    WrMapFP+c.refNum
            sta    GeofP+c.refNum
            jsr    PRODOS8         ;GET_EOF
            DB     $D1
            DW     GeofP
            beq    L31EF
            jsr    ErrHndlr        ;Don't come back
;
L31EF       jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     GeofP           ;Set to EO LinkMap file
            beq    L31FA
            jsr    ErrHndlr        ;Don't come back
L31FA       rts
            REP    50
; Check if cmd line is Align Command/Directive
; Input
; Output
;   Z=1 & C=0 - yes
;
IsALN       EQU    *
            jsr    DspLineB
            jsr    SkipSpcs
            jsr    ChkDrtv         ;Check directive
            bcs    L3209           ;Unknown cmd
            cmp    #5              ;ALN directive
            clc
L3209       rts
;=================================================
; ($320A) Load EDASM's Editor
;=================================================
LoadED      EQU    *
            jsr    PfxEdAsm        ;Set prefix to EdAsm's dir
            bcc    LoadED2
            lda    #$FE
            jsr    PrtError
;
            ldy    #0
            ldx    EdAsmDir
PrtLoop     lda    EdAsmDir+1,y
            jsr    DspChar
            iny
            dex
            bne    PrtLoop
;
            jsr    DspCR
            lda    #$FD            ;Output thru Interpreter's
            jsr    PrtError
;
KeyLoop     lda    KBD
            bpl    KeyLoop
            bit    KBDSTROBE       ;Clear it
            cmp    #CR+$80
            bne    KeyLoop
            jsr    DspCR
            jmp    LoadED          ;Try again
;
LoadED2     lda    #>LoadAdrEd
            sta    EdLoadAdr
            lda    #<LoadAdrEd
            sta    EdLoadAdr+1
;
            lda    #>$2000
            sta    EdRdLen
            lda    #<$2000
            sta    EdRdLen+1
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     OpenEdP
            beq    Opened1
            jsr    FatalErr
;
Opened1     lda    EdRefNbr
            sta    RdEdRefNbr
            jsr    PRODOS8         ;READ
            DB     $CA
            DW     RdEdP
            beq    Loaded1
            jsr    FatalErr
;
Loaded1     lda    RdEdRefNbr
            sta    CloseP+c.refNum
            jsr    PRODOS8         ;CLOSE
            DB     $CC
            DW     CloseP
            beq    Closed1
            jmp    FatalErr
;
Closed1     jsr    S2CurrPfx
            bcs    FatalErr
;=================================================
; Setup memory map for Editor/Command Interpreter
;=================================================
            lda    #%11111111      ;$FF
            sta    BitMap+20
            lda    #%00011111      ;$1F
            sta    BitMap+19
            lda    #%01111111      ;$7F
            sta    BitMap+22
            lda    #%10000001      ;$81
            sta    BitMap+23
;
; TxtBgn=$0801
;
            lda    #CR
            dec    TxtBgn          ;Put a CR @ $0800
            ldy    #$00
            sta    (TxtBgn),y
            inc    TxtBgn          ; and @ $0801
            sta    (TxtBgn),y
            rts
;=================================================
FatalErr    EQU    *
            sta    $FE             ;Save err code
            tsx
            stx    $FF             ;Save stack ptr
;
            ldx    #$80
            txs
            lda    RDROM2          ;Read ROM; no write
            jsr    SETKBD          ;reset input to keyboard
            jsr    SETVID          ;reset output to screen
            jsr    HOME            ;home cursor and clear screen
            jsr    PRERR           ;print "ERR"
            jmp    MON             ;std monitor entry w/beep
;=================================================
; Set prefix to EDASM's dir
;=================================================
PfxEdAsm    EQU    *
            jsr    PRODOS8         ;SET_PREFIX
            DB     $C6
            DW     EdAsmPfxP
            rts
;=================================================
; Set prefix to current prefix
;=================================================
S2CurrPfx   EQU    *
            jsr    PRODOS8         ;SET_PREFIX
            DB     $C6
            DW     SCurrPfx
            rts
;=================================================
; EDASM Editor's parameter blocks
;=================================================
EditorS     STR    'EDASM.ED'
            DB     $00
;
OpenEdP     DB     $03
            DW     EditorS
            DW     XA900           ;1024-byte buffer
EdRefNbr    DB     $CB
;
RdEdP       DB     $04
RdEdRefNbr  DB     $D0
EdLoadAdr   DW     $A0A0
EdRdLen     DW     $A0D3           ;Caller must set this
            DW     $CBA0           ;actual len read
;
EdAsmPfxP   DB     $01
            DW     EdAsmDir
;
SCurrPfx    DB     $01
            DW     CurrPfxB
;=================================================
; Move a block of src code fr one mem location to
; another mem location (not including byte @
; location (Z80)
; Input
;  SrcP - Start addr of data
;  Z80  - End addr of data 
;  Z82  - Destination addr
; Output
;  (Z82)
;  (SrcP)
;  (Y)=0
;
MovData     EQU    *
            ldy    #0
MovLoop3    lda    (SrcP),y
            sta    (Z82),y
            inc    Z82
            bne    Bump2
            inc    Z82+1
Bump2       lda    SrcP            ;Copy until
            cmp    Z80
            lda    SrcP+1
            sbc    Z80+1           ; (Z80)=(SrcP)
            inc    SrcP
            bne    Bump3
            inc    SrcP+1
Bump3       bcc    MovLoop3
            rts
;=================================================
; This rtns adjust the ptrs to the next
; element of their respective arrays
;
IncrXtnP    EQU    *
            pha                    ;Save
            lda    #8              ;rec size
            ldx    #XtnRecP        ;EXTRN table
            jmp    IncRecP
;
IncrEntP    EQU    *
            pha
            lda    #24
            ldx    #EntRecP        ;ENTRY table
            jmp    IncRecP
;
IncrSymP    EQU    *
            pha                    ;Save
            lda    #16
            ldx    #SymP           ;SymbolicName table
;
; (A)=# to add to pointer stored in 2 consecutive mem locations
; (X)=offset into zero page
;
IncRecP     EQU    *
            clc
            adc    $00,x
            sta    $00,x
            lda    #0
            adc    $01,x
            sta    $01,x
            pla                    ;Restore
            rts
            REP    50
;
; Input
; (A)=# to add to pointer stored in 2 consecutive mem locations
; (X)=offset into zero page
; Output
; Same logic as above except (X) can be an index into
; ANY zeropage location
;
IncRecPZ    pha
            jmp    IncRecP
            REP    50
; 
; Advance SrcP to next ESD record
; Input
; Output
; X - unchanged
;
NxtESDRec   EQU    *
            ldy    #0
BumpLoop    lda    (SrcP),y        ;symbolicname
            bpl    GotLastCh       ;Got last char
            iny
            jmp    BumpLoop
;
GotLastCh   iny
            iny
            iny
            iny
            tya
            clc
            adc    SrcP            ;SrcP now pointing @ next ESD
            sta    SrcP
            lda    #0
            adc    SrcP+1          ; record in the curr src file
            sta    SrcP+1
            rts
;=================================================
; There are 3 entry points in this part of the code
; Input
;  OpSrcFP+c.outRef - file ref # of src (REL) file
; Output
;  C=0           - Last chunk of data had been read
;  C=1 & (A)=$10 - Not EOF
;  C=1 & (A)=$4C - EOF
;  (SrcP) points to BO SrcDBuf
;=================================================
L3348       EQU    *
            lda    OpSrcFP+c.outRef
            sta    RWFileP+c.refNum
;
; Use this entry point to attempt to read a fixed chunk
; of data (equal to the size of the data buffer) fr a
; ANY file into the beginning of the Data Buffer ($0C00)
; (SrcP) points to BO of this data buf (SrcDBuf)
;
L334E       EQU    *
            lda    #>SrcDBuf
            sta    RWFileP+c.dataBuf
            lda    #<SrcDBuf
            sta    RWFileP+c.dataBuf+1
;
            lda    #>FileDBSiz     ;# of bytes to be read=5K
            sta    RWFileP+c.reqCnt
            lda    #<FileDBSiz
            sta    RWFileP+c.reqCnt+1
;
; Use this entry point to read a chunk of data fr ANY file.
; Caller must set the # of bytes to read (reqCnt) in 
; RWFile parm block.
; (SrcP) is set to point to BO SrcDBuf ($0C00)
;
ReadCode    EQU    *
            lda    #>SrcDBuf
            sta    SrcP
            lda    #<SrcDBuf
            sta    SrcP+1
            jsr    PRODOS8         ;READ
            DB     $CA
            DW     RWFileP
            bne    ReadErrs        ;If EOF, (A)=$4C and C=1
;
; After a successful read, at most NumRead = ReqLen
; For this case, there may be more data to be read
;
            lda    RWFileP+c.transCnt+1;If actual # of bytes read
            cmp    RWFileP+c.reqCnt+1; = requested len then
            bne    L3382           ; it may not be EOF since
            lda    RWFileP+c.transCnt
            cmp    RWFileP+c.reqCnt
            beq    L3384           ; there may be more data to be read
;
L3382       clc                    ;Not =, ==> last chunk of data read
            rts                    ; since NumRead < ReqLen
L3384       lda    #$10            ;= but not EOF, so use $10 to flag it
ReadErrs    sec
            rts
;=================================================
; Print Message
; The terminating char of each message in
; this table is a backslash
; Input
; Output
; (Y)=index into Message Table whose addresses
; are split into 2 sub-tables
;
DspMsg      EQU    *
            lda    MsgTLo,y
            sta    MsgP
            lda    MsgTHi,y
            sta    MsgP+1
            ldy    #0
DspLoop     lda    (MsgP),y
            cmp    #'\'            ;terminator
            beq    DspMsgX
            jsr    CharOut
            iny
            jmp    DspLoop
DspMsgX     rts
;=================================================
; Setup the filename using a cmd line
; Input
; Output
;
GetSrcPN    EQU    *
            ldy    #-1
MovLoop4    iny
            lda    (cp),y
            and    #$7F
            sta    PathNameB+1,y
            cmp    #CR             ;CR
            bne    MovLoop4
            sty    PathNameB       ;len byte
            rts
;=================================================
; Open a src file by getting its filename from
; the command file
; Get len of its code image and compute the
; addr past its last byte.
; Input
; Output
; C=1 - err
; (A)=err code
; (Z9E)=$80 - src file will be read but EXTRN records will
; not be created fr its ESD. Its code will not be included into
; the OBJECT file. ENTRY and SymbolicName records are created.
; This may be used to facilitate overlays rather than
; hand-patching JSR/JMP etc addresses
; Todo: Check it
; NB: SymbolicName records are created fr info in the
; appended ESD of all src files.
;
OpenSrc     EQU    *
            ldy    #0
            sty    Z9E
            lda    (cp),y
            cmp    #'*'
            bne    L33C8
            inc    cp              ;Skip to next char
            bne    L33C4
            inc    cp+1
L33C4       lda    #$80            ;Flag code from src file
            sta    Z9E             ; will NOT be included in OBJ file
;
L33C8       jsr    GetSrcPN        ;First get the src file's name
            jsr    PRODOS8         ;OPEN
            DB     $C8
            DW     OpSrcFP
            bne    L341F
;
            jsr    PRODOS8         ;GET_FILE_INFO
            DB     $C4
            DW     GFISrcFP
            bne    L341F
;
            lda    #$11            ;Check filetype
            ldy    SrcType
            cpy    #RELtype
            bne    L341F           ;filetype mismatch
;
            lda    OpSrcFP+c.outRef;Prepare to read 1st 2 bytes of this
            sta    RCodeLenP+c.refNum; file which is len of code image
            jsr    PRODOS8         ;READ
            DB     $CA
            DW     RCodeLenP
            bne    L341F
;
            lda    SrcCodeLen
            clc
            adc    SrcORG          ;Value of last ORG in this src file
            sta    L3806           ; Addr+1 of last byte of code image
            lda    SrcCodeLen+1
            adc    SrcORG+1
            sta    L3806+1
;
            lda    SrcORG          ;Perform 2's complement of the
            eor    #$FF
            sta    NegSrcOrg       ; the Last ORG adr of src file
            lda    SrcORG+1
            eor    #$FF
            sta    NegSrcOrg+1
            inc    NegSrcOrg
            bne    L341D
            inc    NegSrcOrg+1
L341D       clc
            rts
L341F       sec
            rts
            REP    50
; ($3421) Read in a line of text from command file
; See description below
;
Read1Cmd    EQU    *
            jsr    PRODOS8         ;READ
            DB     $CA
            DW     RdCmdFP
            beq    L3446
;
            cmp    #$4C            ;Is it EOF?
            beq    L3430           ;Yes
            jsr    ErrHndlr        ;Don't come back
;
L3430       jsr    L343B           ;Reset file posn to BO src file
            lda    #CR             ;Store CR @ BO buffer to
            sta    CmdLineB        ; denote an empty (blank) line
            jmp    L3446           ;Set cp to point @ cmd line buf
            REP    50
; ($343B) Reset file position to BO of command file
; Output
;  cp  - ptr to 1st char of Cmd Line
;  (A) - 1st char
;  Z=1 - 1st char is CR/SPACE
;  Z=0 - Otherwise
;
L343B       EQU    *
            jsr    PRODOS8         ;SET_MARK
            DB     $CE
            DW     SMCmdFP
            beq    L3446
            jsr    ErrHndlr        ;Don't come back
;
L3446       EQU    *
            lda    #>CmdLineB
            sta    cp
            lda    #<CmdLineB
            sta    cp+1
;
            ldy    #0
            lda    (cp),y          ;Get 1st char of cmd line
            cmp    #SPACE
            beq    L3458
            cmp    #CR             ;Z=1
L3458       rts
;=================================================
; ($3459)
; Input
; (A)=file ref #
; Output
;
ClsFile     EQU    *
            sta    CloseP+c.refNum
            jsr    PRODOS8         ;CLOSE
            DB     $CC
            DW     CloseP
            beq    L3467
            jsr    ErrHndlr        ;Don't come back
L3467       rts
            REP    50
; Display contents of Command Line Buffer
; Input
;  cp - ptr to the cmdline buf
; (A) & (P) are preserved
;
DspLineB    EQU    *
            php                    ;Save Status reg
            pha                    ;Save char
            lda    #SPACE
            jsr    CharOut
            jsr    CharOut
            jsr    CharOut
            jsr    CharOut
            jsr    CharOut
;
            ldy    #0
DspLoop2    lda    (cp),y
            and    #$7F
            jsr    CharOut
            iny
            cmp    #CR             ;If not terminating cr,
            bne    DspLoop2        ; get next char
            pla
            plp
            rts
;=================================================
; Parse directive field
; Input
;  cp - pointing @ 1st char of cmdline's
;       directive field
; Output
;  C=0, (A)-index into JMP table
;  C=1 - Unknown command
;=================================================
ChkDrtv     EQU    *
            ldx    #-1
NxtDrtv     ldy    #0
CmpLoop2    inx
            lda    DirectvT,x
            beq    CmdError        ;EOT
            lda    (cp),y
            cmp    DirectvT,x
            beq    Bump5           ;Got a match
            cpy    #3              ;Did we have a 3-char match?
            bne    SkipEntry       ;No, try next entry
            cmp    #CR             ;EO cmd line?
            beq    GotEntry        ;Yes
Bump5       iny                    ;Bump index to next char
            cpy    #4
            bcc    CmpLoop2
            beq    GotEntry        ;All chars match including trailing space
;
SkipEntry   cpy    #3
            beq    NxtDrtv         ;Loop back to check another entry
            inx
            iny
            bne    SkipEntry       ;Skip rest of entry
;
CmdError    ldy    #$1B            ;Unknown cmd
            jsr    DspMsg
            sec
            rts
;
GotEntry    txa                    ;Compute index
            lsr    a
            lsr    a
            clc
            rts
;=================================================
; Start fr beginning of Cmd Line, skip blanks
; Output
;   Z=1 - CR/SPACE
; 
SkipSpcs    EQU    *
            ldy    #0
SkipLoop2   lda    (cp),y
            cmp    #SPACE
            bne    AdvCP
            iny
            bne    SkipLoop2
;
; In case we can't find a non-blank, fall
; thru to start searching fr the 2nd char
; Output
;   (Y) - indexing the 1st non-blank
;   (A) - non-blank char
;
WhiteSpc    EQU    *
            ldy    #0
EatLoop     iny
            lda    (cp),y
            cmp    #SPACE
            beq    L34D8
            cmp    #CR
            bne    EatLoop
L34D8       rts                    ;Z=1 if CR/SPACE
;
; Advance cmd line buffer pointer (cp)
; Input
;  (Y) - # of chars to advance
; Output
;  (Y) = 0
;
AdvCP       EQU    *
            tya
            clc
            adc    cp
            sta    cp
            bcc    Bump4
            inc    cp+1
Bump4       ldy    #0
            rts
            REP    50
;
; These rtns transfer control
; the monitor's I/O  handlers
;
GetLine     bit    RDROM2          ;Read ROM; no write
            jmp    GETLN           ;Input line w/prompt
;
DspCR       bit    RDROM2          ;Read ROM; no write
            jmp    CROUT           ;Issue a carriage return
;
DspChar     bit    RDROM2          ;Read ROM; no write
            jmp    COUT            ;As set by user
;=================================================
; Input
;  (A)=char to display
; Preserved
;  (A)
;
CharOut     EQU    *
            pha                    ;Save char
            cmp    #'a'
            bcc    CharOut1
            cmp    #'z'+1
            bcs    CharOut1
            and    #$DF            ;to uppercase
;
CharOut1    ora    #$80            ;msb on
            jsr    DspChar         ;Calls actual output rtn
            pla
            pha
            cmp    #CR
            bne    CharOut2
            jsr    PollKbd
CharOut2    pla
            rts
            REP    50
; ($3513) Evaluate operand field
; No fancy stuff
;
EvalExpr    EQU    *
            ldy    #0
            sty    Value16         ;Zero the value
            sty    Value16+1
            dey                    ;=-1
            jsr    ChrGet          ;Incr Y b4 getting char fr buf
            cmp    #'$'
            bne    Dec2Int         ;Decimal str
;
; Convert str representing a hexdec
; value into an integer
;
Hex2Int     jsr    ChrGet
            beq    L3532           ;cr/space
            jsr    IsHexChar       ;Is char hexdec?
            bcs    SynErr1         ;No
            jsr    ShiftHex        ;Accomodate the incoming digit
            bcc    Hex2Int         ;Process next char
            bcs    SynErr1
L3532       rts
; Not referenced
            pla                    ;what's this?
;
SynErr1     jsr    CmdSynErr       ;Syntax err
            REP    50
; ($3537) Convert string representing a
; decimal value to an integer
; Input
; Output
;
Dec2Int     EQU    *
            dey
CnvLoop2    jsr    ChrGet
            beq    L3532           ;If cr/space, ret
            jsr    IsDecChar       ;Is it numeric?
            bcs    SynErr1         ;No, err
            jsr    ShiftDec        ;Accomodate the incoming digit
            bcc    CnvLoop2        ;Get next char
            bcs    SynErr1
;
ShiftDec    jsr    Mul2
            bcs    OvrFlow3        ;Overflow
            lda    Value16+1
            pha
            lda    Value16
            jsr    Mul2
            bcs    OvrFlow1        ;Overflow
            jsr    Mul2
            bcs    OvrFlow1        ;Overflow
            adc    Value16
            sta    Value16
            pla
            adc    Value16+1
            sta    Value16+1
            bcs    OvrFlow3        ;Overflow
;
            jsr    ChrGot
            sec
            sbc    #'0'
            clc
            adc    Value16
            sta    Value16
            bcc    OvrFlow3
            inc    Value16+1
            beq    OvrFlow2        ;Overflow
            clc
            rts
;
OvrFlow1    pla
OvrFlow2    sec
OvrFlow3    rts
;
Mul2        asl    Value16
            rol    Value16+1
            rts
;=================================================
; Shift in the hex value into running value
; Input
;  (A) = '0'-'9' or $3A-$3F
; Output
;  (Value) = running hex value
;=================================================
ShiftHex    EQU    *
            sec
            sbc    #'0'            ;$00-$0F
            asl    a
            asl    a
            asl    a
            asl    a
;
            ldx    #4
RotLoop     asl    a
            rol    Value16
            rol    Value16+1
            dex
            bne    RotLoop
            rts
;=================================================
; ($3595) This rtn has 2 entry points
; Input
;  cp = ptr into cmd line buffer
; Output
;  Z=1 - char is space or cr
;  (A) - char (converted to uppercase)
;=================================================
ChrGet      EQU    *
            iny                    ;Bump index first
ChrGot      EQU    *
            lda    (cp),y
            and    #$7F            ;Strip msb of char
            cmp    #'a'
            bcc    AsIs            ;Don't convert to ucase
            and    #$DF            ;ucase
AsIs        cmp    #SPACE
            beq    L35A6
            cmp    #CR
L35A6       rts
;=================================================
; Is char btwn '0'-'9'
; Input
; Output
; C=0 yes
;=================================================
IsDecChar   EQU    *
            cmp    #'9'+1
            bcs    NotHex
            cmp    #'0'
            bcc    NotHex
            clc
            rts
NotHex      sec
            rts
;=================================================
; Check for hexdec char '0'-'9' and 'A'-'F'
; If char is 'A'-'F', convert to a value
; btwn $3A-$3F and return with C=0
; Input
; Output
;=================================================
IsHexChar   EQU    *
            cmp    #'A'
            bcc    IsDecChar       ;chk for numeric char
            cmp    #'F'
            bcs    NotHex
            sbc    #$06            ;$3A-$3F
            clc
            rts
;=================================================
; Check for a keypress
; Ctrl-C   - Abort of linking process
; spacebar - Pause
;
PollKbd     EQU    *
            lda    KBD
            bpl    L35E1
            bit    KBDSTROBE       ;turn off keypressed flag
            cmp    #CTRLC+$80
            bne    IsSpcBar
;
            ldy    #$1C            ;abort
            jsr    DspMsg
            ldy    #$1C
            jsr    StorMsg
            jmp    DoBreak
;
IsSpcBar    cmp    #SPACE+$80      ;Is space bar depressed?
            bne    L35E1
WaitZ       lda    KBD             ;Yes
            bpl    WaitZ           ;Wait for any keypress
L35E1       rts
;=================================================
; Output thru EdAsm Interpreter Print Error rtn
; Don't return to the caller
; Input
;  (A) - error code
;
ErrHndlr    jsr    PrtError
            jmp    DoBreak
;=================================================
DupCmdErr   ldy    #$10
            jmp    GoShowMsg
;
OptnErr     ldy    #$0F
            jmp    GoShowMsg
;
CmdFileErr  ldy    #$0E
            jmp    GoShowMsg
;
CmdOrderErr ldy    #$02
            jmp    GoShowMsg
;
UnknownCmdErr      ldy             #$1B
            jmp    GoShowMsg
;
RldEsdErr   ldy    #$11
            jmp    GoShowMsg
;
ExtrnErr    ldy    #$17            ;>255 EXTRN's
            jmp    GoShowMsg
;
CmdSynErr   ldy    #$01
GoShowMsgZ  jmp    GoShowMsg
;
GoShowMsg   jsr    DspMsg
;
; All errors above will come here
; Close all files. Check for a ctrl-B
; If so, exit to monitor else re-load EdAsm.ED
; & transfer control to the editor
; ($3613)
; Input
; Output
;
DoBreak     EQU    *
            lda    CMDADR          ;last MLI call return address
            pha
            lda    CMDADR+1
            pha
;
            lda    #$01
            sta    ClsAllP
            lda    #$00
            sta    ClsAllP+c.refNum
            jsr    PRODOS8         ;CLOSE
            DB     $CC
            DW     ClsAllP
;
            pla
            sta    CMDADR+1
            pla
            sta    CMDADR          ;last MLI call return address
;
            bit    KBDSTROBE       ;turn off keypressed flag
            bit    RDROM2          ;Read ROM; no write
            jsr    RDKEY           ;Input char with cursor
            cmp    #CTRLB+$80
            bne    Abort
;
            tsx
            stx    StackP
            ldx    #$80
            txs
            lda    ROMIN2          ;read ROM/write LCbank2 (RR)
            lda    ROMIN2
            jmp    MON             ;std monitor entry w/beep
;
Abort       jsr    SetupED         ;Proceed to load & xfer control to EdAsm.Ed
            jmp    USRADR          ;ctl-Y vector
;=================================================
; Put everything back in order
; Input
; Output
; Currently EI's ctrl-Y vector points @ $B198
; If exec mode is on, the entry is modified to
; $B1AB
;
;=================================================
DoExit      EQU    *
            lda    OpCmdFP+c.outRef
            jsr    ClsFile         ;Close the command file
            jsr    SetupED
            bit    ExecMode        ;Was cmd file EXEC fr Editor?
            bmi    L3665           ;Yes (Qn: how to do this since we have to enter MON)
            jmp    USRADR          ;Exit via ctl-Y vector
;
L3665       clc
            lda    USRADR+1        ;ctl-Y vector
            adc    #$13            ;$B1AB-$B198
            sta    L367F+1         ;Self-modifying code
            lda    USRADR+2
            adc    #$00
            sta    L367F+2
            bit    ROMIN2          ;read ROM/write LCbank2 (RR)
            bit    ROMIN2
            ldx    #$F8
            txs
L367F       jmp    USRADR          ;ctl-Y vector
            REP                    50
; Input
; Output
; Load EDASM's Editor
;
SetupED     EQU    *
            jsr    LoadED          ;Load EDASM.ED
            lda    #%01111111      ;$7F
            sta    BitMap+22       ;P8 memory bitmap
            lda    #%10000001      ;$81
            sta    BitMap+23       ;P8 memory bitmap
            lda    TxtBgn          ;No file in mem
            sta    TxtEnd
            lda    TxtBgn+1
            sta    TxtEnd+1
            rts
            REP                    50
;
; Phase 1 use 2 bytes of this table. However, the
; locations accessed should be $3698 and $369A
; & not $3697 and $3699. The bytes should be
; addr hi of the EXTRN & ENTRY tables
;
L3698       DB     $71             ;ENTRY table must be < $7100
            DB     $00
            DB     $91              ;EXTRN table must be < $9100
;
BitsT       DB     $80,$40,$20,$10,$08,$04,$02,$01
;
; Default filenames of workfiles
;
AutoLnkS    STR    'EDASM.AUTOLINK'
            DB     $00
TempESD     STR    'EDASM.TEMPESD'
            DB     $00
TempRLD     STR    'EDASM.TEMPRLD'
            DB     $00
;=================================================
DirectvT    EQU    *
            ASC    'BIN            '
            ASC    'REL            '
            ASC    'SYS            '
            ASC    'ORG            '
            ASC    'OPT            '
            ASC    'ALN            '
            DB     $00             ;Marks end of table
;
; JMP table
;
L36EA       DB     >CmdBin-1       ;Lo
            DB     >CmdRel-1
            DB     >CmdSys-1
            DB     >CmdOrg-1
            DB     >CmdOptn-1
            DB     >CmdAln-1
;
L36F0       DB     <CmdBin-1       ;Hi
            DB     <CmdRel-1
            DB     <CmdSys-1
            DB     <CmdOrg-1
            DB     <CmdOptn-1
            DB     <CmdAln-1
;=================================================
OptionsT    ASC    'MESXNDP'
            DB     $00
;
LinkObjS    STR    'EDASM.LINKOBJ' ;65-byte buffer for pathname
            DS     $33,0           ;51
;
LinkMapS    STR    'EDASM.LINKMAP' ;65-byte buffer for pathname
            DS     $33,0           ;51
;
CmdLineB    DS     128,SPACE       ;Command Line Buffers
;
Origin      DW     $A0B0           ;Set by cmd/AuxType of 1st src file
SrcCodeLen  DW     $A0A0           ;len of code image of src file
NegSrcOrg   DW     $A0CC           ;2's complement of src ORiGin
L3806       DW     $A0BE           ;Addr+1 of code image
RelAdr      DW     $A0FF           ;Relocated Adr
;
; 3-byte work area for ESD records
; The layout of this work area
; offset  Meaning
;   0     DB symbol flag's byte
;      If ENTRY
;   1     DW offset fr BO code image
;      If EXTRN
;   1     DB symbol number referred to by RLD record
;   2     DB 0
;
ESDRec      DB     $A0
            DB     $A0
            DB     $FE
;
RLDFlags    DB     $A0             ;RLD flag-byte
;
ModNbr      DB     $A0             ;source file count/Module Number
L380F       DB     $A0             ;Counter
TrgtFTyp    DB     $00             ;OBJECT filetype
;
; Table of ptrs to BO 1st EXTRN rec of each src file 
;
SrcModTLo   DS     50,0
SrcModTHi   DS     50,0
;
; Posn counter of beginning of code image (ORG ADRS)
; within the OBJECT file for src file module #s 0-49
;
OrgAdrLo    DS     50,0
OrgAdrHi    DS     50,0
;
; Posn counter of end of code image (END ADRS) within
; the OBJECT file for src file module #s 0-49
;
EndAdrLo    DS     50,0
EndAdrHi    DS     50,0
;=================================================
; ($393D) General purpose pathname work area
; Set this b4 opening a disk file
;
PathNameB   DS     64,0            ;Should be 65!
;
MapFDB      DS     90,SPACE        ;data buf for LinkMap
;
SymLen      DB     $A0             ;temp store for len of symbolicname
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Use to open source file(s)
;
OpSrcFP     DB     $03
            DW     PathNameB
            DW     SrcIOAdr        ;1024-byte buf for ProDOS
            DB     $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ProDOS parameter blocks for Command File which 
; is a TXT file. Each text line is terminated by a CR
;
OpCmdFP     DB     $03             ;OPEN
            DW     PathNameB       ;PathName
            DW     XA900           ;1024-byte buf
            DB     $00
;
RdCmdFP     DB     $04             ;READ
            DB     $00
            DW     CmdLineB
            DW     128             ;At most 128 chars/line
            DW     0               ;# actual read (not referenced)
;
NLCmdFP     DB     $03             ;NEWLINE
            DB     $00
            DB     $7F             ;AND mask=ignore msb i.e. both $0D/$8D are accepted
            DB     CR              ;newline char
;
; ($39F0) Use to set file posn to beginning of Command File
;
SMCmdFP     DB     $02             ;SETMARK
            DB     $00
            DS     3,0             ;This doesn't get changed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Used to destroy
; 1) old LinkMap
; 2) old tempESD
; 3) old OBJECT file (if any)
; 4) old tempRLD
; PathNameB must be filled w/the filename
;
DestryP     DB     $01
            DW     PathNameB
;
CloseP      DB     $01             ;Use by anybody
            DB     $00
;
ClsAllP     DB     $01
            DB     $00
;
; Not used
;
L39FC       DB     $04             ;whats this?
            DB     $00
            DB     $00
            DB     $00
            DB     $00
            DB     $00
            DB     $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Used to get File Info of a source (REL) file
;
GFISrcFP    DB     10
            DW     PathNameB
            DB     0
SrcType     DB     0
SrcORG      DW     0               ;auxtype
            DB     0
            DW     0
            DW     0
            DW     0
            DW     0
            DW     0
;
; Used to set the file position of a src file
;
SMSrcFP     DB     $02             ;SETMARK
            DB     $00
            DS     3,0             ;Caller must set this
;
; Used to read the first 2 bytes of src file
; which is the length of its code image
;
RCodeLenP   DB     $04
            DB     $00
            DW     SrcCodeLen      ;SrcCodeLen (2-byte data buf)
            DW     $0002           ;# of bytes to be read
            DW     $A080           ;actual # read (unused)
;
; ($3A22) For reading SRC, tempRLD, tempESD
; For appending to OBJECT file
;
RWFileP     DB     $04
            DB     $00
            DW     SrcDBuf         ;data buf
            DW     0               ;Set this b4 calling PRODOS
            DW     0               ;actual # of bytes read
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Use to open a 1) tempESD 2) OBJECT file
;
Open3P      DB     $03             ;OPEN
            DW     PathNameB
            DW     X3F00           ;1024-byte buf for PRODOS
            DB     0
;
; Use to write 1) TempESD 2) OBJECT files
;
Write1P     DB     $04             ;WRITE
            DB     0
            DW     X9100           ;Data Buf
            DW     $A0A0           ;write len
            DW     $B1A0           ;Actually written
;
; Read one page of code img of current src file
;
RdCodeImgP  DB     $04             ;READ
            DB     0
            DW     X9100           ;Data Buf
            DW     $0000
            DW     $A0D5
;
; Use to create BIN/REL/SYS OBJECT files
; Also use to create TempESD/TempRLD binary files
; The filetype & auxtype must be set first
;
CreateP     DB     7               ;CREATE
            DW     PathNameB
            DB     $E3             ;full access
            DB     $00             ;filetype
            DW     $0000           ;auxtype
            DB     $01             ;seedling
            DW     0
            DW     0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Used to open 1) LinkMap text file
; 2) tempRLD 3) tempESD BIN file
;
Open2P      DB     $03
            DW     PathNameB
            DW     X4300           ;1024-byte buf
            DB     $00
;
; Use to create LinkMap text file
;
CrLnkMapP   DB     7
            DW     PathNameB
            DB     $E3
            DB     TXTtype
            DW     0
            DB     $01             ;storage type
            DW     0
            DW     0
;=================================================
; Use to write the LinkMap text file
; WrMapFIdx doubles as # of bytes to write
; besides being used as an index to store the
; chars into the Map File's Data Buf (MapFDB)
;
WrMapFP     DB     $04             ;WRITE
            DB     $00
            DW     MapFDB          ;data buf addr
WrMapFIdx   DW     $A0C3           ;at most 128 bytes (hi-byte=0)
            DW     $A080
;=================================================
; Use to 
; 1) get eof of LinkMap file, then
; 2) set to file posn to its EOF
;
GeofP       DB     $02             ;GET_EOF/SETMARK
            DB     $00
            DS     3,0
;
; Use to write 1) TempRLD 2) TempESD files
;
Write2P     DB     $04             ;WRITE
            DB     $00
            DW     SrcDBuf         ;source data buffer
            DW     0               ;# of bytes to write
            DW     $A0A0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Use to move file posn to beginning 
; 1) of the tempRLD file
; 2) OBJECT file
;
SMarkP      DB     $02             ;SETMARK
            DB     $00
            DS     3,0             ;Not changed
;=================================================
; Message pointers sub-tables
;
MsgTLo      DB     >L3ADE
            DB     >L3B02
            DB     >L3B1F
            DB     >L3BB7
            DB     >L3BDD
            DB     >L3BFF
            DB     >L3C1E
            DB     >L3C3F
            DB     >L3C63
            DB     >L3C83
            DB     >L3CA0
            DB     >L3CB7
            DB     >L3CCF
            DB     >L3CEB
            DB     >L3B55
            DB     >L3B7B
            DB     >L3BA0
            DB     >L3D06
            DB     >L3D22
            DB     >L3D3F
            DB     >L3D4B
            DB     >L3D58
            DB     >L3D8D
            DB     >L3D9A
            DB     >L3DBE
            DB     >L3DD6
            DB     >L3DEE
            DB     >L3B3A
            DB     >L3AB4
            DB     >L3D75
;
MsgTHi      DB     <L3ADE          ;0
            DB     <L3B02          ;1
            DB     <L3B1F          ;2
            DB     <L3BB7          ;3
            DB     <L3BDD          ;4
            DB     <L3BFF          ;5
            DB     <L3C1E          ;6
            DB     <L3C3F          ;7
            DB     <L3C63          ;8
            DB     <L3C83          ;9
            DB     <L3CA0          ;10
            DB     <L3CB7          ;11
            DB     <L3CCF          ;12
            DB     <L3CEB          ;13
            DB     <L3B55          ;14
            DB     <L3B7B          ;15
            DB     <L3BA0          ;16
            DB     <L3D06          ;17
            DB     <L3D22          ;18
            DB     <L3D3F          ;19
            DB     <L3D4B          ;20
            DB     <L3D58          ;21
            DB     <L3D8D          ;22
            DB     <L3D9A          ;23
            DB     <L3DBE          ;24
            DB     <L3DD6          ;25
            DB     <L3DEE          ;26
            DB     <L3B3A          ;27
            DB     <L3AB4          ;28
            DB     <L3D75          ;29
;
; Messages starts here
;
L3AB4       ASC    'LINKER         ABORTED'
            DB     CR
            ASC    'PRESS          RETURN TO CONTINUE\'
            DB     CR
            ASC    '\'
L3ADE       ASC    'ProDOS         Linker 1.0'
            DB     CR,CR
            ASC    'Command        Filename'
            ASC    '\'             ;end of msg
L3B02       ASC    'ERR:           Syntax error in command'
            ASC    '\'
L3B1F       ASC    'ERR:           Invalid Command order'
            ASC    '\'
L3B3A       ASC    'ERR:           Unknown command found'
            ASC    '\'
L3B55       ASC    'ERR:           Empty or incomplete command'
            ASC    '               file'
            ASC    '\'
L3B7B       ASC    'ERR:           Invalid option or option syntax'
            ASC    '\'
L3BA0       ASC    'ERR:           Duplicate command'
            ASC    '\'
L3BB7       ASC    'Phase          0 : Commands & Options Selected'
            ASC    '\'
L3BDD       ASC    'Phase          1 : Building DEF/REF tables'
            ASC    '\'
L3BFF       ASC    'Phase          2 : Resolving REF-EXTRNs'
            ASC    '\'
L3C1E       ASC    'Phase          3 : Relocating Object code'
            ASC    '\'
L3C3F       ASC    'Phase          4 : Generating Object RLD-ESD'
            ASC    '\'
L3C63       ASC    'Phase          5 : Sorting loadmap index'
            ASC    '\'
L3C83       ASC    'Phase          6 : Generating loadmap'
            ASC    '\'
L3CA0       ASC    'ERR:           Symbol table full'
            ASC    '\'
L3CB7       ASC    'ERR:           Too many REL files'
            ASC    '\'
L3CCF       ASC    'ERR:           File is not a REL file'
            ASC    '\'
L3CEB       ASC    'ERR:           REL file is too large'
            ASC    '\'
L3D06       ASC    'ERR:           REL file ESD too large'
            ASC    '\'
L3D22       ASC    'Duplicate      DEF-ENTRY symbol, '
            ASC    '\'
L3D3F       ASC    'of             module #'
            ASC    '\'
L3D4B       ASC    '               in module #'
            ASC    '\'
L3D58       ASC    'Undefined      REF-EXTRN symbol, '
            ASC    '\'
L3D75       ASC    'REF-DEF        SIZE mismatch, '
            ASC    '\'
L3D8D       ASC    'UNREFERENCED'
            ASC    '\'
L3D9A       ASC    |ERR:           >255 EXTRN's in REL output ESD|
            ASC    '\'
L3DBE       ASC    'MOD             ORG   END  MODULE'
            DB     CR
            ASC    '\'
L3DD6       ASC    '               #   ADRS ADRS  NAME  '
            DB     CR
            ASC    '\'
L3DEE       ASC    '               ADRS M# SYMBOL           MODULE'
            ASC    '               X-REF LIST                     '
            ASC    '                    PAGE '
            ASC    '\'
            ASC    '14-MAR-84'
            ASC    '23:42          '
;
FileDBSiz   EQU    AsmLinker-SrcDBuf;20 mempages=5K