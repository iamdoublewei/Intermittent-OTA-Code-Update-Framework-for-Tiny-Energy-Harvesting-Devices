/*****************************************
 * Author: Wei Wei
 * Date: 10/7/2022
 * Description: This project is used to test if assembly code can be call by C/C++ code in MSP430FR5994
 * environment.
 */
#include <msp430.h>

/* -------------------external Function Prototypes ------------------- */
extern void blink(void);     /* Function Prototype for asm function */

/**
 * main.c
 */
void main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
	PM5CTL0 &= ~LOCKLPM5;                   // Disable the GPIO power-on default high-impedance mode
	                                          // to activate previously configured port settings
	P1DIR = 0x01;
	while(1)
	{
	    blink();
	    __delay_cycles(100000);
	}
}
