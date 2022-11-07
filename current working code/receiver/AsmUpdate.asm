;-------------------------------------------------------------------------------
; Assembly upate
; Author: Wei Wei
; Vesion: 1.0
; Last Edited: 8/24/2022
; Email: iamdoublewei@gmail.com
;
;--------------------------------------------------------------------------------
; MSP430 jump instruction encoding calculation
; 001   ,         111    ,      0100010011
; op code, unconditional jump, 10 bits 2's complement representation offset
; formula: PC(new) = PC(old) + 2 + PC(offset) * 2
; in this complementation we use 001,111,0000000000(0x3C00) + calculation offset
;
; MSP430 jump instruction calculation
; jmp 0
; jmp to the absolute address related to start address
; start address of the program: 0x4000 (can be set through .cmd file)
; to calculate the jmp instruction, use current address - start address
;
;Note: for some reason, the first letter of file name has to be capitalized
;       to be able to see by c code.
;-------------------------------------------------------------------------------

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

;-------------------------------------------------------------------------------
		.cdecls C,NOLIST, "msp430.h" ; Processor specific definitions

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Main code here
;-------------------------------------------------------------------------------
		.bss 	buffer,61	         ; Allocate 61 bytes (30 words) in FRAM for
									 ; decoded update instructions
MPY32_MPY 	.equ 	0x04C0
MPY32_OP2	.equ 	0x04C8
MPY32_RESLO	.equ 	0x04CA
MPY32_MPY32L.equ    0x04D0
MPY32_MPY32H.equ    0x04D2
MPY32_OP2L	.equ	0x04E0
MPY32_OP2H	.equ	0x04E2
MPY32_RES0	.equ	0x04E4
MPY32_RES1	.equ	0x04E6

;============================================================================
; gpio_config
; description: call gpio_config before use led_red and led_green
;============================================================================
		.text
      	.global gpio_config          ; Declare symbol to be exported
gpio_config:   .asmfunc
		bic.b   #BIT0,&P1OUT         ; Clear P1.0 output latch for a defined power-on state
		bis.b   #BIT0,&P1DIR         ; Set P1.0 to output direction
		bic.b   #BIT1,&P1OUT         ; Clear P1.1 output latch for a defined power-on state
		bis.b   #BIT1,&P1DIR         ; Set P1.1 to output direction
   .if ($defined(__MSP430_HAS_MSP430XV2_CPU__) | $defined(__MSP430_HAS_MSP430X_CPU__))
        reta
   .else
        ret
   .endif
         .endasmfunc

;============================================================================
; led_red
; description: blink red led once
;============================================================================
	  	.text
      	.global led_red              ; Declare symbol to be exported
led_red:   .asmfunc
        xor.b   #BIT0,&P1OUT         ; Toggle P1.0, Red LED
   .if ($defined(__MSP430_HAS_MSP430XV2_CPU__) | $defined(__MSP430_HAS_MSP430X_CPU__))
        reta
   .else
        ret
   .endif
         .endasmfunc

;============================================================================
; led_green
; description: blink green led once
;============================================================================
	  	.text
        .global  led_green           ; Declare symbol to be exported
led_green:   .asmfunc
        xor.b   #BIT1,&P1OUT         ; Toggle P1.1, Green LED
   .if ($defined(__MSP430_HAS_MSP430XV2_CPU__) | $defined(__MSP430_HAS_MSP430X_CPU__))
        reta
   .else
        ret
   .endif
         .endasmfunc

;============================================================================
; get_rx_buffer
; description: get the address of rx_buffer
;============================================================================

;============================================================================
; Benchmarks
; description: consecutive benckmarks used for implementing update algorithm
;============================================================================
	  	.text
        .global  benchmarks          ; Declare symbol to be exported
benchmarks:   .asmfunc
m_8bit 	mov.b	#0x0002,R13			 ; Multiplication
		mov.b	#0x0004,R12
		mov.w   R13,&MPY32_MPY	  	 ; Load operand 1 into multiplier
		mov.w   R12,&MPY32_OP2		 ; Load operand 2 which triggers MPY
		mov.w   &MPY32_RESLO,R12 	 ; Move result into return register
		mov.b	#0x0003,R13			 ; Addition
		mov.b	#0x000c,R12
		add.b   R13,R12

;m_16bit	mov.w	#0x00e7,R13
;			mov.w	#0x000c,R12
;			add.w   R13,R12
;			mov.w	#0x0002,R13
;			mov.w	#0x0004,R12
;			mov.w   R13,&MPY32_MPY		 ; Load operand 1 into multiplier
;			mov.w   R12,&MPY32_OP2		 ; Load operand 2 which triggers MPY
;			mov.w   &MPY32_RESLO,R12	 ; Move result into return register
;			mov.w   #0x0012,R13
;			mov.w   #0x003,R14
;			call 	#div

m_32bit	mov.w   #0x0075,R14
		mov.w   #0x00a8,R15
		mov.w   #0x00e7,R12
		mov.w   #0x0038,R13
		add.w   R14,R12
		addc.w  R15,R13 			 ; Addition
		mov.w   #0x0075,R14
		mov.w   #0x00a8,R15
		mov.w   #0x00e7,R12
		mov.w   #0x0038,R13
		mov.w   R12,&MPY32_MPY32L	 ; Load operand 1 Low into multiplier
		mov.w   R13,&MPY32_MPY32H	 ; Load operand 1 High into multiplier
		mov.w   R14,&MPY32_OP2L		 ; Load operand 2 Low into multiplier
		mov.w   R15,&MPY32_OP2H		 ; Load operand 2 High, trigger MPY
		mov.w   &MPY32_RES0,R12		 ; Ready low 16-bits for return
		mov.w   &MPY32_RES1,R13		 ; Ready high 16-bits for return
		mov.w   #0x0075,R14
		mov.w   #0x00a8,R15
		mov.w   #0x00e7,R12
		mov.w   #0x0038,R13
   .if ($defined(__MSP430_HAS_MSP430XV2_CPU__) | $defined(__MSP430_HAS_MSP430X_CPU__))
        reta
   .else
        ret
   .endif
        .endasmfunc

        .end
