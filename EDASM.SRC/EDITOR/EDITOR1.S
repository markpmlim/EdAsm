Name          : EDITOR1.S
End of file   :   32,624
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;=================================================
; $0A,$0B - R5  - TxtBgn
; $0C,$0D - R6  - HiMem
; $0E,$0F - R7  - TxtEnd (last char of text buf being edited)
;=================================================
; UNLOCK cmd
;
LD282       SET    R1,$C2C2
            BR     LD28A
;
; LOCK cmd
;
LD287       SET    R1,$C200
LD28A       SET    R4,XBD80        ;PN is in $BD80 buf
            RTN
;
LD28E       LDA    #TXTtype
            JSR    XB883           ;Does file exist?
            BCC    LD298           ;Yes
LD295       JMP    XB602           ;Display err (A)=err code
;
LD298       JSR    LD29E
            JMP    XB1CB
;
; Modify the file attributes if necessary
;
LD29E       LDA    XBACA           ;File's curr access bits
            AND    Reg1+1
            CMP    Reg1            ;Change file's properties?
            BEQ    LD2C3           ;No
;
            LDY    #12
LD2A9       LDA    XBAC8,Y         ;$BAC8-$BAD4
            STA    XBADA,Y         ;$BADA-$BAE6
            DEY
            BPL    LD2A9
;
            LDA    Reg1+1
            EOR    #$FF            ;Change all 1's to 0's & vice-versa
            AND    XBACA
            ORA    Reg1
            STA    XBADC
            JSR    XB904           ;Change file's info
            BNE    LD295           ;Err
LD2C3       RTS
;=================================================
; DELETE cmd
;
LD2C4       SET    R1,$C2C2        ;Set access bits
            SET    R4,XBD80        ;Set ptr to PN
            RTN
;
            LDA    #TXTtype
            JSR    XB883           ;Get file's attributes
            BCS    LD295           ;File not found
            LDA    XBACA           ;Get file's curr access bits
            AND    #%11000010      ;Mask off B,R bits
            CMP    #%11000010      ;Are the D,N,W bits on?
            BEQ    LD2F4           ;Yes
;
            JSR    NEWSW16
            SET    R9,XB521        ;"File locked" msg
            RTN
            JSR    LD484           ;Prt msg
;
            JSR    LDD37           ;Get key
            PHA
            JSR    XB339           ;Do a CR
            PLA
            CMP    #'Y'
            BNE    LD305
;
            JSR    LD29E           ;Modify file's properties
LD2F4       LDA    XBAC8           ;Set ptr to pathname
            STA    XBAF4           ; to be destroyed
            LDA    XBAC8+1
            STA    XBAF4+1
            JSR    XB90B           ;Destroy it
LD303       BNE    LD295           ;Err
LD305       JMP    XB1CB
;=================================================
; RENAME cmd
; Both Old & New PathNames are in $BD80 buf
; separated/terminated by a null char ($00)
;
LD308       SET    R4,XBD80        ;Set ptr to PN
            LD     R4
            ST     R1
LD30D       LDI    R1              ;Search for null-separator
            BNZ    LD30D
            LD     R1
            ST     R2
            DCR    R2              ;Move back to point @ 0
            SET    R3,$FFFF        ;Count # of chars
LD316       INR    R3              ; in New PN
            LDI    R1              ;Look for the null-terminator
            BNZ    LD316
            RTN
;
            JSR    XB8B2           ;Setup FileNameB w/old PN
            JSR    NEWSW16
            SET    R1,XBAFB
            LD     R2              ;Get ptr to new PN and
            STD    R1              ; store it @ locations $BAFB-FC
            LD     R3              ;len byte
            STI    R2
            RTN
;
            JSR    XB912           ;Rename the file
            BNE    LD331           ;Err
            JMP    XB1CB
LD331       JMP    XB602
;=================================================
; Is this referenced?
;
            JSR    NEWSW16
LD337       SET    R9,XB427        ;Bad Format
            BR     LD33F
LD33C       SET    R9,XB420        ;Syntax
LD33F       RTN
            JSR    XB620           ;ERR
            JMP    XB198
;=================================================
; Print the line
;
LD346       BIT    PrintF          ;Print or List?
            BMI    LD34D
            JSR    LD491           ;Show line #
;
LD34D       LDA    #$FF
            STA    Z60
            LDA    #$01
            STA    Z7B
            LDY    #0
            LDA    (Reg9),Y        ;Is it a comment line?
            CMP    #'*'
            BEQ    LD361
            CMP    #'              ;'
            BNE    LD36B           ;No
;
LD361       LDA    #SPACE          ;Is tabchar a space?
            CMP    TabChar
            BNE    LD36B
            LDA    #$D0            ;Yes, ignore tab expansion
            STA    Z60             ; for comment lines
LD36B       DEY
;
; Print line loop
;
LD36C       INY
            LDX    PrColumn        ;curr prt col
            CPX    #79
            LDA    VideoSlt        ;=$C3 if 80-col card in slot 3
            BNE    LD377           ;No
            CPX    #39
LD377       BCC    LD386
;
            JSR    XB339           ;Do a cr
            LDA    #$D0            ;No tab expansion if
            STA    Z60             ; text line requires
            LDA    #6              ; multiple print lines
            STA    PrColumn
            STA    CH
;
LD386       LDA    (Reg9),Y        ;Get char
            STA    Z5E
            BPL    LD38E
            AND    #$7F
LD38E       CMP    TabChar
            BNE    LD3B3
            INC    Z60
            BMI    LD3B3           ;Ignore tab expansion
;
; Print reqd # of spaces for tabs
;
LD396       LDX    Z60             ;tab col
            CPX    #10
            BCS    LD3B1
            LDA    UserTabT,X      ;tabs
            SEC
            SBC    #1
            BMI    LD3B1
            CMP    PrColumn        ;curr prt col
            BCC    LD3B1
            BEQ    LD3B1
            LDA    #SPACE
            JSR    XB343
            JMP    LD396
;
LD3B1       LDA    Z5E             ;char
LD3B3       CMP    #CR
            BEQ    LD3FE
            CMP    #'              ;'
            BNE    LD3C5
            LDX    TabChar
            CPX    Z7B
            BNE    LD3C5
            LDX    TruncF
            STX    Z7B
LD3C5       LDA    Z5E
            LDX    Z7B
            BEQ    LD3F7
            STA    Z7B
            TAX
            BMI    LD3E0
;
            CMP    #SPACE          ;Is it a ctrl-char?
            BCS    LD3F4           ;No
            BIT    PrintF          ;List?
            BMI    LD3F4           ;No, send it to printer as is
            CMP    TabChar
            BNE    LD3EE
            LDA    #SPACE
            BNE    LD3F4           ;always
;
LD3E0       AND    #$7F
            CMP    TabChar
            BEQ    LD3EC
            CMP    #SPACE
            BCS    LD3F0           :Std ASCII
            BCC    LD3EE           ;$00-$1F -> $40-$5F
;
LD3EC       LDA    #%11100000      ;->$A0 (on fall thru)
LD3EE       EOR    #%01000000
LD3F0       LDX    #$3F
            STX    InvFlg
LD3F4       JSR    XB343
LD3F7       LDX    #$FF
            STX    InvFlg
            JMP    LD36C
;
LD3FE       JSR    XB343           ;Finish print line
            TYA                    ;Compute mem location
            SEC
            ADC    Reg9
            STA    Reg9
            LDA    #0
            ADC    Reg9+1
            STA    Reg9+1          ; of next txt line
            LDA    #CR
            RTS
;=================================================
; Add cmd
; (Reg12)=ptr to $BD00
;
LD410       LDD    R12             ;Was a line # issued w/cmd?
            BZ     LD418           ;No
            INR    R0              ;It's an INSERT, incr line #
            ST     R11             ; since we are adding after
            BRL    LD656
;
LD418       SET    R11,$FFFF
            RTN
;
            JSR    LD4D3           ;Get addr 1 past EO txtbuf
LD41F       JSR    LD44C           ;Get input line
            JSR    NEWSW16
            LD     R9              ;Compute end addr of
            ADD    R2              ; new line of text
            INR    R0
            CPR    R6              ;HiMem
            BC     LD446           ;Out of Mem
            RTN
;
LD42C       LDX    Reg2            ;Get input len
            INX
            LDY    #-1
LD431       INY
            LDA    InBuf,Y         ;Copy to txtbuf+1
            STA    (Reg9),Y
            DEX
            BNE    LD431
;
            JSR    NEWSW16
            LD     R9
            ADD    R2
            ST     R7              ;New TxtEnd
            INR    R0
            ST     R9              ;1 past new TxtEnd
            RTN
            JMP    LD41F           ;Loop back to add another line
;
LD446       SET    R9,XB432
            BRL    LD33F
;=================================================
; Get input line
; Output
;  Reg1 - Ptr to Inbuf
;  Reg2 - input len
;
LD44C       JSR    LD491           ;Print line #
            LDA    #$3F            ;'?'
            STA    Prompt
            JSR    LA710           ;Input line using cmd line rtn
            LDA    #0
            STA    Reg2+1
            LDA    #>InBuf
            STA    Reg1
            LDA    #<InBuf
            STA    Reg1+1
            INC    Reg11           ;Incr line #
            BNE    LD468
            INC    Reg11+1
;
LD468       STX    Reg2            ;# of chars entered
            LDA    InBuf           ;Get 1st char
            AND    #$7F
            CMP    #CR
            BEQ    LD47C
            CMP    #CTRLD
            BEQ    LD47C
            CMP    #CTRLQ
            BEQ    LD47C
            RTS
;
LD47C       PLA                    ;Dump ret addr
            PLA
            JMP    XB1CB           ;Ret to cmd level
;=================================================
; Print message
; Input
;  (Reg9) - ptr to CR-terminated message
;
LD481       JSR    LD491           ;Display # in dec form
LD484       LDY    #0
LD486       LDA    (Reg9),Y        ; followed by msg
            JSR    XB343
            INY
            CMP    #CR
            BNE    LD486
            RTS
;=================================================
; Print dec #
; Input
;  (Reg11)=16-bit value
;
LD491       LDY    #%00000101
            STY    Reg3
            JSR    NEWSW16
            SET    R4,LD4FA        ;Lookup table
            LD     R11             ;Use a copy of
            ST     R10             ; 16-bit value
LD49D       RTN
;
LD49E       JSR    NEWSW16
            SUB    R0              ;Zero the Acc
            ST     R2              ; and R2
            LDD    R4
            ST     R1
            LD     R10
LD4A6       SUB    R1
            BNC    LD4AD
            INR    R2
            ST     R10
            BR     LD4A6
LD4AD       RTN
;
            LDA    Reg2
            BNE    LD4BC
            BIT    Reg3
            BMI    LD4BC
            CPY    #$01
            BEQ    LD4BC
            LDA    #$10            ;->$20 on fall thru
LD4BC       EOR    #'0'
            JSR    XB343           ;Print char
            CMP    #'0'
            ROR    Reg3
            DEY
            BNE    LD49E
            LDA    #SPACE
            JMP    XB343           ;Done
;
LD4CD       SET    R9,XB43E        ;Bad range
            BRL    LD33F
;=================================================
; Input
; (Reg11)= Line #
; Output
;  (Reg9)=Addr of line
;
LD4D3       JSR    NEWSW16
            LD     R5              ;TxtBgn (Start addr of text buf)
            ST     R9              ;Set initial addr
            LD     R11             ;Get Line # and
            ST     R1              ; store it here
            SUB    R0              ;Zero ACC
            ST     R11             ; and this reg
LD4DC       INR    R11             ;Line counter
            DCR    R1              ;Are we done yet?
            BZ     LD4E4           ;Yes
            LD     R9
            CPR    R7              ;=TxtEnd
            BNC    LD4E6           ;Keep searching
LD4E4       RTN
            RTS
;
LD4E6       RTN
            LDY    #0
LD4E9       LDA    (Reg9),Y        ;Look for EOL (cr-terminated)
            INC    Reg9
            BNE    LD4F1
            INC    Reg9+1
LD4F1       CMP    #CR
            BNE    LD4E9
;
            JSR    NEWSW16
            BR     LD4DC           ;Incr the line count
;=================================================
LD4FA       DW     10000
            DW     1000
            DW     100
            DW     10
            DW     1
;=================================================
; KILL2 cmd
; Can be issued whichever txt buf is currently
; in use.
;
LD504       RTN
LD505       LDA    SwapMode
            LDX    #0              ;Deactivate split-buf mode
            STX    SwapMode
            CMP    #$01            ;Was text buf 1 active?
            BCC    LD51B           ;Normal non-split buf
            BNE    LD51E           ;No, buf2
;
            LDA    XBA33+2         ;Make txtbuf2 active
            STA    Reg6
            LDA    XBA33+3
            STA    Reg6+1
LD51B       JMP    XB1CB
LD51E       JMP    LD80D           ;Make txtbuf1 active
;=================================================
; NEW cmd
;  Clears the current text buffer
; Input
;  Reg5 - Points to 1st char of curr txtbuf
;  Reg7 - Points to last char of curr txtbuf
;  When Reg5 & Reg7 both point @ same location ->
;  the text buffer is empty.
;  When Reg5 points @ a pair of zeroes, an XLOAD
;  cmd was issued previously.
;
LD521       LD     R5
            ST     R2
            ST     R7              ;This will clear text buf
            SUB    R0              ;Zero Acc
            SET    R1,XBE00        ;Point @ curr PN
            STI    R1              ;Store a zero byte @ $BE00
            LDD    R2              ;Were we editing a text file?
            BNZ    LD52F           ;Yes
            POPD   R2              ;Load the double zero @ (Reg5) into ACC
            DCR    R0
            STD    R2              ;Store $FFFF there
LD52F       RTN
            JMP    XB1CB
;=================================================
; Print cmd
;
LD533       RTN
            LDA    #$FF
            STA    PrintF
            JSR    NEWSW16
            BRL    LD631
;=================================================
;
LD53E       JSR    NEWSW16
LD541       SET    R9,XB448        ;Invalid parm
            BRL    LD33F
;=================================================
; COLumn cmd
;
LD547       LD     R11             ;Get parm into SW16 Acc
            RTN
            LDA    Reg0
            LDX    #0
            CMP    #40
            BEQ    LD558
            CMP    #80
            BNE    LD53E
            JSR    LA75B           ;Chk if 80-col card present
;
; On fall thru (X)=$C3 if there is an 80-col card
; No 80-col card if (X)=0
;
LD558       LDA    DevCtlS         ;Get slot #
            BEQ    LD561
            CMP    #$03            ;ext 80-col card?
            BNE    LD567           ;No
;
LD561       TXA
            AND    #$0F
            STA    DevCtlS
;
LD567       JSR    LA78A           ;Reset I/O hooks
            JMP    XB1CB
;=================================================
; MON cmd
;
LD56D       RTN
            LDA    #$4C
            STA    USRADR
            LDA    #>XB198
            STA    USRADR+1
            LDA    #<XB198
            STA    USRADR+2
            LDA    VideoSlt        ;=$Cs
            JMP    XB393           ;Go MonZ
;=================================================
; TRunc Off
;
LD582       RTN
            LDA    #$FF
LD585       STA    TruncF
            JMP    XB1CB
;
; TRUNC On
;
LD58A       RTN
            LDA    #$00
            BEQ    LD585           ;always
;=================================================
; Where cmd
; Input
;  (Reg11)=line #
;
LD58F       RTN
            JSR    LD4D3           ;Get addr of line into Reg9
            JSR    LD491           ;Print line #
            LDA    #'='
            JSR    XB343
            LDA    #'$'
            JSR    XB343
            LDA    Reg9+1          ;Print addr as a hexdec str
            LDX    Reg9
            JSR    XB389
            JSR    XB339           ;Do a CR
LD5AA       JMP    XB1CB
;=================================================
; SET Delim cmd
; Change to command delimiter whose
; default is a colon.
;
LD5AD       RTN
            LDA    XBD80
            BEQ    LD5BB           ;If none, use the default
            CMP    #'Z'
            BCC    LD5BB
            CMP    #'a'
            BCC    LD5BD
LD5BB       LDA    #':'
LD5BD       STA    CmdDelim
            JMP    XB1CB
;=================================================
; Set UCase cmd
;
LD5C2       RTN
            LDA    #$80
            JSR    LA659
            JMP    XB1CB
;=================================================
; Set LCase cmd
;
LD5CB       RTN
            LDA    #$7F
            JSR    LA656
            JMP    XB1CB
;=================================================
; Get a line # or an interval of line #s
; The buffer $BD00 will contain the line # intervals
; each separated by a null char
; Callers of this subrtn will not get back control
; if there are no more line intervals. Instead,
; control will be transferred to EI's code @ $B1CB
; A double $FF will marks EO the intervals
; Input
;  (Reg12) - ptr to $BD00 buf
; Output
;  (Reg11) - first line #
;  (Reg8)  - last line #
;  (Reg9)  - addr of first line
;
LD5D4       JSR    NEWSW16
LD5D7       LDD    R12             ;Get first line # of curr interval
            ST     R11
            ST     R8
            BNM1   LD5E2
            RTN                    ;If -ve, no more line #s
            PLA                    ;Dump RTS addr
            PLA
            JMP    XB1CB           ;xfer control back to EI
;
LD5E2       BNZ    LD5E6           ;There is a start line #
            INR    R11             ;=$0001
            DCR    R8              ;=$FFFF
;
LD5E6       LDI    R12             ;Look for null-separator
            BNZ    LD5F1
            LDD    R12             ;Is there an end line #?
            BNZ    LD5EF           ;Yes
;
LD5EC       SET    R0,$FFFF        ;Set ACC to $FFFF
LD5EF       ST     R8              ;=$FFFF or specified end line #
            INR    R12             ;Skip next byte
;
LD5F1       LD     R8              ;Is end line # >=
            CPR    R11             ; start line #?
            BC     LD600           ;Yes
            SET    R1,100          ;Chk for relative range
            CPR    R1              ;Is it >= 100?
            BC     LD60D           ;Yes, err
            DCR    R0              ;Is it zero?
            BM1    LD60D           ;Yes, err
            ADD    R11
            ST     R8              ;End line #
LD600       RTN
;
            JSR    LD4D3           ;Get start addr into (Reg9)
LD604       JSR    NEWSW16
            LD     R9              ;Is addr >= TxtEnd?
            CPR    R7
            BC     LD5D7           ;Yes, ignore this range
            RTN
            RTS
;
LD60D       BRL    LD4CD
;=================================================
; Init the Printer
;
LD610       EQU    *               ;ENTRY
            LDA    DevCtlS         ;Slot # (1-7)
            BEQ    LD61D
            ORA    #$C0
            STA    CSWL+1
            LDA    #$00
            STA    CSWL
;
LD61D       LDY    #1
LD61F       INY
            LDA    DevCtlS,Y
            BEQ    LD62E
            LDA    DevCtlS,Y
            JSR    XB343
            JMP    LD61F
LD62E       JMP    XB339           ;Output CR and back to caller
;=================================================
; List cmd
; The following are valid
; List 3
; List 10-
; List 1,3,4-5
; List 10-2
;
LD631       INR    R5              ;TxtBgn
            INR    R5
            POPD   R5
            BNZ    LD639           ;There is a txt file
            BRL    LD6EC
;
; This will start the listing of a range of lines
;
LD639       RTN
            JSR    XB339           ;Do a cr
            JSR    LD5D4           ;Get line # range
;
; Print lines loop
;
LD640       JSR    LDD2E           ;Chk for a keypress
            JSR    LD346           ;Print line
            JSR    NEWSW16
            LD     R11             ;Curr line #
            INR    R11
            CPR    R8              ;Ending line #
            BC     LD639
            LD     R9              ;Curr location
            CPR    R7              ;TxtEnd
            BC     LD639
            RTN
            JMP    LD640
;=================================================
; Insert cmd
; Input
;  (Reg11) - line #
;
LD656       RTN
;
LD657       JSR    LD4D3           ;Get addr of line
LD65A       JSR    LD44C           ;Get input line
            JSR    LD663           ;Insert into txtbuf
            JMP    LD65A
;
; Input
;  Reg1 - Point @ location (within InBuf) to be copied
;  Reg9 - Point @ location within txtbuf where
;         text is to be inserted
;  Reg2 - # of bytes to copy/insert
;
LD663       JSR    LD672           ;Move rest of txt up in mem
            JSR    NEWSW16
            ST     R7              ;new TxtEnd
            INR    R9              ;Point @ dest
LD66B       LDI    R1              ;Move chars fr InBuf
            STI    R9              ; to txtbuf
            DCR    R2              ;decr len
            BNZ    LD66B
            RTN
            RTS
;=================================================
; Create room for insertion
;
LD672       JSR    NEWSW16
            INR    R2              ;input len/# of bytes of copy
            LD     R7              ;Save old TxtEnd
            ST     R10
            ADD    R2
            CPR    R6              ;HiMem
            BNC    LD67F
            BRL    LD446           ;Out of mem
LD67F       ST     R7              ;new TxtEnd (dest)
            DCR    R9
            RTN
            JMP    LD691           ;Make room for new line(s)
;=================================================
; Copy chars to the space created
;
LD685       JSR    NEWSW16
            ST     R7              ;TxtEnd
            INR    R9              ;addr of dest line
LD68A       LDI    R1              ;Get char and
            STI    R9              ; store it
            DCR    R2              ;Are we done?
            BNZ    LD68A           ;No
            RTN
            RTS
;=================================================
; Move contents of file up in mem
; Input
;  Reg7  - dest
;  Reg9  - BO src-1
;  Reg10 - src
;
LD691       LDY    #0
            LDA    (Reg10),Y
            STA    (Reg7),Y
            LDA    Reg7
            BNE    LD69D
            DEC    Reg7+1
LD69D       DEC    Reg7
;
            LDY    Reg10+1
            LDX    Reg10
            BNE    LD6A6
            DEY
LD6A6       DEX
            STX    Reg10
            STY    Reg10+1
;
            CPY    Reg9+1          ;Are we done?
            BEQ    LD6B1
            BCS    LD691
LD6B1       CPX    Reg9
            BEQ    LD6B7
            BCS    LD691           ;No
LD6B7       RTS
;
LD6B8       BRL    LD33C           ;err
;=================================================
; Del cmd
; More than an interval of line #s are accepted
; with the cmd but it's not recommended
;
LD6BB       RTN
LD6BC       JSR    LD6C2
            JMP    LD6BC           ;Proceed to do another interval
;
LD6C2       JSR    LD5D4           ;Get line #/line interval
            JSR    NEWSW16
            LD     R9              ;Get addr of start line #
            ST     R10             ; which is the dest addr
            LD     R8              ;End line #
            ST     R11
            INR    R11             ;Go past this line
            BZ     LD6B8           ; cannot be -1
            RTN
            JSR    LD4D3           ;Get its addr (src addr)
            JMP    L9C57           ;Move (txtbuf) down
;=================================================
; Replace cmd - equivalent to type Del followed
; by an Insert
;
LD6D6       LDD    R12             ;Get start line #
            BNZ    LD6DA
            INR    R0              ;If 0, make it 1
LD6DA       ST     R4              ;Save for Insert
            POPD   R12             ;Backup to BO buf @ $BD00
            RTN
            JSR    LD6C2           ;Perform a Del
            JSR    NEWSW16
            LD     R4
            ST     R11
            RTN
            JMP    LD657
;
LD6E9       BRL    LD446
;=================================================
; FILE cmd
; Called by SAVE on an empty txtbuf
; and List after an XLOAD
;
LD6EC       RTN
            JSR    XB339
            JSR    LA04E           ;Print filename
            JSR    NEWSW16
            LD     R7              ;Is txtbuf empty?
            SUB    R5
            BZ     LD6FB           ;Yes
            INR    R0
LD6FB       ST     R11             ;# of bytes used
            SET    R9,L9ED6
            RTN
            JSR    LD481
;
            JSR    NEWSW16
            LD     R6              ;Compute # of bytes free
            SUB    R7              ;=HiMem-TxtEnd
            ST     R11
            SET    R9,L9EE1
            RTN
            JSR    LD481
;
            LDY    #1
            LDA    (Reg5),Y        ;Is it a txtfile?
            BNE    LD768           ;Yes
            JSR    NEWSW16
            SET    R0,$0006
            ADD    R5              ;Compute # of bytes
            ST     R1
            LD     R7              ; used as non-text data
            INR    R0
            SUB    R1
            ST     R11
            SET    R9,L9EF1
            RTN
            JSR    LD481
;
            LDA    #SPACE
            JSR    XB343
            LDY    #$03
            LDA    (Reg5),Y        ;Is there an ASCII
            JSR    LA440           ; representation?
            BNE    LD74C           ;No
            DEY
            DEY
            JSR    L9C3C           ;Yes, print 3 chars
            JSR    L9C3C
            JSR    L9C3C
            JSR    NEWSW16
            SET    R9,L9F0D        ;Get msg ptr
            RTN
            JSR    LD484           ; and print msg
LD74C       LDA    #'$'
            JSR    XB343
            LDY    #5              ;Get load addr
            LDA    (Reg5),Y
            JSR    L9C43
            DEY
            LDA    (Reg5),Y
            JSR    L9C43
            JSR    NEWSW16
            SET    R9,L9F21
            RTN
            JSR    LD484
LD768       JMP    XB1CB
;=================================================
; SWAP cmd
; 1) Whether there are two files being edited or not,
; file buf1 will always start @ $801.
; 2) When file1 is edited, file2 will be stored
; downwards fr HiMem ($9900).
; 3) When file2 is edited, file1 will remain where
; it is. File2 will be moved to 1 mempage above
; the TxtEnd of file1.
; 4) When a SWAP cmd is issued and file buf1 is empty
; file2 becomes file1.
;
; Input
;  (SwapMode)-split-buf mode 0,1,2
; $B9EE-$BA32 - save area for file 1
; $BA33-$BA7B - save area for file 2
; The first four bytes of each area are the
; TxtBgn/TxtEnd of the respective files
; The next 65-byte are are their corr. filenames
; $BE00 - name of file currently being edited
;
LD76B       SET    R1,XB9EE
            SET    R2,SwapMode
            LDI    R2              ;Get split-buf mode byte @ SwapMode
            DCR    R0
            DCR    R0
            BNZ    LD779           ;Buf1 was used/Non-split buf
            SET    R1,XBA33        ;Buf2 was used
;
LD779       LD     R5              ;Get ptrs in (TxtBgn)
            STD    R1              ; & (TxtEnd) and
            LD     R7
            STD    R1              ; save'em @ $B9EE/$BA33 (4 bytes)
            SET    R2,XBE00        ;Point @ curr pathname
LD780       LDI    R2              ;Save pathname to 65-byte
            STI    R1              ; buf @ $B9F2/$BA37
            BNZ    LD780           ;Not EO PN yet
            RTN
;
            LDA    SwapMode        ;Were we
            CMP    #$01            ; editing file1?
            BEQ    LD7B1           ;Yes
            BCS    LD7E6           ;No, file2
            LDA    #$00            ;We had a non-split buf
            STA    XBE00           ; -> new file2
            JSR    LD798
            JMP    XB1CB
;=================================================
; Create a new file in txtbuf2
; Or swapping in txtbuf2
;
LD798       LDY    #2
            STY    SwapMode        ;Flag it
LD79C       INC    Reg7+1          ;Set BO txtbuf2
            LDY    Reg7+1          ; to 1 mem page
            STY    Reg5+1          ; above txtbuf1
            LDY    #0
            STY    Reg5
            STY    Reg7
            LDA    #CR
            STA    (Reg5),Y        ;Mark BOF w/cr
            INC    Reg5
            INC    Reg7
            RTS
;
; File1 is currently edited. We are swapping in
; txtbuf2.
;
LD7B1       LDA    Reg5            ;Is buf1 empty?
            LDX    #$02
            CMP    Reg7
            BNE    LD7C1
            LDA    Reg5+1
            CMP    Reg7+1
            BNE    LD7C1           ;No -> swap in txtbuf2
;
LD7BF       LDX    #0              ;No swapping since buf1 is empty
LD7C1       JSR    LD79C
            STX    SwapMode
            JSR    NEWSW16
            SET    R3,XBA33
            LDD    R3              ;BO txtbuf2
            ST     R9
            LDD    R3
            ST     R6              ;HiMem of txtbuf2
            DCR    R0
            ST     R7              ;EO txtbuf2
            LD     R5              ;New TxtBgn of txtbuf2
            ST     R10             ;Dest addr of txtbuf2
            RTN
            JSR    L9C57           ;Move contents of txtbuf2
;
            JSR    NEWSW16
LD7DB       SET    R2,XBE00        ;Copy PN to
LD7DE       LDI    R3              ; currPN buf
            STI    R2
            BNZ    LD7DE
            RTN
            JMP    XB1CB
;
; Swap in txtbuf1
;
LD7E6       JSR    NEWSW16
            LD     R5              ;TxtBgn
            ST     R9
            DCR    R9
            LD     R7              ;TxtEnd
            ST     R10
            LD     R6              ;HiMem
            ST     R7
            DCR    R7
            RTN
;
            JSR    LD691
            JSR    NEWSW16
            SET    R2,XBA33
            INR    R7              ;Now BOF
            LD     R7
            STD    R2
            LD     R6              ;HiMem
            STD    R2
            RTN
;
            LDY    Reg7+1
            DEY
            STY    Reg6+1          ;HiMem of txtbuf1
            LDY    #$01
            STY    SwapMode        ;editing txtbuf1
            DEY
            STY    Reg6            ;=0
;
LD80D       JSR    NEWSW16
            SET    R3,XB9EE        ;txtbuf1
            LDD    R3
            ST     R5              ;TxtBgn
            LDD    R3
            ST     R7              ;TxtEnd
            BR     LD7DB
;=================================================
; COpy cmd
; The dest line must not fall between first line
; and last line
; 2 cases:
; 1) Dest line is before 1st line
; 2) Dest line is after 1st line
;
LD819       LDD    R12             ;Get 1st line #
            ST     R11
            RTN
            JSR    LD4D3           ;Get its addr
            JSR    NEWSW16
            LD     R9
            CPR    R7              ;Is it > TxtEnd?
            BC     LD82E           ;Yes
            ST     R8
            LDD    R12             ;Is there a last line #?
            BNZ    LD82B           ;Yes
            LD     R11             ;Copying 1 line
LD82B       CPR    R11
            BC     LD831
LD82E       BRL    LD4CD           ;Range err
;
LD831       ST     R11             ;last line #
            INR    R11             ;Next line
            RTN
;
            JSR    LD4D3           ;Get addr of next line
            JSR    NEWSW16
            LD     R9
            ST     R3
            SUB    R8
            ST     R10             ;# of chars to copy
LD83E       LDD    R12             ;Get dest line #
            ST     R11
            RTN
            JSR    LD4D3           ;Get its addr
            JSR    NEWSW16
            LD     R9              ;Ensure addr of destline is not
            CPR    R3              ; within addr of lastline+1
            BZ     LD852
            BC     LD852
            CPR    R8              ; and addr of firstline
            BZ     LD852
            BC     LD82E           ;Err
;
; R9 - addr of destline (set by above code)
; R1 and R2 must be set properly
; before the rtns below are called
; R1 - src addr of copy
; R2 - # of bytes to move
;
LD852       LD     R8              ;Is addr of 1stline
            CPR    R9              ; < addr of destline?
            BNC    LD857           ;Yes (case 2)
            ADD    R10
LD857       ST     R1
            LD     R10             ;# of chars to copy
            ST     R2
            DCR    R2
            RTN
            JSR    LD672           ;Create room in txtbuf
            JSR    LD685           ; before doing the copy
            JMP    XB1CB
;=================================================
; Find cmd
;
LD865       RTN
            JSR    LD5D4           ;Get line #/line interval
LD869       JSR    LD87A           ;Search
            JSR    LD346           ;Print the line
            JSR    NEWSW16
            INR    R11
            RTN
            JSR    LDD2E           ;If ctrl-C, don't come back
            JMP    LD869           ;Next line
;=================================================
; Search for a line which has a match within
; current interval of line #s. It will return
; to caller if a match is encountered. Otherwise
; control will be transferred back to EI @ $B1CB
; Output
;  Reg2 - addr where a subsequent search will begin
;  Reg9 - addr of line which has a match
;  Reg4 - start addr of matched str
;  Reg11- curr line #
;
LD87A       JSR    NEWSW16
LD87D       SET    R3,CR
            SET    R10,XBD80       ;Ptr to search string
            SET    R2,CTRLA        ;Wild card char
            LD     R9              ;Get start addr of search
            ST     R4              ; & save it here
            CPR    R7              ;Are we @ eo txtbuf? (TxtEnd)
            BC     LD8AF           ;Yes, done w/this interval
            LD     R8              ;Is end line #
            CPR    R11             ; < curr line #?
            BNC    LD8AF           ;Yes, done
;
LD88F       LDI    R10             ;Get char fr parm string
            BZ     LD8B6           ;eos -> complete match
            ST     R1              ;Save char
            LDI    R9              ;Get char fr line
            CPR    R3              ;Is it a CR?
            BNZ    LD8A3           ;No
            INR    R11             ;Next line of text
            RTN
;
            LDA    KBD
            CMP    #CTRLC+$80
            BNE    LD87A
            JMP    LDD2E           ;Don't come back
;
LD8A3       CPR    R1              ;Compare against char fr parm string
            BZ     LD88F           ;Match, try next pair of chars
            LD     R1              ;Get back char
            CPR    R2              ;Is it the wild card?
            BZ     LD88F           ;Considered a match
;
            LD     R4              ;Restore start
            ST     R9              ; addr of search
            INR    R9              ;Move search addr forward by 1
            BR     LD87D
;
LD8AF       RTN
            JSR    LD5D4           ;Is there another line interval?
            JMP    LD87A           ;Yes
;
LD8B6       LD     R9              ;Got a hit
            ST     R2              ;Save for a later search
            RTN
;
; Now we search for the start addr of the line
; containing the matched string
;
LD8B9       JSR    NEWSW16
            SET    R3,CR
LD8BF       POP    R9              ;Move back until
            CPR    R3              ; CR is found
            BNZ    LD8BF
            INR    R9              ;Point @ 1st char of line
            RTN
            RTS
;=================================================
; Change cmd
; Like Find, this cmd accepts several line #
; intervals. There must be an oldstr at least 1
; char long
;  (Z62)=vert Tab
;  (Z63)=msb off (All)
;  (Z67)-
;
LD8C6       SET    R10,XBD80
            LDI    R10             ;Is there an oldstr?
            BNZ    LD8CF
            BRL    LD337           ;No, err
;
LD8CF       SET    R9,XB45B        ;'All or Some' msg
            RTN
            JSR    LD484           ;Print it
            JMP    LD8DC
;
LD8D9       JSR    XB375           ;Ring...
LD8DC       JSR    LDD37           ;Get key
            CMP    #'S'
            BEQ    LD8E8
            CMP    #'A'
            BNE    LD8D9           ;Try again
            CLC
LD8E8       ROR    Z63             ;msb=0 if All
            JSR    LD5D4           ;Get line # interval
            LDX    CV
            CPX    #23
            BCC    LD8F4
            DEX
LD8F4       STX    Z62
            LDA    #$FF
            STA    Z67
            BNE    LD8FC           ;always
LD8FB       EQU    *-1             ;RTN
;
LD8FC       JSR    LD87A           ;Do we have a line w/a match?
            JSR    NEWSW16         ;Yes
            SET    R1,InBuf
LD905       LD     R9              ;Are we pointing @
            CPR    R4              ; the matched str?
            BZ     LD90D
            LDI    R9              ;No, copy char to
            STI    R1              ; the InBuf
            BR     LD905
;
; Reg10-Pointing @ replacement str
; A replacement string can contain "nothing"
; In which case, the matched str will be
; deleted from the line
;
LD90D       LDI    R10             ;Do we have a replacement str?
            BZ     LD913           ;No
            STI    R1              ;Copy it to InBuf until EO
LD911       BR     LD90D           ; replacement str encountered
;
LD913       LD     R1              ;Point 1 past repstr within InBuf
            ST     R10             ;Save for later
LD915       LDI    R2              ;Now copy rest of line
            STI    R1              ; to InBuf
LD917       CPR    R3              ;=CR
            BNZ    LD915
;
            SET    R9,InBuf
            INR    R4              ;Point 1 past addr of matched str
            LD     R4              ;Load ptr into SW16 ACC
            SET    R1,Z7E
            STD    R1              ;(Z7E)-point @ 1 past matched str
            LD     R10
            STD    R1              ;(Z80)-point @ 1 past repstr
            RTN
;
            LDA    CV
            PHA
            JSR    LDB28           ;Display modified text line
            PLA
            CMP    CV
            BCS    LD933
            STA    Z62
LD933       JSR    NEWSW16
            SET    R1,Z7E
            LDD    R1
            ST     R9              ;=(Z7E)
            LDD    R1
            ST     R10             ;=(Z80)
            RTN
            BIT    Z63             ;Rep All?
            BPL    LD95A           ;Yes
;
LD942       JSR    LD972           ;Prompt for Y/N
            CMP    #CTRLC
            BNE    LD94C
            JMP    XB1CB           ;Abort
LD94C       CMP    #'Y'
            BEQ    LD95A
            CMP    #'N'
            BEQ    LD8FC
            JSR    XB375           ;Ring...
            JMP    LD942
;
; Replace the old line
;
LD95A       JSR    LD8B9           ;Point @ BOL w/matched str
            JSR    NEWSW16
            LD     R10             ;Compute len of substr
            SET    R10,InBuf
            SUB    R10             ; w/rep str @ its end
            ADD    R9              ;Compute addr where to
            ST     R4              ; start next search
            RTN
            JSR    LDAEE
            JSR    NEWSW16
            LD     R4
            ST     R9
            BR     LD8FB           ;Continue search and replace
;=================================================
; Display 'Y/N' and get user's response
;
LD972       LDA    #'Y'
            JSR    XB343
            LDA    #'/'
            JSR    XB343
            LDA    #'N'
            JSR    XB343
            JSR    LDD37           ;Getkey
            PHA
            JSR    LD990           ;Do BS thrice
            JSR    XB37F           ;Print a space
            JSR    LD990
            PLA
            RTS
;
LD990       LDA    #BS+$80
            JSR    XB343
            JSR    XB343
            JMP    XB343
;=================================================
; Copy pathname fr $BD80 buf to Curr filename buf
; including the terminating 0
;
LD99B       SET    R2,XBD80
            SET    R10,XBE00
LD9A1       LDI    R2              ;Get 1 byte at a time
            STI    R10             ; and store it
            BNZ    LD9A1           ;Not null-terminator yet
            RS
;=================================================
; Append cmd
; A optional line # may precede the pathname
;
LD9A6       SET    R4,XBD80        ;Set to PN
            LDD    R12             ;Was a line # issued w/cmd?
            BNZ    LD9BF           ;Yes
            SET    R0,$FFFF        ;Append to EO txtbuf
            BR     LD9BF
;
; Load cmd-equivalent to an APPEND cmd
; with line #1
;
LD9B1       SET    R12,XBA78       ;Useless instr
            BS     LD99B           ;Copy PN to curr PN buf
            SET    R12,XBD00       ;Not used
            SET    R0,$0001        ;Replace all lines from line #1
            SET    R4,XBE00        ;Ptr to Curr PN buf
;
; Code common to Append & Load
; If (Reg11) = -1($FFFF) => Append @ EO text buf
;            = 1         => Load cmd
; Any other value in (Reg11) is treated as a
; line #. The Editor first deletes that line and
; all lines that follow it in the text buffer
; then appends the contents of the specified
; text file
;
LD9BF       ST     R11             ;=$FFFF,$0001,line #
            RTN
            JSR    LD4D3           ;Get start addr of the line
            LDX    #TXTtype
LD9C6       JSR    LoadFile        ;Also called by XLOAD
            BCS    LD9E6           ;Read errs
;
LD9CB       LDA    XBA8A           ;Load addr
            CLC
            ADC    XBA8E           ;# of bytes actually read
            TAX
            LDA    XBA8A+1
            ADC    XBA8E+1
            TAY
            TXA
            BNE    LD9DE
            DEY
LD9DE       DEX
            STX    Reg7            ;Last byte of
            STY    Reg7+1          ; file's data in mem
            JMP    XB1CB
LD9E6       JMP    XB602
;=================================================
; $D9E9
; Input
;  Reg9 - Load addr
;  Reg6 - Top of free space (HiMem)
;
LoadFile    EQU    *
            LDA    Reg9            ;Load addr
            STA    XBA8A           ; is the Data buf
            LDA    Reg9+1
            STA    XBA8A+1
            SEC
            LDA    Reg6            ;HiMem (=$9900)
            SBC    Reg9
            STA    XBA8C           ;# of bytes to read
            LDA    Reg6+1
            SBC    Reg9+1
            STA    XBA8C+1
            TXA                    ;ftype
            JMP    XB937           ;Open and Read the file
;=================================================
; SAVE cmd
; Save an entire text file or a range of lines
; Input
;  Reg7 (TxtEnd) - Point to last char of file in mem
;  Reg5 (TxtBgn) - Point to 1st char of file
;  $BD80 - buffer containing filename
;
LDA06       LD     R7              ;Do we have an empty
            CPR    R5              ; edit buffer?
            BNZ    LDA0D           ;No
            BRL    LD6EC
;
LDA0D       SET    R10,XBD80
            SET    R12,XBA78       ;Set SW16 subrtn ret addr stack
            LDI    R10             ;Did user include a filename?
            BZ     LDA18           ;No
            BS     LD99B
;
LDA18       SET    R12,XBD00       ;Point @ line range
            SET    R4,XBE00
            RTN
            LDA    XBE00           ;Is there an old PN?
            BNE    LDA2D           ;Yes
;
            JSR    NEWSW16
            SET    R9,XB40A        ;missing FN/PN
            BRL    LD33F
;
LDA2D       LDY    #0
            LDA    (Reg12),Y       ;Did user specify a
            INY
            ORA    (Reg12),Y       ; start line #?
            BNE    LDA45           ;Yes
            INY
            LDA    (Reg12),Y       ;Ending line #?
            BEQ    LDA45
;
            JSR    NEWSW16
            LD     R5              ;TxtBgn
            ST     R10
            LD     R7              ;TxtEnd
            ST     R9
            INR    R9
            BR     LDA59
;
LDA45       JSR    LD5D4
            JSR    NEWSW16
            LD     R9              ;Addr of line
            ST     R10
            LD     R8              ;Ending line #
            ST     R11
            BM1    LDA52
            INR    R11
LDA52       RTN
;
            JSR    LD4D3
            JSR    NEWSW16
;
LDA59       LD     R9              ;Addr of line
            SUB    R10
            ST     R9              ;# of bytes to write
            RTN
            LDA    #TXTtype
            JSR    LDA65
LDA62       JMP    XB1CB
;=================================================
; Input
;  (A)=ftype
;  (Reg4)  - Ptr to PN
;  (Reg9)  - # of bytes to write
;  (Reg10) - Ptr to Data buf
;
LDA65       JSR    XB883           ;Is the file there?
            BCS    LDA6F           ;No
            BEQ    LDA9F           ;Yes and ftype is correct
            JMP    XB602           ;Err
;
; The file must be created first since it does not exist
;
LDA6F       LDA    XBAC8
            STA    XBAE8           ;Ptr to PN
            LDA    XBAC8+1
            STA    XBAE8+1
            LDA    FileType
            STA    XBAEB
            LDA    #$C3
            STA    XBAEA           ;Access bits
            LDA    #$00
            STA    XBAEC           ;auxtype
            STA    XBAEC+1
            JSR    XB919           ;Create file
            BEQ    LDA95
            JMP    XB602           ;Err
;
LDA95       LDX    #>XA900
            LDY    #<XA900
            JSR    XB8CE           ;Open the file
            JMP    LDABC
;
; File is there; overwrite
;
LDA9F       LDX    #>XA900
            LDY    #<XA900         ;1024-byte I/O buf
            JSR    XB8CE           ;Open the file
            LDA    XBA80           ;# of free pages
            STA    XBA8C           ;read len
            LDA    XBA80+1
            STA    XBA8C+1
            JSR    XB966           ;Is the old file too large?
            BCC    LDABC           ;No
            LDA    #$12
LDAB9       JMP    XB5FF
;
; Prepare to write to file
;
LDABC       LDA    Reg10
            STA    XBA92           ;data buf
            LDA    Reg10+1
            STA    XBA92+1
            LDA    Reg9
            STA    XBA94           ;# of bytes to write
            STA    XBAB6           ;Mark EOF
            LDA    Reg9+1
            STA    XBA94+1
            STA    XBAB6+1
            LDA    #0
            STA    XBAB6+2         ;At most 64K
            JSR    XB920           ;Write file
            BNE    LDAB9
;
            LDA    XBA91           ;write ref #
            STA    XBAB5           ;Seof ref #
            JSR    XB927           ;Set EOF
            BNE    LDAB9
            JMP    XB8EF           ;Close the file
;=================================================
LDAEE       JSR    NEWSW16
            SET    R1,InBuf        ;Point @ InBuf
            SET    R3,CR
LDAF7       LDI    R9              ;Get char fr old line
            DCR    R9
            CPR    R3              ;Is it a CR?
            BZ     LDB03           ;Yes, done
            LDI    R1              ;Get char fr modified line (InBuf)
            CPR    R3              ;Are we @ EOL?
            BZ     LDB16           ;Yes
            STI    R9              ;Copy over char
            BR     LDAF7           ;Continue copy
;
; Old line is shorter
;
LDB03       LDI    R1              ;Get next char fr InBuf
            CPR    R3              ;Is it a CR?
            BZ     LDB26           ;Yes -> both str have same len
            DCR    R1
            LD     R1              ;Get addr of rest of InBuf to
            ST     R10             ; copy & save it here
            SET    R2,$FFFE        ;-2
LDB0D       LDI    R10             ;Get next char fr InBuf
            INR    R2
            CPR    R3              ;Is a CR?
            BNZ    LDB0D           ;No, keep looking
            RTN
            JMP    LD663           ;Insert rest of InBuf into txtbuf
;
; Modified line is shorter
;
LDB16       LD     R9              ;Get addr of rest of oldline
            ST     R10             ; to overwrite & save it here (dest)
LDB18       LDI    R9              ;Get char fr old line
            CPR    R3              ;Is it a CR?
            BNZ    LDB18           ;No
            DCR    R9              ;Now pointing @ CR of oldline (src)
            RTN
            JSR    L9C57           ;Move rest of txtbuf down
            JSR    NEWSW16
            LD     R10
            ST     R9              ;Addr where next search will continue
LDB26       RTN
            RTS
;=================================================
LDB28       LDA    Reg11           ;Curr line #
            CMP    Z66             ;???
            STA    Z66
            BEQ    LDB37
            LDA    Reg11+1
LDB32       STA    Z66+1
            JMP    LDB42
;
LDB37       LDA    Reg11+1
            CMP    Z66+1
            BNE    LDB32
            LDA    Z62
            JSR    LDB4A
LDB42       LDA    #$1D            ;ctrl-] (clrEOL)
            JSR    XB343
            JMP    LD346           ;Print line
;
LDB4A       STA    CV
            JSR    XB36B           ;Do a VTab
            LDA    #$00
            STA    PrColumn        ;char posn
            RTS
;=================================================
; Edit cmd
; The cmd Edit begin#-end#.string. can be used
; to modify those lines within an interval of
; lines with the specified search string.
; If no search string included, then it is
; assumed a null string is passed.
;
LDB54       RTN
            JSR    LD5D4           ;Get line # interval
LDB58       JSR    LD87A           ;Get a line to edit, search if necessary
            LDA    TruncF
            STA    Z7A
            LDA    #$FF
            STA    TruncF
            JSR    LDB73
            LDA    Z7A
            STA    TruncF
            JSR    NEWSW16
            INR    R11
            INR    R9
            RTN
            JMP    LDB58
;=================================================
; Input
;  (Reg9)-addr of line to be edited
;
LDB73       LDA    #$FF
            STA    Z67
            LDA    PrColumn
            BEQ    LDB81
            JSR    XB339           ;Do a CR
            JMP    LDB73
;
LDB81       LDA    CV
            STA    Z62
            CMP    #21
            BCC    LDB98
            LDA    #23
            JSR    LDB4A
            JSR    XB339
            LDA    #21
            STA    Z62
            JSR    LDB4A
;
LDB98       JSR    NEWSW16
            SET    R1,InBuf
            SET    R2,CR
            LD     R9              ;Get addr of line
            ST     R3
LDBA3       LDI    R3              ;Move (line) including
            STI    R1              ; CR to InBuf
            CPR    R2
            BNZ    LDBA3
            RTN
;
            LDA    Reg9            ;Save line's addr
            PHA
            LDA    Reg9+1
            PHA
            JSR    LDBBD           ;Edit the line
            PLA
            STA    Reg9+1
            PLA
            STA    Reg9
            BCS    LDB98           ;Line was not changed
            JMP    LDAEE           ;Save changes to txtbuf
;=================================================
; Edit the line
; Output
;  C=0 - line was modified
;
LDBBD       LDY    #$00
            STY    Z65
            STY    Z64
LDBC3       LDA    #>InBuf
            STA    Reg9
            LDA    #<InBuf
            STA    Reg9+1
            LDY    Z65             ;Curr posn of cursor
            LDA    InBuf,Y
            PHA
            CMP    #CR
            BNE    LDBDA
            STA    InBuf+1,Y
            LDA    #SPACE
LDBDA       ORA    #$80
            STA    InBuf,Y
            JSR    LDB28           ;Display the line
            LDY    Z65
            PLA
            STA    InBuf,Y
LDBE8       JSR    LDCB8           ;Get valid char fr kbd
            LDY    Z65
            CMP    #SPACE
            BCC    LDC18           ;ctrl-char
            CMP    #DEL
            BEQ    LDC4C
LDBF5       BIT    Z64             ;Insertmode?
            BPL    LDC08           ;No, proceed to store it
;
            PHA                    ;Yes, so save char first
LDBFA       LDY    #255
LDBFC       DEY
            LDA    InBuf,Y         ;Move all chars right
            STA    InBuf+1,Y
            CPY    Z65             ; fr this posn
            BNE    LDBFC
            PLA
;
LDC08       STA    InBuf,Y
LDC0B       INY
            BEQ    LDC10           ;Too many chars
LDC0E       STY    Z65
LDC10       LDA    #CR
            STA    InBuf+255
            JMP    LDBC3
;
; Here we deal w/ctrl chars
;
LDC18       CMP    #CTRLV
            BNE    LDC29
LDC1C       LDA    KBD
            BPL    LDC1C
            BIT    KBDSTROBE
            LDY    Z65
            JMP    LDBF5
;
LDC29       LSR    Z64             ;Clear insert mode
            CMP    #CTRLU
            BNE    LDC3D
            LDA    InBuf,Y
            CMP    #CR
            BNE    LDC0B
            LDA    #SPACE
            STA    InBuf,Y
            BNE    LDC0B           ;always
LDC3D       CMP    #BS
            BNE    LDC48
            TYA
            BEQ    LDBE8
            DEY
            JMP    LDC0E
;
LDC48       CMP    #CTRLD
            BNE    LDC58
LDC4C       LDA    InBuf+1,Y       ;Delete char under cursor
            STA    InBuf,Y
            INY
            BNE    LDC4C
            JMP    LDBC3
;
LDC58       CMP    #CTRLF
            BNE    LDC74
            JSR    LDCB8           ;Get a key
LDC5F       INY                    ;Move forward
            CMP    InBuf,Y
            BEQ    LDC0E           ; until we got a hit
            PHA
            LDA    InBuf,Y         ;Is EOL encountered first?
            CMP    #CR
            BNE    LDC71           ;No
            PLA
            JMP    LDBE8           ;Move cursor to EOL
LDC71       PLA
            BNE    LDC5F           ;Keep moving forward
;
LDC74       CMP    #TAB            ;CTRLI
            BNE    LDC7D
            ROR    Z64             ;Flag insert mode
            JMP    LDBE8
;
LDC7D       PHA
            LDA    #$00
            STA    Reg9
            PLA
            LDY    Z65
            CMP    #CTRLT          ;Truncate line @ cursor?
            BEQ    LDCAE
            CMP    #CTRLR          ;Restore original line?
            BNE    LDC92
            JSR    LDB28           ;Yes, display it
            SEC
            RTS
;
LDC92       CMP    #CR
            BEQ    LDCB3
            CMP    #CTRLX          ;Cancel Edit mode?
            BEQ    LDCA0           ;Yes
            JSR    XB375           ;Ring...
            JMP    LDBE8
;
LDCA0       JSR    LDB28
            LDA    Z7A
            STA    TruncF
            PLA                    ;Prepare to
            PLA
LDCA9       PLA
            PLA
            JMP    XB1CB           ; ret to cmd level
;
LDCAE       LDA    #CR
            STA    InBuf,Y
LDCB3       JSR    LDB28
            CLC
            RTS
;=================================================
; Get valid char
;  (A)-valid char
;
LDCB8       LDA    KBD
            BPL    LDCB8
            BIT    KBDSTROBE
            JSR    LA668           ;Chk if key is valid
            BCS    LDCB8           ;No, ignore
            LDY    Z65
            RTS