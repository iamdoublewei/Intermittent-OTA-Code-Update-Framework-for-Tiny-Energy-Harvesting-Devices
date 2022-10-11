; Note: for some reason, the first letter of file name has to be capitalized
;       to be able to see by c code.
		.cdecls C, list, "msp430.h"	; this allows us to use C headers
;============================================================================
; blink
;============================================================================
		.text
		.global blink
blink:
        xor.b   #01h,&P1OUT             ; Toggle 0x01 bit Port 1 output
