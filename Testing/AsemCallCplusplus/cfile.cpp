#include <cheader.h>

// Function Prototypes for asm function
extern void gpio_config(void);
extern void led_red(void);
extern void led_green(void);
extern void benchmarks(void);

void blink_config(void)
{
    gpio_config();
}

void blink_red(void)
{
    led_red();
}

void blink_green(void)
{
    led_green();
}

void run(void)
{
    benchmarks();
}

int update()
{
    return 1;
}

extern "C" void ctest()
{
    while(1)
    {
        P1OUT ^= BIT0;                      // Toggle LED
        P1OUT ^= BIT1;                      // Toggle LED
        __delay_cycles(100000);
    }
}
