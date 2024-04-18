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

![Flowchart](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/acf85d60-5b2c-4498-88fb-6dad86ae80f1)
*Figure 3: Simplified State Flow Chart Solid lines represent state changes, broken/dotted lines represent information flow Colours represent separate loops*  

### Tilt Detection 
Continuously monitors the state of a tilt sensor to determine whether a dice unit is upright and stable.  

***Behavioral Description:***
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

### Dice Selection and Display 
This block manages the control flow of the dice controller, allowing users to interact with it to set the dice value (2,4,6,8,10,12,20,100 sided dice) and mode based on button presses.  

***Behavioral Description:***
- On a clock edge or reset, it initializes/reset various signals and variables.
- It updates the states of the "up" and "down" buttons (*btnUr* and *btnDr*).
- It checks if the dice is upright (*upright*) and processes button presses accordingly:
  - If both the "up" and "down" buttons are pressed simultaneously, it disables the keep awake feature (*keepon*).
  - If only the "up" button is pressed, it enters the set mode and cycles through dice values (*dselect*).
  - If only the "down" button is pressed, it enters the set mode and cycles through dice values in reverse.
- It updates the displayed value on the segment display (*thou_set, huns_set, tens_set, ones_set*) based on the selected mode (*dselect*).
- If the dice is not upright, it exits the set mode.



### XADC Analog Input to 32-bit Seed Generator
This module converts XADC analogue input to a 32-bit seed using a shift register. It accumulates ADC data on each positive clock edge, generating (Segment_Data) as the seed PRNG.   

***Behavioral Description:***
- On the positive edge of the clock signal (*CLK10Hz*), or upon a negative reset (*rstn*), the module either resets the seed value to zero or shifts in new ADC data.
- If a reset occurs, the seed value is reset to zero.
- Otherwise, the module shifts the current seed value left by 16 bits and assigns the lower 16 bits to the newly acquired ADC data.
- This results in the generation of a  32-bit value in (*Segment_Data*)  as a seed for PRNG. 


### Random Number Generation for Dice Roll 
A pseudorandom number generator (PRNG) is used to generate random numbers for the dice rolls. The PRNG algorithm takes seed values obtained from a XADC and produces pseudorandom values, which are used for generating the dice roll results.

***Behavioral Description:***
- On each rising edge of the system clock (*sysclk*), the PRNG computes the next pseudo-random number.
- It uses the previous pseudo-random number (stored in *rand_reg*) to compute the next value.
- The computation involves bitwise XOR and shifting operations.
- The result is stored in a register (*rand_reg*) synchronously to avoid combinatorial loop issues.
- The pseudo-random number is outputted as rand for further use in the FPGA design.

***RNG Computation:***
- The XORshift algorithm used was adapted from Hammon’s [FPGA RNG design](https://arxiv.org/pdf/2209.04423.pdf). An XORshift algorithm works by taking the exclusive or (XOR) of a number with a shifted version of itself multiple times, before feeding back into the input again.   
![RNG](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/6ba6943f-334b-47b6-80d4-323102963f9a) 
*Figure 4: XORshift method* 
- The use of a 32-bit seed in the XORshift method makes the randomness seemingly close to a TRPG. A UART connection was used to plot a statistical distribution and evaluate the randomness of the generated XORshift outputs: 
![photo1713197398](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/2bb0d28d-79ee-4557-a14b-102e1490d030)
![photo1713192687](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/774458ef-2504-493a-812d-0ade5a145dbb)
*Figure 5 & 6: Statistical distribution for 20-sided dice*
![photo1713112754](https://github.com/stephlovesfries/CMOD-A7-2D/assets/115708694/1268afa3-cf9c-47cd-8bc0-9e2f2780dac6)
*Figure 7: Statistical distribution before RNG value is converted to the chosen dice range*


### Segmented Display Processing 
Processes the raw RNG values generated by the PRNG algorithm and prepares them for display on a segmented display.

***Behavioral Description:*** 
- The raw RNG values (*rand*) are generated by the pseudo-random number generator (PRNG) algorithm discussed earlier.
- These raw RNG values are fed into the display processing logic to convert them into BCD (Binary Coded Decimal) format for display.
- The RNG values are modulo-ed by a dice value to normalize them into the desired range for the dice game. Essentially involves converting a wide range of RNG values into a smaller range suitable for a dice roll (e.g., converting from a 32-bit range to a 1-6 range for a six-sided dice).
- The processed RNG values are then converted to BCD format for display on the segmented display.



### Segment Display Control
The 7-segment display can be set manually or generated randomly. 

***Behavioral Description:***
- Four variables *ones_bcd, tens_bcd, huns_bcd,* and thou_bcd, each 4 bits wide, representing the BCD (Binary Coded Decimal) values for ones, tens, hundreds, and thousands places.
- If setmode is true, it sets the BCD values directly from *thou_set, huns_set, tens_set,* and *ones_set*. If *setmode* is false, it sets the BCD values based on some random values (*thou_rand, huns_rand, tens_rand, ones_rand*), with some conditions.
- BCD values are assigned to *bcd_tim* in the appropriate order for display.



### Battery Module 
It toggles a pin every 5 seconds to prevent the module from shutting down due to low current draw from FPGA. The keep-awake function can be disabled by pressing both up and down buttons simultaneously.  

### UART Interface (Communication) 
Controls the rate of message transmission and outputs data representing the tens and ones value of a dice roll through UART  
***Behavioral Description:*** 
- *uart_ready* toggles on each positive clock edge, controlling the message transmission rate.
- Data is sent over UART when *uart_ready* is high and *uart_valid* is asserted.
- The UART interface operates asynchronously, transmitting data via *uart_rxd_out*.
- The display cycles through the digits at a rate of 500 Hz (*clk500hz*).



## Segment Module 
Controls a 4-digit 7-segment display, sequentially showing each digit of a BCD number.

***Behavioral Description:***
- The module sequentially displays each digit of the BCD number on the 7-segment display.
- An internal register (an_r) determines which digit is currently being displayed, cycling through each digit in sequence.
- The BCD number to be displayed is selected based on the value of an_r.
- The BCD number is converted into the corresponding 7-segment code and stored in an internal register (segment_r).
- On reset (rstn), all displays are turned off and overwritten with “dddd”



## UART TX Module 
The UART transmitter module is designed to transmit serial data asynchronously to a receiver. It operates based on a finite state machine (FSM) to control the transmission process. The module handles data transfer, start and stop bit insertion, and optionally, parity bit generation for error detection.

***Behavioral Description:***
- The module uses an FSM to manage the transmission process. The FSM transitions between states including IDLE, START, TRANSFER, and STOP based on various conditions such as readiness of the receiver (*ap_ready*).
- When data is ready (*ap_ready*), the module starts the transmission process by sending a start bit (*FSM_STAR*). It then proceeds to transmit each bit of the data (*data*) followed by an optional parity bit (*parity*) and a stop bit (*FSM_STOP*).
- The module generates output signals (*ap_valid* and *tx*) to indicate the validity of the transmitted data and the actual serial data stream, respectively.
- Synchronous reset (*ap_rstn*) is used to initialize the module to the IDLE state.
- Optionally, the module can perform parity checking (*FSM_PARI*) to ensure data integrity, although the implementation for this is currently commented out.



## Challenges & Limitations 
The PRNG algorithm should have taken in seed value once and computed the next numbers based on the results to generate more random values. However, due to the nature of Verilog synthesis and optimization, this approach leads to combinatorial loops and race conditions, affecting other functionalities.


As a result, the implemented approach relies on refreshing the seed value (*Segment_data*) continuously from the XADC, which may not produce as "random" results as the ideal feedback loop approach.
