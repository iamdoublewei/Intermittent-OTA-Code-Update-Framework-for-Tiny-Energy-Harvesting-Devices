; Note: for some reason, the first letter of file name has to be capitalized
;       to be able to see by c code.
		.cdecls C, list, "msp430.h"	; this allows us to use C headers
;============================================================================
; blink
;============================================================================
		.text
		.global blink
blink:
        xor.b   #BIT0,&P1OUT            ; Toggle P1.0, Red LED
