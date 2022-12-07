;-------------------------------------------------------------------------------
; main.asm
; Author: Wei Wei
; Vesion: 1.0
; Last Edited: 8/24/2022
; Email: iamdoublewei@gmail.com

;--------------------------------------------------------------------------------
; MSP430 jump instruction encoding calculation
; 001   ,         111    ,      0100010011
; opcode, unconditional jump, 10 bits 2's complement representation offset
; formula: PC(new) = PC(old) + 2 + PC(offset) * 2
; in this complementation we use 001,111,0000000000(0x3C00) + calculation offset
;
; MSP430 jump instruction calculation
; jmp 0
; jmp to the absolute address related to start address
; start address of the program: 0x4000 (can be set through .cmd file)
; to calculate the jmp instruction, use current address - start address

;-------------------------------------------------------------------------------
; Research Notes:
; 1. To serve the research purpose and avoid some function call instructions or jump
; 	 instructions. This project intentionally make some duplicated code which may looks
;	 unnecessary and messy.
; Current Thinking:
; 1. How to define update and decode, should we seperate into two functions or combine
; 2. Unavoidable to replace a jump instruction. Maybe also need to remove backup size from encoding
; 3. Seperate modify into replacement and insert

;-------------------------------------------------------------------------------
            	.cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            	.def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            	.text                           ; Assemble into program memory.
            	.retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            	.retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       	mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     	mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main start from here
;-------------------------------------------------------------------------------

_main

MPY32_MPY 		.equ 	0x04C0
MPY32_OP2		.equ 	0x04C8
MPY32_RESLO		.equ 	0x04CA
MPY32_MPY32L	.equ    0x04D0
MPY32_MPY32H	.equ    0x04D2
MPY32_OP2L		.equ	0x04E0
MPY32_OP2H		.equ	0x04E2
MPY32_RES0		.equ	0x04E4
MPY32_RES1		.equ	0x04E6

;-------------------------------------------------------------------------------
; Variable Definitions
; 1. nop_value: raw value for nop instruction
; 2. br_base: the first word value for branch instruction
; 3. free_address: the starting address of free memory space
; 4. update_avail: 1: update packet available in rx_buffer
; 5. sizerx: the size of update packet stored in rx_buffer in bytes
; 6. rx_buffer: stored received update packet
;    byte 0: opcode
;	 byte 1: destination address lower 8 bits
;	 byte 2: destination address higher 8 bits
;	 byte 3: length of the following update data in words(16 bits)
; 	 byte 4: update data 0 lower 8 bits
;	 byte 5: update data 0 higher 8 bits
;	 ...

_init
				.text
												; All the variables used in assembly is defined in C++ to
												; avoid compiler SRAM overwrite issue between C++ and assembly
				.global nop_value,br_base,free_address,update_avail,rx_buffer,sizerx,init,check_update
SetupP1     	bic.b   #BIT0,&P1OUT            ; Clear P1.0 output latch for a defined power-on state
            	bis.b   #BIT0,&P1DIR            ; Set P1.0 to output direction
SetupP2     	bic.b   #BIT1,&P1OUT            ; Clear P1.1 output latch for a defined power-on state
            	bis.b   #BIT1,&P1DIR            ; Set P1.1 to output direction
UnlockGPIO  	bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default high-impedance mode to activate
                                            	; previously configured port settings
				call 	#init

_loop			call 	#benchmarks
				call 	#check_update
    			cmp.b 	#0x01,update_avail     	; Compare with #1 value
    			jnz 	_loop      	 			; Repeat loop if not equal
				call 	#decode_update
				jmp 	_loop

;--------------------------------------------------
; Function: 	decode_update
; Description:  decode and update packet stored in rx_buffer
; 				header byte definition: xx      xxxxxx,xxxxxxxx
;										opcode  original length
; 										opcode: indicate which update operation.
; 										length(insert): the number of word copy from insert point to new memory space.
; 										length(modify): the number of words copy to the original memory space.
;				destination definition: special definition for insert
;										always point to a start address of an instruction (instruction length are varied)
;										the length of the pointed instruction is defined in header(original length)
;				example insert packet:  header (2 byte)
;										destination address (2 bytes)
;										length (2 byte)
;										data1 (2 bytes)
;										data2 (2 bytes)
;										...
;				packet design notes: 	reason to use 2 byte size in data is the assembly instruction size can be varied in words.
;										header or length can be extend to increase the size of original length as needed.
; Register used:R10: header/original length
;				R9:  destination address
;				R8:  length
; 				R7:  data start address
;				R6:  free memory start address

;----------------------------
; to do: change op => R9, use a temp register instead.
; so R9 can dedicated to address pointer
; current update, if need to replace last 2 instructions, one empty space will be left.

decode_update:	mov.w	rx_buffer,R10		 	; read header
	        	and.w	#1100000000000000b,R10	; bit masking, clear lower 14 bits to extract opcode
   				cmp 	#0000000000000000b,R10  ; Compare with value
    			jz 		insert      	 		; jump if equal
				cmp 	#0100000000000000b,R10
    			jz 		modify
				cmp 	#1000000000000000b,R10
    			jz 		delete
				cmp 	#1100000000000000b,R10
    			jz 		copy
												; load values to registers
insert			mov.w	rx_buffer+2,R9			; destination address
	   			mov.w	rx_buffer+4,R8			; length
	   			mov.w	rx_buffer,R10		 	; read header
	        	and.w	#0011111111111111b,R10	; clear op code, R10 is original length now
				mov.w	#(rx_buffer+6),R7		; data start address
				mov.w	free_address,R6			; free memory start address
												; backup memory at inserting point and replace with branch instruction at
												; inserting point
				mov.w	0(R9),0(R6)				; copy
				mov.w	br_base,0(R9)			; write the branch instruction first word
				mov.w	2(R9),2(R6)				; copy
				mov.w	R6,2(R9)				; write the branch instruction second word
				add.w	#4,R6					; increment free memory start address
				add.w	#4,R9					; increment destination address
				sub.w   #2,R10                  ; update R10
												; backup the rest of unused memory and replace with nop instruction
insert_l1		cmp 	#0,R10    				; Compare with value
				jz 		insert_l2      	 		; jump if equal
				mov.w	0(R9),0(R6)				; copy
				mov.w	nop_value,0(R9)			; write nop instruction
				add.w	#2,R6					; increment free memory start address
				add.w	#2,R9					; increment destination address
				dec.w   R10                     ; Decrement R10
				jmp		insert_l1
												; copy the update instructions to the new allocated memory
insert_l2		cmp		#0,R8					; Update done?
				jz 		insert_l3      	 		; jump if equal
				dec.w   R8                   	; Decrement R8
				mov.w	0(R7),0(R6)				; copy
				add.w	#2,R7
				add.w	#2,R6
				jmp		insert_l2
												; write branch instruction jump back to the original code space
insert_l3		mov.w	br_base,0(R6)			; write the branch instruction first word
				mov.w	R9,2(R6)				; write the branch instruction second word
				add.w	#4,R6
												; update free address
				mov.w	R6,free_address
				jmp		cleanup

;--------------------------------------------------
; modify/replace
modify			jmp		cleanup

;--------------------------------------------------
; delete
delete			jmp		cleanup

;--------------------------------------------------
; copy
copy			jmp		cleanup

cleanup			mov.b	#0x00,update_avail
				ret

;-------------------------------------------------------------------------------
; Utility Functions
;---------------------------------------------------------------------

;---------------------------------------------------------------------
; Function: 	wait
; Description:  about 1 sec time delay

wait:       	mov.w   #50000,R5              	; Delay to R15
wait_l1     	dec.w   R5                     	; Decrement R15
            	jnz     wait_l1                 ; Delay over?
            	ret

;---------------------------------------------------------------------
; Function: 	div
; Description:  unsigned 32/16 division, R12|R13 / R14 = R15, Remainder
; in R12
; Register used:R12 is dividend high word
;               R13 is dividend low word
;               R14 is divisor
;               R15 is result
;               R11 is counter

div:        	clr     R15        				;1C
            	clr     R12        				;only 16/16 really
            	mov     #17,R11        			;2C    -4C ENTRY
div_l1     		cmp     R14,R12        			;1C
            	jlo     div_l2        			;2C
            	sub     R14,R12        			;1C    -4C WORST CASE
div_l2    		rlc     R15        				;1C
            	jc      div_l4        			;2C
            	dec     R11        				;1C
            	jz      div_l4        			;2C    -6C ON LAST BIT
            	rla     R13        				;1C
            	rlc     R12        				;1C
            	jnc     div_l1        			;2C
				sub     R14,R12        			;1C
            	setc            				;2C
            	jmp     div_l2        			;2C    -15C WORST
div_l4	    	ret            					;3C

;-------------------------------------------------------------------------------
; Benchmarks
; 1. 8 bit math: multiplication, division, subtraction and addition
; 2. 16 bit math: multiplication, division, subtraction and addition
; 3. 32 bit math: multiplication, division, subtraction and addition

benchmarks:										; 8 bits math
m8				mov.b	#0x0002,R13				; Multiplication
				mov.b	#0x0004,R12
				mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
				mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
				mov.w   &MPY32_RESLO,R12		; Move result into return register
				mov.b	#0x0003,R13				; Addition
				mov.b	#0x000c,R12
				add.b   R13,R12
				;br 		#0x5000					; hex value 0x4030 0x5000
												; 16 bits math
;				mov.w	#0x00e7,R13
;				mov.w	#0x000c,R12
;				add.w   R13,R12
												; 32 bits math
m32				mov.w   #0x0075,R14
				mov.w   #0x00a8,R15
				mov.w   #0x00e7,R12
				mov.w   #0x0038,R13
				add.w   R14,R12
				addc.w  R15,R13 				; Addition
				mov.w   #0x0075,R14
				mov.w   #0x00a8,R15
				mov.w   #0x00e7,R12
				mov.w   #0x0038,R13
				mov.w   R12,&MPY32_MPY32L		; Load operand 1 Low into multiplier
				mov.w   R13,&MPY32_MPY32H		; Load operand 1 High into multiplier
				mov.w   R14,&MPY32_OP2L			; Load operand 2 Low into multiplier
				mov.w   R15,&MPY32_OP2H			; Load operand 2 High, trigger MPY
				mov.w   &MPY32_RES0,R12			; Ready low 16-bits for return
				mov.w   &MPY32_RES1,R13			; Ready high 16-bits for return
				mov.w   #0x0075,R14
				mov.w   #0x00a8,R15
				mov.w   #0x00e7,R12
				mov.w   #0x0038,R13

				ret
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            	.global __STACK_END
            	.sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            	.sect   ".reset"                ; MSP430 RESET Vector
            	.short  RESET
            
