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

;blinking
 			.data
up_signal	.word   0x0001
;diff		.word	0x1F5D,0xE3D2
			.text
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

Mainloop

LED			xor.b   #BIT0,&P1OUT            ; Toggle P1.1 BIT0 Red, BIT1 Green
			call 	#wait
;			xor.b   #BIT0,&P1OUT            ; Toggle P1.0
;			call 	#wait

math8bit	mov.b	#0x0003,R13
			mov.b	#0x000c,R12
			add.b   R13,R12				; Addition
			mov.b	#0x0002,R13
			mov.b	#0x0004,R12
			call 	#__mspabi_mpyi_f5hw	; Multiplication

math16bit	mov.w	#0x00e7,R13
			mov.w	#0x000c,R12
			add.w   R13,R12
			mov.w	#0x0002,R13
			mov.w	#0x0004,R12
			call   #__mspabi_mpyi_f5hw

math32bit	mov.w   #0x00075,R14
			mov.w   #0x000a8,R15
			mov.w   #0x000e7,R12
			mov.w   #0x00038,R13
			add.w   R14,R12
			addc.w  R15,R13 ; Addition
			mov.w   #0x00075,R14
			mov.w   #0x000a8,R15
			mov.w   #0x000e7,R12
			mov.w   #0x00038,R13
			mov.w   R12,&MPY32_MPY32L		; Load operand 1 Low into multiplier
			mov.w   R13,&MPY32_MPY32H		; Load operand 1 High into multiplier
			mov.w   R14,&MPY32_OP2L			; Load operand 2 Low into multiplier
			mov.w   R15,&MPY32_OP2H			; Load operand 2 High, trigger MPY
			mov.w   &MPY32_RES0,R12			; Ready low 16-bits for return
			mov.w   &MPY32_RES1,R13			; Ready high 16-bits for return
			mov.w   #0x00075,R14
			mov.w   #0x000a8,R15
			mov.w   #0x000e7,R12
			mov.w   #0x00038,R13

    		cmp 	#1,up_signal     ; Compare with #1 value
    		jnz 	Mainloop      	 ; Repeat loop if not equal
			call 	#update
			jmp 	Mainloop

wait:       mov.w   #50000,R5              	; Delay to R15
L1          dec.w   R5                     	; Decrement R15
            jnz     L1                      ; Delay over?
            ret

__mspabi_mpyi_f5hw:
			push    SR 						; Save current interrupt state
			dint    						; Disable interrupt
			nop    							; Account for latency
			mov.w   R13,&MPY32_MPY			; Load operand 1 into multiplier
			mov.w   R12,&MPY32_OP2			; Load operand 2 which triggers MPY
			mov.w   &MPY32_RESLO,R12		; Move result into return register
			pop.w   SR
			nop     						; CPU19 Compatibility
			ret

update:		mov.w	#58338, &16414;
			ret

;insert:	call 	#__mspabi_mpyi_f5hw	; Multiplication
;			mov.w	#0x00e7,R13
;			mov.w	#0x000c,R12
;			add.w   R13,R12
;			ret

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
            
