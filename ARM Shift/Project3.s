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
		mov r3,#0 @Left Over Character False
		swi SWI_Open @ open file for input
		bcs InFileError @ Check Carry-Bit (C): if= 1 then ERROR
	@ Save the file handle in memory:
		ldr r1,=InFileHandle @ if OK, load input file handle
		str r0,[r1] @ save the file handle
	@ == Read integers until end of file =============================
	RLoop:
		ldr r0,=InFileHandle @ load input file handle
		ldr r0,[r0]
		ldr r1,=CharArray
		mov r2,#80
		swi SWI_RdStr @ read the integer into R0
		bcs EofReached @ Check Carry-Bit (C): if= 1 then EOF reached
	@ print the String to Stdout
	@ print new line
		mov R0,#Stdout
		mov r4, r1
		bge CharacterLoop
		bal RLoop @ keep reading till end of file
	
	CharacterLoop:
		@Get Characters using pointer	
		ldrb r0,[r4]
		add r4,r4,#1 
		mov r1,r0
		cmp r1,#0
		bls RLoop
		add r5,r5,#1 @ Character Counter
		
		@Go to if its odd CharacterLoop16bit
		@Go to if even CharacterLoop8bit
		
		TST R5, #1			@Used the character counter to send to correct method
		BEQ CharacterLoop8bit
		BNE CharacterLoop16bit
		
		bge CharacterLoop
		
	CharacterLoop8bit: @second character in the group of 2
		mov r7,r1
		bge PutTogether
		
	CharacterLoop16bit: 	@first character in the group of 2
		MOV r1, r1, LSL #8 	@Shifts the value over 8 bits (=16bits)
		mov r6,r1 			
		bge CharacterLoop
	
	PutTogether:
		add r7,r7,r6 		@Adds the 8 Bit # to the 16 Bit
		add r9,r9,r7 		@Adds the decimal of the 2 chars to the sum
		mov r6,#0			@Clears r6 and r7
		mov r7,#0
		TST r9,#0x10000		@Checking for carry bit (aka 17bit)
		BNE Carry			@if there's a carry bit it branches to the carry method
		
		bge CharacterLoop @in no carry it repeats the character loop
		
	Carry:
		sub r9,r9,#0x10000
		add r9,r9,#1
		
		bge CharacterLoop
	
	EofReached:
		@Is there 1 more character to add?
		cmp r6, #0
		BNE PutTogether
		
	@ == Close a file ===============================================
		ldr R0, =InFileHandle @ get address of file handle
		ldr R0, [R0] @ get value at address
		swi SWI_Close
	
	Exit:
		mov R0, #Stdout 
		
		@Character Count
		ldr R1, =Count
		swi SWI_PrStr
		mov r1, r5 @ integer to print
		swi SWI_PrInt
		ldr r1, =NL
		swi SWI_PrStr
	
		@Sum
		ldr R1, =Sum
		swi SWI_PrStr
		mov r1, r9 @ integer to print
		swi SWI_PrInt
		ldr R1, =NL
		swi SWI_PrStr
		
		@Check Sum
		ldr R1, =CS
		swi SWI_PrStr
		MVN R9,R9
		Mov r8,#0x10000
		sub r8,r8,#1
		and r9,r9,r8
		mov r1, r9 @ integer to print
		swi SWI_PrInt
	
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
	Count: .asciz "Characters: "
	CS: .asciz "Checksum: "
	Sum: .asciz "Sum:"
	Test2: .asciz "Current Sum"
	CharArray: .skip 80
	NL: .asciz "\n" @ new line 
	
	.end