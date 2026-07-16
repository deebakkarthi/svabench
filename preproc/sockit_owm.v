module sockit_owm #(
  parameter OVD_E =    1,   
  parameter CDR_E =    1,   
  parameter BDW   =   32,   
  parameter OWN   =    1,   
  parameter BAW   = 1,   
  parameter BTP_N = "5.0",  
  parameter BTP_O = "1.0",  
  parameter T_RSTH_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,   
  parameter T_RSTL_N = (BTP_N == "7.5") ?  64 : (BTP_N == "5.0") ?  96 :  80,   
  parameter T_RSTP_N = (BTP_N == "7.5") ?  10 : (BTP_N == "5.0") ?  15 :  10,   
  parameter T_DAT0_N = (BTP_N == "7.5") ?   8 : (BTP_N == "5.0") ?  12 :  10,   
  parameter T_DAT1_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,   
  parameter T_BITS_N = (BTP_N == "7.5") ?   2 : (BTP_N == "5.0") ?   3 :   2,   
  parameter T_RCVR_N = (BTP_N == "7.5") ?   1 : (BTP_N == "5.0") ?   1 :   1,   
  parameter T_IDLE_N = (BTP_N == "7.5") ? 128 : (BTP_N == "5.0") ? 200 : 160,   
  parameter T_RSTH_O = (BTP_O == "1.0") ?  48 :  96,   
  parameter T_RSTL_O = (BTP_O == "1.0") ?  48 :  96,   
  parameter T_RSTP_O = (BTP_O == "1.0") ?  10 :  15,   
  parameter T_DAT0_O = (BTP_O == "1.0") ?   6 :  12,   
  parameter T_DAT1_O = (BTP_O == "1.0") ?   1 :   2,   
  parameter T_BITS_O = (BTP_O == "1.0") ?   2 :   3,   
  parameter T_RCVR_O = (BTP_O == "1.0") ?   2 :   4,   
  parameter T_IDLE_O = (BTP_O == "1.0") ?  96 : 192,   
  parameter CDR_N = 5-1,   
  parameter CDR_O = 1-1    
)(
  input            clk,
  input            rst,
  input            bus_ren,   
  input            bus_wen,   
  input  [BAW-1:0] bus_adr,   
  input  [BDW-1:0] bus_wdt,   
  output [BDW-1:0] bus_rdt,   
  output           bus_irq,   
  output [OWN-1:0] owr_p,     
  output [OWN-1:0] owr_e,     
  input  [OWN-1:0] owr_i      
);
localparam PDW = (BDW==32) ? 24 : 8;
localparam CDW = CDR_E ? ((BDW==32) ? 16 : 8) : $clog2(CDR_N);
localparam SDW = $clog2(OWN);
localparam TDW =       (T_RSTH_O+T_RSTL_O) >       (T_RSTH_N+T_RSTL_N)
               ? $clog2(T_RSTH_O+T_RSTL_O) : $clog2(T_RSTH_N+T_RSTL_N);
wire bus_ren_ctl_sts;
wire bus_wen_ctl_sts;
wire bus_wen_pwr_sel;
wire bus_wen_cdr_n;
wire bus_wen_cdr_o;
wire     [7:0] bus_rdt_ctl_sts;
wire [PDW-1:0] bus_rdt_pwr_sel;
reg  [CDW-1:0] div;
reg  [CDW-1:0] cdr_n;
reg  [CDW-1:0] cdr_o;
wire           pls;
reg            owr_cyc;   
reg  [TDW-1:0] cnt;       
reg  [SDW-1:0] owr_sel;
wire           req_ovd;
reg  [OWN-1:0] owr_pwr;   
reg            owr_ovd;   
reg            owr_rst;   
reg            owr_dat;   
reg            owr_smp;   
reg            owr_oen;   
wire           owr_iln;   
reg            irq_ena;   
reg            irq_sts;   
wire [TDW-1:0] t_idl ;    
wire [TDW-1:0] t_rst ;    
wire [TDW-1:0] t_bit ;    
wire [TDW-1:0] t_rstp;    
wire [TDW-1:0] t_rsth;    
wire [TDW-1:0] t_dat0;    
wire [TDW-1:0] t_dat1;    
wire [TDW-1:0] t_bits;    
wire [TDW-1:0] t_zero;    
assign t_idl  = req_ovd ? T_IDLE_O                       : T_IDLE_N                      ;
assign t_rst  = req_ovd ? T_RSTL_O + T_RSTH_O            : T_RSTL_N + T_RSTH_N           ;
assign t_bit  = req_ovd ? T_DAT0_O +          + T_RCVR_O : T_DAT0_N +            T_RCVR_N;
assign t_rstp = owr_ovd ? T_RSTH_O - T_RSTP_O            : T_RSTH_N - T_RSTP_N           ;
assign t_rsth = owr_ovd ? T_RSTH_O                       : T_RSTH_N                      ;
assign t_dat0 = owr_ovd ? T_DAT0_O - T_DAT0_O + T_RCVR_O : T_DAT0_N - T_DAT0_N + T_RCVR_N;
assign t_dat1 = owr_ovd ? T_DAT0_O - T_DAT1_O + T_RCVR_O : T_DAT0_N - T_DAT1_N + T_RCVR_N;
assign t_bits = owr_ovd ? T_DAT0_O - T_BITS_O + T_RCVR_O : T_DAT0_N - T_BITS_N + T_RCVR_N;
assign t_zero = 'd0;
assign bus_rdt_ctl_sts = {irq_ena, irq_sts, 1'b0, owr_pwr[0], owr_cyc, owr_ovd, owr_rst, owr_dat};
generate
  if (BDW==32) begin
    if (OWN>1) begin
      assign bus_rdt_pwr_sel = {{16-OWN{1'b0}}, owr_pwr, 4'h0, {4-SDW{1'b0}}, owr_sel};
    end else begin
      assign bus_rdt_pwr_sel = 24'h0000_00;
    end
  end else if (BDW==8) begin
    if (OWN>1) begin
      assign bus_rdt_pwr_sel = {{ 4-OWN{1'b0}}, owr_pwr,       {4-SDW{1'b0}}, owr_sel};
    end else begin
      assign bus_rdt_pwr_sel = 8'hxx;
    end
  end
endgenerate
generate if (BDW==32) begin
  assign bus_rdt = (bus_adr[0]==1'b0) ? {bus_rdt_pwr_sel, bus_rdt_ctl_sts} : (cdr_o << 16 | cdr_n);
end else if (BDW==8) begin
  assign bus_rdt = (bus_adr[1]==1'b0) ? ((bus_adr[0]==1'b0) ? bus_rdt_ctl_sts
                                                            : bus_rdt_pwr_sel)
                                      : ((bus_adr[0]==1'b0) ? cdr_n
                                                            : cdr_o          );
end endgenerate
generate if (BDW==32) begin
  assign bus_ren_ctl_sts = bus_ren & bus_adr[0] == 1'b0;
  assign bus_wen_ctl_sts = bus_wen & bus_adr[0] == 1'b0;
  assign bus_wen_pwr_sel = bus_wen & bus_adr[0] == 1'b0;
  assign bus_wen_cdr_n   = bus_wen & bus_adr[0] == 1'b1;
  assign bus_wen_cdr_o   = bus_wen & bus_adr[0] == 1'b1;
end else if (BDW==8) begin
  assign bus_ren_ctl_sts = bus_ren & bus_adr[1:0] == 2'b00;
  assign bus_wen_ctl_sts = bus_wen & bus_adr[1:0] == 2'b00;
  assign bus_wen_pwr_sel = bus_wen & bus_adr[1:0] == 2'b01;
  assign bus_wen_cdr_n   = bus_wen & bus_adr[1:0] == 2'b10;
  assign bus_wen_cdr_o   = bus_wen & bus_adr[1:0] == 2'b11;
end endgenerate
generate
  if (CDR_E) begin
    if (BDW==32) begin
      always @ (posedge clk, posedge rst)
      if (rst) begin
        cdr_n <= CDR_N;
        cdr_o <= CDR_O;
      end else begin
        if (bus_wen_cdr_n)  cdr_n <= bus_wdt[15: 0];
        if (bus_wen_cdr_o)  cdr_o <= bus_wdt[31:16];
      end
    end else if (BDW==8) begin
      always @ (posedge clk, posedge rst)
      if (rst) begin
        cdr_n <= CDR_N;
        cdr_o <= CDR_O;
      end else begin
        if (bus_wen_cdr_n)  cdr_n <= bus_wdt;
        if (bus_wen_cdr_o)  cdr_o <= bus_wdt;
      end
    end
  end else begin
    initial begin
      cdr_n = CDR_N;
      cdr_o = CDR_O;
    end
  end
endgenerate
always @ (posedge clk, posedge rst)
if (rst)        div <= 'd0;
else begin
  if (bus_wen)  div <= 'd0;
  else          div <= pls ? 'd0 : div + owr_cyc;
end
assign pls = (div == (owr_ovd ? cdr_o : cdr_n));
generate if (OWN>1) begin : sel_implementation
  always @ (posedge clk, posedge rst)
  if (rst)                   owr_sel <= {SDW{1'b0}};
  else if (bus_wen_pwr_sel)  owr_sel <= bus_wdt[(BDW==32 ?  8 : 0)+:SDW];
  always @ (posedge clk, posedge rst)
  if (rst)                   owr_pwr <= {OWN{1'b0}};
  else if (bus_wen_pwr_sel)  owr_pwr <= bus_wdt[(BDW==32 ? 16 : 4)+:OWN];
end else begin
  initial                    owr_sel <= 'd0; 
  always @ (posedge clk, posedge rst)
  if (rst)                   owr_pwr <= 1'b0;
  else if (bus_wen_ctl_sts)  owr_pwr <= bus_wdt[4];
end endgenerate
assign bus_irq = irq_ena & irq_sts;
always @ (posedge clk, posedge rst)
if (rst)                   irq_ena <= 1'b0;     
else if (bus_wen_ctl_sts)  irq_ena <= bus_wdt[7]; 
always @ (posedge clk, posedge rst)
if (rst)                           irq_sts <= 1'b0;
else begin
  if (bus_wen_ctl_sts)             irq_sts <= 1'b0;
  else if (pls & (cnt == t_zero))  irq_sts <= 1'b1;
  else if (bus_ren_ctl_sts)        irq_sts <= 1'b0;
end
assign req_ovd = OVD_E ? bus_wen_ctl_sts & bus_wdt[2] : 1'b0; 
always @ (posedge clk, posedge rst)
if (rst)                   owr_ovd <= 1'b0;
else if (bus_wen_ctl_sts)  owr_ovd <= req_ovd;
always @ (posedge clk, posedge rst)
if (rst)                   owr_rst <= 1'b0;
else if (bus_wen_ctl_sts)  owr_rst <= bus_wdt[1];
always @ (posedge clk, posedge rst)
if (rst)                           owr_dat <= 1'b0;
else begin
  if (bus_wen_ctl_sts)             owr_dat <= bus_wdt[0];
  else if (pls & (cnt == t_zero))  owr_dat <= owr_smp;
end
always @ (posedge clk, posedge rst)
if (rst)                           owr_cyc <= 1'b0;
else begin
  if (bus_wen_ctl_sts)             owr_cyc <= bus_wdt[3] & ~&bus_wdt[2:0];
  else if (pls & (cnt == t_zero))  owr_cyc <= 1'b0;
end
always @ (posedge clk, posedge rst)
if (rst)                 cnt <= 'd0;
else begin
  if (bus_wen_ctl_sts)   cnt <= (&bus_wdt[1:0] ? t_idl : bus_wdt[1] ? t_rst : t_bit) - 'd1;
  else if (pls)          cnt <= cnt - 'd1;
end
always @ (posedge clk)
if (pls) begin
  if      ( owr_rst & (cnt == t_rstp))  owr_smp <= owr_iln;   
  else if (~owr_rst & (cnt == t_bits))  owr_smp <= owr_iln;   
end
always @ (posedge clk, posedge rst)
if (rst)                                owr_oen <= 1'b0;
else begin
  if (bus_wen_ctl_sts)                  owr_oen <= ~&bus_wdt[1:0];
  else if (pls) begin
    if      (owr_rst & (cnt == t_rsth)) owr_oen <= 1'b0;   
    else if (owr_dat & (cnt == t_dat1)) owr_oen <= 1'b0;   
    else if (          (cnt == t_dat0)) owr_oen <= 1'b0;   
  end
end
assign owr_e   = owr_oen << owr_sel;
assign owr_p   = owr_pwr;
assign owr_iln = owr_i [owr_sel];
endmodule
