Name          : EDITOR3.S
End of file   :   34,353
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            ORG    $9900
;
; Parse cmd line for dec string
; Convert to a 16-bit unsigned val
; Stops process on a non-dec char
;
; Output
;  C=0 - Conversion was done and
;  (Reg11)=16-bit value
;  C=1 - No conversion
;
L9900       LDA    #0
            STA    Reg11
            STA    Reg11+1
            LDA    Z12             ;Get char
            JSR    L996D           ;Convert if dec digit
            BCS    L9958           ;Not dec
            STA    Reg11
            STA    L996C
L9912       JSR    XB274           ;Get next non-blank char
            JSR    L996D
            BCS    L9957           ;Not a dec digit
;
            STA    Reg4            ;(A)=0-9
            ORA    L996C
            STA    L996C
            LDA    Reg11
            STA    Reg0
            CMP    #$98            ;Max val < 65520
            LDA    Reg11+1
            STA    Reg0+1
            SBC    #$19
            BCS    L99A5           ;Overflow
;
            ROL    Reg0            ;x4
            ROL    Reg0+1
            ROL    Reg0
            ROL    Reg0+1
;
            LDA    Reg0            ;x5
            CLC
            ADC    Reg11
            STA    Reg11
            LDA    Reg0+1
            ADC    Reg11+1
            STA    Reg11+1
            ROL    Reg11           ;x2
            ROL    Reg11+1         equi to mulby10
;
            CLC                    ;Add incoming digit
            LDA    Reg4
            ADC    Reg11
            STA    Reg11
            BCC    L9954
            INC    Reg11+1
L9954       JMP    L9912           ;Next digit
;
L9957       CLC
L9958       RTS
;=================================================
L9959       JSR    L9900           ;Convert dec string
            BCS    L9964
            LDA    L996C           ;Was a string of 0's entered?
            BEQ    L9965           ;Yes
            CLC
L9964       RTS
;
L9965       LDX    #$58            ;Bad Line #/Range
            PLA
            PLA
            JMP    XB290           ;err msg
;
L996C       DB     $C0             ;Flag
;=================================================
; Input
;  (A) char
; Output
;  C=0 if decimal char and (A)= 0-9
;  C=1 not a decimal char
;
L996D       CMP    #'9'+1          ;Is char '0'-'9'?
            BCS    L9979
            CMP    #'0'
            BCC    L9979           ;No
            AND    #$0F            ; --> 0-9
            CLC
            RTS
L9979       SEC
            RTS
;=================================================
; Save (Reg11) into $BD00/$BD80 buf
;
L997B       LDA    Reg11
            JSR    L9982
            LDA    Reg11+1
L9982       EQU    *
            LDY    #0
            STA    (Reg12),Y
            INC    Reg12
            BNE    L998C
            INC    Reg12+1
L998C       RTS
;=================================================
; If there is no dec/hexdec str issued with cmd
; then ($BD00-$01)=$0000
;
L998D       JSR    L9959           ;Convert &
L9990       JSR    L997B           ; store
            DEX
            JMP    XB211
;
L9997       JSR    L9900           ;Convert dec string
            JMP    L99A0           ;Chk if parm is mandatory
;
L999D       JSR    L9959           ;Get mandatory dec #
L99A0       BCC    L9990           ;Yes, proceed to store it
;
L99A2       LDX    #$1C            ;Parms omitted
            DB     $2C
L99A5       LDX    #$0B
L99A7       JMP    XB290
;=================================================
L99AA       JSR    L99CD           ;(Reg12)=ptr to $BD80 buf
;
L99AD       JSR    L9A18           ;Copy parm as it
            JMP    XB211
;=================================================
L99B3       JSR    L9A18           ;Copy 1st reqd parm
            BCC    L99A2           ;Err if not parm's not passed
            JSR    L9A1E           ;Copy 2nd optional parm
            JMP    XB211
;=================================================
L99BE       LDA    #CR             ;Set CR to be
            STA    Z12             ; the end
            DEX
            LDY    #33
            STY    Z10
            JSR    L9A22           ;Copy parm as is
            JMP    XB211
;=================================================
; Output
;  (Reg12) - ptr to $BD80
;
L99CD       LDA    #>XBD80         ;SET R12,$BD80
            STA    Reg12
            LDA    #<XBD80
            STA    Reg12+1
            RTS
;=================================================
; Parse cmd line for pathname and store it
; @ the $BD80 buf
;
L99D6       LDA    Z12
            CMP    #CR
            BEQ    L99A2
L99DC       CMP    #','
            BEQ    L99A2
            JSR    L99CD           ;Set (Reg12)=$BD80
L99E3       LDY    #63
            STY    Z10             ;cnt down
            LDY    #','
            STY    Z12             ;Stop on this delimiter
            DEX
            JSR    L9A22           ;Save next part of input line to buf @ $BD80
            BCC    L99F2
            DEX                    ;Push back
L99F2       JMP    XB211
;=================================================
L99F5       LDA    Z12
            CMP    #CR
            BNE    L99DC
;
            JSR    L99CD           ;Set (Reg12)=$BD80
L99FE       JSR    L9A38           ;Store 0 as delimiter into $BD80 buf
            JMP    XB211
;
L9A04       LDA    Z12
            CMP    #CR
            BEQ    L99FE
            BNE    L99E3           ;always
;=================================================
; Char must be CR
;
L9A0C       LDA    Z12
            CMP    #CR
            BNE    L9A15
            JMP    L99A2           ;err
L9A15       JMP    L99E3
;=================================================
; Copy parm fr Inbuf to $BD80 buf
; (X)-curr index in InBuf
; Z10-max # of chars to copy
;
L9A18       LDA    Z12
            CMP    #CR
            BEQ    L9A38
L9A1E       LDY    #0
            STY    Z10
L9A22       LDA    InBuf,X
            INX
            CMP    #CR
            BEQ    L9A38           ;EO cmd
            CMP    Z12             ;Delimiter (either comma or CR)
            BEQ    L9A3A           ;Stop on this
            JSR    L9982           ;Store char in buf
            DEC    Z10
            BNE    L9A22
;
L9A35       JMP    XB28E           ;Cmd Syntax
;
L9A38       DEX                    ;Push back
            CLC
L9A3A       LDA    #0              ;Terminate w/zero
            JMP    L9982
;=================================================
; For parsing several intervals of line #'s
;  Z7D = -1,0,1
;
L9A3F       LDA    #32             ;Max cnt
            STA    Z10
            LDY    #1
            STY    Z7D
            BNE    L9A50           ;always
;
L9A49       LDY    #0
L9A4B       STY    Z7D
            JSR    XB274           ;Get next non-blank
;
L9A50       JSR    L9959           ;Convert if a dec str
            BCC    L9A59           ;There was a conversion
            LDY    Z7D             ;
            BEQ    L9A70
;
L9A59       DEC    Z10
            BEQ    L9A35           ;Err
            JSR    L9A7F
            CMP    #$FF            ;Is char a ','?
            BEQ    L9A49           ;Yes, another interval
            CMP    #$00            ;Is it a '-'?
            BNE    L9A70           ;No
            LDY    Z7D             ;Was an interval?
            BMI    L9A35           ;Yes->err
            LDY    #-1             ;Flag an interval
            BMI    L9A4B           ;always
;
L9A70       LDA    #-1             ;Store a couple of $FF
            JSR    L9982           ; to mark end of interval
            JSR    L9982
            DEX
            JSR    L99CD
            JMP    XB211           ;Continue parsing cmd line
;=================================================
; (Z12)-char
; Output
;  (Z12)  (A)
;    ,    $FF
;    -    $00
;    CR   $E0
;
L9A7F       JSR    L997B           ;Save Reg11 to buffer
            LDA    Z12             ;Get char
            SEC
            SBC    #'-'
            JMP    L9982
;=================================================
; Parse for L$/A$ parms
;
L9A8A       LDA    #'L'
            BNE    L9A93           ;always
L9A8E       JSR    L9AA5
            LDA    #'A'
L9A93       CMP    Z12
            BNE    L9A9F
            JSR    XB274
            JSR    L9AC4
            BCC    L9AA2
L9A9F       JMP    L99A2
L9AA2       JMP    L9990
;=================================================
; Set ptr to buf for storing A$ and L$ 16-bit
; values which are separated by a 0
;
L9AA5       EQU    *               ;ENTRY
            LDA    #>XBD00
            STA    Reg12           ;SET R12,XBD00
            LDA    #<XBD00
            STA    Reg12+1
            RTS
;=================================================
; Parse for L$/A$ parms
;
L9AAE       LDA    #'L'            ;Length
            BNE    L9AB7           ;always
;
L9AB2       JSR    L9AA5           ;Set ptr to $BD00 buf
            LDA    #'A'            ;Addr
L9AB7       CMP    Z12
            BNE    L9ABE
            JSR    XB274           ;Get next non-blank char
L9ABE       JSR    L9AC4
            JMP    L9990
;=================================================
; Parse a string, convert its value and
; store binary result @ $BD00 buf
;
L9AC4       LDA    Z12
            CMP    #'$'
            BEQ    L9ACD
            JMP    L9959           ;Convert dec string
;
L9ACD       JSR    XB274           ;Get next non-blank char
            LDA    #$00
            STA    Reg11
            STA    Reg11+1
            LDA    Z12
            JSR    L9B04           ;Is char hexdec digit?
            BCC    L9ADE           ;Yes
            RTS
;
; (A) has the converted value which is $00-$0F
;
L9ADE       STA    Reg11
L9AE0       JSR    XB274           ;Get next non-blank char
            JSR    L9B04
            BCS    L9B15           ;No, a hexdec digit
;
L9AE8       ASL    Reg11           ;Mul16
            ROL    Reg11+1
            ASL    Reg11           ;Shift to make way
            ROL    Reg11+1
            ASL    Reg11
            ROL    Reg11+1         ; for incoming digit
            ASL    Reg11
            ROL    Reg11+1
            BCS    L9B01           ;Overflow
            ORA    Reg11
            STA    Reg11
            JMP    L9AE0           ;Get next char
L9B01       JMP    L99A5
;=================================================
; Input
;  (A) - ASCII char to be converted
; Output
;  C=0 if char is hexdec and
;  (A) - $00-$0F
;  C=1 if char is not hexdec
;
L9B04       JSR    L996D           ;Try dec conversion first
            BCC    L9B16           ;If char is dec, conversion is done
            CMP    #'F'+1          ;Is char a hexdec digit?
            BCS    L9B18           ;No
            CMP    #'A'
            BCC    L9B17           ;No
            SBC    #$07            ;$41-$46 -> $3A-$3F
            AND    #$0F            ; -> $0A-$0F
L9B15       CLC
L9B16       RTS
;
L9B17       SEC
L9B18       RTS
;=================================================
; XLOAD cmd
; This cmd is only valid if edit is not split
;
L9B19       RTN
            JSR    L9C4F           ;Chk if swap is in effect
            JSR    NEWSW16         ;No
L9B20       SET    R4,XBD80        ;Point @ PN
            SET    R0,$0006
            ADD    R5              ;TxtBgn
            ST     R3
            ST     R9              ;=TxtBgn+6 ($807)
L9B29       LDD    R12             ;Is a Load addr specified?
            BZ     L9B36           ;No
            CPR    R9              ;Addr must not be < this
            BNC    L9B32
            CPR    R6              ;Is it < HiMem?
            BNC    L9B35           ;Yes
L9B32       BRL    LD541           ;Invalid parm err
;
L9B35       ST     R9              ;=Specified LoadAdr
L9B36       LD     R5              ;Ptr to TxtBgn ($801)
            ST     R2
            SUB    R0              ;Zero ACC and
            STD    R2              ; locations $801-$802
            RTN
            LDA    #BINtype
            JSR    XB883
            BCC    L9B45
            JMP    XB602
;
L9B45       LDY    #5
L9B47       LDA    XBAC8,Y         ;Copy Access bits, filetype
            STA    (Reg5),Y        ; & auxtype to $803-$806
            DEY
            CPY    #1
            BNE    L9B47
;
            LDX    XBACB           ;Is file of type TXT?
            CPX    #TXTtype
            BEQ    L9B60           ;Yes
            CPX    #$02
            BCC    L9B60
            CPX    #$0F            ;DIRtype
            BNE    L9B65
L9B60       LDA    #$11            ;File type mismatch
            JMP    XB602
;
L9B65       JSR    NEWSW16
            LD     R3
            ST     R7              ;TxtEnd
            RTN
            JMP    LD9C6           ;(X)=filetype -> go loadfile
;=================================================
; XSAVE cmd
; An XLOAD must precede an XSAVE; this cmd will not
; be executed if this rule is not obeyed. Internal
; control info will be properly setup by the
; XLOAD cmd.
; If no addr is specified, (Reg9) may not be
; computed correctly unless an XLOAD cmd is
; immediately followed by an XSAVE cmd. For
; this case, Reg5 and Reg7 must be set correctly
; For this multiple cmd (w/o A$, L$ parms)
;  XLOAD <pathname1>: XSAVE <pathname2>
; to work correctly, Reg9 and Reg10 must
; be setup properly
; Reg12 - ptr to $BD00 buf
;
L9B6E       SET    R0,$0006
            ADD    R5              ;TxtBgn
            CPR    R7              ;TxtEnd
            BNZ    L9B78
            BRL    LD6EC           ;Just do a FILE cmd
;
L9B78       SET    R4,XBD80        ;Ptr to PN
            ST     R10             ;=TxtBgn+6
            LDD    R12             ;Did user specify an addr?
            BZ     L9B89           ;No
            ST     R10
            LDD    R12             ;Did user specify a len?
            BNZ    L9B86           ;Yes
            BRL    LD541           ;Invalid parm
;
L9B86       ST     R9
            BR     L9B8F
L9B89       LD     R7              ;XLOAD should have set this
            ST     R9              ; correctly to last byte of
            INR    R9              ; file's data in mem
            LD     R9              ;Compute # of bytes
            SUB    R10
            ST     R9              ; to write
L9B8F       RTN
;
            JSR    L9C4F           ;Must not have a split buf
            LDY    #0
            LDA    (Reg5),Y        ;Chk for a double zero
            INY
            ORA    (Reg5),Y
            BEQ    L9BA1           ;Got 'em
L9B9C       LDA    #$11
            JMP    XB602
;
L9BA1       LDY    #3
            LDA    (Reg5),Y        ;filetype
            JSR    LDA65           ;Write the file
            LDA    FileType
L9BAA       JSR    XB883
            LDY    #3
L9BAF       LDA    XBAD1,Y         ;Date/Time
            STA    XBAE3,Y         ; last mod
            DEY
            BPL    L9BAF
;
            LDY    #2
L9BBA       LDA    (Reg5),Y        ;Copy access,filetype
            STA    XBADA,Y         ;and auxtype @ $803-$806
            INY
            CPY    #6
            BCC    L9BBA
;
            LDA    XBAC8           ;PN ptr
            STA    XBADA
            LDA    XBAC8+1
            STA    XBADA+1
            JSR    XB904           ;Set file's attrib
            JMP    XB1CB
;=================================================
; BLOAD cmd
;
L9BD6       RTN
            JSR    L9C4F
            JSR    NEWSW16
            SET    R4,XBD80        ;Ptr to PN
            LDD    R12             ;Get load addr
            CPR    R5              ;Is it >= TxtBgn?
            BC     L9BE7           ;Yes
L9BE4       BRL    LD541
;
L9BE7       CPR    R6              ;Is it >= HiMem?
            BC     L9BE4           ;Yes, err
            ST     R9
            RTN
            LDX    #BINtype
            JSR    LoadFile
L9BF1       BCC    L9BF6
            JMP    XB602
L9BF6       JMP    XB1CB
;=================================================
; BSAVE cmd
;
L9BF9       SET    R4,XBD80        ;Ptr to PN
            LDD    R12
            ST     R10             ;adr
            LDD    R12
            ST     R9              ;len
            RTN
            LDA    #BINtype
            JSR    LDA65           ;Save the file
            LDA    #BINtype
            STA    XBADD
            JSR    XB883           ;Get info on freshly-created file
;
            LDY    #3
L9C10       LDA    XBAD1,Y         ;Date&Time of
            STA    XBAE3,Y         ; last modification
            DEY
            BPL    L9C10
;
            LDA    XBA92           ;Ptr to data buf
            STA    XBADE
            LDA    XBA92+1
            STA    XBADE+1
            LDA    #$C3            ;Access bits
            STA    XBADC
            LDA    XBAC8           ;Ptr to PN
            STA    XBADA
            LDA    XBAC8+1
            STA    XBADA+1
            JSR    XB904           ;Set file's attributes
            JMP    XB1CB
;=================================================
L9C3C       LDA    LA5B4,Y         ;Get char
            INY
            JMP    XB343           ; and print it
;=================================================
; PrByte
;
L9C43       JSR    XB99B           ;Convert (A) into 2-char str
            PHA
            TXA
            JSR    XB343
            PLA
            JMP    XB343
;=================================================
L9C4F       LDA    SwapMode        ;Is txt buf split?
            BEQ    L9C56           ;No
            JMP    XB6EA           ;Show err & don't ret to caller
L9C56       RTS
;=================================================
; Move contents of txtbuf down in mem
;
L9C57       JSR    NEWSW16
            SET    R1,Z7E
            LD     R9
            STD    R1              ;src addr
            LD     R7              ;TxtEnd
            STD    R1              ;=$80
            LD     R10
            STD    R1              ;=$82 (dest addr)
            ADD    R7              ;Compute the final addr
            SUB    R9              ; of last char of txtbuf
            RTN
;
            LDY    #0
L9C68       LDA    (Z7E),Y
            STA    (Z82),Y
            INC    Z82
            BNE    L9C72
            INC    Z82+1
L9C72       LDA    Z7E
            CMP    Z80
            LDA    Z7E+1
            SBC    Z80+1
;
            INC    Z7E
            BNE    L9C80
            INC    Z7E+1
L9C80       BCC    L9C68
;
L9C82       JSR    NEWSW16         ;Is new TxtEnd
            CPR    R5              ; >= new TxtBgn?
            BC     L9C89           ;Yes
            LD     R5
L9C89       ST     R7              ;TxtEnd
            RTN
            RTS
;=================================================
; Print error msg table
; (X)-index into err msg table
;
L9C8C       LDA    L9CA0,X
            BEQ    L9C97
            JSR    XB343
            INX
            BNE    L9C8C
L9C97       RTS
;=================================================
; Editor's error message printer
;
L9C98       EQU    *               ;ENTRY
            JSR    L9C8C
            LDX    #$68            ;ERROR
            JMP    L9C8C
;=================================================
;
L9CA0       ASC    'CMD            SYNTAX'
            DB     $00
            ASC    'NUMERIC        OVERFLOW'
            DB     $00
            ASC    'PARAMETER(S)   OMITTED'
            DB     $00
            ASC    'UNKNOWN        COMMAND'
            DB     $00
            ASC    'MULTI          BUFFER'
            DB     $00
            ASC    'EXEC           NEST'
            DB     $00
            ASC    'BAD            LINE#/RANGE'
            DB     $00
            ASC    '               ERROR'
            DB     $07,CR,$00
;=================================================
; Editor's Default Tab table
;
L9D11       EQU    *               ;ENTRY
            DB     32,36,48
L9D14       EQU    *               ;ENTRY
            ASC    'EDASM.AUTOST'
            DB     $00
;=================================================
; $9D21
; This 'JMP via RTS' table is utilised by the EI's
; code ($B20F-$B262) for further processing of
; the command line stored at InBuf
;
JMPTBL      EQU    *               ;ENTRY
            DW     XB659-1         ;0 - Chk for a CR
            DW     L999D-1         ;2
            DW     L9A3F-1         ;4
            DW     L99AD-1         ;6
            DW     L99B3-1         ;8
            DW     L99D6-1         ;A
            DW     L9A04-1         ;C
            DW     L99BE-1         ;E
            DW     L998D-1         ;10
            DW     L99F5-1         ;12
            DW     L998D-1         ;14
            DW     L9997-1         ;16
            DW     L99AA-1         ;18
            DW     L99D6-1         ;1A
            DW     L9A0C-1         ;1C
            DW     L9AB2-1         ;1E
            DW     L9AAE-1         ;20
            DW     L9A8E-1         ;22
            DW     L9A8A-1         ;24
            DW     L9AB2-1         ;26
;
; Ptr to the various messages. This table must
; be arranged in 1:1 corr with the table above
;
L9D49       DW     XB289           ;0
            DW     L9D7D           ;2
            DW     L9D8F           ;4
            DW     L9DA2           ;6
            DW     L9DAD           ;8
            DW     L9DBD           ;A
            DW     L9DC7           ;C
            DW     L9DD6           ;E
            DW     L9D85           ;10
            DW     L9D71           ;12
            DW     L9DDF           ;14
            DW     L9DE3           ;16
            DW     L9DA2           ;18
            DW     L9DE7           ;1A
            DW     L9DF4           ;1C
            DW     L9E0C           ;1E
            DW     L9E16           ;20
            DW     L9E20           ;22
            DW     L9E29           ;24
            DW     L9E01           ;26
;=================================================
; ERROR FRAGMENTS
;
L9D71       ASC    '               <PATHNAME>'
            DB     $00
L9D7D       ASC    '               LINE# '
            DB     $00
L9D85       ASC    '               <LINE#> '
            DB     $00
L9D8F       ASC    '               <BEGIN# <-END#>> '
            DB     $00
L9DA2       ASC    '               .STRING. '
            DB     $00
L9DAD       ASC    '.OLDSTR.NEWSTR.'
            DB     $00
L9DBD       ASC    '               PATHNAME'
            DB     $00
L9DC7       ASC    '<OBJ-PATHNAME>'
            DB     $00
L9DD6       ASC    '<DEVCTL>'
            DB     $00
L9DDF       ASC    '<#>'
            DB     $00
L9DE3       ASC    '               # '
            DB     $00
L9DE7       ASC    '               OLDPATHNAME'
            DB     $00
L9DF4       ASC    '               NEWPATHNAME'
            DB     $00
L9E01       ASC    '[A<$>ADRS]'
            DB     $00
L9E0C       ASC    '[A<$>ADRS'
            DB     $00
L9E16       ASC    'L<$>LGTH]'
            DB     $00
L9E20       ASC    'A<$>ADRS'
            DB     $00
L9E29       ASC    'L<$>LGTH'
            DB     $00
;=================================================
; Convert (A) into BCD and return
; 2-byte dec string in (X,A)
;
L9E32       TAX
            CPX    #100
            BCC    L9E3B
            LDA    #'*'
            TAX
            RTS
;
L9E3B       LDA    #0
            SED
L9E3E       CLC
            ADC    #1
            DEX
            BNE    L9E3E
;
            CLD
            PHA
            AND    #$F0            ;Isolate ten's digit
            LSR
            LSR
            LSR
            LSR
            ORA    #'0'            ;-> ASCII
            TAX
            PLA
            AND    #$0F            ;Isolate unit's digit
            ORA    #'0'
            RTS
;=================================================
; Convert ProDOS Date/Time into ASCII format
;
L9E55       EQU    *               ;ENTRY
            LDA    #'-'
            STA    DateTime+2
            STA    DateTime+6
            LDA    #':'
            STA    DateTime+13
            LDA    #SPACE
            STA    DateTime+10
            STA    DateTime+9
            LDA    P8TIME
            ORA    P8TIME+1
            BNE    L9E7E
;
            LDX    #5              ;No Time
            LDA    #SPACE
L9E76       STA    DateTime+10,X
            DEX
            BNE    L9E76
            BEQ    L9E9A           ;always
;
L9E7E       LDA    P8TIME
            AND    #%00111111      ;xxMM MMMM
            JSR    L9E32
            STX    DateTime+14
            STA    DateTime+15
            LDA    P8TIME+1
            AND    #%00011111      ;xxxH HHHH
            JSR    L9E32
            STX    DateTime+11
            STA    DateTime+12
;
L9E9A       LDA    P8DATE+1        ;YYYY YYYM
            LSR                    ;0YYY YYYY
            PHP                    ;Save M-bit in C
            JSR    L9E32
            STX    DateTime+7
            STA    DateTime+8
            LDA    P8DATE          ;MMMD DDDD
            PHA
            AND    #%00011111      ;000D DDDD
            JSR    L9E32
            STX    DateTime
            STA    DateTime+1
            PLA
            AND    #%11100000      ;MMM0 0000
            PLP                    ;M-bit
            ROR                    ;MMMM 0000
            LSR                    ;Index in Months table
            LSR
            LSR                    ;000M MMM0 (div8)
            STA    DateTime+3      ;Use as tmp
            LSR                    ;0000 MMMM (div16)
            CLC
            ADC    DateTime+3
            TAX
            DEX
            LDY    #3
L9ECB       LDA    MonthsT,X
            STA    DateTime+2,Y    ;Month in ASCII
            DEX
            DEY
            BNE    L9ECB
            RTS
;=================================================
L9ED6       ASC    'BYTES          USED'
            DB     CR
L9EE1       ASC    'BYTES          REMAINING'
            DB     CR
L9EF1       ASC    'BYTES          USED BY NON TEXT DATA'
            DB     CR
L9F0D       ASC    '                = XSAVE FILE TYPE'
            DB     CR
L9F21       ASC    '               = XSAVE  AUX TYPE'
            DB     CR
;=================================================
L9F34       JSR    PRODOS8         ;Newline
            DB     $C9
            DW     XBAA0
            RTS
;
L9F3B       JSR    PRODOS8
            DB     $CA
            DW     L9F42
            RTS
;
; Read text file parm block
; Used by the TYPE cmd
;
L9F42       DB     $04
L9F43       DB     $A0             ;Ref #
            DW     XBD00           ;read data buf
L9F46       DW     255             ;max val
L9F48       DW     $A0A0
;=================================================
; CREATE cmd
;
L9F4A       SET    R4,XBD80        ;Ptr to PN
            RTN
            LDA    #$0F            ;DIRtype
            JSR    XB883           ;Does file exist?
            BCS    L9F5A           ;No
            LDA    #$47            ;Err
L9F57       JMP    XB602
;
L9F5A       LDA    FileType
            STA    XBAEB
            LDA    #$0D            ;sub-DIR
            STA    XBAEE
            LDA    #$C3            ;Access bits
            STA    XBAEA
            LDA    XBAC8           ;Re-use
            STA    XBAE8
            LDA    XBAC8+1         ; ptr to PN
            STA    XBAE8+1
            JSR    XB919           ;Create subdir
            LDX    #$01
            STX    XBAEE           ;Reset this
            TAX
            BNE    L9F57           ;Err
            JMP    XB1CB
;=================================================
CPYRIGHTS   EQU    *               ;ENTRY
            DB     CR,CR,CR,CR,CR,CR,CR
            ASC    '                   PRODOS  EDITOR-ASSEMBLER // '
            DB     CR,CR
            ASC    '                      RELEASE 1.1 '
            MSB    ON
            ASC    "01-MAY-85"
            MSB    OFF
            DB     CR,CR
            ASC    '                         BY JOHN ARKLEY'
            DB     CR,CR,CR
            ASC    '                      '
            MSB    ON
            ASC    "COPYRIGHT (C) 1983-85"
            MSB    OFF
            DB     CR,CR
            ASC    '                     '
            MSB    ON
            ASC    "  APPLE COMPUTER INC."
            MSB    OFF
            DB     CR
;=================================================
; PTRON cmd
;
LA024       RTN
            LDA    DevCtlS         ;Slot # (0000 0sss)
            ASL
            ASL
            ASL
            ASL
            AND    #$70            ;0sss 0000
            BEQ    LA042           ;Slot 0
;
            STA    LA1A0           ;Unit #
            JSR    PRODOS8
            DB     $C5
            DW     LA19F
            BEQ    LA03F           ;Printers should not ret 0
            CMP    #$28            ;No device connected?
            BEQ    LA042           ;Yes
LA03F       JMP    LD53E           ;Invalid parm
;
LA042       LDA    #$80
LA044       STA    PtrMode         ;PTRON flag
            JMP    XB1CB
;=================================================
; PTROFF cmd
;
LA049       RTN
            LDA    #$00
            BEQ    LA044           ;always
;=================================================
; Print name of file in active txtbuf
;
LA04E       LDA    SwapMode
            CMP    #$02
            BNE    LA054           ;Useless instr
LA054       LDA    XBE00
            BEQ    LA066
;
            LDY    #0
LA05B       LDA    XBE00,Y
            BEQ    LA066
            JSR    XB343           ;Output char
            INY
            BPL    LA05B
;
LA066       JMP    XB339           ;Do a cr
;=================================================
LA069       JSR    NEWSW16
LA06C       SET    R9,XB50D        ;Dir not found
            BRL    LD33F
;=================================================
; CATALOG cmd
;
LA072       SET    R0,80           ;# of cols
            BR     LA07A
;
; CAT
;
LA077       SET    R0,40
;
LA07A       SET    R4,LA5B3
            STI    R4
            SET    R4,XBD80        ;Point @ PN
            LDI    R4              ;Did user include PN?
            BNZ    LA090           ;Yes
            SET    R4,XBB80        ;No, try curr pfx
            LDI    R4              ;Get len byte
            BZ     LA06C           ;No prefix set
            ADD    R4              ;Compute EO pfx
            ST     R1
            SUB    R0              ;Zero ACC
            STI    R1              ;Append a 0 to pfx
            BR     LA091
;
LA090       DCR    R4
LA091       RTN
;
; Reg4-ptr to PN
;
LA092       LDA    #$0F            ;DIRtype
            JSR    XB883           ;Chk file's info
            BCS    LA0C6           ;Not found
            JSR    XB339           ;Do a cr
LA09C       LDA    XBACE           ;Storage type
            CMP    #$0D            ;Linked dir file?
            BEQ    LA0AC           ;Yes
            CMP    #$0F            ;Vol Dir?
            BNE    LA069           ;No
            LDA    #'/'
            JSR    XB343
;
LA0AC       LDX    #>XA900         ;1024-byte I/O buf
            LDY    #<XA900
            JSR    XB8CE           ;Open Dir file
            STA    XBAA5           ;Ref #
            STA    XBAAD
            LDA    #$27+4          ;# of bytes to read
            STA    XBAA8           ; incl 4-byte header
            JSR    PRODOS8
            DB     $CA
            DW     XBAA4
            BEQ    LA0C9
LA0C6       JMP    XB602
;
LA0C9       LDA    LA8D1+$23       ;Entry Len (=$27)
            STA    XBAA8           ;# of bytes to read
            LDY    #0
LA0D1       LDA    LA8D1+4,Y       ;Move contents of dir header left over-
            STA    LA8D1,Y         ; writing 4-byte next/prev block ptrs
            INY
            CPY    #$27
            BCC    LA0D1
;
            JSR    LA251
LA0DF       JSR    XB339           ;Do a cr
            JSR    LA232
            JSR    XB339
            JSR    XB339
;
            LDA    #$00
            STA    Z64
LA0EF       JSR    LA26D           ;Read a file entry
            BCS    LA10D
            LDA    LA8D1
            AND    #$F0
            BEQ    LA0EF           ;Deleted entry
            CMP    #$E0            ;Subdir/vol dir header entry
            BCS    LA0EF
;
            JSR    LA396
            JSR    LA116           ;Display
            JSR    XB339
            JSR    KeyPress
            BCC    LA0EF           ;Not ctrl-C
;
LA10D       JSR    XB8EF           ;Close file
            JSR    LA12A
            JMP    XB1CB
;=================================================
; Display info
;
LA116       LDY    LA5B3           ;# of cols
            DEY
            STY    Z66
            LDY    #0
LA11E       LDA    InBuf,Y
            JSR    XB343
            INY
            DEC    Z66
            BNE    LA11E
            RTS
;=================================================
LA12A       LDA    LASTDEV
            STA    LA1A0
            JSR    PRODOS8
            DB     $C5
            DW     LA19F
            BNE    LA19E
;
            LDA    LA8D1
            BEQ    LA19E
            AND    #$0F            ;Isolate len byte
            TAY
            LDA    #0
            STA    LA8D1+1,Y
            LDA    #'/'            ;Precede name
            STA    LA8D1           ; with a slash
            LDA    #>LA8D1
            STA    Reg4
            LDA    #<LA8D1
            STA    Reg4+1
            LDA    #$0F            ;DIRtype
            JSR    XB883           ;Get info
            BCS    LA19E           ;Not found
            JSR    LA554
;
            LDY    #62
LA15E       LDA    LA1F4-1,Y
            STA    InBuf-1,Y
            DEY
            BNE    LA15E
;
            STY    LA5AC+2         ;=0
            LDA    XBACC           ;Size of vol (auxtype)
            LDX    XBACC+1
            LDY    #61
            JSR    LA50F
            LDA    XBACF           ;Blocks used
            LDX    XBACF+1
            LDY    #38
            JSR    LA50F
;
            LDA    XBACC           ;Compute free blocks
            SEC
            SBC    XBACF
            PHA
            LDA    XBACC+1
            SBC    XBACF+1
            TAX
            PLA
            LDY    #16
            JSR    LA50F
;
            JSR    XB339
            JSR    LA116
            JSR    XB339
LA19E       RTS
;=================================================
; Online parm block for PTRON cmd
;
LA19F       DB     $02
LA1A0       DB     $00
            DW     LA8D1
;
LA1A3       ASC    '               NAME           TYPE  BLOCKS  MODIFIED'
            DB     $00
            ASC    '                       CREATED          ENDFILE SUBTYPE'
            DB     $00
LA1F4       ASC    'BLOCKS         FREE:          BLOCKS USED:      '
            ASC    '                  TOTAL BLOCKS:     '
;=================================================
; Print Catalog Col headers
;
LA232       LDY    #0
LA234       LDA    LA1A3,Y
            BEQ    LA23F
            JSR    XB343
            INY
            BNE    LA234
;
LA23F       BIT    LA5B3           ;=$50 or $28
            BVC    LA250
            INY
LA245       LDA    LA1A3,Y
            BEQ    LA250
            JSR    XB343
            INY
            BNE    LA245
LA250       RTS
;=================================================
; Show directory name
;
LA251       LDA    LA8D1
            PHA
            AND    #$0F            ;Isolate len byte
            STA    LA8D1
            LDY    #0
LA25C       LDA    LA8D1+1,Y       ;Show dir name
LA25F       JSR    XB343
            INY
            CPY    LA8D1
            BNE    LA25C
            PLA
            STA    LA8D1           ;Restore stortype/len byte
            RTS
;=================================================
; Input
; (Z64) Read a file entry if cnt is +ve
; else skip last 5 bytes of dir block
; Each dir block has at most 13 entries
; which takes up 27;13=507 bytes
;
LA26D       BIT    Z64             ;File entry cnt
            BPL    LA27E
            JSR    PRODOS8         ;Skip last 5 bytes
            DB     $CA
            DW     XBAAC           ; of dir block
            STA    RDBANK2
            BEQ    LA27E
LA27C       SEC
            RTS
;
LA27E       JSR    PRODOS8
            DB     $CA
            DW     XBAA4
            STA    RDBANK2
            BEQ    LA290
            CMP    #$4C            ;EOF
            BEQ    LA27C
            JMP    XB5F8
;
LA290       INC    Z64
            LDA    Z64
            CMP    #12
            BCC    LA29C
            LDA    #-1             ;Prepare to skip
            STA    Z64             ; 5 bytes on next read
LA29C       CLC
            RTS
;=================================================
; PREFIX cmd
;
LA29E       RTN
            LDA    XBD80           ;Is PN included w/cmd?
            BEQ    LA2E1           ;No
            CMP    #'/'
            PHP
            LDA    XBD80+1
            BNE    LA2BD           ;Yes
            PLP                    ;Just a single /?
            BNE    LA2BE           ;No
            JSR    XB836           ;Set pfx to EdAsm's dir
            BEQ    LA2B7
            JMP    XB602
LA2B7       JMP    LA2E1
            JMP    XB1CB
;
LA2BD       PLP                    ;Full or partial PN
LA2BE       LDY    #-1
            LDX    #0
LA2C2       INY
            LDA    XBD80,Y
            BEQ    LA2D3
            CMP    #SPACE+1
            BCC    LA2C2
            STA    XBD80,X
            INX
            BPL    LA2C2
            DEX                    ;=$7F
LA2D3       STX    XBD80-1
            JSR    PRODOS8         ;Make this PN the
            DB     $C6
            DW     LA2EF           ; default prefix
            BEQ    LA2E1
            JMP    XB86F
;
LA2E1       JSR    PRODOS8         ;Make it our currpfx
            DB     $C7
            DW     XBABC
            STA    RDBANK2
            BEQ    LA2F2
            JMP    XB602
;
; Set Prefix
;
LA2EF       DB     $01
            DW     XBD80-1
;=================================================
; Display curr prefix
;
LA2F2       LDY    #-1
LA2F4       INY
            CPY    XBB80
            BCS    LA303
            LDA    XBB80+1,Y
            JSR    XB343
            JMP    LA2F4
LA303       JSR    XB339
            JMP    XB1CB
;=================================================
; ONLINE cmd
;
LA309       RTN
LA30A       LDA    #$00            ;All online vols
            STA    XBAFE
            JSR    PRODOS8
            DB     $C5
            DW     XBAFD
            STA    RDBANK2
            BEQ    LA325
;
            CMP    #$27
            BEQ    LA325
            CMP    #$52
            BEQ    LA325
            JMP    XB602
;
LA325       JSR    XB339
            LDY    #0
LA32A       LDA    XA900,Y         ;Get vol's len byte
            AND    #$0F
            STY    Z64
            BEQ    LA383
            STA    Z66             ; and store here
            LDA    #'S'
            JSR    XB343
            LDY    Z64
            LDA    XA900,Y         ;DSSS LLLL (D=0 for dr 1)
            CMP    #$80
            PHP
            AND    #$70            ;0SSS 0000
            LSR
            LSR
            LSR
            LSR
            ORA    #'0'            ;slot # in ASCII
            JSR    XB343
            LDA    #','
            JSR    XB343
            LDA    #'D'
            JSR    XB343
            LDA    #'1'
            PLP                    ;Is it drive 1?
            BCC    LA35E           ;Yes
            LDA    #'2'
LA35E       JSR    XB343
            LDA    #SPACE
            JSR    XB343
            LDA    #'='
            JSR    XB343
            LDA    #SPACE
            JSR    XB343
;
            LDA    #'/'
            JSR    XB343
LA375       LDA    XA900+1,Y
            JSR    XB343
            INY
            DEC    Z66
            BNE    LA375
;
            JSR    XB339
LA383       LDY    Z64
            LDA    XA900,Y
            AND    #$7F
            BEQ    LA393
            TYA
            CLC
            ADC    #16
            TAY
            BNE    LA32A           ;Next online vol
LA393       JMP    XB1CB
;=================================================
; Format a catalog entry line
;
LA396       JSR    LA554           ;Blank buf
            LDA    LA8D1
            AND    #$0F            ;Get entry len
            TAY
LA39F       LDA    LA8D1,Y
            STA    InBuf,Y
            DEY
            BNE    LA39F
;
            STY    LA5AC+2         ;Zero it
            LDA    LA8D1+$10       ;ftype
            JSR    LA440
            BEQ    LA3C3           ;Got a hit
;
            LDY    #$13
            JSR    LA4F2
            BIT    LA5B3           ;80-cols?
            BVC    LA41F           ;No
            LDY    #78
            LDA    #'?'
            BNE    LA3F3           ;always
;
LA3C3       LDX    #2
            PHA                    ;filetype
LA3C6       LDA    LA5B4,Y         ;ASCII rep
            STA    InBuf+17,X
            DEY
            DEX
            BPL    LA3C6
;
            PLA
            BIT    LA5B3           ;80-col display?
            BVC    LA41F           ;No
            LDY    #78
            CMP    #BINtype
            BEQ    LA3F1
            CMP    #TXTtype
            BNE    LA407
;
            LDA    #'R'            ;TXT
            STA    InBuf+72
            LDA    LA8D1+$1F       ;auxtype
            LDX    LA8D1+$20
            JSR    LA50F
            JMP    LA402
;
LA3F1       LDA    #'A'            ;BIN
LA3F3       STA    InBuf+72
            LDA    LA8D1+$1F
            JSR    LA4F2
            LDA    LA8D1+$20
            JSR    LA4F2
;
LA402       LDA    #'='
            STA    InBuf+73
LA407       LDA    LA8D1+$17
            STA    LA5AC+2         ;Should be 0
            LDA    LA8D1+$15       ;EOF
            LDX    LA8D1+$16
            LDY    #70
            JSR    LA50F
            LDX    #$18            ;Creation
            LDY    #61
            JSR    LA450
LA41F       LDY    #27
            LDA    LA8D1+$13       ;Blocks used
            LDX    LA8D1+$14
            JSR    LA50F
            LDA    LA8D1+$1E       ;Access
            AND    #$C2
            CMP    #$C2
            BEQ    LA438
            LDA    #'*'
            STA    InBuf
LA438       LDX    #$21            ;Last Mod
            LDY    #44
            JSR    LA450
            RTS
;=================================================
; Input
;  (A)-filetype
; Output
;  Z=1 - Match
;  (X)-index into filetypes table
;  (Y)-index into ASCII representation table
;
LA440       LDX    #31
            LDY    #0
LA444       INY
            INY
            CMP    FTypesT,X
            BEQ    LA44F
            INY
            DEX
            BPL    LA444
LA44F       RTS
;=================================================
; Convert Date & Time of file entry - 4 bytes
; Byte 0,1 yyyy yyym mmmd dddd
; Byte 2,3 000h hhhh 00mm mmmm
;
LA450       LDA    LA8D1+1,X
            LSR                    ;0yyy yyyy
            STA    LA5B2
            LDA    LA8D1,X
            PHA
            AND    #%00011111      ;000d dddd
            STA    LA5B1
            PLA                    ;mmmd dddd C=m
            ROL                    ;mmdd dddm C=m
            ROL                    ;mddd ddmm C=m
            ROL                    ;dddd dmmm C=m
            ROL                    ;dddd mmmm C=d
            AND    #$0F            ;0000 mmmm
            BEQ    LA483
            CMP    #13             ;12 months
            BCS    LA483
            STA    LA5B0           ;month
            ASL                    ;Form an index which
            ADC    LA5B0           ; is a multiple of 3
            STA    LA5B0           ; with it
            LDA    LA5B1           ;Day
            BEQ    LA483
            LDA    LA5B2           ;Year
            CMP    #100
            BCC    LA495
;
; Invalid date - show as nodate
;
LA483       TYA
            SEC
            SBC    #6
            TAY
            LDX    #8
LA48A       LDA    NoDateS,X
            STA    InBuf,Y
            DEY
            DEX
            BPL    LA48A
            RTS
;
LA495       LDA    LA8D1+3,X       ;000h hhhh
            PHA
            LDA    LA8D1+2,X       ;00mm mmmm
            LDX    #0
            CMP    #60
            BCC    LA4A3
            TXA
LA4A3       JSR    LA4EA           ;Format mins
            LDA    #':'
            STA    InBuf,Y
            DEY
            PLA
            LDX    #0
            CMP    #24
            BCC    LA4B4
            TXA
LA4B4       CMP    #10
            PHP
            JSR    LA50F           ;Format hour
            PLP
            BCS    LA4BE
            DEY
LA4BE       DEY
            LDA    LA5B2           ;Format year
            JSR    LA4EA
            DEY
            LDX    LA5B0           ;Index to month table
            INX
            INX
            INX
LA4CC       LDA    LA57B,X
            STA    InBuf,Y
            DEY
            DEX
            CPX    LA5B0
            BNE    LA4CC
;
            LDA    #'-'
            STA    InBuf,Y
            STA    InBuf+4,Y
            DEY
            LDA    LA5B1
            LDX    #$00
            JMP    LA50F
;=================================================
LA4EA       CLC
            ADC    #100
            JSR    LA50F           ;Convert to dec str
            INY
            RTS
;=================================================
LA4F2       PHA
            AND    #$0F
            JSR    LA4FD
            PLA
            LSR
            LSR
            LSR
            LSR
LA4FD       ORA    #'0'
            CMP    #'9'+1
            BCC    LA505
            ADC    #$06
LA505       STA    InBuf,Y
            DEY
            LDA    #'$'
            STA    InBuf,Y
            RTS
;=================================================
; Convert (X,A) into dec string
; (Y)=index into InBuf
;
LA50F       STX    LA5AC+1
            STA    LA5AC
LA515       JSR    LA52F
            LDA    LA5AC+3
            ORA    #'0'
            STA    InBuf,Y
            DEY
            LDA    LA5AC
            ORA    LA5AC+1
            ORA    LA5AC+2
            BEQ    LA52E
            BNE    LA515           ;always
LA52E       RTS
;=================================================
; NB: A5AC+2,+3 should be zeroed
;
LA52F       LDX    #24
            LDA    #0
            STA    LA5AC+3
LA536       ASL    LA5AC
            ROL    LA5AC+1
            ROL    LA5AC+2
            ROL    LA5AC+3
            SEC
            LDA    LA5AC+3
            SBC    #10
            BCC    LA550
            STA    LA5AC+3
            INC    LA5AC
LA550       DEX
            BNE    LA536
            RTS
;=================================================
LA554       LDA    #SPACE
            LDX    #79
LA558       STA    InBuf,X
            DEX
            BPL    LA558
            RTS
;=================================================
; Filetype table
;
FTypesT     DB     $FF,$FE,$FD,$FC,$FB,$FA,$F9,$F8
            DB     $F7,$F6,$F5,$F4,$F3,$F2,$F1,$F0
            DB     $0F,$0E,$0D,$0C,$0B,$0A,$09,$08
            DB     $07,$06,$05,$04
LA57B       DB     $03,$02,$01,$00
MonthsT     ASC    'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'
NoDateS     ASC    '<NO            DATE>'
;
LA5AC       DB     $A0,$A0,$B0,$C0
LA5B0       DB     $C5             ;month
LA5B1       DB     $A0             ;day
LA5B2       DB     $A0             ;year
LA5B3       DB     40              ;# of cols
;
; ASCII representation of filetypes
;
LA5B4       ASC    'UNK'           ;$00
            ASC    'BAD'           ;$01
            ASC    'PCD'           ;$02
            ASC    'PTX'           ;$03
            ASC    'TXT'           ;$04
            ASC    'PDA'           ;$05
            ASC    'BIN'           ;$06
            ASC    'FNT'           ;$07
            ASC    'GRF'           ;$08
            ASC    'BA3'           ;$09
            ASC    'DA3'           ;$0A
            ASC    'WPF'           ;$0B
            ASC    'SOS'           ;$0C
            ASC    '$0D'           ;$0D
            ASC    '$0E'           ;$0E
            ASC    'DIR'           ;$0F
            ASC    '$U0'           ;$F0-CMD
            ASC    '$U1'           ;$F1
            ASC    '$U2'           ;$F2
            ASC    '$U3'           ;$F3
            ASC    '$U4'           ;$F4
            ASC    '$U5'           ;$F5
            ASC    '$U6'           ;$F6
            ASC    '$U7'           ;$F7
            ASC    '$U8'           ;$F8
            ASC    '$U9'           ;$F9-OS
            ASC    'INT'           ;$FA
            ASC    'IVR'           ;$FB
            ASC    'BAS'           ;$FC
            ASC    'VAR'           ;$FD
            ASC    'REL'           ;$FE
            ASC    'SYS'           ;$FF
;=================================================
LA614       LDY    CH
            LDA    (BASL),Y
            BIT    RDROM2
            JSR    LA653           ;Get key via I/O hooks
            AND    #$7F
            BIT    RDBANK2
            RTS
;=================================================
; Editor's KSW entry point
; Input
;  (A)=char under cursor
;
LA624       PHA
            PHA
            LDA    (BASL),Y        ;Get char fr screen location
            CMP    #UNDERSCORE+$80
            BEQ    LA631           ;Yes
            PLA                    ;char
            LDA    #UNDERSCORE+$80
            BMI    LA632           ;Always
LA631       PLA
LA632       STA    (BASL),Y        ;Replace it
            PLA
LA635       INC    Z4E             ;Delay
            BNE    LA645
            INC    Z4E+1
            PHA
            LDA    #$3F
            AND    Z4E+1
            CMP    #$01
            PLA
            BCC    LA624
LA645       BIT    KBD
            BPL    LA635
;
            STA    (BASL),Y        ;Got a key, store it @ screen location
            LDA    KBD
            BIT    KBDSTROBE
            RTS
;
LA653       JMP    (KSWL)
;=================================================
; (A)= $80 - set ucase
;    = $40
;    = $7F - clear ucase
;    = $00
;
; Output
;  CaseMode - 1000 0000  - ucase only
;      - 0100 0000  - disable lcase
;      - 0000 0000  - lcase
;
LA656       AND    CaseMode
            DB     $2C
LA659       ORA    CaseMode
            STA    CaseMode
            RTS
;=================================================
; Get char and do some char mapping if necessary
;
LA65E       JSR    RDCHAR
            JSR    LA668           ;Chk the key
            BCS    LA65E
            RTS
;
LA667       DB     $00             ;Keyed in char
;
; If //e, //c or later, /// emulation just return
; with C=0 and (A)= char keyed in
; For ][/][+, map the char and save in InBuf if char is valid
; Input
;  (A)= char
; Output
;  C=1 - ignore key
;  C=0 - accept key
;  (A) - modified char
;
LA668       AND    #$7F
            CMP    #$5F            ;Underscore _
            BCS    LA6CB           ;If $5F-$7F, ret w/C=0, (A)=key
            STA    LA667
            LDA    #%00001000
            BIT    MACHID          ;//c or later?
            BNE    LA6C8           ;Yes
            BMI    LA6C8           ;//e
;
; ][/][+
;
            LDA    VideoSlt        ;Is there a video card?
            BNE    LA6C8           ;Yes
            LDA    LA667
            CMP    #']'
            BCS    LA6A2           ;$5D -> $4D
            CMP    #'['
            BCS    LA6CB           ; [ or \
            CMP    #$1E
            BEQ    LA69D           ;ctrl-^ -> ^
            CMP    #$00
            BEQ    LA69D           ;ctrl-@ -> @
            CMP    #$1D
            BEQ    LA69B           ;ctrl-] -> ]
            CMP    #'@'
            BEQ    LA6A2           ;->$50 (P)
            BNE    LA6A5           ;always
;
LA69B       LDA    #'|'
LA69D       ORA    #$40
            JMP    LA6B2
;
LA6A2       EOR    #$10
            CLC
LA6A5       BCC    LA6B2
            BIT    CaseMode        ;Is case disabled?
            BVS    LA6CB           ;Yes
            BIT    BUTN2           ;1-wire shift down?
            BPL    LA6CB           ;No
            ORA    #$20
LA6B2       CMP    #CTRLE          ;Enable lcase?
            BEQ    LA6C1           ;Yes
            CMP    #CTRLW          ;Disable lcase?
            BNE    LA6CB
            LDA    #$40            ;Yes
            JSR    LA659
            SEC
            RTS
;
LA6C1       LDA    #$00
            JSR    LA656
            SEC
            RTS
;
LA6C8       LDA    LA667
LA6CB       CLC
            RTS
;
LA6CD       CMP    #DEL
            BEQ    LA6D5
            CMP    #BS
            BNE    LA6E6
;
LA6D5       DEX
            CPX    #-1             ;Was cursor @ BOL?
            BEQ    LA708           ;Yes
            LDA    InBuf,X
            AND    #$7F
            INX
            CMP    #SPACE          ;ctrl-chars?
            BCC    LA712           ;Yes
            LDA    #BS             ;Printable chars so do BS
;
LA6E6       CMP    #TAB            ;CTRLI
            BCC    LA6EE
            CMP    #SPACE
            BCC    LA6F1
LA6EE       JSR    XB343           ;Printable char
;
LA6F1       CMP    #CTRLX
            BEQ    LA703
            CMP    #BS
            BEQ    LA712
            CPX    #248
            BCC    LA700
            JSR    XB33D           ;Sound the alarm
LA700       INX
            BPL    LA716
LA703       LDA    #'\'            ;Cancel input
            JSR    XB343
LA708       JSR    XB339           ;Display a CR i.e. start entry on a new line
;=================================================
; Input cmd line
;
LA70B       EQU    *               ;ENTRY
            LDA    Prompt          ;prompt
            JSR    XB343
LA710       LDX    #1
LA712       TXA
            BEQ    LA708
            DEX
LA716       BIT    RDROM2
            LDA    #%00001000
            BIT    MACHID
            BNE    LA729           ;//c or later
            BMI    LA729           ;//e or /// emulation
            JSR    LA65E           ;Get char fr ][ kbd
            ORA    #$80
            BMI    LA72C           ;always
;
LA729       JSR    RDCHAR
LA72C       BIT    RDBANK2
            CMP    #CTRLU+$80
            BNE    LA73B
;
            LDY    CH
            LDA    (BASL),Y        ;Pick char fr screen location
            BMI    LA73B
            ORA    #$E0
LA73B       STA    InBuf,X
            AND    #$7F
            CMP    #CR
            BNE    LA6CD
;
            TXA                    ;Got a CR
            PHA
LA746       LDA    InBuf,X         ;Remove msb fr all
            AND    #$7F
            STA    InBuf,X         ; preceding chars
            DEX
            BPL    LA746
;
            PLA
            TAX
            LDA    #$1D            ;ctrl-] -> $9D (clrEOL)
            JSR    XB343
            JMP    XB339           ;Do a CR
;=================================================
; Checks for an 80-col card
; Output
;  (X)=$C3 80-col card detected in slot 3
;  (X)=$00 no 80-col card
;
LA75B       EQU    *               ;ENTRY
            LDX    #$C3
            LDA    #%00000010      ;Is 80-col card present?
            BIT    MACHID
            BEQ    LA76B           ;Maybe
            LDA    SLTBYT
            AND    #%00001000      ;Is there a ROM in slot 3?
            BNE    LA787           ;Yes (NB. (X)=$C3)
;
LA76B       LDA    #$01            ;Pascal v1.1 Protocol?
            CMP    XC30B
            BNE    LA785           ;No
            CMP    XC30B           ;Useless instructions
            BNE    LA785
            CMP    XC30B
            BNE    LA785
;
; Device signature byte=$8x if 80-col card
;
            LDA    XC30C           ;Get Device Signature byte
            AND    #$F0            ;=$x0
            CMP    #$80            :80-column card?
            BEQ    LA787           ;Yes
LA785       LDX    #$00            ;No 80-col card
LA787       RTS
;=================================================
; Reset I/O hooks
;
LA788       EQU    *               ;ENTRY
            LDX    VideoSlt        ;=$Cs
;
; If you enter here, set (X)=$Cs or $00
;
LA78A       EQU    *               ;ENTRY
            TXA
            STX    VideoSlt
            BEQ    LA7AB           ;If (X)=0, init video
;
            CPX    CSWL+1
            BEQ    LA7AA           ;Already setup
;
            LDA    #$00
            STA    CSWL
            STX    CSWL+1          ;=$Cs00
            LDA    #CR
            JSR    XB343           ;Init the card
            LDX    VideoSlt
            CPX    KSWL+1
            BEQ    LA7AA
            STX    KSWL+1          ;=$C300
            LDA    #$00
            STA    KSWL
LA7AA       RTS
;
LA7AB       LDA    CSWL+1
            CMP    #$C3
            BNE    LA7E0
;
            LDA    XC30C           ;Device signature byte
            CMP    #$81            ;ALS Smarterm card?
            BNE    LA7D0
;
            LDA    #CTRLT+$80
            BIT    RDROM2
            JSR    COUT
            LDA    #'A'+$80
            JSR    COUT
            LDA    #'1'+$80
            JSR    COUT
            BIT    RDBANK2
            JMP    LA7E0
;
LA7D0       LDA    #CTRLU+$80
            BIT    RDROM2          ;Read ROM
            JSR    COUT
            BIT    RDBANK2         ;Read only RAM bank 2
            LDA    #$40            ;LCase off
            JSR    LA656
;
; Setup Editor's I/O Hooks (Apple ][)
;
LA7E0       LDA    #>XB3D9         ;Use CmdInt's CSW
            LDX    #<XB3D9
            STA    CSWL
            STX    CSWL+1
            LDA    #>LA624         ; but use Editor's KSW
            STA    KSWL
            LDA    #<LA624
            STA    KSWL+1
            RTS
;=================================================
; Display help
;
DoHelp      EQU    *               ;ENTRY
            LDY    XB286+1         ;Pointer to cmd table
            LDX    XB286+2
            LDA    #>LDE18
            CLC
            ADC    #1              ;Skip 1st byte
            STA    Reg0
            LDA    #<LDE18
            ADC    #0
            STA    Reg0+1
            JSR    XB339           ;Do a CR
LA807       JSR    LA837           ;Print Help on this cmd
            TYA
            SEC
            ADC    Reg0
            STA    Reg0
            LDX    Reg0+1
            BCC    LA815
            INX
LA815       STX    Reg0+1
;
            LDY    #0
            LDA    (Reg0),Y
            CMP    #$54            ;XLOAD
            BEQ    LA823
            CMP    #$0A
            BNE    LA826
;
LA823       JSR    LDCB8
LA826       JSR    KeyPress        ;Was ctrl-C down?
            BCC    LA82E           ;No
            JMP    XB1CB           ;Yes, abort
;
LA82E       INC    Reg0
            BNE    LA834
            INC    Reg0+1
LA834       JMP    LA807
;=================================================
LA837       LDY    #-1
LA839       INY
            LDA    (Reg0),Y        ;Get token
            BEQ    LA86F           ;End of this cmd
            BPL    LA848
            AND    #$7F            ;Cmd char
            JSR    XB343           ;Print char
            JMP    LA839
;
LA848       CMP    #$28            ;Sentinel value
            BNE    LA84F
            JMP    LDCA9
;
LA84F       TAX
            LDA    L9D49,X         ;Get ptr to msg fragment
            STA    Reg1
            LDA    L9D49+1,X
            STA    Reg1+1
            TYA
            PHA
;
            LDY    #0
LA85E       LDA    (Reg1),Y
            BEQ    LA86A           ;EO msg fragment
            AND    #$7F
            JSR    XB343           ;Print char
            INY
            BNE    LA85E           ;always
;
LA86A       PLA
            TAY
            JMP    LA839
LA86F       JMP    XB339           ;Do a CR
;=================================================
; Load EdAsm.Swap
;
LA872       EQU    *               ;ENTRY
            JSR    XB836
            BCS    LA8A9
            LDX    #>LA8C6
            LDY    #<LA8C6
            LDA    #$00
            STA    XBA8A           ;Load addr
            LDA    #$20
            STA    XBA8A+1
            LDA    #$00
            STA    XBA8C           ;Len
            LDA    #$10
            STA    XBA8C+1
            JSR    XB844           ;Load the Quit code
            BCS    LA8A9
            BNE    LA8C0
;
            LDA    #>X2000
            STA    A1
            LDA    #<X2000         ;Start addr
            STA    A1+1
            LDA    #>X2000+$1000-1
            STA    A2
            LDA    #<X2000+$1000-1
            STA    A2+1            ;End addr
            JSR    XB7AB           ;Move code back to LC Bank2
;
LA8A9       BIT    RDBANK2
            LDA    #$00
            STA    BITMAP+$13
            STA    BITMAP+$14
            STA    BITMAP+$15
            STA    BITMAP+$16
            LDA    #$01
            STA    BITMAP+$17
            RTS
;
LA8C0       BIT    RDBANK2
            JMP    LDD09
;=================================================
LA8C6       ASC    'EDASM.SWAP'
            DB     $00
;
; Data buf for vol/sub dir header ($A8D1-$A8FB)
; File Entry ($A8D1-$A8F7)
; Also used for Online call
; $A8D1-$A8F7
; $A8F1-$A8F5 - temporary 5-byte buffer
;
LA8D1       DS     4+$27,0         ;ENTRY
            DS     2,0
            DB     $21