#include "cheader.h"

extern void led(void);     /* Function Prototype for asm function */

void blink(void)
{
    led();
}
