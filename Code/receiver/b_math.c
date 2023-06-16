/*******************************************************************************
*
* Name : 8-bit Math
* Purpose : Benchmark 8-bit math functions.
*
*******************************************************************************/
#include "benchmark.h"

// original math benchmark
typedef unsigned char UInt8;
UInt8 add(UInt8 a, UInt8 b)
{
    return (a + b);
}
UInt8 mul(UInt8 a, UInt8 b)
{
    return (a * b);
}
UInt8 div(UInt8 a, UInt8 b)
{
    return (a / b);
}
extern void math(void)
{
    volatile UInt8 result[4];
    result[0] = 12;
    result[1] = 3;
    result[2] = add(result[0], result[1]);
    result[1] = mul(result[0], result[2]);
    result[3] = div(result[1], result[2]);
    return;
}

// case 5: Insert 16-bit math
//typedef unsigned char UInt8;
//typedef unsigned short UInt16;      // -------------diff---------------
//UInt8 add(UInt8 a, UInt8 b)
//{
//    return (a + b);
//}
//UInt8 mul(UInt8 a, UInt8 b)
//{
//    return (a * b);
//}
//UInt8 div(UInt8 a, UInt8 b)
//{
//    return (a / b);
//}
//UInt16 add16(UInt16 a, UInt16 b)    // -------------diff--------------- start
//{
//    return (a + b);
//}
//UInt16 mul16(UInt16 a, UInt16 b)
//{
//    return (a * b);
//}
//UInt16 div16(UInt16 a, UInt16 b)
//{
//    return (a / b);
//}                                   // -------------diff--------------- end
//extern void math(void)
//{
//    volatile UInt8 result[4];
//    result[0] = 12;
//    result[1] = 3;
//    result[2] = add(result[0], result[1]);
//    result[1] = mul(result[0], result[2]);
//    result[3] = div(result[1], result[2]);
//
//    volatile UInt16 result16[4];                    // -------------diff--------------- start
//    result16[0] = 231;
//    result16[1] = 12;
//    result16[2] = add16(result16[0], result16[1]);
//    result16[1] = mul16(result16[0], result16[2]);
//    result16[3] = div16(result16[1], result16[2]);  // -------------diff--------------- end
//
//    return;
//}

// case 6: Replace 8-bit math with 16-bit math
//typedef unsigned short UInt16;                     // -------------diff--------------- start
//UInt16 add(UInt16 a, UInt16 b)
//{
//    return (a + b);
//}
//UInt16 mul(UInt16 a, UInt16 b)
//{
//    return (a * b);
//}
//UInt16 div(UInt16 a, UInt16 b)
//{
//    return (a / b);
//}
//void main(void)
//{
//    volatile UInt16 result[4];
//    result[0] = 231;
//    result[1] = 12;
//    result[2] = add(result[0], result[1]);
//    result[1] = mul(result[0], result[2]);
//    result[3] = div(result[1], result[2]);
//    return;
//}                                                  // -------------diff--------------- end

// case 7: Remove multiplication operation
//typedef unsigned char UInt8;
//UInt8 add(UInt8 a, UInt8 b)
//{
//    return (a + b);
//}
//UInt8 div(UInt8 a, UInt8 b)
//{
//    return (a / b);
//}
//extern void math(void)
//{
//    volatile UInt8 result[4];
//    result[0] = 12;
//    result[1] = 3;
//    result[2] = add(result[0], result[1]);
//    result[3] = div(result[1], result[2]);
//    return;
//}
