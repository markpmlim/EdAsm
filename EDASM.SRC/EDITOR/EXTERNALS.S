Name          : EXTERNALS.S
End of file   :    3,020
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

;
; These externals labels are EDASM.SYSTEM's entry points
;
XB198       EQU    $B198           ;warm start
XB1AB       EQU    $B1AB           ;EI main loop
XB1CB       EQU    $B1CB           ;reset I/O hooks
XB211       EQU    $B211           ;command parser
XB274       EQU    $B274           ;get non-blank char
XB286       EQU    $B286           ;cmd table ptr
XB289       EQU    $B289           ;do an RTS
XB28E       EQU    $B28E           ;print cmd syntax err
XB290       EQU    $B290           ;prt err msg 
XB339       EQU    $B339           ;output CR
XB33D       EQU    $B33D           ;beep
XB343       EQU    $B343           ;output (A)
XB36B       EQU    $B36B           ;call monitor's VTAB
XB375       EQU    $B375           ;call monitor's BELL1
XB37F       EQU    $B37F           ;call monitor's PRBLNK
XB389       EQU    $B389           ;call monitor's PRNTAX
XB393       EQU    $B393           ;call monitor's SETKBD & SETVID
XB3D9       EQU    $B3D9           ;Output (A) thru EI's CSW
XB5F8       EQU    $B5F8           ;Fatal Error
XB5FF       EQU    $B5FF           ;Close file and fall thru
XB602       EQU    $B602           ; to print err msg
XB620       EQU    $B620           ;Print "ER:" and beep
XB659       EQU    $B659           ;Print err msg and err code
XB6EA       EQU    $B6EA           ;Multi-buffer err msg
XB7AB       EQU    $B7AB           ;Load EDASM.ED
XB836       EQU    $B836           ;Set prefix to EDASM's boot dir
XB844       EQU    $B844           ;Load EDASM.ED or EDASM.ASM
XB86F       EQU    $B86F           ;Print invalid pathname
XB883       EQU    $B883           ;check file's attributes
XB8B2       EQU    $B8B2           ;copy file's name to 2 buffers
XB8CE       EQU    $B8CE           ;open a file for reading
XB8EF       EQU    $B8EF           ;close file and proceed to err handler
XB8FE       EQU    $B8FE           ;close file and return to caller
XB904       EQU    $B904           ;set file info
XB90B       EQU    $B90B           ;kill file
XB912       EQU    $B912           ;rename
XB919       EQU    $B919           ;create
XB920       EQU    $B920           ;write
XB927       EQU    $B927           ;set EOF
XB92E       EQU    $B92E           ;xfer control to another .SYSTEM program
XB937       EQU    $B937           ;open and read an EDASM module
XB966       EQU    $B966           ;check a file's size
XB99B       EQU    $B99B           ;convert (A) to printable HEX code
XB9B0       EQU    $B9B0           ;EXEC command handler
;=================================================
;
; These externals labels are EDASM.SYSTEM's DATA AREAS
;
XB40A       EQU    $B40A           ;text of err messages
XB420       EQU    $B420           ;are in $B40A-$B5BE
XB427       EQU    $B427
XB432       EQU    $B432
XB43E       EQU    $B43E
XB448       EQU    $B448
XB45B       EQU    $B45B
XB50D       EQU    $B50D
XB521       EQU    $B521
;
XB9EE       EQU    $B9EE           ;used by SWAP command
XBA33       EQU    $BA33           ; - ditto -
XBA78       EQU    $BA78           ;used by SW16
XBA80       EQU    $BA80           ;ptr to free mem
XBA87       EQU    $BA87           ;open ref #
XBA8A       EQU    $BA8A           ;read ref #
XBA8C       EQU    $BA8C           ;read request len
XBA8E       EQU    $BA8E           ;actual read len
XBA91       EQU    $BA91           ;write ref #
XBA92       EQU    $BA92           ;write data buffer
XBA94       EQU    $BA94           ;write len
XBAA0       EQU    $BAA0           ;New line parm block
XBAA1       EQU    $BAA1           ;NL ref #
XBAA4       EQU    $BAA4           ;Read park block used by CAT/CATALOG cmd
XBAA5       EQU    $BAA5           ;read ref #
XBAA8       EQU    $BAA8           ;read len
XBAAC       EQU    $BAAC           ;use to read dir block
XBAAD       EQU    $BAAD           ;read ref #
XBAB5       EQU    $BAB5           ;Set EOF ref #
XBAB6       EQU    $BAB6           ;new EOF (3 bytes)
XBABC       EQU    $BABC
XBAC8       EQU    $BAC8
XBACA       EQU    $BACA
XBACB       EQU    $BACB
XBACC       EQU    $BACC
XBACE       EQU    $BACE
XBACF       EQU    $BACF
XBAD1       EQU    $BAD1
XBADA       EQU    $BADA
XBADC       EQU    $BADC
XBADD       EQU    $BADD
XBADE       EQU    $BADE
XBAE3       EQU    $BAE3
XBAE8       EQU    $BAE8
XBAEA       EQU    $BAEA
XBAEB       EQU    $BAEB
XBAEC       EQU    $BAEC
XBAEE       EQU    $BAEE
XBAF4       EQU    $BAF4
XBAF7       EQU    $BAF7
XBAFB       EQU    $BAFB
XBAFD       EQU    $BAFD
XBAFE       EQU    $BAFE
XBB1A       EQU    $BB1A
XBB80       EQU    $BB80