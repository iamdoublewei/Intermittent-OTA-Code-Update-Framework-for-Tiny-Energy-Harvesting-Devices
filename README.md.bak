
# Assembly_update
## Overview
This project implements an innovated framework to achieve intermittent over-the-air update. 
## Hardware Requirements
- [MSP430FR5994](https://www.ti.com/product/MSP430FR5994)
- [CC1101](https://www.ti.com/product/CC1101)
- [Raspberry Pi 4 B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)

## Software Requirement
- [Code Composer Studio](https://www.ti.com/tool/CCSTUDIO)
- [CC1101 Communication for MSP430FR5994](https://github.com/abhra0897/msp430_cc1101_energia_v2)
- [CC1101 Communication for Raspberry Pi](https://github.com/SpaceTeddy/CC1101)

## Structure
- ./Diff -  find memory differences between 2 versions of implementation
- ./MSP430FR5994 - assembly code for energy harvesting IoT device

## MSP430FR5994 Setup Instruction
- Create MSP430FR5994 assembly project: CCS -> File -> New -> Project -> CCS Project -> Target MSP430FR5994 -> Empty Assembly-only Project.
- Replace .asm file and .cmd file with the files under ./MSP430FR5994 folder.

## Diff Setup Instruction
- Have MSP430Fr5994 project setup.
- Click debug assembly and write the assembly code into MSP430FR5994.
- Select: View -> Memory Browser.
- On memory browser select: Save Memory -> File Type (TI Data) -> Format (16-Bit Unsigned Int), Start Addrsss (0), Memory words (524288). This will read all memory content from the device. Different output formats are also supported.
- Put the output files of two different implementations into the folder ./Diff. Examples of memory files are provided.
- Run find_diff.py