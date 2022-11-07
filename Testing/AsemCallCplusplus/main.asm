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
_main
SetupP1     bic.b   #BIT0,&P1OUT            ; Clear P1.0 output latch for a defined power-on state
            bis.b   #BIT0,&P1DIR            ; Set P1.0 to output direction
SetupP2     bic.b   #BIT1,&P1OUT            ; Clear P1.1 output latch for a defined power-on state
            bis.b   #BIT1,&P1DIR            ; Set P1.1 to output direction
UnlockGPIO  bic.w   #LOCKLPM5,&PM5CTL0      ; Disable the GPIO power-on default
                                            ; high-impedance mode to activate
                                            ; previously configured port settings
mainloop
			.global ctest
			call 	#ctest
			jmp 	mainloop
                                            
wait:       mov.w   #50000,R5              	; Delay to R15
wait_l1     dec.w   R5                     	; Decrement R15
            jnz     wait_l1                 ; Delay over?
            ret
;-------------------------------------------------------------------------------
; LED blinking for indication
; 1. BIT0 - toggle red LED.
; 2. BIT1 - toggle green LED.
; 3. wait - delay 1 second.
;-------------------------------------------------------------------------------
led:		xor.b   #BIT0,&P1OUT            ; Toggle P1.0, Red LED
	       	call 	#wait
	       	ret
;			xor.b   #BIT0,&P1OUT            ; Toggle P1.1, Green LED
;			call 	#wait
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
            
