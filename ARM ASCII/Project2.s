@@@ OPEN INPUT FILE, READ INTEGER FROM FILE, PRINT IT, CLOSE INPUT FILE
.equ SWI_Open, 0x66 @open a file
	.equ SWI_Close,0x68 @close a file
	.equ SWI_PrChr,0x00 @ Write an ASCII char to Stdout
	.equ SWI_PrStr, 0x69 @ Write a null-ending string 
	.equ SWI_RdStr,0x6a @ Read an String from a file
	.equ SWI_PrInt,0x6b @ Write an Integer
	.equ SWI_RdInt,0x6c @ Read an Integer from a file
	.equ Stdout, 1 @ Set output target to be Stdout
	.equ SWI_Exit, 0x11 @ Stop execution
	.global _start
	.text
_start:
@ == Open an input file for reading =============================
@ if problems, print message to Stdout and exit
	ldr r0,=InFileName @ set Name for input file
	mov r1,#0 @ mode is input
	
	swi SWI_Open @ open file for input
	bcs InFileError @ Check Carry-Bit (C): if= 1 then ERROR
@ Save the file handle in memory:
	ldr r1,=InFileHandle @ if OK, load input file handle
	str r0,[r1] @ save the file handle
@ == Read integers until end of file =============================
RLoop:
	mov r5,#0
    ldr r0,=InFileHandle @ load input file handle
	ldr r0,[r0]
	ldr r1,=CharArray
	mov r2,#80
	swi SWI_RdStr @ read the integer into R0
	bcs EofReached @ Check Carry-Bit (C): if= 1 then EOF reached
@ print the String to Stdout
	
	@ print new line
	mov R0,#Stdout
	mov r7, r1

	
	mov r4, r7

	bge CharacterLoop
	bal RLoop @ keep reading till end of file
	
CharacterLoop:
	@Get Characters using pointer
	ldr r7, =CharArray
	ldrb r0,[r4]
	add r4,r4,#1
	mov r1,r0
	cmp r1,#0
	bls countspot
	mov R0,#Stdout
	swi SWI_PrInt
	
	add r5,r5,#1
	@ NEW LINE
	ldr r1, =NL
	swi SWI_PrStr
	
	bge CharacterLoop
	
countspot:	
	mov R0, #Stdout @ print last message
	ldr R1, =Count
	swi SWI_PrStr
	mov R0,#Stdout @ mode is Output view
	mov r1, r5 @ integer to print
	swi SWI_PrInt
	ldr r1, =NL
	swi SWI_PrStr
	bge RLoop
EofReached:
	

@ == Close a file ===============================================
	ldr R0, =InFileHandle @ get address of file handle
	ldr R0, [R0] @ get value at address
	swi SWI_Close
	
Exit:
	swi SWI_Exit @ stop executing 
InFileError:
	mov R0, #Stdout
	ldr R1, =FileOpenInpErrMsg
	swi SWI_PrStr 
	bal Exit @ give up, go to end
	.data
	.align
InFileHandle: .skip 4
InFileName: .asciz "udp.dat"
FileOpenInpErrMsg: .asciz "Failed to open input file \n"
Count: .asciz "Count: "
CharArray: .skip 80
NL: .asciz "\n" @ new line 

.end