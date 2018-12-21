`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.12.2018 17:33:56
// Design Name: 
// Module Name: quadrature_decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module quadrature_decoder #(

  parameter POSITION_SIZE = 32   //size of the position counter (bits)

)(
  
  input  logic                      i_clk,              //system clock
  input  logic                      i_aresetn,          //system reset
                                                        
  input  logic                      i_a,                //quadrature encoded signal a
  input  logic                      i_b,                //quadrature encoded signal b
  input  logic                      i_z,                //quadrature encoded signal z (zero mark)
                                                        
  input  logic                      enable,             //enable module
  input  logic [31:0]               dbnc_time,          //number of clock cycles for debouncing circuit, in algorithm DBNC_TIME + 2 clk is used
  input  logic [POSITION_SIZE-1:0]  zero_position,      //set position to this value when Z-mark appears
  input  logic [POSITION_SIZE-1:0]  delta_size,         //delta-value (encoder steps) that should be overcome to generate trigger pulse
  input  logic [POSITION_SIZE/2:0]  steps_in_circle,    //nof encoder steps in 1 turnover, when line encoder - use 0x10000 and it's max value for rotation enc
                                    
  output logic                      enable_status,      //we could use this signal to choose how to work with next module
  output logic                      zero_mark_detected, //zero mark is found, goes 1'b1 when it's the first time and stay constant 
  output logic                      direction,          //direction of last change, 1 = positive, 0 = negative
  output logic                      step_toggle,        //signal is absolute_position[0], so checking changing of this bit allows us to detect the smallest step
  output logic                      trigger_out,        //trigger activates when ( delta_size ) steps are done: | trigger <-- [-delta_size + 1]...0...[delta_size -1] --> trigger |
  output logic [POSITION_SIZE-1:0]  absolute_position   //absolute encoder position

);
//////////////////////////////////////////////////////////////////////////////////

//SIGNALS
logic        [1:0]                 a_new;                   //synchronizer/debounce registers for encoded signal a
logic        [1:0]                 b_new;                   //synchronizer/debounce registers for encoded signal b
logic        [1:0]                 z_new;                   //synchronizer/debounce registers for encoded signal z
                                                            
logic                              a_prev;                  //last previous stable value of encoded signal a
logic                              b_prev;                  //last previous stable value of encoded signal b
logic                              z_prev;                  //last previous stable value of encoded signal z

logic        [31:0]                debounce_cnt_a_b;        //timer to remove glitches and validate stable values of inputs a, b
logic        [31:0]                debounce_cnt_z;          //timer to remove glitches and validate stable values of inputs z

logic signed [POSITION_SIZE-1:0]   steps_in_delta_cnt;      //signed counter of encoder steps in 1 delta section (delta_size)
logic        [POSITION_SIZE/2:0]   steps_in_delta_fraction; //fraction part of steps_in_delta_cnt, has size + 1bit to detect overflow
logic signed [POSITION_SIZE/2-1:0] steps_in_delta_integer;  //integer part of steps_in_delta_integer

logic        [POSITION_SIZE/2-1:0] abs_position_fraction;   //fraction part of absolute_position, for rotation encoder it's fraction part of circle
logic signed [POSITION_SIZE/2-1:0] abs_position_integer;    //integer part of absolute_position, for rotation encoder it's amount of circles done

logic        [POSITION_SIZE/2:0]   steps_in_half_circle;    //value to check in what part of circle we are when Z-mark appears

logic                              zero_mark_found;         //signal that Z-mark was found, goes 1'b1 when it's the first time and then stay constant

logic test1;
logic test2;
logic test3;
logic test4;
//////////////////////////////////////////////////////////////////////////////////


//ASSIGNMENT

assign enable_status        = enable;                                                                 //to output
                                                                                                      
assign zero_mark_detected   = zero_mark_found;                                                        //to output
                                                                                                      
assign steps_in_delta_cnt   = {steps_in_delta_integer, steps_in_delta_fraction[POSITION_SIZE/2-1:0]}; //concat integer and fracton (w/o overflow bit)
                                                                                                      
assign absolute_position    = {abs_position_integer, abs_position_fraction};                          //concat integer and fracton
assign step_toggle          = absolute_position[0];                                                   //this bit toggles with the smallest change of encoder
                                                                                                      
assign steps_in_half_circle = steps_in_circle[POSITION_SIZE/2-1:1];                                   //calculating amount of steps in the half of the circle
                                                                                                      

//////////////////////////////////////////////////////////////////////////////////

always_ff @ ( posedge i_clk, negedge i_aresetn )
  begin
    if ( ~i_aresetn ) begin

      abs_position_integer    <= 0;
      abs_position_fraction   <= 0;

      steps_in_delta_integer  <= 0;
      steps_in_delta_fraction <= 0;


      direction               <= 0;

      a_new                   <= 2'b00; 
      b_new                   <= 2'b00; 
      z_new                   <= 2'b00;
      
      a_prev                  <= 1'b0;
      b_prev                  <= 1'b0;
      z_prev                  <= 1'b0;

      zero_mark_found         <= 1'b0;
      
      debounce_cnt_a_b        <= 0;
      debounce_cnt_z          <= 0;

      trigger_out             <= 1'b0;
      

    end else begin

      trigger_out <= 1'b0; //to activate the trigger only for 1 clk period

      if ( enable ) begin

        /////////////////////////////////
        //synchronize A, B, Z
        a_new <= {a_new[0], i_a}; //shift in new values of 'a'
        b_new <= {b_new[0], i_b}; //shift in new values of 'b'
        z_new <= {z_new[0], i_z}; //shift in new values of 'z'
        /////////////////////////////////
        
        /////////////////////////////////
        //debounce inputs A, B
        //a or b or z input is changing
        if ( ( a_new[0] ^ a_new[1] ) || 
             ( b_new[0] ^ b_new[1] ) 
            ) begin           

          debounce_cnt_a_b <= 0; //clear debounce counter
      
        //debounce time is met
        end else if ( debounce_cnt_a_b == dbnc_time ) begin 

          a_prev <= a_new[1]; //update value of a_prev
          b_prev <= b_new[1]; //update value of b_prev

        end else begin
          debounce_cnt_a_b <= debounce_cnt_a_b + 1; //increment debounce counter
        end	
        /////////////////////////////////

        /////////////////////////////////
        //debounce inputs Z
        if  ( z_new[0] ^ z_new[1] )  begin    
          debounce_cnt_z <= 0; //clear debounce counter
        //debounce time is met
        end else if ( debounce_cnt_z == dbnc_time ) begin 
          z_prev <= z_new[1]; //update value of z_prev
        end else begin
      	  debounce_cnt_z <= debounce_cnt_z + 1; //increment debounce counter
        end
        /////////////////////////////////


        /////////////////////////////////
        //determine direction and position

        // A-B ACTION START
        //debounce time for a and b is met AND..
        //one of the new values is different than the previous value
        if  ( ( debounce_cnt_a_b == dbnc_time ) && 
              ( ( a_prev ^ a_new[1] ) || 
                ( b_prev ^ b_new[1] ) 
               ) 
             ) begin
          
            direction <= b_prev ^ a_new[1]; //update the direction

            //clockwise direction
            if ( b_prev ^ a_new[1] ) begin
 
              /////////////////////////////////
              //absolute_position counter wraps around automatically
              abs_position_fraction   <= abs_position_fraction + 1;

              if ( abs_position_fraction == steps_in_circle - 1 ) begin
                abs_position_fraction <= 0; 
                abs_position_integer  <= abs_position_integer + 1;
              end
              /////////////////////////////////


              /////////////////////////////////
              //step in delta counter
              steps_in_delta_fraction <= steps_in_delta_fraction + 1;
              //if it's overflow -> increase integer part
              if ( steps_in_delta_fraction[POSITION_SIZE/2] == 1'b1 ) begin
                steps_in_delta_fraction <= 0;
                steps_in_delta_integer <= steps_in_delta_integer + 1;
              end
              
              //done enough steps clockwise -> push the trigger
              if  ( steps_in_delta_cnt == $signed ( delta_size - 1 ) ) begin
                steps_in_delta_fraction <= 0;
                steps_in_delta_integer  <= 0;

                trigger_out             <= 1'b1;
              end	
              /////////////////////////////////
            
            //counter-clockwise direction 
            end else begin
            
              /////////////////////////////////
              //absolute_position counter wraps around automatically
          	  abs_position_fraction   <= abs_position_fraction - 1;
            
              if ( abs_position_fraction == 0 ) begin
              	abs_position_fraction <= steps_in_circle - 1;      //in counter-clockwise dir we should go through 0 and get the biggest possible value before it..
                abs_position_integer  <= abs_position_integer - 1; //dont remember to decrease int part
              end
              /////////////////////////////////
              

              /////////////////////////////////
              //step in delta counter
              steps_in_delta_fraction <= steps_in_delta_fraction - 1;
              //in counter-clockwise dir we should go through 0 and decrease int part
              if ( steps_in_delta_fraction == 0) begin	
                steps_in_delta_integer <= steps_in_delta_integer - 1;
              end

              //done enough steps counter-clockwise -> push the trigger
              if  ( steps_in_delta_cnt == $signed ( -delta_size + 1 ) ) begin
                steps_in_delta_fraction <= 0;
                steps_in_delta_integer  <= 0;

                trigger_out             <= 1'b1;
              end
              /////////////////////////////////

            end	
            
 
        end // A-B ACTION END
       


        //Z-mark ACTION START
        //debounce time for z is met AND..
        //the new value is different than the previous value
        if  ( ( debounce_cnt_z == dbnc_time ) && 
              ( z_prev ^ z_new[1] )            
             ) begin
          
          //when zero mark is found for the first time reset the positions
          if ( ( z_new[1] ) && ( ~zero_mark_found ) ) begin
            //set zero position
            abs_position_integer    <= zero_position[POSITION_SIZE-1:POSITION_SIZE/2];
            abs_position_fraction   <= zero_position[POSITION_SIZE/2-1:0];

            steps_in_delta_integer  <= 0;
            steps_in_delta_fraction <= 0;

            zero_mark_found         <= 1'b1;	
          end

          //clockwise direction
          if ( direction ) begin //it's better to use reg value here, cause ( b_prev ^ a_new[1] ) could be different in the moments of Z-action

            //check new value, not prev. Reaction on rising edge
          	if ( z_new[1] ) begin 
          	  abs_position_fraction <= 0;

          	  //check if we've are already got through 0 or not
          	  //this is need when we have SMALL mismatching in sync between Z-mark and done steps (e.g. somehow we've missed several steps or counted lil bit more)
          	  //if our fraction part is smaller then the half of the circle -> it means that we've already made increasing of int part, but
          	  //if fraction part is bigger it means we're lil bit late with our counter and next circle has started -> increase int part
              if ( abs_position_fraction >= steps_in_half_circle ) begin
                abs_position_integer <= abs_position_integer + 1;
              end
          	end	

          //counter-clockwise direction
          end else begin
          	//check new value, not prev. Reaction on fallign edge (to make changes at the same time with clockwise case)
          	if ( ~z_new[1] ) begin 
          	  //in counter-clockwise dir we should go through 0 and get the biggest possible value before it
          	  abs_position_fraction <= steps_in_circle - 1; 
          	   
          	  //idea is the same -> see clockwise dir case.
          	  //The only difference: conditional sign changes form >= to <= bcs of direction             
              if ( abs_position_fraction <= steps_in_half_circle ) begin
                abs_position_integer <= abs_position_integer - 1;
              end
          	end	
          end	

        end//Z-mark ACTION START

      end//enable end
    end //aresetn end
  end  //process end
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
