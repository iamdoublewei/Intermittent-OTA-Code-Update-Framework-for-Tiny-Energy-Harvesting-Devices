#include "cheader.h"

extern void blink(void);     /* Function Prototype for asm function */

void test(void)
{
    blink();
//    __delay_cycles(100000);
}
