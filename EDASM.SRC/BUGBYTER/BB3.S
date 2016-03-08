Name          : BB3.S
End of file   :   34,069
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;=================================================
; ($16BA) Convert a binary value to to its
; decimal value & show it on screen
; The binary value is first converted into its BCD
; equivalent then a DEC to hex string converter
; is called
; NB. Only ADC and SBC inst are affected by a SED
;
Bin2Dec     LDA    #0
            STA    Z40             ;Zero result
            STA    Z40+1
;
            SED                    ;Set 6502 dec mode
            STY    Z43             ;Save Y-reg
            LDY    #16             ;Loop cnt
L16C5       ASL    Z3E
            ROL    Z3E+1
            LDA    Z40             ;Add in the C
            ADC    Z40
            STA    Z40
            LDA    Z40+1
            ADC    Z40+1
            STA    Z40+1
            ROL    Z40+2
            DEY
            BNE    L16C5
;
            CLD                    ;Back to binary mode
            LDY    Z43             ;Restore Y
            LDA    Z40+2           ;Output as 5-char string
            JSR    PUTNYB
            LDA    Z40+1
            JSR    PUTHEX
            LDA    Z40
            JMP    PUTHEX
;=================================================
; Display contents of BB's regs C, R and B
;
DBBREGS     LDA    #>SLIN01
            STA    STOSCR+1
            LDA    #<SLIN01
            STA    STOSCR+2
;
            LDY    #0
            LDA    CYCLEC+1
            JSR    STOHEX
            LDA    CYCLEC
            JSR    STOHEX
;
            INY
            LDA    RATEC
            JSR    STOHEX
            INY
            LDA    #'O'
            BIT    BRKFLAG         ;IN?
            BPL    L1715
            LDA    #'I'            ;yes
;
L1715       STA    SLIN01+8
L1718       RTS
;=================================================
; Show contents of BP Table
;
L1719       BIT    MasDSW          ;Update Master Display?
            BPL    L1718           ;No
;
            LDX    NumBPM1
L1721       JSR    L173A           ;Show BP's data
            BIT    BPDSW
            BPL    L1736
            CPX    BPHitM1         ;curr BP
            BNE    L1736
            LDA    #10
            STA    L2112           ;WndLft
            JSR    InvLine
L1736       DEX
            BPL    L1721
            RTS
;=================================================
; Show BP data on screen
; (X) index into BP data tables
;
L173A       SEC
            STX    Z40
            TXA                    ;Compute the vert tab
            ADC    L2105           ;wndtop BP SD
            TAX
            JSR    VTABX           ;Set up (SrcLoc)
            LDY    #11
            LDX    Z40
            JSR    L16AA           ;Show line #
;
; Show BP addr
;
            LDY    #15
            LDA    BPAdrH,X
            JSR    PUTHEX
            LDA    BPAdrL,X
            JSR    PUTHEX
;
; Show BP cnt
;
            LDY    #21
            LDA    BPCntH,X
            JSR    PUTHEX
            LDA    BPCntL,X
            JSR    PUTHEX
;
            LDY    #27
            LDA    BPTrigH,X
            JSR    PUTHEX
            LDA    BPTrigL,X
            JSR    PUTHEX
;
            LDY    #33
            LDA    BPBrkH,X        ;# of times this BP
            JSR    PUTHEX
            LDA    BPBrkL,X        ; was triggered
            JMP    PUTHEX
;=================================================
; Clear a BP or ALL BP's
;
CLRBPCMD    BIT    BRKFLAG         ;IN?
            BMI    L17AD           ;Yes, BP modification has been disabled
            CPY    INPUTLEN
            BEQ    L17B0           ;Clear ALL BP's
;
            JSR    Dec2Bin         ;DecS -> bin val
            BCS    L17AD           ;Not valid
            LDX    Z3E             ;Valid values 1-16
            BEQ    L17AD
            CPX    #17             ;Max # of BPs=16
            BCS    L17AD
;
            DEX                    ;Range: 0-15
            JSR    L17BE           ;Clear this BP's data record
;
L179F       ASL    BPDSW           ;Clear flag
            BIT    MasDSW
            BPL    L17AA
            JSR    L180F           ;Clear BP SD
L17AA       JMP    L0922           ;Update SDs & get next cmd
;
L17AD       JMP    InputErr
;
L17B0       JSR    L17B5           ;Clear all BP records
            BMI    L179F           ;always
;=================================================
; Zero all BP records
; Ret
; (A)=0, (X)=$FF
;
L17B5       LDX    #15
L17B7       JSR    L17BE           ;Zero one record
            DEX
            BPL    L17B7
            RTS
;=================================================
; Init a BP record
; Entry
;  (X)=rec # (0-15)
; Ret
; (A)=0
;
L17BE       LDA    #0
            STA    BPSetT,X
            STA    BPAdrL,X
            STA    BPAdrH,X
            STA    BPCntL,X
            STA    BPCntH,X
            STA    BPTrigL,X
            STA    BPTrigH,X
            STA    BPBrkL,X
            STA    BPBrkH,X
            RTS
;=================================================
; BP handler
;
BRKHNDLR    SEI
            SEC
            LDA    MONPC
            SBC    #2
            STA    MONPC
            BCS    L17E8
            DEC    MONPC+1
;
L17E8       CLC
            LDA    HSTAKP
            ADC    #4
            STA    HSTAKP
;
            LDX    #>BBStack       ;Use BB's stack area
            TXS
            JSR    L18B4           ;Is it on our list of BP's
            BMI    L1800           ;No
;
            JSR    L0ADD           ;Update all SDs
            LDX    BPHitM1
            JMP    L0E59           ;Let BB's SS rtn handle break
L1800       JMP    (SVBRKV)        ;Let the original BRK handler take care of it
;=================================================
; ($1803) Clear Disassembly/Code SD
;
L1803       LDX    L2108           ;wndbtm of CD SD
            LDA    #3
            STA    L2114           ;wndtop
            LDA    #10
            BNE    L1825           ;Proceed to set wndlft
;
; ($180F) Clear BP SD
;
L180F       LDY    L2105           ;wndtop of BP SD
            INY
            STY    L2114           ;WndTop
            LDX    #21             ;WndBtm
            LDA    #10
            BNE    L1825           ;Always
;
; ($181C) Blank entire screen
;
ClrScrn     LDY    #0
ClrEOS      STY    L2114           ;WndTop
            LDX    #23             ;WndBtm
            LDA    #0
L1825       STA    L2112           ;WndLft
            LDA    #39
            STA    L2113           ;WndRht (ending col)
            BIT    MasDSW
            BMI    L1833
            RTS
;
L1833       JSR    VTABX
            JSR    ClrEOL
            DEX
            CPX    L2114
            BPL    L1833           ;next line
            RTS
;=================================================
ScrollUp    LDA    L2108           ;wndbtm of CD SD
            STA    L2115           ;WndBtm
            LDA    #10             ;WndLft
            STA    L2112
            LDA    #39
            STA    L2113           ;WndRht
;
ScrolUpZ    LDX    #<SLIN03        ;(X)=5
            STX    Z43PTR+1
            STX    ScrollSW        ;clear msb
            DEX                    ;NB.(X)=4
            LDA    #>SLIN03
            STA    Z43PTR
            BNE    L1873           ;always
;
ScrolDwn    SEC
            ROR    ScrollSW
            LDX    L2115
            JSR    VTABX           ;Set (ScrLoc) to point to last line of SD
            BNE    L1885           ;always
;
L186A       INX
L186B       LDA    ScrLoc
            STA    Z43PTR
            LDA    ScrLoc+1
            STA    Z43PTR+1
L1873       JSR    VTABX           ;Set (ScrLoc)
;
            LDY    L2113           ;WndRht
L1879       LDA    (ScrLoc),Y
IMM12       ORA    #$80            ;Set (IMM12+1) to appropriate byte
            STA    (Z43PTR),Y
            DEY
            CPY    L2112           ;WndLft
            BPL    L1879
;
L1885       BIT    ScrollSW        ;Up or down?
            BMI    L1891           ;Down
            CPX    L2115
            BCC    L186A           ;Next line
            BCS    ClrEOL          ;Always
;
L1891       DEX
            CPX    #3
            BPL    L186B
;
; Clear line
; Left and Right edges as well as (SrcLoc) must be set
; (A)=char used to blank the line-$A0/$20
;
ClrEOL      LDA    #SPACE
ClrEOLI     LDY    L2113           ;WndRht
L189B       STA    (ScrLoc),Y
            DEY
            CPY    L2112           ;WndLft
            BPL    L189B
            RTS
;=================================================
; Inverse a line
;
InvLine     LDY    L2113           ;WndRht
L18A7       LDA    (ScrLoc),Y
            AND    #$3F
            STA    (ScrLoc),Y
            DEY
            CPY    L2112           ;WndLft
            BPL    L18A7
            RTS
;=================================================
; Chk if there is a hit
; (X)-$FF -  no hit
;  otherwise (X) index into BP addr
;
L18B4       LDX    NumBPM1
L18B7       LDA    BPSetT,X
            BPL    L18CA
            LDA    MONPC
            CMP    BPAdrL,X
            BNE    L18CA
            LDA    MONPC+1
            CMP    BPAdrH,X
            BEQ    L18CE           ;Got a hit
L18CA       DEX
            BPL    L18B7
            RTS                    ;X=-1 if ret from here
L18CE       STX    BPHitM1         ;currBP
            RTS
;=================================================
; ($18D2)
; Set real BP's
;
INCMD       BIT    BRKFLAG         ;Already IN?
            BPL    L18DA           ;No
            JMP    InputErr
;
L18DA       JSR    SVMONPC
            LDX    NumBPM1
L18E0       STX    Z40
            LDA    BPSetT,X
            BPL    L1918           ;Disabled
;
            LDA    BPAdrL,X        ;BP addr
            STA    MONPC
            LDA    BPAdrH,X
            STA    MONPC+1
            JSR    INSDIS          ;Get addr mode format and len
            LDA    Z40             ;Make into an index
            ASL
            ASL
            TAX
;
            LDY    #0
L18FB       LDA    INSTSV,Y        ;NB. Addr mode format byte is also saved
            STA    L088F,X
            INX
            INY
            CPY    #4
            BNE    L18FB
;
; Patch location with a BRK + $EA's
; 1-byte opcodes -> BRK
; 2-byte opcodes -> BRK NOP
; 3-byte opcodes -> BRK NOP NOP
;
            LDY    INSTLEN         ;Len of instr
L190A       BNE    L190F
            TYA                    ;Y=A=0 -> BRK opcode will be patched
            BPL    L1911
L190F       LDA    #iNOP
L1911       STA    (MONPC),Y
            DEY
            BPL    L190A
;
            LDX    Z40
L1918       DEX
            BPL    L18E0           ;Next BP
;
            STX    BRKFLAG         ;=$FF, disable BP modification
L191E       JSR    RSTMONPC
            JMP    L0922           ;Update SDs & get next cmd
;=================================================
; ($1924)
;
OUTCMD      BIT    BRKFLAG         ;IN?
            BMI    L192C           ;Yes
            JMP    InputErr
;
L192C       JSR    SVMONPC
            LDX    NumBPM1
L1932       STX    Z40
            LDA    BPSetT,X
            BPL    L1968           ;Not enabled
;
            LDA    BPAdrL,X
            STA    MONPC
            LDA    BPAdrH,X
            STA    MONPC+1
            TXA
            ASL
            ASL                    ;index;4
            STA    Z41
            ADC    #3
            TAX
            LDA    L088F,X         ;Get addr mode format byte
            AND    #%00000011      ;Isolate len
            STA    INSTLEN
            INC    INSTLEN         ;0-1 byte,1-2 bytes,2-3 bytes
;
            LDY    #0
            LDX    Z41             ;Restore original inst
L195A       LDA    L088F,X
            STA    (MONPC),Y       ; @ location which was
            INX                    ; set as a real BP
            INY
            CPY    INSTLEN
            BNE    L195A
;
            LDX    Z40
L1968       DEX
            BPL    L1932
            INX                    ;=0
            STX    BRKFLAG         ;Enable BP modification
            JMP    L191E
;=================================================
; Set Break Points
; Each BP consists of 4 pieces of data viz
; Addr, Count, Trigger and Broke values
;
SETBPCMD    BIT    BRKFLAG         ;Is BP modification allowed?
            BPL    L197A           ;Yes
L1977       JMP    InputErr
;
L197A       JSR    Dec2Bin
            BCS    L1977
            BIT    MasDSW
            BPL    L1977
;
            LDX    Z3E             ;BP#=1-16
            DEX
            BMI    L1977
            CPX    #16
            BCS    L1977
            CPX    NumBPM1
            BEQ    L1994
            BCS    L1977
;
; Edit BP data rec
;
L1994       STX    BPHitM1         ;# of BPs - 1
            ASL    BPDSW           ;clear msb
            JSR    L180F           ;Clear BP SD
            JSR    L1719
            LDX    BPHitM1         ;currBP
            SEC
            TXA
            ADC    L2105           ;wndtop BP SD
            TAX
            JSR    VTABX           ;Set (SrcLoc)
;
            LDX    #0              ;Start w/col # 1 which is Addr
L19AE       LDA    BPTabsT,X       ;Get scrn col offset for this col
            TAY
            LDA    #0
            STA    Z41
            STA    Z3E             ;Numeric val of col
            STA    Z3E+1
L19BA       LDA    (ScrLoc),Y      ;Get screen char
            AND    #$3F            ;Convert to a flashing
            ORA    #$40
            STA    (ScrLoc),Y      ; char on the screen
;
WAITK6      LDA    KBD
            BPL    WAITK6
            STA    KBDSTROBE
            CMP    #ESC
            BEQ    L1A3A
            CMP    #CR
            BEQ    L1A3A           ;Done editing data for this BP
;
            CMP    #CURSL
            BEQ    MOVEL
            CMP    #CURSR
            BEQ    MOVER
            CMP    #SPACE
            BEQ    MOVER
;
            JSR    ToUpper
            STA    Z40             ;char
            STX    Z42             ;Save col #
            JSR    Add2Bin         ;Accmulate bin value
            BCS    WAITK6          ;Ignore, not a hex digit
;
            LDX    Z42             ;Restore col #
            JSR    L1A45           ;Blank entry if reqd
            INC    Z41             ;# of chars typed for curr entry so far
            LDA    Z40             ;Get typed char
            STA    (ScrLoc),Y
            INY
            TXA                    ;Form an index with col #
            ASL                    ;Each table is 32 bytes in size
            ASL
            ASL
            ASL
            ASL
;
            CLC
            ADC    BPHitM1         ;BP#-1
            TAX
            LDA    Z3E             ;16-bit value
            STA    BPAdrL,X
            TXA
            CLC
            ADC    #16
            TAX
            LDA    Z3E+1
            STA    BPAdrL,X
;
            LDX    Z42             ;col #
            LDA    Z41             ;char cnt
            CMP    #4              ;Have user typed 4 chars?
            BNE    L19BA           ;No, next char
;
; On fall thru, we're done editing the current col since
; a 4-char hexdec str had been typed
;
MOVER       CPX    #3              ;Was the 4-th col just edited?
            BEQ    L1A29           ;Yes
            INX                    ;Move cursor to col on right
            BNE    L1A29           ;always
;
MOVEL       TXA                    ;Is it 1st col?
            BEQ    L1A29           ;Yes
            TYA
            CMP    BPTabsT,X       ;Is cursor on 1st char of col being edited?
            BNE    L1A29           ;No
            DEX                    ;Prepare to edit col on the left
;
L1A29       LDA    (ScrLoc),Y      ;Get char under cursor
            BMI    L19AE           ;Normal
            CMP    #$60
            BCC    L1A33
            EOR    #$40
L1A33       ORA    #$80
            STA    (ScrLoc),Y
            JMP    L19AE
;
L1A3A       LDX    BPHitM1         ;currBP
            LDA    #$80            ;Flag BP has been set
            STA    BPSetT,X
            JMP    L0922           ;Update SDs & get next cmd
;=================================================
; (X)-offset to BP Tabs tables
; (Y)-bo scrn line
; Ret
;  (Z41)=0 if it was non-zero
;
L1A45       LDA    Z41             ;1st char entered?
            BNE    L1A59           ;No
            LDA    #4
            STA    Z41             ;Blank col
            LDA    #SPACE
L1A4F       STA    (ScrLoc),Y
            INY
            DEC    Z41
            BNE    L1A4F
            LDY    BPTabsT,X       ;Get cursor's posn
L1A59       RTS
;=================================================
; Convert ASCII rep of a dec string to its binary value
; Ret
;  ($3E,$3F)-16-bit binary value
;
Dec2Bin     LDA    #$00
            STA    Z3E
            STA    Z3E+1
L1A60       LDA    IBuff,Y         ;Get a char
            CMP    #'0'            ;Is it $B0-$B9? (hi-bit ASCII 0-9)
            BCC    NOTNUM
            CMP    #'9'+1
            BCS    NOTNUM          ;No
            AND    #$0F            ;(A)=0-9
            STA    Z44             ;Save incoming digit
            LDA    Z3E+1
            STA    Z43             ;Save HOB temporarily
            LDA    Z3E             ;First x4
            ASL
            ROL    Z3E+1
            ASL
            ROL    Z3E+1
            CLC                    ; then +1
            ADC    Z3E
            PHA                    ;Save intermediate result on stack
            LDA    Z3E+1
            ADC    Z43             ;Add in HOB
            STA    Z3E+1
;
            PLA                    ;Finally x2
            ASL
            ROL    Z3E+1
            CLC                    ;Now add in the incoming digit
            ADC    Z44
            STA    Z3E
            BCC    L1A92
            INC    Z3E+1
;
L1A92       INY
            CPY    INPUTLEN
            BNE    L1A60           ;Next char
            CLC
            RTS
NOTNUM      SEC
            RTS
;=================================================
; Change (Mem Cells)
;
MEMCMD      LDX    #0
L1A9E       TXA
            CLC
            ADC    L2103           ;vtab
            TAY
            LDA    SLATLO,Y
            STA    ScrLoc
            LDA    SLATHI,Y
            STA    ScrLoc+1
;
L1AAE       LDY    #0
            STY    ALTYSV
            STY    Z3E
            STY    Z3E+1
L1AB7       LDA    (ScrLoc),Y      ;Flashing
            AND    #$3F
            ORA    #$40
            STA    (ScrLoc),Y
WAITK7      LDA    KBD
            BPL    WAITK7
            STA    KBDSTROBE
;
            CMP    #CURSL
            BEQ    L1B2D
            CMP    #DELCH
            BEQ    L1B2D
;
            CMP    #ESC
            BEQ    L1B48           ;exit
;
            CMP    #CURSR
            BEQ    L1B3A
            CMP    #SPACE
            BEQ    L1B3A
            CMP    #CR
            BEQ    L1B3A           ;Accept
;
            CPY    #0
            BNE    L1AF9
;
            JSR    ToUpper
            CMP    #'P'            ;pointer
            BEQ    L1AF0
            CMP    #'H'            ;hex
            BNE    L1AF9
;
            LDA    #0
L1AF0       STA    MCType,X
            JSR    L1B4B
            JMP    L1AAE
;
L1AF9       STA    HIGHB           ;Char
            STX    Z40
            JSR    Add2Bin         ;Accumulate result
            LDX    Z40
            BCS    L1AB7           ;Not a hex digit
            LDA    ALTYSV          ;Is it 1st char?
            BNE    L1B14
;
            LDY    #3              ;Yes, blank entry
            LDA    #SPACE
L1B0E       STA    (ScrLoc),Y
            DEY
            BPL    L1B0E
;
            INY                    ;Y=0
L1B14       LDA    HIGHB           ;char
            STA    (ScrLoc),Y
            INY
            INC    ALTYSV
            LDA    Z3E             ;Save partial result
            STA    MCAdrL,X
            LDA    Z3E+1
            STA    MCAdrH,X
            CPY    #4
            BNE    L1AB7           ;Get next char
            BEQ    L1B3A           ;done
;
L1B2D       CPY    #0              ;BS or DEL key
            BNE    L1B32           ;Not 1st char
            DEX
L1B32       TXA
            BPL    L1B38
            LDX    NumMCM1         ;Wraparound to last cell
L1B38       BPL    L1B42
;
L1B3A       CPX    NumMCM1
            BCC    L1B41
            LDX    #-1             ;Wraparound to 1st cell
L1B41       INX
L1B42       JSR    L1B4B           ;Update MC SD
            JMP    L1A9E           ;Continue editing
;
L1B48       JMP    L0922           ;Update SDs & get next cmd
;
; Update MEM SD
;
L1B4B       STX    Z40
            JSR    L151A           ;Display MEM SD
            LDX    Z40
            RTS
;=================================================
; ($1B53) Customise Master Display
;
SETCMD      EQU    *
;
; Set the relative sizes of the CD and BP SD's
;
            LDY    #3
            JSR    ClrEOS          ;Clear all SD's
            JSR    L0CCB           ;Show Reg & BP Headers
            JSR    SVMONPC
            ASL    IMM12+1         ;clear msb
            LDA    #1
            STA    ALTYSV
            LDA    #11             ;left edge of CD & BP SD's
            STA    L2112           ;WndLft
            LDA    #38
            STA    L2113           ;WndRht
            LDA    #21
            STA    L2115           ;WndBtm?
;
            LDA    L2106           ;Get sentinel val
            STA    MONPC
            LDX    L2108           ;wndbtm of CD SD
            STX    MONPC+1
;
            LDA    NumBPM1
            STA    Z3E
            LDA    L2105           ;wndtop BP SD
            STA    Z3E+1
            LDA    #'1'            ;Show 1st numbered line
            JSR    L1C38           ; in inverse
            JSR    L1C4A           ;Fix the sizes of CD & BP SD's
;
            LDA    Z3E
            STA    NumBPM1
            LDA    Z3E+1
            STA    L2105           ;wndtop of BP SD
;
; Set the next-instruction-to-be executed horizontal bar
; in the CD SD. This bar divides the SD among instructions
; that had been executed and those yet to be executed
; First setup the necessary window variables
;
            LDX    MONPC+1
            STX    L2108           ;wndbtm of CD SD
            STX    L2115
            STX    Z3E+1
;
            LDY    #0
            STY    ALTYSV
            DEY
            STY    Z3E             ;=-1
            LDA    #$20            ;ASCII space
            JSR    L1C38           ;Show dividing inverse line (no numbering)
            LDA    MONPC           ;If (A)=-1, CD SD
            STA    L2106
            BMI    L1BBC           ; is only 1 line
            JSR    L1C4A           ;CD SD is at least 2 lines
;
; Adjust the relative sizes of the MemCell and Stack SDs
;
L1BBC       LDA    MONPC+1
            STA    CDBar
            LDA    Z3E
            STA    L2109
;
            LDX    #0
            STX    L2112           ;WndLft
            INX
            STX    ALTYSV          ;=1
            LDA    #8
            STA    L2113           ;WndRht
            LDA    #21
            STA    L2115           ;WndBtm
;
            LDA    L210A           ;StackPBar+2
            STA    MONPC
            LDX    L210B           ;wndbtm of stack SD
            STX    MONPC+1
;
            LDA    NumMCM1
            STA    Z3E
            LDY    L2103           ;wndtop of MC SD
            DEY
            STY    Z3E+1
            LDA    #'1'            ;Show 1st numbered
            JSR    L1C38           ; line in inverse
            JSR    L1C4A           ;Fix the sizes of the MC & Stack SD's
;
            LDA    Z3E
            STA    NumMCM1
            LDY    Z3E+1
            INY
            STY    L2103
;
; Finally set the stack pointer bar
;
            LDX    MONPC+1
            STX    Z3E+1
            STX    L210B           ;wndbtm of stack SD
            STX    L2115
;
            LDY    #0
            STY    ALTYSV
            DEY
            STY    Z3E             ;=-1
            LDA    #$20            ;ASCII space
            JSR    L1C38           ;Show inverse line
            LDA    MONPC           ;if (A)=-1, Stack SD
            STA    L210A
            BMI    L1C22           ; is 1 scrn line
            JSR    L1C4A           ;Stack SD is at least 2 lines tall
;
L1C22       LDY    MONPC
            INY
            STY    L210D           ;# of locations above stackptr
            LDA    MONPC+1
            STA    StackPBar
            LDA    #$80            ;Normal char mask
            STA    IMM12+1         ; @ this location
            JSR    RSTMONPC
            JMP    L091F
;=================================================
; (A) - char to store
; (X)- screen row #
; (L2112) - offset into screen row
;
L1C38       LDY    SLATLO,X
            STY    ScrLoc
            LDY    SLATHI,X
            STY    ScrLoc+1
            LDY    L2112           ;WndLft
            STA    (ScrLoc),Y
            JMP    InvLine
;=================================================
; ($1C4A) This rtn divides a screen area into a
; lower and upper window.
; It is used to adjust the relative sizes of
; 1) CD & BP SD's and
; 2) Stack & MemCell SD's
; It is also used to split the
; 3) CD SD
; 4) Stack SD
; The caller must call this rtn to do 1) and 3) consecutively
; Likewise, 2) and 4) must be done consecutively
;
; Caller have to set up the following variables
; ALTYSV - 0/1 =>  start numbering fr 1/2
; MONPC - Sentinel?
; MONPC+1 - wndbtm of upper window
; Z3E - $FF skip numbering lines of lower window
; Z3E+1 - wndtop of lower window
; L2115 - wndbtm of lower window
; wndtop of upper window is fixed at 3
;
; Show numbered lines in upper window
;
L1C4A       LDA    ALTYSV
            LDX    MONPC+1         ;btm of upper window
            CPX    #3              ; cannot be < its wndtop
            BEQ    L1C5E
L1C53       DEX
            CLC
            ADC    #1              ;(A)=line #
            JSR    L1CC7           ;Show it
            CPX    #3              ;wndtop?
            BNE    L1C53           ;No
;
; Show numbered lines in lower window
;
L1C5E       LDA    Z3E             ;Show numbering of lines?
            BMI    WAITK8          ;No
;
            LDA    #0              ;Starting numbering fr 1
            LDX    Z3E+1           ;top of lower window
L1C66       INX
            CLC
            ADC    #1
            JSR    L1CC7           ;Show line #
            CPX    L2115           ;btm of lower window
            BNE    L1C66
;
WAITK8      LDA    KBD
            BPL    WAITK8
            STA    KBDSTROBE
            CMP    #CURSL
            BEQ    DECSZ
            CMP    #CURSR
            BEQ    INCSZ
            CMP    #CR             ;If cr, accept
            BNE    WAITK8
            RTS
;
; Decrease size of upper window and increase size of lower window
;
DECSZ       LDA    MONPC+1         ;btm of upper window
            CMP    #3              ; cannot be < its wndtop
            BEQ    WAITK8
            DEC    MONPC
            DEC    MONPC+1
            DEC    Z3E+1           ;top of lower window
            INC    Z3E
            JSR    ScrolUpZ
;
            LDX    L2115           ;btm of lower window
            CLC
            LDA    Z3E
            ADC    #1
            JSR    L1CC7           ;Show btm line
            JMP    WAITK8
;
; Increase size of upper window and decrease size of lower window
;
INCSZ       LDX    Z3E
            INX
            CPX    ALTYSV
            BEQ    WAITK8
            INC    MONPC
            INC    MONPC+1
            INC    Z3E+1           ;top of lower window
            DEC    Z3E
            JSR    ScrolDwn
            LDX    #3              ;top of upper window
            SEC                    ;NB: it's not CLC
            LDA    MONPC
            ADC    ALTYSV
            JSR    L1CC7           ;Show topmost line
            JMP    WAITK8
;=================================================
; (X)-vtab of line
; (A)-char
;
L1CC7       TAY                    ;Save A
            JSR    VTABX
            TYA
            LDY    L2112           ;Do a htab &
            JSR    DNbrdLin        ; show numbered line
            RTS
;=================================================
; ($1CD3) Disassemble a few inst
; starting fr specified addr
;
LKEY1       JSR    L1803           ;Clear Code Disasm SD
            LDA    Z3E             ;Start fr this addr
            STA    LastAdr
            LDA    Z3E+1
            STA    LastAdr+1
;
; Disassemble fr last addr
;
DISASMCMD   JSR    SVMONPC
            SEC                    ;Flag there is a pending
            ROR    CodeDSW         ; update for code SD
            LDY    L2106
            INY
            STY    ALTYSV
            LDA    LastAdr
            STA    MONPC
            LDA    LastAdr+1
            STA    MONPC+1
;
L1CF8       JSR    INSDIS          ;decode inst
            JSR    ScrollUp
            JSR    INSTDSP         ;Display inst
            JSR    L12B4           ;Display machine code
            JSR    PCADJ
            STA    MONPC
            STY    MONPC+1
            DEC    ALTYSV
            BPL    L1CF8           ;Next inst
;
            LDA    MONPC           ;Save this for later
            STA    LastAdr
            LDA    MONPC+1
            STA    LastAdr+1
;
            JSR    RSTMONPC
            JSR    L1624           ;Restore
            JMP    XDelLin
;=================================================
; Display contents of 2/3 of a mem page (184 bytes)
;
L1D23       LDA    MBStrtAdr       ;Starting addr
            STA    IMM9+1
            LDA    MBStrtAdr+1     ; of mem block
            STA    IMM9+2
            JSR    SwapZP
;
            LDX    #0
L1D34       STX    ALTYSV          ;cntr
            LDA    SLATLO,X
            STA    STOSCR+1        ;Start of scrn line
            LDA    SLATHI,X
            STA    STOSCR+2
;
            LDY    #0
            LDA    IMM9+2          ;Show "xxxx:"
            JSR    STOHEX
            LDA    IMM9+1
            JSR    STOHEX
            LDA    #':'
            JSR    STOSCR
;
            LDX    #7              ;8/row
IMM9        LDA    $FFFF           ;Get (memory)
            LDY    MPTabs2,X       ;Get offset into scrn line
            JSR    STOSCR          ;Show Apple's char rep
            LDY    MPTabs1,X       ;Get offset into scrn line
            JSR    STOHEX          ;Show its hex rep
            INC    IMM9+1
            BNE    L1D6F
            INC    IMM9+2
L1D6F       DEX
            BPL    IMM9
;
            LDX    ALTYSV
            INX
            CPX    #23
            BNE    L1D34           ;Next row
            JMP    SwapZP
;=================================================
; ($1D7D) Display inst
;
INSTDSP     LDY    #$FC            ;Use this as opcode if addr
            BIT    AdrModSW        ; mode format is not valid
            BPL    L1D87
;
            LDY    INSTSV          ;Get opcode
L1D87       JSR    L1E04           ;Get its index
            STA    Z44             ; in mnemonic table
            LDY    #11             ;Display PC and ':'
            LDA    MONPC+1
            JSR    PUTHEX
            LDA    MONPC
            JSR    PUTHEX
            LDA    #':'
            STA    (ScrLoc),Y
            INY
            INY
;
            LDA    #3              ;Display instruction's mnemonic
            STA    Z43             ;as 3 ASCII chars
            LDX    Z44
L1DA4       LDA    MNEMTBL,X
            STA    (ScrLoc),Y
            INX
            INY
            DEC    Z43
            BNE    L1DA4
;
; Display its operand field
;
            INY
            STY    Z40
            LDY    INSTLEN
            LDX    #$06            ;Count for 6 format bits
PrAdr1      CPX    #$03            ;If X=3, then addr
            BEQ    PrAdr5
PrAdr2      ASL    INSTFMT
            BCC    PrAdr3
            LDA    CHAR1-1,X
            STY    Z41
            LDY    Z40
            STA    (ScrLoc),Y
            INY
            LDA    CHAR2-1,X
            BEQ    L1DD2
            STA    (ScrLoc),Y
            INY
L1DD2       STY    Z40
            LDY    Z41
PrAdr3      DEX
            BNE    PrAdr1
            RTS
;
PrAdr4      DEY
            BMI    PrAdr2
;
            STY    Z41
            LDY    Z40
            JSR    PUTHEX
            STY    Z40
            LDY    Z41
PrAdr5      LDA    INSTFMT
            CMP    #$E8            ;handle relative addressing mode
            LDA    INSTSV,Y
            BCC    PrAdr4          ;special (print target, not offset)
;
            JSR    PCADJ3          ;(A) has displacement
            TAX
            INX
            BNE    PRNTYX
            INY
PRNTYX      TYA                    ;(A,X)=(MonPC)+OFFSET+1
            LDY    Z40
            JSR    PUTHEX
            TXA
            JMP    PUTHEX
;=================================================
; Get index into mnemonic table
; Perform some mapping of inst e.g $6C,$7C -> $4C
; Entry
; (Y)=opcode
; Ret:
;  (A)-index into Mnemonic table
;
L1E04       CPY    #$6C            ;JMP (abs)
            BEQ    L1E0C
            CPY    #$7C            ;JMP (abs,X)
            BNE    L1E0E
L1E0C       LDY    #$4C            ;JMP abs
; $A2 -> $A6
L1E0E       CPY    #$A2            ;LDX #imm
            BNE    L1E14
            LDY    #$A6            ;LDX zp
; $9C,$9E -> $64
L1E14       CPY    #$9C            ;STZ abs
            BEQ    L1E1C
            CPY    #$9E            ;STZ abs,X
            BNE    L1E1E
L1E1C       LDY    #$64            ;STZ zp
; $89 -> $34
L1E1E       CPY    #$89            ;BIT #imm
            BNE    L1E24
            LDY    #$34            ;BIT zp,X
;
L1E24       TYA
            AND    #$0F
            CMP    #$02
            BNE    L1E2E
            DEY                    ;$X2 -> $X1 e.g.
            BNE    L1E24           ; sta (zp) -> sta (zp),Y
;
L1E2E       CMP    #$0A
            BEQ    L1E3A
            AND    #%00000111
            BEQ    L1E43
            CMP    #$04
            BNE    L1E48
;
; $XA,$X4,$XC opcodes
;
L1E3A       LSR
            LSR
            TYA                    ;opcode
            ROR
            SEC
            ROR
            CLC
            BCC    L1E4E           ;always
;
; $X0, $X8 opcodes
;
L1E43       TYA                    ;opcode
            LSR
            CLC
            BCC    L1E4E           ;always
;
; Others viz $X1,$X3,$X5,$X6,$X7,$X9,$XB,$XD,$XE,$XF
;
L1E48       LSR
            TYA
            ROR
            LSR
            LSR
            SEC
;
L1E4E       ROR
            LSR
            STA    Z44
            CLC
            ASL
            ADC    Z44
L1E56       RTS
;=================================================
; ($1E57) Mini Assembler-Ref to Apple IIe reference manual
;
DoAsm       LDX    #3              ;# of chars to compare
            JSR    GNNB
            DEY
            JMP    L1E63
;
; Check the 3 chars are alphabetic
;
L1E60       LDA    IBuff,Y
L1E63       CMP    #'A'            ;Is it alphabetic?
            BCC    L1E56
            JSR    ToUpper
            CMP    #'Z'+1
            BCS    L1E56           ;No
            INY
            DEX
            BNE    L1E60
;
            LDA    #$00
            STA    Z41
            STA    Z43             ;Len of inst
            CPY    INPUTLEN
            BEQ    L1EC5           ;No operand -> try to assemble inst
;
; Parse the operand
;  X  char(s) check
;  0     ,Y
;  1     )
;  2     ,X
;  3     #$
;  4     ($
;  5     $
;
            LDX    #5              ;# of format indices
AMod1       JSR    GNNB            ;Get 1st char of addr
            STY    Z42
            CMP    CHAR1,X         ;Does 1st char match pattern?
            BNE    AMod2           ;No
            JSR    GNNB            ;Yes, get 2nd char
            CMP    CHAR2,X         ;Matches 2nd half?
            BEQ    AMod4           ;Yes -> C=1
;
            LDA    CHAR2,X         ;Is 2nd half zero?
            BEQ    AMod3           ;Yes -> C=1
            CMP    #'$'            ;Is 2nd half optional?
            BEQ    AMod3           ;Yes -> C=1
            LDY    Z42
;
AMod2       CLC                    ;No match->Clear bit
AMod3       DEY                    ;Back up 1 char
AMod4       ROL    Z41             ;Shift C-bit into format byte
            CPX    #3              ;Time to check for addr?
            BNE    AMod6           ;No
;
            JSR    Hex2Bin         ;Yes, get the number
            LDX    #1              ;Assume 2-byte operand
            LDA    Z3E+1
            BEQ    AMod5           ;single byte
            INX
AMod5       STX    Z43             ;Store inst len
            LDX    #3              ;Prepare to look for ,X
AMod6       DEX                    ;Done w/format check?
            BPL    AMod1           ;No
;
; On fall thru, the inst's addr mode
; had been parsed.
;
            LDA    Z41             ;Get the format
            ASL
            ASL                    ;Put len which is 2 bits
            ORA    Z43             ;in bits0,1
            CMP    #$20            ;Add "$" if 1-/2-byte
            BCS    AMod7
            ORA    #%10000000      ; operand doesn't have it
AMod7       STA    Z41             ;Update format
;
            LDA    #$00            ;Start with BRK opcode
L1EC5       EQU    *               ;Enter here w/opcode in Acc
            STA    Z40             ;Save the opcode
L1EC7       LDA    Z40             ;Get trial opcode
            JSR    INSDIS1         ;Determine its len & format
            BIT    AdrModSW        ;Is addr mode format valid?
            BPL    L1F04           ;No
;
            LDY    Z40             ;Get Opcode
            JSR    L1E04           ;Get its index in mnemonic table
            TAX                    ;Use X-reg as the index
            LDY    ALTYSV
            JSR    GNNB
            DEY
            LDA    #3
            STA    Z42             ;# of chars to compare
L1EE2       LDA    IBuff,Y
            JSR    ToUpper
            CMP    MNEMTBL,X
            BNE    L1F04           ;No hit
            DEC    Z42
            BEQ    L1EF6           ;Got a match
            INX
            INY
            JMP    L1EE2
;
L1EF6       LDA    Z41             ;Get parsed format
            LDY    INSTFMT         ;Get trial format
            CPY    #$9D            ;Is it relative?
            BEQ    RelMode         ;Yes
            CMP    INSTFMT         ;Same format?
            BEQ    MovInst         ;Yes, move inst to memory
;
L1F04       DEC    Z40             ;Else try next opcode
            BNE    L1EC7
            INC    Z41             ;No more, try with
            DEC    Z43             ; len of inst = 2
            BEQ    L1EC7           ;Go try next format
L1F0E       RTS                    ;Unrecognised inst
;
; Calc offset byte for relative addresses
;
RelMode     SBC    #$81            ;Is format compatible
            LSR                    ;with Relative mode?
            BNE    L1F0E           ;No->Bad branch
;
            LDY    Z3E+1
            LDX    Z3E
            BNE    RelMode1
            DEY                    ;Point to offset
RelMode1    DEX                    ; displacement -1
            TXA
            CLC                    ;NB C is clear
            SBC    MONPC           ;Form Addr-PC-2
            STA    Z3E
            BPL    RelMode2        ;Check page
            INY
RelMode2    TYA                    ;Get page
            SBC    MONPC+1         ;Check page
            BNE    L1F0E           ;Err if > 1-byte displacement
;
; Inst had been assembled; move inst to mem
; (INSTLEN)=1 - 2-byte opcode
;          =2 - 3-byte opcode
;
MovInst     LDY    INSTLEN         ;Single byte opcode?
            BEQ    L1F3A           ;Yes
MovInst1    LDA    Z3E-1,Y         ;Copy operand
            STA    (MONPC),Y
            STA    INSTSV,Y
            DEY
            BNE    MovInst1
;
; Display the inst
;
L1F3A       LDA    Z40             ;opcode
            STA    INSTSV
            STA    (MONPC),Y
            BIT    MemPgDSW        ;Is Mem Pg SD up?
            BMI    L1F54           ;Yes->no SD update
            BIT    CodeDSW         ;Update Code SD?
            BPL    L1F54           ;No
;
            JSR    ScrollUp
            JSR    INSTDSP
            JSR    L12B4
;
L1F54       JSR    PCADJ
            STY    IMM1+2
            STA    IMM1+1
            JSR    RSTMONPC
            PLA
            PLA
            JSR    L1624           ;Restore
            JMP    L0AB8
;=================================================
; Get next non-blank char
; ($1F68) Y=index into Input buffer
; (A) - char
; (X) not used
; (Y) set to index next char in buf
;
GNNB        LDA    IBuff,Y
            INY
            JSR    ToUpper
            CMP    #SPACE
            BEQ    GNNB
            RTS
;=================================================
; Display "TRACE"
;
DTRACE      LDX    #10
L1F76       LDA    TRACEK,X
            STA    SLIN23,X
            DEX
            BPL    L1F76
            RTS
;=================================================
; Display "SINGLE STEP"
;
DSSTEP      LDX    #10
L1F82       LDA    STEPK,X
            STA    SLIN23,X
            DEX
            BPL    L1F82
            RTS
;=================================================
; Display "Waiting" for RTS
;
DWAIRTS     LDX    #11
L1F8E       LDA    WAITRTS,X
            STA    SLIN23+28,X
            DEX
            BPL    L1F8E
            RTS
;=================================================
; Erase "WAITING"
;
L1F98       LDX    #11
            LDA    #SPACE
L1F9C       STA    SLIN23+28,X
            DEX
            BPL    L1F9C
            RTS
;=================================================
; ($1FA3) Show "SKIP"
;
DSKIP       LDY    #31
L1FA5       LDA    SKIPM-31,Y
            STA    (ScrLoc),Y
            INY
            CPY    #35
            BNE    L1FA5
            RTS
;=================================================
QUITCMD     JSR    SwapZP
            JMP    DOSWrm          ;ProDOS warm start
;
MONCMD      JSR    SwapZP
            JMP    MONZ
;=================================================
ASMCMD      SEC
            ROR    CodeDSW
            JSR    L1803           ;Clear Code SD
            JMP    XDelLin
;=================================================
; This cmd allows user to send own output to screen
; during SS/TR mode
;
OFFCMD      JSR    ClrScrn         ;Clear all SD's except cmdln SD
            CLC
            DB     $24
;
; This cmd enables BB control of screen output
; during SS/TR mode
;
ONCMD       SEC
            ROR    MasDSW
            JMP    L091F
;=================================================
; Set ScrLoc to the beginning of screen line
; (X),(Y) unchanged
;
VTABX       LDA    SLATLO,X
            STA    ScrLoc
            LDA    SLATHI,X
            STA    ScrLoc+1
            RTS
;=================================================
; (X),(Y) unchanged
;
ToUpper     CMP    #'a'
            BCC    L1FE3
            AND    #$DF
L1FE3       RTS
;=================================================
; Read paddle
;
PREAD2      LDA    PTRIG           ;Start countdown
            LDY    #$00            ;Time the period
            NOP
            NOP
L1FEB       LDA    PADDL0,X        ; until Paddle button 0 is pressed
            BPL    L1FF4
            INY
            BNE    L1FEB
            DEY
L1FF4       RTS
;=================================================
; Delay rtn
;
WAIT2       SEC
L1FF6       PHA
L1FF7       SBC    #1
            BNE    L1FF7
            PLA
            SBC    #1
            BNE    L1FF6
            RTS
;=================================================
PRTERR      LDA    #'E'
            JSR    COUT2
            LDA    #'R'
            JSR    COUT2
            LDA    #'R'
            JSR    COUT2
BELL2       LDA    #BEL
COUT2       JMP    (CSWL)
;
BBDATA      EQU    *               ;Start of bugbyter's variables
;=================================================
; Break Point records. Each record consists of 5
; pieces of data, 4 of which may be changed by
; onscreen editing.
;
BPSetT      DS     16,0            ;$80=BP is set, $00=no BP
;
BPAdrL      DS     16,0            ;User-defined Addr of BP's
BPAdrH      DS     16,0
;
BPCntL      DS     16,0            ;# of times BP addr was encountered
BPCntH      DS     16,0
;
BPTrigL     DS     16,0            ;User-defined cnt b4 breaking. To cause a
BPTrigH     DS     16,0            ; break, trigger must be set to at least 1
;
BPBrkL      DS     16,0            ;counter for # of times
BPBrkH      DS     16,0            ; BB was triggered at a BP
;=================================================
; Mem cells' addresses and flags
;
MCAdrL      DS     17,0
MCAdrH      DS     17,0
MCType      DS     17,0            ;msb on=1 ptr, =0 hex
;
SVBRKV      DW     0
HOLDPZ      DS     11,0
;
SAVEA       DB     0
SAVEX       DB     0
SAVEY       DB     0
SAVEP       DB     2
SAVES       DB     $FF
SVxZ3A      DW     0               ;Save area for ($3A) which MONPC
;
INSTSV      DS     3,0             ;NB. Format & INSTSV must be consecutive locations
INSTFMT     DB     0               ;FORMAT
INSTLEN     DB     0               ;LENGTH OF INST
;
L20F1       DB     0               ;FORMAT of inst BE
L20F2       DB     0               ;LENGTH of inst BE
AdrModSW    DB     $80             ;$80=addr mode is valid
BRKFLAG     DB     $00             ;$FF=IN, $00=OUT
BPDSW       DB     $00             ;$80-update BP SD
TrigSW      DB     $80
BPHitM1     DB     $FF             ;currBP
INSFLAG     DB     $00             ;bit7=1 => insert, bit7=0 => overwrite mode
SW06        DB     $80             ;$80-use kbd rate, $00-use game paddle to adjust rate
ExecSW      DB     $00             ;$80-execution mode
SSSW        DB     $00             ;Single Step
MasDSW      DB     $80             ;Master Display
MemPgDSW    DB     $00             ;Mem Page displayed
CodeDSW     DB     $00             ;Code DisAssembly (CD) SD switch
RTSSW       DB     $00
;
L2100       DB     3               ;Display Option during SS and TR (default O=P)
NumCycles   DB     0
NumMCM1     DB     4               ;# of mem cells-1
L2103       DB     17              ;wndtop of Mem Cell SD
NumBPM1     DB     3               ;min=0 => 1 BP (# of BP's)
L2105       DB     17              ;wndtop BP SD
L2106       DB     11              ;Sentinel (2108)-(2106)=4 always (min -1)
CDBar       DB     13              ;Position of next-to-be-executed-inst bar
L2108       DB     15              ;wndbtm of CD SD (min 3)
L2109       DB     1               ;# of yet-to-be-executed inst minus 1
L210A       DB     11              ;Sentinel (210B)-(210A)=4 always (min 1)
L210B       DB     15              ;wndbtm of stack SD (min 3)
StackPBar   DB     9               ;Position of stack ptr bar within stack SD
L210D       DB     6               ;# of locations above stackptr (min 0)
INPUTLEN    DB     0               ;len of input string
SW13        DB     0               ;$80=skip next inst
RATEC       DB     0
KBDRate     DB     0
;
L2112       DB     0               ;WndLft
L2113       DB     0               ;WndRht
L2114       DB     0               ;WndTop
L2115       DB     0               ;WndBtm
;
ScrollSW    DB     0               ;$80=down, $00=up
ALTYSV      DB     0
LastAdr     DW     0
MBStrtAdr   DW     0               ;Starting addr of memory block displayed
HIGHB       DB     0               ;hibyte flag for string entry
BPTabsT     DB     15,21,27,33     ;BP scrn col offsets
;=================================================
            MSB    ON
SKIPM       ASC    "SKIP"
OPTSK       ASC    "AXYPSBE"
TRACEK      ASC    "TRACE      "
STEPK       ASC    "SINGLE STEP"
WAITRTS     ASC    "AWAITING RTS"
REGSK       ASC    "PC    A  X  Y  S  P  NV-BDIZC"
BPHDR       ASC    "BP  POINT COUNT TRIG  BROKE  "
COPYRK      ASC    "(C) 1984 COMPUTER-ADVANCED IDEAS  V2.21"
;
; Use to show line numbering during a SET cmd & BP #s
;
LinNbrL     ASC    "12345678911111111"
LinNbrH     ASC    "         01234567"
;=================================================
; command keywords
; an entry of this table consists of 2 parts
; 1) the entry len
; 2) a string of chars whose len is 1 less the entry len
;=================================================
COMMAND     DB     $03
            ASC    "A="
            DB     $03
            ASC    "X="
            DB     $03
            ASC    "Y="
            DB     $03
            ASC    "P="
            DB     $03
            ASC    "S="
            DB     $03
            ASC    "R="
            DB     $04
            ASC    "PC="
            DB     $03
            ASC    "C="
            DB     $03
            ASC    "O="
            DB     $04
            ASC    "SET"
            DB     $04
            ASC    "MEM"
            DB     $02
            ASC    "M"
            DB     $04
            ASC    "CLR"
            DB     $03
            ASC    "BP"
            DB     $04
            ASC    "ASM"
            DB     $02
            ASC    "."
            DB     $03
            ASC    "ON"
            DB     $04
            ASC    "OFF"
            DB     $03
            ASC    "IN"
            DB     $04
            ASC    "OUT"
            DB     $02
            ASC    "Q"
            DB     $02
            ASC    "T"
            DB     $02
            ASC    "S"
            DB     $02
            ASC    "G"
            DB     $02
            ASC    "J"
            DB     $02
            ASC    "L"
            DB     $02
            ASC    "V"
            DB     $00
;=================================================
;
CMDTBL      DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETREG-1
            DW     SETOPT-1
            DW     SETCMD-1
            DW     MEMCMD-1
            DW     MONCMD-1
            DW     CLRBPCMD-1
            DW     SETBPCMD-1
            DW     ASMCMD-1
            DW     DOTCMD-1
            DW     ONCMD-1
            DW     OFFCMD-1
            DW     INCMD-1
            DW     OUTCMD-1
            DW     QUITCMD-1
            DW     TRACECMD-1
            DW     SSTEPCMD-1
            DW     XSUBRCMD-1
            DW     JUMPCMD-1
            DW     DISASMCMD-1
            DW     DCPYRCMD-1
;
OURCTLYV    DW     WrmStrt
OURBRKV     DW     BRKHNDLR
CMDTBLP     DW     COMMAND
NumJmps     EQU    *-CMDTBL-1
;=================================================
; Screen Line offsets for Mem Page display
;
MPTabs2     DB     39,38,37,36,35,34,33,32
MPTabs1     DB     28,25,22,19,16,13,10,7
;=================================================
; BB uses absolate screen addressing for output
;
SLATLO      DB     >SLIN00
            DB     >SLIN01
            DB     >SLIN02
            DB     >SLIN03
            DB     >SLIN04
            DB     >SLIN05
            DB     >SLIN06
            DB     >SLIN07
            DB     >SLIN08
            DB     >SLIN09
            DB     >SLIN10
            DB     >SLIN11
            DB     >SLIN12
            DB     >SLIN13
            DB     >SLIN14
            DB     >SLIN15
            DB     >SLIN16
            DB     >SLIN17
            DB     >SLIN18
            DB     >SLIN19
            DB     >SLIN20
            DB     >SLIN21
            DB     >SLIN22
            DB     >SLIN23
SLATHI      DB     <SLIN00
            DB     <SLIN01
            DB     <SLIN02
            DB     <SLIN03
            DB     <SLIN04
            DB     <SLIN05
            DB     <SLIN06
            DB     <SLIN07
            DB     <SLIN08
            DB     <SLIN09
            DB     <SLIN10
            DB     <SLIN11
            DB     <SLIN12
            DB     <SLIN13
            DB     <SLIN14
            DB     <SLIN15
            DB     <SLIN16
            DB     <SLIN17
            DB     <SLIN18
            DB     <SLIN19
            DB     <SLIN20
            DB     <SLIN21
            DB     <SLIN22
            DB     <SLIN23
;=================================================
; ($229D)
;
MNEMTBL     ASC    "BRK"
            ASC    "PHP"
            ASC    "BPL"
            ASC    "CLC"
            ASC    "JSR"
            ASC    "PLP"
            ASC    "BMI"
            ASC    "SEC"
            ASC    "RTI"
            ASC    "PHA"
            ASC    "BVC"
            ASC    "CLI"
            ASC    "RTS"
            ASC    "PLA"
            ASC    "BVS"
            ASC    "SEI"
            ASC    "BRA"
            ASC    "DEY"
            ASC    "BCC"
            ASC    "TYA"
            ASC    "LDY"
            ASC    "TAY"
            ASC    "BCS"
            ASC    "CLV"
            ASC    "CPY"
            ASC    "INY"
            ASC    "BNE"
            ASC    "CLD"
            ASC    "CPX"
            ASC    "INX"
            ASC    "BEQ"
            ASC    "SED"
            ASC    "TSB"
            ASC    "TRB"
            ASC    "BIT"
            ASC    "BIT"
            ASC    "JMP"
            ASC    "???"
            ASC    "STZ"
            ASC    "STZ"
            ASC    "STY"
            ASC    "STY"
            ASC    "LDY"
            ASC    "LDY"
            ASC    "CPY"
            ASC    "???"
            ASC    "CPX"
            ASC    "???"
            ASC    "ASL"
            ASC    "INC"
            ASC    "ROL"
            ASC    "DEC"
            ASC    "LSR"
            ASC    "PHY"
            ASC    "ROR"
            ASC    "PLY"
            ASC    "TXA"
            ASC    "TXS"
            ASC    "TAX"
            ASC    "TSX"
            ASC    "DEX"
            ASC    "PHX"
            ASC    "NOP"
            ASC    "PLX"
            ASC    "ASL"
            ASC    "ROL"
            ASC    "LSR"
            ASC    "ROR"
            ASC    "STX"
            ASC    "LDX"
            ASC    "DEC"
            ASC    "INC"
            ASC    "ORA"
            ASC    "AND"
            ASC    "EOR"
            ASC    "ADC"
            ASC    "STA"
            ASC    "LDA"
            ASC    "CMP"
            ASC    "SBC"
;=================================================
; The first 64 bytes are for instructions of the form: xxxx xxy0
; which are mapped into the form 00xx xxxx (0000 0000 - 0011 1111)
; which is $00-$3F; this is an index into the table
; IF y=0, use left half byte (lower nybble) - corresponds to $X0,$X4,$X8,$XC
; IF y=1, use right half byte (upper nybble) - corresponds to $X2,$X6,$XA,$XE
; The nybbles of each byte of FMT1 stored a 4-bit index into FMT2 table
; The question is how do we modify the values of these bytes?
; Ans: We need an opcode chart to do that.
; $00,$02,$04,$06,$08,$0A,$0C,$0E,$10,$12,$14,$16,$18,$1A,$1C,$1E
; are mapped into indices 000 000-000 111($00-$07)
; $20,$22,$24,$26,$28,$2A,$2C,$2E,$30,$32,$34,$36,$38,$3A,$3C,$3E
; are mapped into indices 001 000-001 111($08-$0F) etc.
;=================================================
FMT1        DB     $04,$22,$54,$33,$ED,$82,$54,$93;index 000 000-000 111
            DB     $03,$22,$54,$33,$ED,$88,$54,$99
            DB     $04,$20,$54,$33,$ED,$80,$44,$90
            DB     $04,$22,$54,$3B,$ED,$88,$44,$9F
            DB     $0D,$22,$44,$33,$ED,$C8,$44,$93
            DB     $11,$22,$44,$33,$ED,$C8,$44,$A9
            DB     $01,$22,$44,$33,$ED,$80,$44,$90
            DB     $01,$22,$44,$33,$ED,$80,$44,$90
;=================================================
; The last 4 bytes are for instructions of the form xxxx xx01
; which are mapped into $40-$43 (0100 00xx)
; The HEX form of these instructions: $X1,$X5,$X9,$XD
; In the 65C02, all these instructions are valid.
; opcodes of the form $X3,$X7,$XB,$XF are all invalid
;=================================================
            DB     $26,$31,$87,$9A
;=================================================
; This table has 16 ($10) bytes. Only a 4-bit index
; is required to access its bytes.
; Bits 0,1 of the bytes of this table = length of instruction
; What info is stored in Bits 2-7? maybe index to packed mnemonic table?
;=================================================
FMT2        DB     $00             ;ERR
            DB     $21             ;IMMEDIATE
            DB     $81             ;Z-PAGE
            DB     $82             ;ABSOLUTE
            DB     $00             ;IMPLIED
            DB     $00             ;ACCUMULATOR
            DB     $59             ;(ZPAGE,X)
            DB     $4D             ;(ZPAGE),Y
            DB     $91             ;ZPAGE,X
            DB     $92             ;ABSOLUTE,X
            DB     $86             ;ABSOLUTE,Y
            DB     $4A             ;(ABS) - JMP ($1234)
            DB     $85             ;ZPAGE,Y - LDX $12,Y
            DB     $9D             ;RELATIVE
            DB     $49             ;(ZPAGE)
            DB     $5A             ;(ABSOLUTE,X) - new JMP ($1234,X)
;=================================================
CHAR1       DB     $AC             ;","
            DB     $A9             ;")"
            DB     $AC             ;","
            DB     $A3             ;"#"
            DB     $A8             ;"("
            DB     $A4             ;"$"
;=================================================
CHAR2       DB     $D9             ;"Y"
            DB     $00
            DB     $D8             ;"X"
            DB     $A4             ;"$"
            DB     $A4             ;"$"
            DB     $00
BBEND       EQU    *