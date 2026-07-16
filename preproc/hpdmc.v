module hpdmc_busif #(
	parameter sdram_depth = 26
) (
	input sys_clk,
	input sdram_rst,
	input [sdram_depth-1:0] fml_adr,
	input fml_stb,
	input fml_we,
	output fml_ack,
	output mgmt_stb,
	output mgmt_we,
	output [sdram_depth-3-1:0] mgmt_address,  
	input mgmt_ack,
	input data_ack
);
reg mgmt_stb_en;
assign mgmt_stb = fml_stb & mgmt_stb_en;
assign mgmt_we = fml_we;
assign mgmt_address = fml_adr[sdram_depth-1:3];
assign fml_ack = data_ack;
always @(posedge sys_clk) begin
	if(sdram_rst)
		mgmt_stb_en = 1'b1;
	else begin
		if(mgmt_ack)
			mgmt_stb_en = 1'b0;
		if(data_ack)
			mgmt_stb_en = 1'b1;
	end
end
endmodule
module hpdmc_iddr32 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT_Q1 = 1'b0,
	parameter INIT_Q2 = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [31:0] Q1,
	output [31:0] Q2,
	input C,
	input CE,
	input [31:0] D,
	input R,
	input S
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr0 (
	.Q1(Q1[0]),
	.Q2(Q2[0]),
	.C(C),
	.CE(CE),
	.D(D[0]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr1 (
	.Q1(Q1[1]),
	.Q2(Q2[1]),
	.C(C),
	.CE(CE),
	.D(D[1]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr2 (
	.Q1(Q1[2]),
	.Q2(Q2[2]),
	.C(C),
	.CE(CE),
	.D(D[2]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr3 (
	.Q1(Q1[3]),
	.Q2(Q2[3]),
	.C(C),
	.CE(CE),
	.D(D[3]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr4 (
	.Q1(Q1[4]),
	.Q2(Q2[4]),
	.C(C),
	.CE(CE),
	.D(D[4]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr5 (
	.Q1(Q1[5]),
	.Q2(Q2[5]),
	.C(C),
	.CE(CE),
	.D(D[5]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr6 (
	.Q1(Q1[6]),
	.Q2(Q2[6]),
	.C(C),
	.CE(CE),
	.D(D[6]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr7 (
	.Q1(Q1[7]),
	.Q2(Q2[7]),
	.C(C),
	.CE(CE),
	.D(D[7]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr8 (
	.Q1(Q1[8]),
	.Q2(Q2[8]),
	.C(C),
	.CE(CE),
	.D(D[8]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr9 (
	.Q1(Q1[9]),
	.Q2(Q2[9]),
	.C(C),
	.CE(CE),
	.D(D[9]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr10 (
	.Q1(Q1[10]),
	.Q2(Q2[10]),
	.C(C),
	.CE(CE),
	.D(D[10]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr11 (
	.Q1(Q1[11]),
	.Q2(Q2[11]),
	.C(C),
	.CE(CE),
	.D(D[11]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr12 (
	.Q1(Q1[12]),
	.Q2(Q2[12]),
	.C(C),
	.CE(CE),
	.D(D[12]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr13 (
	.Q1(Q1[13]),
	.Q2(Q2[13]),
	.C(C),
	.CE(CE),
	.D(D[13]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr14 (
	.Q1(Q1[14]),
	.Q2(Q2[14]),
	.C(C),
	.CE(CE),
	.D(D[14]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr15 (
	.Q1(Q1[15]),
	.Q2(Q2[15]),
	.C(C),
	.CE(CE),
	.D(D[15]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr16 (
	.Q1(Q1[16]),
	.Q2(Q2[16]),
	.C(C),
	.CE(CE),
	.D(D[16]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr17 (
	.Q1(Q1[17]),
	.Q2(Q2[17]),
	.C(C),
	.CE(CE),
	.D(D[17]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr18 (
	.Q1(Q1[18]),
	.Q2(Q2[18]),
	.C(C),
	.CE(CE),
	.D(D[18]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr19 (
	.Q1(Q1[19]),
	.Q2(Q2[19]),
	.C(C),
	.CE(CE),
	.D(D[19]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr20 (
	.Q1(Q1[20]),
	.Q2(Q2[20]),
	.C(C),
	.CE(CE),
	.D(D[20]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr21 (
	.Q1(Q1[21]),
	.Q2(Q2[21]),
	.C(C),
	.CE(CE),
	.D(D[21]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr22 (
	.Q1(Q1[22]),
	.Q2(Q2[22]),
	.C(C),
	.CE(CE),
	.D(D[22]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr23 (
	.Q1(Q1[23]),
	.Q2(Q2[23]),
	.C(C),
	.CE(CE),
	.D(D[23]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr24 (
	.Q1(Q1[24]),
	.Q2(Q2[24]),
	.C(C),
	.CE(CE),
	.D(D[24]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr25 (
	.Q1(Q1[25]),
	.Q2(Q2[25]),
	.C(C),
	.CE(CE),
	.D(D[25]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr26 (
	.Q1(Q1[26]),
	.Q2(Q2[26]),
	.C(C),
	.CE(CE),
	.D(D[26]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr27 (
	.Q1(Q1[27]),
	.Q2(Q2[27]),
	.C(C),
	.CE(CE),
	.D(D[27]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr28 (
	.Q1(Q1[28]),
	.Q2(Q2[28]),
	.C(C),
	.CE(CE),
	.D(D[28]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr29 (
	.Q1(Q1[29]),
	.Q2(Q2[29]),
	.C(C),
	.CE(CE),
	.D(D[29]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr30 (
	.Q1(Q1[30]),
	.Q2(Q2[30]),
	.C(C),
	.CE(CE),
	.D(D[30]),
	.R(R),
	.S(S)
);
IDDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT_Q1(INIT_Q1),
	.INIT_Q2(INIT_Q2),
	.SRTYPE(SRTYPE)
) iddr31 (
	.Q1(Q1[31]),
	.Q2(Q2[31]),
	.C(C),
	.CE(CE),
	.D(D[31]),
	.R(R),
	.S(S)
);
endmodule
module hpdmc_banktimer(
	input sys_clk,
	input sdram_rst,
	input tim_cas,
	input [1:0] tim_wr,
	input read,
	input write,
	output reg precharge_safe
);
reg [2:0] counter;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		counter <= 3'd0;
		precharge_safe <= 1'b1;
	end else begin
		if(read) begin
			counter <= 3'd4;
			precharge_safe <= 1'b0;
		end else if(write) begin
			counter <= {1'b1, tim_wr};
			precharge_safe <= 1'b0;
		end else begin
			if(counter == 3'b1)
				precharge_safe <= 1'b1;
			if(~precharge_safe)
				counter <= counter - 3'b1;
		end
	end
end
endmodule
module hpdmc #(
	parameter sdram_depth = 26,
	parameter sdram_columndepth = 8
) (
	input sys_clk,
	input dqs_clk,
	input sys_rst,
	input [31:0] wbc_adr_i,
	input [31:0] wbc_dat_i,
	output [31:0] wbc_dat_o,
	input [3:0] wbc_sel_i,
	input wbc_cyc_i,
	input wbc_stb_i,
	input wbc_we_i,
	output wbc_ack_o,
	input [sdram_depth-1:0] fml_adr,
	input fml_stb,
	input fml_we,
	output fml_ack,
	input [7:0] fml_sel,
	input [63:0] fml_di,
	output [63:0] fml_do,
	output reg sdram_cke,
	output reg sdram_cs_n,
	output reg sdram_we_n,
	output reg sdram_cas_n,
	output reg sdram_ras_n,
	output reg [12:0] sdram_adr,
	output reg [1:0] sdram_ba,
	output [3:0] sdram_dqm,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs
);
wire sdram_cke_r;
wire sdram_cs_n_r;
wire sdram_we_n_r;
wire sdram_cas_n_r;
wire sdram_ras_n_r;
wire [12:0] sdram_adr_r;
wire [1:0] sdram_ba_r;
always @(posedge sys_clk) begin
	sdram_cke <= sdram_cke_r;
	sdram_cs_n <= sdram_cs_n_r;
	sdram_we_n <= sdram_we_n_r;
	sdram_cas_n <= sdram_cas_n_r;
	sdram_ras_n <= sdram_ras_n_r;
	sdram_ba <= sdram_ba_r;
	sdram_adr <= sdram_adr_r;
end
wire bypass;
wire sdram_cs_n_bypass;
wire sdram_we_n_bypass;
wire sdram_cas_n_bypass;
wire sdram_ras_n_bypass;
wire [12:0] sdram_adr_bypass;
wire [1:0] sdram_ba_bypass;
wire sdram_cs_n_mgmt;
wire sdram_we_n_mgmt;
wire sdram_cas_n_mgmt;
wire sdram_ras_n_mgmt;
wire [12:0] sdram_adr_mgmt;
wire [1:0] sdram_ba_mgmt;
assign sdram_cs_n_r = bypass ? sdram_cs_n_bypass : sdram_cs_n_mgmt;
assign sdram_we_n_r = bypass ? sdram_we_n_bypass : sdram_we_n_mgmt;
assign sdram_cas_n_r = bypass ? sdram_cas_n_bypass : sdram_cas_n_mgmt;
assign sdram_ras_n_r = bypass ? sdram_ras_n_bypass : sdram_ras_n_mgmt;
assign sdram_adr_r = bypass ? sdram_adr_bypass : sdram_adr_mgmt;
assign sdram_ba_r = bypass ? sdram_ba_bypass : sdram_ba_mgmt;
wire sdram_rst;
wire [2:0] tim_rp;
wire [2:0] tim_rcd;
wire tim_cas;
wire [10:0] tim_refi;
wire [3:0] tim_rfc;
wire [1:0] tim_wr;
wire idelay_rst;
wire idelay_ce;
wire idelay_inc;
hpdmc_ctlif ctlif(
	.sys_clk(sys_clk),
	.sys_rst(sys_rst),
	.wbc_adr_i(wbc_adr_i),
	.wbc_dat_i(wbc_dat_i),
	.wbc_dat_o(wbc_dat_o),
	.wbc_sel_i(wbc_sel_i),
	.wbc_cyc_i(wbc_cyc_i),
	.wbc_stb_i(wbc_stb_i),
	.wbc_we_i(wbc_we_i),
	.wbc_ack_o(wbc_ack_o),
	.bypass(bypass),
	.sdram_rst(sdram_rst),
	.sdram_cke(sdram_cke_r),
	.sdram_cs_n(sdram_cs_n_bypass),
	.sdram_we_n(sdram_we_n_bypass),
	.sdram_cas_n(sdram_cas_n_bypass),
	.sdram_ras_n(sdram_ras_n_bypass),
	.sdram_adr(sdram_adr_bypass),
	.sdram_ba(sdram_ba_bypass),
	.tim_rp(tim_rp),
	.tim_rcd(tim_rcd),
	.tim_cas(tim_cas),
	.tim_refi(tim_refi),
	.tim_rfc(tim_rfc),
	.tim_wr(tim_wr),
	.idelay_rst(idelay_rst),
	.idelay_ce(idelay_ce),
	.idelay_inc(idelay_inc)
);
wire mgmt_stb;
wire mgmt_we;
wire [sdram_depth-3-1:0] mgmt_address;
wire mgmt_ack;
wire read;
wire write;
wire [3:0] concerned_bank;
wire read_safe;
wire write_safe;
wire [3:0] precharge_safe;
hpdmc_mgmt #(
	.sdram_depth(sdram_depth),
	.sdram_columndepth(sdram_columndepth)
) mgmt (
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.tim_rp(tim_rp),
	.tim_rcd(tim_rcd),
	.tim_refi(tim_refi),
	.tim_rfc(tim_rfc),
	.stb(mgmt_stb),
	.we(mgmt_we),
	.address(mgmt_address),
	.ack(mgmt_ack),
	.read(read),
	.write(write),
	.concerned_bank(concerned_bank),
	.read_safe(read_safe),
	.write_safe(write_safe),
	.precharge_safe(precharge_safe),
	.sdram_cs_n(sdram_cs_n_mgmt),
	.sdram_we_n(sdram_we_n_mgmt),
	.sdram_cas_n(sdram_cas_n_mgmt),
	.sdram_ras_n(sdram_ras_n_mgmt),
	.sdram_adr(sdram_adr_mgmt),
	.sdram_ba(sdram_ba_mgmt)
);
wire data_ack;
hpdmc_busif #(
	.sdram_depth(sdram_depth)
) busif (
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.fml_adr(fml_adr),
	.fml_stb(fml_stb),
	.fml_we(fml_we),
	.fml_ack(fml_ack),
	.mgmt_stb(mgmt_stb),
	.mgmt_we(mgmt_we),
	.mgmt_address(mgmt_address),
	.mgmt_ack(mgmt_ack),
	.data_ack(data_ack)
);
wire direction;
hpdmc_datactl datactl(
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.read(read),
	.write(write),
	.concerned_bank(concerned_bank),
	.read_safe(read_safe),
	.write_safe(write_safe),
	.precharge_safe(precharge_safe),
	.ack(data_ack),
	.direction(direction),
	.tim_cas(tim_cas),
	.tim_wr(tim_wr)
);
hpdmc_ddrio ddrio(
	.sys_clk(sys_clk),
	.dqs_clk(dqs_clk),
	.direction(direction),
	.mo(~fml_sel),
	.do(fml_di),
	.di(fml_do),
	.sdram_dqm(sdram_dqm),
	.sdram_dq(sdram_dq),
	.sdram_dqs(sdram_dqs),
	.idelay_rst(idelay_rst),
	.idelay_ce(idelay_ce),
	.idelay_inc(idelay_inc)
);
endmodule
module hpdmc_oddr32 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [31:0] Q,
	input C,
	input CE,
	input [31:0] D1,
	input [31:0] D2,
	input R,
	input S
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr0 (
	.Q(Q[0]),
	.C(C),
	.CE(CE),
	.D1(D1[0]),
	.D2(D2[0]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr1 (
	.Q(Q[1]),
	.C(C),
	.CE(CE),
	.D1(D1[1]),
	.D2(D2[1]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr2 (
	.Q(Q[2]),
	.C(C),
	.CE(CE),
	.D1(D1[2]),
	.D2(D2[2]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr3 (
	.Q(Q[3]),
	.C(C),
	.CE(CE),
	.D1(D1[3]),
	.D2(D2[3]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr4 (
	.Q(Q[4]),
	.C(C),
	.CE(CE),
	.D1(D1[4]),
	.D2(D2[4]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr5 (
	.Q(Q[5]),
	.C(C),
	.CE(CE),
	.D1(D1[5]),
	.D2(D2[5]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr6 (
	.Q(Q[6]),
	.C(C),
	.CE(CE),
	.D1(D1[6]),
	.D2(D2[6]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr7 (
	.Q(Q[7]),
	.C(C),
	.CE(CE),
	.D1(D1[7]),
	.D2(D2[7]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr8 (
	.Q(Q[8]),
	.C(C),
	.CE(CE),
	.D1(D1[8]),
	.D2(D2[8]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr9 (
	.Q(Q[9]),
	.C(C),
	.CE(CE),
	.D1(D1[9]),
	.D2(D2[9]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr10 (
	.Q(Q[10]),
	.C(C),
	.CE(CE),
	.D1(D1[10]),
	.D2(D2[10]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr11 (
	.Q(Q[11]),
	.C(C),
	.CE(CE),
	.D1(D1[11]),
	.D2(D2[11]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr12 (
	.Q(Q[12]),
	.C(C),
	.CE(CE),
	.D1(D1[12]),
	.D2(D2[12]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr13 (
	.Q(Q[13]),
	.C(C),
	.CE(CE),
	.D1(D1[13]),
	.D2(D2[13]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr14 (
	.Q(Q[14]),
	.C(C),
	.CE(CE),
	.D1(D1[14]),
	.D2(D2[14]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr15 (
	.Q(Q[15]),
	.C(C),
	.CE(CE),
	.D1(D1[15]),
	.D2(D2[15]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr16 (
	.Q(Q[16]),
	.C(C),
	.CE(CE),
	.D1(D1[16]),
	.D2(D2[16]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr17 (
	.Q(Q[17]),
	.C(C),
	.CE(CE),
	.D1(D1[17]),
	.D2(D2[17]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr18 (
	.Q(Q[18]),
	.C(C),
	.CE(CE),
	.D1(D1[18]),
	.D2(D2[18]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr19 (
	.Q(Q[19]),
	.C(C),
	.CE(CE),
	.D1(D1[19]),
	.D2(D2[19]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr20 (
	.Q(Q[20]),
	.C(C),
	.CE(CE),
	.D1(D1[20]),
	.D2(D2[20]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr21 (
	.Q(Q[21]),
	.C(C),
	.CE(CE),
	.D1(D1[21]),
	.D2(D2[21]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr22 (
	.Q(Q[22]),
	.C(C),
	.CE(CE),
	.D1(D1[22]),
	.D2(D2[22]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr23 (
	.Q(Q[23]),
	.C(C),
	.CE(CE),
	.D1(D1[23]),
	.D2(D2[23]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr24 (
	.Q(Q[24]),
	.C(C),
	.CE(CE),
	.D1(D1[24]),
	.D2(D2[24]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr25 (
	.Q(Q[25]),
	.C(C),
	.CE(CE),
	.D1(D1[25]),
	.D2(D2[25]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr26 (
	.Q(Q[26]),
	.C(C),
	.CE(CE),
	.D1(D1[26]),
	.D2(D2[26]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr27 (
	.Q(Q[27]),
	.C(C),
	.CE(CE),
	.D1(D1[27]),
	.D2(D2[27]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr28 (
	.Q(Q[28]),
	.C(C),
	.CE(CE),
	.D1(D1[28]),
	.D2(D2[28]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr29 (
	.Q(Q[29]),
	.C(C),
	.CE(CE),
	.D1(D1[29]),
	.D2(D2[29]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr30 (
	.Q(Q[30]),
	.C(C),
	.CE(CE),
	.D1(D1[30]),
	.D2(D2[30]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr31 (
	.Q(Q[31]),
	.C(C),
	.CE(CE),
	.D1(D1[31]),
	.D2(D2[31]),
	.R(R),
	.S(S)
);
endmodule
module hpdmc_oddr4 #(
	parameter DDR_CLK_EDGE = "SAME_EDGE",
	parameter INIT = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output [3:0] Q,
	input C,
	input CE,
	input [3:0] D1,
	input [3:0] D2,
	input R,
	input S
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr0 (
	.Q(Q[0]),
	.C(C),
	.CE(CE),
	.D1(D1[0]),
	.D2(D2[0]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr1 (
	.Q(Q[1]),
	.C(C),
	.CE(CE),
	.D1(D1[1]),
	.D2(D2[1]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr2 (
	.Q(Q[2]),
	.C(C),
	.CE(CE),
	.D1(D1[2]),
	.D2(D2[2]),
	.R(R),
	.S(S)
);
ODDR #(
	.DDR_CLK_EDGE(DDR_CLK_EDGE),
	.INIT(INIT),
	.SRTYPE(SRTYPE)
) oddr3 (
	.Q(Q[3]),
	.C(C),
	.CE(CE),
	.D1(D1[3]),
	.D2(D2[3]),
	.R(R),
	.S(S)
);
endmodule
module hpdmc_idelay8(
	input [7:0] i,
	output [7:0] o,
	input clk,
	input rst,
	input ce,
	input inc
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d0 (
	.I(i[0]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[0])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d1 (
	.I(i[1]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[1])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d2 (
	.I(i[2]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[2])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d3 (
	.I(i[3]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[3])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d4 (
	.I(i[4]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[4])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d5 (
	.I(i[5]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[5])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d6 (
	.I(i[6]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[6])
);
IDELAY #(
	.IOBDELAY_TYPE("VARIABLE"),
	.IOBDELAY_VALUE(0)
) d7 (
	.I(i[7]),
	.C(clk),
	.INC(inc),
	.CE(ce),
	.RST(rst),
	.O(o[7])
);
endmodule
module hpdmc_ctlif(
	input sys_clk,
	input sys_rst,
	input [31:0] wbc_adr_i,
	input [31:0] wbc_dat_i,
	output reg [31:0] wbc_dat_o,
	input [3:0] wbc_sel_i,
	input wbc_cyc_i,
	input wbc_stb_i,
	input wbc_we_i,
	output reg wbc_ack_o,
	output reg bypass,
	output reg sdram_rst,
	output reg sdram_cke,
	output reg sdram_cs_n,
	output reg sdram_we_n,
	output reg sdram_cas_n,
	output reg sdram_ras_n,
	output reg [12:0] sdram_adr,
	output reg [1:0] sdram_ba,
	output reg [2:0] tim_rp,
	output reg [2:0] tim_rcd,
	output reg tim_cas,
	output reg [10:0] tim_refi,
	output reg [3:0] tim_rfc,
	output reg [1:0] tim_wr,
	output reg idelay_rst,
	output reg idelay_ce,
	output reg idelay_inc
);
always @(posedge sys_clk) begin
	if(sys_rst) begin
		wbc_ack_o <= 1'b0;
		bypass <= 1'b1;
		sdram_rst <= 1'b1;
		sdram_cke <= 1'b0;
		sdram_adr <= 13'd0;
		sdram_ba <= 2'd0;
		tim_rp <= 3'd2;
		tim_rcd <= 3'd2;
		tim_cas <= 1'b0;
		tim_refi <= 11'd740;
		tim_rfc <= 4'd8;
		tim_wr <= 2'd2;
	end else begin
		if(~wbc_ack_o) begin
			if(wbc_cyc_i & wbc_stb_i) begin
				if(wbc_we_i) begin
					case(wbc_adr_i[3:2])
						2'b00: begin
							bypass <= wbc_dat_i[0];
							sdram_rst <= wbc_dat_i[1];
							sdram_cke <= wbc_dat_i[2];
						end
						2'b01: begin
							sdram_cs_n <= ~wbc_dat_i[0];
							sdram_we_n <= ~wbc_dat_i[1];
							sdram_cas_n <= ~wbc_dat_i[2];
							sdram_ras_n <= ~wbc_dat_i[3];
							sdram_adr <= wbc_dat_i[16:4];
							sdram_ba <= wbc_dat_i[18:17];
						end
						2'b10: begin
							tim_rp <= wbc_dat_i[2:0];
							tim_rcd <= wbc_dat_i[5:3];
							tim_cas <= wbc_dat_i[6];
							tim_refi <= wbc_dat_i[17:7];
							tim_rfc <= wbc_dat_i[21:18];
							tim_wr <= wbc_dat_i[23:22];
						end
						2'b11: begin
							idelay_rst <= wbc_dat_i[0];
							idelay_ce <= wbc_dat_i[1];
							idelay_inc <= wbc_dat_i[2];
						end
					endcase
				end
				wbc_ack_o <= 1'b1;
			end
		end else begin
			sdram_cs_n <= 1'b1;
			sdram_we_n <= 1'b1;
			sdram_cas_n <= 1'b1;
			sdram_ras_n <= 1'b1;
			idelay_rst <= 1'b0;
			idelay_ce <= 1'b0;
			idelay_inc <= 1'b0;
			wbc_ack_o <= 1'b0;
		end
	end
end
always @(posedge sys_clk) begin
	case(wbc_adr_i[3:2])
		2'b00: wbc_dat_o <= {sdram_cke, sdram_rst, bypass};
		2'b01: wbc_dat_o <= {sdram_ba, sdram_adr, 4'h0};
		2'b10: wbc_dat_o <= {tim_wr, tim_rfc, tim_refi, tim_cas, tim_rcd, tim_rp};
		2'b11: wbc_dat_o <= 32'd0;
	endcase
end
endmodule
module IDDR #(
	parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
	parameter INIT_Q1 = 1'b0,
	parameter INIT_Q2 = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output Q1,
	output Q2,
	input C,
	input CE,
	input D,
	input R,
	input S
);
reg q1_out = INIT_Q1, q2_out = INIT_Q2;
reg q1_out_int, q2_out_int;
reg q1_out_pipelined, q2_out_same_edge_int;
wire c_in;
wire ce_in;
wire d_in;
wire gsr_in;
wire r_in;
wire s_in;
buf buf_c(c_in, C);
buf buf_ce(ce_in, CE);
buf buf_d(d_in, D);
buf buf_q1(Q1, q1_out);
buf buf_q2(Q2, q2_out);
buf buf_r(r_in, R);
buf buf_s(s_in, S);
initial begin
	if((INIT_Q1 != 0) && (INIT_Q1 != 1)) begin
		$display("Attribute Syntax Error : The attribute INIT_Q1 on IDDR instance %m is set to %d.  Legal values for this attribute are 0 or 1.", INIT_Q1);
		$finish;
	end
	if((INIT_Q2 != 0) && (INIT_Q2 != 1)) begin
		$display("Attribute Syntax Error : The attribute INIT_Q1 on IDDR instance %m is set to %d.  Legal values for this attribute are 0 or 1.", INIT_Q2);
		$finish;
	end
	if((DDR_CLK_EDGE != "OPPOSITE_EDGE") && (DDR_CLK_EDGE != "SAME_EDGE") && (DDR_CLK_EDGE != "SAME_EDGE_PIPELINED")) begin
		$display("Attribute Syntax Error : The attribute DDR_CLK_EDGE on IDDR instance %m is set to %s.  Legal values for this attribute are OPPOSITE_EDGE, SAME_EDGE or SAME_EDGE_PIPELINED.", DDR_CLK_EDGE);
		$finish;
	end
	if((SRTYPE != "ASYNC") && (SRTYPE != "SYNC")) begin
		$display("Attribute Syntax Error : The attribute SRTYPE on IDDR instance %m is set to %s.  Legal values for this attribute are ASYNC or SYNC.", SRTYPE);
		$finish;
	end
end
always @(r_in, s_in) begin
	if(r_in == 1'b1 && SRTYPE == "ASYNC") begin
		assign q1_out_int = 1'b0;
		assign q1_out_pipelined = 1'b0;
		assign q2_out_same_edge_int = 1'b0;
		assign q2_out_int = 1'b0;
	end else if(r_in == 1'b0 && s_in == 1'b1 && SRTYPE == "ASYNC") begin
		assign q1_out_int = 1'b1;
		assign q1_out_pipelined = 1'b1;
		assign q2_out_same_edge_int = 1'b1;
		assign q2_out_int = 1'b1;
	end else if((r_in == 1'b1 || s_in == 1'b1) && SRTYPE == "SYNC") begin
		deassign q1_out_int;
		deassign q1_out_pipelined;
		deassign q2_out_same_edge_int;
		deassign q2_out_int;
	end else if(r_in == 1'b0 && s_in == 1'b0) begin
		deassign q1_out_int;
		deassign q1_out_pipelined;
		deassign q2_out_same_edge_int;
		deassign q2_out_int;
	end
end
always @(posedge c_in) begin
	if(r_in == 1'b1) begin
		q1_out_int <= 1'b0;
		q1_out_pipelined <= 1'b0;
		q2_out_same_edge_int <= 1'b0;
	end else if(r_in == 1'b0 && s_in == 1'b1) begin
		q1_out_int <= 1'b1;
		q1_out_pipelined <= 1'b1;
		q2_out_same_edge_int <= 1'b1;
	end else if(ce_in == 1'b1 && r_in == 1'b0 && s_in == 1'b0) begin
		q1_out_int <= d_in;
		q1_out_pipelined <= q1_out_int;
		q2_out_same_edge_int <= q2_out_int;
	end
end
always @(negedge c_in) begin
	if(r_in == 1'b1)
		q2_out_int <= 1'b0;
	else if(r_in == 1'b0 && s_in == 1'b1)
		q2_out_int <= 1'b1;
	else if(ce_in == 1'b1 && r_in == 1'b0 && s_in == 1'b0)
		q2_out_int <= d_in;
end
always @(c_in, q1_out_int, q2_out_int, q2_out_same_edge_int, q1_out_pipelined) begin
	case(DDR_CLK_EDGE)
		"OPPOSITE_EDGE" : begin
			q1_out <= q1_out_int;
			q2_out <= q2_out_int;
		end
		"SAME_EDGE" : begin
			q1_out <= q1_out_int;
			q2_out <= q2_out_same_edge_int;
		end
		"SAME_EDGE_PIPELINED" : begin
			q1_out <= q1_out_pipelined;
			q2_out <= q2_out_same_edge_int;
		end
		default: begin
			$display("Attribute Syntax Error : The attribute DDR_CLK_EDGE on IDDR instance %m is set to %s.  Legal values for this attribute are OPPOSITE_EDGE, SAME_EDGE or SAME_EDGE_PIPELINED.", DDR_CLK_EDGE);
			$finish;
		end
	endcase
end
endmodule
`timescale 1ns / 1ps
module ddr (Clk, Clk_n, Cke, Cs_n, Ras_n, Cas_n, We_n, Ba , Addr, Dm, Dq, Dqs);
    parameter tCK              =     7.5;  
    parameter tDQSQ            =     0.5;  
    parameter tMRD             =    15.0;  
    parameter tRAP             =    15.0;  
    parameter tRAS             =    40.0;  
    parameter tRC              =    60.0;  
    parameter tRFC             =    75.0;  
    parameter tRCD             =    15.0;  
    parameter tRP              =    15.0;  
    parameter tRRD             =    15.0;  
    parameter tWR              =    15.0;  
    parameter ADDR_BITS        =      13;  
    parameter DQ_BITS          =      16;  
    parameter DQS_BITS         =       2;  
    parameter DM_BITS          =       2;  
    parameter COL_BITS         =       9;  
    parameter BA_BITS          =       2;  
    parameter full_mem_bits    = BA_BITS+ADDR_BITS+COL_BITS;  
    parameter part_mem_bits    = 10;                    
    parameter no_halt          =       0;  
    parameter DEBUG            =       1;  
    input                         Clk;
    input                         Clk_n;
    input                         Cke;
    input                         Cs_n;
    input                         Ras_n;
    input                         Cas_n;
    input                         We_n;
    input                 [1 : 0] Ba;
    input     [ADDR_BITS - 1 : 0] Addr;
    input       [DM_BITS - 1 : 0] Dm;
    inout       [DQ_BITS - 1 : 0] Dq;
    inout      [DQS_BITS - 1 : 0] Dqs;
    wire                 [31 : 0] Dq_in;
    wire                  [3 : 0] Dqs_in;
    wire                  [3 : 0] Dm_in;
    assign Dq_in   [DQ_BITS - 1 : 0] = Dq;
    assign Dqs_in [DQS_BITS - 1 : 0] = Dqs;
    assign Dm_in   [DM_BITS - 1 : 0] = Dm;
    reg                  [31 : 0] dq_rise;
    reg                   [3 : 0] dm_rise;
    reg                  [31 : 0] dq_fall;
    reg                   [3 : 0] dm_fall;
    reg                   [7 : 0] dm_pair;
    reg                  [31 : 0] Dq_buf;
    reg       [ADDR_BITS - 1 : 0] Mode_reg;
    reg                           CkeZ, Sys_clk;
    reg                           Dqs_int;
    reg        [DQS_BITS - 1 : 0] Dqs_out;
    reg         [DQ_BITS - 1 : 0] Dq_out;
    reg                           Read_cmnd [0 : 6];
    reg                   [1 : 0] Read_bank [0 : 6];
    reg        [COL_BITS - 1 : 0] Read_cols [0 : 6];
    reg                           Write_cmnd [0 : 3];
    reg                   [1 : 0] Write_bank [0 : 3];
    reg        [COL_BITS - 1 : 0] Write_cols [0 : 3];
    reg                           Read_precharge  [0 : 3];
    reg                           Write_precharge [0 : 3];
    integer                       Count_precharge [0 : 3];
    reg                           A10_precharge  [0 : 6];
    reg                   [1 : 0] Bank_precharge [0 : 6];
    reg                           Cmnd_precharge [0 : 6];
    reg                           Cmnd_bst [0 : 6];
    reg         [DQ_BITS - 1 : 0] mem_array  [0 : (1<<full_mem_bits)-1];
    integer i;
    reg  [3 :0] expect_pos_dqs;
    reg  [3 :0] expect_neg_dqs;
    reg        [COL_BITS - 1 : 0] Burst_counter;
    reg                           Pc_b0, Pc_b1, Pc_b2, Pc_b3;
    reg                           Act_b0, Act_b1, Act_b2, Act_b3;
    reg                           Data_in_enable;
    reg                           Data_out_enable;
    reg                   [1 : 0] Prev_bank;
    reg                   [1 : 0] Bank_addr;
    reg        [COL_BITS - 1 : 0] Cols_addr, Cols_brst, Cols_temp;
    reg       [ADDR_BITS - 1 : 0] Rows_addr;
    reg       [ADDR_BITS - 1 : 0] B0_row_addr;
    reg       [ADDR_BITS - 1 : 0] B1_row_addr;
    reg       [ADDR_BITS - 1 : 0] B2_row_addr;
    reg       [ADDR_BITS - 1 : 0] B3_row_addr;
    reg                           DLL_enable;
    reg                           DLL_reset;
    reg                           DLL_done;
    integer                       DLL_count;
    integer                       aref_count;
    integer                       Prech_count;
    reg                           power_up_done;
    wire      wdqs_valid = Write_cmnd[2] || Write_cmnd[1] || Data_in_enable;
    wire      Active_enable   = ~Cs_n & ~Ras_n &  Cas_n &  We_n;
    wire      Aref_enable     = ~Cs_n & ~Ras_n & ~Cas_n &  We_n;
    wire      Burst_term      = ~Cs_n &  Ras_n &  Cas_n & ~We_n;
    wire      Ext_mode_enable = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n &  Ba[0] & ~Ba[1];
    wire      Mode_reg_enable = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n & ~Ba[0] & ~Ba[1];
    wire      Prech_enable    = ~Cs_n & ~Ras_n &  Cas_n & ~We_n;
    wire      Read_enable     = ~Cs_n &  Ras_n & ~Cas_n &  We_n;
    wire      Write_enable    = ~Cs_n &  Ras_n & ~Cas_n & ~We_n;
    wire [3:0] burst_length = 1 << (Mode_reg[2:0]);
    reg  [3:0] read_precharge_truncation;
    wire [2:0] cas_latency_x2 = (Mode_reg[6:4] === 3'o6) ? 5 : 2*Mode_reg[6:4];
    assign    Dqs = Dqs_out;
    assign    Dq  = Dq_out;
    time      MRD_chk;
    time      RFC_chk;
    time      RRD_chk;
    time      RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3;
    time      RAP_chk0, RAP_chk1, RAP_chk2, RAP_chk3;
    time      RC_chk0, RC_chk1, RC_chk2, RC_chk3;
    time      RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3;
    time      RP_chk0, RP_chk1, RP_chk2, RP_chk3;
    time      WR_chk0, WR_chk1, WR_chk2, WR_chk3;
    initial begin
        CkeZ = 1'b0;
        Sys_clk = 1'b0;
        {Pc_b0, Pc_b1, Pc_b2, Pc_b3} = 4'b0000;
        {Act_b0, Act_b1, Act_b2, Act_b3} = 4'b1111;
        Dqs_int = 1'b0;
        Dqs_out = {DQS_BITS{1'bz}};
        Dq_out = {DQ_BITS{1'bz}};
        Data_in_enable = 1'b0;
        Data_out_enable = 1'b0;
        DLL_enable = 1'b0;
        DLL_reset = 1'b0;
        DLL_done = 1'b0;
        DLL_count = 0;
        aref_count = 0;
        Prech_count = 0;
        power_up_done = 0;
        MRD_chk = 0;
        RFC_chk = 0;
        RRD_chk = 0;
        Mode_reg = 0;  
        {RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3} = 0;
        {RAP_chk0, RAP_chk1, RAP_chk2, RAP_chk3} = 0;
        {RC_chk0, RC_chk1, RC_chk2, RC_chk3} = 0;
        {RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3} = 0;
        {RP_chk0, RP_chk1, RP_chk2, RP_chk3} = 0;
        {WR_chk0, WR_chk1, WR_chk2, WR_chk3} = 0;
        $timeformat (-9, 3, " ns", 12);
    end
    always begin
        @ (posedge Clk) begin
            Sys_clk = CkeZ;
            CkeZ = Cke;
        end
        @ (negedge Clk) begin
            Sys_clk = 1'b0;
        end
    end
    always @(Cke) begin
        if (Cke === 1'b1) begin
            if (!((Cs_n) || (~Cs_n &  Ras_n & Cas_n &  We_n))) begin
                $display ("%m: at time %t MEMORY ERROR:  You must have a Deselect or NOP command applied", $time);
                $display ("%m:           when the Clock Enable is brought High.");
            end 
        end
    end
    initial begin
        @ (posedge Cke) begin
            @ (posedge DLL_enable) begin
                aref_count = 0;
                @ (posedge DLL_reset) begin
                    @ (Prech_count) begin
                        if (aref_count >= 2) begin
                            if (DEBUG) $display ("%m: at time %t MEMORY:  Power Up and Initialization Sequence is complete", $time);
                            power_up_done = 1;
                        end else begin
                            aref_count = 0;
                            @ (aref_count >= 2) begin
                                if (DEBUG) $display ("%m: at time %t MEMORY:  Power Up and Initialization Sequence is complete", $time);
                                power_up_done = 1;
                            end
                        end
                    end
                end
            end
        end
    end
    task write_mem;
        input [full_mem_bits - 1 : 0] addr;
        input       [DQ_BITS - 1 : 0] data;
        reg       [part_mem_bits : 0] i;
        begin
            mem_array[addr] = data;
        end
    endtask
    task read_mem;
        input [full_mem_bits - 1 : 0] addr;
        output      [DQ_BITS - 1 : 0] data;
        reg       [part_mem_bits : 0] i;
        begin
            data = mem_array[addr];
        end
    endtask
    task Burst_Decode;
    begin
        if (Burst_counter < burst_length) begin
            Burst_counter = Burst_counter + 1;
        end
        if (Mode_reg[3] === 1'b0) begin                          
            Cols_temp = Cols_addr + 1;
        end else if (Mode_reg[3] === 1'b1) begin                 
            Cols_temp[2] =  Burst_counter[2] ^ Cols_brst[2];
            Cols_temp[1] =  Burst_counter[1] ^ Cols_brst[1];
            Cols_temp[0] =  Burst_counter[0] ^ Cols_brst[0];
        end
        if (burst_length === 2) begin
            Cols_addr [0] = Cols_temp [0];
        end else if (burst_length === 4) begin
            Cols_addr [1 : 0] = Cols_temp [1 : 0];
        end else if (burst_length === 8) begin
            Cols_addr [2 : 0] = Cols_temp [2 : 0];
        end else begin
            Cols_addr = Cols_temp;
        end
        if (Burst_counter >= burst_length) begin
            Data_in_enable = 1'b0;
            Data_out_enable = 1'b0;
            read_precharge_truncation = 4'h0;
        end
    end
    endtask
    task Manual_Precharge_Pipeline;
    begin
        A10_precharge[0] = A10_precharge[1];
        A10_precharge[1] = A10_precharge[2];
        A10_precharge[2] = A10_precharge[3];
        A10_precharge[3] = A10_precharge[4];
        A10_precharge[4] = A10_precharge[5];
        A10_precharge[5] = A10_precharge[6];
        A10_precharge[6] = 1'b0;
        Bank_precharge[0] = Bank_precharge[1];
        Bank_precharge[1] = Bank_precharge[2];
        Bank_precharge[2] = Bank_precharge[3];
        Bank_precharge[3] = Bank_precharge[4];
        Bank_precharge[4] = Bank_precharge[5];
        Bank_precharge[5] = Bank_precharge[6];
        Bank_precharge[6] = 2'b0;
        Cmnd_precharge[0] = Cmnd_precharge[1];
        Cmnd_precharge[1] = Cmnd_precharge[2];
        Cmnd_precharge[2] = Cmnd_precharge[3];
        Cmnd_precharge[3] = Cmnd_precharge[4];
        Cmnd_precharge[4] = Cmnd_precharge[5];
        Cmnd_precharge[5] = Cmnd_precharge[6];
        Cmnd_precharge[6] = 1'b0;
        if (Cmnd_precharge[0] === 1'b1) begin
            if (Bank_precharge[0] === Bank_addr || A10_precharge[0] === 1'b1) begin
                if (Data_out_enable === 1'b1) begin
                    Data_out_enable = 1'b0;
                    read_precharge_truncation = 4'hF;
                end
            end
        end
    end
    endtask
    task Burst_Terminate_Pipeline;
    begin
        Cmnd_bst[0] = Cmnd_bst[1];
        Cmnd_bst[1] = Cmnd_bst[2];
        Cmnd_bst[2] = Cmnd_bst[3];
        Cmnd_bst[3] = Cmnd_bst[4];
        Cmnd_bst[4] = Cmnd_bst[5];
        Cmnd_bst[5] = Cmnd_bst[6];
        Cmnd_bst[6] = 1'b0;
        if (Cmnd_bst[0] === 1'b1 && Data_out_enable === 1'b1) begin
            Data_out_enable = 1'b0;
        end
    end
    endtask
    task Dq_Dqs_Drivers;
    begin
        Read_cmnd [0] = Read_cmnd [1];
        Read_cmnd [1] = Read_cmnd [2];
        Read_cmnd [2] = Read_cmnd [3];
        Read_cmnd [3] = Read_cmnd [4];
        Read_cmnd [4] = Read_cmnd [5];
        Read_cmnd [5] = Read_cmnd [6];
        Read_cmnd [6] = 1'b0;
        Read_bank [0] = Read_bank [1];
        Read_bank [1] = Read_bank [2];
        Read_bank [2] = Read_bank [3];
        Read_bank [3] = Read_bank [4];
        Read_bank [4] = Read_bank [5];
        Read_bank [5] = Read_bank [6];
        Read_bank [6] = 2'b0;
        Read_cols [0] = Read_cols [1];
        Read_cols [1] = Read_cols [2];
        Read_cols [2] = Read_cols [3];
        Read_cols [3] = Read_cols [4];
        Read_cols [4] = Read_cols [5];
        Read_cols [5] = Read_cols [6];
        Read_cols [6] = 0;
        if (Read_cmnd [0] === 1'b1) begin
            Data_out_enable = 1'b1;
            Bank_addr = Read_bank [0];
            Cols_addr = Read_cols [0];
            Cols_brst = Cols_addr [2 : 0];
            Burst_counter = 0;
            case (Bank_addr)
                2'd0    : Rows_addr = B0_row_addr;
                2'd1    : Rows_addr = B1_row_addr;
                2'd2    : Rows_addr = B2_row_addr;
                2'd3    : Rows_addr = B3_row_addr;
                default : $display ("%m: At time %t ERROR: Invalid Bank Address", $time);
            endcase
        end
        if (Data_out_enable === 1'b1) begin
            Dqs_int = 1'b0;
            if (Dqs_out === {DQS_BITS{1'b0}}) begin
                Dqs_out = {DQS_BITS{1'b1}};
            end else if (Dqs_out === {DQS_BITS{1'b1}}) begin
                Dqs_out = {DQS_BITS{1'b0}};
            end else begin
                Dqs_out = {DQS_BITS{1'b0}};
            end
        end else if (Data_out_enable === 1'b0 && Dqs_int === 1'b0) begin
            Dqs_out = {DQS_BITS{1'bz}};
        end
        if (Read_cmnd [2] === 1'b1) begin
            if (Data_out_enable === 1'b0) begin
                Dqs_int = 1'b1;
                Dqs_out = {DQS_BITS{1'b0}};
            end
        end
        if (Data_out_enable === 1'b1) begin
            read_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_out);
            if (DEBUG) begin
                $display ("%m: At time %t READ : Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_out);
            end
        end else begin
            Dq_out = {DQ_BITS{1'bz}};
        end
    end
    endtask
    task Write_FIFO_DM_Mask_Logic;
    begin
        Write_cmnd [0] = Write_cmnd [1];
        Write_cmnd [1] = Write_cmnd [2];
        Write_cmnd [2] = Write_cmnd [3];
        Write_cmnd [3] = 1'b0;
        Write_bank [0] = Write_bank [1];
        Write_bank [1] = Write_bank [2];
        Write_bank [2] = Write_bank [3];
        Write_bank [3] = 2'b0;
        Write_cols [0] = Write_cols [1];
        Write_cols [1] = Write_cols [2];
        Write_cols [2] = Write_cols [3];
        Write_cols [3] = {COL_BITS{1'b0}};
        if (Write_cmnd [0] === 1'b1) begin
            Data_in_enable = 1'b1;
            Bank_addr = Write_bank [0];
            Cols_addr = Write_cols [0];
            Cols_brst = Cols_addr [2 : 0];
            Burst_counter = 0;
            case (Bank_addr)
                2'd0    : Rows_addr = B0_row_addr;
                2'd1    : Rows_addr = B1_row_addr;
                2'd2    : Rows_addr = B2_row_addr;
                2'd3    : Rows_addr = B3_row_addr;
                default : $display ("%m: At time %t ERROR: Invalid Row Address", $time);
            endcase
        end
        if (Data_in_enable === 1'b1) begin
            read_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_buf);
            if (Sys_clk) begin
                if (!dm_fall[0]) begin
                    Dq_buf [ 7 : 0] = dq_fall [ 7 : 0];
                end
                if (!dm_fall[1]) begin
                    Dq_buf [15 : 8] = dq_fall [15 : 8];
                end
                if (!dm_fall[2]) begin
                    Dq_buf [23 : 16] = dq_fall [23 : 16];
                end
                if (!dm_fall[3]) begin
                    Dq_buf [31 : 24] = dq_fall [31 : 24];
                end
                if (~&dm_fall) begin
                    if (DEBUG) begin
                        $display ("%m: At time %t WRITE: Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_buf[DQ_BITS-1:0]);
                    end
                end
            end else begin
                if (!dm_rise[0]) begin
                    Dq_buf [ 7 : 0] = dq_rise [ 7 : 0];
                end
                if (!dm_rise[1]) begin
                    Dq_buf [15 : 8] = dq_rise [15 : 8];
                end
                if (!dm_rise[2]) begin
                    Dq_buf [23 : 16] = dq_rise [23 : 16];
                end
                if (!dm_rise[3]) begin
                    Dq_buf [31 : 24] = dq_rise [31 : 24];
                end
                if (~&dm_rise) begin
                    if (DEBUG) begin
                        $display ("%m: At time %t WRITE: Bank = %h, Row = %h, Col = %h, Data = %h", $time, Bank_addr, Rows_addr, Cols_addr, Dq_buf[DQ_BITS-1:0]);
                    end
                end
            end
            write_mem({Bank_addr, Rows_addr, Cols_addr}, Dq_buf);
            if (Sys_clk && &dm_pair === 1'b0)  begin
                case (Bank_addr)
                    2'd0    : WR_chk0 = $time;
                    2'd1    : WR_chk1 = $time;
                    2'd2    : WR_chk2 = $time;
                    2'd3    : WR_chk3 = $time;
                    default : $display ("%m: At time %t ERROR: Invalid Bank Address (tWR)", $time);
                endcase
                if (Read_enable === 1'b1) begin
                    $display ("%m: At time %t ERROR: tWTR violation during Read", $time);
                end
            end
        end
    end
    endtask
    task Auto_Precharge_Calculation;
    begin
        if (Read_precharge [0] === 1'b1 || Write_precharge [0] === 1'b1) begin
            Count_precharge [0] = Count_precharge [0] + 1;
        end
        if (Read_precharge [1] === 1'b1 || Write_precharge [1] === 1'b1) begin
            Count_precharge [1] = Count_precharge [1] + 1;
        end
        if (Read_precharge [2] === 1'b1 || Write_precharge [2] === 1'b1) begin
            Count_precharge [2] = Count_precharge [2] + 1;
        end
        if (Read_precharge [3] === 1'b1 || Write_precharge [3] === 1'b1) begin
            Count_precharge [3] = Count_precharge [3] + 1;
        end
        if ((Read_precharge[0] === 1'b1) && ($time - RAS_chk0 >= tRAS)) begin
            if (Count_precharge[0] >= burst_length/2) begin
                Pc_b0 = 1'b1;
                Act_b0 = 1'b0;
                RP_chk0 = $time;
                Read_precharge[0] = 1'b0;
            end
        end
        if ((Read_precharge[1] === 1'b1) && ($time - RAS_chk1 >= tRAS)) begin
            if (Count_precharge[1] >= burst_length/2) begin
                Pc_b1 = 1'b1;
                Act_b1 = 1'b0;
                RP_chk1 = $time;
                Read_precharge[1] = 1'b0;
            end
        end
        if ((Read_precharge[2] === 1'b1) && ($time - RAS_chk2 >= tRAS)) begin
            if (Count_precharge[2] >= burst_length/2) begin
                Pc_b2 = 1'b1;
                Act_b2 = 1'b0;
                RP_chk2 = $time;
                Read_precharge[2] = 1'b0;
            end
        end
        if ((Read_precharge[3] === 1'b1) && ($time - RAS_chk3 >= tRAS)) begin
            if (Count_precharge[3] >= burst_length/2) begin
                Pc_b3 = 1'b1;
                Act_b3 = 1'b0;
                RP_chk3 = $time;
                Read_precharge[3] = 1'b0;
            end
        end
        if ((Write_precharge[0] === 1'b1) && ($time - RAS_chk0 >= tRAS)) begin 
            if ((Count_precharge[0] >= burst_length/2+1) && ($time - WR_chk0 >= tWR)) begin
                Pc_b0 = 1'b1;
                Act_b0 = 1'b0;
                RP_chk0 = $time;
                Write_precharge[0] = 1'b0;
            end
        end
        if ((Write_precharge[1] === 1'b1) && ($time - RAS_chk1 >= tRAS)) begin 
            if ((Count_precharge[1] >= burst_length/2+1) && ($time - WR_chk1 >= tWR)) begin
                Pc_b1 = 1'b1;
                Act_b1 = 1'b0;
                RP_chk1 = $time;
                Write_precharge[1] = 1'b0;
            end
        end
        if ((Write_precharge[2] === 1'b1) && ($time - RAS_chk2 >= tRAS)) begin 
            if ((Count_precharge[2] >= burst_length/2+1) && ($time - WR_chk2 >= tWR)) begin
                Pc_b2 = 1'b1;
                Act_b2 = 1'b0;
                RP_chk2 = $time;
                Write_precharge[2] = 1'b0;
            end
        end
        if ((Write_precharge[3] === 1'b1) && ($time - RAS_chk3 >= tRAS)) begin 
            if ((Count_precharge[3] >= burst_length/2+1) && ($time - WR_chk3 >= tWR)) begin
                Pc_b3 = 1'b1;
                Act_b3 = 1'b0;
                RP_chk3 = $time;
                Write_precharge[3] = 1'b0;
            end
        end
    end
    endtask
    task DLL_Counter;
    begin
        if (DLL_reset === 1'b1 && DLL_done === 1'b0) begin
            DLL_count = DLL_count + 1;
            if (DLL_count >= 200) begin
                DLL_done = 1'b1;
            end
        end
    end
    endtask
    task Control_Logic;
    begin
        if (Aref_enable === 1'b1) begin
            if (DEBUG) begin
                $display ("%m: At time %t AREF : Auto Refresh", $time);
            end
            if (($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) ||
                ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP)) begin
                $display ("%m: At time %t ERROR: tRP violation during Auto Refresh", $time);
            end
            if ($time - MRD_chk < tMRD) begin
                $display ("%m: At time %t ERROR: tMRD violation during Auto Refresh", $time);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%m: At time %t ERROR: tRFC violation during Auto Refresh", $time);
            end
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) begin
                $display ("%m: At time %t ERROR: All banks must be Precharged before Auto Refresh", $time);
                if (!no_halt) $stop (0);
            end else begin
                aref_count = aref_count + 1;
                RFC_chk = $time;
            end
        end
        if (Ext_mode_enable === 1'b1) begin
            if (DEBUG) begin
                $display ("%m: At time %t EMR  : Extended Mode Register", $time);
            end
            if (($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) ||
                ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP)) begin
                $display ("%m: At time %t ERROR: tRP violation during Extended Mode Register", $time);
            end
            if ($time - MRD_chk < tMRD) begin
                $display ("%m: At time %t ERROR: tMRD violation during Extended Mode Register", $time);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%m: At time %t ERROR: tRFC violation during Extended Mode Register", $time);
            end
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) begin
                $display ("%m: At time %t ERROR: all banks must be Precharged before Extended Mode Register", $time);
                if (!no_halt) $stop (0);
            end else begin
                if (Addr[0] === 1'b0) begin
                    DLL_enable = 1'b1;
                    if (DEBUG) begin
                        $display ("%m: At time %t EMR  : Enable DLL", $time);
                    end
                end else begin
                    DLL_enable = 1'b0;
                    if (DEBUG) begin
                        $display ("%m: At time %t EMR  : Disable DLL", $time);
                    end
                end
                MRD_chk = $time;
            end
        end
        if (Mode_reg_enable === 1'b1) begin
            if (DEBUG) begin
                $display ("%m: At time %t LMR  : Load Mode Register", $time);
            end
            if (($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) ||
                ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP)) begin
                $display ("%m: At time %t ERROR: tRP violation during Load Mode Register", $time);
            end
            if ($time - MRD_chk < tMRD) begin
                $display ("%m: At time %t ERROR: tMRD violation during Load Mode Register", $time);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%m: At time %t ERROR: tRFC violation during Load Mode Register", $time);
            end
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) begin
                $display ("%m: At time %t ERROR: all banks must be Precharged before Load Mode Register", $time);
            end else begin
                Mode_reg = Addr;
                if (DLL_enable === 1'b1 && Addr [8] === 1'b1) begin
                    DLL_reset = 1'b1;
                    DLL_done = 1'b0;
                    DLL_count = 0;
                end else if (DLL_enable === 1'b1 && DLL_reset === 1'b0 && Addr [8] === 1'b0) begin
                    $display ("%m: At time %t ERROR: DLL is ENABLE: DLL RESET is required.", $time);
                end else if (DLL_enable === 1'b0 && Addr [8] === 1'b1) begin
                    $display ("%m: At time %t ERROR: DLL is DISABLE: DLL RESET will be ignored.", $time);
                end
                case (Addr [2 : 0])
                    3'b001  : $display ("%m: At time %t LMR  : Burst Length = 2", $time); 
                    3'b010  : $display ("%m: At time %t LMR  : Burst Length = 4", $time);
                    3'b011  : $display ("%m: At time %t LMR  : Burst Length = 8", $time);
                    default : $display ("%m: At time %t ERROR: Burst Length not supported", $time);
                endcase
                case (Addr [6 : 4])
                    3'b010  : $display ("%m: At time %t LMR  : CAS Latency = 2", $time);
                    3'b110  : $display ("%m: At time %t LMR  : CAS Latency = 2.5", $time);
                    3'b011  : $display ("%m: At time %t LMR  : CAS Latency = 3", $time);
                    default : $display ("%m: At time %t ERROR: CAS Latency not supported", $time);
                endcase
                MRD_chk = $time;
            end
        end
        if (Active_enable === 1'b1) begin
            if (!(power_up_done)) begin
                $display ("%m: %m: at time %t ERROR: Power Up and Initialization Sequence not completed before executing Activate command", $time);
            end
            if (DEBUG) begin
                $display ("%m: At time %t ACT  : Bank = %h, Row = %h", $time, Ba, Addr);
            end
            if ((Prev_bank != Ba) && ($time - RRD_chk < tRRD)) begin
                $display ("%m: At time %t ERROR: tRRD violation during Activate bank %h", $time, Ba);
            end
            if ($time - MRD_chk < tMRD) begin
                $display ("%m: At time %t ERROR: tMRD violation during Activate bank %h", $time, Ba);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%m: At time %t ERROR: tRFC violation during Activate bank %h", $time, Ba);
            end
            if ((Ba === 2'b00 && Pc_b0  === 1'b0) || (Ba === 2'b01 && Pc_b1  === 1'b0) ||
                (Ba === 2'b10 && Pc_b2  === 1'b0) || (Ba === 2'b11 && Pc_b3  === 1'b0)) begin
                $display ("%m: At time %t ERROR: Bank = %h is already activated - Command Ignored", $time, Ba);
                if (!no_halt) $stop (0);
            end else begin
                if (Ba === 2'b00 && Pc_b0 === 1'b1) begin
                    if ($time - RC_chk0 < tRC) begin
                        $display ("%m: At time %t ERROR: tRC violation during Activate bank %h", $time, Ba);
                    end
                    if ($time - RP_chk0 < tRP) begin
                        $display ("%m: At time %t ERROR: tRP violation during Activate bank %h", $time, Ba);
                    end
                    Act_b0 = 1'b1;
                    Pc_b0 = 1'b0;
                    B0_row_addr = Addr;
                    RC_chk0  = $time;
                    RCD_chk0 = $time;
                    RAS_chk0 = $time;
                    RAP_chk0 = $time;
                end
                if (Ba === 2'b01 && Pc_b1 === 1'b1) begin
                    if ($time - RC_chk1 < tRC) begin
                        $display ("%m: At time %t ERROR: tRC violation during Activate bank %h", $time, Ba);
                    end
                    if ($time - RP_chk1 < tRP) begin
                        $display ("%m: At time %t ERROR: tRP violation during Activate bank %h", $time, Ba);
                    end
                    Act_b1 = 1'b1;
                    Pc_b1 = 1'b0;
                    B1_row_addr = Addr;
                    RC_chk1  = $time;
                    RCD_chk1 = $time;
                    RAS_chk1 = $time;
                    RAP_chk1 = $time;
                end
                if (Ba === 2'b10 && Pc_b2 === 1'b1) begin
                    if ($time - RC_chk2 < tRC) begin
                        $display ("%m: At time %t ERROR: tRC violation during Activate bank %h", $time, Ba);
                    end
                    if ($time - RP_chk2 < tRP) begin
                        $display ("%m: At time %t ERROR: tRP violation during Activate bank %h", $time, Ba);
                    end
                    Act_b2 = 1'b1;
                    Pc_b2 = 1'b0;
                    B2_row_addr = Addr;
                    RC_chk2  = $time;
                    RCD_chk2 = $time;
                    RAS_chk2 = $time;
                    RAP_chk2 = $time;
                end
                if (Ba === 2'b11 && Pc_b3 === 1'b1) begin
                    if ($time - RC_chk3 < tRC) begin
                        $display ("%m: At time %t ERROR: tRC violation during Activate bank %h", $time, Ba);
                    end
                    if ($time - RP_chk3 < tRP) begin
                        $display ("%m: At time %t ERROR: tRP violation during Activate bank %h", $time, Ba);
                    end
                    Act_b3 = 1'b1;
                    Pc_b3 = 1'b0;
                    B3_row_addr = Addr;
                    RC_chk3  = $time;
                    RCD_chk3 = $time;
                    RAS_chk3 = $time;
                    RAP_chk3 = $time;
                end
                RRD_chk = $time;
                Prev_bank = Ba;
                read_precharge_truncation[Ba] = 1'b0;
            end
        end
        if (Prech_enable === 1'b1) begin
            if (DEBUG) begin
                $display ("%m: At time %t PRE  : Addr[10] = %b, Bank = %b", $time, Addr[10], Ba);
            end
            if ($time - MRD_chk < tMRD) begin
                $display ("%m: At time %t ERROR: tMRD violation during Precharge", $time);
                if (!no_halt) $stop (0);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%m: At time %t ERROR: tRFC violation during Precharge", $time);
                if (!no_halt) $stop (0);
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b00)) && Act_b0 === 1'b1) begin
                Act_b0 = 1'b0;
                Pc_b0 = 1'b1;
                RP_chk0 = $time;
                if ($time - RAS_chk0 < tRAS) begin
                    $display ("%m: At time %t ERROR: tRAS violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
                if ($time - WR_chk0 < tWR) begin
                    $display ("%m: At time %t ERROR: tWR violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b01)) && Act_b1 === 1'b1) begin
                Act_b1 = 1'b0;
                Pc_b1 = 1'b1;
                RP_chk1 = $time;
                if ($time - RAS_chk1 < tRAS) begin
                    $display ("%m: At time %t ERROR: tRAS violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
                if ($time - WR_chk1 < tWR) begin
                    $display ("%m: At time %t ERROR: tWR violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b10)) && Act_b2 === 1'b1) begin
                Act_b2 = 1'b0;
                Pc_b2 = 1'b1;
                RP_chk2 = $time;
                if ($time - RAS_chk2 < tRAS) begin
                    $display ("%m: At time %t ERROR: tRAS violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
                if ($time - WR_chk2 < tWR) begin
                    $display ("%m: At time %t ERROR: tWR violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b11)) && Act_b3 === 1'b1) begin
                Act_b3 = 1'b0;
                Pc_b3 = 1'b1;
                RP_chk3 = $time;
                if ($time - RAS_chk3 < tRAS) begin
                    $display ("%m: At time %t ERROR: tRAS violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
                if ($time - WR_chk3 < tWR) begin
                    $display ("%m: At time %t ERROR: tWR violation during Precharge", $time);
                    if (!no_halt) $stop (0);
                end
            end
            Prech_count = Prech_count + 1;
            A10_precharge [cas_latency_x2] = Addr[10];
            Bank_precharge[cas_latency_x2] = Ba;
            Cmnd_precharge[cas_latency_x2] = 1'b1;
        end
        if (Burst_term === 1'b1) begin
            if (DEBUG) begin
                $display ("%m: At time %t BST  : Burst Terminate",$time);
            end
            if (Data_in_enable === 1'b1) begin
                $display ("%m: At time %t ERROR: It's illegal to burst terminate a Write", $time);
                if (!no_halt) $stop (0);
            end else if (Read_precharge[0] === 1'b1 || Read_precharge[1] === 1'b1 ||
                Read_precharge[2] === 1'b1 || Read_precharge[3] === 1'b1) begin
                $display ("%m: At time %t ERROR: It's illegal to burst terminate a Read with Auto Precharge", $time);
                if (!no_halt) $stop (0);
            end else begin
                Cmnd_bst[cas_latency_x2] = 1'b1;
            end
        end
        if (Read_enable === 1'b1) begin
            if (!(power_up_done)) begin
                $display ("%m: at time %t ERROR: Power Up and Initialization Sequence not completed before executing Read Command", $time);
            end
            if (DLL_reset === 1 && DLL_done === 0) begin
                $display ("%m: at time %t ERROR: You need to wait 200 tCK after DLL Reset Enable to Read, Not %0d clocks.", $time, DLL_count);
            end
            if (DEBUG) begin
                $display ("%m: At time %t READ : Bank = %h, Col = %h", $time, Ba, {Addr [11], Addr [9 : 0]});
            end
            if (Data_in_enable === 1'b1) begin
                Data_in_enable = 1'b0;
            end
            if ((Addr [10] === 1'b0 && Ba === 2'b00 && $time - RCD_chk0 < tRCD) ||
                (Addr [10] === 1'b0 && Ba === 2'b01 && $time - RCD_chk1 < tRCD) ||
                (Addr [10] === 1'b0 && Ba === 2'b10 && $time - RCD_chk2 < tRCD) ||
                (Addr [10] === 1'b0 && Ba === 2'b11 && $time - RCD_chk3 < tRCD)) begin
                $display("%m: At time %t ERROR: tRCD violation during Read", $time);
            end
            if ((Addr [10] === 1'b1 && Ba === 2'b00 && $time - RAP_chk0 < tRAP) ||
                (Addr [10] === 1'b1 && Ba === 2'b01 && $time - RAP_chk1 < tRAP) ||
                (Addr [10] === 1'b1 && Ba === 2'b10 && $time - RAP_chk2 < tRAP) ||
                (Addr [10] === 1'b1 && Ba === 2'b11 && $time - RAP_chk3 < tRAP)) begin
                $display ("%m: At time %t ERROR: tRAP violation during Read", $time);
            end
            if (Read_precharge [Ba] === 1'b1) begin
                $display ("%m: At time %t ERROR: It's illegal to interrupt a Read with Auto Precharge", $time);
                if (!no_halt) $stop (0);
                if (Addr[10] === 1'b0) begin
                    Read_precharge [Ba]= 1'b0;
                end
            end
            if ((Ba === 2'b00 && Pc_b0 === 1'b1) || (Ba === 2'b01 && Pc_b1 === 1'b1) ||
                (Ba === 2'b10 && Pc_b2 === 1'b1) || (Ba === 2'b11 && Pc_b3 === 1'b1)) begin
                $display("%m: At time %t ERROR: Bank is not Activated for Read", $time);
                if (!no_halt) $stop (0);
            end else begin
                Read_cmnd[cas_latency_x2] = 1'b1;
                Read_bank[cas_latency_x2] = Ba;
                Read_cols[cas_latency_x2] = {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]};
                if (Addr[10] === 1'b1) begin
                    Read_precharge [Ba]= 1'b1;
                    Count_precharge [Ba]= 0;
                end
            end
        end
        if (Write_enable === 1'b1) begin
            if (!(power_up_done)) begin
                $display ("%m: at time %t ERROR: Power Up and Initialization Sequence not completed before executing Write Command", $time);
                if (!no_halt) $stop (0);
            end
            if (DEBUG) begin
                $display ("At time %t WRITE: Bank = %h, Col = %h", $time, Ba, {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]});
            end
            if ((Ba === 2'b00 && $time - RCD_chk0 < tRCD) ||
                (Ba === 2'b01 && $time - RCD_chk1 < tRCD) ||
                (Ba === 2'b10 && $time - RCD_chk2 < tRCD) ||
                (Ba === 2'b11 && $time - RCD_chk3 < tRCD)) begin
                $display("%m: At time %t ERROR: tRCD violation during Write to Bank %h", $time, Ba);
            end
            if (Read_cmnd[0] || Read_cmnd[1] || Read_cmnd[2] || Read_cmnd[3] || 
                Read_cmnd[4] || Read_cmnd[5] || Read_cmnd[6] || (Burst_counter < burst_length)) begin
                if (Data_out_enable || read_precharge_truncation[Ba]) begin
                    $display("%m: At time %t ERROR: Read to Write violation", $time);
                end
            end
            if (Write_precharge [Ba] === 1'b1) begin
                $display ("At time %t ERROR: it's illegal to interrupt a Write with Auto Precharge", $time);
                if (!no_halt) $stop (0);
                if (Addr[10] === 1'b0) begin
                    Write_precharge [Ba]= 1'b0;
                end
            end
            if ((Ba === 2'b00 && Pc_b0 === 1'b1) || (Ba === 2'b01 && Pc_b1 === 1'b1) ||
                (Ba === 2'b10 && Pc_b2 === 1'b1) || (Ba === 2'b11 && Pc_b3 === 1'b1)) begin
                $display("%m: At time %t ERROR: Bank is not Activated for Write", $time);
                if (!no_halt) $stop (0);
            end else begin
                Write_cmnd [3] = 1'b1;
                Write_bank [3] = Ba;
                Write_cols [3] = {Addr [ADDR_BITS - 1 : 11], Addr [9 : 0]};
                if (Addr[10] === 1'b1) begin
                    Write_precharge [Ba]= 1'b1;
                    Count_precharge [Ba]= 0;
                end
            end
        end
    end
    endtask
    task check_neg_dqs;
    begin
        if (Write_cmnd[2] || Write_cmnd[1] || Data_in_enable) begin
            for (i=0; i<DQS_BITS; i=i+1) begin
                if (expect_neg_dqs[i]) begin
                    $display ("%m: At time %t ERROR: Negative DQS[%d] transition required.", $time, i);
                end
                expect_neg_dqs[i] = 1'b1;
            end
        end else begin
            expect_pos_dqs = 0;
            expect_neg_dqs = 0;
        end
    end
    endtask
    task check_pos_dqs;
    begin
        if (Write_cmnd[2] || Write_cmnd[1] || Data_in_enable) begin
            for (i=0; i<DQS_BITS; i=i+1) begin
                if (expect_pos_dqs[i]) begin
                    $display ("%m: At time %t ERROR: Positive DQS[%d] transition required.", $time, i);
                end
                expect_pos_dqs[i] = 1'b1;
            end
        end else begin
            expect_pos_dqs = 0;
            expect_neg_dqs = 0;
        end
    end
    endtask
    always @ (posedge Sys_clk) begin
        Manual_Precharge_Pipeline;
        Burst_Terminate_Pipeline;
        Dq_Dqs_Drivers;
        Write_FIFO_DM_Mask_Logic;
        Burst_Decode;
        check_neg_dqs;
        Auto_Precharge_Calculation;
        DLL_Counter;
        Control_Logic;
    end
    always @ (negedge Sys_clk) begin
        Manual_Precharge_Pipeline;
        Burst_Terminate_Pipeline;
        Dq_Dqs_Drivers;
        Write_FIFO_DM_Mask_Logic;
        Burst_Decode;
        check_pos_dqs;
    end
    always @ (posedge Dqs_in[0]) begin
        dq_rise[7 : 0] = Dq_in[7 : 0];
        dm_rise[0] = Dm_in[0];
        expect_pos_dqs[0] = 0;
    end
    always @ (posedge Dqs_in[1]) begin
        dq_rise[15 : 8] = Dq_in[15 : 8];
        dm_rise[1] = Dm_in [1];
        expect_pos_dqs[1] = 0;
    end
    always @ (posedge Dqs_in[2]) begin
        dq_rise[23 : 16] = Dq_in[23 : 16];
        dm_rise[2] = Dm_in [2];
        expect_pos_dqs[2] = 0;
    end
    always @ (posedge Dqs_in[3]) begin
        dq_rise[31 : 24] = Dq_in[31 : 24];
        dm_rise[3] = Dm_in [3];
        expect_pos_dqs[3] = 0;
    end
    always @ (negedge Dqs_in[0]) begin
        dq_fall[7 : 0] = Dq_in[7 : 0];
        dm_fall[0] = Dm_in[0];
        dm_pair[1:0]  = {dm_rise[0], dm_fall[0]};
        expect_neg_dqs[0] = 0;
    end
    always @ (negedge Dqs_in[1]) begin
        dq_fall[15: 8] = Dq_in[15 : 8];
        dm_fall[1] = Dm_in[1];
        dm_pair[3:2]  = {dm_rise[1], dm_fall[1]};
        expect_neg_dqs[1] = 0;
    end
    always @ (negedge Dqs_in[2]) begin
        dq_fall[23: 16] = Dq_in[23 : 16];
        dm_fall[2] = Dm_in[2];
        dm_pair[5:4]  = {dm_rise[2], dm_fall[2]};
        expect_neg_dqs[2] = 0;
    end
    always @ (negedge Dqs_in[3]) begin
        dq_fall[31: 24] = Dq_in[31 : 24];
        dm_fall[3] = Dm_in[3];
        dm_pair[7:6]  = {dm_rise[3], dm_fall[3]};
        expect_neg_dqs[3] = 0;
    end
    specify
        specparam tDSS             =     1.5;  
        specparam tDSH             =     1.5;  
        specparam tIH              =   0.900;  
        specparam tIS              =   0.900;  
        specparam tDQSH            =   2.625;  
        specparam tDQSL            =   2.625;  
        $width    (posedge Dqs_in[0] &&& wdqs_valid, tDQSH);
        $width    (posedge Dqs_in[1] &&& wdqs_valid, tDQSH);
        $width    (negedge Dqs_in[0] &&& wdqs_valid, tDQSL);
        $width    (negedge Dqs_in[1] &&& wdqs_valid, tDQSL);
        $setuphold(posedge Clk,   Cke,   tIS, tIH);
        $setuphold(posedge Clk,   Cs_n,  tIS, tIH);
        $setuphold(posedge Clk,   Cas_n, tIS, tIH);
        $setuphold(posedge Clk,   Ras_n, tIS, tIH);
        $setuphold(posedge Clk,   We_n,  tIS, tIH);
        $setuphold(posedge Clk,   Addr,  tIS, tIH);
        $setuphold(posedge Clk,   Ba,    tIS, tIH);
        $setuphold(posedge Clk, negedge Dqs &&& wdqs_valid, tDSS, tDSH);
    endspecify
endmodule
module hpdmc_mgmt #(
	parameter sdram_depth = 26,
	parameter sdram_columndepth = 8
) (
	input sys_clk,
	input sdram_rst,
	input [2:0] tim_rp,
	input [2:0] tim_rcd,
	input [10:0] tim_refi,
	input [3:0] tim_rfc,
	input stb,
	input we,
	input [sdram_depth-3-1:0] address,  
	output reg ack,
	output reg read,
	output reg write,
	output [3:0] concerned_bank,
	input read_safe,
	input write_safe,
	input [3:0] precharge_safe,
	output sdram_cs_n,
	output sdram_we_n,
	output sdram_cas_n,
	output sdram_ras_n,
	output [12:0] sdram_adr,
	output [1:0] sdram_ba
);
parameter rowdepth = sdram_depth-2-1-(sdram_columndepth+2)+1;
wire [sdram_depth-2-1:0] address32 = {address, 1'b0};
wire [sdram_columndepth-1:0] col_address = address32[sdram_columndepth-1:0];
wire [1:0] bank_address = address32[sdram_columndepth+1:sdram_columndepth];
wire [rowdepth-1:0] row_address = address32[sdram_depth-2-1:sdram_columndepth+2];
reg [3:0] bank_address_onehot;
always @(*) begin
	case(bank_address)
		2'b00: bank_address_onehot <= 4'b0001;
		2'b01: bank_address_onehot <= 4'b0010;
		2'b10: bank_address_onehot <= 4'b0100;
		2'b11: bank_address_onehot <= 4'b1000;
	endcase
end
reg [3:0] has_openrow;
reg [rowdepth-1:0] openrows[0:3];
reg [3:0] track_close;
reg [3:0] track_open;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		has_openrow = 4'h0;
	end else begin
		has_openrow = (has_openrow | track_open) & ~track_close;
		if(track_open[0]) openrows[0] <= row_address;
		if(track_open[1]) openrows[1] <= row_address;
		if(track_open[2]) openrows[2] <= row_address;
 		if(track_open[3]) openrows[3] <= row_address;
	end
end
assign concerned_bank = bank_address_onehot;
wire current_precharge_safe =
	 (precharge_safe[0] | ~bank_address_onehot[0])
	&(precharge_safe[1] | ~bank_address_onehot[1])
	&(precharge_safe[2] | ~bank_address_onehot[2])
	&(precharge_safe[3] | ~bank_address_onehot[3]);
wire bank_open = has_openrow[bank_address];
wire page_hit = bank_open & (openrows[bank_address] == row_address);
reg sdram_adr_loadrow;
reg sdram_adr_loadcol;
reg sdram_adr_loadA10;
assign sdram_adr =
	 ({13{sdram_adr_loadrow}}	& row_address)
	|({13{sdram_adr_loadcol}}	& col_address)
	|({13{sdram_adr_loadA10}}	& 13'd1024);
assign sdram_ba = bank_address;
reg sdram_cs;
reg sdram_we;
reg sdram_cas;
reg sdram_ras;
assign sdram_cs_n = ~sdram_cs;
assign sdram_we_n = ~sdram_we;
assign sdram_cas_n = ~sdram_cas;
assign sdram_ras_n = ~sdram_ras;
reg [2:0] precharge_counter;
reg reload_precharge_counter;
wire precharge_done = (precharge_counter == 3'd0);
always @(posedge sys_clk) begin
	if(reload_precharge_counter)
		precharge_counter <= tim_rp;
	else if(~precharge_done)
		precharge_counter <= precharge_counter - 3'd1;
end
reg [2:0] activate_counter;
reg reload_activate_counter;
wire activate_done = (activate_counter == 3'd0);
always @(posedge sys_clk) begin
	if(reload_activate_counter)
		activate_counter <= tim_rcd;
	else if(~activate_done)
		activate_counter <= activate_counter - 3'd1;
end
reg [10:0] refresh_counter;
reg reload_refresh_counter;
wire must_refresh = refresh_counter == 11'd0;
always @(posedge sys_clk) begin
	if(sdram_rst)
		refresh_counter <= 11'd0;
	else begin
		if(reload_refresh_counter)
			refresh_counter <= tim_refi;
		else if(~must_refresh)
			refresh_counter <= refresh_counter - 11'd1;
	end
end
reg [3:0] autorefresh_counter;
reg reload_autorefresh_counter;
wire autorefresh_done = (autorefresh_counter == 4'd0);
always @(posedge sys_clk) begin
	if(reload_autorefresh_counter)
		autorefresh_counter <= tim_rfc;
	else if(~autorefresh_done)
		autorefresh_counter <= autorefresh_counter - 4'd1;
end
reg [3:0] state;
reg [3:0] next_state;
parameter IDLE			= 4'd0;
parameter ACTIVATE		= 4'd1;
parameter READ			= 4'd2;
parameter WRITE			= 4'd3;
parameter PRECHARGEALL		= 4'd4;
parameter AUTOREFRESH		= 4'd5;
parameter AUTOREFRESH_WAIT	= 4'd6;
always @(posedge sys_clk) begin
	if(sdram_rst)
		state <= IDLE;
	else begin
		state <= next_state;
	end
end
always @(*) begin
	next_state = state;
	reload_precharge_counter = 1'b0;
	reload_activate_counter = 1'b0;
	reload_refresh_counter = 1'b0;
	reload_autorefresh_counter = 1'b0;
	sdram_cs = 1'b0;
	sdram_we = 1'b0;
	sdram_cas = 1'b0;
	sdram_ras = 1'b0;
	sdram_adr_loadrow = 1'b0;
	sdram_adr_loadcol = 1'b0;
	sdram_adr_loadA10 = 1'b0;
	track_close = 4'b0000;
	track_open = 4'b0000;
	read = 1'b0;
	write = 1'b0;
	ack = 1'b0;
	case(state)
		IDLE: begin
			if(must_refresh)
				next_state = PRECHARGEALL;
			else begin
				if(stb) begin
					if(page_hit) begin
						if(we) begin
							if(write_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b0;
								sdram_cas = 1'b1;
								sdram_we = 1'b1;
								sdram_adr_loadcol = 1'b1;
								write = 1'b1;
								ack = 1'b1;
							end
						end else begin
							if(read_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b0;
								sdram_cas = 1'b1;
								sdram_we = 1'b0;
								sdram_adr_loadcol = 1'b1;
								read = 1'b1;
								ack = 1'b1;
							end
						end
					end else begin
						if(bank_open) begin
							if(current_precharge_safe) begin
								sdram_cs = 1'b1;
								sdram_ras = 1'b1;
								sdram_cas = 1'b0;
								sdram_we = 1'b1;
								track_close = bank_address_onehot;
								reload_precharge_counter = 1'b1;
								next_state = ACTIVATE;
							end
						end else begin
							sdram_cs = 1'b1;
							sdram_ras = 1'b1;
							sdram_cas = 1'b0;
							sdram_we = 1'b0;
							sdram_adr_loadrow = 1'b1;
							track_open = bank_address_onehot;
							reload_activate_counter = 1'b1;
							if(we)
								next_state = WRITE;
							else
								next_state = READ;
						end
					end
				end
			end
		end
		ACTIVATE: begin
			if(precharge_done) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b0;
				sdram_we = 1'b0;
				sdram_adr_loadrow = 1'b1;
				track_open = bank_address_onehot;
				reload_activate_counter = 1'b1;
				if(we)
					next_state = WRITE;
				else
					next_state = READ;
			end
		end
		READ: begin
			if(activate_done) begin
				if(read_safe) begin
					sdram_cs = 1'b1;
					sdram_ras = 1'b0;
					sdram_cas = 1'b1;
					sdram_we = 1'b0;
					sdram_adr_loadcol = 1'b1;
					read = 1'b1;
					ack = 1'b1;
					next_state = IDLE;
				end
			end
		end
		WRITE: begin
			if(activate_done) begin
				if(write_safe) begin
					sdram_cs = 1'b1;
					sdram_ras = 1'b0;
					sdram_cas = 1'b1;
					sdram_we = 1'b1;
					sdram_adr_loadcol = 1'b1;
					write = 1'b1;
					ack = 1'b1;
					next_state = IDLE;
				end
			end
		end
		PRECHARGEALL: begin
			if(precharge_safe == 4'b1111) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b0;
				sdram_we = 1'b1;
				sdram_adr_loadA10 = 1'b1;
				reload_precharge_counter = 1'b1;
				track_close = 4'b1111;
				next_state = AUTOREFRESH;
			end
		end
		AUTOREFRESH: begin
			if(precharge_done) begin
				sdram_cs = 1'b1;
				sdram_ras = 1'b1;
				sdram_cas = 1'b1;
				sdram_we = 1'b0;
				reload_refresh_counter = 1'b1;
				reload_autorefresh_counter = 1'b1;
				next_state = AUTOREFRESH_WAIT;
			end
		end
		AUTOREFRESH_WAIT: begin
			if(autorefresh_done)
				next_state = IDLE;
		end
	endcase
end
endmodule
module hpdmc_datactl(
	input sys_clk,
	input sdram_rst,
	input read,
	input write,
	input [3:0] concerned_bank,
	output reg read_safe,
	output reg write_safe,
	output [3:0] precharge_safe,
	output reg ack,
	output reg direction,
	input tim_cas,
	input [1:0] tim_wr
);
reg [2:0] read_safe_counter;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		read_safe_counter <= 3'd0;
		read_safe <= 1'b1;
	end else begin
		if(read) begin
			read_safe_counter <= 3'd4;
			read_safe <= 1'b0;
		end else if(write) begin
			read_safe_counter <= {2'b01, ~tim_cas};
			read_safe <= 1'b0;
		end else begin
			if(read_safe_counter == 3'd1)
				read_safe <= 1'b1;
			if(~read_safe)
				read_safe_counter <= read_safe_counter - 3'd1;
		end
	end
end
reg [2:0] write_safe_counter;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		write_safe_counter <= 3'd0;
		write_safe <= 1'b1;
	end else begin
		if(read) begin
			write_safe_counter <= {2'b11, tim_cas};
			write_safe <= 1'b0;
		end else if(write) begin
			write_safe_counter <= 3'd4;
			write_safe <= 1'b0;
		end else begin
			if(write_safe_counter == 3'd1)
				write_safe <= 1'b1;
			if(~write_safe)
				write_safe_counter <= write_safe_counter - 3'd1;
		end
	end
end
reg ack_read3;
reg ack_read2;
reg ack_read1;
reg ack_read0;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		ack_read3 <= 1'b0;
		ack_read2 <= 1'b0;
		ack_read1 <= 1'b0;
		ack_read0 <= 1'b0;
	end else begin
		if(tim_cas) begin
			ack_read3 <= read;
			ack_read2 <= ack_read3;
			ack_read1 <= ack_read2;
			ack_read0 <= ack_read1;
		end else begin
			ack_read2 <= read;
			ack_read1 <= ack_read2;
			ack_read0 <= ack_read1;
		end
	end
end
reg ack0;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		ack0 <= 1'b0;
		ack <= 1'b0;
	end else begin
		ack0 <= ack_read0|write;
		ack <= ack0;
	end
end
reg write_d;
reg [2:0] counter_writedirection;
always @(posedge sys_clk) begin
	if(sdram_rst) begin
		counter_writedirection <= 3'd0;
		direction <= 1'b0;
	end else begin
		if(write_d) begin
			counter_writedirection <= 3'b101;
			direction <= 1'b1;
		end else begin
			if(counter_writedirection == 3'b001)
				direction <= 1'b0;
			if(direction)
				counter_writedirection <= counter_writedirection - 3'd1;
		end
	end
end
always @(posedge sys_clk) begin
	if(sdram_rst)
		write_d <= 1'b0;
	else
		write_d <= write;
end
hpdmc_banktimer banktimer0(
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.tim_cas(tim_cas),
	.tim_wr(tim_wr),
	.read(read & concerned_bank[0]),
	.write(write & concerned_bank[0]),
	.precharge_safe(precharge_safe[0])
);
hpdmc_banktimer banktimer1(
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.tim_cas(tim_cas),
	.tim_wr(tim_wr),
	.read(read & concerned_bank[1]),
	.write(write & concerned_bank[1]),
	.precharge_safe(precharge_safe[1])
);
hpdmc_banktimer banktimer2(
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.tim_cas(tim_cas),
	.tim_wr(tim_wr),
	.read(read & concerned_bank[2]),
	.write(write & concerned_bank[2]),
	.precharge_safe(precharge_safe[2])
);
hpdmc_banktimer banktimer3(
	.sys_clk(sys_clk),
	.sdram_rst(sdram_rst),
	.tim_cas(tim_cas),
	.tim_wr(tim_wr),
	.read(read & concerned_bank[3]),
	.write(write & concerned_bank[3]),
	.precharge_safe(precharge_safe[3])
);
endmodule
module hpdmc_ddrio(
	input sys_clk,
	input dqs_clk,
	input direction,
	input [7:0] mo,
	input [63:0] do,
	output [63:0] di,
	output [3:0] sdram_dqm,
	inout [31:0] sdram_dq,
	inout [3:0] sdram_dqs,
	input idelay_rst,
	input idelay_ce,
	input idelay_inc
);
wire [31:0] sdram_data_out;
assign sdram_dq = direction ? sdram_data_out : 32'hzzzzzzzz;
assign sdram_dqs = direction ? {4{dqs_clk}} : 4'hz;
hpdmc_oddr4 oddr_dqm(
	.Q(sdram_dqm),
	.C(sys_clk),
	.CE(1'b1),
	.D1(mo[7:4]),
	.D2(mo[3:0]),
	.R(1'b0),
	.S(1'b0)
);
hpdmc_oddr32 oddr_dq(
	.Q(sdram_data_out),
	.C(sys_clk),
	.CE(1'b1),
	.D1(do[63:32]),
	.D2(do[31:0]),
	.R(1'b0),
	.S(1'b0)
);
wire [31:0] sdram_dq_delayed;
hpdmc_idelay8 dq_delay0 (
	.i(sdram_dq[7:0]),
	.o(sdram_dq_delayed[7:0]),
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay1 (
	.i(sdram_dq[15:8]),
	.o(sdram_dq_delayed[15:8]),
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay2 (
	.i(sdram_dq[23:16]),
	.o(sdram_dq_delayed[23:16]),
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_idelay8 dq_delay3 (
	.i(sdram_dq[31:24]),
	.o(sdram_dq_delayed[31:24]),
	.clk(sys_clk),
	.rst(idelay_rst),
	.ce(idelay_ce),
	.inc(idelay_inc)
);
hpdmc_iddr32 iddr_dq(
	.Q1(di[31:0]),
	.Q2(di[63:32]),
	.C(sys_clk),
	.CE(1'b1),
	.D(sdram_dq_delayed),
	.R(1'b0),
	.S(1'b0)
);
endmodule
module ODDR #(
	parameter DDR_CLK_EDGE = "OPPOSITE_EDGE",
	parameter INIT = 1'b0,
	parameter SRTYPE = "SYNC"
) (
	output Q,
	input C,
	input CE,
	input D1,
	input D2,
	input R,
	input S
);
reg q_out = INIT, qd2_posedge_int;
wire c_in;
wire ce_in;
wire d1_in;
wire d2_in;
wire gsr_in;
wire r_in;
wire s_in;
buf buf_c(c_in, C);
buf buf_ce(ce_in, CE);
buf buf_d1(d1_in, D1);
buf buf_d2(d2_in, D2);
buf buf_q(Q, q_out);
buf buf_r(r_in, R);
buf buf_s(s_in, S); 
initial begin
	if((INIT != 0) && (INIT != 1)) begin
		$display("Attribute Syntax Error : The attribute INIT on ODDR instance %m is set to %d.  Legal values for this attribute are 0 or 1.", INIT);
		$finish;
	end
	if((DDR_CLK_EDGE != "OPPOSITE_EDGE") && (DDR_CLK_EDGE != "SAME_EDGE")) begin
		$display("Attribute Syntax Error : The attribute DDR_CLK_EDGE on ODDR instance %m is set to %s.  Legal values for this attribute are OPPOSITE_EDGE or SAME_EDGE.", DDR_CLK_EDGE);
		$finish;
	end
	if((SRTYPE != "ASYNC") && (SRTYPE != "SYNC")) begin
		$display("Attribute Syntax Error : The attribute SRTYPE on ODDR instance %m is set to %s.  Legal values for this attribute are ASYNC or SYNC.", SRTYPE);
		$finish;
	end
end
always @(r_in, s_in) begin
	if(r_in == 1'b1 && SRTYPE == "ASYNC") begin
		assign q_out = 1'b0;
		assign qd2_posedge_int = 1'b0;
	end else if(r_in == 1'b0 && s_in == 1'b1 && SRTYPE == "ASYNC") begin
		assign q_out = 1'b1;
		assign qd2_posedge_int = 1'b1;
	end else if((r_in == 1'b1 || s_in == 1'b1) && SRTYPE == "SYNC") begin
		deassign q_out;
		deassign qd2_posedge_int;
	end else if(r_in == 1'b0 && s_in == 1'b0) begin
		deassign q_out;
		deassign qd2_posedge_int;
	end
end
always @(posedge c_in) begin
	if(r_in == 1'b1) begin
		q_out <= 1'b0;
		qd2_posedge_int <= 1'b0;
	end else if(r_in == 1'b0 && s_in == 1'b1) begin
		q_out <= 1'b1;
		qd2_posedge_int <= 1'b1;
	end else if(ce_in == 1'b1 && r_in == 1'b0 && s_in == 1'b0) begin
		q_out <= d1_in;
		qd2_posedge_int <= d2_in;
	end
end
always @(negedge c_in) begin
	if(r_in == 1'b1)
		q_out <= 1'b0;
	else if(r_in == 1'b0 && s_in == 1'b1)
		q_out <= 1'b1;
	else if(ce_in == 1'b1 && r_in == 1'b0 && s_in == 1'b0) begin
		if(DDR_CLK_EDGE == "SAME_EDGE")
			q_out <= qd2_posedge_int;
		else if(DDR_CLK_EDGE == "OPPOSITE_EDGE")
			q_out <= d2_in;
	end
end
endmodule
`timescale 1ns / 1ps
module IDELAY #(
	parameter IOBDELAY_TYPE = "DEFAULT",
	parameter integer IOBDELAY_VALUE = 0
) (
	input C,
	input CE,
	input I,
	input INC,
	input RST,
	output reg O
);
always @(I)
	# (IOBDELAY_VALUE*0.078) O = I;
endmodule
