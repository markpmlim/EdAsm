Name          : ASM1.S
End of file   :   37,977
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            MSB    OFF
            REP    50
;
; EDASM.ASM - load addr:$6800-$9EFF (len $4000)
; The 1st part of the code ($6800-$77FF) is relocated
; to $D000 of LCBank2. The rest of the code remained
; resident @ $7800-$9EFF
;
; Basically, compilers can be written as:
; Source -> Scanner/Lexer -> Parser -> CodeGenerator
;
; ORG $5800 ;modify ORG in ASSEMBLER.1
            ORG    $D000
;
; This part of the code is loaded into memory
; at $6800 and relocated to $D000 bank2
;
; Print the symbol table after an assembly listing
; The symbol table is about 27K. If there is not
; enough mem to do a listing, the assembler will
; print only those symbols it can sort. The VO
; symbol table may not contain all idfers
; Ref pg 84,113
;
DoPass3     LDA    LstASym         ;List symbols?
            ORA    LstVSym
            BMI    ChkPrtCols      ;Yes
            RTS
;
ChkPrtCols  LDA    #4
            BIT    Lst6Cols
            BPL    UsePrtr
;
            LDA    #6
UsePrtr     LDX    PrSlot          ;Printer?
            BNE    SetPtrCols      ;Yes
            LDA    #2              ;40-col std video
SetPtrCols  STA    NumCols         ;# of print cols=2,4,6
;
; Find out if the symbol table is empty by
; checking the header nodes.
;
            LDA    #0
            TAY                    ;Y=0
ChkLoop     CMP    HeaderT,Y       ;Do we have an empty symbol table?
            BNE    LD025           ;No
            INY
            BNE    ChkLoop
            JMP    LD16E           ;All zeroes => Yes
;
LD025       LDA    #0
            STA    SortF           ;Default to sort by symbol
            BIT    SubTtlF         ;Output subtitle?
            BVC    LD056           ;No
;
            LDA    #$FF
            STA    SubTtlF         ;There is a subtitle string
            LDX    #ChnFile        ;Get the src Pathname
            LDA    PNTable,X       ; from table of ptrs
            STA    SrcPathP
            LDA    PNTable+1,X
            STA    SrcPathP+1
;
; The buffers below are overwritten
; since we are done w/assembly
;
            LDX    #12
            STX    ChnPNB
LD042       LDA    SymbolTxt-1,X
            STA    ChnPNB,X
            DEX
            BNE    LD042
;
            LDX    #16             ;Include null char
LD04D       LDA    SortedTxt,X
            STA    SubTitle,X
            DEX
            BPL    LD04D
;
LD056       LDA    EndSymT
            BNE    LD05C
            DEC    EndSymT+1
LD05C       DEC    EndSymT
            BIT    DskSrcF         ;Should this instr be after LDY #HeaderT?
            LDA    #<HeaderT
            LDY    #>HeaderT
            BMI    LD06A           ;branch never taken
;
            LDA    StrtSymT+1
            LDY    StrtSymT
LD06A       STY    SymNodeP        ;Points @ node containing
            STA    SymNodeP+1      ; symbolicname
            STY    SavSTS          ;Save Start of SymTbl
            STA    SavSTS+1        ; as it will be trashed
            LDA    #2              ;Skip over ptr to
            BNE    LD099           ; next node
;
; The code below will trash the link ptrs (field) of nodes
; (StrtSymT) - points @ symbolicname field of the node
; (SymNodeP) - points @ link field of the same node
; (StrtSymT) & (SymNodeP) will be changed
; The purpose is to change the layout of the Nodes
; removing the link field altogether
; Layout of record now looks like this:
;   symbolicname (variable in length)
;   flagbyte
;   16-bit value
;
LD076       LDY    #0
LD078       LDA    (StrtSymT),Y    ;Get char fr symbolicname
            STA    (SymNodeP),Y    ; move it forward in node
            BPL    LD081           ;eo symbolicname
            INY
            BNE    LD078
;
LD081       LDX    #3
LD083       INY
            LDA    (StrtSymT),Y    ;Copy flagbyte
            STA    (SymNodeP),Y    ; & value field
            DEX
            BNE    LD083
;
            INY
            TYA
            CLC
            ADC    SymNodeP        ;Point @ next node
            STA    SymNodeP
            BCC    LD096
            INC    SymNodeP+1
;
LD096       INY                    ;Skip over link field
            INY
            TYA
LD099       CLC
            ADC    StrtSymT
            STA    StrtSymT        ;Point @ symbolicname of next node
            BCC    LD0A2
            INC    StrtSymT+1
;
LD0A2       CMP    EndSymT         ;EO symbol table?
            LDA    StrtSymT+1
            SBC    EndSymT+1
            BCC    LD076           ;No
;
            LDY    SymNodeP+1
            LDX    SymNodeP
            BNE    LD0B1
            DEY
LD0B1       DEX
            STX    EndSymT         ;New end of Symbol table
            STY    EndSymT+1
;
            LDA    SavSTS          ;Restore Start of symbol table
            STA    StrtSymT
            LDA    SavSTS+1
            STA    StrtSymT+1
            NOP
;
LD0BF       LDA    StrtSymT        ;Start w/the 1st rec
            STA    SymP
            LDA    StrtSymT+1
            STA    SymP+1
;
; The code below builds a fixed array of 2/4-bytes entries for sorting
; Sort by Symbol - array of 2-bytes entries. Each element is a ptr
; to a symbolicnname
; Sort by Address - array of 4-byte entries. Each element consists
; of a ptr to a symbolicname and address associated with
; the symbolicname
;
            LDA    #2              ;Default to 2-byte entries
            BIT    SortF           ;Sort by symbol?
            BPL    LD0CE           ;Yes
            ASL                    ;Sort by addr - use 4-byte entries
LD0CE       CLC
            ADC    EndSymT
            STA    UnsortedP       ;Points to a 2/4-byte entry in
            STA    SortedP
            LDA    EndSymT+1
            ADC    #0
            STA    UnsortedP+1     ; the aux array for fixed rec size
            STA    SortedP+1       ;Init this for later use by PrSymTbl
            LDA    #0
            STA    RecCnt
            STA    RecCnt+1
;
; This loop builds up the aux array
;
LD0E3       JSR    PollKbd         ;Abort?
            BCC    LD0EB
            JMP    AbortAsm        ;Yes
;
LD0EB       LDY    #0
LD0ED       LDA    (SymP),Y        ;Looking for eo symbolicname
            BPL    LD0F5           ;Got it
            INY
            JMP    LD0ED
;
LD0F5       BIT    SortF           ;Sort by Address? (Also means is it phase 2?)
            BMI    LD108           ;Yes, skip code below
;
; Sort by symbol - always done since (SortF) was set to $00 initially
; (SortF) will set to $FF after printing if LstASym=$80
;
            ORA    #%10000000      ;set msb on for last
            STA    (SymP),Y        ; char of symbolicname
            INY
            LDA    (SymP),Y        ;Get symbol's flag byte
            BPL    LD108           ;Symbol is defined (msb off)
            ORA    #%01111110      ;Retain original $80 and $01 bits
            EOR    #%10000000      ;Clear msb to mark symbol is
            STA    (SymP),Y        ; undefined =$7E/$7F (ref pg 231)
;
; msb of ALL chars of symbolicname are on
; msb of flagbyte is off ($7x)
;
LD108       INY
            LDA    (SymP),Y        ;Get associated addr
            STA    SymAddr         ;Save here just in case we need it later
            INY
            LDA    (SymP),Y
            STA    SymAddr+1
            STY    SymIdx          ;Save index for $D198 call
;
            LDA    SymP
            LDY    #0
            STA    (UnsortedP),Y   ;Ptr to symbolic name
            LDA    SymP+1
            INY
            STA    (UnsortedP),Y
            BIT    SortF           ;Sort by symbol?
            BPL    LD12D           ;Yes
;
            INY
            LDA    SymAddr
            STA    (UnsortedP),Y   ;Store associated addr
            INY
            LDA    SymAddr+1
            STA    (UnsortedP),Y
;
LD12D       JSR    LD198           ;Setup envron for next entry
            BCC    LD0E3           ;Continue building up work array
;
; Building of the aux work array of 2/4-byte records is complete
;
            LDA    UnsortedP
            BNE    LD138
            DEC    UnsortedP+1
LD138       DEC    UnsortedP
;
            LDA    UnsortedP
            STA    AuxAryE
            LDA    UnsortedP+1
            STA    AuxAryE+1       ;Points @ EO array to be sorted
            BIT    LstASym         ;Alphabetic Symbol listing?
            BPL    LD14C           ;no
;
            JSR    DoSort
            JSR    PrSymTbl        ;Print it
;
LD14C       DEC    SortF
            LDA    SortF           ;Do we need to sort by address?
            CMP    #$FF
            BNE    LD16E           ;No -> done
            BIT    SubTtlF         ;SBTL directive?
            BVC    LD163           ;No
;
; Overwrite 'SYMBOL'00 with 'ADDRESS'00
;
            LDX    #7
LD15A       LDA    AddrTxt,X
            STA    SubTitle+10,X
            DEX
            BPL    LD15A
;
LD163       BIT    LstVSym         ;Value ordered listing?
            BPL    LD16E           ;no
;
            LDA    #$80
            STA    LstASym         ;Force an Alphabetic sort
            JMP    LD0BF           ;Build aux array again w/(SortF)=$FF
;
LD16E       LDA    #$00
            STA    SubTtlF         ;Reset SBTL flag
doRtn       RTS
;
SymbolTxt   ASC    'SYMBOL         TABLE'
SortedTxt   ASC    'SORTED         BY SYMBOL' ;null-terminated
            DB     0
AddrTxt     ASC    'ADDRESS'
            DB     0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup enviornment to process next entry of 2/4-byte array
; Output
;   C=1 out of mem or EO symbol table
;
LD198       CLC
            LDA    SymIdx          ;Get index into symbol's record
            ADC    #1              ;Skip over hi-byte of assoc addr
            ADC    SymP
            STA    SymP            ;Points @ next record of Symbol table
            BCC    LD1A5
            INC    SymP+1
;
LD1A5       LDA    UnsortedP       ;Ptr to entry of aux array
            CMP    MemTop
            LDA    UnsortedP+1
            SBC    MemTop+1
            BCS    doRtn1          ;Probably out of mem
;
            CLC
            LDA    #2
            BIT    SortF           ;Sort by Symbol?
            BPL    LD1B7           ;Yes
            ASL                    ;=4
LD1B7       ADC    UnsortedP
            STA    UnsortedP       ;Point @ next empty slot
            BCC    LD1BF
            INC    UnsortedP+1
;
LD1BF       INC    RecCnt
            BNE    LD1C5
            INC    RecCnt+1
LD1C5       LDA    SymP            ;Check if EO symbol table?
            CMP    EndSymT
            LDA    SymP+1
            SBC    EndSymT+1       ;C=1 => yes
doRtn1      RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sorting Algorithm
; See Disassembled ProDOS Linker for more details
; Before calling, the work array of 2-byte/4-byte
; entries must be setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DoSort      LDA    NumRecs         ;Size of unsorted array
            STA    Jump
            LDA    NumRecs+1
            STA    Jump+1
;
; WHILE Jump <> 0
;
WhileLoop   LSR    Jump+1          ;Jump := Jump DIV 2
            ROR    Jump
            LDA    Jump
            ORA    Jump+1
            BNE    LD1E1
            RTS
;
LD1E1       SEC
            LDA    NumRecs
            SBC    Jump
            STA    EndIdx          ;NumRecs-Jump
            LDA    NumRecs+1
            SBC    Jump+1
            STA    EndIdx+1
;
            LDX    #0
            STX    StrtIdx+1
            INX
            STX    StrtIdx         ;=1
;
; FOR JJJ := 1 to NumRecs-Jump
;
ForLoop     LDA    StrtIdx
            STA    JJJ
            LDA    StrtIdx+1
            STA    JJJ+1
;
; REPEAT
;
RptLoop     CLC
            LDA    JJJ
            ADC    Jump
            STA    III             ;III := JJJ + Jump
            LDA    JJJ+1
            ADC    Jump+1
            STA    III+1
;
            LDX    #3
LD20C       LDA    JJJ,X           ;$9F-$A2
            STA    J.TH,X          ;$AB-$AE
            DEX
            BPL    LD20C
;
; Compute ptrs to the i-th & j-th elements
; of the array being sorted
; NB. The code below assumes the mem locations
; JJJ & III are consecutively declared
; Mulby4/Mulby2 and add to (EndSymT)
; For the 4-byte entries array (Sort by Address)
;  (J.TH)=(EndSymT)+JJJ;4 and (I.TH)=(EndSymT)+III;4
; For the 2-byte entries array (Sort by Symbol)
;  (J.TH)=(EndSymT)+JJJ;2 and (I.TH)=(EndSymT)+III;2
;
            LDX    #2
LD215       ASL    J.TH,X          ;Compute offset fr
            ROL    J.TH+1,X        ; BO of fixed array
            BIT    SortF           ;Sort by Symbol?
            BPL    LD221           ;Yes
            ASL    J.TH,X          ;No, it's sort by address
            ROL    J.TH+1,X
;
LD221       CLC
            LDA    EndSymT         ;First compute ptr to the j-th
            ADC    J.TH,X          ; & then on looping back
            STA    J.TH,X
            LDA    EndSymT+1
            ADC    J.TH+1,X
            STA    J.TH+1,X
            DEX
            DEX
            BEQ    LD215           ; the i-th element
;
            BIT    SortF           ;Sort by Symbol
            BPL    LD268           ;Yes
;
; Sort addresses in ascending order
; (J.TH)-ptr to j-th element
; (I.TH)-ptr to i-th element
;
            CLC
            LDA    #2
            ADC    J.TH            ;Skip over ptr to symbolicname
            STA    SymPJ
            LDA    #0
            ADC    J.TH+1
            STA    SymPJ+1         ; to point @ 16-bit address
;
            CLC
            LDA    #2
            ADC    I.TH
            STA    SymPI
            LDA    #0
            ADC    I.TH+1
            STA    SymPI+1
;
; IF Ary[J].addr > Ary[I].addr then SWAP(Ary[J], Ary[I])
;
            LDY    #1
            LDA    (SymPJ),Y       ;Compare addresses (hi-byte first)
            CMP    (SymPI),Y
            BEQ    LD25D
            BCS    LD264
LD25A       JMP    NextJ           ;less than
;
LD25D       DEY                    ;Y=0
            LDA    (SymPI),Y       ;Hi-bytes equal so compare lo-bytes
            CMP    (SymPJ),Y
            BCS    LD25A
LD264       LDY    #3              ;Greater than => swap entries
            BNE    LD298           ;always
;
; Sort by symbol
; IF Ary[J].name > Ary[I].name then SWAP(Ary[J], Ary[I])
;
LD268       LDY    #0
            LDA    (J.TH),Y        ;Get ptr to symbolicname field
            TAX
            INY
            LDA    (J.TH),Y        ;with an entry of the symbol table
            STA    SymPJ+1
            STX    SymPJ
;
            LDA    (I.TH),Y
            TAX
            DEY                    ;=0
            LDA    (I.TH),Y
            STA    SymPI
            STX    SymPI+1
;
LD27E       LDA    (SymPJ),Y       ;Get len byte of symbolic name
            CMP    (SymPI),Y       ;Compare it against its counterpart
            BNE    LD294           ;No match
            INY
            CPY    #14             ;At most 14 chars will be compared
            BCS    NextJ
            LDA    (SymPJ),Y
            TAX
            AND    (SymPI),Y
            BMI    LD27E           ;All chars match
            TAX
            BPL    NextJ
            SEC                    ;Flag we have to swap ptrs
LD294       BCC    NextJ           ;C=0 ==> 1st symbol < 2nd symbol
;
; Swap contents of 2/4-byte table
; Fall thru : 2-byte entries
;
            LDY    #1
LD298       LDA    (J.TH),Y        ;Swap ptrs to the symbolicnames (if Y=1/3)
            TAX
            LDA    (I.TH),Y
            STA    (J.TH),Y        ;as well as corr addresses (if Y=3)
            TXA
            STA    (I.TH),Y
            DEY
            BPL    LD298
;
            SEC
            LDA    JJJ
            SBC    Jump
            STA    JJJ             ;JJJ := JJJ - Jump
            LDA    JJJ+1
            SBC    Jump+1
            STA    JJJ+1           ;Is J > Jump?
            BMI    NextJ           ;No, less than
            ORA    JJJ
            BEQ    NextJ           ;No, JJJ=Jump
            JMP    RptLoop
;
; UNTIL JJJ =< Jump
;
NextJ       INC    StrtIdx
            BNE    LD2C1
            INC    StrtIdx+1
;
LD2C1       LDA    StrtIdx+1       ;Finish w/FOR loop?
            CMP    EndIdx+1
            BCC    LD2D2
            BEQ    LD2CC
LD2C9       JMP    WhileLoop       ;No
;
LD2CC       LDA    EndIdx
            CMP    StrtIdx
            BCC    LD2C9
LD2D2       JMP    ForLoop         ;Start Index =< End Index
            REP    50
;
; Print the sorted symbols and addresses
; (SortedP) should be pointing @ BO aux work array
;
PrSymTbl    JSR    PrtFF
LD2D8       LDA    #0
            STA    ColCnt          ;# of cols printed
            JSR    PollKbd         ;Abort assembling
            BCC    LD2E4
            JMP    AbortAsm        ;Yes
;
; NB: All chars of symbolicname would have their msb on
; The msb of the corr flag byte is 0
;
LD2E4       LDY    #0
            LDA    (SortedP),Y     ;Get ptr to symbolicname
            STA    SymP
            INY
            LDA    (SortedP),Y
            STA    SymP+1
            DEY                    ;Y=0
LD2F0       LDA    (SymP),Y        ;Is it the flag byte?
            BPL    LD2F8           ;Yes
            INY
            JMP    LD2F0
;
LD2F8       LDA    #SPACE
            STA    SymRefCh        ;Init with a blank
            LDA    #$00
            STA    IsFwdRef
            LDA    (SymP),Y        ;Get flag byte
            ROR                    ;bit01 -> C (Check bit $01)
            BCC    LD307           ;=> Forward referenced bit was off
            DEC    IsFwdRef        ;-1
LD307       ROL                    ;Get back flag byte
            CMP    #$7E
            BCC    LD310
            LDA    #'*'            ;Symbol was referenced but not defined
            BNE    LD329           ;always
;
LD310       BIT    Bit40           ;Was symbol unreferenced?
            BEQ    LD319           ;No
            LDA    #'?'            ;Defined but never referenced
            BNE    LD329
;
LD319       BIT    Bit10           ;Was symbol defined to be EXTERN?
            BEQ    LD322
            LDA    #'X'            ;Yes
            BNE    LD329
;
LD322       BIT    Bit08           ;Was symbol defined to be ENTRY?
            BEQ    LD32B
;
            LDA    #'N'            ;Yes
LD329       STA    SymRefCh
LD32B       LDA    SymRefCh
            JSR    PutC
            INY
            LDA    (SymP),Y        ;Get symbol's addr
            TAX
            INY
            LDA    (SymP),Y        ;Get its hi-byte
            BNE    LD348           ;Definitely 16-bits
            BIT    IsFwdRef        ;Was forward-referenced bit on?
            BMI    LD348           ;Yes, consider all such addr as 16 bits
;
            LDA    #SPACE          ;Print 2 spaces for zp/single-byte addr
            JSR    PutC
            JSR    PutC
            JMP    LD34B
;
LD348       JSR    PrByte          ;addr
LD34B       TXA
            JSR    PrByte
            LDA    #SPACE
            JSR    PutC
;
; Print up to 14 chars of the symbolicname
;
            LDY    #0
LD356       LDA    (SymP),Y        ;Get char fr symbolicname
            BPL    LD362           ;It is the flagbyte
            JSR    PutC
            INY
            CPY    #14
            BCC    LD356
;
; If symbolicname < 14 chars long, print reqd # of blanks
;
LD362       DEY
LD363       INY
            CPY    #14
            BCS    LD370
            LDA    #SPACE
            JSR    PutC
            JMP    LD363           ;Loop back to print more spaces
;
LD370       JSR    AdvRecP         ;Adv to next entry of aux array
            BCS    doRtn2          ;We're done with table
            INC    ColCnt
            LDA    ColCnt
            CMP    NumCols
            BCC    LD383
            JSR    PutCR           ;Further printing will
            JMP    LD2D8           ; start on next row
LD383       JMP    LD2E4           ;Further printing is on same row
doRtn2      RTS
;=================================================
; Adv ptr to next entry of work array
; On return
;   C=1 - End of work array
;
AdvRecP     CLC
            LDA    #2
            BIT    SortF           ;Sort by addr?
            BPL    LD38F           ;No, by symbol
            ASL                    ;=4
LD38F       ADC    SortedP         ;next Rec
            STA    SortedP
            BCC    LD397
            INC    SortedP+1
LD397       LDA    SortedP         ;EO aux array?
            CMP    AuxAryE
            LDA    SortedP+1
            SBC    AuxAryE+1
            RTS
;=================================================
; Checks if external ROM is present
; (A)=slot # (1-7)
; Z=1 yes, Z=0 no
;=================================================
Chk4ROM     TAX
            LDA    #%00000010
LD3A3       DEX
            BEQ    LD3A9
            ASL
            BNE    LD3A3
;
LD3A9       BIT    SLTBYT          ;Is a Slot ROM present?
            BNE    LD3B1           ;Yes
            LDA    #1
            RTS
LD3B1       LDA    #0              ;Z=1
            RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; (Y)=preserved
; Get ptr to next line record and save it
;
LD3B4       LDA    SrcP            ;save temporarily
            PHA
            LDA    SrcP+1
            PHA
            TYA
            PHA
            JSR    NextRec         ;Point @ start of next src line
            LDX    FCTIndex
            LDA    SrcP            ;Save it
            STA    XA060,X
            LDA    SrcP+1
            STA    XA060+1,X
            PLA
            TAY                    ;restore
            PLA
            STA    SrcP+1
            PLA
            STA    SrcP
            RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; START of Assembler's Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ($D3D4) Table of Ptrs to messages incl. error msgs
; Ref page 219 Workbench
;
ErrMsgT     EQU    *               ;Error code
            DW     LD50F           ;0
            DW     LD524           ;2
            DW     LD539           ;4
            DW     LD54A           ;6
            DW     LD553           ;8
            DW     LD56C           ;A
            DW     LD57E           ;C
            DW     LD58C           ;E
            DW     LD59F           ;10
            DW     LD5AA           ;12
            DW     LD5C0           ;14
            DW     LD5D4           ;16
            DW     LD5E8           ;18
            DW     LD5F6           ;1A
            DW     LD605           ;1C
            DW     LD612           ;1E
            DW     LD626           ;20
            DW     $0000           ;22 - none?
            DW     LD63B           ;24
            DW     LD64D           ;26
            DW     LD65A           ;28
            DW     LD668           ;2A
            DW     LD678           ;2C
            DW     LD688           ;2E
            DW     LD6A0           ;30
            DW     LD6BD           ;32
            DW     LD6CB           ;34
            DW     LD6DD           ;36
            DW     LD6F1           ;38
            DW     LD705           ;3A
            DW     LD71A           ;3C
            DW     LD726           ;3E
            DW     LD739           ;40
            DW     LD74B           ;42
            DW     LD75A           ;44
            DW     LD76E           ;46
            DW     LD781           ;48
ErrMsgTE    EQU    *
;=================================================
FileTxt     ASC    '               # ELIF' ;FILE #
ASEndTxt    EQU    *
ASErrTxt    ASC    '               ERRORS IN THIS ASSEMBLY'
            DB     $00
SuccTxt     EQU    *
            ASC    '**             SUCCESSFUL ASSEMBLY := NO ERRORS'
            DB     $00
WarnTxt     ASC    '               WARNINGS IN THIS ASSEMBLY'
            DB     $00
CreatTxt    ASC    '**             ASSEMBLER CREATED ON '
            DB     $01
FSPCTxt     ASC    '**             FREE SPACE PAGE COUNT'
            DB     $01
TotLnTxt    ASC    '**             TOTAL LINES ASSEMBLED '
            DB     $01
ContTxt     ASC    'PRESS          RETURN TO CONTINUE'
            DB     $01
AbortTxt    ASC    'ASSEMBLY       ABORTED. PRESS RETURN'
            DB     $01
InLinTxt    ASC    'ENIL           NI ' ;' IN LINE'
            ASC    'RORRE          ' ;' ERROR'
;=================================================
; There is a table of ptrs to these messages
;
LD50F       ASC    'UNDEFINED      IDENTIFIER'
            DB     $00
LD524       ASC    'DUPLICATE      IDENTIFIER'
            DB     $00
LD539       ASC    'UNDEFINED      OPCODE'
            DB     $00
LD54A       ASC    'OVERFLOW'
            DB     $00
LD553       ASC    'RELATIVE       EXPRSN OPERATOR'
            DB     $00
LD56C       ASC    'EXPRESSION     SYNTAX'
            DB     $00
LD57E       ASC    'EQUATE         SYNTAX'
            DB     $00
LD58C       ASC    'INVALID        IDENTIFIER'
            DB     $00
LD59F       ASC    'DSECT/DEND'
            DB     $00
LD5AA       ASC    'SYMBOL/RLD     TABLE FULL'
            DB     $00
LD5C0       ASC    'ASSEMBLER      PARAMETER'
            DB     $00
LD5D4       ASC    'INCLUDE/CHN    NESTING'
            DB     $00
LD5E8       ASC    'MACRO          NESTING'
            DB     $00
LD5F6       ASC    'MACRO          ARGUMENT'
            DB     $00
LD605       ASC    'ADDRESS        MODE'
            DB     $00
LD612       ASC    'RESERVED       IDENTIFIER'
            DB     $00
LD626       ASC    'MACRO          FILE NOT FOUND'
            DB     $00
LD63B       ASC    'DIRECTIVE      OPERAND'
            DB     $00
LD64D       ASC    'BRANCH         RANGE'
            DB     $00
LD65A       ASC    'BYTE           OVERFLOW'
            DB     $00
LD668       ASC    'INDIRECT       SYNTAX'
            DB     $00
LD678       ASC    'INDEXING       SYNTAX'
            DB     $00
LD688       ASC    'INDIRECT       REQUIRES ZPAGE'
            DB     $00
LD6A0       ASC    'INVALID        AFTER 1ST IDENTIFIER'
            DB     $00
LD6BD       ASC    'SW16           REGISTER'
            DB     $00
LD6CB       ASC    'INVALID        DELIMITER'
            DB     $00
LD6DD       ASC    'OBJ            BUFFER OVERFLOW'
            DB     $00
LD6F1       ASC    'OBJ            BUFFER CONFLICT'
            DB     $00
LD705       ASC    'INVALID        FROM INCLUDE'
            DB     $00
LD71A       ASC    'BUFFER         SIZE'
            DB     $00
LD726       ASC    '>255           EXTRNS/ENTRYS'
            DB     $00
LD739       ASC    'DUPLICATE      EXT/ENT'
            DB     $00
LD74B       ASC    'SWEET16        OPCODE'
            DB     $01
LD75A       ASC    'EXTRN          USED AS ZXTRN'
            DB     $01
LD76E       ASC    'ORG            MUST BE > $100'
            DB     $00
LD781       ASC    '6502X          ADRS MODE/OPCODE'
            DB     $00
;
LD798       ASC    '-----          NEXT OBJECT FILE NAME IS '
LD7B7       DB     $0D
            ASC    'SOURCE           FILE #'
LD7C7       DB     $0D
            ASC    '               INCLUDE FILE #'
;=================================================
; This table works in conjunction wth the next table
; They are indexed with the same (X)
; Table for operand parser (47 bytes)
; If -ve token (other than $A0) matched with src char
;    If followed by $00 - proceed to evaluate expr
;      If followed by $A0 - chk for a CR
;        If there is a CR and next token is
;          +ve and odd - return to caller with C=0 and (A)=MODULO2
;             which is an index btwn (0-12) for further processing
;             to determine the length of the instruction
;          +ve and even - call a rtn for further processing (2,4,6 valid)
; If -ve token does not match src char
;  use table $D806 to advance to next -ve token
; ($D7D7)
;
            MSB    ON
AModTkns    EQU    *
            ASC    '#'             ;$A3
            DB     $00             ;Evaluate Expression
            ASC    '               ' ;Check for white space
            DB     4+1             ;If CR, ret its mod2 value - imm
;
LD7DB       ASC    '('             ;$A8
            DB     $00             ;eval expr
            ASC    ','             ;$AC
            ASC    'X'             ;$D8
            ASC    ')'             ;$A9
            ASC    '               ' ;Check for CR
            DB     $02             ;Helper rtn 1 - IsZPMod?
            DB     14+1            ;$0F - (zp,X)
LD7E3       DB     $06             ;Helper rtn 3 - Is65C02?
            DB     24+1            ;$19 - (abs,X)
;
LD7E5       ASC    ')'             ;$A9
            ASC    ','             ;$AC
            ASC    'Y'             ;$D9
            ASC    '               ' ;Check for CR
            DB     $02             ;helper rtn 1
            DB     12+1            ;$0D - (zp),y
;
LD7EB       ASC    '               ' ;Check for CR
            DB     $06             ;helper rtn 3
            DB     $02             ;helper rtn 1
            DB     16+1            ;$11 - (zp)
LD7EF       DB     18+1            ;$13 - (abs)
;
LD7F0       DB     $04             ;helper rtn 2 - IsAccMode?
            DB     20+1            ;$15 - Acc
LD7F2       DB     $8D             ;cr
            DB     20+1            ;$15 - Acc
LD7F4       ASC    '               ;' ;$BB
            DB     20+1            ;$15 - Acc
;
LD7F6       DB     $00             ;eval expr
            ASC    '               ' ;Check for CR
            DB     $02             ;Helper rtn 1
            DB     2+1             ;$03 - zp
LD7FA       DB     0+1             ;$01 - abs
;
LD7FB       ASC    ','             ;$AC
            ASC    'X'             ;$D8
            ASC    '               ' ;Check for CR
            DB     $02             ;Helper rtn 1
            DB     6+1             ;$07 - zp,X
LD800       DB     8+1             ;$09 - abs,X
;
LD801       ASC    'Y'             ;$D9
            ASC    '               ' ;Check for whitespace
            DB     $02             ;Helper rtn 1
            DB     22+1            ;$17 - zp,Y
LD805       DB     10+1            ;$0B - abs,Y
            MSB    OFF
;=================================================
; ($D806) - 47 bytes
; Command to the AdrMod parser
; if token is
;  0 - compare next src char to next token in $D7D7 table
;  +ve - index to next token in $D7D7 table to be used to
;        compare against curr src char
;  -ve - error token
;
; error code  = error token & $7E
;
AModCmds    DB     LD7DB-AModTkns  ;index to token in $D7D7 to be used next
            DB     $00             ;Compare next token and src char
            DB     $80+$34         ;error code
            DB     $00
            DB     LD7F0-AModTkns  ;$19
            DB     $00
            DB     LD7E5-AModTkns  ;$0E
            DB     $80+$2A         ;Index Syntax
;
            DB     $80+$2A
            DB     $80+$34         ;Invalid Delimiter
            DB     LD7E3-AModTkns  ;$0C
            DB     $00
            DB     $80+$2E         ;Indirect req zp
            DB     $00
            DB     $80+$2A
            DB     LD7EB-AModTkns  ;$14
;
            DB     $80+$2A
            DB     $80+$34
            DB     $80+$2E
            DB     $00
            DB     $80+$34
            DB     LD7EF-AModTkns  ;$18
            DB     LD7EF-AModTkns  ;$18
            DB     $00
;
            DB     $00
            DB     LD7F2-AModTkns  ;$1B
            DB     $00
            DB     LD7F4-AModTkns  ;$1D
            DB     $00
            DB     LD7F6-AModTkns  ;$1F
            DB     $00
            DB     $00
;
            DB     LD7FB-AModTkns  ;$24
            DB     LD7FA-AModTkns  ;$23
            DB     $00
            DB     $00
            DB     $80+$34
            DB     LD801-AModTkns  ;$2A
            DB     $80+$34         ;Invalid Delimiter
            DB     LD800-AModTkns  ;$29
;
            DB     $00
            DB     $00
            DB     $80+$2C         ;Indexing Syntax
            DB     $80+$34
            DB     LD805-AModTkns  ;$2E
            DB     $00
            DB     $00
;=================================================
; ($D835) 6502/X6502 Opcode Translation table  213 bytes
; The 15 addressing modes of a 65C02
;  1) implied                     - opcode
;  2) accumulator                 - opcode
;  3) program counter relative    - opcode reladdr
;  4) immediate                   - opcode #
;  5) direct                      - opcode zp
;  6) absolute                    - opcode abs
;  7) direct indexed X            - opcode zp,X
;  8) absolute indexed X          - opcode abs,X
;  9) direct indexed Y            - opcode zp,Y
; 10) absolute indexed Y          - opcode abs,Y
; 11) indexed indirect X          - opcode (zp,X)
; 12) absolute indexed indirect X - JMP (abs,X)
; 13) absolute indirect           - JMP (abs)
; 14) indirect                    - opcode (zp)
; 15) indirect indexed Y          - opcode (zp),Y
;=================================================
; Implied and accumulator mode opcodes are all single bytes
; PC rel (branch ops) are 2 bytes
; Only these 3 modes need to be considered separately viz
; JMP (abs) - 1 of its kind!
; opcode (abs,X) JMP (abs,X) - one of its kind
; opcode zp,Y -  LDX zp,Y STX zp,Y - 2 only
; NOP,BRK special
;
; This table is for ADC/AND/ etc
; L8516 DB $03,$02,$02,$02,$03,$03,$02,$02,$02 ;instr len for 9 addr modes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
OpcodeT     EQU    *
ADCOps      EQU    *
            DB     $6D             ;ADC abs          3
            DB     $65             ;ADC zp           2
            DB     $69             ;ADC #            2
            DB     $75             ;ADC zp,X         2
            DB     $7D             ;ADC abs,X        3
            DB     $79             ;ADC abs,Y        3
            DB     $71             ;ADC (zp),Y       2
            DB     $61             ;ADC (zp,X)       2
            DB     $72             ;ADC (zp) - C02   2
;
ANDOps      EQU    *
            DB     $2D             ;AND abs
            DB     $25             ;AND zp
            DB     $29             ;AND #
            DB     $35             ;AND zp,X
            DB     $3D             ;AND abs,X
            DB     $39             ;AND abs,Y
            DB     $31             ;AND (zp),Y
            DB     $21             ;AND (zp,X)
            DB     $32             ;AND (zp) - C02
;
ASLOps      EQU    *
            DB     $0E             ;ASL abs
            DB     $06             ;ASL zp
            DB     $0A             ;ASL A
            DB     $16             ;ASL zp,X
            DB     $1E             ;ASL abs,X
;
            DB     $90             ;BCC
            DB     $B0             ;BCS
            DB     $F0             ;BEQ
;
BITOps      EQU    *
            DB     $2C             ;BIT abs
            DB     $24             ;BIT zp
            DB     $89             ;BIT # - C02
            DB     $34             ;BIT zp,X - C02
            DB     $3C             ;BIT abs,X - C02
;
            DB     $30             ;BMI
            DB     $D0             ;BNE
            DB     $10             ;BPL
            DB     $80             ;BRA
            DB     $00             ;BRK
            DB     $50             ;BVC
            DB     $70             ;BVS
;
CLROps      EQU    *
            DB     $18             ;CLC
            DB     $D8             ;CLD
            DB     $58             ;CLI
            DB     $B8             ;CLV
;
CMPOps      DB     $CD             ;CMP
            DB     $C5             ;CMP
            DB     $C9             ;CMP #
            DB     $D5             ;CMP
            DB     $DD             ;CMP
            DB     $D9             ;CMP
            DB     $D1             ;CMP
            DB     $C1             ;CMP
            DB     $D2             ;CMP
;
CPXOps      EQU    *
            DB     $EC             ;CPX abs
            DB     $E4             ;CPX zp
            DB     $E0             ;CPX #
;
CPYOps      EQU    *
            DB     $CC             ;CPY abs
            DB     $C4             ;CPY zp
            DB     $C0             ;CPY #
;
DECOps      EQU    *
            DB     $CE             ;DEC abs
            DB     $C6             ;DEC zp
            DB     $3A             ;DEC A - C02
            DB     $D6             ;DEC zp,X
            DB     $DE             ;DEC abs,X
;
            DB     $CA             ;DEX
            DB     $88             ;DEY
;
EOROps      EQU    *
            DB     $4D             ;EOR
            DB     $45             ;EOR
            DB     $49             ;EOR
            DB     $55             ;EOR
            DB     $5D             ;EOR
            DB     $59             ;EOR
            DB     $51             ;EOR
            DB     $41             ;EOR
            DB     $52             ;EOR
;
INCOps      EQU    *
            DB     $EE             ;INC
            DB     $E6             ;INC
            DB     $1A             ;INC
            DB     $F6             ;INC
            DB     $FE             ;INC
;
            DB     $E8             ;INX
            DB     $C8             ;INY
;
JMPOps      EQU    *
            DB     $4C             ;JMP abs
            DB     $6C             ;JMP (abs)
            DB     $7C             ;JMP (abs,X) - C02
;
JSROps      DB     $20             ;JSR abs
;
LDAOps      EQU    *
            DB     $AD             ;LDA
            DB     $A5             ;LDA
            DB     $A9             ;LDA
            DB     $B5             ;LDA
            DB     $BD             ;LDA
            DB     $B9             ;LDA
            DB     $B1             ;LDA
            DB     $A1             ;LDA
            DB     $B2             ;LDA
;
LDXOps      EQU    *
            DB     $AE             ;LDX abs
            DB     $A6             ;LDX zp
            DB     $A2             ;LDX #
            DB     $B6             ;LDX zp,Y
            DB     $00             ;Acc - (TXA)
            DB     $BE             ;LDX abs,Y
;
LDYOps      EQU    *
            DB     $AC             ;LDY abs
            DB     $A4             ;LDY zp
            DB     $A0             ;LDY #
            DB     $B4             ;LDY zp,X
            DB     $BC             ;LDY abs,X
;
LSROps      EQU    *
            DB     $4E             ;LSR
            DB     $46             ;LSR
            DB     $4A             ;LSR
            DB     $56             ;LSR
            DB     $5E             ;LSR
;
NOPOps      DB     $EA             ;NOP
;
ORAOps      EQU    *
            DB     $0D             ;ORA
            DB     $05             ;ORA
            DB     $09             ;ORA
            DB     $15             ;ORA
            DB     $1D             ;ORA
            DB     $19             ;ORA
            DB     $11             ;ORA
            DB     $01             ;ORA
            DB     $12             ;ORA
;
PSHOps      EQU    *
            DB     $48             ;PHA
            DB     $08             ;PHP
            DB     $DA             ;PHX
            DB     $5A             ;PHY
            DB     $68             ;PLA
            DB     $28             ;PLP
            DB     $FA             ;PLX
            DB     $7A             ;PLY
;
ROLOps      EQU    *
            DB     $2E             ;ROL
            DB     $26             ;ROL
            DB     $2A             ;ROL
            DB     $36             ;ROL
            DB     $3E             ;ROL
;
ROROps      EQU    *
            DB     $6E             ;ROR
            DB     $66             ;ROR
            DB     $6A             ;ROR
            DB     $76             ;ROR
            DB     $7E             ;ROR
;
            DB     $40             ;RTI
            DB     $60             ;RTS
;
SBCOps      EQU    *
            DB     $ED             ;SBC
            DB     $E5             ;SBC
            DB     $E9             ;SBC
            DB     $F5             ;SBC
            DB     $FD             ;SBC
            DB     $F9             ;SBC
            DB     $F1             ;SBC
            DB     $E1             ;SBC
            DB     $F2             ;SBC
;
            DB     $38             ;SEC
            DB     $F8             ;SED
            DB     $78             ;SEI
;
STAOps      EQU    *
            DB     $8D             ;STA abs
            DB     $85             ;STA zp
            DB     $00             ;# - missing
            DB     $95             ;STA zp,X
            DB     $9D             ;STA abs,X
            DB     $99             ;STA abs,Y
            DB     $91             ;STA (zp),y
            DB     $81             ;STA (zp,X)
            DB     $92             ;STA (zp)
;
STXOps      EQU    *
            DB     $8E             ;STX abs
            DB     $86             ;STX zp
            DB     $00             ;abs,X missing
            DB     $96             ;STX zp,Y
;
STYOps      EQU    *
            DB     $8C             ;STY abs
            DB     $84             ;STY zp
            DB     $00             ;abs,X missing
            DB     $94             ;STY zp,X
;
STZOps      EQU    *
            DB     $9C             ;STZ abs - C02
            DB     $64             ;STZ zp - C02
            DB     $00             ;# - missing
            DB     $74             ;STZ zp,X - C02
            DB     $9E             ;STZ abs,X - C02
;
            DB     $AA             ;TAX
            DB     $A8             ;TAY
;
TRBOps      EQU    *
            DB     $1C             ;TRB abs - C02
            DB     $14             ;TRB zp - C02
;
TSBOps      EQU    *
            DB     $0C             ;TSB abs - C02
            DB     $04             ;TSB zp - C02
;
            DB     $BA             ;TSX
            DB     $8A             ;TXA
            DB     $9A             ;TXS
            DB     $98             ;TYA
;
; ($D8EC) These are SW16 pseudo opcodes (30 bytes)
; SET ($10) is treated separately & is missing fr this table
; NB-Like the table above, these pseudo opcodes are
; in alphabetic order
;
SW16Ops     EQU    *
            DB     $A0             ;ADD
            DB     $03             ;BC
            DB     $0A             ;BK
            DB     $05             ;BM
            DB     $08             ;BM1
            DB     $02             ;BNC
            DB     $09             ;BNM1
            DB     $07             ;BNZ
            DB     $04             ;BP
            DB     $01             ;BR
            DB     $0E             ;BRL
            DB     $0C             ;BS
            DB     $0F             ;BSL
            DB     $06             ;BZ
            DB     $0D             ;CPIM
            DB     $D0             ;CPR
            DB     $F0             ;DCR
            DB     $E0             ;INR
            DB     $20             ;LD
            DB     $60             ;LDD
            DB     $40             ;LDI
            DB     $80             ;POP
            DB     $C0             ;POPD
            DB     $00             ;RTN
            DB     $0B             ;RS
            DB     $30             ;ST
            DB     $50             ;STI
            DB     $70             ;STD
            DB     $90             ;STP
            DB     $B0             ;SUB
;=================================================
; ($D90A) 213 bytes cycle times
; A value of $29 -> no cycle times?
;=================================================
CycTimes    DB     4               ;ADC abs
            DB     3               ;ADC zp
            DB     2               ;ADC #
            DB     4               ;ADC zp,X
            DB     4               ;ADC abs,X
            DB     4               ;ADC abs,Y
            DB     5               ;ADC (zp),y
            DB     6               ;ADC (zp,X)
            DB     5               ;ADC (zp)
;
            DB     04,03,02,04,04,04,05,06,05;AND
            DB     06,05,02,06,07  ;ASL
            DB     03,03,03        ;BCC,BCS,BEQ
            DB     04,03,02,04,04  ;BIT
            DB     03,03,03,03,07,03,03;BMI,BNE,BPL,BRA,BRK,BVC,BVS
            DB     02,02,02,02     ;CLC,CLD,CLI,CLV
;
            DB     04,03,02,04,04,04,05,06,05;CMP
;
            DB     04,03,02        ;CPX
            DB     04,03,02        ;CPY
;
            DB     06,05,02,06,07  ;DEC
            DB     02,02           ;DEX,DEY
;
            DB     04,03,02,04,04,04,05,06,05;EOR
            DB     06,05,02,06,07  ;INC
            DB     02,02           ;INX,INY
;
            DB     03,05,06,06     ;JMP,JSR
            DB     04,03,02,04,04,04,05,06,05;LDA
;
            DB     04,03,02,04,$29,04;LDX
            DB     04,03,02,04,04  ;LDY
            DB     06,05,02,06,07  ;LSR
            DB     02              ;NOP
            DB     04,03,02,04,04,04,05,06,05;ORA
            DB     03,03,03,03     ;PHA,PHP,PHX,PHY
            DB     04,04,04,04     ;PLA,PLP,PLX,PLY
;
            DB     06,05,02,06,07  ;ROL
            DB     06,05,02,06,07  ;ROR
;
            DB     6,6             ;RTI,RTS
            DB     04,03,02,04,04,04,05,06,05;SBC
;
            DB     02,02,02        ;SEC,SED,SEI
            DB     04,03,$29,04,05,05,06,06,05;STA
;
            DB     04,03,$29,04    ;STX
            DB     04,03,$29,04    ;STY
            DB     04,03,$29,04,05 ;STZ
;
            DB     02,02           ;TAX,TAY
            DB     06,05,06,05     ;TRB,TSB
            DB     02,02,02,02     ;TSX,TXA,TXS,TYA
;
; 30 bytes - no cycle time for SW16 pseudo opcodes
;
            DB     $29,$29,$29,$29,$29,$29,$29,$29
            DB     $29,$29,$29,$29,$29,$29,$29,$29
            DB     $29,$29,$29,$29,$29,$29,$29,$29
            DB     $29,$29,$29,$29,$29,$29
;=================================================
; ($D9DF) Char mapping
;   char            NV-B DIZC
; '0'-'9' -->  $43 (0100 0011)
; 'A'-'F' -->  $40 (0100 0000) (hexdec)
; 'G'-'Z' -->  $00 (0000 0000)
; 'a'-'f' -->  $C0 (1100 0000)
; 'g'-'z' -->  $80 (1000 0000)
; others  -->  $01 (0000 0001)
; Value is popped into Status reg
; setting/resetting its ALL bits
;
CharMap1    DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $01,$01,$01,$01,$01,$01,$01,$01
            DB     $43,$43,$43,$43,$43,$43,$43,$43;$30-$39
            DB     $43,$43
            DB     $01,$01,$01,$01,$01,$01,$01
            DB     $40,$40,$40,$40,$40,$40;$41-$46
            DB     $00,00,00,00,00,00,00,00,00
            DB     $00,00,00,00,00,00,00,00,00,00,00
            DB     $01,01,01,01,01,01
            DB     $C0,$C0,$C0,$C0,$C0,$C0;$61-$66
            DB     $80,$80,$80,$80,$80,$80,$80,$80,$80;$67-$7A
            DB     $80,$80,$80,$80,$80,$80,$80,$80,$80
            DB     $80,$80
            DB     $01,$01,$01,$01,$01
;=================================================
; Char mapping
;   char            NV-B DIZC
; '0'-'9' -->  $42 (0100 0010)
; 'A'-'F' -->  $40 (0100 0000)
; 'G'-'Z' -->  $00 (0000 0000)
; 'a'-'f' -->  $C0 (1100 0000)
; 'g'-'z' -->  $80 (1000 0000)
; others  -->  $01 (0000 0001)
; Value is popped into Status reg
; setting/resetting its ALL bits
;
CharMap2    DB     01,01,01,01,01,01,01,01
            DB     01,01,01,01,01,01,01,01
            DB     01,01,01,01,01,01,01,01
            DB     01,01,01,01,01,01,01,01
            DB     01,01,01,01,01,01,01,01
            DB     01,01,01,01,01,01,00,01
            DB     $42,$42,$42,$42,$42,$42;$30-$39
            DB     $42,$42,$42,$42
            DB     01,01,01,01,01,01,01
            DB     $40,$40,$40,$40,$40,$40;$41-$46
            DB     00,00,00,00,00,00,00,00,00
            DB     00,00,00,00,00,00,00,00,00,00,00
            DB     01,01,01,01,01,01
            DB     $C0,$C0,$C0,$C0,$C0,$C0;$61-$66
            DB     $80,$80,$80,$80,$80,$80,$80,$80,$80;$67-$7A
            DB     $80,$80,$80,$80,$80,$80,$80,$80,$80
            DB     $80,$80
            DB     01,01,01,01,01
;=================================================
; Directives/Mnemonics/Sweet16 table
; The table entries are variable in length
; because of the DCI text field
; Format of an entry
; If mnemonics
;  1) DCI text - variable in len
;  2) 1st flag byte - permitted addressing modes
;  3) 2nd flag byte - permitted addressing modes
;  4) index into opcode & cycle timing tables
; If directives
;  1) DCI text
;  2) flag byte - $80/$81
;  3) DDB JMP addr-1
;
; 1st Flag byte
; 1000 000x - directives (if x=1, print expr result field)
; 0100 xxxx - sweet16 pseudo opcode
; 0010 0000 - single byte opcodes excluding acc mode opcodes
; 0001 000x - JMP,JSR,CPIM,BSL,BRL
; 0000 1000 - branch opcodes
; 0000 0100 - LDX,STX --> special mode viz LDX zp,Y or STX zp,Y
; 0000 0011 - ADC,AND,CMP,EOR,LDA,ORA,SBC,STA
; 0000 0010 - ASL,DEC,INC,LSR,ROL,ROR
; 0000 0001 - JMP (abs)
; 0000 0000 - BIT,CPX,CPY,LDY,STY,STZ,TRB,TSB
;
; 1st Flag byte - addressing modes
; 1000 0000 - Directives
; 0100 0000 - Sweet 16
; 0010 0000 - Implied mode
; 0001 0000 - (abs)
; 0000 1000 - Relative mode
; 0000 0100 - zp,Y (for LDX,STX)
; 0000 0011 - (zp)
; 0000 0010 - acc mode
; 0000 0001 - (abs,X) (for JMP)
; 0000 0000
;
; 2nd flag byte - addressing modes
;
; 1000 0000 - (zp,X)
; 0100 0000 - (zp),Y
; 0010 0000 - abs,Y
; 0001 0000 - abs,X
; 0000 1000 - zp,X
; 0000 0100 - immediate mode
; 0000 0010 - zp
; 0000 0001 - abs
;
; NB: If the meaning of the bits in the 2 flag bytes
; are re-arranged/changed, the data tables OpcodeT,
; ModeBitsT etc. must be modified as well. Code
; involving the use of these values must be re-written
;
; Single byte (excluding those which are acc modes)
; & branch ops don't have sub-tables
;
MnemTbl     EQU    *
LtrA        DCI    'ADC'           ;mnemonics
            DB     %00000011       ;$03
            DB     %11111111       ;$FF
            DB     ADCOps-OpcodeT  ;index to sub-table of Opcode table
            DCI    'ADD'
            DB     $40             ;0100 0000
            DB     $02
            DB     SW16Ops-OpcodeT
            DCI    'AND'
            DB     %00000011       ;$03
            DB     %11111111       ;$FF
            DB     ANDOps-OpcodeT
            DCI    'ASC'
            DB     %10000000
            DDB    L8DD2-1
            DCI    'ASL'
            DB     %00000010       ;$02
            DB     %00011011       ;$1B
            DB     ASLOps-OpcodeT
LtrB        DCI    'BC'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+1
;
            DCI    'BCC'
            DB     %00001000       ;$08
            DB     %00000011       ;$03
            DB     $17             ; -OpcodeT
            DCI    'BCS'
            DB     $08
            DB     $03
            DB     $18
            DCI    'BEQ'
            DB     $08
            DB     $03
            DB     $19
            DCI    'BGE'
            DB     $08
            DB     $03
            DB     $18
;
            DCI    'BIT'
            DB     %00000000       ;$00
            DB     %00011111       ;$1F
            DB     BITOps-OpcodeT
            DCI    'BK'
            DB     $60             ;0110 0000
            DB     $00
            DB     SW16Ops-OpcodeT+2
            DCI    'BLT'
            DB     $08
            DB     $03
            DB     $17
            DCI    'BM'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+3
            DCI    'BM1'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+4
;
            DCI    'BMI'
            DB     $08
            DB     $03
            DB     $1F             ; -OpCodeT
            DCI    'BNC'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+5
            DCI    'BNE'
            DB     $08
            DB     $03
            DB     $20
            DCI    'BNM1'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+6
            DCI    'BNZ'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+7
            DCI    'BP'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+8
            DCI    'BPL'
            DB     $08
            DB     $03
            DB     $21
            DCI    'BR'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+9
            DCI    'BRA'
            DB     $08
            DB     $03
            DB     $22
;
            DCI    'BRK'
            DB     $20
            DB     $00
            DB     $23
            DCI    'BRL'
            DB     $58             ;0101 1000
            DB     $03
            DB     SW16Ops-OpcodeT+10
            DCI    'BS'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+11
            DCI    'BSL'
            DB     $58             ;0101 1000
            DB     $03
            DB     SW16Ops-OpcodeT+12
;
            DCI    'BVC'
            DB     $08
            DB     $03
            DB     $24
            DCI    'BVS'
            DB     $08
            DB     $03
            DB     $25
            DCI    'BZ'
            DB     $48             ;0100 1000
            DB     $03
            DB     SW16Ops-OpcodeT+13
LtrC        DCI    'CHN'
            DFB    $80
            DDB    L928C-1
            DCI    'CHR'
            DFB    $80
            DDB    L8FC7-1
;
            DCI    'CLC'
            DB     $20             ;0010 0000
            DB     $00
            DB     $26
            DCI    'CLD'
            DB     $20
            DB     $00
            DB     $27
            DCI    'CLI'
            DB     $20
            DB     $00
            DB     $28
            DCI    'CLV'
            DB     $20
            DB     $00
            DB     $29
;
            DCI    'CMP'
            DB     $03             ;0000 0011
            DB     $FF
            DB     CMPOps-OpcodeT
            DCI    'CPIM'
            DB     $50             ;0101 0000
            DB     $01
            DB     SW16Ops-OpcodeT+14
            DCI    'CPR'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+15
;
            DCI    'CPX'
            DB     $00
            DB     $07
            DB     CPXOps-OpcodeT
            DCI    'CPY'
            DB     $00
            DB     $07
            DB     CPYOps-OpcodeT
;
LtrD        DCI    'DATE'
            DB     $80
            DDB    L901D-1
            DCI    'DB'
            DB     $80
            DDB    L8CC3-1
            DCI    'DCI'
            DB     $80
            DDB    L8E54-1
            DCI    'DCR'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+16
            DCI    'DDB'
            DB     $80
            DDB    L8DCD-1
;
            DCI    'DEC'
            DB     $02             ;0000 0010
            DB     $1B
            DB     DECOps-OpcodeT
            DCI    'DEF'
            DB     $81
            DDB    L9144-1
            DCI    'DEND'
            DB     $80
            DDB    L908E-1
;
            DCI    'DEX'
            DB     $20
            DB     $00
            DB     $3E
            DCI    'DEY'
            DB     $20
            DB     $00
            DB     $3F
;
            DCI    'DFB'
            DB     $80
            DDB    L8CC3-1
            DCI    'DO'
            DB     $81             ;1000 0001
            DDB    L90B7-1
            DCI    'DS'
            DB     $81
            DDB    L8C0E-1
            DCI    'DSECT'
            DB     $80
            DDB    L9065-1
            DCI    'DW'
            DB     $80
            DDB    L8D67-1
LtrE        DCI    'ELSE'
            DB     $80
            DDB    L90CB-1
            DCI    'ENTRY'
            DB     $81
            DDB    L9144-1
;
            DCI    'EOR'
            DB     $03
            DB     $FF
            DB     EOROps-OpcodeT
            DCI    'EQU'
            DB     $81
            DDB    L8A31-1
            DCI    'EXTRN'
            DB     $81
            DDB    L91A8-1
LtrF        DCI    'FAIL'
            DB     $80
            DDB    L9215-1
            DCI    'FIN'
            DB     $80
            DDB    L90D7-1
LtrI        DCI    'IBUFSIZ'
            DB     $81
            DDB    L93C4-1
            DCI    'IDNUM'
            DB     $80
            DDB    L905E-1
            DCI    'IFEQ'
            DB     $81
            DDB    L90DE-1
            DCI    'IFGE'
            DB     $81
            DDB    L90FC-1
            DCI    'IFGT'
            DB     $81
            DDB    L90EB-1
            DCI    'IFNE'
            DB     $81
            DDB    L90B7-1
            DCI    'IFLE'
            DB     $81
            DDB    L9112-1
            DCI    'IFLT'
            DB     $81
            DDB    L9107-1
;
            DCI    'INC'
            DB     $02
            DB     $1B
            DB     INCOps-OpcodeT
            DCI    'INCLUDE'
            DB     $80
            DDB    L9360-1
            DCI    'INR'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+17
            DCI    'INTERP'
            DB     $81
            DDB    L9131-1
;
            DCI    'INX'
            DB     $20
            DB     $00
            DB     $4E
            DCI    'INY'
            DB     $20
            DB     $00
            DB     $4F
LtrJ        DCI    'JMP'
            DB     $11             ;0001 0001
            DB     %00000001
            DB     JMPOps-OpcodeT
            DCI    'JSR'
            DB     $10             ;0001 0000
            DB     %00000001
            DB     JSROps-OpcodeT
;
LtrL        DCI    'LD'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+18
;
            DCI    'LDA'
            DB     $03
            DB     $FF
            DB     LDAOps-OpcodeT
;
            DCI    'LDD'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+19
            DCI    'LDI'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+20
            DCI    'LDP'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+21
;
            DCI    'LDX'
            DB     $04             ;0000_0100
            DB     %00100111       ;$27
            DB     LDXOps-OpcodeT
            DCI    'LDY'
            DB     $00
            DB     %00011111       ;$1F
            DB     LDYOps-OpcodeT
;
            DCI    'LSL'
            DB     $02
            DB     $1B
            DB     ASLOps-OpcodeT
            DCI    'LSR'
            DB     $02
            DB     $1B
            DB     LSROps-OpcodeT
;
            DCI    'LST'
            DB     $80
            DDB    L8ECA-1
LtrM        DCI    'MACLIB'
            DB     $80
            DDB    L937F-1
            DCI    'MSB'
            DB     $80
            DDB    L8E66-1
;
LtrN        DCI    'NOP'
            DB     $20
            DB     $00
            DB     $6D
LtrO        DCI    'OBJ'
            DB     $81
            DDB    L8BAD-1
;
            DCI    'ORA'
            DB     $03
            DB     $FF
            DB     ORAOps-OpcodeT
            DCI    'ORG'
            DB     $81
            DDB    L8A82-1
LtrP        DCI    'PAGE'
            DB     $80
            DDB    DoPage-1
            DCI    'PAUSE'
            DB     $80
            DDB    L927A-1
;
            DCI    'PHA'
            DB     $20
            DB     $00
            DB     $77
            DCI    'PHP'
            DB     $20
            DB     $00
            DB     $78
            DCI    'PHX'
            DB     $20
            DB     $00
            DB     $79
            DCI    'PHY'
            DB     $20
            DB     $00
            DB     $7A
            DCI    'PLA'
            DB     $20
            DB     $00
            DB     $7B
            DCI    'PLP'
            DB     $20
            DB     $00
            DB     $7C
            DCI    'PLX'
            DB     $20
            DB     $00
            DB     $7D
            DCI    'PLY'
            DB     $20
            DB     $00
            DB     $7E
;
            DCI    'POP'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+21
            DCI    'POPD'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+22
LtrR        DCI    'REF'
            DB     $81
            DDB    L91A8-1
            DCI    'REL'
            DB     $80
            DDB    L9126-1
            DCI    'REP'
            DB     $80
            DDB    L8FA3-1
;
            DCI    'ROL'
            DB     $02
            DB     $1B
            DB     ROLOps-OpcodeT
            DCI    'ROR'
            DB     $02
            DB     $1B
            DB     ROROps-OpcodeT
;
            DCI    'RS'
            DB     $60             ;0110 0000
            DB     $00
            DB     SW16Ops-OpcodeT+24
;
            DCI    'RTI'
            DB     $20
            DB     $00
            DB     $89
            DCI    'RTN'
            DB     $60             ;0110 0000
            DB     $00
            DB     $23             ;BRK?
            DCI    'RTS'
            DB     $20
            DB     $00
            DB     $8A
;
LtrS        DCI    'SBC'
            DB     $03
            DB     $FF
            DB     SBCOps-OpcodeT
            DCI    'SBTL'
            DB     $80
            DDB    L8F61-1
            DCI    'SBUFSIZ'
            DB     $81
            DDB    L93C7-1
;
            DCI    'SEC'
            DB     $20
            DB     $00
            DB     $94
            DCI    'SED'
            DB     $20
            DB     $00
            DB     $95
            DCI    'SEI'
            DB     $20
            DB     $00
            DB     $96
;
            DCI    'SET'
            DB     $C0             ;1100 0000
            DDB    L94C0-1
            DCI    'SKP'
            DB     $80
            DDB    L8FEA-1
            DCI    'ST'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+25
;
            DCI    'STA'
            DB     %00000011
            DB     %11111011
            DB     STAOps-OpcodeT
            DCI    'STD'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+27
            DCI    'STI'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+26
            DCI    'STP'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+28
            DCI    'STR'
            DB     $80
            DDB    L8E94-1
;
            DCI    'STX'
            DB     $04             ;0000_0100
            DB     %00000011       ;$03
            DB     STXOps-OpcodeT
            DCI    'STY'
            DB     $00
            DB     $0B             ;0000_1011
            DB     STYOps-OpcodeT
            DCI    'STZ'
            DB     $00
            DB     $1B
            DB     STZOps-OpcodeT
;
            DCI    'SUB'
            DB     $40
            DB     $02
            DB     SW16Ops-OpcodeT+29
            DCI    'SYS'
            DB     $81
            DDB    L9131-1
            DCI    'SW16'
            DB     $C0             ;1100 0000
            DDB    L946F-1
;
LtrT        DCI    'TAX'
            DB     $20
            DB     $00
            DB     $AD
            DCI    'TAY'
            DB     $20
            DB     $00
            DB     $AE
            DCI    'TIME'
            DB     $80
            DDB    L905E-1
;
            DCI    'TRB'
            DB     $00
            DB     $03
            DB     TRBOps-OpcodeT
            DCI    'TSB'
            DB     $00
            DB     $03
            DB     TSBOps-OpcodeT
;
            DCI    'TSX'
            DB     $20
            DB     $00
            DB     $B3
            DCI    'TXA'
            DB     $20
            DB     $00
            DB     $B4
            DCI    'TXS'
            DB     $20
            DB     $00
            DB     $B5
            DCI    'TYA'
            DB     $20
            DB     $00
            DB     $B6
;
LtrX        DCI    'X6502'
            DB     $81
            DDB    L9139-1
LtrZ        DCI    'ZDEF'
            DB     $81
            DDB    L9140-1
            DCI    'ZREF'
            DB     $81
            DDB    L91A4-1
            DCI    'ZXTRN'
            DB     $81
            DDB    L91A4-1
DotDrtv     DCI    '.ASCII'
            DB     $80
            DDB    L8DD2-1
            DCI    '.BLOCK'
            DB     $81
            DDB    L8C0E-1
            DCI    '.BYTE'
            DB     $80
            DDB    L8CC3-1
            DCI    '.DBYTE'
            DB     $80
            DDB    L8DCD-1
            DCI    '.DEF'
            DB     $81
            DDB    L9144-1
            DCI    '.EQU'
            DB     $81
            DDB    L8A31-1
            DCI    '.INCLUDE'
            DB     $80
            DDB    L9360-1
            DCI    '.LIST'
            DB     $80
            DDB    L8F3D-1
            DCI    '.NOLIST'
            DB     $80
            DDB    L8F3A-1
            DCI    '.ORG'
            DB     $81
            DDB    L8A82-1
            DCI    '.PAGE'
            DB     $80
            DDB    DoPage-1
            DCI    '.REF'
            DB     $81
            DDB    L91A8-1
            DCI    '.SKIP'
            DB     $80
            DDB    L8FEA-1
            DCI    '.TITLE'
            DB     $80
            DDB    L8F61-1
            DCI    '.WORD'
            DB     $80
            DDB    L8D67-1
            DS     4,0             ;unused
;=================================================
; Table of ptrs to first letter subtables
;
Tbl1stLet   DW     DotDrtv
            DW     LtrA
            DW     LtrB
            DW     LtrC
            DW     LtrD
            DW     LtrE
            DW     LtrF
            DW     $0000
            DW     $0000
            DW     LtrI
            DW     LtrJ
            DW     $0000
            DW     LtrL
            DW     LtrM
            DW     LtrN
            DW     LtrO
            DW     LtrP
            DW     $0000
            DW     LtrR
            DW     LtrS
            DW     LtrT
            DW     $0000
            DW     $0000
            DW     $0000
            DW     LtrX
            DW     $0000
            DW     LtrZ
;
; Assembler's creation date and time
;
LDF3F       ASC    '30-APR-85'
LDF48       ASC    '22:46          '
;
; Area to preserve the zero page locations $60-$F1
;
SvZPArea    DS     $92,0
;
; ($DFE0) Haven't figure out what is this!
; May be encoded message. Or just random bytes
; generated by a DS 32 statement
;
            DW     $D581
            DW     $D589
            DW     $D58E
            DW     $D546
            DW     $A023
            DW     $A048
            DW     $A308
            DW     $DCC7
            DW     $9BF8
            DW     $A071
            DW     $B9AF
            DW     $9B18
            DW     $9B6D
            DW     $DDC0
            DW     $9F49
            DW     $C8D3
            REP    50