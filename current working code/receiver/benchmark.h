///*
// * benchmark.h
// *
// *  Created on: Jan 17, 2023
// *      Author: iamdo
// *
// *  Basic benchmark: https://people.eecs.berkeley.edu/~boser/courses/40/labs/docs/microcontroller%20benchmarks.pdf
// *  Benchmarks: Blink - Peripheral
// *              ADC12 - Sensor
// *              UART - Communication
// *              Math - Basic Computation
// *              Matrix - Matrix Computation
// *  Cases:      1. Blink modification: change blink frequency.
// *              2. Math insert: add 32 bits math operation.
// *              3. Math delete: remove 8 bits math operation.
// *              4. Matrix modification: change math matrix initialization from local to global
// *              5. ADC12 modification: change timer interrupt frequency.
// *              6. UART insert: add new else statement.
// *
// */
//
#ifndef BENCHMARK_H_
#define BENCHMARK_H_
//
//extern void math(void);
extern void matrix_mul(void);
//
#endif /* BENCHMARK_H_ */
