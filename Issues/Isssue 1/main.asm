;-------------------------------------------------------------------------------
; MSP430 OTA code upate
; Author: Wei Wei
; Vesion: 1.0
; Last Edited: 8/12/2022
;
; Jump instruction offset calculation
; offset start from 0, every time +2
; start address of the program: 0x4000
; to calculate the offset, use current address - start address
; for example: jmp 0 (jump to the beginning of the program)
; the memory value of jmp 0 = 3FAD = 16301
; the memory value of jmp 2 = 3FAE = 16302
; offset = (current addres - start address) / 2
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
	     	.bss 	buffer,60	         	; Allocate 40 bytes (20 words) in FRAM for
											; decoded update instructions
			.bss	index,2					; index for round-robin buffer
 			.data
up_signal	.byte   0x0001
free_addr	.word	0x4300; 				; dac: 17032, point to the start of free space
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

init		mov.w	#0x000A,index
			mov.w	#0xFFFF,buffer
			mov.w	#0xFFFF,buffer+2
			mov.w	#0xFFFF,buffer+4
			mov.w	#0xFFFF,buffer+6
			mov.w	#0xFFFF,buffer+8
			mov.w	#0x0000,buffer+10		; op code
			mov.w	#0x40DA,buffer+12		; destination
			mov.w	#0x0011,buffer+14		; length (in words)
			mov.w	#0x0001,buffer+16		; backup instruction size
			mov.w	#0xE3E2,buffer+18		; data
			mov.w	#0x0202,buffer+20
			mov.w	#0x403D,buffer+22
			mov.w	#0x00E7,buffer+24
			mov.w	#0x403C,buffer+26
			mov.w	#0x000C,buffer+28
			mov.w	#0x5D0C,buffer+30
			mov.w	#0x432D,buffer+32
			mov.w	#0x422C,buffer+34
			mov.w	#0x12B0,buffer+36
			mov.w	#0x40F6,buffer+38
			mov.w	#0x403D,buffer+40
			mov.w	#0x0012,buffer+42
			mov.w	#0x403E,buffer+44
			mov.w	#0x0003,buffer+46
			mov.w	#0x12B0,buffer+48
			mov.w	#0x410E,buffer+50
			mov.w	#0xFFFF,buffer+52
			mov.w	#0xFFFF,buffer+54
			mov.w	#0xFFFF,buffer+56
			mov.w	#0xFFFF,buffer+58

mainloop

led			xor.b   #BIT0,&P1OUT            ; Toggle P1.1 BIT0 Red, BIT1 Green
			call 	#wait
;			xor.b   #BIT0,&P1OUT            ; Toggle P1.0
;			call 	#wait

math8bit	mov.b	#0x0002,R13
			mov.b	#0x0004,R12
			call 	#__mspabi_mpyi_f5hw	; Multiplication
			mov.b	#0x0003,R13
			mov.b	#0x000c,R12
			add.b   R13,R12				; Addition
;			nop

math32bit	mov.w   #0x0075,R14
			mov.w   #0x00a8,R15
			mov.w   #0x00e7,R12
			mov.w   #0x0038,R13
			add.w   R14,R12
			addc.w  R15,R13 ; Addition
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

    		cmp 	#1,up_signal     ; Compare with #1 value
    		jnz 	mainloop      	 ; Repeat loop if not equal
			call 	#decode
			jmp 	mainloop

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

;------
; FUNCTION DEF: div
; DESCRIPTION:  unsigned 32/16 division, R12|R13 / R14 = R15, Remainder
; in R12
; REGISTER USE: R12 is dividend high word
;               R13 is dividend low word
;               R14 is divisor
;               R15 is result
;               R11 is counter
; CALLS:        -
; ORIGINATOR:   Metering Application Report
;------
div         clr     R15        ;1C
            clr     R12        ;only 16/16 really
            mov     #17,R11        ;2C    -4C ENTRY
div_l1     	cmp     R14,R12        ;1C
            jlo     div_l2        ;2C
            sub     R14,R12        ;1C    -4C WORST CASE
div_l2    	rlc     R15        ;1C
            jc      div_l4        ;2C
            dec     R11        ;1C
            jz      div_l4        ;2C    -6C ON LAST BIT
            rla     R13        ;1C
            rlc     R12        ;1C
            jnc     div_l1        ;2C
			sub     R14,R12        ;1C
            setc            ;2C
            jmp     div_l2        ;2C    -15C WORST
div_l4	    ret            ;3C

;------------------------------------------
; Function: 	decode
; Description:  decode update instructions
; Register Use: R10: data start address
;				R9:	 free address
;				R8:  destination address
;               R7:  length
;               R6:  backup size
;------------------------------------------
decode:		mov.w	#buffer,R10
			add.w	index,R10
			mov.w	0(R10), R9		 		; read op code
   			cmp 	#0,R9     		 		; Compare with value
    		jnz 	decode_mod      	 	; jump if not equal
decode_ins	mov.w	2(R10),R8				; destination address
    		mov.w	4(R10),R7				; length
    		mov.w	6(R10),R6				; backup size
	    	add.w	#8,R10					; start data address
	    	mov.w	free_addr,R9
			cmp		#2,R6
			jnz		decode_l1
			mov.w	R8,R15					; temp R15
			sub.w	#2,R15
			mov.w	@R15,0(R9)			; write to free space
			mov.w	0(R8),2(R9)
			add.w	#4,R9
			jmp 	decode_l2
decode_l1	mov.w	0(R8),0(R9)			; Need Testinggggggggggggggggggggggg
			add.w	#2,R9
decode_l2   mov.w	R9,free_addr			; update free_addr
			sub.w	#0x4000,R9				; sub base address, get jump offset
			mov.w	R9,R13
			mov.w	#2,R14
			call 	#div					; R13/R14, result stored in R15
			add.w	#0x3FAD,R15				; add value of "jmp 0"
			cmp		#2,R6
			jnz		decode_l3
			mov.w	R15,-2(R8)
			jmp		update
decode_l3	mov.w	R15,0(R8)
decode_mod  cmp 	#1,R9
    		jnz 	decode_del
    		nop
    		jmp		update
decode_del  cmp 	#2,R9
    		jnz 	decode_cop
    		nop
    		jmp 	update
decode_cop  cmp 	#3,R9
    		jnz 	mainloop
    		nop

; current update, if need to replace last 2 instructions, one empty space will be left.
update:		mov.w	free_addr,R9
update_l1	dec.w   R7                   	; Decrement R7
			mov.w	0(R10),0(R9)
			add.w	#2,R10
			add.w	#2,R9
			cmp		#0,R7
	        jnz     update_l1               ; Delay over?
	        sub.w	#0x4000,R8
	        mov.w	R0,R13
	        mov.w	#2,R14
	        call	#div
	        add.w	#0x3FAD,R15
	        mov.w	R15,0(R9)
	        add.w	#2,R9
cleanup		mov.w	R9,free_addr
			mov.b	#0,up_signal
;			mov.w	R9,R6			; calculate new free address
;			mov.w	R6,free_addr	; update free address
			ret

math16bit	xor.b   #BIT1,&P1OUT            ; Toggle P1.1 BIT0 Red, BIT1 Green
;			mov.w	#0x00e7,R13
;			mov.w	#0x000c,R12
;			add.w   R13,R12
;			mov.w	#0x0002,R13
;			mov.w	#0x0004,R12
;			call   	#__mspabi_mpyi_f5hw
;			mov.w   #0x0012,R13
;			mov.w   #0x003,R14
;			call 	#div

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
            
