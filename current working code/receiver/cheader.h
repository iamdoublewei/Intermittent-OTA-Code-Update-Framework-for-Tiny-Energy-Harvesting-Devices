/*
 * cheader.h
 *
 *  Created on: Nov 7, 2022
 *      Author: iamdo
 */

#ifndef CHEADER_H_
#define CHEADER_H_

extern uint8_t rx_buffer[61]={0};
extern "C" {
    volatile uint8_t sizerx;
}

extern "C" void initComm(void);
extern "C" void checkUpdate(void);


#endif /* CHEADER_H_ */
