// default_nettype of none prevents implicit wire declaration.
// wont synthesis if a signal is not declared
///DIT IFFT
`default_nettype none
`timescale 1ps / 1ps

module ifft_8point_dft #(
    parameter integer C_AXIS_TDATA_WIDTH = 512,  // Data width of total input is 512 (32 bits for each eight of imag and real)
    parameter integer C_AXIS_TOUT_WIDTH = 64,   // Data width of total output is 64 (8 bits for each eight of real)
    parameter integer C_AXIS_TID_WIDTH = 1,
    parameter integer C_AXIS_TDEST_WIDTH = 1,
    parameter integer C_AXIS_TUSER_WIDTH = 1
)
(
    input 			                            s_axis_aclk,
    input 			                            s_axis_areset,
    input 			                            s_axis_tvalid,
    output 			                            s_axis_tready,
    input wire      [C_AXIS_TDATA_WIDTH-1:0]    s_axis_tdata,
/////////////////no use of the following signals/////////////////////////////
    input wire      [C_AXIS_TDATA_WIDTH/8-1:0]  s_axis_tkeep,                          
    input wire      [C_AXIS_TDATA_WIDTH/8-1:0]  s_axis_tstrb,                      
    input wire                                  s_axis_tlast,
    input wire      [C_AXIS_TID_WIDTH-1:0]      s_axis_tid,
    input wire      [C_AXIS_TDEST_WIDTH-1:0]    s_axis_tdest,
    input wire      [C_AXIS_TUSER_WIDTH-1:0]    s_axis_tuser,   
///////////////////////////////////////////////////////////////////////////////
    input                                       m_axis_aclk,
    output 			                            m_axis_tvalid,
    input 			                            m_axis_tready,
    output wire     [C_AXIS_TOUT_WIDTH-1:0]     m_axis_tdata,
/////////////////no use of the following signals/////////////////////////////
    output wire     [C_AXIS_TOUT_WIDTH/8-1:0]   m_axis_tkeep,
    output wire     [C_AXIS_TOUT_WIDTH/8-1:0]   m_axis_tstrb,
    output wire                                 m_axis_tlast,
    output wire     [C_AXIS_TID_WIDTH-1:0]      m_axis_tid,
    output wire     [C_AXIS_TDEST_WIDTH-1:0]    m_axis_tdest,
    output wire     [C_AXIS_TUSER_WIDTH-1:0]    m_axis_tuser
);
///////////////////////////////////////////////////////////////////////
// variables for stream
////////////////////////////////////////////////////////////////////
reg                              d1_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d1_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tkeep;
reg                              d1_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tstrb = {C_AXIS_TDATA_WIDTH/8{1'b1}};
reg   [C_AXIS_TID_WIDTH-1:0]     d1_tid   = {C_AXIS_TID_WIDTH{1'b0}};
reg   [C_AXIS_TDEST_WIDTH-1:0]   d1_tdest = {C_AXIS_TDEST_WIDTH{1'b0}};
reg   [C_AXIS_TUSER_WIDTH-1:0]   d1_tuser = {C_AXIS_TUSER_WIDTH{1'b0}};


reg                              d2_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d2_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tkeep;
reg                              d2_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d2_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d2_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d2_tuser;


reg                              d3_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d3_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d3_tkeep;
reg                              d3_tlast;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d3_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d3_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d3_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d3_tuser;

////////////////////////////////////////////////////////////////
// variables for core calculation 
////////////////////////////////////////////////////////////////
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


    reg signed [31:0] r_Xe_0_real = 'b0;
    reg signed [31:0] r_Xe_0_imag = 'b0;
    reg signed [31:0] r_Xe_1_real = 'b0;
    reg signed [31:0] r_Xe_1_imag = 'b0;
    reg signed [31:0] r_Xe_2_real = 'b0;
    reg signed [31:0] r_Xe_2_imag = 'b0;
    reg signed [31:0] r_Xe_3_real = 'b0;
    reg signed [31:0] r_Xe_3_imag = 'b0;
    reg signed [31:0] r_Xo_0_real = 'b0;
    reg signed [31:0] r_Xo_0_imag = 'b0;
    reg signed [31:0] r_Xo_1_real = 'b0;
    reg signed [31:0] r_Xo_1_imag = 'b0;
    reg signed [31:0] r_Xo_2_real = 'b0;
    reg signed [31:0] r_Xo_2_imag = 'b0;
    reg signed [31:0] r_Xo_3_real = 'b0;
    reg signed [31:0] r_Xo_3_imag = 'b0;
    
    reg signed [31:0] r_Xee_0_real = 'b0;
    reg signed [31:0] r_Xee_0_imag = 'b0;
    reg signed [31:0] r_Xee_1_real = 'b0;
    reg signed [31:0] r_Xee_1_imag = 'b0;
    reg signed [31:0] r_Xeo_0_real = 'b0;
    reg signed [31:0] r_Xeo_0_imag = 'b0;
    reg signed [31:0] r_Xeo_1_real = 'b0;
    reg signed [31:0] r_Xeo_1_imag = 'b0;
    reg signed [31:0] r_Xoe_0_real = 'b0;
    reg signed [31:0] r_Xoe_0_imag = 'b0;
    reg signed [31:0] r_Xoe_1_real = 'b0;
    reg signed [31:0] r_Xoe_1_imag = 'b0;
    reg signed [31:0] r_Xoo_0_real = 'b0;
    reg signed [31:0] r_Xoo_0_imag = 'b0;
    reg signed [31:0] r_Xoo_1_real = 'b0;
    reg signed [31:0] r_Xoo_1_imag = 'b0;
        
    reg signed [31:0] r_x_0_real = 'b0;
    reg signed [31:0] r_x_0_imag = 'b0;
    reg signed [31:0] r_x_1_real = 'b0;
    reg signed [31:0] r_x_1_imag = 'b0;
    reg signed [31:0] r_x_2_real = 'b0;
    reg signed [31:0] r_x_2_imag = 'b0;
    reg signed [31:0] r_x_3_real = 'b0;
    reg signed [31:0] r_x_3_imag = 'b0;
    reg signed [31:0] r_x_4_real = 'b0;
    reg signed [31:0] r_x_4_imag = 'b0;
    reg signed [31:0] r_x_5_real = 'b0;
    reg signed [31:0] r_x_5_imag = 'b0;
    reg signed [31:0] r_x_6_real = 'b0;
    reg signed [31:0] r_x_6_imag = 'b0;
    reg signed [31:0] r_x_7_real = 'b0;
    reg signed [31:0] r_x_7_imag = 'b0;



    reg signed [31:0] Xe_0_real;
    reg signed [31:0] Xe_0_imag;
    reg signed [31:0] Xe_1_real;
    reg signed [31:0] Xe_1_imag;
    reg signed [31:0] Xe_2_real;
    reg signed [31:0] Xe_2_imag;
    reg signed [31:0] Xe_3_real;
    reg signed [31:0] Xe_3_imag;
    reg signed [31:0] Xo_0_real;
    reg signed [31:0] Xo_0_imag;
    reg signed [31:0] Xo_1_real;
    reg signed [31:0] Xo_1_imag;
    reg signed [31:0] Xo_2_real;
    reg signed [31:0] Xo_2_imag;
    reg signed [31:0] Xo_3_real;
    reg signed [31:0] Xo_3_imag;

    reg signed [31:0] Xee_0_real;
    reg signed [31:0] Xee_0_imag;
    reg signed [31:0] Xee_1_real;
    reg signed [31:0] Xee_1_imag;
    reg signed [31:0] Xeo_0_real;
    reg signed [31:0] Xeo_0_imag;
    reg signed [31:0] Xeo_1_real;
    reg signed [31:0] Xeo_1_imag;
    reg signed [31:0] Xoe_0_real;
    reg signed [31:0] Xoe_0_imag;
    reg signed [31:0] Xoe_1_real;
    reg signed [31:0] Xoe_1_imag;
    reg signed [31:0] Xoo_0_real;
    reg signed [31:0] Xoo_0_imag;
    reg signed [31:0] Xoo_1_real;
    reg signed [31:0] Xoo_1_imag;

    reg signed [31:0] x_0_real;
    reg signed [31:0] x_0_imag;
    reg signed [31:0] x_1_real;
    reg signed [31:0] x_1_imag;
    reg signed [31:0] x_2_real;
    reg signed [31:0] x_2_imag;
    reg signed [31:0] x_3_real;
    reg signed [31:0] x_3_imag;
    reg signed [31:0] x_4_real;
    reg signed [31:0] x_4_imag;
    reg signed [31:0] x_5_real;
    reg signed [31:0] x_5_imag;
    reg signed [31:0] x_6_real;
    reg signed [31:0] x_6_imag;
    reg signed [31:0] x_7_real;
    reg signed [31:0] x_7_imag;


    reg signed [31:0] Xoe_1_temp_real, Xoe_1_temp_imag;
    reg signed [31:0] Xoo_1_temp_real, Xoo_1_temp_imag;

/////////////////////////////////////////////////////////////////////
// RTL Logic
///////////////////////////////////////////////////////////////////


assign s_axis_tready = ~m_axis_tvalid | m_axis_tready;

//flow of valid
always @(posedge s_axis_aclk) begin
    if (s_axis_tready) begin
        d1_tvalid   <= s_axis_tvalid;
        {r_X_7_real, r_X_7_imag, r_X_6_real, r_X_6_imag, r_X_5_real, r_X_5_imag, r_X_4_real, r_X_4_imag,
        r_X_3_real, r_X_3_imag, r_X_2_real, r_X_2_imag, r_X_1_real, r_X_1_imag, r_X_0_real, r_X_0_imag}    <= s_axis_tdata[511:0];
		d1_tkeep  	<= s_axis_tkeep; 
		d1_tlast  	<= s_axis_tlast;
		d1_tid    	<= s_axis_tid;
		d1_tstrb  	<= s_axis_tstrb;
		d1_tuser   	<= s_axis_tuser;
		d1_tdest  	<= s_axis_tdest;
	end
end

always @(posedge s_axis_aclk) begin                 //r_Xe_0_real <= Xe_0_real;
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



always @(posedge s_axis_aclk) begin                 //r_Xee_0_real <= Xee_0_real;
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


always @(posedge s_axis_aclk) begin                 //r_x_0_real <= x_0_real;
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



        r_Xee_0_real <= Xee_0_real;
        r_Xee_0_imag <= Xee_0_imag;
        r_Xee_1_real <= Xee_1_real;
        r_Xee_1_imag <= Xee_1_imag;

        r_Xeo_0_real <= Xeo_0_real;
        r_Xeo_0_imag <= Xeo_0_imag;
        r_Xeo_1_real <= Xeo_1_real;
        r_Xeo_1_imag <= Xeo_1_imag;
        
        r_Xoe_0_real <= Xoe_0_real;
        r_Xoe_0_imag <= Xoe_0_imag;
        r_Xoe_1_real <= Xoe_1_real;
        r_Xoe_1_imag <= Xoe_1_imag;

        r_Xoo_0_real <= Xoo_0_real;
        r_Xoo_0_imag <= Xoo_0_imag;
        r_Xoo_1_real <= Xoo_1_real;
        r_Xoo_1_imag <= Xoo_1_imag;
        


        r_x_0_real <= x_0_real;

        r_x_1_real <= x_1_real;

        r_x_2_real <= x_2_real;

        r_x_3_real <= x_3_real;

        r_x_4_real <= x_4_real;

        r_x_5_real <= x_5_real;

        r_x_6_real <= x_6_real;

        r_x_7_real <= x_7_real;

    end
end 


always @(*) begin

//8-point DFT calculation

    Xe_0_real = r_X_0_real + r_X_4_real;
    Xe_0_imag = r_X_0_imag + r_X_4_imag; 

    Xe_1_real = r_X_1_real + r_X_5_real;
    Xe_1_imag = r_X_1_imag + r_X_5_imag; 
    
    Xe_2_real = r_X_2_real + r_X_6_real;
    Xe_2_imag = r_X_2_imag + r_X_6_imag; 

    Xe_3_real = r_X_3_real + r_X_7_real;
    Xe_3_imag = r_X_3_imag + r_X_7_imag; 

    Xo_0_real = r_X_0_real - r_X_4_real;
    Xo_0_imag = r_X_0_imag - r_X_4_imag; 

    Xo_1_real = r_X_1_real - r_X_5_real;
    Xo_1_imag = r_X_1_imag - r_X_5_imag; 
    
    Xo_2_real = r_X_2_real - r_X_6_real;
    Xo_2_imag = r_X_2_imag - r_X_6_imag; 

    Xo_3_real = r_X_3_real - r_X_7_real;
    Xo_3_imag = r_X_3_imag - r_X_7_imag;

//4-point DFT calculation
    // W_8^-1 = cos(pi/4) + j*sin(pi/4) = 0.707 + j*0.707
    // 0.707 is approximately 23170 in a 16-bit signed fixed-point
    Xoe_1_temp_real = (r_Xo_1_real *  23170 + r_Xo_1_imag * -23170) >>> 15;
    Xoe_1_temp_imag = (r_Xo_1_real *  23170 + r_Xo_1_imag *  23170) >>> 15;

    // W_8^-3 = cos(3*pi/4) + j*sin(3*pi/4) = -0.707 + j*0.707
    Xoo_1_temp_real = (r_Xo_3_real * -23170 + r_Xo_3_imag * -23170) >>> 15; 
    Xoo_1_temp_imag = (r_Xo_3_real *  23170 + r_Xo_3_imag *  23170) >>> 15; 


    Xee_0_real = r_Xe_0_real + r_Xe_2_real;
    Xee_0_imag = r_Xe_0_imag + r_Xe_2_imag;

    Xee_1_real = r_Xe_1_real + r_Xe_3_real;
    Xee_1_imag = r_Xe_1_imag + r_Xe_3_imag;
    
    Xeo_0_real = r_Xe_0_real - r_Xe_2_real;
    Xeo_0_imag = r_Xe_0_imag - r_Xe_2_imag;

    Xeo_1_real = r_Xe_1_real - r_Xe_3_real;
    Xeo_1_imag = r_Xe_1_imag - r_Xe_3_imag;
    


    Xoe_0_real = r_Xo_0_real - r_Xo_2_imag;
    Xoe_0_imag = r_Xo_0_imag + r_Xo_2_real;
    
    Xoe_1_real = Xoe_1_temp_real + Xoo_1_temp_real;
    Xoe_1_imag = Xoe_1_temp_imag + Xoo_1_temp_imag;
    
    Xoo_0_real = r_Xo_0_real + r_Xo_2_imag;
    Xoo_0_imag = r_Xo_0_imag - r_Xo_2_real;
    
    Xoo_1_real = Xoe_1_temp_real - Xoo_1_temp_real;
    Xoo_1_imag = Xoe_1_temp_imag - Xoo_1_temp_imag;

//2-point DFT calculation (we only find output which are only real)

	x_0_real = (r_Xee_0_real + r_Xee_1_real) >>> 3; // >>>3 for 1/N

	x_4_real = (r_Xee_0_real - r_Xee_1_real) >>> 3;

	x_2_real = (r_Xeo_0_real - r_Xeo_1_imag) >>> 3;

	x_6_real = (r_Xeo_0_real + r_Xeo_1_imag) >>> 3;

	x_1_real = (r_Xoe_0_real + r_Xoe_1_real) >>> 3;

	x_5_real = (r_Xoe_0_real - r_Xoe_1_real) >>> 3;  

	x_3_real = (r_Xoo_0_real - r_Xoo_1_imag) >>> 3; 

	x_7_real = (r_Xoo_0_real + r_Xoo_1_imag) >>> 3; 

 end

assign m_axis_tvalid = d4_tvalid;
assign m_axis_tdata = {r_x7_real, r_x6_real, r_x5_real, r_x4_real,
		       r_x3_real, r_x2_real, r_x1_real, r_x0_real};    // need to make the output smaller and make it 64 bit


endmodule

//cleaning up `default_nettype none
`default_nettype wire
