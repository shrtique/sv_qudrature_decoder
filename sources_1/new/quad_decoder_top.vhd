library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--REGISTERS DISCIPTION--
-- reg0: W
        --[0]     enable     
        --[20:4]  steps_in_circle
        --[31:21] reserved
--------
-- reg1: W
        --[31:0]  dbnc_time 
--------
-- reg2: W
        --[31:0]  zero_position 
--------
-- reg3: W
        --[31:0]  delta_size 
--------
-- reg4: R
        --[31:0]  absolute_position 
--------
-- reg5: R
        --[0]     enable_status
        --[1]     zero_mark_found
        --[2]     direction
        --[3]     trigger_out
        --[31:4]  reserved 
--------
------------------------

entity quad_decoder_top is
	generic (
		-- Users to add parameters here
		POSITION_SIZE : integer := 32;

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6
	);
	port (
		-- Users to add ports here
		i_clk              : in std_logic;
        i_aresetn          : in std_logic;

        i_a                : in std_logic;       
        i_b                : in std_logic;
        i_z                : in std_logic;
        
        enable_status      : out std_logic;
        zero_mark_detected : out std_logic;
        direction          : out std_logic;
        step_toggle        : out std_logic;
        trigger_out        : out std_logic;
        absolute_position  : out std_logic_vector(POSITION_SIZE-1 downto 0);

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end quad_decoder_top;

architecture arch_imp of quad_decoder_top is

	-- component declaration
	component AXI_Lite_quad_dec is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (

        -- Users to add ports here
        slv_reg0_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); 
        slv_reg1_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0); 
        slv_reg2_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        slv_reg3_out : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
                                                                                 
        slv_reg4_in  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);  
        slv_reg5_in  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);   
        -- User ports ends
			
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component AXI_Lite_quad_dec;

	--User component
	component quadrature_decoder is
      generic (
        POSITION_SIZE : integer := 32   
      );
      port (
  
        i_clk              : in std_logic;
        i_aresetn          : in std_logic;

        i_a                : in std_logic;       
        i_b                : in std_logic;
        i_z                : in std_logic;
        
        enable             : in std_logic;
        dbnc_time          : in std_logic_vector(31 downto 0); 
        zero_position      : in std_logic_vector(POSITION_SIZE-1 downto 0);  
        delta_size         : in std_logic_vector(POSITION_SIZE-1 downto 0);
        steps_in_circle    : in std_logic_vector(POSITION_SIZE/2 downto 0);
        
        enable_status      : out std_logic;
        zero_mark_detected : out std_logic;
        direction          : out std_logic;
        step_toggle        : out std_logic;
        trigger_out        : out std_logic;
        absolute_position  : out std_logic_vector(POSITION_SIZE-1 downto 0)
   
      );
    end component  quadrature_decoder;

-------------------------------------------------------------------------------------------
--SIGNALS

signal slv_reg0 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal slv_reg1 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal slv_reg2 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal slv_reg3 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal slv_reg4 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal slv_reg5 : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);

-------------------------------------------------------------------------------------------
begin

-- Instantiation of Axi Bus Interface S00_AXI
AXI_Lite_quad_dec_inst : AXI_Lite_quad_dec
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (

        slv_reg0_out => slv_reg0,
        slv_reg1_out => slv_reg1,
        slv_reg2_out => slv_reg2,
        slv_reg3_out => slv_reg3,

        slv_reg4_in  => slv_reg4,
        slv_reg5_in  => slv_reg5,

		S_AXI_ACLK	    => s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- Add user logic here

quadrature_decoder_inst : quadrature_decoder
      generic map (
        POSITION_SIZE => POSITION_SIZE   
      )
      port map (
  
        i_clk              => i_clk,
        i_aresetn          => i_aresetn,

        i_a                => i_a,      
        i_b                => i_b,
        i_z                => i_z,
    
        enable             => slv_reg0(0),
        dbnc_time          => slv_reg1, 
        zero_position      => slv_reg2,
        delta_size         => slv_reg3,
        steps_in_circle    => slv_reg0(20 downto 4), 
        
        enable_status      => slv_reg5(0),
        zero_mark_detected => slv_reg5(1),
        direction          => slv_reg5(2),
        trigger_out        => slv_reg5(3),
        step_toggle        => step_toggle,
        absolute_position  => slv_reg4
   
      );


-- TO OUTPUTS --
enable_status      <= slv_reg5(0);
zero_mark_detected <= slv_reg5(1);
direction          <= slv_reg5(2);
trigger_out        <= slv_reg5(3);

absolute_position  <= slv_reg4;

-- User logic ends

end arch_imp;
