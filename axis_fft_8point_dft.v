// default_nettype of none prevents implicit wire declaration.
// wont synthesis if a signal is not declared
`default_nettype none
`timescale 1ps / 1ps

module fft_8point_dft #(
  parameter integer C_AXIS_TDATA_WIDTH = 64, // Data width of input is 64
  parameter integer C_AXIS_TOUT_WIDTH = 512, // Data width of output is 512 if combined
  parameter integer C_AXIS_TID_WIDTH = 1,
  parameter integer C_AXIS_TDEST_WIDTH = 1,
  parameter integer C_AXIS_TUSER_WIDTH = 1
)
(
    input wire		                            s_axis_aclk,
    input wire		                            s_axis_areset,      
    input wire                                  s_axis_tvalid,
    output wire                                 s_axis_tready,
    input wire      [C_AXIS_TDATA_WIDTH-1:0]    s_axis_tdata,
/////////////////no use of the following signals/////////////////////////////
    input wire      [C_AXIS_TDATA_WIDTH/8-1:0]  s_axis_tkeep,
    input wire      [C_AXIS_TDATA_WIDTH/8-1:0]  s_axis_tstrb,
    input wire                                  s_axis_tlast,
    input wire      [C_AXIS_TID_WIDTH-1:0]      s_axis_tid,
    input wire      [C_AXIS_TDEST_WIDTH-1:0]    s_axis_tdest,
    input wire      [C_AXIS_TUSER_WIDTH-1:0]    s_axis_tuser,
////////////////////////////////////////////////////////////////////////////
    input wire                                  m_axis_aclk,
    output wire                                 m_axis_tvalid,
    input  wire                                 m_axis_tready,
    output wire     [C_AXIS_TOUT_WIDTH-1:0]     m_axis_tdata,

////////////////no use of the following signals/////////////////////////////
    output wire     [C_AXIS_TDATA_WIDTH/8-1:0]  m_axis_tkeep,
    output wire     [C_AXIS_TDATA_WIDTH/8-1:0]  m_axis_tstrb,
    output wire                                 m_axis_tlast,
    output wire     [C_AXIS_TID_WIDTH-1:0]      m_axis_tid,
    output wire     [C_AXIS_TDEST_WIDTH-1:0]    m_axis_tdest,
    output wire     [C_AXIS_TUSER_WIDTH-1:0]    m_axis_tuser
);

///////////////////////////////////////////////////////////////////////
// variables for stream
////////////////////////////////////////////////////////////////////
reg                              d1_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tkeep;
reg                              d1_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tstrb = {C_AXIS_TDATA_WIDTH/8{1'b1}};
reg   [C_AXIS_TID_WIDTH-1:0]     d1_tid   = {C_AXIS_TID_WIDTH{1'b0}};
reg   [C_AXIS_TDEST_WIDTH-1:0]   d1_tdest = {C_AXIS_TDEST_WIDTH{1'b0}};
reg   [C_AXIS_TUSER_WIDTH-1:0]   d1_tuser = {C_AXIS_TUSER_WIDTH{1'b0}};


reg                              d2_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tkeep;
reg                              d2_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d2_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d2_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d2_tuser;


reg                              d3_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d3_tkeep;
reg                              d3_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d3_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d3_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d3_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d3_tuser;


reg                              d4_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d4_tkeep;
reg                              d4_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d4_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d4_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d4_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d4_tuser;


////////////////////////////////////////////////////////////////
// variables for core calculation 
//////////////////////////////////////////////////////////////

//input for FFT should be Q7 format (0.9921875 to -1.0)
    reg signed [7:0] x0;  
    reg signed [7:0] x1;  
    reg signed [7:0] x2;  
    reg signed [7:0] x3;  
    reg signed [7:0] x4;  
    reg signed [7:0] x5;  
    reg signed [7:0] x6;  
    reg signed [7:0] x7;

    reg signed [15:0] r_Xee_0_real = 'b0;
    reg signed [15:0] r_Xee_1_real = 'b0;
    reg signed [15:0] r_Xeo_0_real = 'b0;
    reg signed [15:0] r_Xeo_1_real = 'b0;
    reg signed [15:0] r_Xoe_0_real = 'b0;
    reg signed [15:0] r_Xoe_1_real = 'b0;
    reg signed [15:0] r_Xoo_0_real = 'b0;
    reg signed [15:0] r_Xoo_1_real = 'b0;

    reg signed [15:0] r_Xe_0_real = 'b0;
    reg signed [15:0] r_Xe_0_imag = 'b0;
    reg signed [15:0] r_Xe_1_real = 'b0;
    reg signed [15:0] r_Xe_1_imag = 'b0;
    reg signed [15:0] r_Xe_2_real = 'b0;
    reg signed [15:0] r_Xe_2_imag = 'b0;
    reg signed [15:0] r_Xe_3_real = 'b0;
    reg signed [15:0] r_Xe_3_imag = 'b0;
    reg signed [15:0] r_Xo_0_real = 'b0;
    reg signed [15:0] r_Xo_0_imag = 'b0;
    reg signed [15:0] r_Xo_1_real = 'b0;
    reg signed [15:0] r_Xo_1_imag = 'b0;
    reg signed [15:0] r_Xo_2_real = 'b0;
    reg signed [15:0] r_Xo_2_imag = 'b0;
    reg signed [15:0] r_Xo_3_real = 'b0;
    reg signed [15:0] r_Xo_3_imag = 'b0;
        
    reg signed [31:0] r_X_0_real = 'b0;
    reg signed [31:0] r_X_0_imag = 'b0;
    reg signed [31:0] r_X_1_real = 'b0;
    reg signed [31:0] r_X_1_imag = 'b0;
    reg signed [31:0] r_X_2_real = 'b0;
    reg signed [31:0] r_X_2_imag = 'b0;
    reg signed [31:0] r_X_3_real = 'b0;
    reg signed [31:0] r_X_3_imag = 'b0;
    reg signed [31:0] r_X_4_real = 'b0;
    reg signed [31:0] r_X_4_imag = 'b0;
    reg signed [31:0] r_X_5_real = 'b0;
    reg signed [31:0] r_X_5_imag = 'b0;
    reg signed [31:0] r_X_6_real = 'b0;
    reg signed [31:0] r_X_6_imag = 'b0;
    reg signed [31:0] r_X_7_real = 'b0;
    reg signed [31:0] r_X_7_imag = 'b0;



    reg signed [15:0] Xee_0_real;
    reg signed [15:0] Xee_1_real;
    reg signed [15:0] Xeo_0_real;
    reg signed [15:0] Xeo_1_real;
    reg signed [15:0] Xoe_0_real;
    reg signed [15:0] Xoe_1_real;
    reg signed [15:0] Xoo_0_real;
    reg signed [15:0] Xoo_1_real;

    reg signed [15:0] Xe_0_real;
    reg signed [15:0] Xe_0_imag;
    reg signed [15:0] Xe_1_real;
    reg signed [15:0] Xe_1_imag;
    reg signed [15:0] Xe_2_real;
    reg signed [15:0] Xe_2_imag;
    reg signed [15:0] Xe_3_real;
    reg signed [15:0] Xe_3_imag;
    reg signed [15:0] Xo_0_real;
    reg signed [15:0] Xo_0_imag;
    reg signed [15:0] Xo_1_real;
    reg signed [15:0] Xo_1_imag;
    reg signed [15:0] Xo_2_real;
    reg signed [15:0] Xo_2_imag;
    reg signed [15:0] Xo_3_real;
    reg signed [15:0] Xo_3_imag;

    reg signed [31:0] X_0_real;
    reg signed [31:0] X_0_imag;
    reg signed [31:0] X_1_real;
    reg signed [31:0] X_1_imag;
    reg signed [31:0] X_2_real;
    reg signed [31:0] X_2_imag;
    reg signed [31:0] X_3_real;
    reg signed [31:0] X_3_imag;
    reg signed [31:0] X_4_real;
    reg signed [31:0] X_4_imag;
    reg signed [31:0] X_5_real;
    reg signed [31:0] X_5_imag;
    reg signed [31:0] X_6_real;
    reg signed [31:0] X_6_imag;
    reg signed [31:0] X_7_real;
    reg signed [31:0] X_7_imag;



    reg signed [31:0] X_1_temp_real, X_1_temp_imag;
    reg signed [31:0] X_3_temp_real, X_3_temp_imag;
    reg signed [31:0] X_5_temp_real, X_5_temp_imag;
    reg signed [31:0] X_7_temp_real, X_7_temp_imag;

/////////////////////////////////////////////////////////////////////
// RTL Logic
///////////////////////////////////////////////////////////////////

assign s_axis_tready = ~m_axis_tvalid | m_axis_tready;

//flow of valid
always @(posedge s_axis_aclk) begin
    if (s_axis_tready) begin
        d1_tvalid   <= s_axis_tvalid;
     	{x7, x6, x5, x4, x3, x2, x1, x0}  <= s_axis_tdata[63:0];
		d1_tkeep  	<= s_axis_tkeep; 
		d1_tlast  	<= s_axis_tlast;
		d1_tid    	<= s_axis_tid;
		d1_tstrb  	<= s_axis_tstrb;
		d1_tuser   	<= s_axis_tuser;
		d1_tdest  	<= s_axis_tdest;
	end
end

always @(posedge s_axis_aclk) begin                 //r_Xee_0_real <= Xee_0_real;
	if (s_axis_tready) begin
        d2_tvalid 	<= d1_tvalid;
		d2_tkeep  	<= d1_tkeep;
		d2_tlast  	<= d1_tlast;
		d2_tid    	<= d1_tid;
		d2_tstrb  	<= d1_tstrb;
		d2_tuser   	<= d1_tuser;
		d2_tdest  	<= d1_tdest;
	end
end



always @(posedge s_axis_aclk) begin                 //r_Xe_0_real <= Xe_0_real;
	if (s_axis_tready) begin
        d3_tvalid 	<= d2_tvalid;
		d3_tkeep  	<= d2_tkeep;
		d3_tlast  	<= d2_tlast;
		d3_tid    	<= d2_tid;
		d3_tstrb  	<= d2_tstrb;
		d3_tuser   	<= d2_tuser;
		d3_tdest  	<= d2_tdest;
	end
end


always @(posedge s_axis_aclk) begin                 //r_X_0_real <= X_0_real;
	if (s_axis_tready) begin
        d4_tvalid 	<= d3_tvalid;
		d4_tkeep  	<= d3_tkeep;
		d4_tlast  	<= d3_tlast;
		d4_tid    	<= d3_tid;
		d4_tstrb  	<= d3_tstrb;
		d4_tuser   	<= d3_tuser;
		d4_tdest  	<= d3_tdest;
	end
end



always @(posedge s_axis_aclk) begin
    if(s_axis_tready) begin
        r_Xee_0_real <= Xee_0_real;
        r_Xee_1_real <= Xee_1_real;

        r_Xeo_0_real <= Xeo_0_real;
        r_Xeo_1_real <= Xeo_1_real;
        
        r_Xoe_0_real <= Xoe_0_real;
        r_Xoe_1_real <= Xoe_1_real;

        r_Xoo_0_real <= Xoo_0_real;
        r_Xoo_1_real <= Xoo_1_real;


        r_Xe_0_real <= Xe_0_real;
        r_Xe_0_imag <= Xe_0_imag;
        r_Xe_1_real <= Xe_1_real;
        r_Xe_1_imag <= Xe_1_imag;
        r_Xe_2_real <= Xe_2_real;
        r_Xe_2_imag <= Xe_2_imag;
        r_Xe_3_real <= Xe_3_real;
        r_Xe_3_imag <= Xe_3_imag;

        r_Xo_0_real <= Xo_0_real;
        r_Xo_0_imag <= Xo_0_imag;
        r_Xo_1_real <= Xo_1_real;
        r_Xo_1_imag <= Xo_1_imag;
        r_Xo_2_real <= Xo_2_real;
        r_Xo_2_imag <= Xo_2_imag;
        r_Xo_3_real <= Xo_3_real;
        r_Xo_3_imag <= Xo_3_imag;



        r_X_0_real <= X_0_real;
        r_X_0_imag <= X_0_imag;
        r_X_1_real <= X_1_real;
        r_X_1_imag <= X_1_imag;
        r_X_2_real <= X_2_real;
        r_X_2_imag <= X_2_imag;
        r_X_3_real <= X_3_real;
        r_X_3_imag <= X_3_imag;
        r_X_4_real <= X_4_real;
        r_X_4_imag <= X_4_imag;
        r_X_5_real <= X_5_real;
        r_X_5_imag <= X_5_imag;
        r_X_6_real <= X_6_real;
        r_X_6_imag <= X_6_imag;
        r_X_7_real <= X_7_real;
        r_X_7_imag <= X_7_imag;


    end
end 


always @(*) begin

//2-point DFT calculation

    Xee_0_real = x0 + x4;  
    Xee_1_real = x0 - x4;  

    Xeo_0_real = x2 + x6;  
    Xeo_1_real = x2 - x6;

    Xoe_0_real = x1 + x5; 
    Xoe_1_real = x1 - x5;  

    Xoo_0_real = x3 + x7; 
    Xoo_1_real = x3 - x7; 

//4-point DFT calculation

    Xe_0_real = r_Xee_0_real + r_Xeo_0_real;
    Xe_0_imag = 'b0;

    Xe_1_real = r_Xee_1_real;
    Xe_1_imag = -r_Xeo_1_real;
    
    Xe_2_real = r_Xee_0_real - r_Xeo_0_real;
    Xe_2_imag = 'b0;
    
    Xe_3_real = r_Xee_1_real;
    Xe_3_imag = r_Xeo_1_real;

    
    Xo_0_real = r_Xoe_0_real + r_Xoo_0_real;
    Xo_0_imag = 'b0;
    
    Xo_1_real = r_Xoe_1_real;
    Xo_1_imag = -r_Xoo_1_real;
    
    Xo_2_real = r_Xoe_0_real - r_Xoo_0_real;
    Xo_2_imag = 'b0;
    
    Xo_3_real = r_Xoe_1_real;
    Xo_3_imag = r_Xoo_1_real;

//8-point DFT calculation

    X_0_real = r_Xe_0_real + r_Xo_0_real;
    X_0_imag = r_Xe_0_imag + r_Xo_0_imag;

    // W_8^1 = cos(pi/4) - j*sin(pi/4) = 0.707 - j*0.707
    // 0.707 is approximately 23170 in a 16-bit signed fixed-point (Q15 format) (shifting Q22 result back to Q7 could result in percision loss)
    X_1_temp_real = (r_Xo_1_real *  23170 + r_Xo_1_imag * 23170) >>> 15;        //X_1_temp_real is 32 bits Q7 format
    X_1_temp_imag = (r_Xo_1_real * -23170 + r_Xo_1_imag * 23170) >>> 15;
    X_1_real = r_Xe_1_real + X_1_temp_real;
    X_1_imag = r_Xe_1_imag + X_1_temp_imag;

    X_2_real = r_Xe_2_real +r_Xo_2_imag;
    X_2_imag = r_Xe_2_imag -r_Xo_2_real; 

    // W_8^3 = cos(3*pi/4) - j*sin(3*pi/4) = -0.707 - j*0.707
    X_3_temp_real = (r_Xo_3_real * -23170 + r_Xo_3_imag *  23170) >>> 15;
    X_3_temp_imag = (r_Xo_3_real * -23170 + r_Xo_3_imag * -23170) >>> 15; 
    X_3_real = r_Xe_3_real + X_3_temp_real;
    X_3_imag = r_Xe_3_imag + X_3_temp_imag;



    X_4_real = r_Xe_0_real - r_Xo_0_real;
    X_4_imag = r_Xe_0_imag - r_Xo_0_imag;

    X_5_temp_real = (r_Xo_1_real * -23170 + r_Xo_1_imag * -23170) >>> 15; 
    X_5_temp_imag = (r_Xo_1_real *  23170 + r_Xo_1_imag * -23170) >>> 15; 
    X_5_real = r_Xe_1_real + X_5_temp_real;  
    X_5_imag = r_Xe_1_imag + X_5_temp_imag;

    X_6_real = r_Xe_2_real - r_Xo_2_imag; 
    X_6_imag = r_Xe_2_imag + r_Xo_2_real;

    X_7_temp_real = (r_Xo_3_real *  23170 + r_Xo_3_imag * -23170) >>> 15; 
    X_7_temp_imag = (r_Xo_3_real *  23170 + r_Xo_3_imag *  23170) >>> 15; 
    X_7_real = r_Xe_3_real + X_7_temp_real; 
    X_7_imag = r_Xe_3_imag + X_7_temp_imag;


 end


assign m_axis_tvalid = d4_tvalid;
assign m_axis_tdata = {r_X_7_real, r_X_7_imag, r_X_6_real, r_X_6_imag, r_X_5_real, r_X_5_imag, r_X_4_real, r_X_4_imag,
r_X_3_real, r_X_3_imag, r_X_2_real, r_X_2_imag, r_X_1_real, r_X_1_imag, r_X_0_real, r_X_0_imag};



endmodule

//cleaning up `default_nettype none
`default_nettype wire