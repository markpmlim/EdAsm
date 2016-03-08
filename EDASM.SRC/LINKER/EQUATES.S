Name          : EQUATES.S
End of file   :    1,580
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

            SYS
            ORG    $2000
;=================================================
; Zero page usage by Linker
;
Z80         EQU    $80
Z82         EQU    $82
SrcP        EQU    $84             ;ptr into src file data buf
Z86         EQU    $86             ;ptr into tempESD buf ($9100)
Z88         EQU    $88             ;GP rec ptr
EntRecP     EQU    $8A             ;ptr into DEF/ENTRY table 24-byte records
XtnRecP     EQU    $8C             ;ptr into REF/EXTRN table 8-byte records
SymP        EQU    $8E             ;ptr into $9200-$A8DF 16-byte records (SymbolicName table)
Z8E         EQU    $8E             ;re-cycled
;
cp          EQU    $90             ;ptr into cmd line buf
MsgP        EQU    $92
CurrORG     EQU    $94             ;Starting PC of curr src file
Z96         EQU    $96             ;Curr EOF of REL OBJ file
LwrBound    EQU    $98             ;old offset into curr code image
UprBound    EQU    $9A             ;curr offset into curr code (why is $9B not used?)
Z9C         EQU    $9C             ; image in memory
Z9E         EQU    $9E             ;Flag if a src PN is preceded by an ;
XtnNbr      EQU    $9F             ;# of EXTRNs in REL OBJ file's ESD
FTypeF      EQU    $A0             ;filetype of target obj file BIN=$01,REL=$80,SYS=$02
;
OptionsF    EQU    $A1             ;TRUE when the OPTION cmd is encountered
OptFlagT    EQU    $A2
MapFileF    EQU    $A2             ;default ON
ERefF       EQU    $A3             ;default ON
SortLMF     EQU    $A4             ;default ON
XRefF       EQU    $A5             ;default ON
NumSortF    EQU    $A6             ;default OFF
OptDF       EQU    $A7             ;default OFF
PageF       EQU    $A8             ;default OFF
;
; Use to help set flags $A2-$A8
; as well as return as a 16-bit value
;
Switch      EQU    $AB             ;ON/OFF ($80/$00)
Value16     EQU    $AB             ;Value of arithmetic/numeric expression
;
LineCnt     EQU    $AD
PageCnt     EQU    $AE
JJJ         EQU    $AF
III         EQU    $B1
StrtIdx     EQU    $B3
EndIdx      EQU    $B5
Jump        EQU    $B7
NumRecs     EQU    $B9             ;Total # of records in ENTRY table
J.TH        EQU    $BB
I.TH        EQU    $BD
EntRPJ      EQU    $BF
EntRPI      EQU    $C1
;=================================================