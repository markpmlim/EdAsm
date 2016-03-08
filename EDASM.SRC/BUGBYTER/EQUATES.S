Name          : EQUATES.S
End of file   :    2,654
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;---------------------------------------------------------;
;     Disassembled with The Flaming Bird Disassembler     ;
;    (c) Phoenix corp. 1992,93  -  All rights reserved    ;
; References:                                             ;
;              Neil Parker's 6502 instruction set         ;
;                      Apple II Monitor                   ;
;          Appendix C pg 203 of WorkBench Manual          ;
;---------------------------------------------------------;
WNDLFT      EQU    $20
WNDWDTH     EQU    $21
WNDTOP      EQU    $22
WNDBTM      EQU    $23
CH          EQU    $24
CV          EQU    $25
BASL        EQU    $28
BASH        EQU    $29
CSWL        EQU    $36
Z2F         EQU    $2F
;
            DSECT
            ORG    $3A
MONPC       EQU    *
PZWS        EQU    *
Z3APTR      DS     2
ScrLoc      DS     2
Z3E         DS     2
Z40         DS     1
Z41         DS     1
Z40PTR      EQU    Z40
Z42         DS     1
Z43         DS     1
Z44         DS     1
Z43PTR      EQU    Z43
CPURegs     EQU    *
HACCUM      DS     1               ;$45-$49
HXREG       DS     1
HYREG       DS     1
HFLAGS      DS     1
HSTAKP      DS     1
Z46         EQU    HXREG
            DEND
;
; Apple keycodes
;
CTRLB       EQU    $82
CTRLC       EQU    $83
CTRLD       EQU    $84
BEL         EQU    $87
CURSL       EQU    $88             ;ctrl-H
TAB         EQU    $89
CR          EQU    $8D
CTRLN       EQU    $8E
CURSR       EQU    $95             ;ctrlU
CTRLX       EQU    $98
ESC         EQU    $9B
SPACE       EQU    $A0
DELCH       EQU    $FF
;
STACK       EQU    $0100
BBStack     EQU    $011F
INBUF       EQU    $200            ;input buffer for BI
DOSWrm      EQU    $03D0           ;ProDOS warm start vector
BRKV        EQU    $03F0           ;BREAK vector
SOFTEV      EQU    $03F2           ;reset vector
PWREDUP     EQU    $03F4
USRADR      EQU    $03F8           ;ctl-y handler
;
            DSECT  
            ORG    $400
SLIN00      DS     40              ; $0400
SLIN08      DS     40              ; $0428
SLIN16      DS     40              ; $0450
SHOLA0      DS     8               ; $0478..$047F
SLIN01      DS     40              ; $0480
SLIN09      DS     40              ; $04A8
SLIN17      DS     40              ; $04D0
SHOLA1      DS     8               ; $04F8..$04FF
SLIN02      DS     40              ; $0500
SLIN10      DS     40              ; $0528
SLIN18      DS     40              ; $0550
SHOLA2      DS     8               ; $0578..$057F
SLIN03      DS     40              ; $0580
SLIN11      DS     40              ; $05A8
SLIN19      DS     40              ; $05D0
SHOLA3      DS     8               ; $05F8..$05FF
SLIN04      DS     40              ; $0600
SLIN12      DS     40              ; $0628
SLIN20      DS     40              ; $0650
SHOLA4      DS     8               ; $0678..$067F
SLIN05      DS     40              ; $0680
SLIN13      DS     40              ; $06A8
SLIN21      DS     40              ; $06D0
SHOLA5      DS     8               ; $06F8..$06FF
SLIN06      DS     40              ; $0700
SLIN14      DS     40              ; $0728
SLIN22      DS     40              ; $0750
SHOLA6      DS     8               ; $0778..$077F
SLIN07      DS     40              ; $0780
SLIN15      DS     40              ; $07A8
SLIN23      DS     40              ; $07D0
SHOLA7      DS     8               ; $07F8..$07FF
            DEND
;
iJSR        EQU    $20
iRTI        EQU    $40
iJMP        EQU    $4C
iRTS        EQU    $60
iNOP        EQU    $EA
;
; BI & ProDOS
;
DOSCMD      EQU    $BE03
PRINTERR    EQU    $BE0C
PRODOS8     EQU    $BF00
;
; I/O Switches
;
KBD         EQU    $C000
KBDSTROBE   EQU    $C010
SPKR        EQU    $C030
TXTCLR      EQU    $C050
TXTSET      EQU    $C051
MIXCLR      EQU    $C052
MIXSET      EQU    $C053
TXTPAGE1    EQU    $C054
TXTPAGE2    EQU    $C055
LORES       EQU    $C056
HIRES       EQU    $C057
BUTN0       EQU    $C061           ;OA key (Paddle Button 0)
PADDL0      EQU    $C064
PTRIG       EQU    $C070
;
; Monitor
;
MONZ        EQU    $FF69
;
; BB uses 32 bytes of stack space ($100-$11F)
; It is assembled @ $0800 but may be relocated
; to anywhere in memory ($0800-$95FF) as long there
; sufficient mem
;