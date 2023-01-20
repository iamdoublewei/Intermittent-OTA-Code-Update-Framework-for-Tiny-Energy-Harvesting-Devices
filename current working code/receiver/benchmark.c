/*
 * benchmark.c
 *
 *  Created on: Jan 17, 2023
 *      Author: iamdo
 *
 *  Basic benchmark: https://people.eecs.berkeley.edu/~boser/courses/40/labs/docs/microcontroller%20benchmarks.pdf
 */

#ifndef BENCHMARK_C_
#define BENCHMARK_C_

#include <math.h>

typedef unsigned char UInt8;
typedef unsigned short UInt16;
typedef unsigned long UInt32;

/*******************************************************************************
*
* Name : 8-bit Math
* Purpose : Benchmark 8-bit math functions.
*
*******************************************************************************/
void math_8bit(void)
{
    volatile UInt8 result[4];
    result[0] = 12;
    result[1] = 3;
    result[2] = result[0] + result[1];
    result[1] = result[0] * result[2];
    result[3] = result[1] / result[2];
    return;
}

/*******************************************************************************
*
* Name : 16-bit Math
* Purpose : Benchmark 16-bit math functions.
*
*******************************************************************************/
void math_16bit(void)
{
    volatile UInt16 result[4];
    result[0] = 231;
    result[1] = 12;
    result[2] = result[0] + result[1];
    result[1] = result[0] * result[2];
    result[3] = result[1] / result[2];
    return;
}

/*******************************************************************************
*
* Name : 32-bit Math
* Purpose : Benchmark 32-bit math functions.
*
*******************************************************************************/
void math_32bit(void)
{
    volatile UInt32 result[4];
    result[0] = 43125;
    result[1] = 14567;
    result[2] = result[0] + result[1];
    result[1] = result[0] * result[2];
    result[3] = result[1] / result[2];
    return;
}

/*******************************************************************************
*
* Name : Floating-point Math
* Purpose : Benchmark floating-point math functions.
*
*******************************************************************************/
void math_float(void)
{
    volatile float result[4];
    result[0] = 54.567;
    result[1] = 14346.67;
    result[2] = result[0] + result[1];
    result[1] = result[0] * result[2];
    result[3] = result[1] / result[2];
    return;
}

/*******************************************************************************
*
* Name : Math Benchmark
* Purpose : Benchmark for all math functions
*
*******************************************************************************/
void math(void)
{
    math_8bit();
    math_16bit();
    math_32bit();
    math_float();
    return;
}

/*******************************************************************************
*
* Name : 8-bit 2-dim Matrix
* Purpose : Benchmark copying 8-bit values.
*
*******************************************************************************/
void matrix_8bit_copy(void)
{
    const UInt8 m1[16][4] = {
    {0x12, 0x56, 0x90, 0x34},
    {0x78, 0x12, 0x56, 0x90},
    {0x34, 0x78, 0x12, 0x56},
    {0x90, 0x34, 0x78, 0x12},
    {0x12, 0x56, 0x90, 0x34},
    {0x78, 0x12, 0x56, 0x90},
    {0x34, 0x78, 0x12, 0x56},
    {0x90, 0x34, 0x78, 0x12},
    {0x12, 0x56, 0x90, 0x34},
    {0x78, 0x12, 0x56, 0x90},
    {0x34, 0x78, 0x12, 0x56},
    {0x90, 0x34, 0x78, 0x12},
    {0x12, 0x56, 0x90, 0x34},
    {0x78, 0x12, 0x56, 0x90},
    {0x34, 0x78, 0x12, 0x56},
    {0x90, 0x34, 0x78, 0x12}
    };
    int i, j;
    volatile UInt8 m2[16][4], m3[16][4];
    for(i = 0; i < 16; i++)
    {
        for(j=0; j < 4; j++)
        {
            m2[i][j] = m1[i][j];
            m3[i][j] = m2[i][j];
        }
    }
    return;
}

/*******************************************************************************
*
* Name : 16-bit 2-dim Matrix
* Purpose : Benchmark copying 16-bit values.
*
*******************************************************************************/
void matrix_16bit_copy(void)
{
    const UInt16 m1[16][4] = {
    {0x1234, 0x5678, 0x9012, 0x3456},
    {0x7890, 0x1234, 0x5678, 0x9012},
    {0x3456, 0x7890, 0x1234, 0x5678},
    {0x9012, 0x3456, 0x7890, 0x1234},
    {0x1234, 0x5678, 0x9012, 0x3456},
    {0x7890, 0x1234, 0x5678, 0x9012},
    {0x3456, 0x7890, 0x1234, 0x5678},
    {0x9012, 0x3456, 0x7890, 0x1234},
    {0x1234, 0x5678, 0x9012, 0x3456},
    {0x7890, 0x1234, 0x5678, 0x9012},
    {0x3456, 0x7890, 0x1234, 0x5678},
    {0x9012, 0x3456, 0x7890, 0x1234},
    {0x1234, 0x5678, 0x9012, 0x3456},
    {0x7890, 0x1234, 0x5678, 0x9012},
    {0x3456, 0x7890, 0x1234, 0x5678},
    {0x9012, 0x3456, 0x7890, 0x1234}
    };
    int i, j;
    volatile UInt16 m2[16][4], m3[16][4];
    for(i = 0; i < 16; i++)
    {
        for(j = 0; j < 4; j++)
        {
            m2[i][j] = m1[i][j];
            m3[i][j] = m2[i][j];
        }
    }
    return;
}

/*******************************************************************************
*
* Name : Matrix Multiplication
* Purpose : Benchmark multiplying a 3x4 matrix by a 4x5 matrix.
* Matrix contains 16-bit values.
*
*******************************************************************************/
void matrix_mul(void)
{
    const UInt16 m1[3][4] = {
    {0x01, 0x02, 0x03, 0x04},
    {0x05, 0x06, 0x07, 0x08},
    {0x09, 0x0A, 0x0B, 0x0C}
    };
    const UInt16 m2[4][5] = {
    {0x01, 0x02, 0x03, 0x04, 0x05},
    {0x06, 0x07, 0x08, 0x09, 0x0A},
    {0x0B, 0x0C, 0x0D, 0x0E, 0x0F},
    {0x10, 0x11, 0x12, 0x13, 0x14}
    };
    int m, n, p;
    volatile UInt16 m3[3][5];
    for(m = 0; m < 3; m++)
    {
        for(p = 0; p < 5; p++)
        {
            m3[m][p] = 0;
            for(n = 0; n < 4; n++)
            {
                m3[m][p] += m1[m][n] * m2[n][p];
            }
        }
    }
    return;
}

/*******************************************************************************
*
* Name : 2D Convolution
* Purpose : 2D data are usually stored in computer memory as contiguous 1D array.
*           So, we are using 1D array for 2D data.
*           2D convolution assumes the kernel is center originated, which means, if
*           kernel size 3 then, k[-1], k[0], k[1]. The middle of index is always 0.
*           The following programming logics are somewhat complicated because of using
*           pointer indexing in order to minimize the number of multiplications.
* Source:   http://www.songho.ca/dsp/convolution/convolution.html
*
*******************************************************************************/
UInt8 convolve2D(UInt16* in, UInt16* out, int dataSizeX, int dataSizeY,
                float* kernel, int kernelSizeX, int kernelSizeY)
{
    int i, j, m, n;
    UInt16 *inPtr, *inPtr2, *outPtr;
    float *kPtr;
    int kCenterX, kCenterY;
    int rowMin, rowMax;                             // to check boundary of input array
    int colMin, colMax;                             //
    float sum;                                      // temp accumulation buffer

    // check validity of params
    if(!in || !out || !kernel) return 0;
    if(dataSizeX <= 0 || kernelSizeX <= 0) return 0;

    // find center position of kernel (half of kernel size)
    kCenterX = kernelSizeX >> 1;
    kCenterY = kernelSizeY >> 1;

    // init working  pointers
    inPtr = inPtr2 = &in[dataSizeX * kCenterY + kCenterX];  // note that  it is shifted (kCenterX, kCenterY),
    outPtr = out;
    kPtr = kernel;

    // start convolution
    for(i= 0; i < dataSizeY; ++i)                   // number of rows
    {
        // compute the range of convolution, the current row of kernel should be between these
        rowMax = i + kCenterY;
        rowMin = i - dataSizeY + kCenterY;

        for(j = 0; j < dataSizeX; ++j)              // number of columns
        {
            // compute the range of convolution, the current column of kernel should be between these
            colMax = j + kCenterX;
            colMin = j - dataSizeX + kCenterX;

            sum = 0;                                // set to 0 before accumulate

            // flip the kernel and traverse all the kernel values
            // multiply each kernel value with underlying input data
            for(m = 0; m < kernelSizeY; ++m)        // kernel rows
            {
                // check if the index is out of bound of input array
                if(m <= rowMax && m > rowMin)
                {
                    for(n = 0; n < kernelSizeX; ++n)
                    {
                        // check the boundary of array
                        if(n <= colMax && n > colMin)
                            sum += *(inPtr - n) * *kPtr;

                        ++kPtr;                     // next kernel
                    }
                }
                else
                    kPtr += kernelSizeX;            // out of bound, move to next row of kernel

                inPtr -= dataSizeX;                 // move input data 1 raw up
            }

            // convert negative number to positive
            *outPtr = (UInt16)((float)fabs(sum) + 0.5f);

            kPtr = kernel;                          // reset kernel to (0,0)
            inPtr = ++inPtr2;                       // next input
            ++outPtr;                               // next output
        }
    }

    return 1;
}

/*******************************************************************************
*
* Name : Matrix Convolution
* Purpose : Benchmark convolving 16x16 matrix by kernel 3x3
*
*******************************************************************************/
void matrix_conv(void)
{
    const UInt16 x[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
                        1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
    UInt16 y[256];
    const float k[] = {1,2,3,4,5,6,7,8,9};
    convolve2D(x, y, 16, 16, k, 3, 3);
}

/*******************************************************************************
*
* Name : Matrix Benchmark
* Purpose : Benchmark for all matrix functions
*
*******************************************************************************/
void matrix(void)
{
    matrix_8bit_copy();
    matrix_16bit_copy();
    matrix_mul();
    matrix_conv();
    return;
}

#endif /* BENCHMARK_C_ */
