Name          : BB1.S
End of file   :   14,078
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            ORG    $0800
            MSB    ON
; BB (ProDOS version) was assembled @ $0800
; but may be run from any location starting
; from $0800 as long as there is enough memory
;
BBSTART     EQU    *
            SEC
            BCS    SkipSWA
;
XUNDSW      DB     $80             ;Allow BB to call ProDOS
Btn0SW      DB     $00             ;Use Paddle button 0 for trace/suspend (ON=$80)
PDL0SW      DB     $80             ;Use Paddle 0 for trace rate
KBDPOLL     DB     $00             ;Tr/SS keyboard polling (msb on=OFF)
SNDSW       DB     $80             ;$80-ON
CYCLEC      DW     $0000           ;Cycle Counter
BARTC       DW     $FFFF           ;Beginning & Ending Addresses
EARTC       DW     $FFFF           ; of Real Time Code
;
IBuff       EQU    *               ;$080E-$088D (128 chars)
SkipSWA     LDA    #iRTS
            STA    Z2F
            JSR    Z2F
RetHere     EQU    *
            TSX
            LDY    STACK,X         ;Hi
            DEX
            LDA    STACK,X
            SBC    #>RetHere-1
            STA    Z44
            BCS    L0824
            DEY
L0824       STY    Z44+1           ;($44,$45)=load addr
;
            CLC
            ADC    #>L08CF
            STA    MONPC           ;bugbyter's main entry point
            BCC    L082E
            INY
L082E       STY    MONPC+1
;
            CLC
            ADC    #>BBDATA-L08CF  ;#$46
            STA    Z46             ;Point to end of bugbyter's program code
            TYA
            ADC    #<BBDATA-L08CF  ;#$17
            STA    Z46+1
;
; This part of the code modifies the instruction @
; the load address to a JMP to BugByter's main entry point
;
            LDY    #0
            LDA    #iJMP
L083E       STA    (Z44),Y
            LDA    MONPC,Y         ;Get load address
            INY
            CPY    #3
            BCC    L083E
;
            LDA    Z44+1           ;Only need to modify the Hi byte because BB is
            SBC    #<BBSTART       ; assembled @ $0800 which is the lowest mem page
            STA    Z44+1           ;($44,45)=offset to be added to abs addrs
L084E       BCC    L084E           ;BB will hang if run addr below $800
;
; On fall thru, (MONPC) is pointing @ BugByter's main entry
; point. Basically, we will be looking for $X9,$XC,$XD,$XE
; $XF are assummed to be abs opcodes
; $29,$49,$69 etc are 2-byte immediate opcodes
;
L0850       LDY    #0
            LDA    (MONPC),Y       ;Get instruction's opcode
            TAX                    ;save it temporarily
            AND    #%00011111      ;xxxx xxxx  -> 000x xxxx
            CMP    #%00011001      ;Checking for opcodes $19,$39,$59 etc
            BEQ    L0874
            AND    #$0F            ;0000 xxxx
            CMP    #%00001100      ;This should cover ($XC,$XD,$XE)
            BCS    L0874
            AND    #%00001101      ;0000 xx0x
            CMP    #%00001000      ;$X8 opcodes (1-byte)
            BEQ    L0890           ;NB: (Y)=0
            TXA                    ;Restore opcode
            BEQ    L0890           ;BRK instruction
            CMP    #iJSR
            BEQ    L0874
            AND    #%10011111      ;x00x xxxx (Y)=0
            BNE    L088F           ;Assume all are 2-byte instructions
            BEQ    L0890           ;($40,$60) always
;
; Handle 3-byte 65C02 instructions
; We only need to consider references to memory
; locations btwn BBSTART-BBDATA ($0800-$2150)
;
L0874       INY                    ;Skip opcode & low byte of abs addr
            INY
            LDA    (MONPC),Y       ;Abs addr's hi byte
            CMP    #<BBSTART       ;Modify abs addrs btwn $0800-$2400
            BCC    L0890
            CMP    #BBEND+$100/256
            BCS    L0890
;
            DEY
            LDA    (MONPC),Y       ;Get abs addr's lobyte
            ADC    Z44             ;Add offset to get
            STA    (MONPC),Y       ; relocated addr
            INY
            LDA    (MONPC),Y
            ADC    Z44+1
            STA    (MONPC),Y
            DEY                    ;Indexing lobyte
;
; The code in this area will be overwritten by BB.
; Saved area (67 bytes) for instructions and their format bytes
; when real BP addrs are set
;
L088F       EQU    *
            INY
L0890       SEC                    ;Advance our PC
            TYA
            ADC    MONPC
            STA    MONPC
            BCC    L089A
            INC    MONPC+1
;
L089A       CMP    Z46             ;Are we done with modifying
            LDA    MONPC+1
            SBC    Z46+1           ; all the abs addrs?
            BCC    L0850           ;nope
;
; Now, modify all JMP addrs of BB's cmd table
;
            LDA    Z44             ;NB:C set on fall thru
            ADC    #>CMDTBL-1
            STA    MONPC
            LDA    Z44+1
            ADC    #<CMDTBL
            STA    MONPC+1
;
            LDY    #0
L08B0       LDA    (MONPC),Y       ;Add offset to
            ADC    Z44
            STA    (MONPC),Y
            INY
            LDA    (MONPC),Y
            ADC    Z44+1
            STA    (MONPC),Y       ; the JMP addrs
            INY
            CPY    #NumJmps
            BCC    L08B0
;
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
            NOP
;=================================================
; MAIN ENTRY POINT
;
L08CF       LDA    OURCTLYV        ;Ctrl-Y vector
            STA    USRADR+1
            LDA    OURCTLYV+1
            STA    USRADR+2
;
            LDA    BRKV            ;Save curr BREAK vector
            STA    SVBRKV
            LDA    BRKV+1
            STA    SVBRKV+1
            LDA    OURBRKV         ; & use BB's
            STA    BRKV
            LDA    OURBRKV+1
            STA    BRKV+1
;
            LDA    #>MONZ          ;RESET vector
            STA    SOFTEV
            LDA    #<MONZ
            STA    SOFTEV+1
            LDA    #$5A
            STA    PWREDUP
            LDX    #>BBStack       ;BB's stack usage ($100-$11F)
            TXS
            JSR    SwapZP
            JSR    DRegHdr         ;Show registers
            JSR    L0ADD           ;Show all SDs
;
; Display copyright notice
;
DCPYRCMD    LDX    #$26
L0910       LDA    COPYRK,X
            STA    SLIN23+1,X
            DEX
            BPL    L0910
            JMP    BBGetLn
;=================================================
; BB's ctrl-Y Handler
;
WrmStrt     JSR    SwapZP
L091F       JSR    DRegHdr
L0922       JSR    L0ADD           ;Show all SDs
XDelLin     JMP    DelLin
;=================================================
; Execute cmd
;
XCmd        LDX    INPUTLEN        ;null entry?
            BEQ    XDelLin
            BIT    MemPgDSW        ;Mem Page being displayed?
            BMI    ParseCmd        ;Yes
            JSR    HndlCmd
            BEQ    ParseCmd        ;No hit
;
            STX    Z40             ;Entry #
            TXA
            ASL
            TAX
            LDA    CMDTBL+1,X
            PHA
            LDA    CMDTBL,X
            PHA
            RTS
;
EqSign      INY
            INY
            JSR    Bin2Dec
            JMP    L0982
;
; Convert dec rep to hex rep
;
PlusDecS    LDA    #$00
            BEQ    L0953           ;always
NegDecS     LDA    #$80
L0953       STA    Z40
            INY
            JSR    Dec2Bin         ;First convert dec str to its binary value
            LDA    IBuff,Y
            CMP    #'='
            BNE    L09D8           ;Input err
            INY
            INY
            LDA    #'$'
            STA    (ScrLoc),Y
            INY
            BIT    Z40
            BPL    DspHexS         ;+ve dec->hex
;
            SEC
            LDA    #0              ;-ve dec->hex
            SBC    Z3E
            STA    Z3E
            LDA    #0
            SBC    Z3E+1
            STA    Z3E+1
;
DspHexS     LDA    Z3E+1           ;Now convert binary value
            JSR    PUTHEX          ; to its hex rep &
            LDA    Z3E
            JSR    PUTHEX          ; show on cmdln SD
;
L0982       JSR    CPY2IB          ;Copy scrn ln to input buffer
            JMP    BOCL
;
ParseCmd    LDA    #>SLIN23
            STA    ScrLoc
            LDA    #<SLIN23
            STA    ScrLoc+1
;
            LDY    #0              ;Get 1st char of
            LDA    IBuff,Y         ; user's input
            CMP    #'+'
            BEQ    PlusDecS
            CMP    #'-'
            BEQ    NegDecS         ;DecS -> Bin value -> HexS
            CMP    #'$'
            BNE    L09A2
            INY                    ;Skip over $
;
L09A2       JSR    Hex2Bin         ;Do we have a hexdec str?
            BCS    InputErr        ;No
            LDA    IBuff,Y
            CMP    #'='
            BEQ    EqSign          ;HexS -> DecS
;
            CMP    #':'            ;Addr:
            BEQ    L0A16           ;Mem Page Display or assignment
;
            BIT    MemPgDSW
            BMI    InputErr
            JSR    ToUpper
;
; Debugging modes viz TRACE, SINGLE STEP, EXECUTE
; AddrT, AddrS, AddrG, AddrJ
;
            CMP    #'T'
            BNE    L09C1
            JMP    TKEY1
;
L09C1       CMP    #'S'
            BNE    L09C8
            JMP    SKEY1
;
L09C8       CMP    #'G'
            BNE    L09CF
            JMP    GKEY1
;
L09CF       CMP    #'J'
            BNE    L09D6
            JMP    JKEY1
; AddrL
L09D6       CMP    #'L'            ;DisAssembly
L09D8       BNE    InputErr
            JMP    LKEY1
;
InputErr    JSR    BELL2
            JMP    BOCL
;=================================================
; Parse the cmd line for keywords
; Ret Z=1 no hit, Z=0 hit
;
HndlCmd     LDX    #$00
            LDA    CMDTBLP
            STA    Z40PTR          ;points @ table of COMMAND keywords
            LDA    CMDTBLP+1
            STA    Z40PTR+1
;
L09EF       LDY    #0
            LDA    (Z40PTR),Y      ;Get entry len
            BEQ    L0A15           ;end of table
            STA    Z42
L09F7       INY
            CPY    Z42
            BEQ    L0A14           ;got a hit
            LDA    IBuff-1,Y
            JSR    ToUpper
            CMP    (Z40PTR),Y
            BEQ    L09F7           ;keep searching
;
            INX                    ;cmd # (to be used later as an index)
            CLC
            LDA    Z40             ;bump to next entry
            ADC    Z42
            STA    Z40
            BCC    L09EF
            INC    Z41
            BCS    L09EF           ;always
L0A14       DEY                    ;Z=0 to flag a hit
L0A15       RTS
;
; An assignment or memory page display
;
L0A16       INY
            STY    ALTYSV
            CPY    INPUTLEN
            BEQ    L0A8F           ;-> display mem page
;
; Altering mem contents
;
            JSR    SVMONPC
            LDA    Z3E
            STA    MONPC
            STA    IMM1+1
            LDA    Z3E+1
            STA    MONPC+1
            STA    IMM1+2
;
            JSR    DoAsm           ;Try to assemble inst
            JSR    RSTMONPC
            LDY    ALTYSV
            DEY
L0A3A       INY
L0A3B       CPY    INPUTLEN        ;End of input?
            BEQ    L0AB8           ;Yes, chk if a mem page display is needed
;
            LDA    IBuff,Y
            CMP    #SPACE
            BEQ    L0A3A           ;Skip blanks
;
; Memory cell assignment. Altering the contents of mem
; Including 6502 instr & operands
;
            CMP    #'"'
            BEQ    L0A5C
            CMP    #'''
            BEQ    L0A60           ;-> string assignment
;
            JSR    Hex2Bin
            BCS    InputErr
            LDA    Z3E
            JSR    L0AC3           ;Assign to mem
            JMP    L0A3B           ;Loop back for more
;
; String assignment
;
L0A5C       LDA    #$00
            BEQ    L0A62           ;always
L0A60       LDA    #$80
L0A62       STA    HIGHB           ;string type
L0A65       INY
            CPY    INPUTLEN
            BEQ    L0AB8
            LDA    IBuff,Y
            CMP    #'/'            ;Accepts next char verbatim
            BNE    L0A7E
            INY
            CPY    INPUTLEN
            BEQ    L0AB8
            LDA    IBuff,Y         ;Get ASCII char
            JMP    L0A86
;
L0A7E       CMP    #'"'            ;Check for closing quotes
            BEQ    L0A3A
            CMP    #'''
            BEQ    L0A3A
;
L0A86       EOR    HIGHB
            JSR    L0AC3           ;Assign to mem
            JMP    L0A65           ;Next char
;
; Do a mem page display
;
L0A8F       LDA    Z3E             ;Starting addr
            STA    MBStrtAdr
            LDA    Z3E+1
            STA    MBStrtAdr+1
            BIT    MemPgDSW
            BMI    L0AA1
            JSR    ClrScrn         ;Blank entire scrn if necessary
;
L0AA1       JSR    L1D23           ;Display mem page
            LDA    #$80
            STA    MemPgDSW
            LDA    IMM9+1
            STA    IMM1+1
            LDA    IMM9+2
            STA    IMM1+2
            JMP    L0922
;
L0AB8       BIT    MemPgDSW
            BPL    L0AC0
            JSR    L1D23
;
L0AC0       JMP    L0922
;=================================================
; Change contents of mem cell
;
L0AC3       PHA
            STY    ALTYSV
            JSR    SwapZP
            PLA
IMM1        STA    $FFFF           ;curr Mem loc
            JSR    SwapZP
            LDY    ALTYSV
            INC    IMM1+1
            BNE    L0ADC
            INC    IMM1+2
L0ADC       RTS
;=================================================
; Update BB SDs
;
L0ADD       BIT    MasDSW
            BPL    L0ADC
            BIT    MemPgDSW
            BMI    L0ADC
;
            JSR    DBBREGS         ;Show (regs)
            JSR    DMONPC          ;Show PC
            JSR    DREGS
            JSR    L14C3           ;Show Stack SD
            JSR    L151A           ;Show MC SD
            JMP    L1719           ;Show BP SD
;=================================================
; ($0AF9) BB Command Level
;
BBGetLn     JSR    CLRIB
            LDY    #1
            STY    Z40
            LDX    #$00
            STX    Z41
            STX    Z42
            STX    INSFLAG
            BEQ    L0B36           ;always
;
; This rtn allows user to type up to 128 chars using the
; 39-char CmdLn SD. We may think of this SD as a 39-char
; wide window into the IBuff which can store up to 128 chars
;
; (Z40) - cursor posn within cmdln SD (1-39)
; (Z41) - IBuff index of char at cursor posn
; (Z42) - IBuff index of char at posn 1 of cmdln SD
;         Posn 0 of SD is the colon prompt
;
DelLin      JSR    CLRIB
BOCL        LDX    #0
            STX    Z42
            LDY    #1
CMDCLP      CLC
InsChar     ROR    INSFLAG         ;bit7=0 => overwrite mode
L0B18       STY    Z40             ;cursor posn
            STX    Z41             ;index of char under cursor
;
            LDY    #1              ;Skip past colon
            LDX    Z42             ;Start refresh of cmdln SD fr here
L0B20       LDA    IBuff,X
            CMP    #SPACE
            BCS    L0B29
            AND    #$3F            ;Convert to inverse char (00-3F)
L0B29       STA    SLIN23,Y
            INX
            INY
            CPY    #40             ;Only 1-39 chars are displayed
            BNE    L0B20           ;next char
;
            LDY    Z40             ;curr cursor posn
            LDX    Z41             ;index into IBuff
L0B36       LDA    SLIN23,Y
            AND    #$3F            ;$00-$3F
            ORA    #$40            ;$40-$7F
            STA    SLIN23,Y        ;Flash the char
            LDA    #':'            ;Put a colon in front
            STA    SLIN23          ; of cmdln SD
;
WAITK1      LDA    KBD
            BPL    WAITK1
;
            STA    KBDSTROBE
            CMP    #CTRLX
            BEQ    DelLin          ;Clear every thing and re-start input
            CMP    #CTRLB
            BEQ    BOCL
            CMP    #TAB
            BEQ    InsChar         ;Proceed to set INSERT flag (NB. C=1)
            CMP    #ESC
            BNE    L0B6C
            CPX    #0              ;Was it the 1st char?
            BNE    BOCL            ;No, move cursor to BO input line
;
            LSR    MemPgDSW        ;msb=0
            BIT    MemPgDSW        ;Was MEM PAGE SD displayed?
            BVC    L0B36           ;No, get 1st char (Y=1, X=0)
            JMP    L091F
;
L0B6C       CMP    #SPACE          ;Was space bar pressed?
            BNE    L0B77
            CPX    #0              ;Was 1st char a space?
            BNE    L0B77           ;char is a space but it's not 1st char
            JMP    DNxtMem         ;Yes
;
L0B77       CMP    #CURSL          ;BS key
            BEQ    ML1CH
            CMP    #DELCH          ;Delete key
            BEQ    ML1CH
;
            CMP    #CURSR          ;FS
            BEQ    MR1CH
            CMP    #CTRLD
            BEQ    DELCHR
            CMP    #CTRLC
            BEQ    ASISST
            CMP    #CTRLN
            BEQ    EOCL
            CMP    #CR
            BEQ    L0BFA           ;Accept input
;
            CMP    #SPACE          ;If ctrl-char,
            BCC    L0B36           ; ignore input char
            BIT    INSFLAG         ;Insert mode?
            BPL    Add2IB          ;No, Overwrite mode
            JSR    MVCHARS         ;Move chars forward
;
Add2IB      STA    IBuff,X         ;Replace old char w/new one
L0BA2       CPX    #127            ;maxlen?
            BNE    L0BAC
            JSR    BELL2           ;Too many chars
            JMP    CMDCLP
;
L0BAC       INX
            CPY    #39             ;Is it at the edge of SD?
            BNE    L0BB4           ;No, proceed to incr (Y)
            INC    Z42
            DB     $24             ;Y=39 on fall thru
L0BB4       INY
            JMP    L0B18
;
MR1CH       CLC
            ROR    INSFLAG         ;Set overwrite mode
            BPL    L0BA2           ;always
;
ML1CH       DEX
            BPL    L0BC4
            JMP    BOCL            ;(X) was 0
L0BC4       CPY    #1              ;Is cursor @ BO SD?
            BNE    L0BCB           ;No, just decr (Y)
            DEC    Z42             ;Yes
            DB     $24             ;NB. On fall thru (Y) = 1
L0BCB       DEY
            JMP    CMDCLP
;
; Enter next key verbatim
;
ASISST      LDA    #$20            ;ASCII space
            STA    SLIN23,Y
WAITK2      LDA    KBD
            BPL    WAITK2
            STA    KBDSTROBE       ;Clear key latch
            STA    IBuff,X         ;Store key as it is
            BMI    MR1CH           ;always
;
DELCHR      STX    Z40             ;Save temporarily
L0BE3       CPX    #127            ;maxlen
            BEQ    L0BF0
            LDA    IBuff+1,X       ;Shift chars left
            STA    IBuff,X         ; within input buffer
            INX
            BNE    L0BE3           ;Always since (X) < 128
L0BF0       LDA    #SPACE          ;Replace with space
            STA    IBuff,X
            LDX    Z40             ;Restore
            JMP    CMDCLP
;
; CR - Accept user input
;
L0BFA       LDA    #SPACE
            STX    INPUTLEN
L0BFF       STA    SLIN23,Y        ;Clear rest of scrn line
            INY
            CPY    #40
            BNE    L0BFF
;
            JSR    ClrIBZ          ;Clear rest of buffer
            JMP    XCmd
;
EOCL        LDX    #127
L0C0F       LDA    IBuff,X         ;Trailing spaces
            CMP    #SPACE
            BNE    L0C19
            DEX
            BPL    L0C0F
L0C19       INX
            BPL    L0C1D
            DEX                    ;(X) was 128, so set to 127
;
L0C1D       TXA
            TAY                    ;(Y)=(X)
            LDA    #0
            CPX    #39
            BCC    L0C2A
;
            TXA
            LDY    #38             ;Y becomes 39 on looping back
            SBC    #38
;
L0C2A       STA    Z42             ;index of char @ posn 1 of SD
            INY
            JMP    CMDCLP
;=================================================
; ($0C30) Fill the input buffer with 128 blanks
;
CLRIB       LDX    #0
            LDA    #SPACE
ClrIBZ      STA    IBuff,X
            INX
            BPL    ClrIBZ
            RTS
;=================================================
; Move chars forward in IBuff to make space
; for char to be inserted
;
MVCHARS     PHA                    ;save char to be inserted
            STX    Z40             ;curr index
            LDX    #127
L0C40       CPX    Z40             ;finish?
            BEQ    L0C4D           ;done
            LDA    IBuff-1,X
            STA    IBuff,X
            DEX
            BPL    L0C40
L0C4D       PLA
            LDX    Z40
            RTS
;=================================================
; ($0C51) Display next mem location on cmdln SD
;
DNxtMem     LDA    #>SLIN23
            STA    STOSCR+1
            LDA    #<SLIN23
            STA    STOSCR+2
            LDA    IMM1+2
            JSR    STOHEX
            LDA    IMM1+1
            JSR    STOHEX
;
            LDA    #':'
            STA    SLIN23,Y
            JSR    CPY2IB
            LDY    #6              ;scrn offset into cmdln SD
            LDX    #5              ;Index into IBuff
            JMP    L0B36
;=================================================
; ($0C76) Convert a hex str into its binary value
; Return result in ($3E,$3F)
;
Hex2Bin     LDA    #$00
            STA    Z3E             ;result
            STA    Z3E+1
            STY    Z43
L0C7E       LDA    IBuff,Y
            JSR    Add2Bin
            BCS    L0C8C           ;char is not a hex digit
            INY
            CPY    INPUTLEN
            BNE    L0C7E           ;convert next char
L0C8C       CPY    Z43
            BNE    L0CB1           ;--> C=0
            RTS
;=================================================
; ($0C91) Convert a ASCII hex digit into its binary
; value & combine it into with the partial result
; ($3E,$3F) - partial result
; C=1 - (A) is not an ASC hex char
; (A) & (X) - changed
;
Add2Bin     EOR    #'0'            ;Change numeric char into its binary value
            CMP    #10
            BCC    L0C9F           ;Was ASCII '0'-'9';now $00-$09
            ADC    #$88            ;Adjust
            ORA    #$20
            CMP    #$FA            ;$FA-$FF (ASCII 'A'-'F')
            BCC    L0CB3           ;On fall thru (A)=$0A-$0F
;
L0C9F       AND    #$0F            ;Mask off upper nybble
            STA    Z44             ;$00-$0F
            LDX    #4
            LDA    Z3E             ;Shift to accommodate
L0CA7       ASL                    ; the incoming value
            ROL    Z3E+1
            DEX
            BNE    L0CA7
            ORA    Z44             ;Combine it
            STA    Z3E
L0CB1       CLC
            DB     $24
L0CB3       SEC                    ;Invalid numeral
            RTS
;=================================================
; ($0CB5) Display the topmost line of column 
; and the break point headers
;
DRegHdr     BIT    MasDSW
            BPL    L0CE8
            JSR    ClrScrn         ;Clear entire screen if necessary
            LDX    #'C'            ;cycle
            STX    SLIN00
            DEX
            STX    SLIN00+8        ;"B" - break point reg
            LDA    #'R'            ;rate
            STA    SLIN00+5
;
L0CCB       LDX    L2105           ;Set (ScrLoc)
            JSR    VTABX
;
            LDY    #39
L0CD3       LDA    REGSK-11,Y
            STA    SLIN00,Y
            LDA    BPHDR-11,Y      ;BP header
            STA    (ScrLoc),Y
            DEY
            CPY    #10
            BNE    L0CD3
;
            LDA    #$00
            STA    MemPgDSW
L0CE8       RTS