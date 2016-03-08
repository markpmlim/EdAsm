Name          : EXTERNALS.S
End of file   :      826
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;=================================================
; Memory usage by Linker
;
SrcIOAdr    EQU    $0800           ;1024-byte buf for REL src file(s) ($0800-$BFFF)
SrcDBuf     EQU    $0C00           ;R/W data buf for file(s) ($0C00-$1FFF)
X3F00       EQU    $3F00           ;1024-byte buf for OBJ/tempESD files ($3F00-$42FF)
X4300       EQU    $4300           ;1024-byte buf for LinkMap/tempRLD file ($4300-$46FF)
EntTbl      EQU    $4700           ;DEFine table (24-byte records) ($4700-$70FF)
XtnTbl      EQU    $7100           ;REFerence table (8-byte records) ($7100-$90FF)
X9100       EQU    $9100           ;databuf-tempESD/REL Obj file ($9100-$91FF)
X9200       EQU    $9200           ;1 mem page data buf for code image read
SymTbl      EQU    $9200           ;SymbolicName table (16-byte records) ($9200-$A8DF?)
XA8E0       EQU    $A8E0           ;Upper limit of symbolicname table
;=================================================
CurrPfxB    EQU    $BB80           ;Curr Prefix set by user in Editor's environment