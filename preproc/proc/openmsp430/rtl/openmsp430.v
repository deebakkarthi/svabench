module  omsp_alu (
    alu_out,                        
    alu_out_add,                    
    alu_stat,                       
    alu_stat_wr,                    
    dbg_halt_st,                    
    exec_cycle,                     
    inst_alu,                       
    inst_bw,                        
    inst_jmp,                       
    inst_so,                        
    op_dst,                         
    op_src,                         
    status                          
);
output       [15:0] alu_out;        
output       [15:0] alu_out_add;    
output        [3:0] alu_stat;       
output        [3:0] alu_stat_wr;    
input               dbg_halt_st;    
input               exec_cycle;     
input        [11:0] inst_alu;       
input               inst_bw;        
input         [7:0] inst_jmp;       
input         [7:0] inst_so;        
input        [15:0] op_dst;         
input        [15:0] op_src;         
input         [3:0] status;         
function [4:0] bcd_add;
   input [3:0] X;
   input [3:0] Y;
   input       C_;
   reg   [4:0] Z_;
   begin
      Z_ = {1'b0,X}+{1'b0,Y}+{4'b0000,C_};
      if (Z_<5'd10) bcd_add = Z_;
      else          bcd_add = Z_+5'd6;
   end
endfunction
wire        op_src_inv_cmd = exec_cycle & (inst_alu[0]);
wire [15:0] op_src_inv     = {16{op_src_inv_cmd}} ^ op_src;
wire        op_bit8_msk     = ~exec_cycle | ~inst_bw;
wire [16:0] op_src_in       = {1'b0, {op_src_inv[15:8] & {8{op_bit8_msk}}}, op_src_inv[7:0]};
wire [16:0] op_dst_in       = {1'b0, {op_dst[15:8]     & {8{op_bit8_msk}}}, op_dst[7:0]};
wire        jmp_not_taken  = (inst_jmp[6]  & ~(status[3]^status[2])) |
                             (inst_jmp[5] &  (status[3]^status[2])) |
                             (inst_jmp[4]  &  ~status[2])            |
                             (inst_jmp[3]  &  ~status[0])            |
                             (inst_jmp[2] &   status[0])            |
                             (inst_jmp[1] &  ~status[1])            |
                             (inst_jmp[0] &   status[1]);
wire [16:0] op_src_in_jmp  = op_src_in & {17{~jmp_not_taken}};
wire [16:0] alu_add        = op_src_in_jmp + op_dst_in;
wire [16:0] alu_and        = op_src_in     & op_dst_in;
wire [16:0] alu_or         = op_src_in     | op_dst_in;
wire [16:0] alu_xor        = op_src_in     ^ op_dst_in;
wire        alu_inc         = exec_cycle & ((inst_alu[2] & status[0]) |
                                             inst_alu[1]);
wire [16:0] alu_add_inc    = alu_add + {16'h0000, alu_inc};
wire  [4:0] alu_dadd0      = bcd_add(op_src_in[3:0],   op_dst_in[3:0],  status[0]);
wire  [4:0] alu_dadd1      = bcd_add(op_src_in[7:4],   op_dst_in[7:4],  alu_dadd0[4]);
wire  [4:0] alu_dadd2      = bcd_add(op_src_in[11:8],  op_dst_in[11:8], alu_dadd1[4]);
wire  [4:0] alu_dadd3      = bcd_add(op_src_in[15:12], op_dst_in[15:12],alu_dadd2[4]);
wire [16:0] alu_dadd       = {alu_dadd3, alu_dadd2[3:0], alu_dadd1[3:0], alu_dadd0[3:0]};
wire        alu_shift_msb  = inst_so[0] ? status[0]     :
	                     inst_bw       ? op_src[7]     : op_src[15];
wire        alu_shift_7    = inst_bw       ? alu_shift_msb : op_src[8];
wire [16:0] alu_shift      = {1'b0, alu_shift_msb, op_src[15:9], alu_shift_7, op_src[7:1]};
wire [16:0] alu_swpb       = {1'b0, op_src[7:0],op_src[15:8]};
wire [16:0] alu_sxt        = {1'b0, {8{op_src[7]}},op_src[7:0]};
wire        alu_short_thro = ~(inst_alu[4]   |
                               inst_alu[5]    |
                               inst_alu[6]   |
                               inst_alu[10] |
                               inst_so[1]       |
                               inst_so[3]);
wire [16:0] alu_short      = ({17{inst_alu[4]}}   & alu_and)   |
                             ({17{inst_alu[5]}}    & alu_or)    |
                             ({17{inst_alu[6]}}   & alu_xor)   |
                             ({17{inst_alu[10]}} & alu_shift) |
                             ({17{inst_so[1]}}       & alu_swpb)  |
                             ({17{inst_so[3]}}        & alu_sxt)   |
                             ({17{alu_short_thro}}       & op_src_in);
wire [16:0] alu_out_nxt    = (inst_so[7] | dbg_halt_st |
                              inst_alu[3]) ? alu_add_inc :
                              inst_alu[7] ? alu_dadd    : alu_short;
assign      alu_out        =  alu_out_nxt[15:0];
assign      alu_out_add    =  alu_add[15:0];
wire    V_xor       = inst_bw ? (op_src_in[7]  & op_dst_in[7])  :
                                (op_src_in[15] & op_dst_in[15]);
wire    V           = inst_bw ? ((~op_src_in[7]  & ~op_dst_in[7]  &  alu_out[7])  |
                                 ( op_src_in[7]  &  op_dst_in[7]  & ~alu_out[7])) :
                                ((~op_src_in[15] & ~op_dst_in[15] &  alu_out[15]) |
                                 ( op_src_in[15] &  op_dst_in[15] & ~alu_out[15]));
wire    N           = inst_bw ?  alu_out[7]       : alu_out[15];
wire    Z           = inst_bw ? (alu_out[7:0]==0) : (alu_out==0);
wire    C           = inst_bw ?  alu_out[8]       : alu_out_nxt[16];
assign  alu_stat    = inst_alu[10]  ? {1'b0, N,Z,op_src_in[0]} :
                      inst_alu[8] ? {1'b0, N,Z,~Z}           :
                      inst_alu[6]    ? {V_xor,N,Z,~Z}           : {V,N,Z,C};
assign  alu_stat_wr = (inst_alu[9] & exec_cycle) ? 4'b1111 : 4'b0000;
endmodule  
module  omsp_and_gate (
    y,                          
    a,                          
    b                           
);
output         y;               
input          a;               
input          b;               
assign  y  =  a & b;
endmodule  
module  omsp_clock_gate (
    gclk,                       
    clk,                        
    enable,                     
    scan_enable                 
);
output         gclk;            
input          clk;             
input          enable;          
input          scan_enable;     
wire    enable_in =   (enable | scan_enable);
reg     enable_latch;
always @(clk or enable_in)
  if (~clk)
    enable_latch <= enable_in;
assign  gclk      =  (clk & enable_latch);
endmodule  
module  omsp_clock_module (
    aclk,                          
    aclk_en,                       
    cpu_en_s,                      
    dbg_clk,                       
    dbg_en_s,                      
    dbg_rst,                       
    dco_enable,                    
    dco_wkup,                      
    lfxt_enable,                   
    lfxt_wkup,                     
    mclk,                          
    per_dout,                      
    por,                           
    puc_pnd_set,                   
    puc_rst,                       
    smclk,                         
    smclk_en,                      
    cpu_en,                        
    cpuoff,                        
    dbg_cpu_reset,                 
    dbg_en,                        
    dco_clk,                       
    lfxt_clk,                      
    mclk_enable,                   
    mclk_wkup,                     
    oscoff,                        
    per_addr,                      
    per_din,                       
    per_en,                        
    per_we,                        
    reset_n,                       
    scan_enable,                   
    scan_mode,                     
    scg0,                          
    scg1,                          
    wdt_reset                      
);
output              aclk;          
output              aclk_en;       
output              cpu_en_s;      
output              dbg_clk;       
output              dbg_en_s;      
output              dbg_rst;       
output              dco_enable;    
output              dco_wkup;      
output              lfxt_enable;   
output              lfxt_wkup;     
output              mclk;          
output       [15:0] per_dout;      
output              por;           
output              puc_pnd_set;   
output              puc_rst;       
output              smclk;         
output              smclk_en;      
input               cpu_en;        
input               cpuoff;        
input               dbg_cpu_reset; 
input               dbg_en;        
input               dco_clk;       
input               lfxt_clk;      
input               mclk_enable;   
input               mclk_wkup;     
input               oscoff;        
input        [13:0] per_addr;      
input        [15:0] per_din;       
input               per_en;        
input         [1:0] per_we;        
input               reset_n;       
input               scan_enable;   
input               scan_mode;     
input               scg0;          
input               scg1;          
input               wdt_reset;     
parameter       [14:0] BASE_ADDR   = 15'h0050;
parameter              DEC_WD      =  4;
parameter [DEC_WD-1:0] BCSCTL1     =  'h7,
                       BCSCTL2     =  'h8;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] BCSCTL1_D   = (BASE_REG << BCSCTL1),
                       BCSCTL2_D   = (BASE_REG << BCSCTL2);
wire nodiv_mclk;
wire nodiv_mclk_n;
wire nodiv_smclk;
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};
wire [DEC_SZ-1:0] reg_dec      = (BCSCTL1_D  &  {DEC_SZ{(reg_addr==(BCSCTL1 >>1))}}) |
                                 (BCSCTL2_D  &  {DEC_SZ{(reg_addr==(BCSCTL2 >>1))}});
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}};
reg  [7:0] bcsctl1;
wire       bcsctl1_wr  = BCSCTL1[0] ? reg_hi_wr[BCSCTL1] : reg_lo_wr[BCSCTL1];
wire [7:0] bcsctl1_nxt = BCSCTL1[0] ? per_din[15:8]      : per_din[7:0];
wire [7:0] divax_mask = 8'h30;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)          bcsctl1  <=  8'h00;
  else if (bcsctl1_wr)  bcsctl1  <=  bcsctl1_nxt & divax_mask;  
reg  [7:0] bcsctl2;
wire       bcsctl2_wr    = BCSCTL2[0] ? reg_hi_wr[BCSCTL2] : reg_lo_wr[BCSCTL2];
wire [7:0] bcsctl2_nxt   = BCSCTL2[0] ? per_din[15:8]      : per_din[7:0];
wire [7:0] selmx_mask = 8'h00;
wire [7:0] divmx_mask = 8'h00;
wire [7:0] sels_mask  = 8'h08;
wire [7:0] divsx_mask = 8'h06;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)          bcsctl2  <=  8'h00;
  else if (bcsctl2_wr)  bcsctl2  <=  bcsctl2_nxt & ( sels_mask  | divsx_mask |
                                                     selmx_mask | divmx_mask);  
wire [15:0] bcsctl1_rd   = {8'h00, (bcsctl1  & {8{reg_rd[BCSCTL1]}})}  << (8 & {4{BCSCTL1[0]}});
wire [15:0] bcsctl2_rd   = {8'h00, (bcsctl2  & {8{reg_rd[BCSCTL2]}})}  << (8 & {4{BCSCTL2[0]}});
wire [15:0] per_dout =  bcsctl1_rd   |
                        bcsctl2_rd;
wire por_a;
wire dco_wkup;
wire cpu_en_wkup;
   assign dco_enable    = 1'b1;
   assign dco_wkup      = 1'b1;
wire lfxt_clk_s;
omsp_sync_cell sync_cell_lfxt_clk (
    .data_out  (lfxt_clk_s),
    .data_in   (lfxt_clk),
    .clk       (mclk),
    .rst       (por)
);
reg  lfxt_clk_dly;
always @ (posedge mclk or posedge por)
  if (por) lfxt_clk_dly <=  1'b0;
  else     lfxt_clk_dly <=  lfxt_clk_s;    
wire   lfxt_clk_en = (lfxt_clk_s & ~lfxt_clk_dly) & ~(oscoff & ~bcsctl2[3]);
assign lfxt_enable = 1'b1;
assign lfxt_wkup   = 1'b0;
   assign cpu_en_s    = cpu_en;
   assign cpu_en_wkup = 1'b0;
   wire   cpu_en_aux_s    = cpu_en_s;
assign nodiv_mclk   =  dco_clk;
assign nodiv_mclk_n = ~nodiv_mclk;
wire mclk_wkup_s;
   assign mclk_wkup_s = 1'b0;
wire mclk_active = 1'b1;
  wire  mclk_div_en = mclk_active;
   assign mclk   = nodiv_mclk;
  reg       aclk_en;
  reg [2:0] aclk_div;
  wire      aclk_en_nxt =  lfxt_clk_en & ((bcsctl1[5:4]==2'b00) ?  1'b1          :
                                          (bcsctl1[5:4]==2'b01) ?  aclk_div[0]   :
                                          (bcsctl1[5:4]==2'b10) ? &aclk_div[1:0] :
                                                                     &aclk_div[2:0]);
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)                                     aclk_div <=  3'h0;
    else if ((bcsctl1[5:4]!=2'b00) & lfxt_clk_en) aclk_div <=  aclk_div+3'h1;
  always @ (posedge mclk or posedge puc_rst)
    if (puc_rst)  aclk_en <=  1'b0;
    else          aclk_en <=  aclk_en_nxt & cpu_en_s;
  assign  aclk   = mclk;
assign nodiv_smclk = dco_clk;
reg       smclk_en;
reg [2:0] smclk_div;
wire      smclk_in     = ~scg1 & (bcsctl2[3] ? lfxt_clk_en : 1'b1);
wire      smclk_en_nxt = smclk_in & ((bcsctl2[2:1]==2'b00) ?  1'b1           :
                                     (bcsctl2[2:1]==2'b01) ?  smclk_div[0]   :
                                     (bcsctl2[2:1]==2'b10) ? &smclk_div[1:0] :
                                                                &smclk_div[2:0]);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  smclk_en <=  1'b0;
  else          smclk_en <=  smclk_en_nxt & cpu_en_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                                  smclk_div <=  3'h0;
  else if ((bcsctl2[2:1]!=2'b00) & smclk_in) smclk_div <=  smclk_div+3'h1;
wire  smclk  = mclk;
    assign dbg_en_s    =  dbg_en;
    wire   dbg_rst_nxt = ~dbg_en;
     assign dbg_clk = dco_clk;
assign    por_a         =  !reset_n;
wire      por_noscan;
omsp_sync_reset sync_reset_por (
    .rst_s        (por_noscan),
    .clk          (nodiv_mclk),
    .rst_a        (por_a)
);
 assign por = por_noscan;
reg  dbg_rst_noscan;
always @ (posedge mclk or posedge por)
  if (por)  dbg_rst_noscan <=  1'b1;
  else      dbg_rst_noscan <=  dbg_rst_nxt;
   assign dbg_rst = dbg_rst_noscan;
wire puc_noscan_n;
wire puc_a_scan;
wire puc_a = por | wdt_reset;
wire puc_s = dbg_cpu_reset |                               
            (dbg_en_s & dbg_rst_noscan & ~puc_noscan_n);   
  assign puc_a_scan = puc_a;
omsp_sync_cell sync_cell_puc (
    .data_out  (puc_noscan_n),
    .data_in   (~puc_s),
    .clk       (mclk),
    .rst       (puc_a_scan)
);
  assign puc_rst = ~puc_noscan_n;
assign puc_pnd_set = ~puc_noscan_n;
endmodule  
module  omsp_clock_mux (
    clk_out,                    
    clk_in0,                    
    clk_in1,                    
    reset,                      
    scan_mode,                  
    select                      
);
output         clk_out;         
input          clk_in0;         
input          clk_in1;         
input          reset;           
input          scan_mode;       
input          select;          
wire in0_select;
reg  in0_select_s;
reg  in0_select_ss;
wire in0_enable;
wire in1_select;
reg  in1_select_s;
reg  in1_select_ss;
wire in1_enable;
wire clk_in0_inv;
wire clk_in1_inv;
wire gated_clk_in0;
wire gated_clk_in1;
assign in0_select = ~select & ~in1_select_ss;
always @ (posedge clk_in0_inv or posedge reset)
  if (reset) in0_select_s  <=  1'b1;
  else       in0_select_s  <=  in0_select;
always @ (posedge clk_in0     or posedge reset)
  if (reset) in0_select_ss <=  1'b1;
  else       in0_select_ss <=  in0_select_s;
assign in0_enable = in0_select_ss | scan_mode;
assign in1_select =  select & ~in0_select_ss;
always @ (posedge clk_in1_inv or posedge reset)
  if (reset) in1_select_s  <=  1'b0;
  else       in1_select_s  <=  in1_select;
always @ (posedge clk_in1     or posedge reset)
  if (reset) in1_select_ss <=  1'b0;
  else       in1_select_ss <=  in1_select_s;
assign in1_enable = in1_select_ss & ~scan_mode;
assign clk_in0_inv   = ~clk_in0;
assign clk_in1_inv   = ~clk_in1;
assign gated_clk_in0 = ~(clk_in0_inv & in0_enable);
assign gated_clk_in1 = ~(clk_in1_inv & in1_enable);
assign clk_out       =  (gated_clk_in0 & gated_clk_in1);
endmodule  
module  omsp_dbg (
    dbg_cpu_reset,                      
    dbg_freeze,                         
    dbg_halt_cmd,                       
    dbg_i2c_sda_out,                    
    dbg_mem_addr,                       
    dbg_mem_dout,                       
    dbg_mem_en,                         
    dbg_mem_wr,                         
    dbg_reg_wr,                         
    dbg_uart_txd,                       
    cpu_en_s,                           
    cpu_id,                             
    cpu_nr_inst,                        
    cpu_nr_total,                       
    dbg_clk,                            
    dbg_en_s,                           
    dbg_halt_st,                        
    dbg_i2c_addr,                       
    dbg_i2c_broadcast,                  
    dbg_i2c_scl,                        
    dbg_i2c_sda_in,                     
    dbg_mem_din,                        
    dbg_reg_din,                        
    dbg_rst,                            
    dbg_uart_rxd,                       
    decode_noirq,                       
    eu_mab,                             
    eu_mb_en,                           
    eu_mb_wr,                           
    fe_mdb_in,                          
    pc,                                 
    puc_pnd_set                         
);
output              dbg_cpu_reset;      
output              dbg_freeze;         
output              dbg_halt_cmd;       
output              dbg_i2c_sda_out;    
output       [15:0] dbg_mem_addr;       
output       [15:0] dbg_mem_dout;       
output              dbg_mem_en;         
output        [1:0] dbg_mem_wr;         
output              dbg_reg_wr;         
output              dbg_uart_txd;       
input               cpu_en_s;           
input        [31:0] cpu_id;             
input         [7:0] cpu_nr_inst;        
input         [7:0] cpu_nr_total;       
input               dbg_clk;            
input               dbg_en_s;           
input               dbg_halt_st;        
input         [6:0] dbg_i2c_addr;       
input         [6:0] dbg_i2c_broadcast;  
input               dbg_i2c_scl;        
input               dbg_i2c_sda_in;     
input        [15:0] dbg_mem_din;        
input        [15:0] dbg_reg_din;        
input               dbg_rst;            
input               dbg_uart_rxd;       
input               decode_noirq;       
input        [15:0] eu_mab;             
input               eu_mb_en;           
input         [1:0] eu_mb_wr;           
input        [15:0] fe_mdb_in;          
input        [15:0] pc;                 
input               puc_pnd_set;        
wire  [5:0] dbg_addr;
wire [15:0] dbg_din;
wire        dbg_wr;
reg 	    mem_burst;
wire        dbg_reg_rd;
wire        dbg_mem_rd;
reg         dbg_mem_rd_dly;
wire        dbg_swbrk;
wire        dbg_rd;
reg         dbg_rd_rdy;
wire        mem_burst_rd;
wire        mem_burst_wr;
wire        brk0_halt;
wire        brk0_pnd;
wire [15:0] brk0_dout;
wire        brk1_halt;
wire        brk1_pnd;
wire [15:0] brk1_dout;
wire        brk2_halt;
wire        brk2_pnd;
wire [15:0] brk2_dout;
wire        brk3_halt;
wire        brk3_pnd;
wire [15:0] brk3_dout;
parameter           NR_REG       = 25;
parameter           CPU_ID_LO    = 6'h00;
parameter           CPU_ID_HI    = 6'h01;
parameter           CPU_CTL      = 6'h02;
parameter           CPU_STAT     = 6'h03;
parameter           MEM_CTL      = 6'h04;
parameter           MEM_ADDR     = 6'h05;
parameter           MEM_DATA     = 6'h06;
parameter           MEM_CNT      = 6'h07;
parameter           CPU_NR       = 6'h18;
parameter           BASE_D       = {{NR_REG-1{1'b0}}, 1'b1};
parameter           CPU_ID_LO_D  = (BASE_D << CPU_ID_LO);
parameter           CPU_ID_HI_D  = (BASE_D << CPU_ID_HI);
parameter           CPU_CTL_D    = (BASE_D << CPU_CTL);
parameter           CPU_STAT_D   = (BASE_D << CPU_STAT);
parameter           MEM_CTL_D    = (BASE_D << MEM_CTL);
parameter           MEM_ADDR_D   = (BASE_D << MEM_ADDR);
parameter           MEM_DATA_D   = (BASE_D << MEM_DATA);
parameter           MEM_CNT_D    = (BASE_D << MEM_CNT);
parameter           CPU_NR_D     = (BASE_D << CPU_NR);
wire  [5:0] dbg_addr_in = mem_burst ? MEM_DATA : dbg_addr;
reg  [NR_REG-1:0]  reg_dec; 
always @(dbg_addr_in)
  case (dbg_addr_in)
    CPU_ID_LO :  reg_dec  =  CPU_ID_LO_D;
    CPU_ID_HI :  reg_dec  =  CPU_ID_HI_D;
    CPU_CTL   :  reg_dec  =  CPU_CTL_D;
    CPU_STAT  :  reg_dec  =  CPU_STAT_D;
    MEM_CTL   :  reg_dec  =  MEM_CTL_D;
    MEM_ADDR  :  reg_dec  =  MEM_ADDR_D;
    MEM_DATA  :  reg_dec  =  MEM_DATA_D;
    MEM_CNT   :  reg_dec  =  MEM_CNT_D;
    CPU_NR    :  reg_dec  =  CPU_NR_D;
    default:     reg_dec  =  {NR_REG{1'b0}};
  endcase
wire               reg_write =  dbg_wr;
wire               reg_read  =  1'b1;
wire  [NR_REG-1:0] reg_wr    = reg_dec & {NR_REG{reg_write}};
wire  [NR_REG-1:0] reg_rd    = reg_dec & {NR_REG{reg_read}};
wire [15:0] cpu_nr = {cpu_nr_total, cpu_nr_inst};
reg   [6:3] cpu_ctl;
wire        cpu_ctl_wr = reg_wr[CPU_CTL];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)         cpu_ctl <=  4'h6;
  else if (cpu_ctl_wr) cpu_ctl <=  dbg_din[6:3];
wire  [7:0] cpu_ctl_full = {1'b0, cpu_ctl, 3'b000};
wire        halt_cpu = cpu_ctl_wr & dbg_din[0]  & ~dbg_halt_st;
wire        run_cpu  = cpu_ctl_wr & dbg_din[1]   &  dbg_halt_st;
wire        istep    = cpu_ctl_wr & dbg_din[2] &  dbg_halt_st;
reg   [3:2] cpu_stat;
wire        cpu_stat_wr  = reg_wr[CPU_STAT];
wire  [3:2] cpu_stat_set = {dbg_swbrk, puc_pnd_set};
wire  [3:2] cpu_stat_clr = ~dbg_din[3:2];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)          cpu_stat <=  2'b00;
  else if (cpu_stat_wr) cpu_stat <= ((cpu_stat & cpu_stat_clr) | cpu_stat_set);
  else                  cpu_stat <=  (cpu_stat                 | cpu_stat_set);
wire  [7:0] cpu_stat_full = {brk3_pnd, brk2_pnd, brk1_pnd, brk0_pnd,
                             cpu_stat, 1'b0, dbg_halt_st};
reg   [3:1] mem_ctl;
wire        mem_ctl_wr = reg_wr[MEM_CTL];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)         mem_ctl <=  3'h0;
  else if (mem_ctl_wr) mem_ctl <=  dbg_din[3:1];
wire  [7:0] mem_ctl_full  = {4'b0000, mem_ctl, 1'b0};
reg         mem_start;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)  mem_start <=  1'b0;
  else          mem_start <=  mem_ctl_wr & dbg_din[0];
wire        mem_bw    = mem_ctl[3];
reg  [15:0] mem_data;
reg  [15:0] mem_addr;
wire        mem_access;
wire        mem_data_wr = reg_wr[MEM_DATA];
wire [15:0] dbg_mem_din_bw = ~mem_bw      ? dbg_mem_din                :
	                      mem_addr[0] ? {8'h00, dbg_mem_din[15:8]} :
	                                    {8'h00, dbg_mem_din[7:0]};
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)             mem_data <=  16'h0000;
  else if (mem_data_wr)    mem_data <=  dbg_din;
  else if (dbg_reg_rd)     mem_data <=  dbg_reg_din;
  else if (dbg_mem_rd_dly) mem_data <=  dbg_mem_din_bw;
reg  [15:0] mem_cnt;
wire        mem_addr_wr  = reg_wr[MEM_ADDR];
wire        dbg_mem_acc  = (|dbg_mem_wr | (dbg_rd_rdy & ~mem_ctl[2]));
wire        dbg_reg_acc  = ( dbg_reg_wr | (dbg_rd_rdy &  mem_ctl[2]));
wire [15:0] mem_addr_inc = (mem_cnt==16'h0000)                       ? 16'h0000 : 
                           (mem_burst &  dbg_mem_acc & ~mem_bw)      ? 16'h0002 : 
                           (mem_burst & (dbg_mem_acc | dbg_reg_acc)) ? 16'h0001 : 16'h0000; 
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)          mem_addr <=  16'h0000;
  else if (mem_addr_wr) mem_addr <=  dbg_din;
  else                  mem_addr <=  mem_addr + mem_addr_inc;
wire        mem_cnt_wr  = reg_wr[MEM_CNT];
wire [15:0] mem_cnt_dec = (mem_cnt==16'h0000)                       ? 16'h0000 :
                          (mem_burst & (dbg_mem_acc | dbg_reg_acc)) ? 16'hffff : 16'h0000;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)         mem_cnt <=  16'h0000;
  else if (mem_cnt_wr) mem_cnt <=  dbg_din;
  else                 mem_cnt <=  mem_cnt + mem_cnt_dec;
assign brk0_halt =  1'b0;
assign brk0_pnd  =  1'b0;
assign brk0_dout = 16'h0000;
assign brk1_halt =  1'b0;
assign brk1_pnd  =  1'b0;
assign brk1_dout = 16'h0000;
assign brk2_halt =  1'b0;
assign brk2_pnd  =  1'b0;
assign brk2_dout = 16'h0000;
assign brk3_halt =  1'b0;
assign brk3_pnd  =  1'b0;
assign brk3_dout = 16'h0000;
wire [15:0] cpu_id_lo_rd = cpu_id[15:0]           & {16{reg_rd[CPU_ID_LO]}};
wire [15:0] cpu_id_hi_rd = cpu_id[31:16]          & {16{reg_rd[CPU_ID_HI]}};
wire [15:0] cpu_ctl_rd   = {8'h00, cpu_ctl_full}  & {16{reg_rd[CPU_CTL]}};
wire [15:0] cpu_stat_rd  = {8'h00, cpu_stat_full} & {16{reg_rd[CPU_STAT]}};
wire [15:0] mem_ctl_rd   = {8'h00, mem_ctl_full}  & {16{reg_rd[MEM_CTL]}};
wire [15:0] mem_data_rd  = mem_data               & {16{reg_rd[MEM_DATA]}};
wire [15:0] mem_addr_rd  = mem_addr               & {16{reg_rd[MEM_ADDR]}};
wire [15:0] mem_cnt_rd   = mem_cnt                & {16{reg_rd[MEM_CNT]}};
wire [15:0] cpu_nr_rd    = cpu_nr                 & {16{reg_rd[CPU_NR]}};
wire [15:0] dbg_dout = cpu_id_lo_rd |
                       cpu_id_hi_rd |
                       cpu_ctl_rd   |
                       cpu_stat_rd  |
                       mem_ctl_rd   |
                       mem_data_rd  |
                       mem_addr_rd  |
                       mem_cnt_rd   |
                       brk0_dout    |
                       brk1_dout    |
                       brk2_dout    |
                       brk3_dout    |
                       cpu_nr_rd;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                       dbg_rd_rdy  <=  1'b0;
  else if (mem_burst | mem_burst_rd) dbg_rd_rdy  <= (dbg_reg_rd | dbg_mem_rd_dly);
  else                               dbg_rd_rdy  <=  dbg_rd;
wire dbg_cpu_reset  = cpu_ctl[6];
wire halt_rst = cpu_ctl[5] & dbg_en_s & puc_pnd_set;
wire dbg_freeze = dbg_halt_st & (cpu_ctl[4] | ~cpu_en_s);
assign dbg_swbrk = (fe_mdb_in==16'h4343) & decode_noirq & cpu_ctl[3];
reg [1:0] inc_step;
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)    inc_step <= 2'b00;
  else if (istep) inc_step <= 2'b11;
  else            inc_step <= {inc_step[0], 1'b0};
reg   halt_flag;
wire  mem_halt_cpu;
wire  mem_run_cpu;
wire  halt_flag_clr = run_cpu   | mem_run_cpu;
wire  halt_flag_set = halt_cpu  | halt_rst  | dbg_swbrk | mem_halt_cpu |
                      brk0_halt | brk1_halt | brk2_halt | brk3_halt;
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)            halt_flag <= 1'b0;
  else if (halt_flag_clr) halt_flag <= 1'b0;
  else if (halt_flag_set) halt_flag <= 1'b1;
wire dbg_halt_cmd = (halt_flag | halt_flag_set) & ~inc_step[1];
wire mem_burst_start = (mem_start             &  |mem_cnt);
wire mem_burst_end   = ((dbg_wr | dbg_rd_rdy) & ~|mem_cnt);
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)              mem_burst <= 1'b0;
  else if (mem_burst_start) mem_burst <= 1'b1;
  else if (mem_burst_end)   mem_burst <= 1'b0;
assign mem_burst_rd = (mem_burst_start & ~mem_ctl[1]);
assign mem_burst_wr = (mem_burst_start &  mem_ctl[1]);
reg        mem_startb;   
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) mem_startb <= 1'b0;
  else         mem_startb <= (mem_burst & (dbg_wr | dbg_rd)) | mem_burst_rd;
wire       mem_seq_start = ((mem_start & ~|mem_cnt) | mem_startb);
reg  [1:0] mem_state;
reg  [1:0] mem_state_nxt;
parameter  M_IDLE       = 2'h0;
parameter  M_SET_BRK    = 2'h1;
parameter  M_ACCESS_BRK = 2'h2;
parameter  M_ACCESS     = 2'h3;
always @(mem_state or mem_seq_start or dbg_halt_st)
  case (mem_state)
    M_IDLE       : mem_state_nxt = ~mem_seq_start ? M_IDLE       : 
                                    dbg_halt_st   ? M_ACCESS     : M_SET_BRK;
    M_SET_BRK    : mem_state_nxt =  dbg_halt_st   ? M_ACCESS_BRK : M_SET_BRK;
    M_ACCESS_BRK : mem_state_nxt =  M_IDLE;
    M_ACCESS     : mem_state_nxt =  M_IDLE;
    default      : mem_state_nxt =  M_IDLE;
  endcase
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) mem_state <= M_IDLE;
  else         mem_state <= mem_state_nxt;
assign mem_halt_cpu = (mem_state==M_IDLE)       & (mem_state_nxt==M_SET_BRK);
assign mem_run_cpu  = (mem_state==M_ACCESS_BRK) & (mem_state_nxt==M_IDLE);
assign mem_access   = (mem_state==M_ACCESS)     | (mem_state==M_ACCESS_BRK);
assign      dbg_mem_addr   =  mem_addr;
assign      dbg_mem_dout   = ~mem_bw      ? mem_data               :
                              mem_addr[0] ? {mem_data[7:0], 8'h00} :
                                            {8'h00, mem_data[7:0]};
assign      dbg_reg_wr     = mem_access &  mem_ctl[1] &  mem_ctl[2];
assign      dbg_reg_rd     = mem_access & ~mem_ctl[1] &  mem_ctl[2];
assign      dbg_mem_en     = mem_access & ~mem_ctl[2];
assign      dbg_mem_rd     = dbg_mem_en & ~mem_ctl[1];
wire  [1:0] dbg_mem_wr_msk = ~mem_bw      ? 2'b11 :
                              mem_addr[0] ? 2'b10 : 2'b01;
assign      dbg_mem_wr     = {2{dbg_mem_en & mem_ctl[1]}} & dbg_mem_wr_msk;
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) dbg_mem_rd_dly <= 1'b0;
  else         dbg_mem_rd_dly <= dbg_mem_rd;
omsp_dbg_uart dbg_uart_0 (
    .dbg_addr         (dbg_addr),          
    .dbg_din          (dbg_din),           
    .dbg_rd           (dbg_rd),            
    .dbg_uart_txd     (dbg_uart_txd),      
    .dbg_wr           (dbg_wr),            
    .dbg_clk          (dbg_clk),           
    .dbg_dout         (dbg_dout),          
    .dbg_rd_rdy       (dbg_rd_rdy),        
    .dbg_rst          (dbg_rst),           
    .dbg_uart_rxd     (dbg_uart_rxd),      
    .mem_burst        (mem_burst),         
    .mem_burst_end    (mem_burst_end),     
    .mem_burst_rd     (mem_burst_rd),      
    .mem_burst_wr     (mem_burst_wr),      
    .mem_bw           (mem_bw)             
);
    assign dbg_i2c_sda_out =  1'b1;
endmodule  
module  omsp_dbg_hwbrk (
    brk_halt,                 
    brk_pnd,                  
    brk_dout,                 
    brk_reg_rd,               
    brk_reg_wr,               
    dbg_clk,                  
    dbg_din,                  
    dbg_rst,                  
    decode_noirq,             
    eu_mab,                   
    eu_mb_en,                 
    eu_mb_wr,                 
    pc                        
);
output         brk_halt;      
output         brk_pnd;       
output  [15:0] brk_dout;      
input    [3:0] brk_reg_rd;    
input    [3:0] brk_reg_wr;    
input          dbg_clk;       
input   [15:0] dbg_din;       
input          dbg_rst;       
input          decode_noirq;  
input   [15:0] eu_mab;        
input          eu_mb_en;      
input    [1:0] eu_mb_wr;      
input   [15:0] pc;            
wire      range_wr_set;
wire      range_rd_set;
wire      addr1_wr_set;
wire      addr1_rd_set;
wire      addr0_wr_set;
wire      addr0_rd_set;
parameter BRK_CTL   = 0,
          BRK_STAT  = 1,
          BRK_ADDR0 = 2,
          BRK_ADDR1 = 3;
reg   [4:0] brk_ctl;
wire        brk_ctl_wr = brk_reg_wr[BRK_CTL];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)         brk_ctl <=  5'h00;
  else if (brk_ctl_wr) brk_ctl <=  {1'b0 & dbg_din[4], dbg_din[3:0]};
wire  [7:0] brk_ctl_full = {3'b000, brk_ctl};
reg   [5:0] brk_stat;
wire        brk_stat_wr  = brk_reg_wr[BRK_STAT];
wire  [5:0] brk_stat_set = {range_wr_set & 1'b0,
                            range_rd_set & 1'b0,
			    addr1_wr_set, addr1_rd_set,
			    addr0_wr_set, addr0_rd_set};
wire  [5:0] brk_stat_clr = ~dbg_din[5:0];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)          brk_stat <=  6'h00;
  else if (brk_stat_wr) brk_stat <= ((brk_stat & brk_stat_clr) | brk_stat_set);
  else                  brk_stat <=  (brk_stat                 | brk_stat_set);
wire  [7:0] brk_stat_full = {2'b00, brk_stat};
wire        brk_pnd       = |brk_stat;
reg  [15:0] brk_addr0;
wire        brk_addr0_wr = brk_reg_wr[BRK_ADDR0];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)           brk_addr0 <=  16'h0000;
  else if (brk_addr0_wr) brk_addr0 <=  dbg_din;
reg  [15:0] brk_addr1;
wire        brk_addr1_wr = brk_reg_wr[BRK_ADDR1];
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)           brk_addr1 <=  16'h0000;
  else if (brk_addr1_wr) brk_addr1 <=  dbg_din;
wire [15:0] brk_ctl_rd   = {8'h00, brk_ctl_full}  & {16{brk_reg_rd[BRK_CTL]}};
wire [15:0] brk_stat_rd  = {8'h00, brk_stat_full} & {16{brk_reg_rd[BRK_STAT]}};
wire [15:0] brk_addr0_rd = brk_addr0              & {16{brk_reg_rd[BRK_ADDR0]}};
wire [15:0] brk_addr1_rd = brk_addr1              & {16{brk_reg_rd[BRK_ADDR1]}};
wire [15:0] brk_dout = brk_ctl_rd   |
                       brk_stat_rd  |
                       brk_addr0_rd |
                       brk_addr1_rd;
wire        equ_d_addr0 = eu_mb_en & (eu_mab==brk_addr0) & ~brk_ctl[4];
wire        equ_d_addr1 = eu_mb_en & (eu_mab==brk_addr1) & ~brk_ctl[4];
wire        equ_d_range = eu_mb_en & ((eu_mab>=brk_addr0) & (eu_mab<=brk_addr1)) & 
                          brk_ctl[4] & 1'b0;
wire        equ_i_addr0 = decode_noirq & (pc==brk_addr0) & ~brk_ctl[4];
wire        equ_i_addr1 = decode_noirq & (pc==brk_addr1) & ~brk_ctl[4];
wire        equ_i_range = decode_noirq & ((pc>=brk_addr0) & (pc<=brk_addr1)) &
                          brk_ctl[4] & 1'b0;
wire i_addr0_rd =  equ_i_addr0 &  brk_ctl[3];
wire i_addr1_rd =  equ_i_addr1 &  brk_ctl[3];
wire i_range_rd =  equ_i_range &  brk_ctl[3];
wire d_addr0_wr =  equ_d_addr0 & ~brk_ctl[3] &  |eu_mb_wr;
wire d_addr1_wr =  equ_d_addr1 & ~brk_ctl[3] &  |eu_mb_wr;
wire d_range_wr =  equ_d_range & ~brk_ctl[3] &  |eu_mb_wr;
wire d_addr0_rd =  equ_d_addr0 & ~brk_ctl[3] & ~|eu_mb_wr;
wire d_addr1_rd =  equ_d_addr1 & ~brk_ctl[3] & ~|eu_mb_wr;
wire d_range_rd =  equ_d_range & ~brk_ctl[3] & ~|eu_mb_wr;
assign addr0_rd_set = brk_ctl[0] & (d_addr0_rd  | i_addr0_rd);
assign addr0_wr_set = brk_ctl[1] &  d_addr0_wr;
assign addr1_rd_set = brk_ctl[0] & (d_addr1_rd  | i_addr1_rd);
assign addr1_wr_set = brk_ctl[1] &  d_addr1_wr;
assign range_rd_set = brk_ctl[0] & (d_range_rd  | i_range_rd);
assign range_wr_set = brk_ctl[1] &  d_range_wr;
assign brk_halt     = brk_ctl[2] & |brk_stat_set;
endmodule  
module  omsp_dbg_i2c (
    dbg_addr,                           
    dbg_din,                            
    dbg_i2c_sda_out,                    
    dbg_rd,                             
    dbg_wr,                             
    dbg_clk,                            
    dbg_dout,                           
    dbg_i2c_addr,                       
    dbg_i2c_broadcast,                  
    dbg_i2c_scl,                        
    dbg_i2c_sda_in,                     
    dbg_rd_rdy,                         
    dbg_rst,                            
    mem_burst,                          
    mem_burst_end,                      
    mem_burst_rd,                       
    mem_burst_wr,                       
    mem_bw                              
);
output        [5:0] dbg_addr;           
output       [15:0] dbg_din;            
output              dbg_i2c_sda_out;    
output              dbg_rd;             
output              dbg_wr;             
input               dbg_clk;            
input        [15:0] dbg_dout;           
input         [6:0] dbg_i2c_addr;       
input         [6:0] dbg_i2c_broadcast;  
input               dbg_i2c_scl;        
input               dbg_i2c_sda_in;     
input               dbg_rd_rdy;         
input               dbg_rst;            
input               mem_burst;          
input               mem_burst_end;      
input               mem_burst_rd;       
input               mem_burst_wr;       
input               mem_bw;             
wire scl_sync_n;
omsp_sync_cell sync_cell_i2c_scl (
    .data_out  (scl_sync_n),
    .data_in   (~dbg_i2c_scl),
    .clk       (dbg_clk),
    .rst       (dbg_rst)
);
wire scl_sync = ~scl_sync_n;
wire sda_in_sync_n;
omsp_sync_cell sync_cell_i2c_sda (
    .data_out  (sda_in_sync_n),
    .data_in   (~dbg_i2c_sda_in),
    .clk       (dbg_clk),
    .rst       (dbg_rst)
);
wire sda_in_sync = ~sda_in_sync_n;
reg  [1:0] scl_buf;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) scl_buf <=  2'h3;
  else         scl_buf <=  {scl_buf[0], scl_sync};
reg  [1:0] sda_in_buf;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) sda_in_buf <=  2'h3;
  else         sda_in_buf <=  {sda_in_buf[0], sda_in_sync};
wire scl         =  (scl_sync      & scl_buf[0])    |
                    (scl_sync      & scl_buf[1])    |
                    (scl_buf[0]    & scl_buf[1]);
wire sda_in      =  (sda_in_sync   & sda_in_buf[0]) |
                    (sda_in_sync   & sda_in_buf[1]) |
                    (sda_in_buf[0] & sda_in_buf[1]);
reg        sda_in_dly;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) sda_in_dly <=  1'b1;
  else         sda_in_dly <=  sda_in;
wire sda_in_fe   =  sda_in_dly & ~sda_in;
wire sda_in_re   = ~sda_in_dly &  sda_in;
wire sda_in_edge =  sda_in_dly ^  sda_in;
reg        scl_dly;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) scl_dly <=  1'b1;
  else         scl_dly <=  scl;
wire scl_fe      =  scl_dly    & ~scl;
wire scl_re      = ~scl_dly    &  scl;
wire scl_edge    =  scl_dly    ^  scl;
reg  [1:0] scl_re_dly;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) scl_re_dly <=  2'b00;
  else         scl_re_dly <=  {scl_re_dly[0], scl_re};
wire scl_sample  =  scl_re_dly[1];
wire start_detect = sda_in_fe & scl;
 wire stop_detect = sda_in_re & scl;
wire i2c_addr_not_valid;
reg  i2c_active_seq;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                                 i2c_active_seq <= 1'b0;
  else if (start_detect)                       i2c_active_seq <= 1'b1;
  else if (stop_detect || i2c_addr_not_valid)  i2c_active_seq <= 1'b0;
wire i2c_active =  i2c_active_seq & ~stop_detect;
wire i2c_init   = ~i2c_active     |  start_detect;
reg   [2:0] i2c_state;
reg   [2:0] i2c_state_nxt;
reg   [8:0] shift_buf;
wire        shift_rx_done;
wire        shift_tx_done;
reg         dbg_rd;
parameter   RX_ADDR      =  3'h0;
parameter   RX_ADDR_ACK  =  3'h1;
parameter   RX_DATA      =  3'h2;
parameter   RX_DATA_ACK  =  3'h3;
parameter   TX_DATA      =  3'h4;
parameter   TX_DATA_ACK  =  3'h5;
always @(i2c_state or i2c_init or shift_rx_done or i2c_addr_not_valid or shift_tx_done or scl_fe or shift_buf or sda_in)
  case (i2c_state)
    RX_ADDR     : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~shift_rx_done      ?  RX_ADDR      :
                                    i2c_addr_not_valid ?  RX_ADDR      :
                                                          RX_ADDR_ACK;
    RX_ADDR_ACK : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~scl_fe             ?  RX_ADDR_ACK  :
                                    shift_buf[0]       ?  TX_DATA      :
                                                          RX_DATA;
    RX_DATA     : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~shift_rx_done      ?  RX_DATA      :
                                                          RX_DATA_ACK;
    RX_DATA_ACK : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~scl_fe             ?  RX_DATA_ACK  :
                                                          RX_DATA;
    TX_DATA     : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~shift_tx_done      ?  TX_DATA      :
                                                          TX_DATA_ACK;
    TX_DATA_ACK : i2c_state_nxt =   i2c_init           ?  RX_ADDR      :
                                   ~scl_fe             ?  TX_DATA_ACK  :
                                   ~sda_in             ?  TX_DATA      :
                                                          RX_ADDR;
    default     : i2c_state_nxt =                         RX_ADDR;
  endcase
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)       i2c_state <= RX_ADDR;
  else               i2c_state <= i2c_state_nxt;
wire       shift_rx_en       = ((i2c_state==RX_ADDR) | (i2c_state    ==RX_DATA) | (i2c_state    ==RX_DATA_ACK));
wire       shift_tx_en       =                         (i2c_state    ==TX_DATA) | (i2c_state    ==TX_DATA_ACK);
wire       shift_tx_en_pre   =                         (i2c_state_nxt==TX_DATA) | (i2c_state_nxt==TX_DATA_ACK);
assign     shift_rx_done     = shift_rx_en & scl_fe & shift_buf[8];
assign     shift_tx_done     = shift_tx_en & scl_fe & (shift_buf==9'h100);
wire       shift_buf_rx_init = i2c_init | ((i2c_state==RX_ADDR_ACK) & scl_fe & ~shift_buf[0]) |
                                          ((i2c_state==RX_DATA_ACK) & scl_fe);
wire       shift_buf_rx_en   = shift_rx_en     & scl_sample;
wire       shift_buf_tx_init =            ((i2c_state==RX_ADDR_ACK) & scl_re &  shift_buf[0]) |
                                          ((i2c_state==TX_DATA_ACK) & scl_re);
wire       shift_buf_tx_en   = shift_tx_en_pre & scl_fe & (shift_buf!=9'h100);
wire [7:0] shift_tx_val;
wire [8:0] shift_buf_nxt     = shift_buf_rx_init  ? 9'h001                   :  
                               shift_buf_tx_init  ? {shift_tx_val,   1'b1}   :  
                               shift_buf_rx_en    ? {shift_buf[7:0], sda_in} :  
                               shift_buf_tx_en    ? {shift_buf[7:0], 1'b0}   :  
                                                     shift_buf[8:0];            
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) shift_buf <= 9'h001;
  else         shift_buf <= shift_buf_nxt;
assign i2c_addr_not_valid =  (i2c_state == RX_ADDR) && shift_rx_done && (
                              (shift_buf[7:1] != dbg_i2c_addr[6:0]));
wire        shift_rx_data_done = shift_rx_done & (i2c_state==RX_DATA); 
wire        shift_tx_data_done = shift_tx_done; 
reg dbg_i2c_sda_out;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)     dbg_i2c_sda_out <= 1'b1;
  else if (scl_fe) dbg_i2c_sda_out <= ~((i2c_state_nxt==RX_ADDR_ACK) ||
                                        (i2c_state_nxt==RX_DATA_ACK) ||
                                       (shift_buf_tx_en & ~shift_buf[8]));
reg   [2:0] dbg_state;
reg   [2:0] dbg_state_nxt;
reg         dbg_bw;
parameter  RX_CMD     = 3'h0;
parameter  RX_BYTE_LO = 3'h1;
parameter  RX_BYTE_HI = 3'h2;
parameter  TX_BYTE_LO = 3'h3;
parameter  TX_BYTE_HI = 3'h4;
always @(dbg_state    or shift_rx_data_done or shift_tx_data_done or shift_buf     or dbg_bw or
         mem_burst_wr or mem_burst_rd       or mem_burst          or mem_burst_end or mem_bw)
  case (dbg_state)
    RX_CMD     : dbg_state_nxt =  mem_burst_wr                ? RX_BYTE_LO  :
                                  mem_burst_rd                ? TX_BYTE_LO  :
                                  ~shift_rx_data_done         ? RX_CMD      :
                                   shift_buf[7]               ? RX_BYTE_LO  :
                                                                TX_BYTE_LO;
    RX_BYTE_LO : dbg_state_nxt = (mem_burst &  mem_burst_end) ? RX_CMD      :
                                  ~shift_rx_data_done         ? RX_BYTE_LO  :
                                 (mem_burst & ~mem_burst_end) ?
                                 (mem_bw                      ? RX_BYTE_LO  :
                                                                RX_BYTE_HI) :
                                  dbg_bw                      ? RX_CMD      :
                                                                RX_BYTE_HI;
    RX_BYTE_HI : dbg_state_nxt =  ~shift_rx_data_done         ? RX_BYTE_HI  :
                                 (mem_burst & ~mem_burst_end) ? RX_BYTE_LO  :
                                                                RX_CMD;
    TX_BYTE_LO : dbg_state_nxt =  ~shift_tx_data_done         ? TX_BYTE_LO  :
                                 ( mem_burst &  mem_bw)       ? TX_BYTE_LO  :
                                 ( mem_burst & ~mem_bw)       ? TX_BYTE_HI  :
                                  ~dbg_bw                     ? TX_BYTE_HI  :
                                                                RX_CMD;
    TX_BYTE_HI : dbg_state_nxt =  ~shift_tx_data_done         ? TX_BYTE_HI  :
                                   mem_burst                  ? TX_BYTE_LO  :
                                                                RX_CMD;
    default    : dbg_state_nxt =                                RX_CMD;
  endcase
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) dbg_state <= RX_CMD;
  else         dbg_state <= dbg_state_nxt;
wire cmd_valid   = (dbg_state==RX_CMD)     & shift_rx_data_done;
wire rx_lo_valid = (dbg_state==RX_BYTE_LO) & shift_rx_data_done;
wire rx_hi_valid = (dbg_state==RX_BYTE_HI) & shift_rx_data_done;
parameter MEM_DATA = 6'h06;
reg [5:0] dbg_addr;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)
    begin
       dbg_bw   <= 1'b0;
       dbg_addr <= 6'h00;
    end
  else if (cmd_valid)
    begin
       dbg_bw   <= shift_buf[6];
       dbg_addr <= shift_buf[5:0];
    end
  else if (mem_burst)
    begin
       dbg_bw   <= mem_bw;
       dbg_addr <= MEM_DATA;
    end
reg [7:0] dbg_din_lo;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)          dbg_din_lo <= 8'h00;
  else if (rx_lo_valid) dbg_din_lo <= shift_buf[7:0];
reg [7:0] dbg_din_hi;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)          dbg_din_hi <= 8'h00;
  else if (rx_lo_valid) dbg_din_hi <= 8'h00;
  else if (rx_hi_valid) dbg_din_hi <= shift_buf[7:0];
assign dbg_din = {dbg_din_hi, dbg_din_lo};
reg  dbg_wr;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) dbg_wr <= 1'b0;
  else         dbg_wr <= (mem_burst &  mem_bw) ? rx_lo_valid :
                         (mem_burst & ~mem_bw) ? rx_hi_valid :
                         dbg_bw                ? rx_lo_valid :
                                                 rx_hi_valid;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) dbg_rd <= 1'b0;
  else         dbg_rd <= (mem_burst &  mem_bw) ? (shift_tx_data_done & (dbg_state==TX_BYTE_LO)) :
                         (mem_burst & ~mem_bw) ? (shift_tx_data_done & (dbg_state==TX_BYTE_HI)) :        
                         cmd_valid             ?  ~shift_buf[7]                                 :
                                                  1'b0;
assign shift_tx_val = (dbg_state==TX_BYTE_HI) ? dbg_dout[15:8] :
                                                dbg_dout[7:0];
endmodule
module  omsp_dbg_uart (
    dbg_addr,                        
    dbg_din,                         
    dbg_rd,                          
    dbg_uart_txd,                    
    dbg_wr,                          
    dbg_clk,                         
    dbg_dout,                        
    dbg_rd_rdy,                      
    dbg_rst,                         
    dbg_uart_rxd,                    
    mem_burst,                       
    mem_burst_end,                   
    mem_burst_rd,                    
    mem_burst_wr,                    
    mem_bw                           
);
output        [5:0] dbg_addr;        
output       [15:0] dbg_din;         
output              dbg_rd;          
output              dbg_uart_txd;    
output              dbg_wr;          
input               dbg_clk;         
input        [15:0] dbg_dout;        
input               dbg_rd_rdy;      
input               dbg_rst;         
input               dbg_uart_rxd;    
input               mem_burst;       
input               mem_burst_end;   
input               mem_burst_rd;    
input               mem_burst_wr;    
input               mem_bw;          
    wire uart_rxd_n;
    omsp_sync_cell sync_cell_uart_rxd (
        .data_out  (uart_rxd_n),
        .data_in   (~dbg_uart_rxd),
        .clk       (dbg_clk),
        .rst       (dbg_rst)
    );
    wire uart_rxd = ~uart_rxd_n;
reg  [1:0] rxd_buf;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) rxd_buf <=  2'h3;
  else         rxd_buf <=  {rxd_buf[0], uart_rxd};
reg        rxd_maj;
wire       rxd_maj_nxt = (uart_rxd   & rxd_buf[0]) |
			 (uart_rxd   & rxd_buf[1]) |
			 (rxd_buf[0] & rxd_buf[1]);
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst) rxd_maj <=  1'b1;
  else         rxd_maj <=  rxd_maj_nxt;
wire rxd_s    =  rxd_maj;
wire rxd_fe   =  rxd_maj & ~rxd_maj_nxt;
wire rxd_re   = ~rxd_maj &  rxd_maj_nxt;
wire rxd_edge =  rxd_maj ^  rxd_maj_nxt;
reg   [2:0] uart_state;
reg   [2:0] uart_state_nxt;
wire        sync_done;
wire        xfer_done;
reg  [19:0] xfer_buf;
wire [19:0] xfer_buf_nxt;
parameter  RX_SYNC  = 3'h0;
parameter  RX_CMD   = 3'h1;
parameter  RX_DATA1 = 3'h2;
parameter  RX_DATA2 = 3'h3;
parameter  TX_DATA1 = 3'h4;
parameter  TX_DATA2 = 3'h5;
always @(uart_state or xfer_buf_nxt or mem_burst or mem_burst_wr or mem_burst_rd or mem_burst_end or mem_bw)
  case (uart_state)
    RX_SYNC  : uart_state_nxt =  RX_CMD;
    RX_CMD   : uart_state_nxt =  mem_burst_wr                ?
                                (mem_bw                      ? RX_DATA2 : RX_DATA1) :
                                 mem_burst_rd                ?
                                (mem_bw                      ? TX_DATA2 : TX_DATA1) :
                                (xfer_buf_nxt[18]  ?
                                (xfer_buf_nxt[17]  ? RX_DATA2 : RX_DATA1) :
                                (xfer_buf_nxt[17]  ? TX_DATA2 : TX_DATA1));
    RX_DATA1 : uart_state_nxt =  RX_DATA2;
    RX_DATA2 : uart_state_nxt = (mem_burst & ~mem_burst_end) ?
                                (mem_bw                      ? RX_DATA2 : RX_DATA1) :
                                 RX_CMD;
    TX_DATA1 : uart_state_nxt =  TX_DATA2;
    TX_DATA2 : uart_state_nxt = (mem_burst & ~mem_burst_end) ?
                                (mem_bw                      ? TX_DATA2 : TX_DATA1) :
                                 RX_CMD;
    default  : uart_state_nxt =  RX_CMD;
  endcase
always @(posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                          uart_state <= RX_SYNC;
  else if (xfer_done    | sync_done |
           mem_burst_wr | mem_burst_rd) uart_state <= uart_state_nxt;
wire cmd_valid = (uart_state==RX_CMD) & xfer_done;
wire rx_active = (uart_state==RX_DATA1) | (uart_state==RX_DATA2) | (uart_state==RX_CMD);
wire tx_active = (uart_state==TX_DATA1) | (uart_state==TX_DATA2);
reg        sync_busy;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                             sync_busy <=  1'b0;
  else if ((uart_state==RX_SYNC) & rxd_fe) sync_busy <=  1'b1;
  else if ((uart_state==RX_SYNC) & rxd_re) sync_busy <=  1'b0;
assign sync_done =  (uart_state==RX_SYNC) & rxd_re & sync_busy;
reg [16+2:0] sync_cnt;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                                     sync_cnt <=  {{16{1'b1}}, 3'b000};
  else if (sync_busy | (~sync_busy & sync_cnt[2])) sync_cnt <=  sync_cnt+{{16+2{1'b0}}, 1'b1};
wire [16-1:0] bit_cnt_max = sync_cnt[16+2:3];
reg                      [3:0] xfer_bit;
reg [16-1:0] xfer_cnt;
wire       txd_start    = dbg_rd_rdy | (xfer_done & (uart_state==TX_DATA1));
wire       rxd_start    = (xfer_bit==4'h0) & rxd_fe & ((uart_state!=RX_SYNC));
wire       xfer_bit_inc = (xfer_bit!=4'h0) & (xfer_cnt=={16{1'b0}});
assign     xfer_done    = rx_active ? (xfer_bit==4'ha) : (xfer_bit==4'hb);
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                       xfer_bit <=  4'h0;
  else if (txd_start | rxd_start)    xfer_bit <=  4'h1;
  else if (xfer_done)                xfer_bit <=  4'h0;
  else if (xfer_bit_inc)             xfer_bit <=  xfer_bit+4'h1;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                       xfer_cnt <=  {16{1'b0}};
  else if (rx_active & rxd_edge)     xfer_cnt <=  {1'b0, bit_cnt_max[16-1:1]};
  else if (txd_start | xfer_bit_inc) xfer_cnt <=  bit_cnt_max;
  else if (|xfer_cnt)                xfer_cnt <=  xfer_cnt+{16{1'b1}};
assign xfer_buf_nxt =  {rxd_s, xfer_buf[19:1]};
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)           xfer_buf <=  20'h00000;
  else if (dbg_rd_rdy)   xfer_buf <=  {1'b1, dbg_dout[15:8], 2'b01, dbg_dout[7:0], 1'b0};
  else if (xfer_bit_inc) xfer_buf <=  xfer_buf_nxt;
reg dbg_uart_txd;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)                       dbg_uart_txd <=  1'b1;
  else if (xfer_bit_inc & tx_active) dbg_uart_txd <=  xfer_buf[0];
reg [5:0] dbg_addr;
 always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)        dbg_addr <=  6'h00;
  else if (cmd_valid) dbg_addr <=  xfer_buf_nxt[16:11];
reg       dbg_bw;
always @ (posedge dbg_clk or posedge dbg_rst)
  if (dbg_rst)        dbg_bw   <=  1'b0;
  else if (cmd_valid) dbg_bw   <=  xfer_buf_nxt[17];
wire        dbg_din_bw =  mem_burst  ? mem_bw : dbg_bw;
wire [15:0] dbg_din    =  dbg_din_bw ? {8'h00,           xfer_buf_nxt[18:11]} :
                                       {xfer_buf_nxt[18:11], xfer_buf_nxt[9:2]};
wire        dbg_wr     = (xfer_done & (uart_state==RX_DATA2));
wire        dbg_rd     = mem_burst ? (xfer_done & (uart_state==TX_DATA2)) :
                                     (cmd_valid & ~xfer_buf_nxt[18]) | mem_burst_rd;
endmodule  
module  omsp_execution_unit (
    cpuoff,                         
    dbg_reg_din,                    
    gie,                            
    mab,                            
    mb_en,                          
    mb_wr,                          
    mdb_out,                        
    oscoff,                         
    pc_sw,                          
    pc_sw_wr,                       
    scg0,                           
    scg1,                           
    dbg_halt_st,                    
    dbg_mem_dout,                   
    dbg_reg_wr,                     
    e_state,                        
    exec_done,                      
    inst_ad,                        
    inst_as,                        
    inst_alu,                       
    inst_bw,                        
    inst_dest,                      
    inst_dext,                      
    inst_irq_rst,                   
    inst_jmp,                       
    inst_mov,                       
    inst_sext,                      
    inst_so,                        
    inst_src,                       
    inst_type,                      
    mclk,                           
    mdb_in,                         
    pc,                             
    pc_nxt,                         
    puc_rst,                        
    scan_enable                     
);
output 	            cpuoff;         
output       [15:0] dbg_reg_din;    
output 	            gie;            
output       [15:0] mab;            
output              mb_en;          
output        [1:0] mb_wr;          
output       [15:0] mdb_out;        
output 	            oscoff;         
output       [15:0] pc_sw;          
output              pc_sw_wr;       
output              scg0;           
output              scg1;           
input               dbg_halt_st;    
input        [15:0] dbg_mem_dout;   
input               dbg_reg_wr;     
input         [3:0] e_state;        
input               exec_done;      
input         [7:0] inst_ad;        
input         [7:0] inst_as;        
input        [11:0] inst_alu;       
input               inst_bw;        
input        [15:0] inst_dest;      
input        [15:0] inst_dext;      
input               inst_irq_rst;   
input         [7:0] inst_jmp;       
input               inst_mov;       
input        [15:0] inst_sext;      
input         [7:0] inst_so;        
input        [15:0] inst_src;       
input         [2:0] inst_type;      
input               mclk;           
input        [15:0] mdb_in;         
input        [15:0] pc;             
input        [15:0] pc_nxt;         
input               puc_rst;        
input               scan_enable;    
wire         [15:0] alu_out;
wire         [15:0] alu_out_add;
wire          [3:0] alu_stat;
wire          [3:0] alu_stat_wr;
wire         [15:0] op_dst;
wire         [15:0] op_src;
wire         [15:0] reg_dest;
wire         [15:0] reg_src;
wire         [15:0] mdb_in_bw;
wire         [15:0] mdb_in_val;
wire          [3:0] status;
wire reg_dest_wr  = ((e_state==4'hB) & (
                     (inst_type[2] & inst_ad[0] & ~inst_alu[11])  |
                     (inst_type[0] & inst_as[0] & ~(inst_so[4] | inst_so[5] | inst_so[6])) |
                      inst_type[1])) | dbg_reg_wr;
wire reg_sp_wr    = (((e_state==4'h1) | (e_state==4'h3)) & ~inst_irq_rst) |
                     ((e_state==4'h9) & ((inst_so[4] | inst_so[5]) &  ~inst_as[1] & ~((inst_as[2] | inst_as[3]) & inst_src[1]))) |
                     ((e_state==4'h5) & ((inst_so[4] | inst_so[5]) &  inst_as[1])) |
                     ((e_state==4'h6) & ((inst_so[4] | inst_so[5]) &  ((inst_as[2] | inst_as[3]) & inst_src[1])));
wire reg_sr_wr    =  (e_state==4'h9) & inst_so[6];
wire reg_sr_clr   =  (e_state==4'h0);
wire reg_pc_call  = ((e_state==4'hB)   & inst_so[5]) | 
                    ((e_state==4'hA) & inst_so[6]);
wire reg_incr     =  (exec_done          & inst_as[3]) |
                    ((e_state==4'h6) & inst_so[6])    |
                    ((e_state==4'hB)   & inst_so[6]);
assign dbg_reg_din = reg_dest;
omsp_register_file register_file_0 (
    .cpuoff       (cpuoff),        
    .gie          (gie),           
    .oscoff       (oscoff),        
    .pc_sw        (pc_sw),         
    .pc_sw_wr     (pc_sw_wr),      
    .reg_dest     (reg_dest),      
    .reg_src      (reg_src),       
    .scg0         (scg0),          
    .scg1         (scg1),          
    .status       (status),        
    .alu_stat     (alu_stat),      
    .alu_stat_wr  (alu_stat_wr),   
    .inst_bw      (inst_bw),       
    .inst_dest    (inst_dest),     
    .inst_src     (inst_src),      
    .mclk         (mclk),          
    .pc           (pc),            
    .puc_rst      (puc_rst),       
    .reg_dest_val (alu_out),       
    .reg_dest_wr  (reg_dest_wr),   
    .reg_pc_call  (reg_pc_call),   
    .reg_sp_val   (alu_out_add),   
    .reg_sp_wr    (reg_sp_wr),     
    .reg_sr_clr   (reg_sr_clr),    
    .reg_sr_wr    (reg_sr_wr),     
    .reg_incr     (reg_incr),      
    .scan_enable  (scan_enable)    
);
wire src_reg_src_sel    =  (e_state==4'h2)                    |
                           (e_state==4'h0)                    |
                          ((e_state==4'h6) & ~inst_as[6]) |
                          ((e_state==4'h7) & ~inst_as[6]) |
                          ((e_state==4'hB)   &  inst_as[0] & ~inst_type[1]);
wire src_reg_dest_sel   =  (e_state==4'h1)                    |
                           (e_state==4'h3)                    |
                          ((e_state==4'h9) & (inst_so[4] | inst_so[5])) |
                          ((e_state==4'h5) & (inst_so[4] | inst_so[5]) & inst_as[1]);
wire src_mdb_in_val_sel = ((e_state==4'h9) &  inst_so[6])                     |
                          ((e_state==4'hB)   & (inst_as[2] | inst_as[3] |
                                                   inst_as[1]   | inst_as[4]    |
                                                   inst_as[6]));
wire src_inst_dext_sel =  ((e_state==4'h9) & ~(inst_so[4] | inst_so[5])) |
                          ((e_state==4'hA) & ~(inst_so[4] | inst_so[5]   |
                                                    inst_so[6]));
wire src_inst_sext_sel =  ((e_state==4'hB)   &  (inst_type[1] | inst_as[5] |
                                                    inst_as[7]      | inst_so[6]));
assign op_src = src_reg_src_sel     ?  reg_src    :
                src_reg_dest_sel    ?  reg_dest   :
                src_mdb_in_val_sel  ?  mdb_in_val :
                src_inst_dext_sel   ?  inst_dext  :
                src_inst_sext_sel   ?  inst_sext  : 16'h0000;
wire dst_inst_sext_sel  = ((e_state==4'h6) & (inst_as[1] | inst_as[4] |
                                                   inst_as[6]))                |
                          ((e_state==4'h7) & (inst_as[1] | inst_as[4] |
                                                   inst_as[6]));
wire dst_mdb_in_bw_sel  = ((e_state==4'hA) &   inst_so[6]) |
                          ((e_state==4'hB)   & ~(inst_ad[0] | inst_type[1] |
                                                    inst_type[0]) & ~inst_so[6]);
wire dst_fffe_sel       =  (e_state==4'h2)  |
                           (e_state==4'h1)  |
                           (e_state==4'h3)  |
                          ((e_state==4'h9) & (inst_so[4] | inst_so[5]) & ~inst_so[6]) |
                          ((e_state==4'h5) & (inst_so[4] | inst_so[5]) & inst_as[1]) |
                          ((e_state==4'h6) & (inst_so[4] | inst_so[5]) & (inst_as[2] | inst_as[3]) & inst_src[1]);
wire dst_reg_dest_sel   = ((e_state==4'h9) & ~(inst_so[4] | inst_so[5] | inst_ad[6] | inst_so[6])) |
                          ((e_state==4'hA) &  ~inst_ad[6]) |
                          ((e_state==4'hB)   &  (inst_ad[0] | inst_type[1] |
                                                    inst_type[0]) & ~inst_so[6]);
assign op_dst = dbg_halt_st        ? dbg_mem_dout  :
                dst_inst_sext_sel  ? inst_sext     :
                dst_mdb_in_bw_sel  ? mdb_in_bw     :
                dst_reg_dest_sel   ? reg_dest      :
                dst_fffe_sel       ? 16'hfffe      : 16'h0000;
wire exec_cycle = (e_state==4'hB);
omsp_alu alu_0 (
    .alu_out      (alu_out),       
    .alu_out_add  (alu_out_add),   
    .alu_stat     (alu_stat),      
    .alu_stat_wr  (alu_stat_wr),   
    .dbg_halt_st  (dbg_halt_st),   
    .exec_cycle   (exec_cycle),    
    .inst_alu     (inst_alu),      
    .inst_bw      (inst_bw),       
    .inst_jmp     (inst_jmp),      
    .inst_so      (inst_so),       
    .op_dst       (op_dst),        
    .op_src       (op_src),        
    .status       (status)         
);
wire        mb_rd_det = ((e_state==4'h6) & ~inst_as[5])       |
                        ((e_state==4'hB)   &  inst_so[6])      |
                        ((e_state==4'h9) & ~inst_type[0]
                                              & ~inst_mov);
wire        mb_wr_det = ((e_state==4'h1)  & ~inst_irq_rst)        |
                        ((e_state==4'h3)  & ~inst_irq_rst)        |
                        ((e_state==4'hA) & ~inst_so[6])      |
                         (e_state==4'h7);
wire  [1:0] mb_wr_msk =  inst_alu[11]  ? 2'b00 :
                        ~inst_bw                ? 2'b11 :
                         alu_out_add[0]         ? 2'b10 : 2'b01;
assign      mb_en     = mb_rd_det | (mb_wr_det & ~inst_alu[11]);
assign      mb_wr     = ({2{mb_wr_det}}) & mb_wr_msk;
assign      mab       = alu_out_add[15:0];
reg  [15:0] mdb_out_nxt;
wire        mclk_mdb_out_nxt = mclk;
always @(posedge mclk_mdb_out_nxt or posedge puc_rst)
  if (puc_rst)                                        mdb_out_nxt <= 16'h0000;
  else if (e_state==4'h9)                        mdb_out_nxt <= pc_nxt;
  else if ((e_state==4'hB & ~inst_so[5]) |
           (e_state==4'h2) | (e_state==4'h0)) mdb_out_nxt <= alu_out;
assign      mdb_out = inst_bw ? {2{mdb_out_nxt[7:0]}} : mdb_out_nxt;
reg        mab_lsb;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)    mab_lsb <= 1'b0;
  else if (mb_en) mab_lsb <= alu_out_add[0];
assign mdb_in_bw  = ~inst_bw ? mdb_in :
                     mab_lsb ? {2{mdb_in[15:8]}} : mdb_in;
reg         mdb_in_buf_en;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  mdb_in_buf_en <= 1'b0;
  else          mdb_in_buf_en <= (e_state==4'h6);
reg         mdb_in_buf_valid;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)               mdb_in_buf_valid <= 1'b0;
  else if (e_state==4'hB) mdb_in_buf_valid <= 1'b0;
  else if (mdb_in_buf_en)    mdb_in_buf_valid <= 1'b1;
reg  [15:0] mdb_in_buf;
wire        mclk_mdb_in_buf = mclk;
always @(posedge mclk_mdb_in_buf or posedge puc_rst)
  if (puc_rst)            mdb_in_buf <= 16'h0000;
  else if (mdb_in_buf_en) mdb_in_buf <= mdb_in_bw;
assign mdb_in_val = mdb_in_buf_valid ? mdb_in_buf : mdb_in_bw;
endmodule  
module  omsp_frontend (
    dbg_halt_st,                     
    decode_noirq,                    
    e_state,                         
    exec_done,                       
    inst_ad,                         
    inst_as,                         
    inst_alu,                        
    inst_bw,                         
    inst_dest,                       
    inst_dext,                       
    inst_irq_rst,                    
    inst_jmp,                        
    inst_mov,                        
    inst_sext,                       
    inst_so,                         
    inst_src,                        
    inst_type,                       
    irq_acc,                         
    mab,                             
    mb_en,                           
    mclk_enable,                     
    mclk_wkup,                       
    nmi_acc,                         
    pc,                              
    pc_nxt,                          
    cpu_en_s,                        
    cpuoff,                          
    dbg_halt_cmd,                    
    dbg_reg_sel,                     
    fe_pmem_wait,                    
    gie,                             
    irq,                             
    mclk,                            
    mdb_in,                          
    nmi_pnd,                         
    nmi_wkup,                        
    pc_sw,                           
    pc_sw_wr,                        
    puc_rst,                         
    scan_enable,                     
    wdt_irq,                         
    wdt_wkup,                        
    wkup                             
);
output               dbg_halt_st;    
output               decode_noirq;   
output         [3:0] e_state;        
output               exec_done;      
output         [7:0] inst_ad;        
output         [7:0] inst_as;        
output        [11:0] inst_alu;       
output               inst_bw;        
output        [15:0] inst_dest;      
output        [15:0] inst_dext;      
output               inst_irq_rst;   
output         [7:0] inst_jmp;       
output               inst_mov;       
output        [15:0] inst_sext;      
output         [7:0] inst_so;        
output        [15:0] inst_src;       
output         [2:0] inst_type;      
output [64-3:0] irq_acc;        
output        [15:0] mab;            
output               mb_en;          
output               mclk_enable;    
output               mclk_wkup;      
output               nmi_acc;        
output        [15:0] pc;             
output        [15:0] pc_nxt;         
input                cpu_en_s;       
input                cpuoff;         
input                dbg_halt_cmd;   
input          [3:0] dbg_reg_sel;    
input                fe_pmem_wait;   
input                gie;            
input  [64-3:0] irq;            
input                mclk;           
input         [15:0] mdb_in;         
input                nmi_pnd;        
input                nmi_wkup;       
input         [15:0] pc_sw;          
input                pc_sw_wr;       
input                puc_rst;        
input                scan_enable;    
input                wdt_irq;        
input                wdt_wkup;       
input                wkup;           
function [63:0] one_hot64;
   input  [5:0] binary;
   begin
      one_hot64         = 64'h0000_0000_0000_0000;
      one_hot64[binary] =  1'b1;
   end
endfunction
function [15:0] one_hot16;
   input  [3:0] binary;
   begin
      one_hot16         = 16'h0000;
      one_hot16[binary] =  1'b1;
   end
endfunction
function [7:0] one_hot8;
   input  [2:0] binary;
   begin
      one_hot8         = 8'h00;
      one_hot8[binary] = 1'b1;
   end
endfunction
function  [5:0] get_irq_num;
   input [62:0] irq_all;
   integer      ii;
   begin
      get_irq_num = 6'h3f;
      for (ii = 62; ii >= 0; ii = ii - 1)
        if (&get_irq_num & irq_all[ii]) get_irq_num = ii[5:0];
   end
endfunction
parameter I_IRQ_FETCH = 3'h0;
parameter I_IRQ_DONE  = 3'h1;
parameter I_DEC       = 3'h2;         
parameter I_EXT1      = 3'h3;        
parameter I_EXT2      = 3'h4;        
parameter I_IDLE      = 3'h5;        
parameter E_IRQ_0     = 4'h2;
parameter E_IRQ_1     = 4'h1;
parameter E_IRQ_2     = 4'h0;
parameter E_IRQ_3     = 4'h3;
parameter E_IRQ_4     = 4'h4;
parameter E_SRC_AD    = 4'h5;
parameter E_SRC_RD    = 4'h6;
parameter E_SRC_WR    = 4'h7;
parameter E_DST_AD    = 4'h8;
parameter E_DST_RD    = 4'h9;
parameter E_DST_WR    = 4'hA;
parameter E_EXEC      = 4'hB;
parameter E_JUMP      = 4'hC;
parameter E_IDLE      = 4'hD;
reg  [2:0] i_state;
reg  [2:0] i_state_nxt;
reg  [1:0] inst_sz;
wire [1:0] inst_sz_nxt;
wire       irq_detect;
wire [2:0] inst_type_nxt;
wire       is_const;
reg [15:0] sconst_nxt;
reg  [3:0] e_state_nxt;
wire   cpu_halt_cmd = dbg_halt_cmd | ~cpu_en_s;
always @(i_state    or inst_sz  or inst_sz_nxt  or pc_sw_wr or exec_done or
         irq_detect or cpuoff   or cpu_halt_cmd or e_state)
    case(i_state)
      I_IDLE     : i_state_nxt = (irq_detect & ~cpu_halt_cmd) ? I_IRQ_FETCH :
                                 (~cpuoff    & ~cpu_halt_cmd) ? I_DEC       : I_IDLE;
      I_IRQ_FETCH: i_state_nxt =  I_IRQ_DONE;
      I_IRQ_DONE : i_state_nxt =  I_DEC;
      I_DEC      : i_state_nxt =  irq_detect                  ? I_IRQ_FETCH :
                          (cpuoff | cpu_halt_cmd) & exec_done ? I_IDLE      :
                            cpu_halt_cmd & (e_state==E_IDLE)  ? I_IDLE      :
                                  pc_sw_wr                    ? I_DEC       :
                             ~exec_done & ~(e_state==E_IDLE)  ? I_DEC       :         
                                  (inst_sz_nxt!=2'b00)        ? I_EXT1      : I_DEC;  
      I_EXT1     : i_state_nxt =  pc_sw_wr                    ? I_DEC       : 
                                  (inst_sz!=2'b01)            ? I_EXT2      : I_DEC;
      I_EXT2     : i_state_nxt =  I_DEC;
      default    : i_state_nxt =  I_IRQ_FETCH;
    endcase
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) i_state  <= I_IRQ_FETCH;
  else         i_state  <= i_state_nxt;
wire   decode_noirq =  ((i_state==I_DEC) &  (exec_done | (e_state==E_IDLE)));
wire   decode       =  decode_noirq | irq_detect;
wire   fetch        = ~((i_state==I_DEC) & ~(exec_done | (e_state==E_IDLE))) & ~(e_state_nxt==E_IDLE);
reg    dbg_halt_st;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  dbg_halt_st <= 1'b0;
  else          dbg_halt_st <= cpu_halt_cmd & (i_state_nxt==I_IDLE);
reg         inst_irq_rst;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)                  inst_irq_rst <= 1'b1;
  else if (exec_done)           inst_irq_rst <= 1'b0;
assign  irq_detect = (nmi_pnd | ((|irq | wdt_irq) & gie)) & ~cpu_halt_cmd & ~dbg_halt_st & (exec_done | (i_state==I_IDLE));
wire       mclk_irq_num = mclk;
wire [62:0] irq_all     = {nmi_pnd, irq}                     |
                          {1'b0,    3'h0, wdt_irq, {58{1'b0}}};
reg  [5:0] irq_num;
always @(posedge mclk_irq_num or posedge puc_rst)
  if (puc_rst)         irq_num <= 6'h3f;
  else if (irq_detect)
                       irq_num <= get_irq_num(irq_all);
wire [15:0] irq_addr    = {9'h1ff, irq_num, 1'b0};
wire        [63:0] irq_acc_all = one_hot64(irq_num) & {64{(i_state==I_IRQ_FETCH)}};
wire [64-3:0] irq_acc     = irq_acc_all[61:64-64];
wire               nmi_acc     = irq_acc_all[62];
assign  mclk_wkup   = 1'b1;
assign  mclk_enable = 1'b1;
reg  [15:0] pc;
wire [15:0] pc_incr = pc + {14'h0000, fetch, 1'b0};
wire [15:0] pc_nxt  = pc_sw_wr               ? pc_sw    :
                      (i_state==I_IRQ_FETCH) ? irq_addr :
                      (i_state==I_IRQ_DONE)  ? mdb_in   :  pc_incr;
wire       mclk_pc = mclk;
always @(posedge mclk_pc or posedge puc_rst)
  if (puc_rst)  pc <= 16'h0000;
  else          pc <= pc_nxt;
reg pmem_busy;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  pmem_busy <= 1'b0;
  else          pmem_busy <= fe_pmem_wait;
wire [15:0] mab      = pc_nxt;
wire        mb_en    = fetch | pc_sw_wr | (i_state==I_IRQ_FETCH) | pmem_busy | (dbg_halt_st & ~cpu_halt_cmd);
wire [15:0] ir  = mdb_in;
wire is_sext = (inst_as[1] | inst_as[4] | inst_as[6] | inst_as[5]);
wire [15:0] ext_incr = ((i_state==I_EXT1)     &  inst_as[4]) |
                       ((i_state==I_EXT2)     &  inst_ad[4]) |
                       ((i_state==I_EXT1)     & ~inst_as[4] &
                       ~(i_state_nxt==I_EXT2) &  inst_ad[4])   ? 16'hfffe : 16'h0000;
wire [15:0] ext_nxt  = ir + ext_incr;
reg [15:0] inst_sext;
wire       mclk_inst_sext = mclk;
always @(posedge mclk_inst_sext or posedge puc_rst)
  if (puc_rst)                                 inst_sext <= 16'h0000;
  else if (decode & is_const)                  inst_sext <= sconst_nxt;
  else if (decode & inst_type_nxt[1])  inst_sext <= {{5{ir[9]}},ir[9:0],1'b0};
  else if ((i_state==I_EXT1) & is_sext)        inst_sext <= ext_nxt;
wire inst_sext_rdy = (i_state==I_EXT1) & is_sext;
reg [15:0] inst_dext;
wire       mclk_inst_dext = mclk;
always @(posedge mclk_inst_dext or posedge puc_rst)
  if (puc_rst)                           inst_dext <= 16'h0000;
  else if ((i_state==I_EXT1) & ~is_sext) inst_dext <= ext_nxt;
  else if  (i_state==I_EXT2)             inst_dext <= ext_nxt;
wire inst_dext_rdy = (((i_state==I_EXT1) & ~is_sext) | (i_state==I_EXT2));
wire       mclk_decode = mclk;
reg  [2:0] inst_type;
assign     inst_type_nxt = {(ir[15:14]!=2'b00),
                            (ir[15:13]==3'b001),
                            (ir[15:13]==3'b000)} & {3{~irq_detect}};
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)      inst_type <= 3'b000;
  else if (decode)  inst_type <= inst_type_nxt;
reg   [7:0] inst_so;
wire  [7:0] inst_so_nxt = irq_detect ? 8'h80 : (one_hot8(ir[9:7]) & {8{inst_type_nxt[0]}});
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_so <= 8'h00;
  else if (decode) inst_so <= inst_so_nxt;
reg   [2:0] inst_jmp_bin;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_jmp_bin <= 3'h0;
  else if (decode) inst_jmp_bin <= ir[12:10];
wire [7:0] inst_jmp = one_hot8(inst_jmp_bin) & {8{inst_type[1]}};
wire [15:0] inst_to_1hot = one_hot16(ir[15:12]) & {16{inst_type_nxt[2]}};
wire [11:0] inst_to_nxt  = inst_to_1hot[15:4];
reg         inst_mov;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_mov <= 1'b0;
  else if (decode) inst_mov <= inst_to_nxt[0];
reg [3:0] inst_dest_bin;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_dest_bin <= 4'h0;
  else if (decode) inst_dest_bin <= ir[3:0];
wire  [15:0] inst_dest = dbg_halt_st          ? one_hot16(dbg_reg_sel) :
                         inst_type[1] ? 16'h0001               :
                         inst_so[7]  |
                         inst_so[4] |
                         inst_so[5]       ? 16'h0002               :
                                                one_hot16(inst_dest_bin);
reg [3:0] inst_src_bin;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_src_bin <= 4'h0;
  else if (decode) inst_src_bin <= ir[11:8];
wire  [15:0] inst_src = inst_type[2] ? one_hot16(inst_src_bin)  :
                        inst_so[6]      ? 16'h0002                 :
                        inst_so[7]       ? 16'h0001                 :
                        inst_type[0] ? one_hot16(inst_dest_bin) : 16'h0000;
reg [12:0] inst_as_nxt;
wire [3:0] src_reg = inst_type_nxt[0] ? ir[3:0] : ir[11:8];
always @(src_reg or ir or inst_type_nxt)
  begin
     if (inst_type_nxt[1])
       inst_as_nxt =  13'b0000000000001;
     else if (src_reg==4'h3)  
       case (ir[5:4])
         2'b11  : inst_as_nxt =  13'b1000000000000;
         2'b10  : inst_as_nxt =  13'b0100000000000;
         2'b01  : inst_as_nxt =  13'b0010000000000;
         default: inst_as_nxt =  13'b0001000000000;
       endcase
     else if (src_reg==4'h2)  
       case (ir[5:4])
         2'b11  : inst_as_nxt =  13'b0000100000000;
         2'b10  : inst_as_nxt =  13'b0000010000000;
         2'b01  : inst_as_nxt =  13'b0000001000000;
         default: inst_as_nxt =  13'b0000000000001;
       endcase
     else if (src_reg==4'h0)  
       case (ir[5:4])
         2'b11  : inst_as_nxt =  13'b0000000100000;
         2'b10  : inst_as_nxt =  13'b0000000000100;
         2'b01  : inst_as_nxt =  13'b0000000010000;
         default: inst_as_nxt =  13'b0000000000001;
       endcase
     else                     
       case (ir[5:4])
         2'b11  : inst_as_nxt =  13'b0000000001000;
         2'b10  : inst_as_nxt =  13'b0000000000100;
         2'b01  : inst_as_nxt =  13'b0000000000010;
         default: inst_as_nxt =  13'b0000000000001;
       endcase
  end
assign    is_const = |inst_as_nxt[12:7];
reg [7:0] inst_as;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_as <= 8'h00;
  else if (decode) inst_as <= {is_const, inst_as_nxt[6:0]};
always @(inst_as_nxt)
  begin
     if (inst_as_nxt[7])        sconst_nxt = 16'h0004;
     else if (inst_as_nxt[8])   sconst_nxt = 16'h0008;
     else if (inst_as_nxt[9])   sconst_nxt = 16'h0000;
     else if (inst_as_nxt[10])  sconst_nxt = 16'h0001;
     else if (inst_as_nxt[11])  sconst_nxt = 16'h0002;
     else if (inst_as_nxt[12])  sconst_nxt = 16'hffff;
     else                       sconst_nxt = 16'h0000;
  end
reg  [7:0] inst_ad_nxt;
wire [3:0] dest_reg = ir[3:0];
always @(dest_reg or ir or inst_type_nxt)
  begin
     if (~inst_type_nxt[2])
       inst_ad_nxt =  8'b00000000;
     else if (dest_reg==4'h2)    
       case (ir[7])
         1'b1   : inst_ad_nxt =  8'b01000000;
         default: inst_ad_nxt =  8'b00000001;
       endcase
     else if (dest_reg==4'h0)    
       case (ir[7])
         1'b1   : inst_ad_nxt =  8'b00010000;
         default: inst_ad_nxt =  8'b00000001;
       endcase
     else                        
       case (ir[7])
         1'b1   : inst_ad_nxt =  8'b00000010;
         default: inst_ad_nxt =  8'b00000001;
       endcase
  end
reg [7:0] inst_ad;
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_ad <= 8'h00;
  else if (decode) inst_ad <= inst_ad_nxt;
reg       inst_bw;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)     inst_bw     <= 1'b0;
  else if (decode) inst_bw     <= ir[6] & ~inst_type_nxt[1] & ~irq_detect & ~cpu_halt_cmd;
assign    inst_sz_nxt = {1'b0,  (inst_as_nxt[1] | inst_as_nxt[4] | inst_as_nxt[6] | inst_as_nxt[5])} +
                        {1'b0, ((inst_ad_nxt[1] | inst_ad_nxt[4] | inst_ad_nxt[6]) & ~inst_type_nxt[0])};
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_sz     <= 2'b00;
  else if (decode) inst_sz     <= inst_sz_nxt;
reg  [3:0] e_state;
wire src_acalc_pre =  inst_as_nxt[1]   | inst_as_nxt[4]    | inst_as_nxt[6];
wire src_rd_pre    =  inst_as_nxt[2] | inst_as_nxt[3] | inst_as_nxt[5]  | inst_so_nxt[6];
wire dst_acalc_pre =  inst_ad_nxt[1]   | inst_ad_nxt[4]    | inst_ad_nxt[6];
wire dst_acalc     =  inst_ad[1]       | inst_ad[4]        | inst_ad[6];
wire dst_rd_pre    =  inst_ad_nxt[1]   | inst_so_nxt[4]    | inst_so_nxt[5] | inst_so_nxt[6];
wire dst_rd        =  inst_ad[1]       | inst_so[4]        | inst_so[5]     | inst_so[6];
wire inst_branch   =  (inst_ad_nxt[0] & (ir[3:0]==4'h0)) | inst_type_nxt[1] | inst_so_nxt[6];
reg exec_jmp;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)                   exec_jmp <= 1'b0;
  else if (inst_branch & decode) exec_jmp <= 1'b1;
  else if (e_state==E_JUMP)      exec_jmp <= 1'b0;
reg exec_dst_wr;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)                exec_dst_wr <= 1'b0;
  else if (e_state==E_DST_RD) exec_dst_wr <= 1'b1;
  else if (e_state==E_DST_WR) exec_dst_wr <= 1'b0;
reg exec_src_wr;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)                                         exec_src_wr <= 1'b0;
  else if (inst_type[0] & (e_state==E_SRC_RD))  exec_src_wr <= 1'b1;
  else if ((e_state==E_SRC_WR) || (e_state==E_DST_WR)) exec_src_wr <= 1'b0;
reg exec_dext_rdy;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)                exec_dext_rdy <= 1'b0;
  else if (e_state==E_DST_RD) exec_dext_rdy <= 1'b0;
  else if (inst_dext_rdy)     exec_dext_rdy <= 1'b1;
wire [3:0] e_first_state = ~dbg_halt_st  & inst_so_nxt[7] ? E_IRQ_0  :
                            cpu_halt_cmd | (i_state==I_IDLE) ? E_IDLE   :
                            cpuoff                           ? E_IDLE   :
                            src_acalc_pre                    ? E_SRC_AD :
                            src_rd_pre                       ? E_SRC_RD :
                            dst_acalc_pre                    ? E_DST_AD :
                            dst_rd_pre                       ? E_DST_RD : E_EXEC;
always @(e_state       or dst_acalc     or dst_rd   or inst_sext_rdy or
         inst_dext_rdy or exec_dext_rdy or exec_jmp or exec_dst_wr   or
         e_first_state or exec_src_wr)
    case(e_state)
      E_IDLE   : e_state_nxt =  e_first_state;
      E_IRQ_0  : e_state_nxt =  E_IRQ_1;
      E_IRQ_1  : e_state_nxt =  E_IRQ_2;
      E_IRQ_2  : e_state_nxt =  E_IRQ_3;
      E_IRQ_3  : e_state_nxt =  E_IRQ_4;
      E_IRQ_4  : e_state_nxt =  E_EXEC;
      E_SRC_AD : e_state_nxt =  inst_sext_rdy     ? E_SRC_RD : E_SRC_AD;
      E_SRC_RD : e_state_nxt =  dst_acalc         ? E_DST_AD : 
                                 dst_rd           ? E_DST_RD : E_EXEC;
      E_DST_AD : e_state_nxt =  (inst_dext_rdy |
                                 exec_dext_rdy)   ? E_DST_RD : E_DST_AD;
      E_DST_RD : e_state_nxt =  E_EXEC;
      E_EXEC   : e_state_nxt =  exec_dst_wr       ? E_DST_WR :
                                exec_jmp          ? E_JUMP   :
                                exec_src_wr       ? E_SRC_WR : e_first_state;
      E_JUMP   : e_state_nxt =  e_first_state;
      E_DST_WR : e_state_nxt =  exec_jmp          ? E_JUMP   : e_first_state;
      E_SRC_WR : e_state_nxt =  e_first_state;
      default  : e_state_nxt =  E_IRQ_0;
    endcase
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) e_state  <= E_IRQ_1;
  else         e_state  <= e_state_nxt;
wire exec_done = exec_jmp        ? (e_state==E_JUMP)   :
                 exec_dst_wr     ? (e_state==E_DST_WR) :
                 exec_src_wr     ? (e_state==E_SRC_WR) : (e_state==E_EXEC);
reg  [11:0] inst_alu;
wire        alu_src_inv   = inst_to_nxt[4]  | inst_to_nxt[3] |
                            inst_to_nxt[5]  | inst_to_nxt[8] ;
wire        alu_inc       = inst_to_nxt[4]  | inst_to_nxt[5];
wire        alu_inc_c     = inst_to_nxt[2] | inst_to_nxt[6] |
                            inst_to_nxt[3];
wire        alu_add       = inst_to_nxt[1]  | inst_to_nxt[2]       |
                            inst_to_nxt[4]  | inst_to_nxt[3]       |
                            inst_to_nxt[5]  | inst_type_nxt[1] |
                            inst_so_nxt[6];
wire        alu_and       = inst_to_nxt[11]  | inst_to_nxt[8]  |
                            inst_to_nxt[7];
wire        alu_or        = inst_to_nxt[9];
wire        alu_xor       = inst_to_nxt[10];
wire        alu_dadd      = inst_to_nxt[6];
wire        alu_stat_7    = inst_to_nxt[7]  | inst_to_nxt[11]  |
                            inst_so_nxt[3];
wire        alu_stat_f    = inst_to_nxt[1]  | inst_to_nxt[2] |
                            inst_to_nxt[4]  | inst_to_nxt[3] |
                            inst_to_nxt[5]  | inst_to_nxt[6] |
                            inst_to_nxt[7]  | inst_to_nxt[10]  |
                            inst_to_nxt[11]  |
                            inst_so_nxt[0]  | inst_so_nxt[2]  |
                            inst_so_nxt[3];
wire        alu_shift     = inst_so_nxt[0]  | inst_so_nxt[2];
wire        exec_no_wr    = inst_to_nxt[5] | inst_to_nxt[7];
wire [11:0] inst_alu_nxt  = {exec_no_wr,
                             alu_shift,
                             alu_stat_f,
                             alu_stat_7,
                             alu_dadd,
                             alu_xor,
                             alu_or,
                             alu_and,
                             alu_add,
                             alu_inc_c,
                             alu_inc,
                             alu_src_inv};
always @(posedge mclk_decode or posedge puc_rst)
  if (puc_rst)     inst_alu <= 12'h000;
  else if (decode) inst_alu <= inst_alu_nxt;
endmodule  
module  omsp_mem_backbone (
    dbg_mem_din,                     
    dmem_addr,                       
    dmem_cen,                        
    dmem_din,                        
    dmem_wen,                        
    eu_mdb_in,                       
    fe_mdb_in,                       
    fe_pmem_wait,                    
    per_addr,                        
    per_din,                         
    per_we,                          
    per_en,                          
    pmem_addr,                       
    pmem_cen,                        
    pmem_din,                        
    pmem_wen,                        
    dbg_halt_st,                     
    dbg_mem_addr,                    
    dbg_mem_dout,                    
    dbg_mem_en,                      
    dbg_mem_wr,                      
    dmem_dout,                       
    eu_mab,                          
    eu_mb_en,                        
    eu_mb_wr,                        
    eu_mdb_out,                      
    fe_mab,                          
    fe_mb_en,                        
    mclk,                            
    per_dout,                        
    pmem_dout,                       
    puc_rst,                         
    scan_enable                      
);
output        [15:0] dbg_mem_din;    
output [6-1:0] dmem_addr;      
output               dmem_cen;       
output        [15:0] dmem_din;       
output         [1:0] dmem_wen;       
output        [15:0] eu_mdb_in;      
output        [15:0] fe_mdb_in;      
output               fe_pmem_wait;   
output        [13:0] per_addr;       
output        [15:0] per_din;        
output         [1:0] per_we;         
output               per_en;         
output [10-1:0] pmem_addr;      
output               pmem_cen;       
output        [15:0] pmem_din;       
output         [1:0] pmem_wen;       
input                dbg_halt_st;    
input         [15:0] dbg_mem_addr;   
input         [15:0] dbg_mem_dout;   
input                dbg_mem_en;     
input          [1:0] dbg_mem_wr;     
input         [15:0] dmem_dout;      
input         [14:0] eu_mab;         
input                eu_mb_en;       
input          [1:0] eu_mb_wr;       
input         [15:0] eu_mdb_out;     
input         [14:0] fe_mab;         
input                fe_mb_en;       
input                mclk;           
input         [15:0] per_dout;       
input         [15:0] pmem_dout;      
input                puc_rst;        
input                scan_enable;    
wire               eu_dmem_cen   = ~(eu_mb_en & (eu_mab>=(512>>1)) &
                                                (eu_mab<((512+128)>>1)));
wire        [15:0] eu_dmem_addr  = {1'b0, eu_mab}-(512>>1);
wire               dbg_dmem_cen  = ~(dbg_mem_en & (dbg_mem_addr[15:1]>=(512>>1)) &
                                                  (dbg_mem_addr[15:1]<((512+128)>>1)));
wire        [15:0] dbg_dmem_addr = {1'b0, dbg_mem_addr[15:1]}-(512>>1);
wire [6-1:0] dmem_addr     = ~dbg_dmem_cen ? dbg_dmem_addr[6-1:0] : eu_dmem_addr[6-1:0];
wire               dmem_cen      =  dbg_dmem_cen & eu_dmem_cen;
wire         [1:0] dmem_wen      = ~(dbg_mem_wr | eu_mb_wr);
wire        [15:0] dmem_din      = ~dbg_dmem_cen ? dbg_mem_dout : eu_mdb_out;
parameter          PMEM_OFFSET   = (16'hFFFF-2048+1);
wire               eu_pmem_cen   = ~(eu_mb_en & ~|eu_mb_wr & (eu_mab>=(PMEM_OFFSET>>1)));
wire        [15:0] eu_pmem_addr  = eu_mab-(PMEM_OFFSET>>1);
wire               fe_pmem_cen   = ~(fe_mb_en & (fe_mab>=(PMEM_OFFSET>>1)));
wire        [15:0] fe_pmem_addr  = fe_mab-(PMEM_OFFSET>>1);
wire               dbg_pmem_cen  = ~(dbg_mem_en & (dbg_mem_addr[15:1]>=(PMEM_OFFSET>>1)));
wire        [15:0] dbg_pmem_addr = {1'b0, dbg_mem_addr[15:1]}-(PMEM_OFFSET>>1);
wire [10-1:0] pmem_addr     = ~dbg_pmem_cen ? dbg_pmem_addr[10-1:0] :
                                   ~eu_pmem_cen  ? eu_pmem_addr[10-1:0]  : fe_pmem_addr[10-1:0];
wire               pmem_cen      =  fe_pmem_cen & eu_pmem_cen & dbg_pmem_cen;
wire         [1:0] pmem_wen      = ~dbg_mem_wr;
wire        [15:0] pmem_din      =  dbg_mem_dout;
wire               fe_pmem_wait  = (~fe_pmem_cen & ~eu_pmem_cen);
wire              dbg_per_en   =  dbg_mem_en & (dbg_mem_addr[15:1]<(512>>1));
wire              eu_per_en    =  eu_mb_en   & (eu_mab<(512>>1));
wire       [15:0] per_din      =  dbg_mem_en ? dbg_mem_dout               : eu_mdb_out;
wire        [1:0] per_we       =  dbg_mem_en ? dbg_mem_wr                 : eu_mb_wr;
wire              per_en       =  dbg_mem_en ? dbg_per_en                 : eu_per_en;
wire [8-1:0] per_addr_mux =  dbg_mem_en ? dbg_mem_addr[8-1+1:1] : eu_mab[8-1:0];
wire       [14:0] per_addr_ful =  {{15-8{1'b0}}, per_addr_mux};
wire       [13:0] per_addr     =   per_addr_ful[13:0];
reg   [15:0] per_dout_val;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  per_dout_val <= 16'h0000;
  else          per_dout_val <= per_dout;
reg 	    fe_pmem_cen_dly;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst) fe_pmem_cen_dly <=  1'b0;
  else         fe_pmem_cen_dly <=  fe_pmem_cen;
wire fe_pmem_save    = ( fe_pmem_cen & ~fe_pmem_cen_dly) & ~dbg_halt_st;
wire fe_pmem_restore = (~fe_pmem_cen &  fe_pmem_cen_dly) |  dbg_halt_st;
wire mclk_bckup = mclk;
reg  [15:0] pmem_dout_bckup;
always @(posedge mclk_bckup or posedge puc_rst)
  if (puc_rst)           pmem_dout_bckup     <=  16'h0000;
  else if (fe_pmem_save) pmem_dout_bckup     <=  pmem_dout;
reg         pmem_dout_bckup_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)              pmem_dout_bckup_sel <=  1'b0;
  else if (fe_pmem_save)    pmem_dout_bckup_sel <=  1'b1;
  else if (fe_pmem_restore) pmem_dout_bckup_sel <=  1'b0;
assign fe_mdb_in = pmem_dout_bckup_sel ? pmem_dout_bckup : pmem_dout;
reg [1:0] eu_mdb_in_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  eu_mdb_in_sel <= 2'b00;
  else          eu_mdb_in_sel <= {~eu_pmem_cen, per_en};
assign      eu_mdb_in      = eu_mdb_in_sel[1] ? pmem_dout    :
                             eu_mdb_in_sel[0] ? per_dout_val : dmem_dout;
reg   [1:0] dbg_mem_din_sel;
always @(posedge mclk or posedge puc_rst)
  if (puc_rst)  dbg_mem_din_sel <= 2'b00;
  else          dbg_mem_din_sel <= {~dbg_pmem_cen, dbg_per_en};
assign      dbg_mem_din  = dbg_mem_din_sel[1] ? pmem_dout    :
                           dbg_mem_din_sel[0] ? per_dout_val : dmem_dout;
endmodule  
module  omsp_multiplier (
    per_dout,                        
    mclk,                            
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    puc_rst,                         
    scan_enable                      
);
output       [15:0] per_dout;        
input               mclk;            
input        [13:0] per_addr;        
input        [15:0] per_din;         
input               per_en;          
input         [1:0] per_we;          
input               puc_rst;         
input               scan_enable;     
parameter       [14:0] BASE_ADDR   = 15'h0130;
parameter              DEC_WD      =  4;
parameter [DEC_WD-1:0] OP1_MPY     = 'h0,
                       OP1_MPYS    = 'h2,
                       OP1_MAC     = 'h4,
                       OP1_MACS    = 'h6,
                       OP2         = 'h8,
                       RESLO       = 'hA,
                       RESHI       = 'hC,
                       SUMEXT      = 'hE;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] OP1_MPY_D   = (BASE_REG << OP1_MPY),
                       OP1_MPYS_D  = (BASE_REG << OP1_MPYS),
                       OP1_MAC_D   = (BASE_REG << OP1_MAC),
                       OP1_MACS_D  = (BASE_REG << OP1_MACS),
                       OP2_D       = (BASE_REG << OP2),
                       RESLO_D     = (BASE_REG << RESLO),
                       RESHI_D     = (BASE_REG << RESHI),
                       SUMEXT_D    = (BASE_REG << SUMEXT);
wire  result_wr;
wire  result_clr;
wire  early_read;
wire              reg_sel     =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr    =  {per_addr[DEC_WD-2:0], 1'b0};
wire [DEC_SZ-1:0] reg_dec     =  (OP1_MPY_D   &  {DEC_SZ{(reg_addr == OP1_MPY  )}})  |
                                 (OP1_MPYS_D  &  {DEC_SZ{(reg_addr == OP1_MPYS )}})  |
                                 (OP1_MAC_D   &  {DEC_SZ{(reg_addr == OP1_MAC  )}})  |
                                 (OP1_MACS_D  &  {DEC_SZ{(reg_addr == OP1_MACS )}})  |
                                 (OP2_D       &  {DEC_SZ{(reg_addr == OP2      )}})  |
                                 (RESLO_D     &  {DEC_SZ{(reg_addr == RESLO    )}})  |
                                 (RESHI_D     &  {DEC_SZ{(reg_addr == RESHI    )}})  |
                                 (SUMEXT_D    &  {DEC_SZ{(reg_addr == SUMEXT   )}});
wire              reg_write   =  |per_we & reg_sel;
wire              reg_read    = ~|per_we & reg_sel;
wire [DEC_SZ-1:0] reg_wr      = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd      = reg_dec & {DEC_SZ{reg_read}};
wire       [15:0] per_din_msk =  per_din & {{8{per_we[1]}}, 8'hff};
reg  [15:0] op1;
wire        op1_wr = reg_wr[OP1_MPY]  |
                     reg_wr[OP1_MPYS] |
                     reg_wr[OP1_MAC]  |
                     reg_wr[OP1_MACS];
wire        mclk_op1 = mclk;
always @ (posedge mclk_op1 or posedge puc_rst)
  if (puc_rst)      op1 <=  16'h0000;
  else if (op1_wr)  op1 <=  per_din_msk;
wire [15:0] op1_rd  = op1;
reg  [15:0] op2;
wire        op2_wr = reg_wr[OP2];
wire        mclk_op2 = mclk;
always @ (posedge mclk_op2 or posedge puc_rst)
  if (puc_rst)      op2 <=  16'h0000;
  else if (op2_wr)  op2 <=  per_din_msk;
wire [15:0] op2_rd  = op2;
reg  [15:0] reslo;
wire [15:0] reslo_nxt;
wire        reslo_wr = reg_wr[RESLO];
wire        mclk_reslo = mclk;
always @ (posedge mclk_reslo or posedge puc_rst)
  if (puc_rst)         reslo <=  16'h0000;
  else if (reslo_wr)   reslo <=  per_din_msk;
  else if (result_clr) reslo <=  16'h0000;
  else if (result_wr)  reslo <=  reslo_nxt;
wire [15:0] reslo_rd = early_read ? reslo_nxt : reslo;
reg  [15:0] reshi;
wire [15:0] reshi_nxt;
wire        reshi_wr = reg_wr[RESHI];
wire        mclk_reshi = mclk;
always @ (posedge mclk_reshi or posedge puc_rst)
  if (puc_rst)         reshi <=  16'h0000;
  else if (reshi_wr)   reshi <=  per_din_msk;
  else if (result_clr) reshi <=  16'h0000;
  else if (result_wr)  reshi <=  reshi_nxt;
wire [15:0] reshi_rd = early_read ? reshi_nxt  : reshi;
reg  [1:0] sumext_s;
wire [1:0] sumext_s_nxt;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)         sumext_s <=  2'b00;
  else if (op2_wr)     sumext_s <=  2'b00;
  else if (result_wr)  sumext_s <=  sumext_s_nxt;
wire [15:0] sumext_nxt = {{14{sumext_s_nxt[1]}}, sumext_s_nxt};
wire [15:0] sumext     = {{14{sumext_s[1]}},     sumext_s};
wire [15:0] sumext_rd  = early_read ? sumext_nxt : sumext;
wire [15:0] op1_mux    = op1_rd     & {16{reg_rd[OP1_MPY]  |
                                          reg_rd[OP1_MPYS] |
                                          reg_rd[OP1_MAC]  |
                                          reg_rd[OP1_MACS]}};
wire [15:0] op2_mux    = op2_rd     & {16{reg_rd[OP2]}};
wire [15:0] reslo_mux  = reslo_rd   & {16{reg_rd[RESLO]}};
wire [15:0] reshi_mux  = reshi_rd   & {16{reg_rd[RESHI]}};
wire [15:0] sumext_mux = sumext_rd  & {16{reg_rd[SUMEXT]}};
wire [15:0] per_dout   = op1_mux    |
                         op2_mux    |
                         reslo_mux  |
                         reshi_mux  |
                         sumext_mux;
reg sign_sel;
always @ (posedge mclk_op1 or posedge puc_rst)
  if (puc_rst)     sign_sel <=  1'b0;
  else if (op1_wr) sign_sel <=  reg_wr[OP1_MPYS] | reg_wr[OP1_MACS];
reg acc_sel;
always @ (posedge mclk_op1 or posedge puc_rst)
  if (puc_rst)     acc_sel  <=  1'b0;
  else if (op1_wr) acc_sel  <=  reg_wr[OP1_MAC]  | reg_wr[OP1_MACS];
assign      result_clr = op2_wr & ~acc_sel;
wire [31:0] result     = {reshi, reslo};
reg [1:0] cycle;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) cycle <=  2'b00;
  else         cycle <=  {cycle[0], op2_wr};
assign result_wr = |cycle;
wire signed [16:0] op1_xp    = {sign_sel & op1[15], op1};
wire signed  [8:0] op2_hi_xp = {sign_sel & op2[15], op2[15:8]};
wire signed  [8:0] op2_lo_xp = {              1'b0, op2[7:0]};
wire signed  [8:0] op2_xp    = cycle[0] ? op2_hi_xp : op2_lo_xp;
wire signed [25:0] product    = op1_xp * op2_xp;
wire        [31:0] product_xp = cycle[0] ? {product[23:0], 8'h00} :
                                           {{8{sign_sel & product[23]}}, product[23:0]};
wire [32:0] result_nxt  = {1'b0, result} + {1'b0, product_xp[31:0]};
assign reslo_nxt    = result_nxt[15:0];
assign reshi_nxt    = result_nxt[31:16];
assign sumext_s_nxt =  sign_sel ? {2{result_nxt[31]}} :
                                  {1'b0, result_nxt[32] | sumext_s[0]};
assign early_read   = cycle[1];
endmodule  
module  omsp_register_file (
    cpuoff,                        
    gie,                           
    oscoff,                        
    pc_sw,                         
    pc_sw_wr,                      
    reg_dest,                      
    reg_src,                       
    scg0,                          
    scg1,                          
    status,                        
    alu_stat,                      
    alu_stat_wr,                   
    inst_bw,                       
    inst_dest,                     
    inst_src,                      
    mclk,                          
    pc,                            
    puc_rst,                       
    reg_dest_val,                  
    reg_dest_wr,                   
    reg_pc_call,                   
    reg_sp_val,                    
    reg_sp_wr,                     
    reg_sr_wr,                     
    reg_sr_clr,                    
    reg_incr,                      
    scan_enable                    
);
output 	            cpuoff;        
output 	            gie;           
output 	            oscoff;        
output       [15:0] pc_sw;         
output              pc_sw_wr;      
output       [15:0] reg_dest;      
output       [15:0] reg_src;       
output              scg0;          
output              scg1;          
output        [3:0] status;        
input         [3:0] alu_stat;      
input         [3:0] alu_stat_wr;   
input               inst_bw;       
input        [15:0] inst_dest;     
input        [15:0] inst_src;      
input               mclk;          
input        [15:0] pc;            
input               puc_rst;       
input        [15:0] reg_dest_val;  
input               reg_dest_wr;   
input               reg_pc_call;   
input        [15:0] reg_sp_val;    
input               reg_sp_wr;     
input               reg_sr_wr;     
input               reg_sr_clr;    
input               reg_incr;      
input               scan_enable;   
wire [15:0] inst_src_in;
wire [15:0] incr_op         = (inst_bw & ~inst_src_in[1]) ? 16'h0001 : 16'h0002;
wire [15:0] reg_incr_val    = reg_src+incr_op;
wire [15:0] reg_dest_val_in = inst_bw ? {8'h00,reg_dest_val[7:0]} : reg_dest_val;
assign inst_src_in = reg_sr_clr ? 16'h0004 : inst_src;
wire [15:0] r0       = pc;
wire [15:0] pc_sw    = reg_dest_val_in;
wire        pc_sw_wr = (inst_dest[0] & reg_dest_wr) | reg_pc_call;
reg [15:0] r1;
wire       r1_wr  = inst_dest[1] & reg_dest_wr;
wire       r1_inc = inst_src_in[1]  & reg_incr;
wire       mclk_r1 = mclk;
always @(posedge mclk_r1 or posedge puc_rst)
  if (puc_rst)        r1 <= 16'h0000;
  else if (r1_wr)     r1 <= reg_dest_val_in & 16'hfffe;
  else if (reg_sp_wr) r1 <= reg_sp_val      & 16'hfffe;
  else if (r1_inc)    r1 <= reg_incr_val    & 16'hfffe;
reg  [15:0] r2;
wire        r2_wr  = (inst_dest[2] & reg_dest_wr) | reg_sr_wr;
wire        r2_c   = alu_stat_wr[0] ? alu_stat[0]          :
                     r2_wr          ? reg_dest_val_in[0]   : r2[0];               
wire        r2_z   = alu_stat_wr[1] ? alu_stat[1]          :
                     r2_wr          ? reg_dest_val_in[1]   : r2[1];               
wire        r2_n   = alu_stat_wr[2] ? alu_stat[2]          :
                     r2_wr          ? reg_dest_val_in[2]   : r2[2];               
wire  [7:3] r2_nxt = r2_wr          ? reg_dest_val_in[7:3] : r2[7:3];
wire        r2_v   = alu_stat_wr[3] ? alu_stat[3]          :
                     r2_wr          ? reg_dest_val_in[8]   : r2[8];               
wire        mclk_r2 = mclk;
   wire [15:0] cpuoff_mask = 16'h0010;  
   wire [15:0] oscoff_mask = 16'h0020;  
   wire [15:0] scg0_mask   = 16'h0000;  
   wire [15:0] scg1_mask   = 16'h0080;  
   wire [15:0] r2_mask     = cpuoff_mask | oscoff_mask | scg0_mask | scg1_mask | 16'h010f;
always @(posedge mclk_r2 or posedge puc_rst)
  if (puc_rst)         r2 <= 16'h0000;
  else if (reg_sr_clr) r2 <= 16'h0000;
  else                 r2 <= {7'h00, r2_v, r2_nxt, r2_n, r2_z, r2_c} & r2_mask;
assign status = {r2[8], r2[2:0]};
assign gie    =  r2[3];
assign cpuoff =  r2[4] | (r2_nxt[4] & r2_wr & cpuoff_mask[4]);
assign oscoff =  r2[5];
assign scg0   =  r2[6];
assign scg1   =  r2[7];
reg [15:0] r3;
wire       r3_wr  = inst_dest[3] & reg_dest_wr;
wire       mclk_r3 = mclk;
always @(posedge mclk_r3 or posedge puc_rst)
  if (puc_rst)     r3 <= 16'h0000;
  else if (r3_wr)  r3 <= reg_dest_val_in;
reg [15:0] r4;
wire       r4_wr  = inst_dest[4] & reg_dest_wr;
wire       r4_inc = inst_src_in[4]  & reg_incr;
wire       mclk_r4 = mclk;
always @(posedge mclk_r4 or posedge puc_rst)
  if (puc_rst)      r4  <= 16'h0000;
  else if (r4_wr)   r4  <= reg_dest_val_in;
  else if (r4_inc)  r4  <= reg_incr_val;
reg [15:0] r5;
wire       r5_wr  = inst_dest[5] & reg_dest_wr;
wire       r5_inc = inst_src_in[5]  & reg_incr;
wire       mclk_r5 = mclk;
always @(posedge mclk_r5 or posedge puc_rst)
  if (puc_rst)      r5  <= 16'h0000;
  else if (r5_wr)   r5  <= reg_dest_val_in;
  else if (r5_inc)  r5  <= reg_incr_val;
reg [15:0] r6;
wire       r6_wr  = inst_dest[6] & reg_dest_wr;
wire       r6_inc = inst_src_in[6]  & reg_incr;
wire       mclk_r6 = mclk;
always @(posedge mclk_r6 or posedge puc_rst)
  if (puc_rst)      r6  <= 16'h0000;
  else if (r6_wr)   r6  <= reg_dest_val_in;
  else if (r6_inc)  r6  <= reg_incr_val;
reg [15:0] r7;
wire       r7_wr  = inst_dest[7] & reg_dest_wr;
wire       r7_inc = inst_src_in[7]  & reg_incr;
wire       mclk_r7 = mclk;
always @(posedge mclk_r7 or posedge puc_rst)
  if (puc_rst)      r7  <= 16'h0000;
  else if (r7_wr)   r7  <= reg_dest_val_in;
  else if (r7_inc)  r7  <= reg_incr_val;
reg [15:0] r8;
wire       r8_wr  = inst_dest[8] & reg_dest_wr;
wire       r8_inc = inst_src_in[8]  & reg_incr;
wire       mclk_r8 = mclk;
always @(posedge mclk_r8 or posedge puc_rst)
  if (puc_rst)      r8  <= 16'h0000;
  else if (r8_wr)   r8  <= reg_dest_val_in;
  else if (r8_inc)  r8  <= reg_incr_val;
reg [15:0] r9;
wire       r9_wr  = inst_dest[9] & reg_dest_wr;
wire       r9_inc = inst_src_in[9]  & reg_incr;
wire       mclk_r9 = mclk;
always @(posedge mclk_r9 or posedge puc_rst)
  if (puc_rst)      r9  <= 16'h0000;
  else if (r9_wr)   r9  <= reg_dest_val_in;
  else if (r9_inc)  r9  <= reg_incr_val;
reg [15:0] r10;
wire       r10_wr  = inst_dest[10] & reg_dest_wr;
wire       r10_inc = inst_src_in[10]  & reg_incr;
wire       mclk_r10 = mclk;
always @(posedge mclk_r10 or posedge puc_rst)
  if (puc_rst)      r10 <= 16'h0000;
  else if (r10_wr)  r10 <= reg_dest_val_in;
  else if (r10_inc) r10 <= reg_incr_val;
reg [15:0] r11;
wire       r11_wr  = inst_dest[11] & reg_dest_wr;
wire       r11_inc = inst_src_in[11]  & reg_incr;
wire       mclk_r11 = mclk;
always @(posedge mclk_r11 or posedge puc_rst)
  if (puc_rst)      r11 <= 16'h0000;
  else if (r11_wr)  r11 <= reg_dest_val_in;
  else if (r11_inc) r11 <= reg_incr_val;
reg [15:0] r12;
wire       r12_wr  = inst_dest[12] & reg_dest_wr;
wire       r12_inc = inst_src_in[12]  & reg_incr;
wire       mclk_r12 = mclk;
always @(posedge mclk_r12 or posedge puc_rst)
  if (puc_rst)      r12 <= 16'h0000;
  else if (r12_wr)  r12 <= reg_dest_val_in;
  else if (r12_inc) r12 <= reg_incr_val;
reg [15:0] r13;
wire       r13_wr  = inst_dest[13] & reg_dest_wr;
wire       r13_inc = inst_src_in[13]  & reg_incr;
wire       mclk_r13 = mclk;
always @(posedge mclk_r13 or posedge puc_rst)
  if (puc_rst)      r13 <= 16'h0000;
  else if (r13_wr)  r13 <= reg_dest_val_in;
  else if (r13_inc) r13 <= reg_incr_val;
reg [15:0] r14;
wire       r14_wr  = inst_dest[14] & reg_dest_wr;
wire       r14_inc = inst_src_in[14]  & reg_incr;
wire       mclk_r14 = mclk;
always @(posedge mclk_r14 or posedge puc_rst)
  if (puc_rst)      r14 <= 16'h0000;
  else if (r14_wr)  r14 <= reg_dest_val_in;
  else if (r14_inc) r14 <= reg_incr_val;
reg [15:0] r15;
wire       r15_wr  = inst_dest[15] & reg_dest_wr;
wire       r15_inc = inst_src_in[15]  & reg_incr;
wire       mclk_r15 = mclk;
always @(posedge mclk_r15 or posedge puc_rst)
  if (puc_rst)      r15 <= 16'h0000;
  else if (r15_wr)  r15 <= reg_dest_val_in;
 else if (r15_inc)  r15 <= reg_incr_val;
assign reg_src  = (r0      & {16{inst_src_in[0]}})   | 
                  (r1      & {16{inst_src_in[1]}})   | 
                  (r2      & {16{inst_src_in[2]}})   | 
                  (r3      & {16{inst_src_in[3]}})   | 
                  (r4      & {16{inst_src_in[4]}})   | 
                  (r5      & {16{inst_src_in[5]}})   | 
                  (r6      & {16{inst_src_in[6]}})   | 
                  (r7      & {16{inst_src_in[7]}})   | 
                  (r8      & {16{inst_src_in[8]}})   | 
                  (r9      & {16{inst_src_in[9]}})   | 
                  (r10     & {16{inst_src_in[10]}})  | 
                  (r11     & {16{inst_src_in[11]}})  | 
                  (r12     & {16{inst_src_in[12]}})  | 
                  (r13     & {16{inst_src_in[13]}})  | 
                  (r14     & {16{inst_src_in[14]}})  | 
                  (r15     & {16{inst_src_in[15]}});
assign reg_dest = (r0      & {16{inst_dest[0]}})  | 
                  (r1      & {16{inst_dest[1]}})  | 
                  (r2      & {16{inst_dest[2]}})  | 
                  (r3      & {16{inst_dest[3]}})  | 
                  (r4      & {16{inst_dest[4]}})  | 
                  (r5      & {16{inst_dest[5]}})  | 
                  (r6      & {16{inst_dest[6]}})  | 
                  (r7      & {16{inst_dest[7]}})  | 
                  (r8      & {16{inst_dest[8]}})  | 
                  (r9      & {16{inst_dest[9]}})  | 
                  (r10     & {16{inst_dest[10]}}) | 
                  (r11     & {16{inst_dest[11]}}) | 
                  (r12     & {16{inst_dest[12]}}) | 
                  (r13     & {16{inst_dest[13]}}) | 
                  (r14     & {16{inst_dest[14]}}) | 
                  (r15     & {16{inst_dest[15]}});
endmodule  
module  omsp_scan_mux (
    data_out,                       
    data_in_scan,                   
    data_in_func,                   
    scan_mode                       
);
output              data_out;       
input               data_in_scan;   
input               data_in_func;   
input               scan_mode;      
assign  data_out  =  scan_mode ? data_in_scan : data_in_func;
endmodule  
module  omsp_sfr (
    cpu_id,                        
    nmi_pnd,                       
    nmi_wkup,                      
    per_dout,                      
    wdtie,                         
    wdtifg_sw_clr,                 
    wdtifg_sw_set,                 
    cpu_nr_inst,                   
    cpu_nr_total,                  
    mclk,                          
    nmi,                           
    nmi_acc,                       
    per_addr,                      
    per_din,                       
    per_en,                        
    per_we,                        
    puc_rst,                       
    scan_mode,                     
    wdtifg,                        
    wdtnmies                       
);
output       [31:0] cpu_id;        
output              nmi_pnd;       
output              nmi_wkup;      
output       [15:0] per_dout;      
output              wdtie;         
output              wdtifg_sw_clr; 
output              wdtifg_sw_set; 
input         [7:0] cpu_nr_inst;   
input         [7:0] cpu_nr_total;  
input               mclk;          
input               nmi;           
input               nmi_acc;       
input        [13:0] per_addr;      
input        [15:0] per_din;       
input               per_en;        
input         [1:0] per_we;        
input               puc_rst;       
input               scan_mode;     
input               wdtifg;        
input               wdtnmies;      
parameter       [14:0] BASE_ADDR   = 15'h0000;
parameter              DEC_WD      =  4;
parameter [DEC_WD-1:0] IE1         =  'h0,
                       IFG1        =  'h2,
                       CPU_ID_LO   =  'h4,
                       CPU_ID_HI   =  'h6,
                       CPU_NR      =  'h8;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] IE1_D       = (BASE_REG << IE1),
                       IFG1_D      = (BASE_REG << IFG1),
                       CPU_ID_LO_D = (BASE_REG << CPU_ID_LO),
                       CPU_ID_HI_D = (BASE_REG << CPU_ID_HI),
                       CPU_NR_D    = (BASE_REG << CPU_NR);
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};
wire [DEC_SZ-1:0] reg_dec      = (IE1_D        &  {DEC_SZ{(reg_addr==(IE1       >>1))}})  |
                                 (IFG1_D       &  {DEC_SZ{(reg_addr==(IFG1      >>1))}})  |
                                 (CPU_ID_LO_D  &  {DEC_SZ{(reg_addr==(CPU_ID_LO >>1))}})  |
                                 (CPU_ID_HI_D  &  {DEC_SZ{(reg_addr==(CPU_ID_HI >>1))}})  |
                                 (CPU_NR_D     &  {DEC_SZ{(reg_addr==(CPU_NR    >>1))}});
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}};
wire [7:0] ie1;
wire       ie1_wr  = IE1[0] ? reg_hi_wr[IE1] : reg_lo_wr[IE1];
wire [7:0] ie1_nxt = IE1[0] ? per_din[15:8]  : per_din[7:0];
reg        nmie;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      nmie  <=  1'b0;
  else if (nmi_acc) nmie  <=  1'b0; 
  else if (ie1_wr)  nmie  <=  ie1_nxt[4];    
reg        wdtie;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)      wdtie <=  1'b0;
  else if (ie1_wr)  wdtie <=  ie1_nxt[0];    
assign  ie1 = {3'b000, nmie, 3'b000, wdtie};
wire [7:0] ifg1;
wire       ifg1_wr  = IFG1[0] ? reg_hi_wr[IFG1] : reg_lo_wr[IFG1];
wire [7:0] ifg1_nxt = IFG1[0] ? per_din[15:8]   : per_din[7:0];
reg        nmiifg;
wire       nmi_edge;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       nmiifg <=  1'b0;
  else if (nmi_edge) nmiifg <=  1'b1;
  else if (ifg1_wr)  nmiifg <=  ifg1_nxt[4];
assign  wdtifg_sw_clr = ifg1_wr & ~ifg1_nxt[0];
assign  wdtifg_sw_set = ifg1_wr &  ifg1_nxt[0];
assign  ifg1 = {3'b000, nmiifg, 3'b000, wdtifg};
wire  [2:0] cpu_version  =  3'h2;
wire        cpu_asic     =  1'b0;
wire  [4:0] user_version =  5'b00000;
wire  [6:0] per_space    = (512  >> 9);   
wire        mpy_info     =  1'b1;
wire  [8:0] dmem_size    = (128 >> 7);   
wire  [5:0] pmem_size    = (2048 >> 10);  
assign      cpu_id       = {pmem_size,
			    dmem_size,
			    mpy_info,
			    per_space,
			    user_version,
			    cpu_asic,
                            cpu_version};
wire [15:0] cpu_nr = {cpu_nr_total, cpu_nr_inst};
wire [15:0] ie1_rd        = {8'h00, (ie1  &  {8{reg_rd[IE1]}})}  << (8 & {4{IE1[0]}});
wire [15:0] ifg1_rd       = {8'h00, (ifg1 &  {8{reg_rd[IFG1]}})} << (8 & {4{IFG1[0]}});
wire [15:0] cpu_id_lo_rd  = cpu_id[15:0]  & {16{reg_rd[CPU_ID_LO]}};
wire [15:0] cpu_id_hi_rd  = cpu_id[31:16] & {16{reg_rd[CPU_ID_HI]}};
wire [15:0] cpu_nr_rd     = cpu_nr        & {16{reg_rd[CPU_NR]}};
wire [15:0] per_dout =  ie1_rd       |
                        ifg1_rd      |
                        cpu_id_lo_rd |
                        cpu_id_hi_rd |
                        cpu_nr_rd;
wire nmi_pol = nmi ^ wdtnmies;
   wire   nmi_capture = nmi_pol;
   wire   nmi_s;
   omsp_sync_cell sync_cell_nmi (
       .data_out  (nmi_s),
       .data_in   (nmi_capture),
       .clk       (mclk),
       .rst       (puc_rst)
   );
reg  nmi_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) nmi_dly <= 1'b0;
  else         nmi_dly <= nmi_s;
assign      nmi_edge  = ~nmi_dly & nmi_s;
wire        nmi_pnd   = nmiifg & nmie;
wire        nmi_wkup  = 1'b0;
endmodule  
module  omsp_sync_cell (
    data_out,                       
    clk,                            
    data_in,                        
    rst                             
);
output              data_out;       
input               clk;           
input               data_in;       
input               rst;           
reg  [1:0] data_sync;
always @(posedge clk or posedge rst)
  if (rst) data_sync <=  2'b00;
  else     data_sync <=  {data_sync[0], data_in};
assign     data_out   =   data_sync[1];
endmodule  
module  omsp_sync_reset (
    rst_s,                         
    clk,                           
    rst_a                          
);
output              rst_s;         
input               clk;           
input               rst_a;         
reg    [1:0] data_sync;
always @(posedge clk or posedge rst_a)
  if (rst_a) data_sync <=  2'b11;
  else       data_sync <=  {data_sync[0], 1'b0};
assign       rst_s      =   data_sync[1];
endmodule  
module  omsp_wakeup_cell (
    wkup_out,                   
    scan_clk,                   
    scan_mode,                  
    scan_rst,                   
    wkup_clear,                 
    wkup_event                  
);
output         wkup_out;        
input          scan_clk;        
input          scan_mode;       
input          scan_rst;        
input          wkup_clear;      
input          wkup_event;      
   wire wkup_rst  =  wkup_clear;
   wire wkup_clk  =  wkup_event;
reg    wkup_out;
always @(posedge wkup_clk or posedge wkup_rst)
  if (wkup_rst) wkup_out <= 1'b0;
  else          wkup_out <= 1'b1;
endmodule  
module  omsp_watchdog (
    per_dout,                        
    wdt_irq,                         
    wdt_reset,                       
    wdt_wkup,                        
    wdtifg,                          
    wdtnmies,                        
    aclk,                            
    aclk_en,                         
    dbg_freeze,                      
    mclk,                            
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    por,                             
    puc_rst,                         
    scan_enable,                     
    scan_mode,                       
    smclk,                           
    smclk_en,                        
    wdtie,                           
    wdtifg_irq_clr,                  
    wdtifg_sw_clr,                   
    wdtifg_sw_set                    
);
output       [15:0] per_dout;        
output              wdt_irq;         
output              wdt_reset;       
output              wdt_wkup;        
output              wdtifg;          
output              wdtnmies;        
input               aclk;            
input               aclk_en;         
input               dbg_freeze;      
input               mclk;            
input        [13:0] per_addr;        
input        [15:0] per_din;         
input               per_en;          
input         [1:0] per_we;          
input               por;             
input               puc_rst;         
input               scan_enable;     
input               scan_mode;       
input               smclk;           
input               smclk_en;        
input               wdtie;           
input               wdtifg_irq_clr;  
input               wdtifg_sw_clr;   
input               wdtifg_sw_set;   
parameter       [14:0] BASE_ADDR   = 15'h0120;
parameter              DEC_WD      =  2;
parameter [DEC_WD-1:0] WDTCTL      = 'h0;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] WDTCTL_D    = (BASE_REG << WDTCTL);
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};
wire [DEC_SZ-1:0] reg_dec   =  (WDTCTL_D & {DEC_SZ{(reg_addr==WDTCTL)}});
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};
reg  [7:0] wdtctl;
wire       wdtctl_wr = reg_wr[WDTCTL];
wire       mclk_wdtctl = mclk;
parameter [7:0] WDTNMIES_MASK = 8'h40;
parameter [7:0] WDTSSEL_MASK  = 8'h04;
parameter [7:0] WDTCTL_MASK   = (8'b1001_0011 | WDTSSEL_MASK | WDTNMIES_MASK);
always @ (posedge mclk_wdtctl or posedge puc_rst)
  if (puc_rst)        wdtctl <=  8'h00;
  else if (wdtctl_wr) wdtctl <=  per_din[7:0] & WDTCTL_MASK;
wire       wdtpw_error = wdtctl_wr & (per_din[15:8]!=8'h5a);
wire       wdttmsel    = wdtctl[4];
wire       wdtnmies    = wdtctl[6];
parameter [7:0] WDTNMI_RD_MASK  = 8'h20;
parameter [7:0] WDTSSEL_RD_MASK = 8'h00;
parameter [7:0] WDTCTL_RD_MASK  = WDTNMI_RD_MASK | WDTSSEL_RD_MASK;
wire [15:0] wdtctl_rd  = {8'h69, wdtctl | WDTCTL_RD_MASK} & {16{reg_rd[WDTCTL]}};
wire [15:0] per_dout   =  wdtctl_rd;
wire  clk_src_en = wdtctl[2] ? aclk_en : smclk_en;
reg [15:0] wdtcnt;
wire        wdtifg_evt;
wire        wdtcnt_clr  = (wdtctl_wr & per_din[3]) | wdtifg_evt;
wire        wdtcnt_incr = ~wdtctl[7] & clk_src_en & ~dbg_freeze;
wire [15:0] wdtcnt_nxt  = wdtcnt+16'h0001;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)           wdtcnt <= 16'h0000;
  else if (wdtcnt_clr)   wdtcnt <= 16'h0000;
  else if (wdtcnt_incr)  wdtcnt <= wdtcnt_nxt;
reg        wdtqn;
always @(wdtctl or wdtcnt_nxt)
    case(wdtctl[1:0])
      2'b00  : wdtqn =  wdtcnt_nxt[15];
      2'b01  : wdtqn =  wdtcnt_nxt[13];
      2'b10  : wdtqn =  wdtcnt_nxt[9];
      default: wdtqn =  wdtcnt_nxt[6];
    endcase
assign     wdtifg_evt =  (wdtqn & wdtcnt_incr) | wdtpw_error;
reg        wdtifg;
wire       wdtifg_set =  wdtifg_evt                  |  wdtifg_sw_set;
wire       wdtifg_clr =  (wdtifg_irq_clr & wdttmsel) |  wdtifg_sw_clr;
always @ (posedge mclk or posedge por)
  if (por)             wdtifg <=  1'b0;
  else if (wdtifg_set) wdtifg <=  1'b1;
  else if (wdtifg_clr) wdtifg <=  1'b0;
wire    wdt_irq       = wdttmsel & wdtifg & wdtie;
wire    wdt_wkup      =  1'b0;
reg     wdt_reset;
always @ (posedge mclk or posedge por)
  if (por) wdt_reset <= 1'b0;
  else     wdt_reset <= wdtpw_error | (wdtifg_set & ~wdttmsel);
endmodule  
module  openMSP430 (
    aclk,                                
    aclk_en,                             
    dbg_freeze,                          
    dbg_i2c_sda_out,                     
    dbg_uart_txd,                        
    dco_enable,                          
    dco_wkup,                            
    dmem_addr,                           
    dmem_cen,                            
    dmem_din,                            
    dmem_wen,                            
    irq_acc,                             
    lfxt_enable,                         
    lfxt_wkup,                           
    mclk,                                
    per_addr,                            
    per_din,                             
    per_we,                              
    per_en,                              
    pmem_addr,                           
    pmem_cen,                            
    pmem_din,                            
    pmem_wen,                            
    puc_rst,                             
    smclk,                               
    smclk_en,                            
    cpu_en,                              
    dbg_en,                              
    dbg_i2c_addr,                        
    dbg_i2c_broadcast,                   
    dbg_i2c_scl,                         
    dbg_i2c_sda_in,                      
    dbg_uart_rxd,                        
    dco_clk,                             
    dmem_dout,                           
    irq,                                 
    lfxt_clk,                            
    nmi,                                 
    per_dout,                            
    pmem_dout,                           
    reset_n,                             
    scan_enable,                         
    scan_mode,                           
    wkup                                 
);
parameter            INST_NR  = 8'h00;   
parameter            TOTAL_NR = 8'h00;   
output               aclk;               
output               aclk_en;            
output               dbg_freeze;         
output               dbg_i2c_sda_out;    
output               dbg_uart_txd;       
output               dco_enable;         
output               dco_wkup;           
output [6-1:0] dmem_addr;          
output               dmem_cen;           
output        [15:0] dmem_din;           
output         [1:0] dmem_wen;           
output [64-3:0] irq_acc;            
output               lfxt_enable;        
output               lfxt_wkup;          
output               mclk;               
output        [13:0] per_addr;           
output        [15:0] per_din;            
output         [1:0] per_we;             
output               per_en;             
output [10-1:0] pmem_addr;          
output               pmem_cen;           
output        [15:0] pmem_din;           
output         [1:0] pmem_wen;           
output               puc_rst;            
output               smclk;              
output               smclk_en;           
input                cpu_en;             
input                dbg_en;             
input          [6:0] dbg_i2c_addr;       
input          [6:0] dbg_i2c_broadcast;  
input                dbg_i2c_scl;        
input                dbg_i2c_sda_in;     
input                dbg_uart_rxd;       
input                dco_clk;            
input         [15:0] dmem_dout;          
input  [64-3:0] irq;                
input                lfxt_clk;           
input  	             nmi;                
input         [15:0] per_dout;           
input         [15:0] pmem_dout;          
input                reset_n;            
input                scan_enable;        
input                scan_mode;          
input                wkup;               
wire          [7:0] inst_ad;
wire          [7:0] inst_as;
wire         [11:0] inst_alu;
wire                inst_bw;
wire                inst_irq_rst;
wire                inst_mov;
wire         [15:0] inst_dest;
wire         [15:0] inst_dext;
wire         [15:0] inst_sext;
wire          [7:0] inst_so;
wire         [15:0] inst_src;
wire          [2:0] inst_type;
wire          [7:0] inst_jmp;
wire          [3:0] e_state;
wire                exec_done;
wire                decode_noirq;
wire                cpu_en_s;
wire                cpuoff;
wire                oscoff;
wire                scg0;
wire                scg1;
wire                por;
wire                gie;
wire                mclk_enable;
wire                mclk_wkup;
wire         [31:0] cpu_id;
wire          [7:0] cpu_nr_inst  = INST_NR;
wire          [7:0] cpu_nr_total = TOTAL_NR;
wire         [15:0] eu_mab;
wire         [15:0] eu_mdb_in;
wire         [15:0] eu_mdb_out;
wire          [1:0] eu_mb_wr;
wire                eu_mb_en;
wire         [15:0] fe_mab;
wire         [15:0] fe_mdb_in;
wire                fe_mb_en;
wire                fe_pmem_wait;
wire                pc_sw_wr;
wire         [15:0] pc_sw;
wire         [15:0] pc;
wire         [15:0] pc_nxt;
wire                nmi_acc;
wire                nmi_pnd;
wire                nmi_wkup;
wire                wdtie;
wire                wdtnmies;
wire                wdtifg;
wire                wdt_irq;
wire                wdt_wkup;
wire                wdt_reset;
wire                wdtifg_sw_clr;
wire                wdtifg_sw_set;
wire                dbg_clk;
wire                dbg_rst;
wire                dbg_en_s;
wire                dbg_halt_st;
wire                dbg_halt_cmd;
wire                dbg_mem_en;
wire                dbg_reg_wr;
wire                dbg_cpu_reset;
wire         [15:0] dbg_mem_addr;
wire         [15:0] dbg_mem_dout;
wire         [15:0] dbg_mem_din;
wire         [15:0] dbg_reg_din;
wire          [1:0] dbg_mem_wr;
wire                puc_pnd_set;
wire         [15:0] per_dout_or;
wire         [15:0] per_dout_sfr;
wire         [15:0] per_dout_wdog;
wire         [15:0] per_dout_mpy;
wire         [15:0] per_dout_clk;
omsp_clock_module clock_module_0 (
    .aclk         (aclk),           
    .aclk_en      (aclk_en),        
    .cpu_en_s     (cpu_en_s),       
    .dbg_clk      (dbg_clk),        
    .dbg_en_s     (dbg_en_s),       
    .dbg_rst      (dbg_rst),        
    .dco_enable   (dco_enable),     
    .dco_wkup     (dco_wkup),       
    .lfxt_enable  (lfxt_enable),    
    .lfxt_wkup    (lfxt_wkup),      
    .mclk         (mclk),           
    .per_dout     (per_dout_clk),   
    .por          (por),            
    .puc_pnd_set  (puc_pnd_set),    
    .puc_rst      (puc_rst),        
    .smclk        (smclk),          
    .smclk_en     (smclk_en),       
    .cpu_en       (cpu_en),         
    .cpuoff       (cpuoff),         
    .dbg_cpu_reset(dbg_cpu_reset),  
    .dbg_en       (dbg_en),         
    .dco_clk      (dco_clk),        
    .lfxt_clk     (lfxt_clk),       
    .mclk_enable  (mclk_enable),    
    .mclk_wkup    (mclk_wkup),      
    .oscoff       (oscoff),         
    .per_addr     (per_addr),       
    .per_din      (per_din),        
    .per_en       (per_en),         
    .per_we       (per_we),         
    .reset_n      (reset_n),        
    .scan_enable  (scan_enable),    
    .scan_mode    (scan_mode),      
    .scg0         (scg0),           
    .scg1         (scg1),           
    .wdt_reset    (wdt_reset)       
);
omsp_frontend frontend_0 (
    .dbg_halt_st  (dbg_halt_st),    
    .decode_noirq (decode_noirq),   
    .e_state      (e_state),        
    .exec_done    (exec_done),      
    .inst_ad      (inst_ad),        
    .inst_as      (inst_as),        
    .inst_alu     (inst_alu),       
    .inst_bw      (inst_bw),        
    .inst_dest    (inst_dest),      
    .inst_dext    (inst_dext),      
    .inst_irq_rst (inst_irq_rst),   
    .inst_jmp     (inst_jmp),       
    .inst_mov     (inst_mov),       
    .inst_sext    (inst_sext),      
    .inst_so      (inst_so),        
    .inst_src     (inst_src),       
    .inst_type    (inst_type),      
    .irq_acc      (irq_acc),        
    .mab          (fe_mab),         
    .mb_en        (fe_mb_en),       
    .mclk_enable  (mclk_enable),    
    .mclk_wkup    (mclk_wkup),      
    .nmi_acc      (nmi_acc),        
    .pc           (pc),             
    .pc_nxt       (pc_nxt),         
    .cpu_en_s     (cpu_en_s),       
    .cpuoff       (cpuoff),         
    .dbg_halt_cmd (dbg_halt_cmd),   
    .dbg_reg_sel  (dbg_mem_addr[3:0]),  
    .fe_pmem_wait (fe_pmem_wait),   
    .gie          (gie),            
    .irq          (irq),            
    .mclk         (mclk),           
    .mdb_in       (fe_mdb_in),      
    .nmi_pnd      (nmi_pnd),        
    .nmi_wkup     (nmi_wkup),       
    .pc_sw        (pc_sw),          
    .pc_sw_wr     (pc_sw_wr),       
    .puc_rst      (puc_rst),        
    .scan_enable  (scan_enable),    
    .wdt_irq      (wdt_irq),        
    .wdt_wkup     (wdt_wkup),       
    .wkup         (wkup)            
);
omsp_execution_unit execution_unit_0 (
    .cpuoff       (cpuoff),         
    .dbg_reg_din  (dbg_reg_din),    
    .mab          (eu_mab),         
    .mb_en        (eu_mb_en),       
    .mb_wr        (eu_mb_wr),       
    .mdb_out      (eu_mdb_out),     
    .oscoff       (oscoff),         
    .pc_sw        (pc_sw),          
    .pc_sw_wr     (pc_sw_wr),       
    .scg0         (scg0),           
    .scg1         (scg1),           
    .dbg_halt_st  (dbg_halt_st),    
    .dbg_mem_dout (dbg_mem_dout),   
    .dbg_reg_wr   (dbg_reg_wr),     
    .e_state      (e_state),        
    .exec_done    (exec_done),      
    .gie          (gie),            
    .inst_ad      (inst_ad),        
    .inst_as      (inst_as),        
    .inst_alu     (inst_alu),       
    .inst_bw      (inst_bw),        
    .inst_dest    (inst_dest),      
    .inst_dext    (inst_dext),      
    .inst_irq_rst (inst_irq_rst),   
    .inst_jmp     (inst_jmp),       
    .inst_mov     (inst_mov),       
    .inst_sext    (inst_sext),      
    .inst_so      (inst_so),        
    .inst_src     (inst_src),       
    .inst_type    (inst_type),      
    .mclk         (mclk),           
    .mdb_in       (eu_mdb_in),      
    .pc           (pc),             
    .pc_nxt       (pc_nxt),         
    .puc_rst      (puc_rst),        
    .scan_enable  (scan_enable)     
);
omsp_mem_backbone mem_backbone_0 (
    .dbg_mem_din  (dbg_mem_din),    
    .dmem_addr    (dmem_addr),      
    .dmem_cen     (dmem_cen),       
    .dmem_din     (dmem_din),       
    .dmem_wen     (dmem_wen),       
    .eu_mdb_in    (eu_mdb_in),      
    .fe_mdb_in    (fe_mdb_in),      
    .fe_pmem_wait (fe_pmem_wait),   
    .per_addr     (per_addr),       
    .per_din      (per_din),        
    .per_we       (per_we),         
    .per_en       (per_en),         
    .pmem_addr    (pmem_addr),      
    .pmem_cen     (pmem_cen),       
    .pmem_din     (pmem_din),       
    .pmem_wen     (pmem_wen),       
    .dbg_halt_st  (dbg_halt_st),    
    .dbg_mem_addr (dbg_mem_addr),   
    .dbg_mem_dout (dbg_mem_dout),   
    .dbg_mem_en   (dbg_mem_en),     
    .dbg_mem_wr   (dbg_mem_wr),     
    .dmem_dout    (dmem_dout),      
    .eu_mab       (eu_mab[15:1]),   
    .eu_mb_en     (eu_mb_en),       
    .eu_mb_wr     (eu_mb_wr),       
    .eu_mdb_out   (eu_mdb_out),     
    .fe_mab       (fe_mab[15:1]),   
    .fe_mb_en     (fe_mb_en),       
    .mclk         (mclk),           
    .per_dout     (per_dout_or),    
    .pmem_dout    (pmem_dout),      
    .puc_rst      (puc_rst),        
    .scan_enable  (scan_enable)     
);
omsp_sfr sfr_0 (
    .cpu_id       (cpu_id),         
    .nmi_pnd      (nmi_pnd),        
    .nmi_wkup     (nmi_wkup),       
    .per_dout     (per_dout_sfr),   
    .wdtie        (wdtie),          
    .wdtifg_sw_clr(wdtifg_sw_clr),  
    .wdtifg_sw_set(wdtifg_sw_set),  
    .cpu_nr_inst  (cpu_nr_inst),    
    .cpu_nr_total (cpu_nr_total),   
    .mclk         (mclk),           
    .nmi          (nmi),            
    .nmi_acc      (nmi_acc),        
    .per_addr     (per_addr),       
    .per_din      (per_din),        
    .per_en       (per_en),         
    .per_we       (per_we),         
    .puc_rst      (puc_rst),        
    .scan_mode    (scan_mode),      
    .wdtifg       (wdtifg),         
    .wdtnmies     (wdtnmies)        
);
omsp_watchdog watchdog_0 (
    .per_dout       (per_dout_wdog),       
    .wdt_irq        (wdt_irq),             
    .wdt_reset      (wdt_reset),           
    .wdt_wkup       (wdt_wkup),            
    .wdtifg         (wdtifg),              
    .wdtnmies       (wdtnmies),            
    .aclk           (aclk),                
    .aclk_en        (aclk_en),             
    .dbg_freeze     (dbg_freeze),          
    .mclk           (mclk),                
    .per_addr       (per_addr),            
    .per_din        (per_din),             
    .per_en         (per_en),              
    .per_we         (per_we),              
    .por            (por),                 
    .puc_rst        (puc_rst),             
    .scan_enable    (scan_enable),         
    .scan_mode      (scan_mode),           
    .smclk          (smclk),               
    .smclk_en       (smclk_en),            
    .wdtie          (wdtie),               
    .wdtifg_irq_clr (irq_acc[64-6]),  
    .wdtifg_sw_clr  (wdtifg_sw_clr),       
    .wdtifg_sw_set  (wdtifg_sw_set)        
);
omsp_multiplier multiplier_0 (
    .per_dout     (per_dout_mpy),   
    .mclk         (mclk),           
    .per_addr     (per_addr),       
    .per_din      (per_din),        
    .per_en       (per_en),         
    .per_we       (per_we),         
    .puc_rst      (puc_rst),        
    .scan_enable  (scan_enable)     
);
assign  per_dout_or  =  per_dout      |
                        per_dout_clk  |
                        per_dout_sfr  |
                        per_dout_wdog |
                        per_dout_mpy;
omsp_dbg dbg_0 (
    .dbg_cpu_reset     (dbg_cpu_reset),      
    .dbg_freeze        (dbg_freeze),         
    .dbg_halt_cmd      (dbg_halt_cmd),       
    .dbg_i2c_sda_out   (dbg_i2c_sda_out),    
    .dbg_mem_addr      (dbg_mem_addr),       
    .dbg_mem_dout      (dbg_mem_dout),       
    .dbg_mem_en        (dbg_mem_en),         
    .dbg_mem_wr        (dbg_mem_wr),         
    .dbg_reg_wr        (dbg_reg_wr),         
    .dbg_uart_txd      (dbg_uart_txd),       
    .cpu_en_s          (cpu_en_s),           
    .cpu_id            (cpu_id),             
    .cpu_nr_inst       (cpu_nr_inst),        
    .cpu_nr_total      (cpu_nr_total),       
    .dbg_clk           (dbg_clk),            
    .dbg_en_s          (dbg_en_s),           
    .dbg_halt_st       (dbg_halt_st),        
    .dbg_i2c_addr      (dbg_i2c_addr),       
    .dbg_i2c_broadcast (dbg_i2c_broadcast),  
    .dbg_i2c_scl       (dbg_i2c_scl),        
    .dbg_i2c_sda_in    (dbg_i2c_sda_in),     
    .dbg_mem_din       (dbg_mem_din),        
    .dbg_reg_din       (dbg_reg_din),        
    .dbg_rst           (dbg_rst),            
    .dbg_uart_rxd      (dbg_uart_rxd),       
    .decode_noirq      (decode_noirq),       
    .eu_mab            (eu_mab),             
    .eu_mb_en          (eu_mb_en),           
    .eu_mb_wr          (eu_mb_wr),           
    .fe_mdb_in         (fe_mdb_in),          
    .pc                (pc),                 
    .puc_pnd_set       (puc_pnd_set)         
);
endmodule  
module  omsp_gpio (
    irq_port1,                       
    irq_port2,                       
    p1_dout,                         
    p1_dout_en,                      
    p1_sel,                          
    p2_dout,                         
    p2_dout_en,                      
    p2_sel,                          
    p3_dout,                         
    p3_dout_en,                      
    p3_sel,                          
    p4_dout,                         
    p4_dout_en,                      
    p4_sel,                          
    p5_dout,                         
    p5_dout_en,                      
    p5_sel,                          
    p6_dout,                         
    p6_dout_en,                      
    p6_sel,                          
    per_dout,                        
    mclk,                            
    p1_din,                          
    p2_din,                          
    p3_din,                          
    p4_din,                          
    p5_din,                          
    p6_din,                          
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    puc_rst                          
);
parameter           P1_EN = 1'b1;    
parameter           P2_EN = 1'b1;    
parameter           P3_EN = 1'b0;    
parameter           P4_EN = 1'b0;    
parameter           P5_EN = 1'b0;    
parameter           P6_EN = 1'b0;    
output              irq_port1;       
output              irq_port2;       
output        [7:0] p1_dout;         
output        [7:0] p1_dout_en;      
output        [7:0] p1_sel;          
output        [7:0] p2_dout;         
output        [7:0] p2_dout_en;      
output        [7:0] p2_sel;          
output        [7:0] p3_dout;         
output        [7:0] p3_dout_en;      
output        [7:0] p3_sel;          
output        [7:0] p4_dout;         
output        [7:0] p4_dout_en;      
output        [7:0] p4_sel;          
output        [7:0] p5_dout;         
output        [7:0] p5_dout_en;      
output        [7:0] p5_sel;          
output        [7:0] p6_dout;         
output        [7:0] p6_dout_en;      
output        [7:0] p6_sel;          
output       [15:0] per_dout;        
input               mclk;            
input         [7:0] p1_din;          
input         [7:0] p2_din;          
input         [7:0] p3_din;          
input         [7:0] p4_din;          
input         [7:0] p5_din;          
input         [7:0] p6_din;          
input        [13:0] per_addr;        
input        [15:0] per_din;         
input               per_en;          
input         [1:0] per_we;          
input               puc_rst;         
parameter              P1_EN_MSK   = {8{P1_EN[0]}};
parameter              P2_EN_MSK   = {8{P2_EN[0]}};
parameter              P3_EN_MSK   = {8{P3_EN[0]}};
parameter              P4_EN_MSK   = {8{P4_EN[0]}};
parameter              P5_EN_MSK   = {8{P5_EN[0]}};
parameter              P6_EN_MSK   = {8{P6_EN[0]}};
parameter       [14:0] BASE_ADDR   = 15'h0000;
parameter              DEC_WD      =  6;
parameter [DEC_WD-1:0] P1IN        = 'h20,                     
                       P1OUT       = 'h21,
                       P1DIR       = 'h22,
                       P1IFG       = 'h23,
                       P1IES       = 'h24,
                       P1IE        = 'h25,
                       P1SEL       = 'h26,
                       P2IN        = 'h28,                     
                       P2OUT       = 'h29,
                       P2DIR       = 'h2A,
                       P2IFG       = 'h2B,
                       P2IES       = 'h2C,
                       P2IE        = 'h2D,
                       P2SEL       = 'h2E,
                       P3IN        = 'h18,                     
                       P3OUT       = 'h19,
                       P3DIR       = 'h1A,
                       P3SEL       = 'h1B,
                       P4IN        = 'h1C,                     
                       P4OUT       = 'h1D,
                       P4DIR       = 'h1E,
                       P4SEL       = 'h1F,
                       P5IN        = 'h30,                     
                       P5OUT       = 'h31,
                       P5DIR       = 'h32,
                       P5SEL       = 'h33,
                       P6IN        = 'h34,                     
                       P6OUT       = 'h35,
                       P6DIR       = 'h36,
                       P6SEL       = 'h37;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] P1IN_D      =  (BASE_REG << P1IN),      
                       P1OUT_D     =  (BASE_REG << P1OUT),
                       P1DIR_D     =  (BASE_REG << P1DIR),
                       P1IFG_D     =  (BASE_REG << P1IFG),
                       P1IES_D     =  (BASE_REG << P1IES),
                       P1IE_D      =  (BASE_REG << P1IE),
                       P1SEL_D     =  (BASE_REG << P1SEL),
                       P2IN_D      =  (BASE_REG << P2IN),      
                       P2OUT_D     =  (BASE_REG << P2OUT),
                       P2DIR_D     =  (BASE_REG << P2DIR),
                       P2IFG_D     =  (BASE_REG << P2IFG),
                       P2IES_D     =  (BASE_REG << P2IES),
                       P2IE_D      =  (BASE_REG << P2IE),
                       P2SEL_D     =  (BASE_REG << P2SEL),
                       P3IN_D      =  (BASE_REG << P3IN),      
                       P3OUT_D     =  (BASE_REG << P3OUT),
                       P3DIR_D     =  (BASE_REG << P3DIR),
                       P3SEL_D     =  (BASE_REG << P3SEL),
                       P4IN_D      =  (BASE_REG << P4IN),      
                       P4OUT_D     =  (BASE_REG << P4OUT),
                       P4DIR_D     =  (BASE_REG << P4DIR),
                       P4SEL_D     =  (BASE_REG << P4SEL),
                       P5IN_D      =  (BASE_REG << P5IN),      
                       P5OUT_D     =  (BASE_REG << P5OUT),
                       P5DIR_D     =  (BASE_REG << P5DIR),
                       P5SEL_D     =  (BASE_REG << P5SEL),
                       P6IN_D      =  (BASE_REG << P6IN),      
                       P6OUT_D     =  (BASE_REG << P6OUT),
                       P6DIR_D     =  (BASE_REG << P6DIR),
                       P6SEL_D     =  (BASE_REG << P6SEL); 
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};
wire [DEC_SZ-1:0] reg_dec      =  (P1IN_D   &  {DEC_SZ{(reg_addr==(P1IN  >>1))  &  P1_EN[0]}})  |
                                  (P1OUT_D  &  {DEC_SZ{(reg_addr==(P1OUT >>1))  &  P1_EN[0]}})  |
                                  (P1DIR_D  &  {DEC_SZ{(reg_addr==(P1DIR >>1))  &  P1_EN[0]}})  |
                                  (P1IFG_D  &  {DEC_SZ{(reg_addr==(P1IFG >>1))  &  P1_EN[0]}})  |
                                  (P1IES_D  &  {DEC_SZ{(reg_addr==(P1IES >>1))  &  P1_EN[0]}})  |
                                  (P1IE_D   &  {DEC_SZ{(reg_addr==(P1IE  >>1))  &  P1_EN[0]}})  |
                                  (P1SEL_D  &  {DEC_SZ{(reg_addr==(P1SEL >>1))  &  P1_EN[0]}})  |
                                  (P2IN_D   &  {DEC_SZ{(reg_addr==(P2IN  >>1))  &  P2_EN[0]}})  |
                                  (P2OUT_D  &  {DEC_SZ{(reg_addr==(P2OUT >>1))  &  P2_EN[0]}})  |
                                  (P2DIR_D  &  {DEC_SZ{(reg_addr==(P2DIR >>1))  &  P2_EN[0]}})  |
                                  (P2IFG_D  &  {DEC_SZ{(reg_addr==(P2IFG >>1))  &  P2_EN[0]}})  |
                                  (P2IES_D  &  {DEC_SZ{(reg_addr==(P2IES >>1))  &  P2_EN[0]}})  |
                                  (P2IE_D   &  {DEC_SZ{(reg_addr==(P2IE  >>1))  &  P2_EN[0]}})  |
                                  (P2SEL_D  &  {DEC_SZ{(reg_addr==(P2SEL >>1))  &  P2_EN[0]}})  |
                                  (P3IN_D   &  {DEC_SZ{(reg_addr==(P3IN  >>1))  &  P3_EN[0]}})  |
                                  (P3OUT_D  &  {DEC_SZ{(reg_addr==(P3OUT >>1))  &  P3_EN[0]}})  |
                                  (P3DIR_D  &  {DEC_SZ{(reg_addr==(P3DIR >>1))  &  P3_EN[0]}})  |
                                  (P3SEL_D  &  {DEC_SZ{(reg_addr==(P3SEL >>1))  &  P3_EN[0]}})  |
                                  (P4IN_D   &  {DEC_SZ{(reg_addr==(P4IN  >>1))  &  P4_EN[0]}})  |
                                  (P4OUT_D  &  {DEC_SZ{(reg_addr==(P4OUT >>1))  &  P4_EN[0]}})  |
                                  (P4DIR_D  &  {DEC_SZ{(reg_addr==(P4DIR >>1))  &  P4_EN[0]}})  |
                                  (P4SEL_D  &  {DEC_SZ{(reg_addr==(P4SEL >>1))  &  P4_EN[0]}})  |
                                  (P5IN_D   &  {DEC_SZ{(reg_addr==(P5IN  >>1))  &  P5_EN[0]}})  |
                                  (P5OUT_D  &  {DEC_SZ{(reg_addr==(P5OUT >>1))  &  P5_EN[0]}})  |
                                  (P5DIR_D  &  {DEC_SZ{(reg_addr==(P5DIR >>1))  &  P5_EN[0]}})  |
                                  (P5SEL_D  &  {DEC_SZ{(reg_addr==(P5SEL >>1))  &  P5_EN[0]}})  |
                                  (P6IN_D   &  {DEC_SZ{(reg_addr==(P6IN  >>1))  &  P6_EN[0]}})  |
                                  (P6OUT_D  &  {DEC_SZ{(reg_addr==(P6OUT >>1))  &  P6_EN[0]}})  |
                                  (P6DIR_D  &  {DEC_SZ{(reg_addr==(P6DIR >>1))  &  P6_EN[0]}})  |
                                  (P6SEL_D  &  {DEC_SZ{(reg_addr==(P6SEL >>1))  &  P6_EN[0]}});
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}}; 
wire [7:0] p1in;
omsp_sync_cell sync_cell_p1in_0 (.data_out(p1in[0]), .data_in(p1_din[0] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_1 (.data_out(p1in[1]), .data_in(p1_din[1] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_2 (.data_out(p1in[2]), .data_in(p1_din[2] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_3 (.data_out(p1in[3]), .data_in(p1_din[3] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_4 (.data_out(p1in[4]), .data_in(p1_din[4] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_5 (.data_out(p1in[5]), .data_in(p1_din[5] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_6 (.data_out(p1in[6]), .data_in(p1_din[6] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p1in_7 (.data_out(p1in[7]), .data_in(p1_din[7] & P1_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p1out;
wire       p1out_wr  = P1OUT[0] ? reg_hi_wr[P1OUT] : reg_lo_wr[P1OUT];
wire [7:0] p1out_nxt = P1OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p1out <=  8'h00;
  else if (p1out_wr)  p1out <=  p1out_nxt & P1_EN_MSK;
assign p1_dout = p1out;
reg  [7:0] p1dir;
wire       p1dir_wr  = P1DIR[0] ? reg_hi_wr[P1DIR] : reg_lo_wr[P1DIR];
wire [7:0] p1dir_nxt = P1DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p1dir <=  8'h00;
  else if (p1dir_wr)  p1dir <=  p1dir_nxt & P1_EN_MSK;
assign p1_dout_en = p1dir;
reg  [7:0] p1ifg;
wire       p1ifg_wr  = P1IFG[0] ? reg_hi_wr[P1IFG] : reg_lo_wr[P1IFG];
wire [7:0] p1ifg_nxt = P1IFG[0] ? per_din[15:8]    : per_din[7:0];
wire [7:0] p1ifg_set;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p1ifg <=  8'h00;
  else if (p1ifg_wr)  p1ifg <=  (p1ifg_nxt | p1ifg_set) & P1_EN_MSK;
  else                p1ifg <=  (p1ifg     | p1ifg_set) & P1_EN_MSK;
reg  [7:0] p1ies;
wire       p1ies_wr  = P1IES[0] ? reg_hi_wr[P1IES] : reg_lo_wr[P1IES];
wire [7:0] p1ies_nxt = P1IES[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p1ies <=  8'h00;
  else if (p1ies_wr)  p1ies <=  p1ies_nxt & P1_EN_MSK;
reg  [7:0] p1ie;
wire       p1ie_wr  = P1IE[0] ? reg_hi_wr[P1IE] : reg_lo_wr[P1IE];
wire [7:0] p1ie_nxt = P1IE[0] ? per_din[15:8]   : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p1ie <=  8'h00;
  else if (p1ie_wr)  p1ie <=  p1ie_nxt & P1_EN_MSK;
reg  [7:0] p1sel;
wire       p1sel_wr  = P1SEL[0] ? reg_hi_wr[P1SEL] : reg_lo_wr[P1SEL];
wire [7:0] p1sel_nxt = P1SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p1sel <=  8'h00;
  else if (p1sel_wr) p1sel <=  p1sel_nxt & P1_EN_MSK;
assign p1_sel = p1sel;
wire [7:0] p2in;
omsp_sync_cell sync_cell_p2in_0 (.data_out(p2in[0]), .data_in(p2_din[0] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_1 (.data_out(p2in[1]), .data_in(p2_din[1] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_2 (.data_out(p2in[2]), .data_in(p2_din[2] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_3 (.data_out(p2in[3]), .data_in(p2_din[3] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_4 (.data_out(p2in[4]), .data_in(p2_din[4] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_5 (.data_out(p2in[5]), .data_in(p2_din[5] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_6 (.data_out(p2in[6]), .data_in(p2_din[6] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p2in_7 (.data_out(p2in[7]), .data_in(p2_din[7] & P2_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p2out;
wire       p2out_wr  = P2OUT[0] ? reg_hi_wr[P2OUT] : reg_lo_wr[P2OUT];
wire [7:0] p2out_nxt = P2OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p2out <=  8'h00;
  else if (p2out_wr)  p2out <=  p2out_nxt & P2_EN_MSK;
assign p2_dout = p2out;
reg  [7:0] p2dir;
wire       p2dir_wr  = P2DIR[0] ? reg_hi_wr[P2DIR] : reg_lo_wr[P2DIR];
wire [7:0] p2dir_nxt = P2DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p2dir <=  8'h00;
  else if (p2dir_wr)  p2dir <=  p2dir_nxt & P2_EN_MSK;
assign p2_dout_en = p2dir;
reg  [7:0] p2ifg;
wire       p2ifg_wr  = P2IFG[0] ? reg_hi_wr[P2IFG] : reg_lo_wr[P2IFG];
wire [7:0] p2ifg_nxt = P2IFG[0] ? per_din[15:8]    : per_din[7:0];
wire [7:0] p2ifg_set;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p2ifg <=  8'h00;
  else if (p2ifg_wr)  p2ifg <=  (p2ifg_nxt | p2ifg_set) & P2_EN_MSK;
  else                p2ifg <=  (p2ifg     | p2ifg_set) & P2_EN_MSK;
reg  [7:0] p2ies;
wire       p2ies_wr  = P2IES[0] ? reg_hi_wr[P2IES] : reg_lo_wr[P2IES];
wire [7:0] p2ies_nxt = P2IES[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p2ies <=  8'h00;
  else if (p2ies_wr)  p2ies <=  p2ies_nxt & P2_EN_MSK;
reg  [7:0] p2ie;
wire       p2ie_wr  = P2IE[0] ? reg_hi_wr[P2IE] : reg_lo_wr[P2IE];
wire [7:0] p2ie_nxt = P2IE[0] ? per_din[15:8]   : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p2ie <=  8'h00;
  else if (p2ie_wr)  p2ie <=  p2ie_nxt & P2_EN_MSK;
reg  [7:0] p2sel;
wire       p2sel_wr  = P2SEL[0] ? reg_hi_wr[P2SEL] : reg_lo_wr[P2SEL];
wire [7:0] p2sel_nxt = P2SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p2sel <=  8'h00;
  else if (p2sel_wr) p2sel <=  p2sel_nxt & P2_EN_MSK;
assign p2_sel = p2sel;
wire  [7:0] p3in;
omsp_sync_cell sync_cell_p3in_0 (.data_out(p3in[0]), .data_in(p3_din[0] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_1 (.data_out(p3in[1]), .data_in(p3_din[1] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_2 (.data_out(p3in[2]), .data_in(p3_din[2] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_3 (.data_out(p3in[3]), .data_in(p3_din[3] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_4 (.data_out(p3in[4]), .data_in(p3_din[4] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_5 (.data_out(p3in[5]), .data_in(p3_din[5] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_6 (.data_out(p3in[6]), .data_in(p3_din[6] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p3in_7 (.data_out(p3in[7]), .data_in(p3_din[7] & P3_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p3out;
wire       p3out_wr  = P3OUT[0] ? reg_hi_wr[P3OUT] : reg_lo_wr[P3OUT];
wire [7:0] p3out_nxt = P3OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p3out <=  8'h00;
  else if (p3out_wr)  p3out <=  p3out_nxt & P3_EN_MSK;
assign p3_dout = p3out;
reg  [7:0] p3dir;
wire       p3dir_wr  = P3DIR[0] ? reg_hi_wr[P3DIR] : reg_lo_wr[P3DIR];
wire [7:0] p3dir_nxt = P3DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p3dir <=  8'h00;
  else if (p3dir_wr)  p3dir <=  p3dir_nxt & P3_EN_MSK;
assign p3_dout_en = p3dir;
reg  [7:0] p3sel;
wire       p3sel_wr  = P3SEL[0] ? reg_hi_wr[P3SEL] : reg_lo_wr[P3SEL];
wire [7:0] p3sel_nxt = P3SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p3sel <=  8'h00;
  else if (p3sel_wr) p3sel <=  p3sel_nxt & P3_EN_MSK;
assign p3_sel = p3sel;
wire  [7:0] p4in;
omsp_sync_cell sync_cell_p4in_0 (.data_out(p4in[0]), .data_in(p4_din[0] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_1 (.data_out(p4in[1]), .data_in(p4_din[1] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_2 (.data_out(p4in[2]), .data_in(p4_din[2] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_3 (.data_out(p4in[3]), .data_in(p4_din[3] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_4 (.data_out(p4in[4]), .data_in(p4_din[4] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_5 (.data_out(p4in[5]), .data_in(p4_din[5] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_6 (.data_out(p4in[6]), .data_in(p4_din[6] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p4in_7 (.data_out(p4in[7]), .data_in(p4_din[7] & P4_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p4out;
wire       p4out_wr  = P4OUT[0] ? reg_hi_wr[P4OUT] : reg_lo_wr[P4OUT];
wire [7:0] p4out_nxt = P4OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p4out <=  8'h00;
  else if (p4out_wr)  p4out <=  p4out_nxt & P4_EN_MSK;
assign p4_dout = p4out;
reg  [7:0] p4dir;
wire       p4dir_wr  = P4DIR[0] ? reg_hi_wr[P4DIR] : reg_lo_wr[P4DIR];
wire [7:0] p4dir_nxt = P4DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p4dir <=  8'h00;
  else if (p4dir_wr)  p4dir <=  p4dir_nxt & P4_EN_MSK;
assign p4_dout_en = p4dir;
reg  [7:0] p4sel;
wire       p4sel_wr  = P4SEL[0] ? reg_hi_wr[P4SEL] : reg_lo_wr[P4SEL];
wire [7:0] p4sel_nxt = P4SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p4sel <=  8'h00;
  else if (p4sel_wr) p4sel <=  p4sel_nxt & P4_EN_MSK;
assign p4_sel = p4sel;
wire  [7:0] p5in;
omsp_sync_cell sync_cell_p5in_0 (.data_out(p5in[0]), .data_in(p5_din[0] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_1 (.data_out(p5in[1]), .data_in(p5_din[1] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_2 (.data_out(p5in[2]), .data_in(p5_din[2] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_3 (.data_out(p5in[3]), .data_in(p5_din[3] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_4 (.data_out(p5in[4]), .data_in(p5_din[4] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_5 (.data_out(p5in[5]), .data_in(p5_din[5] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_6 (.data_out(p5in[6]), .data_in(p5_din[6] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p5in_7 (.data_out(p5in[7]), .data_in(p5_din[7] & P5_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p5out;
wire       p5out_wr  = P5OUT[0] ? reg_hi_wr[P5OUT] : reg_lo_wr[P5OUT];
wire [7:0] p5out_nxt = P5OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p5out <=  8'h00;
  else if (p5out_wr)  p5out <=  p5out_nxt & P5_EN_MSK;
assign p5_dout = p5out;
reg  [7:0] p5dir;
wire       p5dir_wr  = P5DIR[0] ? reg_hi_wr[P5DIR] : reg_lo_wr[P5DIR];
wire [7:0] p5dir_nxt = P5DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p5dir <=  8'h00;
  else if (p5dir_wr)  p5dir <=  p5dir_nxt & P5_EN_MSK;
assign p5_dout_en = p5dir;
reg  [7:0] p5sel;
wire       p5sel_wr  = P5SEL[0] ? reg_hi_wr[P5SEL] : reg_lo_wr[P5SEL];
wire [7:0] p5sel_nxt = P5SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p5sel <=  8'h00;
  else if (p5sel_wr) p5sel <=  p5sel_nxt & P5_EN_MSK;
assign p5_sel = p5sel;
wire  [7:0] p6in;
omsp_sync_cell sync_cell_p6in_0 (.data_out(p6in[0]), .data_in(p6_din[0] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_1 (.data_out(p6in[1]), .data_in(p6_din[1] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_2 (.data_out(p6in[2]), .data_in(p6_din[2] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_3 (.data_out(p6in[3]), .data_in(p6_din[3] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_4 (.data_out(p6in[4]), .data_in(p6_din[4] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_5 (.data_out(p6in[5]), .data_in(p6_din[5] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_6 (.data_out(p6in[6]), .data_in(p6_din[6] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
omsp_sync_cell sync_cell_p6in_7 (.data_out(p6in[7]), .data_in(p6_din[7] & P6_EN[0]), .clk(mclk), .rst(puc_rst));
reg  [7:0] p6out;
wire       p6out_wr  = P6OUT[0] ? reg_hi_wr[P6OUT] : reg_lo_wr[P6OUT];
wire [7:0] p6out_nxt = P6OUT[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p6out <=  8'h00;
  else if (p6out_wr)  p6out <=  p6out_nxt & P6_EN_MSK;
assign p6_dout = p6out;
reg  [7:0] p6dir;
wire       p6dir_wr  = P6DIR[0] ? reg_hi_wr[P6DIR] : reg_lo_wr[P6DIR];
wire [7:0] p6dir_nxt = P6DIR[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        p6dir <=  8'h00;
  else if (p6dir_wr)  p6dir <=  p6dir_nxt & P6_EN_MSK;
assign p6_dout_en = p6dir;
reg  [7:0] p6sel;
wire       p6sel_wr  = P6SEL[0] ? reg_hi_wr[P6SEL] : reg_lo_wr[P6SEL];
wire [7:0] p6sel_nxt = P6SEL[0] ? per_din[15:8]    : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       p6sel <=  8'h00;
  else if (p6sel_wr) p6sel <=  p6sel_nxt & P6_EN_MSK;
assign p6_sel = p6sel;
reg    [7:0] p1in_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  p1in_dly <=  8'h00;
  else          p1in_dly <=  p1in & P1_EN_MSK;    
wire   [7:0] p1in_re   =   p1in & ~p1in_dly;
wire   [7:0] p1in_fe   =  ~p1in &  p1in_dly;
assign       p1ifg_set = {p1ies[7] ? p1in_fe[7] : p1in_re[7],
                          p1ies[6] ? p1in_fe[6] : p1in_re[6],
                          p1ies[5] ? p1in_fe[5] : p1in_re[5],
                          p1ies[4] ? p1in_fe[4] : p1in_re[4],
                          p1ies[3] ? p1in_fe[3] : p1in_re[3],
                          p1ies[2] ? p1in_fe[2] : p1in_re[2],
                          p1ies[1] ? p1in_fe[1] : p1in_re[1],
                          p1ies[0] ? p1in_fe[0] : p1in_re[0]} & P1_EN_MSK;
assign       irq_port1 = |(p1ie & p1ifg) & P1_EN[0];
reg    [7:0] p2in_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)  p2in_dly <=  8'h00;
  else          p2in_dly <=  p2in & P2_EN_MSK;    
wire   [7:0] p2in_re   =   p2in & ~p2in_dly;
wire   [7:0] p2in_fe   =  ~p2in &  p2in_dly;
assign       p2ifg_set = {p2ies[7] ? p2in_fe[7] : p2in_re[7],
                          p2ies[6] ? p2in_fe[6] : p2in_re[6],
                          p2ies[5] ? p2in_fe[5] : p2in_re[5],
                          p2ies[4] ? p2in_fe[4] : p2in_re[4],
                          p2ies[3] ? p2in_fe[3] : p2in_re[3],
                          p2ies[2] ? p2in_fe[2] : p2in_re[2],
                          p2ies[1] ? p2in_fe[1] : p2in_re[1],
                          p2ies[0] ? p2in_fe[0] : p2in_re[0]} & P2_EN_MSK;
assign      irq_port2 = |(p2ie & p2ifg) & P2_EN[0];
wire [15:0] p1in_rd   = {8'h00, (p1in  & {8{reg_rd[P1IN]}})}  << (8 & {4{P1IN[0]}});
wire [15:0] p1out_rd  = {8'h00, (p1out & {8{reg_rd[P1OUT]}})} << (8 & {4{P1OUT[0]}});
wire [15:0] p1dir_rd  = {8'h00, (p1dir & {8{reg_rd[P1DIR]}})} << (8 & {4{P1DIR[0]}});
wire [15:0] p1ifg_rd  = {8'h00, (p1ifg & {8{reg_rd[P1IFG]}})} << (8 & {4{P1IFG[0]}});
wire [15:0] p1ies_rd  = {8'h00, (p1ies & {8{reg_rd[P1IES]}})} << (8 & {4{P1IES[0]}});
wire [15:0] p1ie_rd   = {8'h00, (p1ie  & {8{reg_rd[P1IE]}})}  << (8 & {4{P1IE[0]}});
wire [15:0] p1sel_rd  = {8'h00, (p1sel & {8{reg_rd[P1SEL]}})} << (8 & {4{P1SEL[0]}});
wire [15:0] p2in_rd   = {8'h00, (p2in  & {8{reg_rd[P2IN]}})}  << (8 & {4{P2IN[0]}});
wire [15:0] p2out_rd  = {8'h00, (p2out & {8{reg_rd[P2OUT]}})} << (8 & {4{P2OUT[0]}});
wire [15:0] p2dir_rd  = {8'h00, (p2dir & {8{reg_rd[P2DIR]}})} << (8 & {4{P2DIR[0]}});
wire [15:0] p2ifg_rd  = {8'h00, (p2ifg & {8{reg_rd[P2IFG]}})} << (8 & {4{P2IFG[0]}});
wire [15:0] p2ies_rd  = {8'h00, (p2ies & {8{reg_rd[P2IES]}})} << (8 & {4{P2IES[0]}});
wire [15:0] p2ie_rd   = {8'h00, (p2ie  & {8{reg_rd[P2IE]}})}  << (8 & {4{P2IE[0]}});
wire [15:0] p2sel_rd  = {8'h00, (p2sel & {8{reg_rd[P2SEL]}})} << (8 & {4{P2SEL[0]}});
wire [15:0] p3in_rd   = {8'h00, (p3in  & {8{reg_rd[P3IN]}})}  << (8 & {4{P3IN[0]}});
wire [15:0] p3out_rd  = {8'h00, (p3out & {8{reg_rd[P3OUT]}})} << (8 & {4{P3OUT[0]}});
wire [15:0] p3dir_rd  = {8'h00, (p3dir & {8{reg_rd[P3DIR]}})} << (8 & {4{P3DIR[0]}});
wire [15:0] p3sel_rd  = {8'h00, (p3sel & {8{reg_rd[P3SEL]}})} << (8 & {4{P3SEL[0]}});
wire [15:0] p4in_rd   = {8'h00, (p4in  & {8{reg_rd[P4IN]}})}  << (8 & {4{P4IN[0]}});
wire [15:0] p4out_rd  = {8'h00, (p4out & {8{reg_rd[P4OUT]}})} << (8 & {4{P4OUT[0]}});
wire [15:0] p4dir_rd  = {8'h00, (p4dir & {8{reg_rd[P4DIR]}})} << (8 & {4{P4DIR[0]}});
wire [15:0] p4sel_rd  = {8'h00, (p4sel & {8{reg_rd[P4SEL]}})} << (8 & {4{P4SEL[0]}});
wire [15:0] p5in_rd   = {8'h00, (p5in  & {8{reg_rd[P5IN]}})}  << (8 & {4{P5IN[0]}});
wire [15:0] p5out_rd  = {8'h00, (p5out & {8{reg_rd[P5OUT]}})} << (8 & {4{P5OUT[0]}});
wire [15:0] p5dir_rd  = {8'h00, (p5dir & {8{reg_rd[P5DIR]}})} << (8 & {4{P5DIR[0]}});
wire [15:0] p5sel_rd  = {8'h00, (p5sel & {8{reg_rd[P5SEL]}})} << (8 & {4{P5SEL[0]}});
wire [15:0] p6in_rd   = {8'h00, (p6in  & {8{reg_rd[P6IN]}})}  << (8 & {4{P6IN[0]}});
wire [15:0] p6out_rd  = {8'h00, (p6out & {8{reg_rd[P6OUT]}})} << (8 & {4{P6OUT[0]}});
wire [15:0] p6dir_rd  = {8'h00, (p6dir & {8{reg_rd[P6DIR]}})} << (8 & {4{P6DIR[0]}});
wire [15:0] p6sel_rd  = {8'h00, (p6sel & {8{reg_rd[P6SEL]}})} << (8 & {4{P6SEL[0]}});
wire [15:0] per_dout  =  p1in_rd   |
                         p1out_rd  |
                         p1dir_rd  |
                         p1ifg_rd  |
                         p1ies_rd  |
                         p1ie_rd   |
                         p1sel_rd  |
                         p2in_rd   |
                         p2out_rd  |
                         p2dir_rd  |
                         p2ifg_rd  |
                         p2ies_rd  |
                         p2ie_rd   |
                         p2sel_rd  |
                         p3in_rd   |
                         p3out_rd  |
                         p3dir_rd  |
                         p3sel_rd  |
                         p4in_rd   |
                         p4out_rd  |
                         p4dir_rd  |
                         p4sel_rd  |
                         p5in_rd   |
                         p5out_rd  |
                         p5dir_rd  |
                         p5sel_rd  |
                         p6in_rd   |
                         p6out_rd  |
                         p6dir_rd  |
                         p6sel_rd;
endmodule  
module  omsp_timerA (
    irq_ta0,                         
    irq_ta1,                         
    per_dout,                        
    ta_out0,                         
    ta_out0_en,                      
    ta_out1,                         
    ta_out1_en,                      
    ta_out2,                         
    ta_out2_en,                      
    aclk_en,                         
    dbg_freeze,                      
    inclk,                           
    irq_ta0_acc,                     
    mclk,                            
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    puc_rst,                         
    smclk_en,                        
    ta_cci0a,                        
    ta_cci0b,                        
    ta_cci1a,                        
    ta_cci1b,                        
    ta_cci2a,                        
    ta_cci2b,                        
    taclk                            
);
output              irq_ta0;         
output              irq_ta1;         
output       [15:0] per_dout;        
output              ta_out0;         
output              ta_out0_en;      
output              ta_out1;         
output              ta_out1_en;      
output              ta_out2;         
output              ta_out2_en;      
input               aclk_en;         
input               dbg_freeze;      
input               inclk;           
input               irq_ta0_acc;     
input               mclk;            
input        [13:0] per_addr;        
input        [15:0] per_din;         
input               per_en;          
input         [1:0] per_we;          
input               puc_rst;         
input               smclk_en;        
input               ta_cci0a;        
input               ta_cci0b;        
input               ta_cci1a;        
input               ta_cci1b;        
input               ta_cci2a;        
input               ta_cci2b;        
input               taclk;           
parameter       [14:0] BASE_ADDR  = 15'h0100;
parameter              DEC_WD     =  7;
parameter [DEC_WD-1:0] TACTL      = 'h60,
                       TAR        = 'h70,
                       TACCTL0    = 'h62,
                       TACCR0     = 'h72,
                       TACCTL1    = 'h64,
                       TACCR1     = 'h74,
                       TACCTL2    = 'h66,
                       TACCR2     = 'h76,
                       TAIV       = 'h2E;
parameter              DEC_SZ     =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG   =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] TACTL_D    = (BASE_REG << TACTL),
                       TAR_D      = (BASE_REG << TAR),
                       TACCTL0_D  = (BASE_REG << TACCTL0),
                       TACCR0_D   = (BASE_REG << TACCR0),
                       TACCTL1_D  = (BASE_REG << TACCTL1),
                       TACCR1_D   = (BASE_REG << TACCR1),
                       TACCTL2_D  = (BASE_REG << TACCTL2),
                       TACCR2_D   = (BASE_REG << TACCR2),
                       TAIV_D     = (BASE_REG << TAIV);
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};
wire [DEC_SZ-1:0] reg_dec   =  (TACTL_D    &  {DEC_SZ{(reg_addr == TACTL   )}})  |
                               (TAR_D      &  {DEC_SZ{(reg_addr == TAR     )}})  |
                               (TACCTL0_D  &  {DEC_SZ{(reg_addr == TACCTL0 )}})  |
                               (TACCR0_D   &  {DEC_SZ{(reg_addr == TACCR0  )}})  |
                               (TACCTL1_D  &  {DEC_SZ{(reg_addr == TACCTL1 )}})  |
                               (TACCR1_D   &  {DEC_SZ{(reg_addr == TACCR1  )}})  |
                               (TACCTL2_D  &  {DEC_SZ{(reg_addr == TACCTL2 )}})  |
                               (TACCR2_D   &  {DEC_SZ{(reg_addr == TACCR2  )}})  |
                               (TAIV_D     &  {DEC_SZ{(reg_addr == TAIV    )}});
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {512{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {512{reg_read}};
reg   [9:0] tactl;
wire        tactl_wr = reg_wr[TACTL];
wire        taclr    = tactl_wr & per_din[2];
wire        taifg_set;
wire        taifg_clr;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       tactl <=  10'h000;
  else if (tactl_wr) tactl <=  ((per_din[9:0] & 10'h3f3) | {9'h000, taifg_set}) & {9'h1ff, ~taifg_clr};
  else               tactl <=  (tactl                    | {9'h000, taifg_set}) & {9'h1ff, ~taifg_clr};
reg  [15:0] tar;
wire        tar_wr = reg_wr[TAR];
wire        tar_clk;
wire        tar_clr;
wire        tar_inc;
wire        tar_dec;
wire [15:0] tar_add  = tar_inc ? 16'h0001 :
                       tar_dec ? 16'hffff : 16'h0000;
wire [15:0] tar_nxt  = tar_clr ? 16'h0000 : (tar+tar_add);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                     tar <=  16'h0000;
  else if  (tar_wr)                tar <=  per_din;
  else if  (taclr)                 tar <=  16'h0000;
  else if  (tar_clk & ~dbg_freeze) tar <=  tar_nxt;
reg  [15:0] tacctl0;
wire        tacctl0_wr = reg_wr[TACCTL0];
wire        ccifg0_set;
wire        cov0_set;   
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)         tacctl0  <=  16'h0000;
  else if (tacctl0_wr) tacctl0  <=  ((per_din & 16'hf9f7) | {14'h0000, cov0_set, ccifg0_set}) & {15'h7fff, ~irq_ta0_acc};
  else                 tacctl0  <=  (tacctl0              | {14'h0000, cov0_set, ccifg0_set}) & {15'h7fff, ~irq_ta0_acc};
wire        cci0;
reg         scci0;
wire [15:0] tacctl0_full = tacctl0 | {5'h00, scci0, 6'h00, cci0, 3'h0};
reg  [15:0] taccr0;
wire        taccr0_wr = reg_wr[TACCR0];
wire        cci0_cap;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        taccr0 <=  16'h0000;
  else if (taccr0_wr) taccr0 <=  per_din;
  else if (cci0_cap)  taccr0 <=  tar;
reg  [15:0] tacctl1;
wire        tacctl1_wr = reg_wr[TACCTL1];
wire        ccifg1_set;
wire        ccifg1_clr;
wire        cov1_set;   
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)         tacctl1 <=  16'h0000;
  else if (tacctl1_wr) tacctl1 <=  ((per_din & 16'hf9f7) | {14'h0000, cov1_set, ccifg1_set}) & {15'h7fff, ~ccifg1_clr};
  else                 tacctl1 <=  (tacctl1              | {14'h0000, cov1_set, ccifg1_set}) & {15'h7fff, ~ccifg1_clr};
wire        cci1;
reg         scci1;
wire [15:0] tacctl1_full = tacctl1 | {5'h00, scci1, 6'h00, cci1, 3'h0};
reg  [15:0] taccr1;
wire        taccr1_wr = reg_wr[TACCR1];
wire        cci1_cap;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        taccr1 <=  16'h0000;
  else if (taccr1_wr) taccr1 <=  per_din;
  else if (cci1_cap)  taccr1 <=  tar;
reg  [15:0] tacctl2;
wire        tacctl2_wr = reg_wr[TACCTL2];
wire        ccifg2_set;
wire        ccifg2_clr;
wire        cov2_set;   
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)         tacctl2 <=  16'h0000;
  else if (tacctl2_wr) tacctl2 <=  ((per_din & 16'hf9f7) | {14'h0000, cov2_set, ccifg2_set}) & {15'h7fff, ~ccifg2_clr};
  else                 tacctl2 <=  (tacctl2              | {14'h0000, cov2_set, ccifg2_set}) & {15'h7fff, ~ccifg2_clr};
wire        cci2;
reg         scci2;
wire [15:0] tacctl2_full = tacctl2 | {5'h00, scci2, 6'h00, cci2, 3'h0};
reg  [15:0] taccr2;
wire        taccr2_wr = reg_wr[TACCR2];
wire        cci2_cap;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        taccr2 <=  16'h0000;
  else if (taccr2_wr) taccr2 <=  per_din;
  else if (cci2_cap)  taccr2 <=  tar;
wire [3:0] taiv = (tacctl1[0] & tacctl1[4]) ? 4'h2 : 
                  (tacctl2[0] & tacctl2[4]) ? 4'h4 : 
                  (tactl[0]     & tactl[1])     ? 4'hA : 
                                                           4'h0;
assign     ccifg1_clr = (reg_rd[TAIV] | reg_wr[TAIV]) & (taiv==4'h2);
assign     ccifg2_clr = (reg_rd[TAIV] | reg_wr[TAIV]) & (taiv==4'h4);
assign     taifg_clr  = (reg_rd[TAIV] | reg_wr[TAIV]) & (taiv==4'hA);
wire [15:0] tactl_rd   = {6'h00, tactl}  & {16{reg_rd[TACTL]}};
wire [15:0] tar_rd     = tar             & {16{reg_rd[TAR]}};
wire [15:0] tacctl0_rd = tacctl0_full    & {16{reg_rd[TACCTL0]}};
wire [15:0] taccr0_rd  = taccr0          & {16{reg_rd[TACCR0]}};
wire [15:0] tacctl1_rd = tacctl1_full    & {16{reg_rd[TACCTL1]}};
wire [15:0] taccr1_rd  = taccr1          & {16{reg_rd[TACCR1]}};
wire [15:0] tacctl2_rd = tacctl2_full    & {16{reg_rd[TACCTL2]}};
wire [15:0] taccr2_rd  = taccr2          & {16{reg_rd[TACCR2]}};
wire [15:0] taiv_rd    = {12'h000, taiv} & {16{reg_rd[TAIV]}};
wire [15:0] per_dout   =  tactl_rd   |
                          tar_rd     |
                          tacctl0_rd |
                          taccr0_rd  |
                          tacctl1_rd |
                          taccr1_rd  |
                          tacctl2_rd |
                          taccr2_rd  |
                          taiv_rd;
wire taclk_s;
wire inclk_s;
omsp_sync_cell sync_cell_taclk (
    .data_out  (taclk_s),
    .data_in   (taclk),
    .clk       (mclk),
    .rst       (puc_rst)
);
omsp_sync_cell sync_cell_inclk (
    .data_out  (inclk_s),
    .data_in   (inclk),
    .clk       (mclk),
    .rst       (puc_rst)
);
reg  taclk_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) taclk_dly <=  1'b0;
  else         taclk_dly <=  taclk_s;    
wire taclk_en = taclk_s & ~taclk_dly;
reg  inclk_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) inclk_dly <=  1'b0;
  else         inclk_dly <=  inclk_s;    
wire inclk_en = inclk_s & ~inclk_dly;
wire sel_clk = (tactl[9:8]==2'b00) ? taclk_en :
               (tactl[9:8]==2'b01) ?  aclk_en :
               (tactl[9:8]==2'b10) ? smclk_en : inclk_en;
reg [2:0] clk_div;
assign    tar_clk = sel_clk & ((tactl[7:6]==2'b00) ?  1'b1         :
                               (tactl[7:6]==2'b01) ?  clk_div[0]   :
                               (tactl[7:6]==2'b10) ? &clk_div[1:0] :
                                                        &clk_div[2:0]);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                               clk_div <=  3'h0;
  else if  (tar_clk | taclr)                 clk_div <=  3'h0;
  else if ((tactl[5:4]!=2'b00) & sel_clk) clk_div <=  clk_div+3'h1;
assign  tar_clr   = ((tactl[5:4]==2'b01) & (tar>=taccr0))         |
                    ((tactl[5:4]==2'b11) & (taccr0==16'h0000));
assign  tar_inc   =  (tactl[5:4]==2'b01) | (tactl[5:4]==2'b10) | 
                    ((tactl[5:4]==2'b11) & ~tar_dec);
reg tar_dir;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                        tar_dir <=  1'b0;
  else if (taclr)                     tar_dir <=  1'b0;
  else if (tactl[5:4]==2'b11)
    begin
       if (tar_clk & (tar==16'h0001)) tar_dir <=  1'b0;
       else if       (tar>=taccr0)    tar_dir <=  1'b1;
    end
  else                                tar_dir <=  1'b0;
assign tar_dec = tar_dir | ((tactl[5:4]==2'b11) & (tar>=taccr0));
wire equ0 = (tar_nxt==taccr0) & (tar!=taccr0);
wire equ1 = (tar_nxt==taccr1) & (tar!=taccr1);
wire equ2 = (tar_nxt==taccr2) & (tar!=taccr2);
assign cci0 = (tacctl0[13:12]==2'b00) ? ta_cci0a :
              (tacctl0[13:12]==2'b01) ? ta_cci0b :
              (tacctl0[13:12]==2'b10) ?     1'b0 : 1'b1;
assign cci1 = (tacctl1[13:12]==2'b00) ? ta_cci1a :
              (tacctl1[13:12]==2'b01) ? ta_cci1b :
              (tacctl1[13:12]==2'b10) ?     1'b0 : 1'b1;
assign cci2 = (tacctl2[13:12]==2'b00) ? ta_cci2a :
              (tacctl2[13:12]==2'b01) ? ta_cci2b :
              (tacctl2[13:12]==2'b10) ?     1'b0 : 1'b1;
wire cci0_s;
wire cci1_s;
wire cci2_s;
omsp_sync_cell sync_cell_cci0 (
    .data_out (cci0_s),
    .data_in  (cci0),
    .clk      (mclk),
    .rst      (puc_rst)
);
omsp_sync_cell sync_cell_cci1 (
    .data_out (cci1_s),
    .data_in  (cci1),
    .clk      (mclk),
    .rst      (puc_rst)
);
omsp_sync_cell sync_cell_cci2 (
    .data_out (cci2_s),
    .data_in  (cci2),
    .clk      (mclk),
    .rst      (puc_rst)
);
reg cci0_dly;
reg cci1_dly;
reg cci2_dly;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)
    begin
       cci0_dly <=  1'b0;
       cci1_dly <=  1'b0;
       cci2_dly <=  1'b0;
    end
  else
    begin
       cci0_dly <=  cci0_s;
       cci1_dly <=  cci1_s;
       cci2_dly <=  cci2_s;
    end
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             scci0 <=  1'b0;
  else if (tar_clk & equ0) scci0 <=  cci0_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             scci1 <=  1'b0;
  else if (tar_clk & equ1) scci1 <=  cci1_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             scci2 <=  1'b0;
  else if (tar_clk & equ2) scci2 <=  cci2_s;
wire cci0_evt = (tacctl0[15:14]==2'b00) ? 1'b0                  :
                (tacctl0[15:14]==2'b01) ? ( cci0_s & ~cci0_dly) :    
                (tacctl0[15:14]==2'b10) ? (~cci0_s &  cci0_dly) :    
                                           ( cci0_s ^  cci0_dly);     
wire cci1_evt = (tacctl1[15:14]==2'b00) ? 1'b0                  :
                (tacctl1[15:14]==2'b01) ? ( cci1_s & ~cci1_dly) :    
                (tacctl1[15:14]==2'b10) ? (~cci1_s &  cci1_dly) :    
                                           ( cci1_s ^  cci1_dly);     
wire cci2_evt = (tacctl2[15:14]==2'b00) ? 1'b0                  :
                (tacctl2[15:14]==2'b01) ? ( cci2_s & ~cci2_dly) :    
                (tacctl2[15:14]==2'b10) ? (~cci2_s &  cci2_dly) :    
                                           ( cci2_s ^  cci2_dly);     
reg cci0_evt_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       cci0_evt_s <=  1'b0;
  else if (tar_clk)  cci0_evt_s <=  1'b0;
  else if (cci0_evt) cci0_evt_s <=  1'b1;
reg cci1_evt_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       cci1_evt_s <=  1'b0;
  else if (tar_clk)  cci1_evt_s <=  1'b0;
  else if (cci1_evt) cci1_evt_s <=  1'b1;
reg cci2_evt_s;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)       cci2_evt_s <=  1'b0;
  else if (tar_clk)  cci2_evt_s <=  1'b0;
  else if (cci2_evt) cci2_evt_s <=  1'b1;
reg cci0_sync;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) cci0_sync <=  1'b0;
  else         cci0_sync <=  (tar_clk & cci0_evt_s) | (tar_clk & cci0_evt & ~cci0_evt_s);
reg cci1_sync;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) cci1_sync <=  1'b0;
  else         cci1_sync <=  (tar_clk & cci1_evt_s) | (tar_clk & cci1_evt & ~cci1_evt_s);
reg cci2_sync;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst) cci2_sync <=  1'b0;
  else         cci2_sync <=  (tar_clk & cci2_evt_s) | (tar_clk & cci2_evt & ~cci2_evt_s);
assign cci0_cap  = tacctl0[11] ? cci0_sync : cci0_evt;
assign cci1_cap  = tacctl1[11] ? cci1_sync : cci1_evt;
assign cci2_cap  = tacctl2[11] ? cci2_sync : cci2_evt;
reg  cap0_taken;
wire cap0_taken_clr = reg_rd[TACCR0] | (tacctl0_wr & tacctl0[1] & ~per_din[1]);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             cap0_taken <=  1'b0;
  else if (cci0_cap)       cap0_taken <=  1'b1;
  else if (cap0_taken_clr) cap0_taken <=  1'b0;
reg  cap1_taken;
wire cap1_taken_clr = reg_rd[TACCR1] | (tacctl1_wr & tacctl1[1] & ~per_din[1]);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             cap1_taken <=  1'b0;
  else if (cci1_cap)       cap1_taken <=  1'b1;
  else if (cap1_taken_clr) cap1_taken <=  1'b0;
reg  cap2_taken;
wire cap2_taken_clr = reg_rd[TACCR2] | (tacctl2_wr & tacctl2[1] & ~per_din[1]);
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)             cap2_taken <=  1'b0;
  else if (cci2_cap)       cap2_taken <=  1'b1;
  else if (cap2_taken_clr) cap2_taken <=  1'b0;
assign cov0_set = cap0_taken & cci0_cap & ~reg_rd[TACCR0];
assign cov1_set = cap1_taken & cci1_cap & ~reg_rd[TACCR1];   
assign cov2_set = cap2_taken & cci2_cap & ~reg_rd[TACCR2];
reg  ta_out0;
wire ta_out0_mode0 = tacctl0[2];                 
wire ta_out0_mode1 = equ0 ?  1'b1    : ta_out0;       
wire ta_out0_mode2 = equ0 ? ~ta_out0 :                
                     equ0 ?  1'b0    : ta_out0;
wire ta_out0_mode3 = equ0 ?  1'b1    :                
                     equ0 ?  1'b0    : ta_out0;
wire ta_out0_mode4 = equ0 ? ~ta_out0 : ta_out0;       
wire ta_out0_mode5 = equ0 ?  1'b0    : ta_out0;       
wire ta_out0_mode6 = equ0 ? ~ta_out0 :                
                     equ0 ?  1'b1    : ta_out0;
wire ta_out0_mode7 = equ0 ?  1'b0    :                
                     equ0 ?  1'b1    : ta_out0;
wire ta_out0_nxt   = (tacctl0[7:5]==3'b000) ? ta_out0_mode0 :
                     (tacctl0[7:5]==3'b001) ? ta_out0_mode1 :
                     (tacctl0[7:5]==3'b010) ? ta_out0_mode2 :
                     (tacctl0[7:5]==3'b011) ? ta_out0_mode3 :
                     (tacctl0[7:5]==3'b100) ? ta_out0_mode4 :
                     (tacctl0[7:5]==3'b101) ? ta_out0_mode5 :
                     (tacctl0[7:5]==3'b110) ? ta_out0_mode6 :
                                                     ta_out0_mode7;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                                     ta_out0 <=  1'b0;
  else if ((tacctl0[7:5]==3'b001) & taclr)  ta_out0 <=  1'b0;
  else if (tar_clk)                                ta_out0 <=  ta_out0_nxt;
assign  ta_out0_en = ~tacctl0[8];
reg  ta_out1;
wire ta_out1_mode0 = tacctl1[2];                 
wire ta_out1_mode1 = equ1 ?  1'b1    : ta_out1;       
wire ta_out1_mode2 = equ1 ? ~ta_out1 :                
                     equ0 ?  1'b0    : ta_out1;
wire ta_out1_mode3 = equ1 ?  1'b1    :                
                     equ0 ?  1'b0    : ta_out1;
wire ta_out1_mode4 = equ1 ? ~ta_out1 : ta_out1;       
wire ta_out1_mode5 = equ1 ?  1'b0    : ta_out1;       
wire ta_out1_mode6 = equ1 ? ~ta_out1 :                
                     equ0 ?  1'b1    : ta_out1;
wire ta_out1_mode7 = equ1 ?  1'b0    :                
                     equ0 ?  1'b1    : ta_out1;
wire ta_out1_nxt   = (tacctl1[7:5]==3'b000) ? ta_out1_mode0 :
                     (tacctl1[7:5]==3'b001) ? ta_out1_mode1 :
                     (tacctl1[7:5]==3'b010) ? ta_out1_mode2 :
                     (tacctl1[7:5]==3'b011) ? ta_out1_mode3 :
                     (tacctl1[7:5]==3'b100) ? ta_out1_mode4 :
                     (tacctl1[7:5]==3'b101) ? ta_out1_mode5 :
                     (tacctl1[7:5]==3'b110) ? ta_out1_mode6 :
                                                     ta_out1_mode7;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                                     ta_out1 <=  1'b0;
  else if ((tacctl1[7:5]==3'b001) & taclr)  ta_out1 <=  1'b0;
  else if (tar_clk)                                ta_out1 <=  ta_out1_nxt;
assign  ta_out1_en = ~tacctl1[8];
reg  ta_out2;
wire ta_out2_mode0 = tacctl2[2];                 
wire ta_out2_mode1 = equ2 ?  1'b1    : ta_out2;       
wire ta_out2_mode2 = equ2 ? ~ta_out2 :                
                     equ0 ?  1'b0    : ta_out2;
wire ta_out2_mode3 = equ2 ?  1'b1    :                
                     equ0 ?  1'b0    : ta_out2;
wire ta_out2_mode4 = equ2 ? ~ta_out2 : ta_out2;       
wire ta_out2_mode5 = equ2 ?  1'b0    : ta_out2;       
wire ta_out2_mode6 = equ2 ? ~ta_out2 :                
                     equ0 ?  1'b1    : ta_out2;
wire ta_out2_mode7 = equ2 ?  1'b0    :                
                     equ0 ?  1'b1    : ta_out2;
wire ta_out2_nxt   = (tacctl2[7:5]==3'b000) ? ta_out2_mode0 :
                     (tacctl2[7:5]==3'b001) ? ta_out2_mode1 :
                     (tacctl2[7:5]==3'b010) ? ta_out2_mode2 :
                     (tacctl2[7:5]==3'b011) ? ta_out2_mode3 :
                     (tacctl2[7:5]==3'b100) ? ta_out2_mode4 :
                     (tacctl2[7:5]==3'b101) ? ta_out2_mode5 :
                     (tacctl2[7:5]==3'b110) ? ta_out2_mode6 :
                                                     ta_out2_mode7;
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)                                     ta_out2 <=  1'b0;
  else if ((tacctl2[7:5]==3'b001) & taclr)  ta_out2 <=  1'b0;
  else if (tar_clk)                                ta_out2 <=  ta_out2_nxt;
assign  ta_out2_en = ~tacctl2[8];
assign   taifg_set   = tar_clk & (((tactl[5:4]==2'b01) & (tar==taccr0))                  |
                                  ((tactl[5:4]==2'b10) & (tar==16'hffff))                |
                                  ((tactl[5:4]==2'b11) & (tar_nxt==16'h0000) & tar_dec));
assign   ccifg0_set  = tacctl0[8] ? cci0_cap : (tar_clk &  ((tactl[5:4]!=2'b00) & equ0));
assign   ccifg1_set  = tacctl1[8] ? cci1_cap : (tar_clk &  ((tactl[5:4]!=2'b00) & equ1));
assign   ccifg2_set  = tacctl2[8] ? cci2_cap : (tar_clk &  ((tactl[5:4]!=2'b00) & equ2));
wire     irq_ta0    = (tacctl0[0] & tacctl0[4]);
wire     irq_ta1    = (tactl[0]     & tactl[1])     |
                      (tacctl1[0] & tacctl1[4]) |
                      (tacctl2[0] & tacctl2[4]);
endmodule  
module  template_periph_16b (
    per_dout,                        
    mclk,                            
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    puc_rst                          
);
output       [15:0] per_dout;        
input               mclk;            
input        [13:0] per_addr;        
input        [15:0] per_din;         
input               per_en;          
input         [1:0] per_we;          
input               puc_rst;         
parameter       [14:0] BASE_ADDR   = 15'h0190;
parameter              DEC_WD      =  3;
parameter [DEC_WD-1:0] CNTRL1      = 'h0,
                       CNTRL2      = 'h2,
                       CNTRL3      = 'h4,
                       CNTRL4      = 'h6;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] CNTRL1_D    = (BASE_REG << CNTRL1),
                       CNTRL2_D    = (BASE_REG << CNTRL2),
                       CNTRL3_D    = (BASE_REG << CNTRL3),
                       CNTRL4_D    = (BASE_REG << CNTRL4);
wire              reg_sel   =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr  =  {per_addr[DEC_WD-2:0], 1'b0};
wire [DEC_SZ-1:0] reg_dec   =  (CNTRL1_D  &  {DEC_SZ{(reg_addr == CNTRL1 )}})  |
                               (CNTRL2_D  &  {DEC_SZ{(reg_addr == CNTRL2 )}})  |
                               (CNTRL3_D  &  {DEC_SZ{(reg_addr == CNTRL3 )}})  |
                               (CNTRL4_D  &  {DEC_SZ{(reg_addr == CNTRL4 )}});
wire              reg_write =  |per_we & reg_sel;
wire              reg_read  = ~|per_we & reg_sel;
wire [DEC_SZ-1:0] reg_wr    = reg_dec & {DEC_SZ{reg_write}};
wire [DEC_SZ-1:0] reg_rd    = reg_dec & {DEC_SZ{reg_read}};
reg  [15:0] cntrl1;
wire        cntrl1_wr = reg_wr[CNTRL1];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl1 <=  16'h0000;
  else if (cntrl1_wr) cntrl1 <=  per_din;
reg  [15:0] cntrl2;
wire        cntrl2_wr = reg_wr[CNTRL2];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl2 <=  16'h0000;
  else if (cntrl2_wr) cntrl2 <=  per_din;
reg  [15:0] cntrl3;
wire        cntrl3_wr = reg_wr[CNTRL3];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl3 <=  16'h0000;
  else if (cntrl3_wr) cntrl3 <=  per_din;
reg  [15:0] cntrl4;
wire        cntrl4_wr = reg_wr[CNTRL4];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl4 <=  16'h0000;
  else if (cntrl4_wr) cntrl4 <=  per_din;
wire [15:0] cntrl1_rd  = cntrl1  & {16{reg_rd[CNTRL1]}};
wire [15:0] cntrl2_rd  = cntrl2  & {16{reg_rd[CNTRL2]}};
wire [15:0] cntrl3_rd  = cntrl3  & {16{reg_rd[CNTRL3]}};
wire [15:0] cntrl4_rd  = cntrl4  & {16{reg_rd[CNTRL4]}};
wire [15:0] per_dout   =  cntrl1_rd  |
                          cntrl2_rd  |
                          cntrl3_rd  |
                          cntrl4_rd;
endmodule  
module  template_periph_8b (
    per_dout,                        
    mclk,                            
    per_addr,                        
    per_din,                         
    per_en,                          
    per_we,                          
    puc_rst                          
);
output      [15:0] per_dout;         
input              mclk;             
input       [13:0] per_addr;         
input       [15:0] per_din;          
input              per_en;           
input        [1:0] per_we;           
input              puc_rst;          
parameter       [14:0] BASE_ADDR   = 15'h0090;
parameter              DEC_WD      =  2;
parameter [DEC_WD-1:0] CNTRL1      =  'h0,
                       CNTRL2      =  'h1,
                       CNTRL3      =  'h2,
                       CNTRL4      =  'h3;
parameter              DEC_SZ      =  (1 << DEC_WD);
parameter [DEC_SZ-1:0] BASE_REG    =  {{DEC_SZ-1{1'b0}}, 1'b1};
parameter [DEC_SZ-1:0] CNTRL1_D  = (BASE_REG << CNTRL1),
                       CNTRL2_D  = (BASE_REG << CNTRL2), 
                       CNTRL3_D  = (BASE_REG << CNTRL3), 
                       CNTRL4_D  = (BASE_REG << CNTRL4); 
wire              reg_sel      =  per_en & (per_addr[13:DEC_WD-1]==BASE_ADDR[14:DEC_WD]);
wire [DEC_WD-1:0] reg_addr     =  {1'b0, per_addr[DEC_WD-2:0]};
wire [DEC_SZ-1:0] reg_dec      = (CNTRL1_D  &  {DEC_SZ{(reg_addr==(CNTRL1 >>1))}}) |
                                 (CNTRL2_D  &  {DEC_SZ{(reg_addr==(CNTRL2 >>1))}}) |
                                 (CNTRL3_D  &  {DEC_SZ{(reg_addr==(CNTRL3 >>1))}}) |
                                 (CNTRL4_D  &  {DEC_SZ{(reg_addr==(CNTRL4 >>1))}});
wire              reg_lo_write =  per_we[0] & reg_sel;
wire              reg_hi_write =  per_we[1] & reg_sel;
wire              reg_read     = ~|per_we   & reg_sel;
wire [DEC_SZ-1:0] reg_hi_wr    = reg_dec & {DEC_SZ{reg_hi_write}};
wire [DEC_SZ-1:0] reg_lo_wr    = reg_dec & {DEC_SZ{reg_lo_write}};
wire [DEC_SZ-1:0] reg_rd       = reg_dec & {DEC_SZ{reg_read}};
reg  [7:0] cntrl1;
wire       cntrl1_wr  = CNTRL1[0] ? reg_hi_wr[CNTRL1] : reg_lo_wr[CNTRL1];
wire [7:0] cntrl1_nxt = CNTRL1[0] ? per_din[15:8]     : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl1 <=  8'h00;
  else if (cntrl1_wr) cntrl1 <=  cntrl1_nxt;
reg  [7:0] cntrl2;
wire       cntrl2_wr  = CNTRL2[0] ? reg_hi_wr[CNTRL2] : reg_lo_wr[CNTRL2];
wire [7:0] cntrl2_nxt = CNTRL2[0] ? per_din[15:8]     : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl2 <=  8'h00;
  else if (cntrl2_wr) cntrl2 <=  cntrl2_nxt;
reg  [7:0] cntrl3;
wire       cntrl3_wr  = CNTRL3[0] ? reg_hi_wr[CNTRL3] : reg_lo_wr[CNTRL3];
wire [7:0] cntrl3_nxt = CNTRL3[0] ? per_din[15:8]     : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl3 <=  8'h00;
  else if (cntrl3_wr) cntrl3 <=  cntrl3_nxt;
reg  [7:0] cntrl4;
wire       cntrl4_wr  = CNTRL4[0] ? reg_hi_wr[CNTRL4] : reg_lo_wr[CNTRL4];
wire [7:0] cntrl4_nxt = CNTRL4[0] ? per_din[15:8]     : per_din[7:0];
always @ (posedge mclk or posedge puc_rst)
  if (puc_rst)        cntrl4 <=  8'h00;
  else if (cntrl4_wr) cntrl4 <=  cntrl4_nxt;
wire [15:0] cntrl1_rd   = {8'h00, (cntrl1  & {8{reg_rd[CNTRL1]}})}  << (8 & {4{CNTRL1[0]}});
wire [15:0] cntrl2_rd   = {8'h00, (cntrl2  & {8{reg_rd[CNTRL2]}})}  << (8 & {4{CNTRL2[0]}});
wire [15:0] cntrl3_rd   = {8'h00, (cntrl3  & {8{reg_rd[CNTRL3]}})}  << (8 & {4{CNTRL3[0]}});
wire [15:0] cntrl4_rd   = {8'h00, (cntrl4  & {8{reg_rd[CNTRL4]}})}  << (8 & {4{CNTRL4[0]}});
wire [15:0] per_dout  =  cntrl1_rd  |
                         cntrl2_rd  |
                         cntrl3_rd  |
                         cntrl4_rd;
endmodule  
