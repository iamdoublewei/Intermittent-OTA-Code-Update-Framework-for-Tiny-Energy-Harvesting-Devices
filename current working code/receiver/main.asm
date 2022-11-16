;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
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

_init
				.text
				.global update_avail,rx_buffer,sizerx,init,check_update
SetupP1     	bic.b   #BIT0,&P1OUT            ; Clear P1.0 output latch for a defined power-on state
            	bis.b   #BIT0,&P1DIR            ; Set P1.0 to output direction
SetupP2     	bic.b   #BIT1,&P1OUT            ; Clear P1.1 output latch for a defined power-on state
            	bis.b   #BIT1,&P1DIR            ; Set P1.1 to output direction
UnlockGPIO  	bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings
				call 	#init

_loop
;-------------------------------------------------------------------------------
; Benchmarks
; 1. 8 bit math: multiplication, division, subtraction and addition
; 2. 16 bit math: multiplication, division, subtraction and addition
; 3. 32 bit math: multiplication, division, subtraction and addition
;-------------------------------------------------------------------------------
math8bit		mov.b	#0x0002,R13				; Multiplication
				mov.b	#0x0004,R12
				mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
				mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
				mov.w   &MPY32_RESLO,R12		; Move result into return register
				mov.b	#0x0003,R13				; Addition
				mov.b	#0x000c,R12
				add.b   R13,R12

;math16bit		mov.w	#0x00e7,R13
;				mov.w	#0x000c,R12
;				add.w   R13,R12
;				mov.w	#0x0002,R13
;				mov.w	#0x0004,R12
;				mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
;				mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
;				mov.w   &MPY32_RESLO,R12		; Move result into return register
;				mov.w   #0x0012,R13
;				mov.w   #0x003,R14
;				call 	#div

math32bit		mov.w   #0x0075,R14
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

				call 	#check_update
    			cmp.b 	#0x01,update_avail     	; Compare with #1 value
    			jnz 	_loop      	 			; Repeat loop if not equal
				call 	#decode_update
				jmp 	_loop

;--------------------------------------------------
; Function: 	deco_updt
; Description:  decode and update packet stored in rx_buffer
; Register used:R10: data start address
;				R9:	 current free address pointer
;				R8:  destination address
;               R7:  update data length
;               R6:  backup size
;--------------------------------------------------
; to do: change op => R9, use a temp register instead.
; so R9 can dedicated to address pointer
; current update, if need to replace last 2 instructions, one empty space will be left.
decode_update:	mov.w	rx_buffer,R9		 	; read op code
   				cmp 	#0x0000,R9     		 	; Compare with value
    			jnz 	modify      	 		; jump if not equal
    										; insert operation with backup instruction size = 1 tested
insert			mov.w	2(R10),R8				; destination address
; ;   			mov.w	4(R10),R7				; length
;    			mov.w	6(R10),R6				; backup size
;	    		add.w	#8,R10					; start data address
;	    		mov.w	free_addr,R9			; load free_addr
;				cmp		#2,R6					; based on backup size run different code
;				jnz		decode_ins1				; need testingggggggggggggggggggggggggggggggggggggggggggggggggggg
;				mov.w	-2(R8),0(R9)			; copy last two instruction to new location (1)
;				mov.w	0(R8),2(R9)				; copy last two instruction to new location	(2)
;				add.w	#4,R9					; update current free address
;				jmp 	decode_ins2
;decode_ins1	mov.w	0(R8),0(R9)				; copy last instruction to new location
;				add.w	#2,R9					; update current free address
;decode_ins2 	mov.w	free_addr,R11
;				sub.w	R8,R11					; calculate offset
;				sub.w	#2,R11
;				mov.w	R11,R13
;				mov.w	#2,R14
;				call 	#div					; R13/R14, result stored in R15
;				add.w	jmp_base,R15			; add jump base value
;				cmp		#2,R6					; write jump instruction in different location
;				jnz		decode_ins3
;				mov.w	R15,-2(R8)
;				jmp		update_ins
;decode_ins3	mov.w	R15,0(R8)
			;	mov.w	#0x3D13,0(R8)			; use precalculate value to test jump
;				jmp		update_ins
;update_ins		dec.w   R7                   	; Decrement R7
;				mov.w	0(R10),0(R9)
;				add.w	#2,R10
;				add.w	#2,R9
;				cmp		#0,R7
;	        	jnz     update               	; Update done?
;	        	sub.w	R9,R8					; Calculate jump back instruction
;	        								; should +2 to next instruction, and -2 to calculate offset, cancelled here
;	        	mov.w	R8,R13
;	        	mov.w	#2,R14
;	        	call	#div					; R13/R14, result stored in R15
;	        	and.w	#0000001111111111b,R15	; bit masking, clear upper 6 bits
;	        	add.w	jmp_base,R15
;	        	mov.w	R15,0(R9)
	        ;	mov.w	#0x3AE9,0(R9)			; Testing jump
;	        	add.w	#2,R9
	        	jmp		cleanup
modify			cmp 	#0x0001,R9
    			jnz 	delete
;    			nop
	        	jmp		cleanup
delete			cmp 	#0x0002,R9
    			jnz 	copy
;    			mov.w	2(R10),R8				; destination address
  ;  			mov.w	4(R10),R7				; length
 ;   			mov.w	free_addr,R11
;				sub.w	R8,R11					; calculate offset
;				sub.w	#2,R11
;				mov.w	R11,R13
;				mov.w	#2,R14
;				call 	#div					; R13/R14, result stored in R15
;				add.w	jmp_base,R15			; add jump base value
;				mov.w	R15,R8
	        	jmp		cleanup
copy			cmp 	#0x0003,R9
    			jnz 	cleanup
 ;  			mov.w	2(R10),R8				; destination address
 ;   			mov.w	4(R10),R7				; length
;decode_cop1 	dec.w   R7                   	; Decrement R7
;				mov.w	0(R10),0(R9)
;				add.w	#2,R10
;				add.w	#2,R9
;				cmp		#0,R7
;	        	jnz     decode_cop1             ; Done?
cleanup			;mov.w	R9,free_addr
				mov.b	#0x00,update_avail
				ret

;-------------------------------------------------------------------------------
; Utility Functions
;-------------------------------------------------------------------------------
;---------------------------------------------------------------------
; Function: 	wait
; Description:  about 1 sec time delay
;----------------------------------------------------------------------
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
;----------------------------------------------------------------------
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
; Stack Pointer definition
;-------------------------------------------------------------------------------
            	.global __STACK_END
            	.sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            	.sect   ".reset"                ; MSP430 RESET Vector
            	.short  RESET
            
