# CMOD-A7-2D
## Introduction 
SUTDicey is a hardware module (Figure 1) that provides an interactive solution for simulating dice rolls, offering users the ability to select and roll various types of dice, from 2-sided to 100-sided. Integrated with a tilt sensor and pseudorandom number generator (PRNG), it enables the real-time display of dice roll results on a 7-segment display, delivering an engaging experience for gaming and other applications. The video demonstration is submitted separately.  
![Figure 1: Exploded view of SUTDicey](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/556bb49d-5d40-465d-ae5b-0aa725c9341f)  
*Figure 1: Exploded view of SUTDicey*  
| Materials | Quantity | 
|----|----|
| CMOD A7 35T | 1 |
| Tilt Switch sw-520d | 1 |
| 3D Printed parts | Reference to above image |
| USB-CPD trigger (5V) | 1 |
| DC-DC battery charge/discharge module (5V)| 1 |
|3.3V DC-DC step down synchronous buck regulator D24V10F3 | 1 |
| 7 segment display 5643BH | 1 |
| 3Mx4 heat-set threaded inserts | 4 |
| Perforated board 70mmx50mm | 2 |
| Accelerometer adxl335 | 1 | 
| Steel Weight for rattler | 1 |
| 9.1k ohm resistors | 3 | 
| 10K ohm resistors | 3 |
| 6mm tactile pushbutton | 3 |
| 3.7V LiPo battery | 1 | 
| Translucent Acrylic Faceplate | 1 |
| 3Mx8 hex head screws | 4 |   
## Circuit Diagram  
Various electronics components such as CMOD-A7, battery, DC-DC Charge Discharge Integrated Module, Step-down voltage regulators, power push button, up/down push button, tilt switch and resistors (9.1k & 10k) were used and interconnected based on Figure 2. 
![photo1713197398](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/5c04479c-d33f-48f1-b608-e9f3292a66bb)  
*Figure 2: Wiring Circuit for SUTDicey*  
## Operating SUTDicey
1. Power on SUTDicey by pressing the recessed button on the bottom of the unit, a red light should show in the slot nearby.

* If a red light does not show, the unit is probably out of power, please charge it with a USB C cable (5v mode)



2. Place the SUTDicey unit upright, with the smooth acrylic side facing up, it will take a few seconds to “boot” up. When numerals are displayed through the acrylic face, it has completed booting.



3. Press above or below on the acrylic face to change between the d2,d4,d6,d8,d10,d12d,20 and d100-sided die.

* Pressing both up and down buttons at the same time while the dice is upright will initiate shutdown which will occur after around 15-30 seconds



4. To roll the selected dice, tilt upside down or shake the SUTDicey unit for more than one second, a colon in the middle of the display will light to show that the unit is not stable and is “tossing/scrambling” the dice. The display numbers will also scramble and randomise.



5. Place or hold the unit upright for more than a second to “roll” the die.  The colon in the middle of the display will disappear once the die is “stable” and has “settled” on a final value. Be careful to not shake or upset the SUTDicey unit as it will roll the dice again if it detects enough movement.



6. Shaking or tilting the SUTDicey unit will roll the last type of dice selected.

## Constraint File 
The constraint file is intended for the CmodA7 rev. B FPGA board. It defines pin assignments and I/O standards for various peripherals and interfaces. 

To implement the file in the project simply: 
1. Uncomment lines corresponding to used pins   
2. Rename the ports (in each line, after get_ports) according to the top-level signal names in the project.

Furthermore, it's worth noting that the file also contains a commented-out line. If uncommented, it permits combinational logic loops with a warning severity level

## Top Module
This section summarises the functionality and behavioural description of each block in the top module Verilog file.   


### Tilt Detection 
Continuously monitors the state of a tilt sensor to determine whether a dice unit is upright and stable.  

*Behavioral Description:* 
1.  Initialization and Reset Handling:
* Upon system initialization or a reset signal (*rstn*), the system resets its internal state.
* *sumtilt* is reset to 0, indicating no prior detection of the tilt sensor being in an "on" state.
* The tiltlog *shift* register is cleared, ensuring a fresh start for storing tilt sensor readings.
* The *upright* flag is set to 0, indicating that the dice unit is not currently detected as upright.



2. Continuous Monitoring and Upright Determination:
* The system continuously monitors the state of the tilt sensor by sampling it at each positive edge of the *CLK10Hz* signal.
* The current state of the tilt sensor is stored in the *tiltlog* shift register, replacing the oldest recorded state.
* The sum of the bits in the *tiltlog* register is calculated, representing the duration the tilt sensor has been in the "on" state over a specific period (approximately 1 second).
* If the sum of the *tiltlog* register exceeds a predetermined threshold (7), indicating that the tilt sensor has been consistently in the "on" state for a certain duration (about 7/10th of a second), the system sets the *upright* flag to 1.
* If the sum of the *tiltlog* register is below the threshold, the *upright* flag remains at 0, indicating that the dice unit is not considered upright and stable.




