Name          : EXTERNALS.S
End of file   :      884
This file was generated using the DiskBrowser utility with minimal editing.
It is meant for viewing purposes only.

**************************************************
* EXTERN labels used by Assembler
* The 1024-byte buffers are used by ProDOS8 for I/O
*
X0800       EQU    $0800
X6E00       EQU    $6E00           ;1024-byte buf for MACRO defn file if List to File
MacExpBuf   EQU    $7200           ;$7200-$727F Use to expand macro lines
MacStrBuf   EQU    $7280           ;$7280-$72FF Use to store string parms passed
OLDataB     EQU    $7300           ;Online data buf
LstDBuf     EQU    $7300           ;256-bytes circular data buf for LST file
X7400       EQU    $7400           ;1024-bytes buf for LST/MACRO file
ObjDataB    EQU    $BD00           ;128-byte data buf for obj code
AsmParmB    EQU    $BD80           ;128-byte buf use to pass by editor to pass parm to asmbler
XA100       EQU    $A100           ;1024-bytes buf for OBJ file
XA500       EQU    $A500           ;1024-bytes buf for SRC file
*XA900 EQU $A900 ;1024-bytes buf for INCLUDE file
*
HeaderT     EQU    $BC00           ;Table of ptrs to 1st node of singly linked lists
*=================================================