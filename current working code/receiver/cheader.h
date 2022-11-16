/*
 * cheader.h
 *
 *  Created on: Nov 7, 2022
 *      Author: iamdo
 */

#ifndef CHEADER_H_
#define CHEADER_H_

extern uint16_t free_address = 18432; //hex value: 0x4800
extern uint8_t update_avail = 0;
extern uint8_t rx_buffer[61] = {0};
extern "C" {
    volatile uint8_t sizerx;
}

extern "C" void init(void);
extern "C" void check_update(void);
void blink(void);

#endif /* CHEADER_H_ */
