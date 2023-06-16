;-------------------------------------------------------------------------------
; main.asm
; Author: Wei Wei
; Vesion: 1.1
; Last Edited: 12/27/2022
; Email: iamdoublewei@gmail.com

;--------------------------------------------------------------------------------
; MSP430 jump instruction encoding calculation (currently not used)
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

;--------------------------------------------------------------------------------
; MSP430 branch instruction (currently used)
; 0x4030(first word)      0x????(second word)
; branch base			  the obsolute address jump to
; example: br 0x5000 (0x4030 0x5000)
; jump to address 0x5000

;--------------------------------------------------------------------------------
; Assembly math benchmark (currently not used)
; benchmarks:
; 												; 8 bits math
; m8			mov.b	#0x02,R13				; multiplication
; 				mov.b	#0x04,R12
; 				mov.w   R13,&MPY32_MPY			; load operand 1 into multiplier
; 				mov.w   R12,&MPY32_OP2			; load operand 2 which triggers MPY
; 				mov.w   &MPY32_RESLO,R12		; move result into return register
; 				mov.b	#0x24,R13				; division
; 				mov.b	#0x04,R14
; 				call 	#div
; 				mov.b	#0x03,R13				; addition
; 				mov.b	#0x0C,R12
; 				add.b   R13,R12
; 				mov.b	#0x03,R13				; substraction
; 				mov.b	#0x0C,R12
; 				sub.b	R13,R12
; 												; 16 bits math
; m16			mov.w	#0x1002,R13				; multiplication
; 				mov.w	#0x0003,R12
; 				mov.w   R13,&MPY32_MPY			; load operand 1 into multiplier
; 				mov.w   R12,&MPY32_OP2			; load operand 2 which triggers MPY
; 				mov.w   &MPY32_RESLO,R12		; move result into return register
; 				mov.w	#0x3024,R13				; division
; 				mov.w	#0x0003,R14
; 				call 	#div
; 				mov.w	#0x2133,R13				; addition
; 				mov.w	#0x1CA0,R12
; 				add.w   R13,R12
; 				mov.w	#0x2009,R13				; substraction
; 				mov.w	#0x610A,R12
; 				sub.w	R13,R12
; 												; 32 bits math
; m32			mov.w   #0x0075,R14				; multiplication
; 				mov.w   #0x00A8,R15
; 				mov.w   #0x00E7,R12
; 				mov.w   #0x0038,R13
; 				mov.w   R12,&MPY32_MPY32L		; load operand 1 Low into multiplier
; 				mov.w   R13,&MPY32_MPY32H		; load operand 1 High into multiplier
; 				mov.w   R14,&MPY32_OP2L			; load operand 2 Low into multiplier
; 				mov.w   R15,&MPY32_OP2H			; load operand 2 High, trigger MPY
; 				mov.w   &MPY32_RES0,R12			; ready low 16-bits for return
; 				mov.w   &MPY32_RES1,R13			; ready high 16-bits for return
; 				mov.w   #0x1000,R12				; division
; 				mov.w   #0x1116,R13
; 				mov.w   #0x000A,R14
; 				call	#div
; 				mov.w   #0x1000,R14				; addition
; 				mov.w   #0x0116,R15
; 				mov.w   #0x000A,R12
; 				mov.w   #0x0038,R13
; 				add.w   R14,R12
; 				addc.w  R15,R13
; 				mov.w   #0x0305,R14				; substraction
; 				mov.w   #0x10CA,R15
; 				mov.w   #0x3002,R12
; 				mov.w   #0x4035,R13
; 				sub.w	R14,R12
; 				subc.w	R15,R13

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
												; all the variables used in assembly is defined in C++ to
												; avoid compiler SRAM overwrite issue between C++ and assembly
				.global nop_value,br_base,free_address,checkpoint_buffer,update_avail,rx_buffer,sizerx,init,check_update
												; benchmark
;				.global math,matrix
setup_gpio     	bic.b   #BIT0,&P1OUT            ; clear P1.0 output latch for a defined power-on state
            	bis.b   #BIT0,&P1DIR            ; set P1.0 to output direction
		     	bic.b   #BIT1,&P1OUT            ; clear P1.1 output latch for a defined power-on state
            	bis.b   #BIT1,&P1DIR            ; set P1.1 to output direction
unlock_gpio  	bic.w   #LOCKLPM5,&PM5CTL0      ; disable the GPIO power-on default high-impedance mode to activate
                                            	; previously configured port settings
;setup_adc12  	mov.w   #ADC12SHT0_2+ADC12ON,&ADC12CTL0 ; 16x
;            	bis.w   #ADC12SHP,&ADC12CTL1    ; ADCCLK = MODOSC; sampling timer
;            	bis.w   #ADC12RES_2,&ADC12CTL2  ; 12-bit conversion results
;            	bis.w   #ADC12INCH_2,&ADC12MCTL0; A2 ADC input select; Vref=AVCC
;            	bis.w   #ADC12IE0,&ADC12IER0    ; Enable ADC conv complete interrupt
;setup_timer     mov.w   #CCIE,&TA0CCTL0         ; TACCR0 interrupt enabled
;            	mov.w   #50000,&TA0CCR0
;            	mov.w   #TASSEL__SMCLK+MC__CONTINOUS,&TA0CTL  ; SMCLK, continuous mode
;            	nop
;            	bis.w   #GIE,SR            		; Enable interrupt
;            	nop                             ; for debug
				call 	#init

_loop			call 	#math					; benchmark
				call	#matrix
				call 	#check_update
    			cmp.b 	#0x01,update_avail     	; compare with #1 value
    			jnz 	_loop      	 			; repeat loop if not equal
				call 	#decode_update
				jmp 	_loop

;--------------------------------------------------
; Function: 	decode_update
; Description:  decode and update packet stored in rx_buffer
; 				header byte definition: xx        xxxxxx,xxxxxxxx
;										opcode    original length
; 										opcode: indicate which update operation.
;												0 - insert
;												1 - modify
;												2 - delete
; 												3 - copy
; 										original length(insert): the number of words copy from insert point to new memory space.
; 										original length(modify): the number of words copy to the original memory space.
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
; Note: 		Ssme duplicated code presented for clean design and easy reading.

;--------------------------------------------------
; Register used:R10: header/op code

decode_update:	mov.w	rx_buffer,R10		 	; read header
	        	and.w	#1100000000000000b,R10	; bit masking, clear lower 14 bits to extract opcode
   				cmp 	#0000000000000000b,R10  ; compare with value
    			jz 		insert      	 		; jump if equal
				cmp 	#0100000000000000b,R10
    			jz 		modify
				cmp 	#1000000000000000b,R10
    			jz 		delete
				cmp 	#1100000000000000b,R10
    			jz 		copy

;--------------------------------------------------
; Register used:R9:  header/original length
;				R8:  destination address
;				R7:  length
; 				R6:  data start address
;				R5:  free memory start address

insert											; load values to registers
				mov.w	rx_buffer+2,R8			; destination address
	   			mov.w	rx_buffer+4,R7			; length
	   			mov.w	rx_buffer,R9		 	; read header
	        	and.w	#0011111111111111b,R9	; clear op code, R9 is original length now
				mov.w	#(rx_buffer+6),R6		; data start address
				mov.w	free_address,R5			; free memory start address
												; backup memory at inserting point and replace with branch instruction at
												; inserting point
				mov.w	0(R8),0(R5)				; copy
				mov.w	br_base,0(R8)			; write the branch instruction first word
				mov.w	2(R8),2(R5)				; copy
				mov.w	R5,2(R8)				; write the branch instruction second word
				add.w	#4,R5					; increment free memory start address
				add.w	#4,R8					; increment destination address
				sub.w   #2,R9                  	; update R9
												; backup the rest of unused memory and replace with nop instruction
insert_l1		cmp 	#0,R9    				; compare with value
				jz 		insert_l2      	 		; jump if equal
				mov.w	0(R8),0(R5)				; copy
				mov.w	nop_value,0(R8)			; write nop instruction
				add.w	#2,R5					; increment free memory start address
				add.w	#2,R8					; increment destination address
				dec.w   R9                     	; decrement R9
				jmp		insert_l1
												; copy the update instructions to the new allocated memory
insert_l2		cmp		#0,R7					; update done?
				jz 		insert_l3      	 		; jump if equal
				mov.w	0(R6),0(R5)				; copy
				add.w	#2,R6
				add.w	#2,R5
				dec.w   R7                   	; decrement R7
				jmp		insert_l2
												; write branch instruction jump back to the original code space
insert_l3		mov.w	br_base,0(R5)			; write the branch instruction first word
				mov.w	R8,2(R5)				; write the branch instruction second word
				add.w	#4,R5
												; update free address
				mov.w	R5,free_address
				jmp		cleanup

;--------------------------------------------------
; Register used:R9: header/original length
;				R8: destination address
;				R7: replaced length
; 				R6: data start address
;				R5: free memory start address
;				R4: modified length

modify											; load values to registers
				mov.w	rx_buffer+2,R8			; destination address
	   			mov.w	rx_buffer+4,R7			; length
	   			mov.w	rx_buffer,R9		 	; read header
	        	and.w	#0011111111111111b,R9	; clear op code, R9 is original length now
				mov.w	#(rx_buffer+8),R6		; data start address
				mov.w	free_address,R5			; free memory start address
				mov.w	rx_buffer+6,R4			; mlength
												; modify the original code space
modify_l1		cmp 	#0,R9    				; compare with value
				jz 		modify_l2      	 		; jump if equal
				mov.w	0(R6),0(R8)				; copy
				add.w	#2,R6					; increment data start address
				add.w	#2,R8					; increment destination address
				dec.w   R9                      ; decrement R9
				dec.w   R7                     	; decrement R7
				dec.w	R4						; decrement R4
				jmp		modify_l1
												; check if need to copy to new allocated memory
				cmp		#0,R7					; modify done?
				jz 		modify_l2      	 		; jump if equal
				mov.w	br_base,0(R8)			; write the branch instruction first word
				mov.w	R5,2(R8)				; write the branch instruction second word
				add.w	#4,R8					; update R8
				sub.w   #2,R4                   ; update R4
												; backup the rest of unused memory and replace with nop instruction
modify_l2		cmp 	#0,R4    				; compare with value
				jz 		modify_l3      	 		; jump if equal
				mov.w	nop_value,0(R8)			; write nop instruction
				add.w	#2,R8					; increment destination address
				dec.w   R4                     	; decrement R4
				jmp		modify_l2
												; copy the update instructions to the new allocated memory
modify_l3		cmp		#0,R7					; modify done?
				jz 		modify_l4      	 		; jump if equal
				mov.w	0(R6),0(R5)				; copy
				add.w	#2,R6
				add.w	#2,R5
				dec.w   R7                   	; decrement R7
				jmp		modify_l3
												; write branch instruction jump back to the original code space
modify_l4		mov.w	br_base,0(R5)			; write the branch instruction first word
				mov.w	R8,2(R5)				; write the branch instruction second word
				add.w	#4,R5
												; update free address
				mov.w	R5,free_address
				jmp		cleanup

;--------------------------------------------------
; Note: assume the deleted code block is at least 2 words, so the branch instruction can be fit inside
; Register used:R8: destination address
;				R7: length
; 				R6: end address jump to

delete											; load values to registers
				mov.w	rx_buffer+2,R8			; destination address
	   			mov.w	rx_buffer+4,R7			; length
	   											; calculate end address (the address jump to)
	   			mov.w	R7,R6
	   			rla.w	R6						; multiply by 2 (length is in words)
	   			add.w	R8,R6
				mov.w	br_base,0(R8)			; write the branch instruction first word
				mov.w	R6,2(R8)				; write the branch instruction second word
				add.w	#4,R8
				sub.w	#2,R7
delete_l1		cmp 	#0,R7    				; delete done?
				jz 		delete_l2      	 		; jump if equal
				mov.w	nop_value,0(R8)			; write nop instruction
				add.w	#2,R8					; increment destination address
				dec.w   R7                     	; decrement R7
				jmp		delete_l1
delete_l2		jmp		cleanup

;--------------------------------------------------
; Register used:R8: destination address
;				R7: length
; 				R6: source

copy											; load values to registers
				mov.w	rx_buffer+2,R8			; destination address
	   			mov.w	rx_buffer+4,R7			; length
				mov.w	rx_buffer+6,R6			; source
copy_l1			cmp		#0,R7					; copy done?
				jz 		copy_l2      	 		; jump if equal
				mov.w	0(R6),0(R8)				; copy
				add.w	#2,R6
				add.w	#2,R6
				dec.w   R7                  	; decrement R7
				jmp		copy_l1
copy_l2			jmp		cleanup

cleanup			mov.b	#0x00,update_avail
				ret

;--------------------------------------------------
; Function: 	checkpoint
; Description:  checkpoint runtime states or update states

   				cmp 	#0000000000000000b,R10  ; compare with value
    			jz 		insert      	 		; jump if equal
checkpoint:		cmp.b 	#0x01,update_avail     	; compare with #1 value
    			jz 		ckpt_updt      			; backup update if equal
ckpt_rt			push.w 	R4
				push.w	R5
				push.w	R6
				push.w	R7
				push.w	R8
				push.w	R9
				push.w	R10
				push.w	R11
				push.w	R12
				push.w	R13
				push.w	R14
				push.w	R15
				mov.w	#checkpoint_buffer,R4
ckpt_rt_l1		cmp		#__STACK_END,SP     	; compare if reach the end of stack
    			jz 		exit_ckpt      			; finsih backup stack if equal
			   	pop.w	0(R4)
				add.w	#2,R4
				jmp 	ckpt_rt_l1
ckpt_updt 		mov.w	R10,checkpoint_buffer
ckpt_updt_ins   cmp 	#0000000000000000b,R10  ; insert?
    			jnz 	ckpt_updt_mod      	 	; if not jump
				mov.w	R9,checkpoint_buffer+2
				mov.w	R8,checkpoint_buffer+4
				mov.w	R7,checkpoint_buffer+6
				mov.w	R6,checkpoint_buffer+8
				mov.w	R5,checkpoint_buffer+10
				jmp		exit_ckpt
ckpt_updt_mod	cmp 	#0100000000000000b,R10	; modify?
    			jnz 	ckpt_updt_decpy			; if not jump
    			mov.w	R9,checkpoint_buffer+2
				mov.w	R8,checkpoint_buffer+4
				mov.w	R7,checkpoint_buffer+6
				mov.w	R6,checkpoint_buffer+8
				mov.w	R5,checkpoint_buffer+10
				mov.w	R4,checkpoint_buffer+12
				jmp		exit_ckpt
ckpt_updt_decpy	mov.w	R8,checkpoint_buffer+4	; backup delete or copy
				mov.w	R7,checkpoint_buffer+6
				mov.w	R6,checkpoint_buffer+8
exit_ckpt		ret

;---------------------------------------------------------------------
; Function: 	wait
; Description:  about 1 sec time delay

wait:       	mov.w   #50000,R5              	; delay to R15
wait_l1     	dec.w   R5                     	; decrement R15
            	jnz     wait_l1                 ; delay over?
            	ret

;---------------------------------------------------------------------
; Function: 	div
; Description:  unsigned 32/16 division, R12|R13 / R14 = R15, Remainder
; in R12
; Register used:R12: dividend high word
;               R13: dividend low word
;               R14: divisor
;               R15: result
;               R11: counter

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
; ADC12_ISR

;ADC12_ISR										; ADC12 interrupt service routine
;            	add.w   &ADC12IV,PC             ; add offset to PC
;            	reti                            ; Vector  0:  No interrupt
;            	reti                            ; Vector  2:  ADC12MEMx Overflow
;            	reti                            ; Vector  4:  Conversion time overflow
;            	reti                            ; Vector  6:  ADC12HI
;            	reti                            ; Vector  8:  ADC12LO
;            	reti                            ; Vector 10:  ADC12IN
;            	jmp     MEM0                    ; Vector 12:  ADC12MEM0 Interrupt
;            	reti                            ; Vector 14:  ADC12MEM1
;            	reti                            ; Vector 16:  ADC12MEM2
;            	reti                            ; Vector 18:  ADC12MEM3
;            	reti                            ; Vector 20:  ADC12MEM4
;            	reti                            ; Vector 22:  ADC12MEM5
;            	reti                            ; Vector 24:  ADC12MEM6
;            	reti                            ; Vector 26:  ADC12MEM7
;            	reti                            ; Vector 28:  ADC12MEM8
;            	reti                            ; Vector 30:  ADC12MEM9
;            	reti                            ; Vector 32:  ADC12MEM10
;            	reti                            ; Vector 34:  ADC12MEM11
;            	reti                            ; Vector 36:  ADC12MEM12
;            	reti                            ; Vector 38:  ADC12MEM13
;            	reti                            ; Vector 40:  ADC12MEM14
;            	reti                            ; Vector 42:  ADC12MEM15
;            	reti                            ; Vector 44:  ADC12MEM16
;            	reti                            ; Vector 46:  ADC12MEM17
;            	reti                            ; Vector 48:  ADC12MEM18
;            	reti                            ; Vector 50:  ADC12MEM19
;            	reti                            ; Vector 52:  ADC12MEM20
;            	reti                            ; Vector 54:  ADC12MEM21
;            	reti                            ; Vector 56:  ADC12MEM22
;            	reti                            ; Vector 58:  ADC12MEM23
;            	reti                            ; Vector 60:  ADC12MEM24
;            	reti                            ; Vector 62:  ADC12MEM25
;            	reti                            ; Vector 64:  ADC12MEM26
;            	reti                            ; Vector 66:  ADC12MEM27
;            	reti                            ; Vector 68:  ADC12MEM28
;            	reti                            ; Vector 70:  ADC12MEM29
;            	reti                            ; Vector 72:  ADC12MEM30
;            	reti                            ; Vector 74:  ADC12MEM31
;            	reti                            ; Vector 76:  ADC12RDY
;MEM0        	bic.b   #BIT0,&P1OUT            ; Clear LED as default
;            	cmp.w   #0x7FF,&ADC12MEM0       ; ADCMEM > 0.5*Vcc?
;            	jlo     ExitLPM0                ; No, exit ISR
;            	bis.b   #BIT1,&P1OUT            ; Yes, set LED
;            	call	#checkpoint
;ExitLPM0    	reti

;-------------------------------------------------------------------------------
; TIMER0_A0_ISR

;TIMER0_A0_ISR									; Timer0_A3 CC0 Interrupt Service Routine
;            	xor.b   #BIT0,&P1OUT            ; Toggle LED
;            	bis.w   #ADC12ENC+ADC12SC,&ADC12CTL0 ; Start ADC12 sampling/conversion
;            	add.w   #50000,&TA0CCR0         ; Add offset to TA0CCR0
;            	reti

;---------------------------------------------------------------------
; benchmark
math:
 												; 8 bits math
				mov.b	#0x02,R13				; multiplication
 				mov.b	#0x04,R12
 				mov.w   R13,&MPY32_MPY			; load operand 1 into multiplier
 				mov.w   R12,&MPY32_OP2			; load operand 2 which triggers MPY
 				mov.w   &MPY32_RESLO,R12		; move result into return register
 				mov.b	#0x24,R13				; division
 				mov.b	#0x04,R14
				call 	#div
 				mov.b	#0x03,R13				; addition
 				mov.b	#0x0C,R12
 				add.b   R13,R12
 				mov.b	#0x03,R13				; substraction
 				mov.b	#0x0C,R12
 				sub.b	R13,R12
 												; 16 bits math
				mov.w	#0x1002,R13				; multiplication
 				mov.w	#0x0003,R12
 				mov.w   R13,&MPY32_MPY			; load operand 1 into multiplier
 				mov.w   R12,&MPY32_OP2			; load operand 2 which triggers MPY
 				mov.w   &MPY32_RESLO,R12		; move result into return register
 				mov.w	#0x3024,R13				; division
 				mov.w	#0x0003,R14
 				call 	#div
 				mov.w	#0x2133,R13				; addition
 				mov.w	#0x1CA0,R12
 				add.w   R13,R12
 				mov.w	#0x2009,R13				; substraction
 				mov.w	#0x610A,R12
 				sub.w	R13,R12
 												; 32 bits math
				mov.w   #0x0075,R14				; multiplication
 				mov.w   #0x00A8,R15
 				mov.w   #0x00E7,R12
 				mov.w   #0x0038,R13
 				mov.w   R12,&MPY32_MPY32L		; load operand 1 Low into multiplier
 				mov.w   R13,&MPY32_MPY32H		; load operand 1 High into multiplier
 				mov.w   R14,&MPY32_OP2L			; load operand 2 Low into multiplier
 				mov.w   R15,&MPY32_OP2H			; load operand 2 High, trigger MPY
 				mov.w   &MPY32_RES0,R12			; ready low 16-bits for return
 				mov.w   &MPY32_RES1,R13			; ready high 16-bits for return
 				mov.w   #0x1000,R12				; division
 				mov.w   #0x1116,R13
 				mov.w   #0x000A,R14
 				call	#div
 				mov.w   #0x1000,R14				; addition
 				mov.w   #0x0116,R15
 				mov.w   #0x000A,R12
 				mov.w   #0x0038,R13
 				add.w   R14,R12
 				addc.w  R15,R13
 				mov.w   #0x0305,R14				; substraction
 				mov.w   #0x10CA,R15
 				mov.w   #0x3002,R12
 				mov.w   #0x4035,R13
 				sub.w	R14,R12
 				subc.w	R15,R13

math_end		ret

; mamul assembly example: https://github.com/khairanabila/nab-NN
;https://github.com/AgentANAKIN/Gender-Predictor-Neural-Network-in-C/blob/master/gpnnc.c
				.data
matrix:			;.usect ".matrix",4,2
				;mov.w	#0x0010,matrix
				;mov.w	#0x0004,matrix+2
m1_row			.word	0x0010
m1_col			.word	0x0004
m1				.word	0x0012, 0x0056, 0x0090, 0x0034
    			.word	0x0078, 0x0012, 0x0056, 0x0090
    			.word	0x0034, 0x0078, 0x0012, 0x0056
    			.word	0x0090, 0x0034, 0x0078, 0x0012
    			.word	0x0012, 0x0056, 0x0090, 0x0034
    			.word	0x0078, 0x0012, 0x0056, 0x0090
    			.word	0x0034, 0x0078, 0x0012, 0x0056
    			.word	0x0090, 0x0034, 0x0078, 0x0012
    			.word	0x0012, 0x0056, 0x0090, 0x0034
    			.word	0x0078, 0x0012, 0x0056, 0x0090
   			 	.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;m2_row			.word	0x0010
;m2_col			.word	0x0004
;m2				.word	0x0012, 0x0056, 0x0090, 0x0034
 ;   			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;   			 	.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;m3_row			.word	0x0010
;m3_col			.word	0x0004
;m3				.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;   			 	.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
;    			.word	0x0012, 0x0056, 0x0090, 0x0034
;    			.word	0x0078, 0x0012, 0x0056, 0x0090
;    			.word	0x0034, 0x0078, 0x0012, 0x0056
;    			.word	0x0090, 0x0034, 0x0078, 0x0012
												; matrix copy
;		       	mov.w 	SP,R4					; matrix 1 start address
;				push.b	0x12
;				push.b 	0x56
;				push.b	0x90
;				push.b	0x34
;				push.b	0x78
;				push.b	0x12
;				push.b 	0x56
;				push.b  0x90
;				push.b	0x34
;				push.b	0x78
;				push.b 	0x12
;				push.b	0x56
;				push.b	0x90
;				push.b 	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b 	0x12
;				push.b 	0x56
;				push.b 	0x90
;				push.b 	0x34
;				push.b	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b 	0x90
;				push.b	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b	0x90
;				push.b 	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b	0x12
;				push.b  0x56
;				push.b 	0x90
;				push.b 	0x34
;				push.b	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b 	0x90
;				push.b	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b	0x90
;				push.b 	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b	0x12
;				push.b 	0x56
;				push.b 	0x90
;				push.b 	0x34
;				push.b	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b 	0x90
;				push.b	0x34
;				push.b 	0x78
;				push.b 	0x12
;				push.b 	0x56
;				push.b	0x90
;				push.b 	0x34
;				push.b 	0x78
;				push.b 	0x12
;				mov.w	SP+1,R5					; matrix 2 start address
;				mov.w	R4,R6
;matrix_l1		cmp		R6,R5					; copy done?
;				push.b	0(R6)
;				dec		R6
;				jnz 	matrix_l1      	 		; jump if not equal
;												; matrix addition
;				mov.w	R4,R6					; R6 matrix 1
;				mov.w	R5,R7					; R7 matrix 2
;matrix_l2		mov.b	0(R6),R8
;				mov.b	0(R7),R9
;				add.b	R8,R9
;				mov.w	R9,0(R7)				; store result to matrix 2
;				dec		R6
;				dec		R7
;				cmp		R6,R5
;				jnz		matrix_l2				; jump if equal

				.text
matrix_end		ret

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            	.global __STACK_END
            	.sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            	.sect   ".reset"                ; MSP430 RESET Vector
            	.short  RESET                   ;
            	;.sect   ADC12_VECTOR            ; ADC12 Vector
            	;.short  ADC12_ISR               ;
;            	.sect   TIMER0_A0_VECTOR        ; Timer0_A3 CC0 Interrupt Vector
;            	.short  TIMER0_A0_ISR
            	.end
