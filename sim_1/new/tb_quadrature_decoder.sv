`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.12.2018 11:28:43
// Design Name: 
// Module Name: tb_quadrature_decoder
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


module tb_quadrature_decoder();

localparam POSITION_SIZE   = 32;
localparam DBNC_TIME       = 2;
localparam ZERO_POSITION   = 0;
localparam DELTA_SIZE      = 3;
localparam STEPS_IN_CIRCLE = 4;


//signsals
logic clk, clk_r;
logic aresetn;

logic a, r_a;
logic b, r_b;
logic z, r_z;

logic [POSITION_SIZE-1:0] abs_position;
logic                     trigger;

logic [POSITION_SIZE-1:0] from_FIFO;
logic                     rd_en, rd_en_reg;
logic                     w_en, w_en_reg;

logic [0:1]               delay_stages;
logic                     trigger_delayed;

logic en;
logic zero_mark;


quadrature_decoder #(

  .POSITION_SIZE ( POSITION_SIZE ) 


) UUT (
  
  .i_clk            ( clk             ),          
  .i_aresetn        ( aresetn         ),      

  .i_a              ( r_a             ),              
  .i_b              ( r_b             ),               
  .i_z              ( r_z             ),               

  .enable           ( 1'b1            ),
  .dbnc_time        ( DBNC_TIME       ),      
  .zero_position    ( ZERO_POSITION   ),
  .delta_size       ( DELTA_SIZE      ),
  .steps_in_circle  ( STEPS_IN_CIRCLE ),
  

  .enable_status     (  ),
  .direction         (  ),
  .step_toggle       (  ),
  .trigger_out       ( trigger        ),       
  .absolute_position ( abs_position   ) 

);
//////////////////////////////////////////////////////////////////////////////////


//TO USE IT - create and add module to your project with xilinx fifo gen
/*
fifo_generator_0 JOPA_FIFO(

  .rst    ( ~aresetn     ),  
  .wr_clk ( clk          ),
  .rd_clk ( clk_r        ),

  .din    ( abs_position ),
  .wr_en  ( trigger      ),//( w_en_reg     ),//( 1'b1 ),//( trigger      ),

  .rd_en  ( rd_en_reg    ),//( 1'b1 ),
  .dout   ( from_FIFO    ),

  .full   (  ),
  .empty  (  ),

  .rd_data_count (),
  .wr_data_count ()

);
*/

//generate clk
always
  begin
    clk = 1; #0.5;
    clk = 0; #0.5;
  end

  always
  begin
    clk_r = 1; #0.05;
    clk_r = 0; #0.05;
  end
//////////////////////////////////////////////////////////////////////////////////

always
  begin
      wait ( trigger );
      #5;
      rd_en = 1; #0.1;
      rd_en = 0;
  end

//generate zero mark

always
  begin
  	  wait ( zero_mark );
      z = 1; #5;
      z = 0;
  end
 
////
always
  begin
  	  wait ( en );
      a = 1; b = 0; #10;
      b = 1;        #10;
      a = 0;        #10;
      b = 0;        #10;

      a = 1; b = 0; #10;
      b = 1;        #10;
      a = 0;        #10;
      b = 0;        #10;

      //reverse test
      b = 1;        #10;
      a = 1;        #10;
      b = 0;        #10;
      a = 0;        #10;

      b = 1;        #10;
      a = 1;        #10;
      b = 0;        #10;
      a = 0;        #10;  
     
  end  
//////////////////////////////////////////////////////////////////////////////////

initial
  begin
  	a = 0; b = 0; z = 0; zero_mark = 0;
    rd_en = 0; w_en = 0;

    aresetn   = 0; en = 0; #10; 
    aresetn   = 1;         #1;
    
    en        = 1;       
    zero_mark = 1;         #1;
    zero_mark = 0;            
    
    
    
    ////////////////////////////////////////////////////////
    //activate zero-marks when you want to sim rotation enc
    //POSITION_SIZE   = 6; STEPS_IN_CIRCLE = 5;
    // #39 #64 - it's sync case
    // #34 #59 - it's when Z is earlier then counted end of circ
    // #49 #63 - it's when Z is later then counted end of circ
    ///*
    #39;
    zero_mark = 1; #1;
    zero_mark = 0; 
    #64;

    zero_mark = 1; #1;
    zero_mark = 0;
    //*/ 
    ////////////////////////////////////////////////////////
  end	


always_ff @(posedge clk or negedge aresetn) 
begin 
  if( ~aresetn ) begin
    r_a       <= 1'b0;
    r_b       <= 1'b0;
    r_z       <= 1'b0;
    w_en_reg  <= 1'b0;
    
  end else begin
    r_a       <= a;
    r_b       <= b;
    r_z       <= z;
    w_en_reg  <= w_en;
    
  end
end 


always_ff @(posedge clk_r or negedge aresetn) 
begin 
  if( ~aresetn ) begin
    rd_en_reg       <= 1'b0;
    trigger_delayed <= 1'b0; 
    delay_stages    <= 'b0;
  end else begin
    rd_en_reg       <= rd_en;
    delay_stages    <= {rd_en_reg, delay_stages[0]};
    trigger_delayed <= delay_stages[1];
  end
end



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
endmodule
