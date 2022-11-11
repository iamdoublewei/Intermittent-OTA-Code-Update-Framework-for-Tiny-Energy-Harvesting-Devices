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
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
 			.data
up_signal	.byte   0x0001
buffer:		.word	0x0000	 				; Pointer for the start of allocated update memory
free_addr	.word	0x4800	 				; Pointer for the start of allocated update memory
jmp_base	.word	0x3C00					; The base value (exclude offset) of unconditional jump
			.text
			.global getRxBufferAddress
			.global checkUpdate
_main
SetupP1     bic.b   #BIT0,&P1OUT            ; Clear P1.0 output latch for a defined power-on state
            bis.b   #BIT0,&P1DIR            ; Set P1.0 to output direction
SetupP2     bic.b   #BIT1,&P1OUT            ; Clear P1.1 output latch for a defined power-on state
            bis.b   #BIT1,&P1DIR            ; Set P1.1 to output direction
UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings

MPY32_MPY 	.equ 	0x04C0
MPY32_OP2	.equ 	0x04C8
MPY32_RESLO	.equ 	0x04CA
MPY32_MPY32L.equ    0x04D0
MPY32_MPY32H.equ    0x04D2
MPY32_OP2L	.equ	0x04E0
MPY32_OP2H	.equ	0x04E2
MPY32_RES0	.equ	0x04E4
MPY32_RES1	.equ	0x04E6

_init
;			call 	#getRxBufferAddress		; return value stored in R12
;			mov.w 	#0x0002,0(R12)
;			mov.w	R12,buffer
			mov.w	#0x000A,buffer


mainloop
;-------------------------------------------------------------------------------
; LED blinking for indication
; 1. BIT0 - toggle red LED.
; 2. BIT1 - toggle green LED.
; 3. wait - delay 1 second.
;-------------------------------------------------------------------------------
;led			xor.b   #BIT0,&P1OUT            ; Toggle P1.0, Red LED
;	       	call 	#wait
;			xor.b   #BIT0,&P1OUT            ; Toggle P1.1, Green LED
;			call 	#wait

;-------------------------------------------------------------------------------
; Benchmarks
; 1. 8 bit math: multiplication, division, subtraction and addition
; 2. 16 bit math: multiplication, division, subtraction and addition
; 3. 32 bit math: multiplication, division, subtraction and addition
;-------------------------------------------------------------------------------
math8bit	mov.b	#0x0002,R13				; Multiplication
			mov.b	#0x0004,R12
			mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
			mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
			mov.w   &MPY32_RESLO,R12		; Move result into return register
			mov.b	#0x0003,R13				; Addition
			mov.b	#0x000c,R12
			add.b   R13,R12

;math16bit	mov.w	#0x00e7,R13
;			mov.w	#0x000c,R12
;			add.w   R13,R12
;			mov.w	#0x0002,R13
;			mov.w	#0x0004,R12
;			mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
;			mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
;			mov.w   &MPY32_RESLO,R12		; Move result into return register
;			mov.w   #0x0012,R13
;			mov.w   #0x003,R14
;			call 	#div

math32bit	mov.w   #0x0075,R14
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

;    		cmp 	#1,up_signal     		; Compare with #1 value
;    		jnz 	mainloop      	 		; Repeat loop if not equal
;			call 	#decode
			mov.w	#0x0003,R12
			call 	#checkUpdate
			jmp 	mainloop

wait:       mov.w   #50000,R5              	; Delay to R15
wait_l1     dec.w   R5                     	; Decrement R15
            jnz     wait_l1                 ; Delay over?

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
div         clr     R15        				;1C
            clr     R12        				;only 16/16 really
            mov     #17,R11        			;2C    -4C ENTRY
div_l1     	cmp     R14,R12        			;1C
            jlo     div_l2        			;2C
            sub     R14,R12        			;1C    -4C WORST CASE
div_l2    	rlc     R15        				;1C
            jc      div_l4        			;2C
            dec     R11        				;1C
            jz      div_l4        			;2C    -6C ON LAST BIT
            rla     R13        				;1C
            rlc     R12        				;1C
            jnc     div_l1        			;2C
			sub     R14,R12        			;1C
            setc            				;2C
            jmp     div_l2        			;2C    -15C WORST
div_l4	    ret            					;3C

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
            
