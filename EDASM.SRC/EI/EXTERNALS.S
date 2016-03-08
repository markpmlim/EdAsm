Name          : EXTERNALS.S
End of file   :      979
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

*=================================================
* EDASM Command Interpreter
* This module references of a number
* of routines and tables of EdAsm.Ed
*
X9AA5       EQU    $9AA5           ;set R12 to $BD00
X9C98       EQU    $9C98           ;output err msg
X9D11       EQU    $9D11           ;Default TAB table
X9D14       EQU    $9D14           ;Edasm.AutoSt
X9D21       EQU    $9D21           ;JMP table
X9E55       EQU    $9E55           ;convert date/time to ASCII
X9F83       EQU    $9F83           ;copy right
XA70B       EQU    $A70B           ;cmd line input
XA75B       EQU    $A75B           ;chk for presence of 80-col card
XA788       EQU    $A788           ;reset I/O hooks
XA78A       EQU    $A78A           ;alternate entry point of $A788
DoHelp      EQU    $A7F1
XA872       EQU    $A872           ;Load EDASM.SWAP
XA8D1       EQU    $A8D1           ;vol/sub-dir header entry
NEWSW16     EQU    $D000           ;Modified version of Sweet16 lives here
XD610       EQU    $D610           ;printer init
XDD41       EQU    $DD41           ;init TAB tabke
XDE18       EQU    $DE18           ;Table of cmds (ASM,NEW,ONLINE etc)
XDFA2       EQU    $DFA2           ;Cmd SW16 jmp table
*
LoadAdrAsm  EQU    $6800
X7800       EQU    $7800           ;EdAsm.Asm's sub-module load/exec Addr
X9900       EQU    $9900           ;EdAsm.Ed's sub-module load/exec addr