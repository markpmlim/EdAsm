Name          : BB2.S
End of file   :   27,417
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;=================================================
; Execute BI commands
;
DOTCMD      JSR    SwapZP
            BIT    TXTSET
            BIT    TXTPAGE1
            LDA    #$00            ;Set to full text screen
; STA CH
            DB     $8D,$24,00      ;This should ensure
; STA WNDLFT
            DB     $8D,$20,00      ; the assembled copy
; STA WNDTOP
            DB     $8D,$22,00      ; is an exact image of
            LDA    #40
; STA WNDWDTH ; the original program
            DB     $8D,$21,00
            LDA    #24
; STA WNDBTM
            DB     $8D,$23,00
            LDA    #23
; STA CV
            DB     $8D,$25,00
;
            LDA    #>SLIN23
; STA BASL
            DB     $8D,$28,00
            LDA    #<SLIN23
; STA BASH
            DB     $8D,$29,00
            LDA    #CR
            JSR    COUT2
;
            LDY    #1              ;Skip the dot
L0D1D       LDA    IBuff,Y         ;Copy user's input
            STA    INBUF-1,Y
            INY
            CPY    INPUTLEN
            BNE    L0D1D
;
            LDA    #CR             ;Append a CR
            STA    INBUF-1,Y
            JSR    DOSCMD          ;Let BI take care of it
            BCC    L0D36
            JSR    PRINTERR
;
L0D36       LDA    #$60            ;Flashing cursor
            STA    (BASL),Y
WAITK3      BIT    KBD             ; while we wait for
            BPL    WAITK3          ; a keypress
            STA    KBDSTROBE
            JMP    WrmStrt
;=================================================
; ($0D45) A=$xx, X=$xx, PC=$xxxx
;
SETREG      JSR    Hex2Bin
            BCC    L0D4D
L0D4A       JMP    InputErr
;
L0D4D       LDA    Z3E             ;value
            LDX    Z40
            CPX    #5
            BEQ    SetRate
            CPX    #6
            BEQ    SetPC
            CPX    #7
            BEQ    SetCyc
            STA    CPURegs,X       ;(X)=0-4
            BNE    L0D93           ;always
;
SetRate     STA    KBDRate
            STA    RATEC
            ROR    SW06
            BMI    L0D93
;
SetPC       STA    MONPC
            LDA    Z3E+1
            STA    MONPC+1
            BCS    L0D93           ;always
;
SetCyc      STA    CYCLEC
            LDA    Z3E+1
            STA    CYCLEC+1
            BCS    L0D93           ;always
;=================================================
; O=A, O=E etc
;
SETOPT      LDA    IBuff,Y
            JSR    ToUpper
            LDX    #6
L0D86       CMP    OPTSK,X
            BEQ    L0D90           ;Got a hit
            DEX
            BPL    L0D86
            BMI    L0D4A           ;always
;
L0D90       STX    L2100           ;0-6 - Display option
L0D93       JMP    L0922           ;Update SDs & get next cmd
;=================================================
; Execute at full speed starting fr specified addr
; Encoutering a RTS, BRK or BP will force BB to
; return to cmd level
; pg 163-164
;
GKEY1       LDA    Z3E
            STA    SVxZ3A
            LDA    Z3E+1
            STA    SVxZ3A+1
;
; G cmd w/o starting addr. The last starting addr
; specified with a SS,TR or G will be used
;
XSUBRCMD    EQU    *
            BIT    MasDSW
            BPL    L0DA8
            JSR    L0E07           ;Update SDs
;
L0DA8       SEC
            ROR    ExecSW
            LDX    SAVES
            TXS
            JSR    SwapZP
            JSR    RstRegs
            JSR    GoFullSpd       ;Execute subrtn
            JSR    SavRegs
            JMP    WrmStrt         ;Back to cmd level
;
; J cmd w/o starting addr
; This cmd could be used to continue executing a program after a BP
; has forced BB out of Execution Mode. However, no return addr is
; pushed onto the stack
;
JUMPCMD     SEC
            ROR    ExecSW
            JSR    L0E07           ;Update SDs
            JMP    L1058
;
; Execute code with real break points starting with specified addr
; A return addr is pushed onto stack
;
JKEY1       LDA    Z3E
            STA    SVxZ3A
            LDA    Z3E+1
            STA    SVxZ3A+1
            BIT    MasDSW          ;Update Master Display?
            BPL    L0DDB           ;No
            JSR    L0E07           ;Update SDs
;
L0DDB       SEC
            ROR    ExecSW
            JSR    SwapZP
            LDX    SAVES
            TXS
            JSR    RstRegs
;
GoFullSpd   JMP    (SVxZ3A)        ;Exec at full speed
;=================================================
; Clear Code Disassembly and Break Point SD
;
L0DEC       LSR    SW13            ;Clear these switches
            LSR    RTSSW
            LSR    SSSW
            LSR    ExecSW
;
            LDA    #10
            STA    L2112           ;WndLft
            LDA    #39
            STA    L2113           ;WndRht
            ASL    CodeDSW         ;Do we clear CD SD?
            BCC    L0E0A           ;No (NB. msb=0 at the same time)
;
L0E07       JSR    L1803           ;Redraw CD SD
;
L0E0A       ASL    BPDSW           ;Do we clear BP SD also?
            BCC    L0E12           ;No
            JSR    L180F           ;Clear BP SD
;
L0E12       JMP    L1719           ;Redraw BP window
;=================================================
; ($0E15) Single Step mode with transparent BP's
;
; Re-enter into Single Step mode w/o specifying a starting addr
; BB remembers the last inst it executed b4 leaving trace
; or single step mode and continues fr the next inst whenever
; user re-enter trace/single step mode
;
SSTEPCMD    JSR    L0DEC           ;Setup & update Code/BP SDs
            SEC
            ROR    SSSW
            JSR    DSSTEP
            JMP    L103D
;
SKEY1       JSR    L0DEC           ;Start fr specified addr
            JSR    DSSTEP
            LDA    #$80
            STA    SSSW
            BNE    L0E3E           ;always
;=================================================
; Trace mode with transparent BP's
;
; Re-enter into Trace mode w/o specifying a starting addr
;
TRACECMD    JSR    L0DEC           ;Setup & update Code/BP SDs
            JSR    DTRACE
            JMP    L103D
;
TKEY1       JSR    L0DEC           ;Start fr specified addr
            JSR    DTRACE
;
; Common code for SS/TR with a specified addr
;
L0E3E       JSR    L1803           ;Clear Code SD
            LDA    Z3E             ;Addr already converted &
            STA    MONPC
            LDA    Z3E+1           ; stored here temporarily
            STA    MONPC+1
;
L0E49       LDY    #0
            LDA    (MONPC),Y       ;Get opcode @ this addr
            BNE    L0E75           ;Not a BRK inst
            BIT    BRKFLAG         ;IN?
            BPL    L0E75           ;No
            JSR    L18B4           ;Is it in our list of BP's?
            BMI    L0E75           ;No
;
; Since real BPs are IN, BB will operate as
; if real BPs are OUT during a TRACE
;
L0E59       TXA                    ;Form an index
            ASL
            ASL
            TAY                    ; in Y-reg
            LDX    #0
            STX    TrigSW
L0E62       LDA    L088F,Y         ;Get original inst & format
            STA    INSTSV,X        ; for this BP & store it here
            INY
            INX
            CPX    #4
            BNE    L0E62
;
            AND    #%000000011     ;Isolate len bits fr the
            STA    INSTLEN         ; addr mode format bits
            BCS    L0E78           ;always
;
L0E75       JSR    INSDIS          ;Get format & length of instr @ PC
;
L0E78       LDA    #iNOP           ;Make sure area is filled
            STA    INSTBE+1        ; with $EA in case inst len
            STA    INSTBE+2        ; is 1-2 bytes long
            LDY    INSTLEN         ;Length
            STY    L20F2
            LDA    INSTFMT         ;Format
            STA    L20F1
;
L0E8C       LDA    INSTSV,Y        ;Move inst to soon-
            STA    INSTBE,Y        ; -to-be executed area 
            DEY
            BPL    L0E8C
;
            BIT    MasDSW          ;Do we update the Master Display?
            BPL    L0EE3           ;No
;
            LDX    CDBar           ;Highlight next-to-be-exec inst
            JSR    VTABX
            STX    Z3E
            LDA    #$20            ;ASCII space
            JSR    ClrEOLI         ;Inverse the scrn line
            JSR    INSTDSP
            JSR    InvLine
            JSR    DMONPC
;
            LDX    L2109
            BMI    L0EE3           ;-1 -> no-yet-to-be-executed inst
            STX    Z3E+1           ;1 -> 2 yet-to-be-executed inst displayed
            JSR    SVMONPC
            LDA    AdrModSW        ;(Is this for the next-to-be-exec inst?)
            PHA
;
L0EBE       JSR    PCADJ
            STA    MONPC
            STY    MONPC+1
            JSR    INSDIS          ;Get format & len of instr
            INC    Z3E
            LDX    Z3E
            JSR    VTABX
            JSR    ClrEOL
            JSR    INSTDSP         ;Show disassembled inst
            DEC    Z3E+1
            BPL    L0EBE           ;next yet-to-be-executed-inst
;
            PLA
            STA    AdrModSW
            JSR    RSTMONPC
            JSR    L1624           ;Copy INSTBE data to INSTSV area
;
L0EE3       BIT    TrigSW
            BPL    L0EF2
            BIT    BRKFLAG         ;IN?
            BMI    L0F3C           ;Yes
            JSR    L18B4           ;Chk if it's one of ours
            BMI    L0F3C           ;No hit
;
; BB has encountered an inst located @ a BP addr
;
L0EF2       LDA    #$80
            STA    TrigSW
            LDX    BPHitM1
            INC    BPCntL,X
            BNE    L0F02
            INC    BPCntH,X
;
L0F02       LDA    BPTrigL,X       ;If trigger = count
            CMP    BPCntL,X
            BNE    L0F2C
            LDA    BPTrigH,X
            CMP    BPCntH,X
            BNE    L0F2C
            INC    BPBrkL,X        ; incr BROKE cntr
            BNE    L0F1A
            INC    BPBrkH,X
;
; Stops program execution b4 executing the inst @ the BP addr.
; BB will highlight the row in the BP SD that corresponds to
; the breakpoint that was triggered
;
L0F1A       LDA    #$80            ;Flag we have to update BP SD
            STA    BPDSW
            ASL                    ;(A)=0
            STA    BPCntL,X        ;Clears the count
            STA    BPCntH,X
            JSR    BELL2
            JMP    L1060           ;Back to cmd level
;
L0F2C       BIT    MasDSW
            BPL    L0F34
            JSR    L173A           ;Update BP SD
;
L0F34       BIT    ExecSW
            BPL    L0F3C
            JMP    L1058
;
; During Trace mode, instead of using the keyboard, user can use
; Paddle Button 0 to control the tracing. To do this, user
; must set Btn0SW to $80 b4 entering trace mode.
; Ref pg 168
;
L0F3C       BIT    Btn0SW          ;Use Paddle Button 0 to suspend tracing?
            BPL    L0F46           ;No
            BIT    BUTN0
            BMI    L0F3C           ;Loop until paddle 0 is released
;
; NB. User's program will never receive any keystroke unless
; BB's keyboard polling is turned off.
; To turn off keyboard polling, set (KBDPOLL) to $80+ASCII char.
; BB will ignore all chars typed at keyboard except this special
; interrupt char which the user had specified.
; ref pg 167
;
L0F46       BIT    KBDPOLL         ;Is polling off?
            BPL    L0F5B           ;No, allow user's program to accept keystroke
            LDA    KBD             ;Is there a keypress?
            BPL    L0F76           ;No
            CMP    KBDPOLL         ;Yes, is it the interrupt char?
            BNE    L0F76           ;No
            STA    KBDSTROBE       ;Yes, clear keyboard ready flag
;
ExitDbg     JMP    L1060           ;Stop SS/TR & transfer back to BB's cmd level
;
L0F5B       BIT    SSSW
            BPL    ChkKS
L0F60       LDA    #$C0            ;Set values for noise generation
            STA    IMM2+1
            LDA    #$02
            STA    IMM3+1
WAITK5      LDA    KBD
            BPL    WAITK5
            CMP    #SPACE
            BNE    ChkKS2
            STA    KBDSTROBE
;
L0F76       LDA    #$10            ;Set sound delay
            STA    IMM2+1
            STA    IMM3+1
L0F7E       JMP    L103D
;
; These keystrokes are checked during Single Step or Trace modes
;
ChkKS       LDA    KBD
            BPL    L0F7E
ChkKS2      STA    KBDSTROBE
            CMP    #ESC            ;Did user ask for a ret to cmdline?
            BEQ    ExitDbg         ;Yes, exit debugging
            CMP    #SPACE          ;Did user ask for a single step?
            BEQ    ExecSS          ;yes
            CMP    #CR
            BEQ    L0FE2
            CMP    #'1'            ;Did user ask to display primary Apple screen?
            BEQ    DTxtPg1
            CMP    #'2'            ;Did user ask to display secondary Apple screen?
            BEQ    DTxtPg2
            JSR    ToUpper
            CMP    #'T'            ;Did user ask to display text screen?
            BEQ    DTxtScr
;
            CMP    #'L'            ;Did user ask to display lores graphic screen?
            BEQ    DLoResGr
            CMP    #'H'            ;Did user ask to display hires graphic screen?
            BEQ    DHiResGr
            CMP    #'F'            ;Did user ask to display full screen graphics?
            BEQ    DFullGr
            CMP    #'M'            ;Did user ask to display mixed text & graphics?
            BEQ    DMixGr
;
            CMP    #'Q'            ;Did user ask to turn off the sound?
            BEQ    SNDOFF
            CMP    #'S'            ;Did user ask to turn on the sound?
            BEQ    SNDON
;
            CMP    #'R'
            BEQ    Tr2RTS
;
            CMP    #'K'            ;key board to adjust trace rate
            BEQ    UseKR
            CMP    #'P'
            BEQ    UsePdl0         ;game paddle to adjust trace rate
;
            CMP    #'C'            ;Did user ask to clear cycle counter?
            BEQ    ClrCC
            CMP    #CURSR          ;Did user ask to skip next instruction?
            BNE    SkipNxtI
;
            STA    SSSW
            STA    SW13            ;Flag "skip next inst"s
            JSR    DSSTEP          ;Display "SINGLE STEP"
            JMP    L123B
;
Tr2RTS      ROR    RTSSW           ;Trace until RTS
            JSR    DWAIRTS
;
; Do trace until BP encountered or end of program
;
L0FE2       JSR    DTRACE
            LSR    SSSW            ;Clear SS mode
            BPL    SkipNxtI        ;always
;
ExecSS      JSR    DSSTEP
            SEC
            ROR    SSSW
            BMI    SkipNxtI        ;always
;
DTxtPg1     STA    TXTPAGE1
            BEQ    SkipNxtI
DTxtPg2     STA    TXTPAGE2
            BEQ    SkipNxtI        ;always
;
DTxtScr     STA    TXTSET
            BEQ    SkipNxtI
DLoResGr    STA    LORES
            STA    TXTCLR
            BEQ    SkipNxtI
DHiResGr    STA    HIRES
            STA    TXTCLR
            BEQ    SkipNxtI
DFullGr     STA    MIXCLR
            BEQ    SkipNxtI
DMixGr      STA    MIXSET
            BEQ    SkipNxtI
;
SNDOFF      LDA    #$00
SNDON       STA    SNDSW
            BEQ    SkipNxtI
;
ClrCC       LDA    #$00
            STA    CYCLEC
            STA    CYCLEC+1
            JSR    DBBREGS
            BNE    SkipNxtI        ;always
;
; $80 use KBD rate, $00=game paddle to control rate
;
UsePdl0     LDA    #$00            ;Use paddle
UseKR       STA    SW06
;
; Skip next inst
;
SkipNxtI    BIT    SSSW            ;Single Step?
            BPL    L103D           ;No
            JMP    L0F60
;
L103D       BIT    SNDSW           ;Make some noise?
            BPL    L1058           ;No
IMM2        LDX    #$C0
IMM3        LDY    #$02
            LDA    SPKR
L1049       INX
            BEQ    L1058           ;->done
            NOP
            JMP    L1050
L1050       DEY
            BEQ    IMM3
            JMP    L1056
L1056       BNE    L1049           ;always
;
L1058       BIT    AdrModSW        ;Is inst valid i.e. opcode defined?
            BMI    L1069           ;Yes
            JMP    L123B           ;->???
;
L1060       STA    TXTSET          ;Exit
            STA    TXTPAGE1
            JMP    L0922           ;Update SDs & get next cmd
;
; NB. (A) may be a random value
;
L1069       LDX    HSTAKP
            LDY    INSTBE          ;Get opcode
            BEQ    L1060           ;BRK -> back to cmd level
;
            CPY    #iRTI
            BEQ    L10AB
            CPY    #iRTS
            BEQ    L10B2
            CPY    #iJMP
            BEQ    L10D9
;
            LDA    #$00
            CPY    #$6C            ;JMP (ABSOLUTE)
            BEQ    L10DA
            LDA    HXREG
            CPY    #$7C            ;JMP (ABSOLUTE,X) - new addressing mode
            BEQ    L10DA
;
            CPY    #$BA            ;TSX
            BEQ    L1104
            CPY    #$9A            ;TXS
            BEQ    L110B
;
            CPY    #iJSR
            BEQ    L1110
;
            TYA
            AND    #%01011111
            CMP    #$5A            ;PHY,PLY,PHX,PLX?
            BNE    L109E           ;No
            JMP    L1194
;
L109E       TYA
            AND    #%10011111
            CMP    #$08            ;PHP,PLP,PHA,PLA
            BEQ    L10A8
            JMP    L11F0           ;BR insts
L10A8       JMP    L11B2
; RTI inst
L10AB       CLC
            INX
            LDA    STACK,X
            STA    HFLAGS
; RTS inst
L10B2       BIT    RTSSW           ;Wait for RTS?
            BPL    L10C1           ;No
            CLC
            ROR    RTSSW           ;Clear
            JSR    L1F98           ;Remove "AWAITING RTS" msg
            JMP    ExecSS
;
L10C1       INX
            LDA    STACK,X         ;Get the ret addr
            STA    MONPC
            INX
            LDA    STACK,X
            STA    MONPC+1
            STX    HSTAKP
            PHP
            JSR    L14C3           ;Update Stack SD
            PLP
            BCC    L1101           ;Was RTI inst
            JMP    L123B
;
; JMP instructions handler
; If inst is JMP abs, (A) is irrelevant
;
L10D9       CLC                    ;JMP abs
L10DA       TAY                    ;JMP (abs) or JMP (abs,X)
            LDA    INSTBE+1
            LDX    INSTBE+2
            STA    MONPC
            STX    MONPC+1
            BCC    L1101           ;JMP abs
;
; JMP indirect modes
; (Y)=0 if JMP (abs)
; (Y)=(HXREG) if JMP (abs,X)
;
            JSR    SVMONPC
            TYA
            PHA
            JSR    SwapZP
            PLA
            CLC
            ADC    SVxZ3A
            LDX    SVxZ3A+1
            BCC    L10FA
            INX
;
L10FA       JSR    L13DD
            STA    MONPC
            STX    MONPC+1
L1101       JMP    L1242
;
L1104       LDA    HSTAKP          ;TSX
            STA    HXREG
            JMP    L123B
;
L110B       LDX    HXREG           ;TXS
            JMP    L11D8
;
; NB. We are still in simulation mode
; This part of the code allows user to
; execute ProDOS calls in real time
;
L1110       LDY    INSTBE+2        ;JSR
            LDA    INSTBE+1
            BNE    L1148           ;Addr is not @ mem page bdry
            BIT    XUNDSW          ;Allow execution of ProDOS calls?
            BPL    L1148           :No
            CPY    #$BF            ;Is ProDOS Global Page
            BNE    L1148           ;No
;
            LDY    #5
L1123       LDA    (MONPC),Y
            STA    L113F,Y         ;Self-modifying code
            DEY
            CPY    #2
            BNE    L1123
;
            LDA    MONPC
            CLC
            ADC    #3
            STA    MONPC
            BCC    L1138
            INC    MONPC+1
;
L1138       TXS
            JSR    SwapZP
            JSR    RstRegs
L113F       JSR    PRODOS8
            DB     0
            DW     0
            JMP    L1172
;
; This part of the BB's code allows the user to execute code in
; real time while in Simulation mode. It checks if the instr is
; within the specified Real Time Code region
;
L1148       CPY    BARTC+1         ;Is (Y,A) btwn (BARTC)
            BCC    L117B
            BNE    L1162
            CMP    BARTC
            BCC    L117B
;
            CPY    EARTC+1         ; and (EARTC)?
            BCC    L1162
            BNE    L117B
            CMP    EARTC
            BCC    L1162           ;Yes
            BNE    L117B
;
; Execute code in real time
;
L1162       STY    SVxZ3A+1        ;Set up the JMP addr
            STA    SVxZ3A
            TXS
            JSR    SwapZP
            JSR    RstRegs
            JSR    GoFullSpd       ;xfer control to code
;
L1172       JSR    SavRegs
            LDX    #>BBStack       ;Reset BB's stack area $100-$1FF
            TXS
            JMP    L1238
;
; Simulation mode
;
L117B       CLC
            JSR    PCADJ2          ;(Y,A)-effective addr
            LDX    HSTAKP
            PHA
            TYA
            STA    STACK,X         ;Save (Y) and (A) here
            DEX
            PLA
            STA    STACK,X
            DEX
            STX    HSTAKP
            JSR    L14C3           ;Update Stack SD
            JMP    L10D9
;
; PHY,PLY,PHX,PLX
;
L1194       TYA
            ASL
            AND    #%01000000
            BNE    L11A4
            BCC    L11A0
            LDA    HXREG           ;PHX
            BCS    L11BF           ;always
;
L11A0       LDA    HYREG           ;PHY
            BCC    L11BF
;
L11A4       INX
            LDA    STACK,X
            BCC    L11AE
            STA    HXREG           ;PLX
            BCS    L11CE           ;always
L11AE       STA    HYREG           ;PLY
            BCC    L11CE           ;always
;
; PHP,PLP,PHA,PLA
;
L11B2       TYA
            ASL
            ASL
            BMI    L11C6           ;PLP/PLA
            BCC    L11BD           ;PHP
            LDA    HACCUM          ;PHA
            BCS    L11BF           ;always
;
L11BD       LDA    HFLAGS
L11BF       STA    STACK,X
            DEX
            JMP    L11D8           ;-> adjust SP
;
L11C6       INX
            LDA    STACK,X
            BCC    L11D6           ;PLP
            STA    HACCUM          ;PLA
;
L11CE       TAY
            LDA    HFLAGS
            PHA
            PLP
            TYA
            PHP
            PLA
;
L11D6       STA    HFLAGS
L11D8       STX    HSTAKP          :NB. Must adjust SP
            JSR    L14C3           ;Update stack SD
            JMP    L123B
;=================================================
; (INSTLEN)=0-1 byte, 1-2 bytes, 2-3 bytes
; Branch inst should make use of PCADJ3 entry
; with displacement in (A)
; Ret
;  (Y,A)-effective addr
;
PCADJ       SEC
PCADJ2      LDA    INSTLEN         ;length
PCADJ3      LDY    MONPC+1
            TAX                    ;Test displacement sign
            BPL    PCADJ4          ; (for relative branch)
            DEY                    ;Extend -ve by decrementing MONPC+1
;
PCADJ4      ADC    MONPC
            BCC    L11EF
            INY
L11EF       RTS
;
; Check if the inst in Y-reg is a branch opcode
; There are 9 rel branch insts whose opcodes are
; $10,$30,$50,$70,$90,$B0,$D0,$F0 and $80
;
L11F0       CPY    #$80            ;If BRA,
            BNE    L11F6
            LDA    #$10            ; use $10
L11F6       AND    #$1F            ;If relative branch, then
            EOR    #$14            ; change displacement ..
            CMP    #$04
            BNE    L1201           ;-> Not a branch inst
            STA    INSTBE+1        ; ..to $04 @ this location
;
L1201       JSR    SwapZP
            JSR    RstRegs
;
; Next-Instruction-To-Be-Executed
;
INSTBE      NOP                    ;Opcode
            NOP                    ;Lobyte
            NOP                    ;HiByte
            JMP    L1230
;
; Relative instructions that actually branch comes here
;
            CLD
            JSR    SwapZP
            JSR    PCADJ
            STA    MONPC
            STY    MONPC+1
;
            CLC
            LDA    INSTSV+1        ;displacement of rel insts
            JSR    PCADJ3
            STA    MONPC
            LDX    #3              ;3 cycles for successful brch
            CPY    MONPC+1
            BEQ    L1228
            INX
;
L1228       STX    NumCycles
            STY    MONPC+1         ;Addr of next inst
            JMP    L1242
;
; Instructions that do not involve transfer of 
; control (include those relative insts that
; did not branch)
;
L1230       JSR    SavRegs
            LDA    #2              ;This is the default
            STA    NumCycles       
;
L1238       JSR    SwapZP
;
L123B       JSR    PCADJ
            STA    MONPC
            STY    MONPC+1         ;Addr of next inst
;
; Common code for all instructions
;
L1242       BIT    MasDSW          ;Update Master Display?
            BPL    L128B           ;No
;
            LDX    CDBar           ;Next-to-be-executed
            JSR    VTABX
            BIT    SW13            ;Was inst skipped?
            BPL    L125A
;
            JSR    DSKIP           ;Yes
            LSR    SW13            ;clear msb
            BPL    L1269           ;Always
;
L125A       JSR    DOptions
            JSR    InvLine
            JSR    DREGS
            JSR    L151A           ;Update MC SD
            JSR    DBBREGS
;
L1269       BIT    SSSW            ;Single Step mode?
            BMI    L1288           ;Yes
;
            LDY    KBDRate         ;Trace mode
            BIT    SW06            ;Are we using the KB rate?
            BMI    L1280           ;Yes
            BIT    PDL0SW          ;Use Paddle 0?
            BPL    L1280
;
            LDX    #0              ;Yes
            JSR    PREAD2          ;Get a reading fr paddle 0
L1280       STY    RATEC
            INY
            TYA
            JSR    WAIT2
;
L1288       JSR    ScrollUp
L128B       BIT    ExecSW          ;Executing in full speed?
            BMI    L1293
            JMP    L0E49           ;No, continue with SS/TR mode
;
L1293       JSR    SVMONPC
            JMP    L0DDB
;=================================================
; ($1299) Display relevant info on the right side of inst
;
DOptions    LDY    #30
            LDX    L2100           ;Curr display option
            LDA    OPTSK,X         ;Show Letter
            STA    (ScrLoc),Y
            LDA    #':'
            INY
            STA    (ScrLoc),Y
            CPX    #5
            BCS    L12B2           ;O=E/O=B
            INY
            LDA    CPURegs,X       ;Get the register's curr value and display
            JMP    DBINSTR         ; its contents as a string of 0's and 1'
;
L12B2       BNE    L12D4           ;-> O=E
;
; Display machine code in hex
;
L12B4       LDX    #-1
            LDY    #32             ;offset in scrn line
L12B8       INX
            LDA    INSTSV,X
            JSR    PUTHEX
            INY
            CPX    INSTLEN
            BNE    L12B8
            RTS
;
; Branch insts
;
L12C6       LDA    INSTSV+1        ;Print the displacement
            LDY    #34
            JSR    PUTHEX
            LDY    NumCycles       ;# of cycles
            JMP    L149F
;
; Compute effective addrs/rel branches
; & instruction cycles - pg 160, 208
;
L12D4       LDY    INSTBE+1
            LDX    INSTBE+2
            LDA    INSTBE          ;Get opcode
            STA    Z40             ;Save here for later
;
; The following instructons are handled
; individually because their bit patterns
; do not conform to the norm
;
            CMP    #$80
            BEQ    L12C6           ;-> BRA
            CMP    #$14
            BEQ    L1329           ;-> TRB zp
            CMP    #$BC
            BEQ    L1327           ;-> LDY abs,X
            CMP    #$3C
            BEQ    L1327           ;-> BIT abs,X
            CMP    #$7C
            BNE    L12F6
            JMP    L13B7           ;-> JMP (abs,X)
L12F6       CMP    #$6C
            BNE    L12FD
            JMP    L13CD           ;-> JMP (abs)
;
L12FD       AND    #%00011111      ;abcd efgh
            STA    Z41             ;000d efgh
            CMP    #$10
            BEQ    L12C6           ;Branch inst
            CMP    #$19
            BEQ    L135F           ;abs,Y inst
;
            CMP    #$14            ;inst involving zp,X and zp,Y
            BEQ    L132C           ; & the special case TRB zp
            CMP    #$15
            BEQ    L132C
            CMP    #$16
            BEQ    L132C
;
            CMP    #$1D            ;abs,X inst
            BEQ    L1352
;
            CMP    #$01            ;(zp,X) inst - indirect
            BEQ    L138E
            CMP    #$11            ;(zp),Y inst
            BEQ    L1399
            CMP    #$12            ;(zp) inst
            BEQ    L1386
            CMP    #$1E            ;abs,X inst
L1327       BEQ    L1352
L1329       JMP    L142C           ;Others
;
; Instructions involving zp,X zp,Y
;
L132C       LDX    #$00
            LDA    Z40             ;Opcode
            AND    #%11011111
            CMP    #$96
            BEQ    L1349           ;LDX zp,Y & STX zp,Y
;
            TYA                    ;addr lobyte
            CLC
            ADC    HXREG
            LDY    #4              ;# of cycles
            PHA
            LDA    Z41             ;000d efgh
            CMP    #$16
            BNE    L1345           ;-> zp,X
            LDY    #6              ;# of cycles
L1345       PLA
            JMP    L13FB
;
; STX zp,Y/LDX zp,Y
;
L1349       TYA                    ;addr lobyte (zp loc)
            CLC
            ADC    HYREG
            LDY    #4              ;# of cycles
            JMP    L13FB
;
; abs,X insts, LDX abs,Y inst 
; BIT abs,X & LDY abs,X
;
L1352       LDA    Z40             ;Get opcode
            CMP    #$BE
            BEQ    L135F           ;-> LDX abs,Y
;
; abs,X insts
;
            TYA
            CLC
            ADC    HXREG
            JMP    L1363
;
; abs,Y instructions
;
L135F       TYA                    ;addr lo
            CLC
            ADC    HYREG
L1363       BCC    L1366
            INX
;
L1366       PHA                    ;Save addr lo-byte
            LDA    Z40             ;Get opcode
            CMP    #$BE
            BEQ    L137D           ;-> LDX abs,Y
            LDY    #5              ;# of cycles
            AND    #$F0
            CMP    #$90
            BEQ    L1382           ;-> STA abs,X/STZ abs,X
;
            LDY    #7              ;# of cycles
            LDA    Z41
            CMP    #$1E
            BEQ    L1382           ;->abs,X shifts insts
L137D       LDY    #4              ;# of cyles for
            JSR    L1425           ; other abs,X insts
L1382       PLA
            JMP    L13FB
;
; (zp) inst
;
L1386       TYA                    ;zp loc
            JSR    L140B
            LDY    #5              ;# of cycles
            BNE    L13FB           ;Always
;
; (zp,X)
;
L138E       TYA
            CLC
            ADC    HXREG
            JSR    L140B
            LDY    #6              ;# of cycles
            BNE    L13FB           ;always
;
; (zp),Y inst
;
L1399       TYA                    ;zp loc
            JSR    L140B           ;(A,X) - ptr
            STX    INSTBE+2
            CLC
            ADC    HYREG
            BCC    L13A6
            INX
;
L13A6       PHA
            LDY    #6              ;# of cycles
            LDA    Z40
            CMP    #$91            ;STA (zp),y
            BEQ    L13B3
            DEY                    ;Less 1 cycle
            JSR    L1425           ;Cross mem page bdry?
L13B3       PLA
            JMP    L13FB
;
; JMP (abs,X)
;
L13B7       JSR    SwapZP
            LDA    INSTBE+1
            CLC
            ADC    HXREG
            LDX    INSTBE+2
            BCC    L13C6
            INX
L13C6       JSR    L13DD
            LDY    #6              ;# of cycles
            BNE    L13FB           ;always
;
L13CD       JSR    SwapZP
            LDA    INSTBE+1
            LDX    INSTBE+2
            JSR    L13DD
            LDY    #5              ;# of cycles
            BNE    L13FB           ;always
;=================================================
; Get pointer located in non-zp memory
; Entry
;  (X,A)=addr
; Ret
;  (A,X)=pointer
;
L13DD       STA    IMM4+1
            STX    IMM4+2
            STX    IMM5+2
            CLC
            ADC    #1
            STA    IMM5+1          ;-> page brdy bug?
IMM4        LDA    $FFFF
            PHA
IMM5        LDA    $FFFF
            PHA
            JSR    SwapZP
            PLA
            TAX
            PLA
            RTS
;=================================================
; Print addr & # of cycles
; (Y)=# of cycles
; (A,X)=addr
;
L13FB       STY    Z43             ;# of cycles
            LDY    #32
            PHA
            TXA
            JSR    PUTHEX
            PLA
            JSR    PUTHEX
            JMP    L14A1
;=================================================
; Get zp pointer
; Input
;  (A)=zp location
; Output
;  (A,X)=pointer stored @ zp loc
;
L140B       PHA
            JSR    SwapZP
            PLA
            TAX
            STX    IMM10+1
            INX
            STX    IMM11+1
;
IMM10       LDA    $00             ;zpage locn
            PHA
IMM11       LDA    $00
            PHA                    ;hi
            JSR    SwapZP
            PLA
            TAX
            PLA
            RTS
;=================================================
; 1 more cycle if mem page boundary is crossed
;
L1425       CPX    INSTBE+2
            BEQ    L142B
            INY
L142B       RTS
;=================================================
; Determine # of cycles for other inst
; Need to check all 65C02 opcodes are included
;
L142C       LDY    #5              ;Assume 5 cycles
            LDA    Z40             ;opcode abcd efgh
            AND    #%11100111      ;abc0 0fgh
            CMP    #$04
            BNE    L143F
            LDA    Z40             ;$04,$0C,$14,$1C (TSB,TRB)
            AND    #%00001000
            BEQ    L149F           ;-> TSB/TRB dp
            INY                    ;-> TSB/TRB abs
            BNE    L149F           ;always
;
L143F       LDY    #3              ;3 cycle inst
            LDA    Z41             ;000d efgh
            CMP    #$04
            BEQ    L149F           ;$24,$44,$64,$84,$A4,$C4,$E4
            CMP    #$05
            BEQ    L149F           ;$05,$25,$45,$65,$85,$A5,$C5,$E5
;
            LDA    Z40             ;Get opcode
            AND    #%11011111      ;ab0d efgh
            STA    Z42
            CMP    #$86
            BEQ    L149F           ;-> LDX/STX zp
            LDA    Z40             ;Get opcode
            CMP    #iJMP
            BEQ    L149F           ;-> JMP abs
            AND    #%10111111      ;a0cd efgh
            CMP    #$08
            BEQ    L149F           ;-> $08,$48
            LDA    Z40             ;Get opcode
            ASL
            CMP    #$B4
            BEQ    L149F           ;-> PHY/PHX
;
            INY                    ;4 cycle inst
            CMP    #$F4
            BEQ    L149F           ;->PLY/PLX
;
            LDA    Z41             ;000d efgh
            CMP    #$0D
            BEQ    L149F           ;-> $0D,$2D,$4D,$6D,$8D,$AD,$CD,$ED
            CMP    #$0C
            BEQ    L149F           ;-> $0C,$2C,$4C,$6C,$8C,$AC,$CC,$EC
            LDA    Z42             ;ab0d efgh
            CMP    #$8E
            BEQ    L149F           ;-> $8E,$AE
            LDA    Z40             ;Get opcode
            CMP    #$9C
            BEQ    L149F           ;-> STZ abs
            AND    #%10111111      ;a0cd efgh
            CMP    #$28
            BEQ    L149F           ;-> $28,$68
;
            INY                    ;5 cycle inst
            LDA    Z41             ;000d efgh
            CMP    #$06            ;$06,$26,$46,$66,$C6,$E6
            BEQ    L149F
;
            INY                    ;6 cycle inst
            LDA    Z40             ;Get opcode
            AND    #%10011111
            BEQ    L149F           ;-> $20,$40,$60
            LDA    Z41             ;000d efgh
            CMP    #$0E
            BEQ    L149F           ;-> $0E,$2E,$4E,$6E,$8E,$AE,$CE,$EE
;
; On fall thru, instructions not filtered out
; by the code above will be 2 cycles
; Print # of cycles
;
            LDY    #2
L149F       STY    Z43             ;# of cycles
L14A1       LDY    #37
            LDA    #'('
            STA    (ScrLoc),Y
            INY
            CLC
            LDA    Z43
            ADC    #'0'
            STA    (ScrLoc),Y
            INY
            LDA    #')'
            STA    (ScrLoc),Y
;
            LDA    Z43
            CLC
            ADC    CYCLEC
            STA    CYCLEC
            BCC    L14C2
            INC    CYCLEC+1
L14C2       RTS
;=================================================
; Show Stack SD
;
L14C3       BIT    MasDSW
            BPL    L1519           ;-> No update
;
            SEC
            LDA    HSTAKP
            SBC    L210D           ;# of locations above stack ptr
            STA    Z40
;
            LDX    #2              ;top of SD-1
L14D2       INX
            STX    Z43
            JSR    VTABX
            LDY    #1
            LDA    #'1'
            STA    (ScrLoc),Y      ;Show "1xx:"
            INY
            LDA    Z40
            TAX
            JSR    PUTHEX
            LDA    #':'
            STA    (ScrLoc),Y
;
            INY
            INY
            LDA    STACK,X
            JSR    PUTHEX
;
            LDA    Z43
            CMP    StackPBar
            BNE    L1510
;
            LDY    #8
L14FA       LDA    (ScrLoc),Y      ;Hilite stack ptr bar
            AND    #$3F
            STA    (ScrLoc),Y
            DEY
            BPL    L14FA
;
            CPX    #32
            BCS    L1510
;
; BB's stack area
;
            LDA    #$60            ;Flashing space
            INY                    ;=1
            STA    (ScrLoc),Y
            LDY    #8
            STA    (ScrLoc),Y
;
L1510       INC    Z40             ;NB. If -1, (Z40) becomes 0
            LDX    Z43
            CPX    L210B           ;wnd btm of Stack SD
            BCC    L14D2           ;Next stack location
L1519       RTS
;=================================================
; Show MemCell SD
;
L151A       JSR    SwapZP
            LDY    L2103           ;lst line of MC SD
            LDX    #-1
L1522       INX
            STY    ALTYSV
            LDA    SLATLO,Y
            STA    STOSCR+1        ;Point @ scrn loc
            LDA    SLATHI,Y
            STA    STOSCR+2
;
            LDY    #$00            ;Show "xxxx:"
            LDA    MCAdrH,X
            STA    IMM6+2
            STA    IMM7+2
            JSR    STOHEX
            LDA    MCAdrL,X
            STA    IMM6+1
            STA    IMM7+1
            JSR    STOHEX
            LDA    #':'
            JSR    STOSCR
;
IMM6        LDA    $FFFF
            PHA
            LDA    MCType,X        ;Pointer?
            BPL    L1569           ;No
            INC    IMM7+1          ;mem page bdry bug!
;
IMM7        LDA    $FFFF
            JSR    STOHEX
            PLA
            JSR    STOHEX
            BNE    L1577           ;always
;
L1569       PLA                    ;Hex
            PHA
            JSR    STOHEX
            LDA    #SPACE
            JSR    STOSCR
            PLA
            JSR    STOSCR
;
L1577       LDY    ALTYSV
            INY
            CPY    #22             ;Last line of MC SD?
            BNE    L1522           ;No, next mem cell
            JMP    SwapZP
;=================================================
; Store the hexdec rep of (A) into a mem location
; esply video mem
;
STOHEX      PHA
            LSR
            LSR
            LSR
            LSR
            JSR    STONYB
            PLA
            AND    #$0F
STONYB      ORA    #'0'            ;hi-bit A2 ASCII
            CMP    #'9'+1
            BCC    STOSCR
            ADC    #$06
;
; Store a char into any video mem location
; User must set up the location b4 calling rtn
;
STOSCR      STA    $FFFF,Y         ;Self-modifying code
            INY
            RTS
;=================================================
; ($159A)
; Returns the format and length of the opcode
; Each opcode is of the form xxxx xxyy
; Three cases are considered since xxxx xx11 is invalid
; (1) xxxx xx00
; (2) xxxx xx10
; (3) xxxx xx01
; Case (1) & (2) will lead to
;  (A) = 00xx xxxx with C-bit=bit1 (which is 0 or 1)
; Case (3) will lead to
;  (A) = 0100 00xx with C-bit=bit2 (which is 0 or 1)
;  The original 01 will be in bit7,6
; bits5-7 are masked off
;
INSDIS      LDY    #0
            LDA    (MONPC),Y       ;get opcode
INSDIS1     LDX    #$FC            ;%1111 1100
            STX    AdrModSW
            LSR                    ;test bit 0 (A=0xxx xxxy) C-bit=y(bit0)
            BCC    L15AB
            ROR                    ;(A=10xx xxxx) C-bit=y(bit1)
            BCS    L15BA           ;opcode was xxxx xx11  -> invalid!
            AND    #%10000111      ;(A)=1000 0xxx mask bits
;
L15AB       LSR                    ;(A)=00xx xxxx or  0100 00xx (on fall thru)
            TAX                    ;C-bit=bit1 or bit2 (see comments above)
            LDA    FMT1,X          ;Get format index byte
            BCC    L15B6           ;Even, use low nybble
            LSR                    ;Odd, shift high nybble
            LSR
            LSR
            LSR
;
L15B6       AND    #$0F            ;mask 4-bits
            BNE    L15BF
L15BA       LDA    #$00            ;Set print format index to 0
            STA    AdrModSW
L15BF       TAX
            LDA    FMT2,X          ;Index into print format table
            STA    INSTFMT         ;Save for addr field formatting
            AND    #%00000011      ;Mask for 2-bit length
            STA    INSTLEN         ;0-1 byte, 1-2 bytes, 2-3 bytes
;
            TAY
L15CC       LDA    (MONPC),Y       ;Save instruction
            STA    INSTSV,Y
            DEY
            BPL    L15CC
            RTS
;=================================================
; ($15D5) Swap 16 zpage locations ($3A-$49)
; (Y) unchanged
; (X)=$FF
;
SwapZP      LDX    #15
L15D7       LDA    MONPC,X
            LDY    HOLDPZ,X
            STA    HOLDPZ,X
            STY    MONPC,X
            DEX
            BPL    L15D7
            RTS
;=================================================
; ($15E5) Save & Restore 6502's regs
;
SavRegs     PHP
            CLD
            STA    SAVEA
            STX    SAVEX
            STY    SAVEY
            PLA
            STA    SAVEP
            RTS
;
RstRegs     LDA    SAVEP
            PHA
            LDA    SAVEA
            LDX    SAVEX
            LDY    SAVEY
            PLP
            RTS
;=================================================
SVMONPC     LDA    MONPC
            STA    SVxZ3A
            LDA    MONPC+1
            STA    SVxZ3A+1
            RTS
;
RSTMONPC    LDA    SVxZ3A
            STA    MONPC
            LDA    SVxZ3A+1
            STA    MONPC+1
            RTS
;
CPY2IB      LDA    SLIN23,Y        ;Copy # of chars from cmdln
            STA    IBuff-1,Y       ; to input buffer
            DEY
            BNE    CPY2IB
            RTS
;=================================================
; Restore (INSTSV) to that of INSTBE
;
L1624       LDA    INSTBE
            STA    INSTSV
            LDA    INSTBE+1
            STA    INSTSV+1
            LDA    INSTBE+2
            STA    INSTSV+2
;
            LDA    L20F1           ;FORMAT of inst BE
            STA    INSTFMT
            AND    #%00000011
            STA    INSTLEN         ;len of instruction
            RTS
;=================================================
; Update the PC display
;
DMONPC      LDA    #<SLIN01
            STA    ScrLoc+1
            LDA    #>SLIN01
            STA    ScrLoc
            LDY    #11             ;scrn line offset
            LDA    MONPC+1
            JSR    PUTHEX
            LDA    MONPC
            JMP    PUTHEX
;=================================================
; Update regs display
;
DREGS       LDX    #1
            JSR    VTABX
            LDY    #17             ;display acc
            LDA    HACCUM
            JSR    PUTHEX
            INY
            LDA    HXREG           ;display X-reg
            JSR    PUTHEX
;
            INY
            LDA    HYREG           ;display Y-reg
            JSR    PUTHEX
;
            INY
            LDA    HSTAKP          ;display stack pointer
            JSR    PUTHEX
;
            INY
            LDA    HFLAGS          ;display processor flags
            JSR    PUTHEX
            INY
            LDA    HFLAGS
            JMP    DBINSTR         ;Display flags as 0s and 1s
;=================================================
; ($1680) Display the hexdec rep of (A)
; (A) - destroyed
; (Y) - horiz offset into screen line, incr by 1
; (X) - unchanged
; SrcLoc set prior to entry
;
PUTHEX      PHA
            LSR
            LSR
            LSR
            LSR
            JSR    PUTNYBZ
            PLA
PUTNYB      AND    #$0F            ;lower nybble
PUTNYBZ     ORA    #'0'
            CMP    #'9'+1
            BCC    L1693
            ADC    #$06
L1693       STA    (ScrLoc),Y
            INY
            RTS
;=================================================
; ($1697) Display (A) as a string of ASC 0's and 1's
; SrcLoc set prior to entry
;
DBINSTR     LDX    #8
L1699       ASL                    ;Shift bit into C
            PHA                    ;Save temporarily for later
            LDA    #%01011000
            ROL                    ;Now shift C into bit0
            STA    (ScrLoc),Y      ;1011 000c ($B0 or $B1)
            INY
            PLA                    ;recover
            DEX
            BNE    L1699           ;next bit
            RTS
;=================================================
; Show numbered line
; (A) index into table
; (A) & (X) unchanged
; (Y) incr by 1
; SrcLoc set prior to entry
;
DNbrdLin    STX    Z40             ;save (X) temporarily
            TAX
            DEX
L16AA       EQU    *
            LDA    LinNbrL,X       ;Get ASCII line #
            STA    (ScrLoc),Y      ; & show it
            INY
            LDA    LinNbrH,X
            STA    (ScrLoc),Y
            INX
            TXA
            LDX    Z40
            RTS