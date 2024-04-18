`timescale 1ns / 1ps


module top_module(
        input sysclk,
        input tilt,
        input btnU,
        input btnD,
        input [1:0] btn,
        output onpin,
        output [6:0] seg,// 7-Segment - Segment[6:0];
        output dp,      // 7-Segment - Segment-DP;
        output [3:0] an, // 7-Segment - Common Anode;
        output [1:0] led,
        input vp_in,
        input vn_in,
        input [1:0] xa_n,
        input [1:0] xa_p,
        output uart_rxd_out
);

reg CLK1000Hz,CLK1500Hz,CLK500Hz,CLK10Hz,CLK5s;
wire [15:0] bcd_tim;
wire rstn;
reg keepon;
reg onsig;
reg clk5;

assign rstn=~btn[0];
assign led[1]=tilt;
assign led[0]=clk5;

reg [12:0] CLK_CNTER_1000Hz;
reg [12:0] CLK_CNTER_1500Hz;
reg [13:0] CLK_CNTER_500Hz;
reg [19:0] CLK_CNTER_10Hz;
reg [24:0] CLK_CNTER_5s;

//Generate 1000Hz CLK;
always@(posedge sysclk, negedge rstn)begin
    if(!rstn) begin
        CLK_CNTER_1000Hz<=13'd0;
        CLK1000Hz <= 1'b0;
    end
    else begin
        if(CLK_CNTER_1000Hz == 13'd6000-1'b1) begin
            CLK1000Hz <= ~ CLK1000Hz;
            CLK_CNTER_1000Hz <= 13'd0;
        end
        else CLK_CNTER_1000Hz <= CLK_CNTER_1000Hz + 1'b1;
    end
end

//Generate 1500Hz CLK;
always@(posedge sysclk, negedge rstn)begin
    if(!rstn) begin
        CLK_CNTER_1500Hz<=13'd0;
        CLK1500Hz <= 1'b0;
    end
    else begin
        if(CLK_CNTER_1500Hz == 13'd4000-1'b1) begin
            CLK1500Hz <= ~ CLK1500Hz;
            CLK_CNTER_1500Hz <= 13'd0;
        end
        else CLK_CNTER_1500Hz <= CLK_CNTER_1500Hz + 1'b1;
    end
end

//Generate 5s CLK;
always@(posedge sysclk, negedge rstn)begin
    if(!rstn) begin
        CLK_CNTER_5s<=25'd0;
        CLK5s<= 1'b0;
    end
    else begin
        if(CLK_CNTER_5s == 25'd30001200-1'b1) begin
            CLK5s <= ~ CLK5s;
            CLK_CNTER_5s <= 25'd0;
        end
        else CLK_CNTER_5s <= CLK_CNTER_5s + 1'b1;
    end
end

//Generate 500Hz CLK; 
always@(posedge sysclk, negedge rstn) begin
    if(!rstn) begin
        CLK_CNTER_500Hz<=14'h0000;
        CLK500Hz <= 1'b0;
    end
    else begin
        if(CLK_CNTER_500Hz == 14'd12_000-1'b1) begin
            CLK500Hz <= ~ CLK500Hz;
            CLK_CNTER_500Hz <= 14'h0000;
        end
        else CLK_CNTER_500Hz <= CLK_CNTER_500Hz + 1'b1;
    end
end

//Generate 10Hz CLK;
always@(posedge sysclk, negedge rstn)begin
    if(!rstn) begin
        CLK_CNTER_10Hz<=20'd0;
        CLK10Hz <= 1'b0;
    end
    else begin
        if(CLK_CNTER_10Hz == 20'd600024-1'b1) begin
            CLK10Hz <= ~ CLK10Hz;
            CLK_CNTER_10Hz <= 20'd0;
        end
        else CLK_CNTER_10Hz <= CLK_CNTER_10Hz + 1'b1;
    end
end


//XADC IP block setup
reg [31:0] Segment_data;
wire enable;                     //enable into the xadc to continuosly get data out
reg [6:0] Address_in = 7'h14;    //Adress of register in XADC drp corresponding to data
wire ready;                      //XADC port that declares when data is ready to be taken
wire [15:0] ADC_data;                //XADC data   
        
xadc_wiz_0 xadc_u0
(
    .daddr_in(Address_in),        // Address bus for the dynamic reconfiguration port
    .dclk_in(sysclk),             // Clock input for the dynamic reconfiguration port
    .den_in(enable),              // Enable Signal for the dynamic reconfiguration port
    .di_in(0),                    // Input data bus for the dynamic reconfiguration port
    .dwe_in(0),                   // Write Enable for the dynamic reconfiguration port
    .vauxp12(xa_p[1]),
    .vauxn12(xa_n[1]),
    .vauxp4(xa_p[0]),
    .vauxn4(xa_n[0]),  
    .busy_out(),                 // ADC Busy signal
    .channel_out(),              // Channel Selection Outputs
    .do_out(ADC_data),           // Output data bus for dynamic reconfiguration port
    .drdy_out(ready),            // Data ready signal for the dynamic reconfiguration port
    .eoc_out(enable),            // End of Conversion Signal
    .vp_in(vp_in),               // Dedicated Analog Input Pair
    .vn_in(vn_in)
);

//Read XADC analog input value and store into "Segment_Data" via shift register to create 32 bit seed value
always @(posedge CLK10Hz or negedge rstn) begin
if(!rstn)begin
    Segment_data<=0;
  end
  else begin
    Segment_data<=Segment_data<<16;
    Segment_data[15:0] <= ADC_data;
  end
end

reg [31:0] temp; 
reg [31:0] temp2;
reg [31:0] rand;


//Pseudo-Random XOR shift register algorithm with seed value supplied by XADC, it's not perfect as seed keeps changing every number
always@(sysclk)begin
temp = Segment_data ^ Segment_data >>7;
temp2 = temp ^ temp << 9;
rand = temp2 ^ temp2 >> 13;
end

//"correct" algorithm should feed output "rand" back into itself like this
/*
always@(sysclk)begin
temp = rand ^ rand >>7;
temp2 = temp ^ temp << 9;
rand = temp2 ^ temp2 >> 13;
end
*/
//Unfortunately verilog/FPGA does not like this as this leads to a combinatorial loop condition which causes unintended RACE condition.
//In theroy this is "more random" than a seed that keeps on refreshing, but the issue is that the verilog synthesis optimises the gates in such a way that the race condition propogates 
//all the way though the gates and affects other functions, one cannot simply "sample" from the RACE condition withough extensive customisation of the syntehsis/optimisation parameters
//For example, when this was tested, the modulo and divisor functions to convert the 32 bit RNG value into BCD values to display became corrupted.

//setup for tilt detection and dice selection function
reg [15:0] out;
reg [3:0] ones_set;
reg [3:0] tens_set;
reg [3:0] huns_set;
reg [3:0] thou_set;
reg upright;
reg setmode;
reg [3:0] dselect;
reg [9:0] tiltlog;
reg [4:0] sumtilt;
reg [6:0] diceval;
assign dp = upright;
reg btnUr,btnDr;

//this function polls the tilt sensor every 1/10th of a second and adds it to a 10 bit shift register, it adds the total value of the register to the "sumtilt" variable, if a critical number of bits are 1 (meaning the dice unit has been upright and stable
//for enough time, sumtilt>7 aka, the dice was upright for 7/10th of the second) then it sets the upright register to 1, otherwise it sets it to 0.
always@(posedge CLK10Hz or negedge rstn)begin
  if(!rstn)begin
    sumtilt<=5'b00000;
    tiltlog<=9'b000000000;
    upright<=0;
  end
  else
  begin
    tiltlog <= tiltlog << 1;
    tiltlog[0]<=tilt;
    sumtilt=tiltlog[9]+tiltlog[8]+tiltlog[7]+tiltlog[6]+tiltlog[5]+tiltlog[4]+tiltlog[3]+tiltlog[2]+tiltlog[1]+tiltlog[0];
  if (sumtilt>=7) begin
      upright<=1;
  end
  else begin
      upright<=0;
  end
  end
end


//This function detects when the set dice value buttons are pressed only when the dice is upright, and changes the dice's mode into dice set mode (setmode). pressing the buttons in this mode will allow the value of the dice (diceval) to be
//changed between 2,4,6,8,10,12,20,100 sided dice. The keep awake disable is also here, which requires both up and down buttons to be pressed at the same time.
always@(posedge CLK10Hz or negedge rstn)begin
  if(!rstn)begin
  thou_set<=0;
  huns_set<=0;
  tens_set<=0;
  ones_set<=0;
    btnUr<=0;
    btnDr<=0;
    dselect<=0;
    setmode<=0;
    diceval<=2;
    keepon<=1;
  end
    else begin

  if(btnU)
    btnUr<=1;
  else
    btnUr<=0;
  if(btnD)
    btnDr<=1;
  else
    btnDr<=0;

  if(upright)begin
      if(btnUr)begin
        if(btnDr)begin
            keepon<=0;
        end
        else begin
        setmode<=1;
        if(dselect==7)
          dselect<=0;
        else
          dselect<=dselect+1;
        end
        end
      else if(btnDr)begin
        setmode<=1;
        if(dselect==0)
          dselect<=7;
        else
          dselect<=dselect-1;
        end
        
        thou_set<=4'hd;
        case(dselect)
            4'd0:begin
            huns_set<=2;
            tens_set<=4'hf;
            ones_set<=4'hf;
            diceval<=2;
            end
            4'd1:begin
            huns_set<=4;
            tens_set<=4'hf;
            ones_set<=4'hf;
            diceval<=4;
            end
            4'd2:begin
            huns_set<=6;
            tens_set<=4'hf;
            ones_set<=4'hf;
            diceval<=6;
            end
            4'd3:begin
            huns_set<=8;
            tens_set<=4'hf;
            ones_set<=4'hf;
            diceval<=8;
            end
            4'd4:begin
            huns_set<=1;
            tens_set<=0;
            ones_set<=4'hf;
            diceval<=10;
            end
            4'd5:begin
            huns_set<=1;
            tens_set<=2;
            ones_set<=4'hf;
            diceval<=12;
            end
            4'd6:begin
            huns_set<=2;
            tens_set<=0;
            ones_set<=4'hf;
            diceval<=20;
            end
            4'd7:begin
            huns_set<=1;
            tens_set<=0;
            ones_set<=0;
            diceval<=100;
            end
         endcase        
      
   end
    else
        setmode<=0;

end
end
// setup for the raw RNG value to be processed
reg [3:0] ones_rand;
reg [3:0] tens_rand;
reg [3:0] huns_rand;
reg [3:0] thou_rand;
reg [3:0] ones_randr;
reg [3:0] tens_randr;
reg [3:0] huns_randr;
reg [3:0] thou_randr;

//The raw RNG value is processed every 10th of a second, the value is modulo ed by the dice value to normalise the extended 32 bit range to the required dice range (eg, compressed from 0-4,294,967,295 to 1-6 for a 6 sided dice) the result is then converted to
//a BCD value for display, values are shifted by 10 to centralise the values displayed. The continious updating gives the "scambled" or "rolling" effect that scrolls through the values on the display.
always @(posedge CLK10Hz or negedge rstn) begin
if(!rstn)begin
    ones_rand=4'hd;
    tens_rand=4'hd;
    huns_rand=4'hd;
    thou_rand=4'hd;
  end
  else if(!upright) begin
    out=(rand%diceval)+1;   //32 bit to dice range conversion
    ones_randr=4'hf;        //ones segment disabled
    tens_randr = out % 10;  // Units digit displayed in tens segment
    out = out / 10;         // divisor fed to next modulo
    huns_randr = out % 10;  // Tens digit displayed in hundreds segment
    out = out / 10;         // divisor fed to next modulo
    thou_randr = out % 10;  // Hundreds digitdisplayed in thousands segment
    
    thou_rand=thou_randr;
    huns_rand=huns_randr;
    tens_rand=tens_randr;
    ones_rand=ones_randr;
    end
    else begin
    thou_rand=thou_rand; //if dice is upright, the values are held so they can be read
    huns_rand=huns_rand;
    tens_rand=tens_rand;
    ones_rand=ones_rand;
    
    end
  end

  //The keep awake function is needed as the battery charge/discharge module turns off after 30 seconds if current less than 50ma is drawn (the FPGA module current draw tends to dip below 50ma at times, thus it can sporadically shut off.
  //the button on the charge/discharge module is a on/off button, if the button is pressed in quick succession, it turns off, but if it's pressed after a long interval, it will refresh the 30 second shutdown timer.
  //the button is triggered by a falling edge pulled to ground.
  //this function prevents shutdown from happening by pulling the pin low every 10 seconds (5 sec clock) unless the keep awake is switched off by pressing both up and down buttons simultaneously
always @ (posedge CLK5s)begin
if(!rstn) begin
    onsig<=1;
    clk5<=0;
    end
else if(keepon) begin
    onsig<=~onsig;
    clk5<=~clk5;
    end
else begin
    onsig<=0;
    clk5<=0;
    end
end
assign onpin = onsig;

// setup to write values into segment display buffer
reg [3:0] ones_bcd;
reg [3:0] tens_bcd;
reg [3:0] huns_bcd;
reg [3:0] thou_bcd;
// selects values to be displayed from the dice selection mode or RNG mode based on the state it is in using the value (setmode)
always@(sysclk)begin
if(setmode)begin
thou_bcd<=thou_set;
huns_bcd<=huns_set;
tens_bcd<=tens_set;
ones_bcd<=ones_set;
end
else begin
if(thou_rand==0)
thou_bcd<=4'hf;
else
thou_bcd<=thou_rand;
if(huns_rand==0 && thou_rand==0)
huns_bcd<=4'hf;
else
huns_bcd<=huns_rand;
if(tens_rand==0 && huns_rand==00 && thou_rand ==0)
tens_bcd<=4'hf;
else
tens_bcd<=tens_rand;
if(ones_rand==0)
ones_bcd<=4'hf;
else
ones_bcd<=ones_rand;
end
end

//writes to registers to transfer to segment display function
assign  bcd_tim[15:12]  = thou_bcd;
assign  bcd_tim[11:8]   = huns_bcd;
assign  bcd_tim[7:4]    = tens_bcd;
assign  bcd_tim[3:0]    = ones_bcd;

//segment display function
Segment segment_u0(rstn,CLK500Hz,bcd_tim,{an[0],an[1],an[2],an[3]},seg[6:0]);



//uart setup
reg uart_ready;
wire uart_vaild;

//uart control function, this determines the rate at which messages are sent, not to be confused by bitrate.
//has some issues sending messages at a rate lower than 100Hz even though the actual data rate capable by this system is 100Hz
always@(posedge CLK1000Hz,negedge rstn)begin
    if (!rstn)begin
        uart_ready <= 1'b0;
    end 
    else begin
uart_ready <= ~uart_ready;
    end
end

//outputs the value of the 100s and 10s segments (aka the tens and ones value of teh diceroll) through UART for logging in the computer
//the signal is pased through the uart_rxd_out pin which is tied to the FT2232HQ USB-UART bridge to enable communcation with the computer rather than needing to have a seperate device to act as the middleman.
uart_tx uart_tx_u0(CLK1000Hz,rstn,uart_ready,uart_valid,uart_rxd_out,1'b0,{huns_rand,tens_rand});

endmodule