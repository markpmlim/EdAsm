Name          : ASM3.S
Record length :    2,049
End of file   :   62,315
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;
; EQU directive
;
L8A31       LDA    PassNbr
            BNE    L8A41
;
            LDA    LabelF          ;Does src line have a label field?
            BEQ    L8A53           ;No
            LDX    #$00
            LDA    #undefined
            ORA    (SymFBP,X)      ;NB: SymFBP is set only
            STA    (SymFBP,X)      ; during pass1
;
L8A41       JSR    EvalOprnd       ;Process operand
            BCS    L8A50
            LDA    NxtToken        ;Is sp/cr?
            BNE    L8A50           ;No
            LDA    PassNbr         ;If pass2, skip code below cos
            BNE    DrtvFin         ; (SymFBP) won't be set correctly
            BEQ    L8A5E           ;Pass 1
;
L8A50       LDX    #$24            ;directive operand err
            DB     $2C
L8A53       LDX    #$0C            ;equate err
            JSR    RegAsmEW
;
DrtvFin     LDA    ZAB             ;Same as DrtvDone!
            LDY    #0
            CLC
            RTS                    ;Ret to HndlMnem
;
; External idfers can not be used to define the label
;
L8A5E       LDA    ExprAccF        ;Expr's accumulated flag bits
            BIT    Bit10           ;EXTeRNal
            BNE    L8A53           ;Yes
            LDY    #0
            LDA    SymFByte        ;Is it a new symbol?
            BNE    L8A6F           ;No (If non-zero, its val had been ret by FindSym)
            LDA    #unrefd         ;Symbol is unreferenced
            BNE    L8A71           ;always
;
L8A6F       AND    #$FF-undefined  ;Mark symbol is now defined
L8A71       ORA    RelExprF
            STA    (SymFBP),Y      ;Set flag byte of symbol entry
            INY
            LDA    ValExpr
            STA    (SymFBP),Y
            LDA    ValExpr+1
            INY
            STA    (SymFBP),Y      ;addr field
            JMP    DrtvFin
            REP    50
;
; ORG directive
; At least one ORG must be declared or no object
; code will be generated. If REL code is to be
; generated, then the REL directive must precede
; the ORG directive
; Ref pg 93 on rel ORG
;
L8A82       JSR    EvalOprnd
            BCS    L8A50
            LDA    NxtToken        ;Is sp/cr?
            BNE    L8A50           ;No
            LDA    PassNbr         ;Pass 1?
            BEQ    L8A9E           ;Yes
            BIT    DummyF          ;R we in a dummy section?
            BMI    L8A9E           ;Yes
            LDA    RelExprF
            BEQ    L8A9A           ;expr's val is abs
            JMP    L8B2F
;
L8A9A       BIT    GenF
            BVS    L8AA1           ;Output MC to disk
L8A9E       JMP    SetPC           ;NB. (ObjPC) is not changed
;
L8AA1       LDA    ValExpr+1
            BNE    L8AAE
            BIT    RelCodeF        ;REL obj code?
            BPL    L8AAE           ;No
            LDX    #$46            ;ORG > $100
            JSR    RegAsmEW
;
L8AAE       LDA    ValExpr         ;New ORG value
            PHA
            LDA    ValExpr+1
            PHA
            JSR    L99DF           ;Flush all obj code incl RLD etc
            LDX    #ObjFile
            JSR    Open4RW         ;Kill old objfile, create new one for output
            LDA    #BINtype
            STA    ftypeT          ;Reset to BIN after obj file is opened
            LDA    GenF
            AND    #$7F            ;N=0 => Lift suppression of code generation
            STA    GenF
            PLA
            STA    ValExpr+1
            PLA
            STA    ValExpr
;
            LDA    ValExpr
            STA    CurrORG
            LDA    ValExpr+1
            STA    CurrORG+1
;
            LDY    #6
L8AD7       LDA    GFInfoPB,Y
            STA    SFInfoPB,Y
            DEY
            BNE    L8AD7
;
            LDA    CurrORG         ;Set auxtype of OBJ file
            STA    SFIaux
            LDA    CurrORG+1       ; to the new ORG value
            STA    SFIaux+1        ;NB. ORG can never be $0000-$00FF
            JSR    PRODOS8
            DB     $C3
            DW     SFInfoPB
            BEQ    L8AF5
            JMP    DOSErrs
;
L8AF5       LDA    #0
            STA    FileLen
            STA    FileLen+1
            BIT    RelCodeF        ;REL code?
            BPL    L8B05           ;No
;
            JSR    Wr1Byte         ;Write 2 zeros @ BOF
            JSR    Wr1Byte         ; as place holder
;
L8B05       LDA    #0
            STA    CodeLen
            STA    CodeLen+1
            LDA    ListingF        ;Listing on?
            BPL    L8B2C           ;no
;
            LDX    #$1F
            LDA    #>LD798         ;Next obj file
            STA    Msg2P
            LDA    #<LD798
            STA    Msg2P+1
            JSR    L7E19
;
            LDX    #$1E
            LDA    #>ObjPNB+1
            STA    Msg2P
            LDA    #<ObjPNB+1
            STA    Msg2P+1
            JSR    L7E19
            JSR    PutCR
L8B2C       JMP    SetPC
;
; Handle relative ORG
;
L8B2F       SEC
            LDA    ValExpr
            SBC    PC
            TAY
            LDA    ValExpr+1
            SBC    PC+1
            TAX
            BCC    L8B5A           ; <
;
            LDA    ValExpr         ; >=
            PHA
            LDA    ValExpr+1
            PHA
            STY    ValExpr         ;# of bytes to write
            STX    ValExpr+1
            JSR    Is16K           ;Is val > 16384?
            BCC    L8B4E
            JMP    L8B6D           ;Yes
;
; Move fileposn forward by write random data
;
L8B4E       JSR    L8CAB           ;Fill
            PLA
            STA    ValExpr+1
            PLA
            STA    ValExpr
            JMP    SetPC
;
; Move fileposn backwards
;
L8B5A       BIT    GenF
            BVS    L8B61           ;disk write
            JMP    SetPC
;
L8B61       SEC
            LDA    ValExpr         ;Make sure this
            SBC    CurrORG         ; >= curr ORG
            TAY
            LDA    ValExpr+1
            SBC    CurrORG+1
            BCS    L8B75
;
L8B6D       LDX    #$06
            JSR    RegAsmEW        ;overflow err
            JMP    CanclAsm
;
L8B75       STY    CodeLen         ;file pos rel to curr ORG
            STA    CodeLen+1
            LDA    CodeLen
            CLC
            BIT    RelCodeF        ;R we writing a REL file?
            BPL    L8B82           ;No
            ADC    #2              ;2 more for the Code Image Len @ BOF
L8B82       STA    FileLen
            TAY                    ;lobyte of new file posn
            LDA    CodeLen+1
            ADC    #0
            STA    FileLen+1       ;file len
            LDX    #ObjFile        ;Force a flush
            JSR    SetFPos         (A,Y) - fileposn
;
SetPC       LDA    ValExpr
            STA    PC              ;PC=new ORG Addr
            LDA    ValExpr+1
            STA    PC+1
            JMP    DrtvFin
            REP    50
;
; Greater than 16384 (16K)
; C=0 - No
; C=1 - Yes
;
Is16K       BIT    ValExpr+1
            BMI    L8BAB
            BVC    L8BA9
            LDA    ValExpr+1
            AND    #%00111111
            ORA    ValExpr         ;Zero?
            BNE    L8BAB           ;No
L8BA9       CLC
            RTS
L8BAB       SEC
            RTS
            REP    50
; OBJ directive
; This directive cannot be used in conjunction with
; REL directive. To store object code directly into
; mem, do ASM srcfile,@ and have the following
; src statements
;  ORG $1000 ;optional
;  OBJ $6000
; at the beginning of file
; Normally sym table is $0800-$7000
; Ref pg 96
;
L8BAD       LDA    #0
            STA    ValExpr
            STA    ValExpr+1
            JSR    EvalOprnd
            BCC    L8BBB
L8BB8       JMP    L8A50
;
L8BBB       LDA    NxtToken        ;Is sp/cr?
            BNE    L8BB8           ;No
            BIT    GenF
            BVS    L8BFC           ;disk write
            LDA    ValExpr
            ORA    ValExpr+1
            BNE    L8BCF
            LDA    #$80
            STA    GenF            ;N=1-Suppress code generation
            BNE    L8BFC           ;Always
L8BCF       BIT    RelCodeF        ;Is REL obj code?
            BPL    L8BDB           ;No
;
L8BD3       LDX    #$38            ;Can't use OBJ and
            JSR    RegAsmEW        ; REL directives together
            JMP    DrtvFin
;
L8BDB       LDA    EndSymT
            CMP    ValExpr         ;Is value < curr EO
            LDA    EndSymT+1       ; symbol table?
            SBC    ValExpr+1
            BCS    L8BD3           ;Yes, err
;
            LDA    ValExpr
            STA    ObjPC
            STA    MemTop
            STA    RLDEnd
            LDA    ValExpr+1
            STA    ObjPC+1
            STA    RLDEnd+1
            STA    MemTop+1
;
            JSR    L828A           ;Ensure val < mem limit
            LDA    #$00            ;N=0,V=0-Flag gen obj code in mem
            STA    GenF
L8BFC       JMP    DrtvFin
            REP    50
;
; Evaluate a Directive's operand expression
; This rtn expects all idfers used in the expr
; are defined
;
EvalOprnd   LDA    PassNbr
            PHA
            LDA    #1              ;Force a pass 2
            STA    PassNbr
            JSR    EvalExpr
            TAX                    ;error token?
            PLA
            STA    PassNbr
            RTS
            REP    50
;
; DS/.BLOCK directive
;
L8C0E       JSR    EvalOprnd
            BCS    L8C1D
            JSR    Is16K           ;Is expr's val > 16384?
            BCC    L8C23
            LDX    #$06            ;Yes, overflow
L8C1A       DB     $2C
L8C1B       LDX    #$24            ;directive operand err
L8C1D       JSR    RegAsmEW
            JMP    DrtvFin
;
L8C23       SEC
            ROR    RndF            ;Assume no filler char
            LDA    NxtToken        ;Is sp/cr?
            BEQ    L8C5F           ;Yes
            CMP    #$01            ;Comma?
            BNE    L8C1B           ;No, err
;
            LDA    ValExpr         ;# of bytes to reserve
            PHA
            LDA    ValExpr+1
            PHA
            INY
            INY
            JSR    WhiteSpc        ;Is it sp/cr after comma?
            BEQ    L8C44           ;Yes
            JSR    EvalExpr        ;2nd expr -> filler byte
            BCS    L8C44
            LDA    NxtToken        ;Make sure nxt char is sp/cr
            BEQ    L8C49           ;Yes, it is
L8C44       PLA                    ;Dump val
            PLA
            JMP    L8C1B           ;err
;
L8C49       CLC
            ROR    RndF            ;Flag we will use a filler
            LDA    ValExpr
            STA    Filler          ;byte used to fill
            LDA    ValExpr+1
            BEQ    L8C59           ;Must be 8-bits
            LDX    #$28            ;byte overflow err
            JSR    RegAsmEW
;
L8C59       PLA
            STA    ValExpr+1
            PLA
            STA    ValExpr
;
L8C5F       LDA    ValExpr         ;# of bytes to reserve
            CLC
            ADC    PC
            STA    NewPC           ;New PC
            LDA    ValExpr+1
            ADC    PC+1
            STA    NewPC+1
;
            LDA    PassNbr
            BEQ    L8CA0
            LDA    ValExpr
            STA    ERfield         ;# of bytes reserve
            LDA    ValExpr+1
            STA    ERfield+1
;
            LDA    #%10000001
            STA    LstCodeF
            BIT    GenF
            BMI    L8C9D           ;No obj code output
            BIT    RndF            ;Use filler char?
            BMI    L8C9A           ;No
;
L8C84       LDA    ValExpr
            ORA    ValExpr+1
            BEQ    L8C9D           ;Done
            LDA    Filler
            JSR    StorByt
            LDA    ValExpr
            BNE    L8C95
            DEC    ValExpr+1
L8C95       DEC    ValExpr
            JMP    L8C84
;
L8C9A       JSR    L8CAB           ;Fill w/random data
L8C9D       JSR    PrtAsmLn        ;print code,stmt
L8CA0       LDA    NewPC           ;Adjust PC
            STA    PC
            LDA    NewPC+1
            STA    PC+1
            JMP    L8D44
            REP    50
;
; Fill obj file with random data
; until new posn
;
L8CAB       LDA    ValExpr         ;# of bytes to write
            ORA    ValExpr+1
            BEQ    doRtn4
            LDA    BUTN3           ;Get data byte here
            JSR    StorByt
            LDA    ValExpr
            BNE    L8CBD
            DEC    ValExpr+1
L8CBD       DEC    ValExpr
            JMP    L8CAB
doRtn4      RTS
            REP    50
;
; Define Byte (DB/DFB) psuedo opcode - pg 102
;
L8CC3       JSR    L8D5E           ;Setup
NxtDFB      STX    ByteCnt         ;curr cnt
            JSR    EvalExpr        ;rtn will take care of comma
            LDX    ByteCnt         ;double as index
            LDA    ValExpr         ;val defined
            STA    GMC,X
            INX
            BCS    L8CED           ;err during eval
            LDA    PassNbr
            BEQ    L8CED
            LDA    RelExprF        ;Evaluate fr relocatable expr?
            BEQ    L8CED           ;No, abs
;
; For each byte an RLD entry is created if
; expr is obtained fr relative addr
;
            STX    ByteCnt         ;Save temporarily
            STY    SavIndY         ;Save index into operand field
            DEX
            TXA                    ;offset
            LDX    #$01
            LDY    #$00            ;Reverse order
            JSR    AddRLDEnt       ;Make RLD entry
;
            LDX    ByteCnt
            LDY    SavIndY
L8CED       STX    Length
            LDA    NxtToken
            BEQ    L8D0C           ;cr/space
            EOR    #$01
            BEQ    L8CFD           ;Comma
L8CF7       JSR    L9193           ;err
            JMP    L8D35
;
L8CFD       INY
            INY
            LDA    (SrcP),Y
            CMP    #SPACE+1
            BCC    L8CF7
            CPX    #4              ;4 bytes generated?
            BNE    NxtDFB          ;No
;
            JSR    AdvSrcP
L8D0C       LDA    PassNbr
            BEQ    L8D20
            LDX    #$00
            JSR    L8E28           ;Store MC,update PC etc
L8D15       LDA    NxtToken
            BEQ    L8D26           ;cr/space -> done
            LDX    #0              ;Reset cnt
            LDY    #0              ; & index
            JMP    NxtDFB
;
L8D20       JSR    L8D52           ;update total cnt
            JMP    L8D15
;---
L8D26       LDA    PassNbr
            BNE    L8D44
L8D2A       JSR    L8D52           ;update total cnt
            LDA    TotCnt
            JSR    AdvPC
            JMP    DrtvDone
;---
L8D35       LDA    PassNbr
            BEQ    L8D2A
            JSR    StorGMC         ;write instr
            JSR    PrtAsmLn        ;print code,stmt
            LDA    Length
            JSR    AdvPC
;---
L8D44       LDA    #0
            STA    Length
            LDA    #$83
            STA    ZAB
;
DrtvDone    LDY    #0
            LDA    ZAB
            CLC
            RTS
            REP    50
;
; Keep track of total # of bytes generated
;
L8D52       CLC
            LDA    Length
            ADC    TotCnt
            STA    TotCnt
            LDA    #0
            STA    Length
            RTS
            REP    50
;
; (X)=0
;
L8D5E       LDX    #%00100001      ;$21
            STX    LstCodeF
            LDX    #0
            STX    TotCnt          ;cntr
            RTS
            REP    50
;
; DW directive
;
L8D67       LDA    #$00            ;Reverse
;
L8D69       STA    EndianF         ;enter here for DDB
            JSR    L8D5E
NxtDW       JSR    EvalExpr
            STY    SavIndY         ;Index into operand field
            LDY    ValExpr
            LDX    ValExpr+1
            LDA    EndianF
            BEQ    L8D81
;
            STY    GMC+1           ;normal (DDB)
            STX    GMC
            BNE    L8D85           ;always
L8D81       STY    GMC
            STX    GMC+1
;
L8D85       BCS    L8D98           ;err during eval
            LDA    PassNbr
            BEQ    L8D98
            LDA    RelExprF
            BEQ    L8D98           ;abs expr
;
            LDA    #$00            ;offset
            LDX    #$02
            LDY    EndianF         ;byte ordering
            JSR    AddRLDEnt       ;Make RLD entry
;
L8D98       LDY    SavIndY         ;Restore index into operand field
            LDX    #2
            STX    Length
            LDA    NxtToken
            BEQ    L8DB4           ;cr/space -> done
            EOR    #$01
            BEQ    L8DA9           ;comma
L8DA6       JMP    L8CF7           ;err
;
L8DA9       INY
            INY
            LDA    (SrcP),Y
            CMP    #SPACE+1
            BCC    L8DA6
            JSR    AdvSrcP
;
L8DB4       LDA    PassNbr
            BEQ    L8DC7
            JSR    L8E28           ;Store MC, update PC, print
L8DBB       LDA    NxtToken        ;Is cr/space?
            BNE    L8DC2           ;No, comma or )
            JMP    L8D26           ;done
;
L8DC2       LDY    #$00            ;Index into src line
            JMP    NxtDW
;
L8DC7       JSR    L8D52           ;update total cnt
            JMP    L8DBB
            REP    50
;
; Define Double Byte (DDB)
;
L8DCD       LDA    #$01            ;Normal
            JMP    L8D69
            REP    50
;
; ASC directive
;
L8DD2       LDA    #-1
            STA    StrType
L8DD6       JSR    SkipSpcs
            STA    Delimitr
            JSR    AdvSrcP
            LDA    PassNbr
            BEQ    L8E41           ;Pass 1
            LDA    #%00100001
            STA    LstCodeF
            BNE    L8DED           ;always
;
L8DE8       ORA    msbF
L8DEA       STA    GMC-1,Y         ;$9A-$9D
L8DED       INY
            LDA    (SrcP),Y
            CMP    Delimitr
            BEQ    GotDelim2       ;Done
            CMP    #CR
            BEQ    L8E13           ;No comment field
            CPY    #5              ;4 bytes at a time
            BNE    L8DE8
;
            DEY                    ;=4
            STY    Length
            JSR    AdvSrcP
            JSR    L8E28           ;Store MC,update PC etc
            LDY    #0
            BEQ    L8DED           ;always
;
GotDelim2   INY                    ;Skip past 2nd delimiter
            JSR    WhiteSpc        ;Do we have a sp/cr?
            BEQ    L8E12           ;Yes
            JSR    L8530           ;invalid delim
L8E12       DEY                    ;Backup to 2nd delim
L8E13       DEY                    ;Backup to last char
            STY    Length
            BIT    StrType         ;ASC?
            BMI    L8E22           ;yes
            LDA    GMC-1,Y         ;DCI
            ORA    #$80
            STA    GMC-1,Y         ;last char of str
L8E22       JSR    L8E28           ;Store MC,update PC etc
            JMP    L8D44
;=================================================
L8E28       JSR    StorGMC
            LDA    ZAB
            CMP    #$82            ;Print 1 line + up to 4 bytes?
            BNE    L8E35           ;Yes
            BIT    LstGCode        ;Do we list gen code?
            BPL    L8E3C           ;No
L8E35       JSR    PrtAsmLn        ;print
            LDA    #$82
            STA    ZAB
L8E3C       LDA    Length
            JMP    AdvPC           ;Update PC & ret to caller
;
L8E41       INY
            LDA    (SrcP),Y
            CMP    Delimitr
            BEQ    L8E4C
            CMP    #CR
            BNE    L8E41
L8E4C       DEY
            TYA
L8E4E       JSR    AdvPC           ;(A) has # of bytes to be added to PC
            JMP    DrtvDone
            REP    50
;
; DCI pseudo opcode
;
L8E54       LDA    msbF
            PHA
            LDA    #$00
            STA    msbF            ;OFF temporarily
            STA    StrType
            JSR    L8DD6           ;Scan as all chars except last as ASC
            PLA
            STA    msbF
            JMP    DrtvDone
            REP    50
;
; MSB directive
; (X) not used?
L8E66       JSR    SkipSpcs
            JSR    ChrGot
            CMP    #'O'
            BNE    L8E91
            JSR    ChrGet
            CMP    #'N'
            BEQ    L8E8A           ;got 'ON'
;
            CMP    #'F'
            BNE    L8E91
            INY
            JSR    WhiteSpc
            BEQ    L8E87           ;cr?
            INY
            JSR    WhiteSpc
            BNE    L8E91           ;not-terminated
;
L8E87       LDA    #$00
            DB     $2C
L8E8A       LDA    #$80
            STA    msbF
            JMP    DrtvDone
L8E91       JMP    L8C1B           ;err
            REP    50
;
; STR directive
;
L8E94       LDA    #-1             ;ASC
            STA    StrType
            JSR    SkipSpcs
            STA    Delimitr
            LDX    #0
            DEY                    ;Move back past delimiter
            JSR    AdvSrcP         ;SrcP pointing @ sp b4 delim
            INY                    ;Indexing delim
L8EA4       INY
            INX
            LDA    (SrcP),Y        ;Scan ahead for
            CMP    Delimitr        ; 2nd one
            BEQ    L8EB0           ;Got it
            CMP    #CR
            BNE    L8EA4           ;Treat char as part of str
L8EB0       CPX    #2
            BCS    L8EB7           ;only 1 byte?
            JMP    L8A50           ;Yes, err
;
L8EB7       LDA    PassNbr
            BNE    L8EBF
            TXA                    ;len of str + 1 (len byte)
            JMP    L8E4E           ;Just adj PC & ret to caller
;
L8EBF       DEX
            LDY    #$01            ;Skip past 1st delim
            LDA    #%00100001
            STA    LstCodeF
            TXA                    ;len of str
            JMP    L8DEA           ;Store & can scanning as ASC
            REP    50
;
; LST directive
;
L8ECA       JSR    SkipSpcs
            JSR    ChrGot
            BCS    L8F34           ;non-alphabetic char
            CMP    #'O'
            BNE    L8EF3
            JSR    ChrGet
            BCS    L8F34           ;non-alphabetic
            CMP    #'N'
            BNE    L8EE9
            LDA    PassNbr
            BEQ    L8EEE
            JSR    PutCR
            SEC
            BCS    L8EEE           ;always
;
L8EE9       CMP    #'F'
            BNE    L8F34
            CLC
L8EEE       ROR    ListingF        ;ON => set msb
            JMP    L8F22
;
; The code here looks for 8 listing flags viz.
; Cyc, Gen, Warn, Unasm, Asym, Vsym, Sixup, Exp
; Only the 1st char is considered.
;
; The defaults are:
; LST ON,NOCyc,NOGen,Warn,Unasm,Asym,NOVsym,NOSixup,Exp
; Ref pg 111-113
;
L8EF3       LDA    #$80            ;Default to ON
            STA    OnOffSW
            JSR    ChrGot
            BCS    L8F34           ;Non-alphabetic
            CMP    #'N'            ;look for 'NO'
            BNE    L8F12
            JSR    ChrGet
            BCS    L8F34
            CMP    #'O'
            BNE    L8F34
            LDA    #$00            ;Got one
            STA    OnOffSW         ;Set to OFF
            JSR    ChrGet
            BCS    L8F34           ;Non-alphabetic
;
L8F12       LDX    #8
L8F14       CMP    LstOptns-1,X
            BEQ    L8F1E           ;Got a match
            DEX
            BNE    L8F14
            BEQ    L8F34           ;probably err
;
L8F1E       LDA    OnOffSW
            STA    LstFlags-1,X
L8F22       JSR    ChrGet
            BCC    L8F22           ;alphabetic
            CMP    #SPACE
            BEQ    L8F37
            CMP    #CR
            BEQ    L8F37           ;done
            INY
            CMP    #','            ;delimiter
            BEQ    L8EF3           ;Next option
L8F34       JMP    L9193
L8F37       JMP    DrtvDone
            REP    50
;
; .NOLIST directive
;
L8F3A       CLC
            BCC    L8F3E           ;always
; .LIST directive
;
L8F3D       SEC
;
L8F3E       ROR    ListingF
            JMP    DrtvDone
;
LstOptns    ASC    'CUEWGAVS'
            REP    50
;
; PAGE directive
;
DoPage      DEY
            DEY
            LDA    PassNbr
            BEQ    L8F5E
            JSR    RVLsting        ;Are we listing?
            BCS    L8F5E           ;No
            LDA    #FF
            JSR    PutC
            JMP    L9008           ;Ret to Pass2 loop
L8F5E       JMP    DrtvDone
            REP    50
;
; SBTL directive
; SubTtlF=$40 - directive encountered
;    =$FF - a string has been set
;    =$00 - no subtitle
; NB: $FF also means $40-bit is set
;
L8F61       LDA    #$40
            STA    SubTtlF
            LDA    PassNbr         ;Pass 1?
            BEQ    L8FA0           ;Yes
;
            JSR    SkipSpcs
            STA    Delimitr
            CMP    #CR
            BEQ    L8FA0
            JSR    AdvSrcP
            STX    SavIndX
;
            LDX    #0
L8F79       INY
            LDA    (SrcP),Y
            CMP    Delimitr
            BEQ    L8F8C
            CMP    #CR             ;CR => no 2nd delimiter
            BEQ    L8F8D
            STA    SubTitle,X
            INX
            CPX    #35
            BCC    L8F79
;
L8F8C       INY                    ;Bump past char
L8F8D       LDA    #0
            STA    SubTitle,X      ;null-terminated
            LDA    #$FF
            STA    SubTtlF         ;Flag there is a string (NB. V=1)
            JSR    WhiteSpc        ;cr/space?
            BEQ    L8F9E           ;Yes
            JMP    L8C1B           ;No, err
;
L8F9E       LDX    SavIndX
L8FA0       JMP    DoPage          ;Do a FF
            REP    50
;
; REP directive
;
L8FA3       LDA    PassNbr
            BNE    L8FAA
L8FA7       JMP    DrtvDone
;
L8FAA       JSR    RVLsting
            BCS    L8FA7           ;No
            JSR    L9013           ;Get # of times
            BCS    L8FA7
            JSR    ListCode
            JSR    PrtDecS         ;line #
            LDA    RepChar
            LDX    ValExpr         ;char count
L8FBE       JSR    PutC
            DEX
            BNE    L8FBE
            INX
            BNE    L8FFD           ;always
            REP    50
; CHR directive
;
L8FC7       JSR    SkipSpcs
            STA    Delimitr
            INY
            JSR    WhiteSpc
            BEQ    L8FE4
            STA    RepChar         ;This is what we want
            INY
            JSR    WhiteSpc
            BEQ    L8FE7
            CMP    Delimitr
            BNE    L8FE4
            INY
            JSR    WhiteSpc
            BEQ    L8FE7
L8FE4       JSR    L9018           ;err
L8FE7       JMP    DrtvDone
            REP    50
;
; SKP directive
;
L8FEA       LDA    PassNbr
            BNE    L8FF1
L8FEE       JMP    DrtvDone
;
L8FF1       JSR    RVLsting
            BCS    L8FEE           ;No
            JSR    L9013           ;Get # of times
            BCS    L8FEE
            LDX    ValExpr         ;# of blank lines
L8FFD       LDA    #SPACE
            JSR    PutC
            JSR    PutCR
            DEX
            BNE    L8FFD
;
L9008       PLA                    ;Discard ret addr
            PLA
            JSR    NextRec
            JSR    L81A3           ;Update counters
            JMP    Pass2Lup
;=================================================
L9013       JSR    EvalOprnd       ;Result in ValExpr
            BCC    doRtn5
L9018       JSR    L8C1B           ;err
            SEC
doRtn5      RTS
            REP    50
;
; DATE directive
;
L901D       LDX    #9              ;# of ASCII chars to get
            LDY    #0
L9021       LDA    PassNbr
            BNE    L9029
            TXA                    ;Don't generate
            JMP    L8E4E
;
; DATETIME field: Offset 0-8=DD-MMM-YY; 11-16=HH:MM<sp>
;
L9029       STY    DTCurIdx        ;0,11
            TXA                    ;9,6
            CLC
            ADC    DTCurIdx
            STA    DTEndCol        ;9,17
            LDX    #%00100001
            STX    LstCodeF
L9035       LDX    #0
L9037       LDY    DTCurIdx
            CPY    DTEndCol
            BCS    L9053
            LDA    DateTime,Y      ;Already in ASCII
            ORA    msbF
            STA    GMC,X
            INC    DTCurIdx
            INX
            CPX    #4
            BCC    L9037
            STX    Length          ;=4 so store MC,
            JSR    L8E28           ; update PC, print etc
            JMP    L9035
;
L9053       STX    Length
            TXA
            BEQ    L905B           ;Nothing to store
            JSR    L8E28           ;Write MC,update PC etc
L905B       JMP    L8D44
            REP    50
;
; IDNUM/TIME directive - pg 106
;
L905E       LDX    #6              ;# of ASCII chars to get
            LDY    #11             ;Index TIME portion
            JMP    L9021
            REP    50
;
; DSECT directive
;
L9065       LDA    DummyF
            BMI    L90AF           ;Already declared
;
            LDA    PC
            STA    SavPC
            LDA    PC+1
            STA    SavPC+1
            LDA    ObjPC           ;renamed as CodeLen when
            STA    SavObjPC        ; REL code is generated
            LDA    ObjPC+1
            STA    SavObjPC+1
            LDA    GenF
            STA    SavGenF
;
            LDA    #$FF
            STA    GenF            ;Suppress obj code output temporarily
            LDA    #0              ;PC=0
            STA    PC
            STA    PC+1
            LDA    #$80
            STA    DummyF
            JMP    DrtvDone
            REP    50
;
; DEND directive
;
L908E       LDA    DummyF
            BPL    L90AF           ;Not declared
;
            LDA    SavPC
            STA    PC
            LDA    SavPC+1
            STA    PC+1
            LDA    SavGenF
            STA    GenF
            LDA    PassNbr
            BEQ    L90AA           ;Pass 1
;
            LDA    SavObjPC
            STA    ObjPC
            LDA    SavObjPC+1
            STA    ObjPC+1
L90AA       LSR    DummyF          ;msb off
            JMP    DrtvDone
;
L90AF       LDX    #$10            ;Dummy section error
L90B1       JSR    RegAsmEW
            JMP    DrtvDone
            REP    50
;
; DO & IFNE directive-marks BO cond asm block
; CondAsmF
;  V=1 - false, V=0 - true
;  N=1 - within Alt blk
;
L90B7       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr
            BNE    L90C8
            LDA    ValExpr+1
            BNE    L90C8
L90C4       LDA    #$40            ;false
            STA    CondAsmF
L90C8       JMP    DrtvFin         ;true - CondAsmF=$00
            REP    50
;
; ELSE directive
; NB. ELSE block is optional
;
L90CB       LDA    #$80
            EOR    CondAsmF        ;$00->$80, $40->$C0, $80->$00
            BEQ    L90D2
            LSR                    ;$00->$80->$00, $40->$C0->$40
L90D2       STA    CondAsmF
            JMP    DrtvDone
            REP    50
;
; FIN directive-marks EO cond asm block
;
L90D7       LDA    #$00
            STA    CondAsmF
            JMP    DrtvDone
            REP    50
;
; IFEQ directive
;
L90DE       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr
            ORA    ValExpr+1
            BNE    L90C4
            BEQ    L90C8           ;=0 -> true
            REP    50
;
; IFGT directive
;
L90EB       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr+1
            BMI    L90C4           ;-ve
            BNE    L90C8           ;+ve but > 0 -> true
            LDA    ValExpr
            BEQ    L90C4           ;=0 -> false
            BNE    L90C8           ;true
            REP    50
;
; IFGE directive
;
L90FC       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr+1
            BMI    L90C4           ;-ve so < 0
            BPL    L90C8           ;>=0 - true
; IFLT
L9107       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr+1
            BPL    L90C4
            BMI    L90C8           ;true
; IFLE
L9112       JSR    EvalOprnd
            BCS    L9123
            LDA    ValExpr+1
            BMI    L90C8
            BNE    L90C4           ;+ve but > 0 - false
            LDA    ValExpr
            BEQ    L90C8
            BNE    L90C4           ;> 0 - false
;
L9123       JMP    L9193
            REP    50
;
; REL directive
; RLD will be cleared when an abs ORG is encountered
; e.g.
;  REL
;  ORG $3000
;
L9126       SEC
            ROR    RelCodeF        ;msb=1
            LDA    #RELtype
            STA    ftypeT
            JMP    DrtvDone
            REP    50
;
; INTERP directive
;
L9131       LDA    #SYStype
            STA    ftypeT
            JMP    DrtvDone
            REP    50
;
; X6502 directive
;
L9139       LDA    #$C0            ;N=1,V=1
            STA    X6502F          ;NCR 65C02
            JMP    DrtvDone
            REP    50
;
; ZDEF directive - pg 100-101
;
L9140       LDA    #$00
            BEQ    L9146           ;always
;
; DEF/ENTRY directive
;
L9144       LDA    #$01
;
; Common code
;
L9146       STA    GblAbsF
            LDA    PassNbr         ;pass 2
            BNE    L918E
            INC    SymNbr          ;# of ENTRY/EXTRN points
            BEQ    L9196           ;>255
;
            JSR    NxtField        ;Point @ operand field
            JSR    ChrGot          ;Get its 1st char
            BCS    L919C           ;A non-alphabetic char => err
            JSR    RsvdId          ;Is operand a reserved idfer?
            BCS    L918B           ;No
            JSR    FindSym
            BCC    L9172           ;Found in symbol table
;
; Idfer is found somewhere else
;
            LDX    GblAbsF         ;R we creating a global ZP idfer?
            BEQ    L919C           ;Yes -> err
            LDA    #$00
            STA    RelExprF        ;Init expr as abs
            LDA    #undefined+entry+fwdrefd;Symbol's flag byte
            JSR    AddNode         ;Add to symbol table
            JMP    DrtvFin
;
; Symbol is already in the symbol table
; 
; Consider the case
; lab1 ENTRY lab1
; A node had been created when the label field was parsed
;
L9172       DEY                    ;(A) has symbol's flag byte
            BIT    Bit10           ;EXTeRNal symbol?
            BNE    L919C           ;Yes -> err
            BIT    Bit08           ;ENTRY symbol?
            BNE    L9199           ;Yes -> err
            LDX    GblAbsF         ;ZDEF/ZREF?
            BNE    L9187           ;No
            TAX                    ;Save temporarily
            AND    #fwdrefd         ;ForwardRef?
            BNE    L919C           ;Yes -> err
            TXA
L9187       ORA    #entry          ;flag as ENTRY
            STA    (SymP),Y        ;Set sym's flag byte
L918B       JMP    DrtvFin
;
L918E       JSR    EvalExpr
            BCC    L918B
;
L9193       LDX    #$24            ;Directive operand err
            DB     $2C
L9196       LDX    #$3E            ;>255 ENT/EXT idfers
            DB     $2C
L9199       LDX    #$40            ;Duplicate ENT
            DB     $2C
L919C       LDX    #$0E            ;Invalid idfer
            JSR    RegAsmEW
            JMP    DrtvFin
            REP    50
;
; ZREF directive - pg 101,102
; Each assembly supports max 255 DEF/REF idfers
; To circumvent this, assemble modules separately
;
L91A4       LDA    #$00
            BEQ    L91AA
;
; REF/EXTRN directive
;
L91A8       LDA    #$01
;
; Common code
;
L91AA       STA    GblAbsF
            LDA    PassNbr
            BNE    L920C
            INC    SymNbr          ;# of ENTRYs/EXTRNs
            BEQ    L9196           ;>255
;
            JSR    NxtField
            JSR    ChrGot
            BCS    L919C           ;non-alphabetic char
            JSR    RsvdId          ;Is operand a reserved id?
            BCS    L920C           ;No
            JSR    FindSym         ;Is it in symbol table?
            BCC    L91E9           ;Yes
;
            LDA    PC
            PHA
            LDA    PC+1
            PHA
;
            LDA    #0
            STA    PC+1
            LDA    SymNbr          ;Extern symbol #?
            STA    PC
            LDA    #relative
            STA    RelExprF        ;Mark expr as relative
            LDA    #relative+external
            ORA    GblAbsF         ;0-ZDEF/ZREF,1-DEF/REF
            JSR    AddNode         ;(A) has symbol's flag byte
;
            PLA
            STA    PC+1
            PLA
            STA    PC
            BCS    L919C           ;Fail to add to symbol table
            BCC    L920C
;
; Found in symtbl; no node created; just update node
;
L91E9       TAX                    ;symbol's flagbyte
            BMI    L91F2           ;undefined symbol
            AND    #external       ;Defined but is it EXTeRNal?
            BNE    L9199           ;Yes -> duplicate
            BEQ    L919C           ;Always
;
L91F2       BIT    Bit08           ;ENTRY symbol?
            BNE    L919C           ;Yes -> err
            LDA    GblAbsF         ;ZDEF/ZREF?
            BEQ    L919C           ;Yes -> invalid
            DEY
            ORA    #relative+external
            STA    (SymP),Y
            INY
            LDA    SymNbr          ;symbol #
            STA    (SymP),Y        ;Value field
            INY
            LDA    #0
            STA    (SymP),Y
            DEY
            DEY                    ;Index symbol's flag byte
;
L920C       LDA    #0
            STA    ValExpr
            STA    ValExpr+1
            JMP    DrtvFin
            REP    50
;
; FAIL directive pg 108-109
;
L9215       JSR    SkipSpcs
            JSR    WhiteSpc        ;cr/space?
            BNE    L9220           ;No
L921D       JMP    L9193
;
L9220       CMP    #'3'            ;Pass 3 means both passes
            BEQ    L922E
            EOR    #'1'
            BEQ    L922A           ;pass 1
            LDA    #1              ;pass 2
L922A       CMP    PassNbr         ;Correct pass?
            BNE    L926C           ;No
;
L922E       INY
            LDA    (SrcP),Y
            CMP    #','            ;If not comma,
            BNE    L921D           ; error
            INY
            JSR    AdvSrcP
            JSR    PutCR
            LDA    #'>'
            LDX    #6
L9240       JSR    PutC
            DEX
            BNE    L9240
;
            LDA    #BEL
            JSR    PutC
            JSR    PutC
            LDX    #$08
L9250       LDA    FailTxt-1,X
            JSR    PutC
            DEX
            BNE    L9250
;
L9259       LDA    (SrcP),Y        ;Print user's msg
            CMP    #CR
            BEQ    L9265
            JSR    PutC
            INY
            BNE    L9259
;
L9265       JSR    FlagErrZ        ;incr err cnt
            LDA    PassNbr
            BNE    L926F           ;pass 2
L926C       JMP    DrtvDone
L926F       JMP    L9008
;
FailTxt     ASC    ':ERULIAF'
            REP    50
;
; PAUSE directive
; Allows for manual disk swaps-pg 98
;
L927A       JSR    L9013           ;Get #
            BCS    L9289
            LDX    ValExpr         ;1/2 -> 0/1
            DEX
            CPX    PassNbr
            BNE    L9289
            JSR    Wait4CR
L9289       JMP    DrtvDone
            REP    50
;
; CHN directive
; We should not declare a CHN in an INCLUDE/macro defn file
;
L928C       JSR    NxtField
            LDX    FCTIndex
            BEQ    L92B9           ;OBJ -> incl/chn nesting
            CPX    #MacFile        ;CHN directive in Macro defn file?
            BEQ    L92B9           ;Yes, error
;
            JSR    ClsFile         ;Close curr SRC/CHN file
            LDX    FCTIndex
;
; X=2,4
; The code below is also used by the INCLUDE directive
;
L929C       JSR    SetPNBuf        ;Use src/isrc PN buf
            JSR    GetPNStr        ;Copy str into the PN buf
            SEC
            ROR    NewF            ;=$80
;
            SED
            LDA    #0
            SEC                    ;add 1
            ADC    FileNbr
            STA    FileNbr
            CLD
;
            JSR    L92F0           ;Inform user we're opening another file
            LDX    FCTIndex
            JSR    Open4RW         ;Open source file for input
            JMP    DrtvDone
;
L92B9       JMP    L9364
            REP    50
;
; Get filename into corresponding PN buffer fr
; a src line record
; Input
;  PathName-ptr to PN buf
; Ret:
; If no errs
;   (Y)=len of filename
;   (A)=space
;
GetPNStr    LDY    #64
            LDA    #SPACE
L92C0       STA    (PathP),Y       ;First blank the pathname buffer
            DEY
            BNE    L92C0
            TYA                    ;Y=A=0
            STA    (PathP),Y       ;len byte
;
            LDY    #0
L92CA       JSR    WhiteSpc        ;Get char fr src line rec
            BEQ    L92E7           ;If sp/cr, done
            JSR    ToUpper
            CMP    #SPACE
            BCS    L92DB
L92D6       LDA    #$40            ;Char is invalid
            JSR    DOSErrs         ;Report as "Invalid PN system"
;
L92DB       INY
            STA    (PathP),Y
            CPY    #64
            BCC    L92CA
            JSR    WhiteSpc        ;CR?
            BNE    L92D6           ;No, error
;
L92E7       TYA
            LDY    #0
            STA    (PathP),Y       ;Set len byte
            TAY
            LDA    #SPACE
            RTS
            REP    50
;
; Print src file name & associated messages
;
L92F0       LDA    PassNbr         ;Is pass 1?
            BEQ    L92F8           ;Yes
            BIT    ListingF        ;Pass2:Is listing on?
            BMI    doRtn6          ;Yes
;
L92F8       LDA    #>LD7C7         ;include file
            LDY    #<LD7C7
            LDX    FCTIndex        ;=2/4
            CPX    #InclFile
            BEQ    L9306
;
            LDA    #>LD7B7         ;src file
            LDY    #<LD7B7
L9306       STA    Msg2P
            STY    Msg2P+1
;
            LDX    #$10
            JSR    L7E19           ;Print msg
            LDA    FileNbr
            JSR    PrByte
            LDA    #SPACE
            JSR    PutC
            LDA    #'='
            JSR    PutC
            LDA    #'>'
            JSR    PutC
;
            LDY    #0
            LDA    (PathP),Y
            TAX                    ;# of chars to print
            SEC                    ;Add 1 to skip
            LDA    PathP
            ADC    #0
            STA    Msg2P           ; past len byte
            LDY    PathP+1
            BCC    L9334
            INY
L9334       STY    Msg2P+1
;
            JSR    L7E19           ;Print src PN
            JSR    IsVideo         ;Video output?
            BEQ    doRtn6          ;Yes, just ret
;
            LDY    #0
L9340       LDA    LD7B7,Y         ;Src file #
            JSR    VidOut
            INY
            CPY    #$10
            BCC    L9340
;
            LDA    #BS
            JSR    VidOut
            LDY    #0
            LDA    (PathP),Y       ;Get len byte of filename
            TAX
            INY                    ;Skip past len byte
L9356       LDA    (PathP),Y       ;Get char
            JSR    VidOut
            INY
            DEX
            BNE    L9356
doRtn6      RTS
            REP    50
;
; INCLUDE directive
; We can't declare a INCLUDE directive in
; an INCLUDE or a MACRO defn file
;
L9360       LDA    IDskSrcF
            BPL    L9369
L9364       LDX    #$16            ;incl/chn nesting
            JMP    L90B1
;
L9369       LDA    MacroF          ;Processing macros?
            BMI    L9364           ;Err -> INCLUDE in a macro defn file
;
            JSR    NxtField        ;No, Point @ PN
            LDA    #$80
            STA    IDskSrcF
            JSR    LD3B4           ;Get ptr to next srcline & save it
;
            LDX    #InclFile
            JSR    L9D51           ;Save curr line # of CHN/SRC file
            JMP    L929C           ; b4 opening the INCLUDE file
            REP    50
;
; MACLIB directive - pg 115
; MacroF  $00=not using macros
; non-zero-macros enabled
; $04,$06
; $40-macro had been invoked
; $80-curr srcline is an expanded stmt
;
L937F       LDX    #$06            ;Flag we are going
            STX    MacroF          ; to use macros
            LDA    PassNbr         ;Pass 2?
            BNE    L93AE           ;Yes
;
            LDA    StrtSymT+1      ;Chk directive is b4
            CMP    EndSymT+1
            BNE    L9393           ; declaration of 1st idfer
            LDA    StrtSymT
            CMP    EndSymT
            BEQ    L9396
L9393       JMP    L9453
;
L9396       LDA    DskListF        ;Output listing to file?
            BNE    L93A0           ;Yes
;
            LDX    #>MacExpBuf     ;$7200
            LDA    #<MacExpBuf
            BNE    L93A6           ;always
;
L93A0       LDX    FBufTbl+MacFile
            LDA    FBufTbl+MacFile+1
;
; (MemTop)  =$6E00 if Disk Listing
; otherwise =$7200 (macro expansion buf)
;
L93A6       STX    MemTop
            STX    RLDEnd
            STA    MemTop+1
            STA    RLDEnd+1
;
L93AE       LDA    FCTIndex        ;Save for later
            PHA
            JSR    NxtField        ;Prepare to parse operand field
            LDX    #MacFile
            JSR    SetPNBuf        ;Use MACRO PN buf
            JSR    GetPNStr        ;Get the maclib prefix
            PLA
            TAX
            JSR    SetPNBuf        ;Reset the pointers
            JMP    DrtvDone
            REP    50
;
; IBUFSIZ directive
; The directive can be declared as
; 1) IBUFSIZ 2048 or
; 2) IBUFSIZ 8
; Case 1) Operand > 256 & is treated as # of bytes
; Case 2) Operand < 128 & is the # of mempages
; In both cases, the work buffers will align at
; the start of a mempage
; NB These directives must be declared b4 any
; symbols/identifers, and cannot be in an
; INCLUDE file
; min size of SBuf/IBuf = 1 mempage
;
L93C4       LDX    #InclFile
            DB     $2C
; SBUFSIZ directive
L93C7       LDX    #ChnFile
            LDA    PassNbr         ;Pass 1?
            BNE    L93FC           ;No
;
            TXA                    ;Save (X)
            PHA
            JSR    L9439           ;Get # of pages
            PLA
            TAX                    ;X=2,4
            LDA    ValExpr+1       ;Is requested # of mem pages
            CMP    XA056+1,X       ;  =< curr bufsize? ($A059,$A05B)
            BCC    L93FF           ;Less than
            BEQ    L93FC           ;Same size, no further action
;
; When size of SBuf is increased/decreased, we need to
; adjust the ptrs to the start of 1) IBuf & 2) SymTbl
; When size of IBuf is increased/decreased we need to
; adjust the ptr to the start of SymTbl only.
; Do we need to ensure there is 1 mempage btwn
; the end of SBuf & start of IBuf?
;
            LDY    XA056+1,X       ;No, bufsize has increased so save
            STY    ValExpr         ; curr bufsize here temporarily
            STA    XA056+1,X       ;Set new bufsize
            SEC
            SBC    ValExpr
            CLC
            PHA                    ;(A)=# of pages to increment
            ADC    XA074+3,X       ;$A079/$A07B since X=2 or 4
            STA    XA074+3,X       ;NB.($A07A,7B) has not been initialised!
            PLA
            CLC
            ADC    StrtSymT+1
            STA    StrtSymT+1      ;New start of Symbol table
            STA    EndSymT+1
            CMP    MemTop+1        ;Chk within mem limits
            BCS    L940F           ;err
L93FC       JMP    DrtvDone
;
; (A)=new bufsize (in mempages)
;
L93FF       CPX    #ChnFile        ;Are we resizing the SRC buf?
            BNE    L9414           ;No
;
            CLC                    ;X=2
            ADC    XA074+1,X       ;Chk that the EO SBuf ($A077)
            SEC
            SBC    #1
            CMP    XA06A+1,X       ; is above ($A06D) - bug?
            BCS    L9414           ;($A06D) has not been initialised!
L940F       LDX    #$3C            ;bufsiz err
            JMP    L9441
;
L9414       BEQ    L93FC
            LDA    ValExpr+1       ;New size of ibuf/sbuf
            LDY    XA056+1,X       ;Curr size of ibuf/sbuf ($A059,$A05B)
            STA    XA056+1,X
            TYA
            SEC
            SBC    ValExpr+1
            STA    ValExpr+1       ;# of pages to decrement
            LDA    XA074+3,X       ;$A079/$A07B since X=2/4
            SEC
            SBC    ValExpr+1
            STA    XA074+3,X
;
            LDA    StrtSymT+1      ;More mem for sym table
            SEC
            SBC    ValExpr+1
            STA    StrtSymT+1
            STA    EndSymT+1
            JMP    L93FC
            REP    50
;
; Get # of mem pages
;
L9439       LDX    FCTIndex
            CPX    #ChnFile        ;SRC file?
            BEQ    L9447           ;yes
;
            LDX    #$3A            ;Invalid fr INCLUDE
L9441       JSR    RegAsmEW
L9444       JMP    CanclAsm
;
L9447       LDA    StrtSymT+1      ;Is symbol table empty?
            CMP    EndSymT+1
            BNE    L9453
            LDA    StrtSymT
            CMP    EndSymT
            BEQ    L9458           ;Yes
L9453       LDX    #$30            ;No, invalid after 1st idfer
            JMP    L9441
;
L9458       JSR    L9013
            BCS    L9444
            LDA    ValExpr+1       ;If 16-bit value then ignore
            BNE    L9463           ; lobyte by taking hibyte
            LDA    ValExpr         ;Since hibyte is 0, take lobyte to be # of mempages
L9463       STA    ValExpr+1       ;bufsize is returned here in terms # of mempages
            BEQ    L9469           ;Can't be 0
            BPL    doRtn7          ;Allow only mempages < $7F (actually $78)
L9469       LDX    #$06            ;Overflow err
            JMP    L9441
doRtn7      RTS
            REP    50
;
; SW16 directive
; This is acceptable
;        SW16  operand
; where operand evaluates to a 16-bit addr
;
L946F       JSR    SkipSpcs
            JSR    ChrGot
            BCC    L948C           ;alphabetic char
            CMP    #CR
            BEQ    L9482
            CMP    #'              ;' ;comment char?
            BEQ    L9482           ;yes
L947F       JMP    L9193           ;directive operand error
;
L9482       LDA    #<SWEET16       ;Integer BASIC's original location
            STA    ValExpr+1
            LDA    #>SWEET16
            STA    ValExpr
            BNE    L9498           ;always
;
L948C       JSR    EvalExpr        ;process operand
            BCC    L9494           ;good
            JMP    L94EE           ;report err
;
L9494       LDA    NxtToken        ;sp/cr?
            BNE    L947F           ;No, error
;
L9498       LDA    #3
            STA    Length
            LDA    #$01
            STA    SW16F           ;Flag SW16 opcodes can be assembled
            LDA    #$20            ;JSR opcode
            STA    GMC
L94A4       LDA    #%00100111
            STA    LstCodeF
            LDA    ValExpr
            STA    GMC+1           ;20 xx yy
            LDA    ValExpr+1
            STA    GMC+2
            LDA    RelExprF        ;abs
            BEQ    L94BD
;
            LDA    #$01            ;offset
            LDX    #$02
            LDY    #$00            ;Reverse order
            JSR    AddRLDEnt       ;Make RLD entry
L94BD       JMP    DrtvDone
            REP    50
;
; SW16 SET pseudo opcode is parsed as a directive
;
L94C0       LDA    #$10            ;pseudo opcode
            STA    GMC
            LDA    #3
            STA    Length
            JSR    EvalExpr        ;Rn (0-15)
            BCS    L94EE
            LDA    NxtToken
            CMP    #$01            ;Do we have a ,?
            BNE    L94EC           ;No
            JSR    IsSW16Reg
            BNE    L94F2           ;No
            LDA    ValExpr
            ORA    GMC
            STA    GMC             ;$1n where n=0-F
            INY
            INY
            JSR    EvalExpr        ;Eval 2-byte constant
            BCS    L94EE
            LDA    NxtToken        ;Must be cr/space
            BEQ    L94A4
;
            LDA    #$34            ;Invalid delimiter err
L94EB       DB     $2C
L94EC       LDA    #$24            ;directive operand err
L94EE       TAX
            JSR    RegAsmEW
L94F2       JMP    DrtvDone
            REP    50
;
; Chk if sw16 reg ($00-$0F)
; Z=0
; Z=1 - yes
; (Y)-unchanged?
;
IsSW16Reg   LDA    ValExpr+1
            BNE    L9500
            LDA    #$F0
            BIT    ValExpr         ;valid values 0-F
            BNE    L9500
            RTS
;
L9500       PHP
            LDX    #$32            ;SW16 reg err
            JSR    RegAsmEW
            PLP
            RTS
            REP    50
;
; Print Code Section. The following may be printed
; (1) program counter
; (2) generated machine code,
; (3) expr result/branch target field
; (4) cycle time
; of the assembled instruction
; Ref: Page 81
; Input
;  (LstCodeF)
; msb=0 => output ER field
; For the other bits: 0 => precede printing
; of a generated code byte with a space
; NB. Not all bits will be used even if they have been set
;
ListCode    BIT    ListingF        ;Is listing on?
            BPL    doRtn8          ;No
            BIT    CondAsmF        ;Conditional assembly?
            BPL    ListPC          ;No
;
; A total of 17 chars are printed for code section
;
            LDA    #SPACE          ;Unassembled src line
            JSR    PutC
            LDA    #'S'
            JSR    PutC
            LDY    #14
            LDA    #SPACE
L951E       JSR    PutC
            DEY
            BPL    L951E
            BIT    LstCyc          ;Print cycle times?
            BMI    Pr3BL           ;Yes, just print spaces instead
doRtn8      RTS
;
ListPC      JSR    PrtPC           ;Print PC field
            JSR    PutC            ; follow by :
            LDA    LstCodeF
            STA    SavLstF         ;Save temporarily
            ASL    LstCodeF
            ASL    LstCodeF
            LDX    #0
            LDY    #0
            ASL    LstCodeF        ;bit20 is usually 1
            BCS    LCLoop
;
            LDA    #SPACE
            JSR    PutC
            INY
Pr1BL       LDA    #SPACE
            JSR    PutC
            INY
LCLoop      CPX    Length          ;Have all generated code bytes been printed?
            BCC    PrMCode         ;No
            CPY    #12             ;NB. By the time 4 MC bytes had
            BCS    LCDone          ; been printed, (Y)=12
            LDA    SavLstF         ;Is there a result field?
            BPL    Pr1BL           ;No, just print a space
            CPY    #8              ;Yes, print it now?
            BCC    Pr1BL           ;Not yet
;
            LDA    ERfield+1       ;offset 8 fr :
            JSR    PrByte
            LDA    ERfield
            JSR    PrByte
            JMP    LCDone
;
PrMCode     LDA    GMC,X           ;Up to 4 bytes of
            JSR    PrByte          ; generated obj code
            INX                    ; are printed/line
            INY                    ;NB. When 3 MC bytes had
            INY                    ; been printed, (Y)=8 here
            ASL    LstCodeF
            BCC    Pr1BL
            BCS    LCLoop          ;always
;
LCDone      BIT    LstCyc          ;Print cycle times?
            BPL    L959D           ;no
            LDX    NumCycles
            BNE    PrCTimes
;
Pr3BL       LDX    #3              ;Output blanks when
            JSR    PrBlnkX         ;  no cycle times printed
            BEQ    L959D           ;always
;
PrCTimes    LDA    #'('            ;Print Cycle times
            JSR    PutC
            LDA    #'E'
            CPX    #16
            BCS    L9595
            TXA                    ;# of cycles
            AND    #$0F
            ORA    #'0'
L9595       JSR    PutC
            LDA    #')'
            JSR    PutC
L959D       LDA    SavLstF         ;Restore
            STA    LstCodeF
            RTS
            REP    50
;
; Print src line
; Input
;  (Src2P)-Point to BO a src line
; Ref pg 82 - TAB control
;
LstSrcLn    LDA    ZAB
            CMP    #$82
            BNE    L95AB
            JMP    PutCR
;
L95AB       JSR    PrtDecS         ;line #
            LDY    #-1
            STY    TabTIdx         ;index tabtable
            INY                    ;=0
L95B3       LDA    (Src2P),Y       ;get src char
            LDX    TabChar         ;Get user-defined tabchar
            CPX    #SPACE          ;Is it a space?
            BEQ    L95BF           ;Yes
            CPX    #TAB
            BNE    L95F5
;
L95BF       CMP    #TAB            ;Is src char a TAB?
            BEQ    L95C7           ;Yes
            CMP    #SPACE
            BNE    L95F5
;
L95C7       INC    TabTIdx
            LDX    ZAB
            INX                    ;-1?
            BEQ    L95F3           ;Yes
            LDX    TabTIdx         ;1st tab stop?
            BEQ    L95E3           ;Yes
            CPX    #2              ;3rd tab stop?
            BEQ    L95E3           ;Yes
            BCS    L95F3
            LDA    ZAB             ;2nd tabstop
            CMP    #$7F            ;Alt block?
            BEQ    L95E3
            BIT    Bit20
            BNE    L95C7
;
; Only the first 3 editor tabs are used if
; first tab setting is >= 12
;
L95E3       LDA    TabTable,X      ;Get tab stop fr editor's tab table
            SEC
            SBC    PrtCol
            BCC    L95F3
            BEQ    L95F3
            TAX                    ;(A)=# of spaces to print
            JSR    PrBlnkX
            BEQ    L95F8           ;always
;
L95F3       LDA    #SPACE
L95F5       JSR    PutC
L95F8       INC    Src2P           ;Skip src tab char
            BNE    L95FE
            INC    Src2P+1
L95FE       CMP    #CR
            BNE    L95B3
            RTS
            REP    50
;
; Output char in Acc thru printer or video
; A, X, Y regs are preserved
;
PutC        STA    SaveA           ;Save the regs
            TXA
            PHA
            TYA
            PHA
            LDA    SaveA           ;Restore char
            CMP    #FF
            BEQ    L963A
            CMP    #CR
            BNE    L9666
;
            LDX    PrtCol          ;# of chars printed so far
            BNE    L961E
            LDA    #SPACE          ;newline
            JSR    PrtChar
            LDA    #CR
L961E       INC    LineCnt
            LDX    LineCnt
            CPX    LogPL
            BCC    L9666
            LDA    PhyPL           ;Did user set this(via ctl-string)?
            BNE    L9632           ;Yes
            BIT    SubTtlF         ;SBTL directive?
            BVS    L9642           ;Yes
;
L962E       JSR    DoLF            ;LF
L9631       INX
L9632       CPX    PhyPL
            BCC    L962E
            BEQ    L962E
            BCS    L9652           ;always
;
L963A       LDX    LineCnt
            BEQ    L9674
            LDA    PhyPL           ;Is this set?
            BNE    L9631           ;Yes
;
L9642       JSR    IsVideo         ;Output via video?
            BNE    L964D           ;No
;
            JSR    DoLF            ;Yes, just output space followed by cr
            JMP    L9652
;
L964D       LDA    #FF             ;Send a FormFeed to printer
            JSR    PrtChar
;
L9652       LDA    #0
            STA    LineCnt
            SED
            SEC                    ;add 1
            ADC    PageNbr
            STA    PageNbr
            LDA    #0
            ADC    PageNbr+1
            STA    PageNbr+1
            CLD
            JMP    L9674
;
L9666       LDX    LineCnt
            BNE    L9671
            LDX    PrtCol
            BNE    L9671
            JSR    L979F           ;Print page header
L9671       JSR    PrtChar
;
L9674       PLA                    ;Restore X,Y regs
            TAY
            PLA
            TAX
            LDA    SaveA
            RTS
            REP    50
;
; ($967B)
;
DoLF        LDA    #SPACE
            JSR    PrtChar
            LDA    #CR
            JMP    PrtChar
            REP    50
;
; X=# of spaces
; Z=1
;
PrBlnkX     LDA    #SPACE
            JSR    PutC
            DEX
            BNE    PrBlnkX
            RTS
            REP    50
;
PrtPC       LDA    PC+1
            LDX    PC
            JSR    PrByte
            TXA
            JSR    PrByte
            LDA    #':'
            RTS
            REP    50
;
; Prints (A) as 2 hex digits
; (X),(Y) preserved
;
PrByte      PHA                    ;save
            LSR
            LSR
            LSR
            LSR
            JSR    PrHex
            PLA
PrHex       AND    #$0F
            ORA    #'0'
            CMP    #'9'+1
            BCC    L96AF
            ADC    #$06
L96AF       JMP    PutC
            REP    50
;
; A, X, Y-regs are preserved
; Print BCD # ($60-62) out as a 5-char dec string
; The BCD digits are packed in 3 mem bytes
; but only up to 5 nybbles will be used.
; 12 34 05 is printed as 53412
; The output dec string will be preceded
; by the required # of leading spaces
;
PrtDecS     PHA
            TYA
            PHA
            TXA
            PHA
            LDY    #%00000011
            STY    ZCF             ;Make sure msb=0 for this byte
            LDX    #%00001010      ;Start w/lower nybble
            STX    ZCE             ; of the 3rd BCD #
;
            LDX    #5              ;5 chars
L96C1       DEY                    ;=2 on fall thru
L96C2       LDA    BCDNbr,Y        ;$60-$62
            LSR    ZCE
            PHP                    ;Save C for later
            BCC    L96CE
            LSR                    ;if odd, use the upper nybble
            LSR                    ; by shifting it
            LSR
            LSR                    ; into lower nybble
L96CE       AND    #$0F            ;Isolate BCD digit (0-9)
            BNE    L96DC           ;non-zero
;
            BIT    ZCF             ;Was prev output char a leading space?
            BMI    L96DC           ;No => output as a '0'
            CPX    #1              ;unit's digit?
            BEQ    L96DC           ;Yes => must print as a '0'
            LDA    #$10            ;Print as a leading space
;
L96DC       EOR    #'0'
            JSR    PutC
            CMP    #'0'            ;C=1 if (A)='0'-'9'
            ROR    ZCF             ;Save C for next iteration
            PLP
            DEX
            BEQ    L96ED           ;done
            BCS    L96C2           ;Use the same byte
            BCC    L96C1           ;Was even => next byte
;
L96ED       LDA    #SPACE
            BIT    MacroF          ;Macro Expanded line?
            BPL    L96F5           ;No
            LDA    #'+'
L96F5       JSR    PutC
            PLA
            TAX
            PLA
            TAY
            PLA
            RTS
            REP    50
;
; Output char via monitor
;
MonCOUT     PHA
            ORA    #$80
            BIT    RDROM2
            JSR    COUT1           ;video h/w
            BIT    RDBANK2
            PLA
            RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A=output char to monitor/file/printer
; Ret:
; (A),(X),(Y)-preserved
;
PrtChar     PHA
            CMP    #SPACE          ;ctrl-chars?
            BCC    L9715           ;yes
            INC    PrtCol          ;# of chars printed so far
            BCS    L9721           ;printable chars
;
L9715       CMP    #FF             ;Is it a CR?
            BCC    L9721
            CMP    #CR+1
            BCS    L9721
            LDA    #0              ;Yes
            STA    PrtCol          ;Reset cnt
L9721       LDA    PrSlot          ;Output thru 40-col video?
            BEQ    L9786           ;Yes
            BIT    DskListF        ;Listing to file?
            BPL    L9777           ;No, printer
;
            STX    SaveX           ;Save X,Y-regs
            STY    SaveY
            LDX    LstDBIdx
            PLA
            PHA
            CMP    #CR
            BEQ    L9739
            CMP    #FF
            BNE    L9765           ;Proceed to save to buf
;
; Flush it - when char is FF/CR
;
L9739       AND    #$7F            ;Make sure its std ASCII
            STA    LstDBuf,X       ;Save char in data buffer
            INX
            STX    WrLstLen
            LDA    #0
            STA    WrLstLen+1
            JSR    PRODOS8
            DB     $CB
            DW     WrLstPB
            BEQ    L9761
;
            PHA                    ;ProDOS error code
            LDA    #0
            STA    DskListF        ;Reset all subsequent
            LDA    VidSlot         ; output through
            STA    PrSlot          ; video card
            LDX    #LstFile
            JSR    ClsFileX
            PLA
            JSR    DOSErrs         ;don't come back
;
L9761       LDX    #0
            BEQ    L976F           ;always
L9765       AND    #$7F            ;Save char in Circular Data buf
            STA    LstDBuf,X
            INX
            BNE    L976F
            BEQ    L9765           ;Buf is filled so store @ beginning
;
L976F       STX    LstDBIdx        ;# of bytes to write
            LDX    SaveX
            LDY    SaveY
            PLA
            RTS
;
; Output via I/O hooks set by a PR#n cmd
;
L9777       PLA
            PHA
            ORA    #$80
            BIT    RDROM2
            JSR    COUT
            BIT    RDBANK2
            PLA
            RTS
;
; 40 col output via video H/W
; (Y)-preserved
;
L9786       STY    SaveY
            LDY    PrtCol
            PLA
            CMP    #SPACE
            BCC    L9797           ;Non-printable char
;
            CPY    WinLeft         ;R we within display window?
            BCC    L979C
            CPY    WinRight
            BCS    L979C           ;No
;
L9797       LDY    SaveY
            JMP    VidOut
;
L979C       LDY    SaveY
            RTS
            REP    50
;
; Print the header
; Ret:
; (A) & (Y) preserved
;
L979F       BIT    ListingF        ;listing on?
            BMI    L97A4           ;yes
            RTS
;
L97A4       BIT    SubTtlF         ;SBTL directive?
            BVS    L97A9           ;Yes
            RTS
;
L97A9       PHA
            TYA
            PHA
            LDY    FileNbr
            BIT    Bit40
;
            JSR    Prt1Dec         ;print it
            LDA    #SPACE
            JSR    PrtChar
            LDY    #0
            LDA    (SrcPathP),Y    ;Get len byte of Pathname
            TAX
            CMP    #16
            BCC    L97D2
            LDX    #0
            TAY                    ;Index last char of PN
            LDA    #'/'
L97C7       CMP    (SrcPathP),Y    ;Look for a trailing /
            BEQ    L97CF           ;Got it
            INX
            DEY
            BNE    L97C7           ;Keep looking
L97CF       INY
            BNE    L97D4           ;always
;
L97D2       LDY    #1              ;Skip past len byte
L97D4       LDA    (SrcPathP),Y    ;Get char of filename
            JSR    PrtChar
            INY
            DEX
            BNE    L97D4
            LDA    #SPACE
            JSR    PrtChar
L97E2       LDY    PrtCol          ;Print reqd # of blanks
            CPY    #19
            BCS    L97F0
            LDA    #SPACE
            JSR    PrtChar
            JMP    L97E2
;
L97F0       LDX    #0
            BIT    SubTtlF         ;Is there a title string?
            BPL    L9801           ;No
L97F6       LDA    SubTitle,X
            BEQ    L9801           ;null-terminated
            JSR    PrtChar
            INX
            BNE    L97F6
L9801       LDA    #SPACE          ;Print reqd # of spaces
            JSR    PrtChar
            INX
            CPX    #36
            BCC    L9801
;
            LDX    #0
L980D       LDA    DateTime,X      ;Follow by printing
            JSR    PrtChar         ;the DATE & TIME
            INX
            CPX    #16
            BCC    L980D
;
            LDX    #0
L981A       LDA    PageTxt,X
            JSR    PrtChar
            INX
            CPX    #6
            BCC    L981A
;
            LDX    #1
            CLV                    ;Bug?
L9828       LDY    PageNbr,X       ;page #
            JSR    Prt1Dec
            DEX
            BPL    L9828
;
            LDA    #CR
            JSR    PrtChar
            LDA    #SPACE
            JSR    PrtChar
            LDA    #CR             ;Output a blank line
            JSR    PrtChar
            LDA    #2
            STA    LineCnt
            PLA
            TAY
            PLA
            RTS
;
PageTxt     ASC    '               PAGE '
            REP    50
;
; ($984D)
; Entry:
;   (Y)=BCD #
; Ret:
;
Prt1Dec     LDA    #%10101010
L984F       ASL
            PHA
            TYA
            BCC    L9858
            LSR                    ;Shift upper nybble
            LSR
            LSR
            LSR                    ; to lower nybble
L9858       AND    #$0F            ;Isolate lonybble
            BNE    L985E
            BVC    L9866
L985E       ORA    #'0'
            JSR    PrtChar
            BIT    Bit40
L9866       PLA
            BPL    L984F
            RTS
            REP    50
;
; Entry:
;   (X)=index into text message block
;
L986A       LDA    ASEndTxt,X
            CMP    #SPACE
            BCC    L9877
            JSR    VidOut
            INX
            BNE    L986A
L9877       TAY
            BEQ    PrtCR
            RTS
;
PrtCR       LDA    #CR
            JMP    VidOut
            REP    50
;
; Entry:
;   A=char to be displayed on ROM monitor/video card
; A, X, Y regs are preserved
;
VidOut      STY    SaveY
            STX    SaveX
            PHA                    ;Char to be displayed
            LDA    VidSlot         ;slot #
            BEQ    L98A2
;
            JSR    SwapIO          ;Swap in 80-col display
            PLA
            PHA
            ORA    #$80
            BIT    RDROM2
            JSR    COUT
            BIT    RDBANK2
            JSR    SwapIO          ;Swap out 80-col display
            PLA
L989D       LDY    SaveY
            LDX    SaveX
            RTS
;
L98A2       PLA
            JSR    MonCOUT
            JMP    L989D
;=================================================
SwapIO      LDY    #3
L98AB       LDA    IOHooks,Y
            PHA
            LDA    CSWL,Y          ;Save curr I/O Hooks
            STA    IOHooks,Y       ;vector here
            PLA
            STA    CSWL,Y          ;Set I/O to Firmware
            DEY
            BPL    L98AB
            RTS
;
IOHooks     DW     BASICINT        ;$C300
            DW     RDKEY
;=================================================
; Not used?
L98C1       LDA    #$20
L98C3       STA    (BASL),Y
            INY
            CPY    WNDWDTH
            BCC    L98C3
            RTS
            REP    50
;
; Do a Form Feed if output to printer
;
PrtFF       JSR    IsVideo         ;Video output?
            BEQ    L98D5           ;Yes
;
            LDA    #FF             ;send to printer
            JMP    PutC
;
L98D5       LDA    #SPACE
            JSR    PutC
            JMP    PutCR
            REP    50
; Entry:
;  A - slot #
; Ret:
;  Z=1 - output thru video
;  X,Y - not used
;
IsVideo     LDA    PrSlot          ;Std 40-col?
            BEQ    Exit1
            CMP    #3              ;Slot 3 80-col card
Exit1       RTS
;
Tens2Tbl    DB     0,10,20,30,40,50,60,70,80,90
            REP    50
;
; Open a file for reading/writing
; Destroy if it's OBJ/LST file and create a new one
; Entry:
;   X=FCTIndex (0,2,4,6,8)
;
Open4RW     JSR    SetPNBuf        ;Set ptr to correct PN buf
            LDA    #0
            STA    XA04C,X         ;Zero flag
            STA    XA04C+1         ;Len of partial line rec
            LDA    PathP
            STA    GFIPN
            STA    DestroyPN
            LDA    PathP+1
            STA    GFIPN+1
            STA    DestroyPN+1
            JSR    PRODOS8
            DB     $C4
            DW     GFInfoPB
            TAY                    ;Save err code if any
            CPX    #LstFile
            BEQ    L991A
            CPX    #ObjFile
            BNE    L9962           ;If (X)=2,4,6 ==> Don't destroy these
            STX    ObjDBIdx        ;Zero this
;
L991A       TYA                    ;Does OBJ/LST file exists?
            BEQ    L9923           ;Yes
            CMP    #$46            ;File not found?
            BEQ    L9948           ;Yes, so that's ok for OBJ/LST files
            BNE    L997E           ;Some other errors, report it
;
L9923       LDA    GFIftype        ;Check the file type
            CMP    #BINtype
            BEQ    L993D           ;Proceed to destroy it
            CMP    #RELtype        ;Kill all files whose type
            BNE    L993D           ; is not REL including SYS
            CMP    #SYStype        ;On fall thru (A)=REL
            BNE    L9939           ;Always! -> destroy
;
L9932       CMP    ftypeT,X        ;Same filetype?
            BNE    L997C           ;No, err
            BEQ    L993D           ;Yes
;
L9939       CPX    #LstFile
            BEQ    L9932
;
L993D       JSR    PRODOS8
            DB     $C1
            DW     DestroyPB
            BEQ    L9948
            JSR    DOSErrs
;
L9948       LDA    PathP
            STA    CreatePN
            LDA    PathP+1
            STA    CreatePN+1
            LDA    ftypeT,X
            STA    CrFType
            JSR    PRODOS8
            DB     $C0
            DW     CreatePB
            BEQ    L9981           ;If no errs, check it's there
            BNE    L997E           ;always
;
; Handle SRC,INCLUDE,MACRO files
; (X=)2,4,6
; If macro file doesn't exist, it is not
; considered fatal. Just ret to mainloop
;
L9962       TYA                    ;If no errs then
            BEQ    L9975           ; the file exists
            CPX    #MacFile
            BNE    L997E
            CMP    #$46            ;File not found?
            BNE    L997E
;
            LDX    #$20            ;Macro file not found
            JSR    RegAsmEW
            JMP    CanclAsm
;
L9975       LDA    GFIftype        ;Ensure it's a TXT file
            CMP    #TXTtype
            BEQ    L9989           ;Proceed to open
;
L997C       LDA    #$11            ;EI error code
L997E       JSR    DOSErrs
;
L9981       JSR    PRODOS8         ;Chk newly created OBJ/LST file is there
            DB     $C4
            DW     GFInfoPB
            BNE    L997E           ;Sorry, some sort of OS error
;
L9989       LDA    PathP           ;Open for I/O
            STA    OpenPN
            LDA    PathP+1
            STA    OpenPN+1
            LDA    FBufTbl,X
            STA    OpenFBuf
            LDA    FBufTbl+1,X
            STA    OpenFBuf+1
            JSR    PRODOS8
            DB     $C8
            DW     OpenPB
            BEQ    L99AA
            JSR    DOSErrs
L99AA       LDA    OpenRN
            STA    RefNbrT,X
            RTS
            REP    50
;
; ($99B1)
; Close the file flushing it only if its an OBJ file
; Entry:
;   (X)-index into file control tables
; X,Y-preserved
;
ClsFile     TYA
            PHA
            TXA
            PHA
            BNE    L99BD
; (X)=0
            JSR    Flush           ;OBJ file
            PLA
            PHA
            TAX
;
L99BD       JSR    SetPNBuf
            JSR    ClsFileX
            PLA
            TAX
            PLA
            TAY
            RTS
;=================================================
; Entry:
;  (X)=index into File Control Table
;  RefNbrT
; Ret:
;  RefNbrT
; (X),(Y)-unchanged
;
ClsFileX    LDA    RefNbrT,X
            BEQ    Exit2           ;Already closed
            STA    CloseRN
            JSR    PRODOS8
            DB     $CC
            DW     ClosePB
            BEQ    L99DB
            JSR    DOSErrs
;
L99DB       STA    RefNbrT,X       ;zero the slot
Exit2       RTS
            REP    50
;
; Write out all obj code
; For REL files, append RLD and ESD (if required)
; Create a new objfilename fr old name
; (GenF)=$00,$40,$80,$8F,$FF
; Entry:
;   N=1 - No code generation
;   V=1 - Write to disk file
;   V=0 - Write to mem
;  RelCodeF=$80
; Ret:
;  GenF=$C0
;
L99DF       BIT    GenF            ;Generate code?
            BPL    L99E4
Exit3       RTS                    ;No
;
L99E4       BVC    Exit3           ;Writing to mem, skip code below
            PHA                    ;Save A,X,Y regs
            TYA
            PHA
            TXA
            PHA
            LDA    RelCodeF        ;Writing REL codefile?
            BMI    L99F2           ;Yes
            JMP    L9AA2
;
L99F2       LDA    CodeLen         ;Save temporarily cos
            STA    CodeImgLen      ; its val will changed
            LDA    CodeLen+1       ; when the RLD is appended
            STA    CodeImgLen+1    ; by calling Wr1Byte
            LDA    MemTop          ;leftovers?
;
            SEC
            LDA    RLDEnd
            SBC    #4
            STA    RLDEnd
            LDA    RLDEnd+1
            SBC    #0
            STA    RLDEnd+1
;
            LDA    MemTop
            STA    RLDEntP
            LDA    MemTop+1
            STA    RLDEntP+1
;
; Write out all entries in Relocation Dictionary
;
L9A11       LDA    RLDEntP         ;Point @ EO of entry
            SEC
            SBC    #4
            STA    RLDEntP
            LDA    RLDEntP+1
            SBC    #0
            STA    RLDEntP+1
;
            LDA    RLDEnd
            CMP    RLDEntP
            LDA    RLDEnd+1
            SBC    RLDEntP+1
            BCS    L9A35           ;Finish writing out all RLD entries
;
            LDY    #3
L9A2A       LDA    (RLDEntP),Y     ;Write out RLD entry
            JSR    Wr1Byte         ;1st byte written is RLD flag byte
            DEY
            BPL    L9A2A
            JMP    L9A11           ;Next RLD entry
;
L9A35       LDA    #0              ;Mark EO RLD
            JSR    Wr1Byte         ; with a zero byte
            LDA    MemTop          ;Mark RLD is now empty
            STA    RLDEnd
            LDA    MemTop+1
            STA    RLDEnd+1
;
; This will write out all entries in the ESD if any
; The code scans through the entire symbol table
; looking for idfers which are marked as EXTeRNal/ENTRY
; The link field is not used at all because the nodes
; are stored one after another in contiguous mem.
;
            LDA    StrtSymT        ;Start fr BO symbol table
            CLC
            ADC    #2
            STA    WrkP            ;Skip link field
            LDA    StrtSymT+1
            ADC    #0
            STA    WrkP+1
;
L9A4F       LDY    #0
L9A51       LDA    (WrkP),Y        ;Get symbol's char
            BPL    L9A59           ;last char
            INY
            JMP    L9A51
;
L9A59       INY
            LDA    (WrkP),Y        ;Symbol's flag byte
            AND    #external+entry
            BEQ    L9A82           ;No, skip this entry
;
            STY    SymLen
L9A62       LDY    #0
L9A64       LDA    (WrkP),Y        ;Write out the symbolicname
            JSR    Wr1Byte
            INY
            CPY    SymLen
            BNE    L9A64
;
            LDA    (WrkP),Y        ;Write symbol's flag byte
            JSR    Wr1Byte
            INY                    ;lobyte of addr if ENTRY or
            LDA    (WrkP),Y        ;symbol # referred to by an RLD entry if EXTERN
            JSR    Wr1Byte
            INY
            LDA    (WrkP),Y        ;Hi-byte of addr if ENTRY
            JSR    Wr1Byte
            JMP    L9A84
;
L9A82       INY
            INY
L9A84       INY                    ;Skip link field of next Node
            INY
            INY                    ;Indexing symbolicname of next Node
            TYA
            CLC
            ADC    WrkP            ;Pointing @ next symbolic name
            STA    WrkP
            LDA    WrkP+1
            ADC    #0
            STA    WrkP+1
;
            LDA    WrkP
            CMP    EndSymT         ;Finish?
            LDA    WrkP+1
            SBC    EndSymT+1
            BCC    L9A4F           ;Loop back for more
;
            LDA    #$00            ;Marks EO ESD
            JSR    Wr1Byte
;
L9AA2       BIT    RelCodeF        ;REL file?
            BPL    L9AB9           ;No, BIN object file
            LDX    #ObjFile
            LDY    #0
            LDA    #0
            JSR    SetFPos         ;Position to BOF
            LDA    CodeImgLen      ;Store len of
            JSR    Wr1Byte         ; code image
            LDA    CodeImgLen+1
            JSR    Wr1Byte
;
; Create an OBJx name fr old name - ref pg 93
;
L9AB9       LDX    #ObjFile        ;Close this OBJ file
            JSR    ClsFile
            LDA    #$C0            ;Suppress code generation
            STA    GenF
            LDY    ObjPNB          ;len byte
            LDA    ObjPNB,Y
            CLC
            ADC    #1
            CMP    #'Z'+1
            BNE    L9AD3
            LDA    #'0'            ;start fr 0
            BNE    L9AD9           ;always
L9AD3       CMP    #'9'+1
            BNE    L9AD9
            LDA    #'A'
L9AD9       STA    ObjPNB,Y
            PLA
            TAX
            PLA
            TAY
            PLA
            RTS
            REP    50
;
; Write 1 byte
; Write out to file when buf is filled with 128 bytes
; Entry:
;  (A)-byte to be written
;  ObjDBIdx-# of bytes in buf/index to next byte to store
;
; Ret:
;  (FileLen)++
;  (CodeLen)++
; Preserved:
;  (A),(X)
;
Wr1Byte     STA    OneByte
            PHA
            TXA                    ;save X
            PHA
            LDX    ObjDBIdx
            LDA    OneByte
            STA    ObjDataB,X
            INC    ObjDBIdx        ;Is buffer full?
            BPL    L9AFB           ;No
            TYA                    ;Save Y
            PHA
            JSR    Flush           ;Write out to disk
            PLA
            TAY
;
L9AFB       INC    FileLen         ;curr filelen
            BNE    L9B01
            INC    FileLen+1
L9B01       INC    CodeLen         ;curr len of code image
            BNE    L9B07
            INC    CodeLen+1
L9B07       PLA
            TAX
            PLA
            RTS
            REP    50
;
; Write out generated object code
; Entry:
;   ObjDBIdx-# of bytes to write
;
Flush       LDX    #0
            JSR    SetPNBuf
            LDA    ObjDBIdx
            BEQ    L9B50           ;Nothing to write
            STA    WrObjLen
            STX    WrObjLen+1
            LDA    #>ObjDataB
            STA    WrObjDB
            LDA    #<ObjDataB
            STA    WrObjDB+1
;
            LDX    #0
            LDA    RefNbrT,X
            BEQ    L9B50           ;already closed
            STA    WrObjRN
            JSR    PRODOS8
            DB     $CB
            DW     WrObjPB
            BEQ    L9B50
;
            BIT    DskListF        ;Listing to file?
            BPL    L9B4D           ;No
            CMP    #$48            ;disk full
            BNE    L9B4D
;
            LDA    #0
            STA    DskListF
            LDA    VidSlot         ;Send all output
            STA    PrSlot          ; thru video card
            LDX    #LstFile
            JSR    ClsFile
            LDA    #$48            ;Disk Full
L9B4D       JSR    DOSErrs
;
L9B50       LDA    #0
            STA    ObjDBIdx        ;# of bytes to write
            RTS
            REP    50
;
; Mark the file position
; Entry:
;  A,Y-file posn
;  X-index into FCTs (X=0 only)
; Ret:
; Preserved:
; A,X,Y
;
SetFPos     STY    SMfposn
            STA    SMfposn+1
            PHA
            TYA
            PHA
            TXA
            PHA
            JSR    SetPNBuf
            TXA
            BNE    L9B69
            JSR    Flush           ;X=0 => write obj code
L9B69       PLA
            PHA
            TAX
            LDA    RefNbrT,X
            STA    SMarkRN
            LDA    #0
            STA    SMfposn+2
            JSR    PRODOS8
            DB     $CE
            DW     SMarkPB
            BEQ    L9B82
            JSR    DOSErrs
;
L9B82       PLA
            TAX
            PLA
            TAY
            PLA
            RTS
            REP    50
;
; Character Handler
; Get next assembly statement
; This subrtn should be part of src handler
; Entry:
;  DskSrcF -
;  MacroF -
;  FCTIndex - 2,4,6
;
; Ret:
;  SrcP
;  C=0 - more src lines to process
;  C=1 - all lines assembled
;  MacroF - $8x if macro expanded source line
;  (X) changed
;  FCTIndex
;  IDskSrcF-include file
;
GSrcLin     EQU    *
            LDA    DskSrcF         ;Are we using disk source files?
            BMI    L9B95           ;Yes
;
            LDA    SrcP            ;Chk if there are still
            CMP    TxtEnd          ; lines to be assembled
            LDA    SrcP+1
            SBC    TxtEnd+1
Exit4       RTS                    ;If C=1, done
;
L9B95       BIT    MacroF          ;Have a macro been invoked?
            BVS    L9B9D           ;Yes
            BPL    L9BA2           ;No
            BMI    L9B9F           ;Always -> Get stmt fr macro defn file
;
L9B9D       ASL    MacroF          ;=$80
L9B9F       JMP    L9CDD           ;Handle macro defn file
;
; Chain/Include files are handled here
;
L9BA2       LDX    FCTIndex        ;=2,4
            LDA    XA04C,X         ;Get flag
            STA    XA04C
            BIT    XA04C           ;Ready for processing?
            BVC    L9BBB           ;No
;
            LDA    SrcP            ;Are we done with this
            CMP    XA06A,X         ; $A06C/$A06E
            LDA    SrcP+1          ; chunk of source code?
            SBC    XA06A+1,X
            BCC    Exit4           ;No
;
L9BBB       JSR    L9BFC           ;Read another block
            BCS    L9BCC
;
            LDA    XA060,X         ;$A062/$A064
            STA    SrcP            ;Point @ beginning
            LDA    XA060+1,X
            STA    SrcP+1          ; of block of source code
            CLC
            RTS
;
L9BCC       LDX    FCTIndex
            JSR    ClsFile         ;Close it
            CPX    #ChnFile        ;SRC
            BEQ    L9BD8
            JSR    L9D61           ;X=4
;
L9BD8       LDA    #0
            STA    XA04C,X         ;X=2/4
            CPX    #InclFile
            BCS    L9BE3
            SEC                    ;SRC was closed
            RTS
;
L9BE3       BEQ    L9BE6           ;(X)=4
            BRK
;
L9BE6       DEX
            DEX                    ;=2
            STX    IDskSrcF        ;NB. only msb has meaning
            STX    FCTIndex
;
; An INCLuded/macro defintion file was closed. We
; must return to the parent source file
;
L9BEC       LDA    XA060,X         ;Point to where we were
            STA    SrcP
            LDA    XA060+1,X       ; stop b4 suspension
            STA    SrcP+1
L9BF6       JSR    SetPNBuf        ;Set up PN buf correctly
            JMP    L9B95
;
; Read another block for source code
;
L9BFC       BIT    XA04C           ;Ready 4 processing?
            BVC    L9C06           ;No
            LDY    XA04C+1,X       ;Is there is a partial line leftover
            BNE    L9C0A           ; from previous disk read?
L9C06       JSR    ReadMore        ;No, just read more src lines into mem
            RTS
;
; Before we read a new block of source code into mem we
; need to move the partial line leftover from the last
; disk read into a temp buf indicated by LoMem. Then we read
; in a block of source code. After that we proceed to
; PREPEND the leftover partial line to the beginning of this
; new block of source code so we have a full line of code.
; Finally, we setup a ptr to this line of source code.
; For this to work during the entire assembly process, there
; must be one mem page ($100 bytes) reserved just below
; the start of the SRC/INCLUDE (SBuf/IBuf) data files i.e.
; if SBuf = $0900, a mempage must be reserved @ $0800
; if IBuf = $0E00, a mempage must be reserved @ $0D00
;
L9C0A       LDA    XA06A,X         ;Point to the EO last
            STA    SrcP3
            LDA    XA06A+1,X       ; complete line rec of prev read
            STA    SrcP3+1
;
; (Y)=len of partial line
;
L9C14       LDA    (SrcP3),Y       ;Copy partial line into
            STA    (LoMem),Y       ; this part of mem
            DEY
            BNE    L9C14
;
            LDA    XA04C+1,X       ;Len of the partial line should
            STA    BufIdx          ; saved here first b4 we proceed
            JSR    ReadMore        ; to load in more src lines
;
; Set (SrcP3) to point @ 1 mem page below the start
; of the block of source code just read in
;
            LDY    XA074+1,X       ;Point to SBuf/IBuf (hi-byte)
            DEY                    ;less 1 page
            STY    SrcP3+1
            LDY    XA074,X         ;$A076/$A078
            STY    SrcP3
;
            LDA    LoMem
            STA    L9C3E+1         ;self-modifying code
            LDA    LoMem+1
            STA    L9C3E+2
;
            LDX    BufIdx          ;# of bytes to copy
            LDY    #255
L9C3E       LDA    X0800,X         ;Prepend partial line to
            STA    (SrcP3),Y       ; start of source block
            DEY
            DEX
            BNE    L9C3E
;
            INY
            TYA
            LDX    FCTIndex
            STA    XA060,X         ;Set a ptr to the beginning
            LDA    SrcP3+1
            STA    XA060+1,X       ; of block of source code
            CLC
            RTS
            REP    50
;
; Read in a block of src code into BO SBuf/IBuf
; fr a SRC/INCLUDE file
;
ReadMore    LDX    FCTIndex        ;=2,4
            JSR    SetPNBuf
            LDA    XA074,X         ;Block of source code to be
            STA    ReadDBuf
            LDA    XA074+1,X       ; read into this mem location
            STA    ReadDBuf+1      ;SBuf/IBuf
;
            LDA    #0              ;Whole # of
            STA    ReadLen
            LDA    XA056+1,X       ;SBuf/IBuf size
            STA    ReadLen+1       ; pages are read
            LDA    RefNbrT,X
            STA    ReadRN
            JSR    PRODOS8
            DB     $CA
            DW     ReadPB
            BEQ    L9C8F
;
            CMP    #$4C            ;Is eof?
            BEQ    L9C86           ;Yes
            JSR    DOSErrs
;
L9C86       LDA    #0
            STA    XA04C+1,X       ;Zero len of partial src line
            PLA                    ;Dump ret addr
            PLA
            SEC
            RTS
;
L9C8F       LDA    LenRead         ;# of bytes read
            CLC
            ADC    ReadDBuf
            STA    SBufP           ;Point to end of
            LDA    LenRead+1
            ADC    ReadDBuf+1      ; read data (+1)
            STA    SBufP+1
;
            LDA    #CR
            LDX    #0
L9CA4       LDY    SBufP           ;Search backwards
            BNE    L9CAA
            DEC    SBufP+1
L9CAA       DEC    SBufP           ; fr end of src buffer
            LDY    #0
            CMP    (SBufP),Y       ;Do we have a CR?
            BEQ    L9CBA           ;Yes
            INX
            BNE    L9CA4           ;Keep searching
;
            LDA    #$11            ;Can't find a CR -> File type mismatch
            JSR    DOSErrs
;
L9CBA       TXA                    ;Len of partial line
            LDX    FCTIndex
            STA    XA04C+1,X       ; @ end of read buf
            LDA    SBufP           ;This points to the end of
            STA    XA06A,X
            LDA    SBufP+1         ; last complete line rec
            STA    XA06A+1,X       ; in SBuf/IBuf
;
            LDA    XA074,X
            STA    XA060,X         ;Set src ptr to BO src data buf
            LDA    XA074+1,X
            STA    XA060+1,X
            LDA    #$40            ;Marks block is ready for processing
            STA    XA04C,X
            CLC
            RTS
            REP    50
;
; Read a src line fr macro definition file into
; expansion buf. Expand the src line.
; Assume during expansion of a srcline, the MacStrBuf
; is not overwritten.
; Entry:
;  (X)=6
;
L9CDD       LDX    FCTIndex        ;Is curr src file
            CPX    #MacFile        ; a macro defn file?
            BEQ    L9CE4           ;Yes
            BRK
L9CE4       JSR    SetPNBuf        ;Set up PN buf to Macro defn file
            LDA    RefNbrT,X       ;Macro defn file already opened
            STA    ReadRN
            LDX    #127            ;lexLength
            LDA    #CR             ;Fill buf w/cr
L9CF1       STA    MacExpBuf,X
            DEX
            BPL    L9CF1
;
            LDX    #0              ;index=0
L9CF9       LDA    #>OneByte
            STA    ReadDBuf
            LDA    #<OneByte
            STA    ReadDBuf+1
            LDA    #0
            STA    ReadLen+1
            LDA    #1
            STA    ReadLen
            JSR    PRODOS8
            DB     $CA
            DW     ReadPB
            BEQ    L9D1C
;
            CMP    #$4C            ;EOF?
            BEQ    L9D3A           ;Yes, done reading macro defn file
            JSR    DOSErrs
;
L9D1C       LDA    OneByte
            JSR    L9D75
            BCS    L9CF9
            STA    MacExpBuf,X     ;Store char as it
            INX
            CMP    #CR
            BNE    L9CF9           ;Read another char
;
; We have a complete src line. Prepare to assemble it
;
            LDA    #$80            ;Flag we're assembling a macro expanded srcline
            STA    MacroF
            LDA    #>MacExpBuf     ;Get srcline fr this area
            STA    SrcP
            LDA    #<MacExpBuf
            STA    SrcP+1
            CLC
            RTS
;
L9D3A       LDX    FCTIndex        ;=6
            JSR    ClsFile
            JSR    L9D61
            LDX    #InclFile       ;INCL
            STX    MacroF          ;Flag macro invocation is off
            BIT    IDskSrcF        ;Was macro called fr INCL file?
            BMI    L9D4C           ;Yes
            DEX
            DEX                    ;X=2 SRC
L9D4C       STX    FCTIndex
            JMP    L9BEC           ;Get back to where we were
            REP    50
;
; (X)=4,6 - takes only these values
; The Curr Line # of curr src file is saved
; 1) @ $A07E,$A080 when an INCLUDE
; 2) @ $A086/$A088 when a MACRO defn
; file is opened
; A, X, Y unchanged
;
L9D51       PHA
            LDA    BCDNbr
            STA    XA07E-4,X
            LDA    BCDNbr+1
            STA    XA086-4,X
            SEC
            ROR    NewF            ;=$80
            PLA
            RTS
            REP    50
;
; (X)=4,6
; Counterpart of $9D51
; Restore
; A & X preserved
;
L9D61       PHA
            TXA
            PHA
            LDA    XA07E-4,X
            STA    BCDNbr
            LDA    XA086-4,X
            STA    BCDNbr+1
            JSR    L81A3           ;incr line #s, show a dot
            PLA
            TAX
            PLA
            RTS
            REP    50
; Description of macro defn file - pg 115
; Replace macro variable (argument) with string params
; Entry:
;  (A)-char read fr macro defn file
;  (X)-index into MacExpBuf
;  MacroF=$80/$C0
; Ret:
;  C=0 - (A)=store char in macro expansion buf
;  C=1 - Don't store
;
; It is legal to have a conditional assembly block within
; a macro definition. However, can (CondAsmF) be non-zero
; during a macro expansion? Yes, but there will be no
; macro substitution
;
L9D75       BIT    CondAsmF        ;Will we be assembling alt block?
            BMI    L9D88
            BVS    L9D88           ;Yes, no macro expansion
            BIT    MacroF          ;Do macro subst?
            BVS    L9D8A           ;Yes
            CMP    #'&'            ;1st char of a macro arg?
            BNE    L9D88           ;No
            SEC
            ROR    MacroF          ;$C0 since (MacroF) was $80
            SEC
            RTS
L9D88       CLC
            RTS
;
; Handle &0, &1-&9, &X variables
; If V=1, (A)='&', char is stored as is
; If V=1, (A)='0'-'9','X', parm subst takes place
;
L9D8A       ROL    MacroF          ;=$80 since (MacroF) was $C0
            CMP    #'&'
            BEQ    L9D88           ;Treated as an ordinary char; just store it
            CMP    #'X'
            BEQ    L9DA1
;
            CMP    #'9'+1          ;Is it '0'-'9'?
            BCS    L9D9C
            CMP    #'0'
            BCS    L9DC4           ;Yes
;
L9D9C       JSR    L9DEC           ;Report err
            CLC
            RTS
;
; The &X parm
;
L9DA1       LDY    #0
            STY    ZCF             ;msb=0->1st char can't be numeric char
L9DA5       LDA    DecimalS,Y      ;Create a unique label
            CMP    #'1'
            BCS    L9DB0
            BIT    ZCF
            BPL    L9DB7
L9DB0       STA    MacExpBuf,X     ; within a macro expansion
            SEC
            ROR    ZCF             ;msb=1
            INX
L9DB7       INY
            CPY    #4
            BCC    L9DA5
            SEC
            RTS
;
L9DBE       LDA    MParmCnt        ;Set when macro was invoked
            ORA    #'0'
            CLC                    ;Store char in macro exp buf
            RTS
;
; Replace argument w/substitution string
;
L9DC4       AND    #$0F            ;'0'-'9' -> 0-9
            STA    MacArg
            LDY    #-1
L9DCA       INY
            DEC    MacArg
            BMI    L9DBE           ;&0 parm
            BEQ    L9DD9           ;We have the correct substn str
;
L9DD1       LDA    MacStrBuf,Y     ;Look for a 0 delimiter
            BEQ    L9DCA           ;Got one
            INY
            BNE    L9DD1
;
L9DD9       LDA    MacStrBuf,Y     ;Now copy str over starting
            BNE    L9DE0
            SEC
            RTS
L9DE0       STA    MacExpBuf,X     ; fr the correct position
            INY
            INX
            LDA    MacStrBuf,Y
            BNE    L9DE0
            SEC
            RTS
;
L9DEC       PHA
            TXA
            PHA
            LDX    #$1A            ;mac arg err
            JSR    RegAsmEW
            PLA
            TAX
            PLA
            RTS
            REP    50
;
; Incr by decimal str by 1
;
L9DF8       LDY    #4
            SEC                    ;Add 1 to cntr
L9DFB       DEY
            BMI    Exit5           ;done
            LDA    DecimalS,Y      ;valid values $30-$39
            AND    #%00111111
            SED
            ADC    #0
            CLD
            CMP    #$40
            BCC    L9E0D           ;No overflow
            EOR    #%01110000      ;Zero it (=$30 or '0')
L9E0D       STA    DecimalS,Y
            BCS    L9DFB           ;Overflow, 'carry' forward
Exit5       RTS
            REP    50
;
; ($9E13)
; (X)=Common index into various file control tables
; Valid values of (X)=0,2,4,6,8
;
; Ret:
;  (PathP)-ptr to PN buffer
;  ($C9) - ptr to SRC/INCL PN
; For source files (X=2,4,6), FCTIndex=(X)
; A,Y preserved
;
SetPNBuf    CPX    #9              ;max 8
            BCC    L9E18
            BRK
L9E18       PHA
            LDA    PNTable,X       ;Get ptr to pathname
            STA    PathP           ; buffer to use
            LDA    PNTable+1,X
            STA    PathP+1
            TXA
            BEQ    L9E38           ;X=0
;
            CPX    #MacFile
            BEQ    L9E36           ;X=6
            BCS    L9E38           ;X=8
;
            LDA    PNTable,X       ;X=2,4
            STA    SrcPathP
            LDA    PNTable+1,X
            STA    SrcPathP+1
;
L9E36       STX    FCTIndex        ;=2,4,6
L9E38       PLA
            RTS
            REP    50
;
; $9E3A-not referenced
;
            INC    CancelF
            JSR    CountErr        ;incr # of errs
            JMP    CleanUp
            REP    50
;
; Handler ProDOS errors
; Such errors will cause the Assembler to abort
; (A)=error code (defined in EI module)
;
DOSErrs     TAX
            PLA
            STA    ZPRetAdr
            PLA
            STA    ZPRetAdr+1
            TXA
            PHA
            JSR    PutCR
            PLA
            JSR    PrtError        ;Output thru EdAsm Interp
            JMP    CanclAsm
;=================================================
SBufSize    DB     4               ;Defaults to  4 pages=1K
IBufSize    DB     16              ;Defaults to 16 pages=4K
;
; Table of ptrs to pathname buffers
;
PNTable     DW     ObjPNB          ;ptrs to fullpathname buffers
            DW     ChnPNB
            DW     InclPNB
            DW     MacroPNB
            DW     LstPNB          ;May be a partial PN
;
; ($9E61) These 1024-byte areas are used by ProDOS8
; A ptr to them is passed when an MLI Open call is made
; If there is a disk output of the listing, the MACRO
; I/O buf will be $6E00-$71FF. Otherwise its $7400-$77FF
; $7200-$727F: Macro expansion buf
; $7280-$72FF: Macro string parm buf
; $7300-$73FF: LST data buf
;
FBufTbl     DW     XA100           ;OBJ
            DW     XA500           ;SRC
            DW     XA900           ;INCL
            DW     X7400           ;MACRO (ptr changed if listing to file)
            DW     X7400           ;LST
;
; $9E6B-only 5 out of 10 bytes used
;
RefNbrT     DS     10,0            ;ProDOS8 file ref #s for 5 open files
;
OneByte     DB     $00             ;1-byte data buffer
BufIdx      DB     $00
;
; $9E77 All these P8 parameter blocks are internal to EdAsm.Asm
;
OpenPB      DB     $03
OpenPN      DW     $0000
OpenFBuf    DW     $0000
OpenRN      DB     $A0
;
ReadPB      DB     $04
ReadRN      DB     $A0
ReadDBuf    DW     $A0A0
ReadLen     DW     $A0A0           ;requested
LenRead     DW     $A0A0           ;actual
; $9E85
WrObjPB     DB     $04             ;BIN/SYS/REL obj code file
WrObjRN     DB     $A0
WrObjDB     DW     $A0A0
WrObjLen    DW     $A0A0
            DW     $A0C0
; $9E8D
WrLstPB     DB     $04             ;TXT file
WrLstRN     DB     $A0
            DW     LstDBuf
WrLstLen    DW     $A0C0
            DW     $A0C5
; Not used
L9E95       DB     $02
            DW     $00A0
            DW     $0000
; Not used
L9E9A       DB     $01             ;get/set prefix
            DW     EdAsmDir
; Not used
L9E9D       DB     $02
            DW     $FEA0
            DW     $A0A0
;
GFInfoPB    DB     $0A
GFIPN       DW     $A0A0
GFIAcc      DB     $A0             ;access bits
GFIftype    DB     $A0
            DW     $A0A0
            DB     $A0
            DW     $A0A0
            DW     $A0A0
            DW     $A0A0
            DW     $A0A0
            DW     $A0A0
;
SFInfoPB    DB     $07
            DW     $A0A0
            DB     $A0
            DB     $C0
SFIaux      DW     $A0A0
            DB     $A0
            DW     $A0A0
            DW     $0000
            DW     $0000
;
CreatePB    DB     $07
CreatePN    DW     $A0A0
;CreatABits DB $C3
            DB     $C3
CrFType     DB     TXTtype
            DW     $0000
            DB     $01
            DW     $0000
            DW     $0000
;
DestroyPB   DB     $01
DestroyPN   DW     $A0A0
;
ClosePB     DB     $01
CloseRN     DB     $A0
;
SMarkPB     DB     $02
SMarkRN     DB     $A0
SMfposn     DS     3,$A0
;
OnlinePB    DB     $02
OLUnit      DB     $A0
OLBufAdr    DW     $A0EB           ;=$7300
;
; Name of 1st SRC file is stored here
;
L9EDC       DS     $23,0           ;$9EDC-$9F1C (should be 65)
            DSECT
            ORG    L9EDC+65
;=================================================
; 5 files may be opened at any one time
; OBJ, SRC, INCLUDE, MACLIB, LST
; X=0 object file
; X=2 source file/chained source file
; X=4 include source file
; X=6 macro defn file
; X=8 listing file
;
ObjPNB      DS     65              ;Object
ChnPNB      DS     65              ;Chain
InclPNB     DS     65              ;Include
MacroPNB    DS     65              ;macro lib's prefix
LstPNB      DS     33              ;LST filename
; corr filetypes
ftypeT      DS     10
;
; ($A04C) This table consists of five 2-byte entries
; 1st byte is a flag; 2nd byte len of partial line which doubles
; as an index into the last mem page of the SBuf/IBuf data buffers
;
; $A04C,$A04D,$A04E-$A051
;
XA04C       DS     10              ;$A04C-$A055
;
; curr val of SBufSiz, IBufSiz
; Only $A059/$A05B used
;
XA056       DS     10              ;$A056-$A05F
;
; The table below store ptrs to the mem location of the
; curr src line within the block of source code of
; consisting of complete line recs
; $A060 : Unused
; $A062 : src/chn
; $A064 : incl
; $A066 : Unused
; $A068 : Unused
;
XA060       DS     10              ;$A060-$A069
;
; The table below store ptrs to the mem location of
; the end of last complete line record in SBuf/IBuf
; $A06A : Unused
; $A06C : No init - src/chn
; $A06E = $1D00   - incl
; $A070 : Unused
; $A072 : Unused
;
XA06A       DS     10              ;$A06A-$A073
;
; Memory map:
; $0800-$08FF - Reserved for use with SRC data buf
; $0900-$0CFF - SRC file data buffer - 4 mempages
; $0D00-$0DFF - Reserved for use with INCLUDE data buf
; $0E00-$1DFF - INCLUDE file data buffer - 16 mempages
; $1E00-$xxxx - Start of Symbol table
;
; The following locations are set
; to point @ various buffers:
; $A074 <= $1E00
; $A076 <= $0900
; $A078 <= $0E00 - changed by SBufSize directive
; $A07A : No init but may be changed by IBufSiz directive
; $A07C : Unused?
;
XA074       DS     10              ;$A074-$A07D ptrs to start of SBuf/IBuf data bufs
;
; $A07E : line # (lo) - hi is stored at $A086
; $A080 : line # (lo) - hi is stored at $A088
; $A082 : Unused?
; $A084 : Unused?
; $A086 : line # (hi)
; $A088 : line # (hi)
; $A08A : Unused?
; $A08C : Unused?
;
XA07E       DS     8               ;$A07E-$A085
XA086       DS     8               ;$A086-$A08D
SubTitle    DS     36              ;Store area for subtitle string ($A08E-$B1)
;
;
; This is a table of recs which is used to store
; a) the file # where an asmbly error occurs (1-byte)
; b) index into a table of ptrs to Error msgs (1-byte)
; c) line # of src stmt which is flagged as incorrect (2 bytes)
; Up to 16 (64 bytes) errors may be saved for later display
;
ErrInfoT    DS     64              ;($A0B2-$F1)
            DEND