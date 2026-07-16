module fault_sm( 
  status_local_fault_crx, status_remote_fault_crx, 
  clk_xgmii_rx, reset_xgmii_rx_n, local_fault_msg_det, 
  remote_fault_msg_det
  );
input         clk_xgmii_rx;
input         reset_xgmii_rx_n;
input  [1:0]  local_fault_msg_det;
input  [1:0]  remote_fault_msg_det;
output        status_local_fault_crx;
output        status_remote_fault_crx;
reg                     status_local_fault_crx;
reg                     status_remote_fault_crx;
reg    [1:0]  curr_state;
reg    [7:0]  col_cnt;
reg    [1:0]  fault_sequence;
reg    [1:0]  last_seq_type;
reg    [1:0]  link_fault;
reg    [2:0]  seq_cnt;
reg    [1:0]  seq_type;
reg    [1:0]  seq_add;
parameter [1:0]
             SM_INIT       = 2'd0,
             SM_COUNT      = 2'd1,
             SM_FAULT      = 2'd2,
             SM_NEW_FAULT  = 2'd3;
always @( local_fault_msg_det or remote_fault_msg_det) begin
    fault_sequence = local_fault_msg_det | remote_fault_msg_det;
    if (|local_fault_msg_det) begin
        seq_type = 2'd1;
    end
    else if (|remote_fault_msg_det) begin
        seq_type = 2'd2;
    end
    else begin
        seq_type = 2'd0;
    end
    if (|remote_fault_msg_det) begin
        seq_add = remote_fault_msg_det[1] + remote_fault_msg_det[0];
    end
    else begin
        seq_add = local_fault_msg_det[1] + local_fault_msg_det[0];
    end
end
always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if (reset_xgmii_rx_n == 1'b0) begin
        status_local_fault_crx <= 1'b0;
        status_remote_fault_crx <= 1'b0;
    end
    else begin
        status_local_fault_crx <= curr_state == SM_FAULT &&
                                  link_fault == 2'd1;
        status_remote_fault_crx <= curr_state == SM_FAULT &&
                                   link_fault == 2'd2;
    end
end
always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if (reset_xgmii_rx_n == 1'b0) begin
        curr_state <= SM_INIT;
        col_cnt <= 8'b0;
        last_seq_type <= 2'd0;
        link_fault <= 2'd0;
        seq_cnt <= 3'b0;
    end
    else begin
        case (curr_state)
          SM_INIT:
            begin
                last_seq_type <= seq_type;
                if (|fault_sequence) begin
                    if (fault_sequence[0]) begin
                        col_cnt <= 8'd2;
                    end
                    else begin
                        col_cnt <= 8'd1;
                    end
                    seq_cnt <= {1'b0, seq_add};
                    curr_state <= SM_COUNT;
                end
                else begin
                    col_cnt <= 8'b0;
                    seq_cnt <= 3'b0;
                end
            end
          SM_COUNT:
            begin
                col_cnt <= col_cnt + 8'd2;
                seq_cnt <= seq_cnt + {1'b0, seq_add};
                if (!fault_sequence[0] && col_cnt >= 8'd127) begin
                    curr_state <= SM_INIT;
                end
                else if (col_cnt > 8'd127) begin
                    curr_state <= SM_INIT;
                end
                else if (|fault_sequence) begin
                    if (seq_type != last_seq_type) begin
                        curr_state <= SM_NEW_FAULT;
                    end
                    else begin
                        if ((seq_cnt + {1'b0, seq_add}) > 3'd3) begin
                            col_cnt <= 8'b0;
                            link_fault <= seq_type;
                            curr_state <= SM_FAULT;
                        end
                    end
                end
            end
          SM_FAULT:
            begin
                col_cnt <= col_cnt + 8'd2;
                if (!fault_sequence[0] && col_cnt >= 8'd127) begin
                    curr_state <= SM_INIT;
                end
                else if (col_cnt > 8'd127) begin
                    curr_state <= SM_INIT;
                end
                else if (|fault_sequence) begin
                    col_cnt <= 8'd0;
                    if (seq_type != last_seq_type) begin
                        curr_state <= SM_NEW_FAULT;
                    end
                end
            end
          SM_NEW_FAULT:
            begin
                col_cnt <= 8'b0;
                last_seq_type <= seq_type;
                seq_cnt <= {1'b0, seq_add};
                curr_state <= SM_COUNT;
            end
        endcase
    end
end
endmodule
module generic_fifo(
    wclk,
    wrst_n,
    wen,
    wdata,
    wfull,
    walmost_full,
    rclk,
    rrst_n,
    ren,
    rdata,
    rempty,
    ralmost_empty
);
parameter DWIDTH = 32;
parameter AWIDTH = 3;
parameter RAM_DEPTH = (1 << AWIDTH);
parameter SYNC_WRITE = 1;
parameter SYNC_READ = 1;
parameter REGISTER_READ = 0;
parameter EARLY_READ = 0;
parameter CLOCK_CROSSING = 1;
parameter ALMOST_EMPTY_THRESH = 1;
parameter ALMOST_FULL_THRESH = RAM_DEPTH-2;
parameter MEM_TYPE = 1;
input          wclk;
input          wrst_n;
input          wen;
input  [DWIDTH-1:0] wdata;
output         wfull;
output         walmost_full;
input          rclk;
input          rrst_n;
input          ren;
output [DWIDTH-1:0] rdata;
output         rempty;
output         ralmost_empty;
wire             mem_wen;
wire [AWIDTH:0]  mem_waddr;
wire             mem_ren;
wire [AWIDTH:0]  mem_raddr;
generic_fifo_ctrl #(.AWIDTH (AWIDTH),
                    .RAM_DEPTH (RAM_DEPTH), 
                    .EARLY_READ (EARLY_READ),
                    .CLOCK_CROSSING (CLOCK_CROSSING),
                    .ALMOST_EMPTY_THRESH (ALMOST_EMPTY_THRESH),
                    .ALMOST_FULL_THRESH (ALMOST_FULL_THRESH)
                    )
  ctrl0(.wclk (wclk),
        .wrst_n (wrst_n),
        .wen (wen),
        .wfull (wfull),
        .walmost_full (walmost_full),
        .mem_wen (mem_wen),
        .mem_waddr (mem_waddr),
        .rclk (rclk),
        .rrst_n (rrst_n),
        .ren (ren),
        .rempty (rempty),
        .ralmost_empty (ralmost_empty),
        .mem_ren (mem_ren),
        .mem_raddr (mem_raddr)
        );
generate
    if (MEM_TYPE == 1) begin
        generic_mem_small #(.DWIDTH (DWIDTH),
                            .AWIDTH (AWIDTH),
                            .RAM_DEPTH (RAM_DEPTH),
                            .SYNC_WRITE (SYNC_WRITE),
                            .SYNC_READ (SYNC_READ),
                            .REGISTER_READ (REGISTER_READ)
                            )
          mem0(.wclk (wclk),
               .wrst_n (wrst_n),
               .wen (mem_wen),	
               .waddr (mem_waddr),
               .wdata (wdata),
               .rclk (rclk),
               .rrst_n (rrst_n),
               .ren (mem_ren),
               .roen (ren),
               .raddr (mem_raddr),
               .rdata (rdata)
               );
    end
    if (MEM_TYPE == 2) begin
        generic_mem_medium #(.DWIDTH (DWIDTH),
                             .AWIDTH (AWIDTH),
                             .RAM_DEPTH (RAM_DEPTH),
                             .SYNC_WRITE (SYNC_WRITE),
                             .SYNC_READ (SYNC_READ),
                             .REGISTER_READ (REGISTER_READ)
                             )
          mem0(.wclk (wclk),
               .wrst_n (wrst_n),
               .wen (mem_wen),	
               .waddr (mem_waddr),
               .wdata (wdata),
               .rclk (rclk),
               .rrst_n (rrst_n),
               .ren (mem_ren),
               .roen (ren),
               .raddr (mem_raddr),
               .rdata (rdata)
               );
    end
endgenerate
endmodule
module generic_fifo_ctrl(
    wclk,
    wrst_n,
    wen,
    wfull,
    walmost_full,
    mem_wen,
    mem_waddr,
    rclk,
    rrst_n,
    ren,
    rempty,
    ralmost_empty,
    mem_ren,
    mem_raddr
);
parameter AWIDTH = 3;
parameter RAM_DEPTH = (1 << AWIDTH);
parameter EARLY_READ = 0;
parameter CLOCK_CROSSING = 1;
parameter ALMOST_EMPTY_THRESH = 1;
parameter ALMOST_FULL_THRESH = RAM_DEPTH-2;
input              wclk;
input              wrst_n;
input              wen;
output             wfull;
output             walmost_full;
output             mem_wen;
output [AWIDTH:0]  mem_waddr;
input              rclk;
input              rrst_n;
input              ren;
output             rempty;
output             ralmost_empty;
output             mem_ren;
output [AWIDTH:0]  mem_raddr;
reg  [AWIDTH:0]   wr_ptr;
reg  [AWIDTH:0]   rd_ptr;
reg  [AWIDTH:0]   next_rd_ptr;
wire [AWIDTH:0]   wr_gray;
reg  [AWIDTH:0]   wr_gray_meta;
reg  [AWIDTH:0]   wr_gray_sync;
reg  [AWIDTH:0]   wck_rd_ptr;
wire [AWIDTH:0]   wck_level;
wire [AWIDTH:0]   rd_gray;
reg  [AWIDTH:0]   rd_gray_meta;
reg  [AWIDTH:0]   rd_gray_sync;
reg  [AWIDTH:0]   rck_wr_ptr;
wire [AWIDTH:0]   rck_level;
wire [AWIDTH:0]   depth;
wire [AWIDTH:0]   empty_thresh;
wire [AWIDTH:0]   full_thresh;
integer         i;
assign depth = RAM_DEPTH[AWIDTH:0];
assign empty_thresh = ALMOST_EMPTY_THRESH[AWIDTH:0];
assign full_thresh = ALMOST_FULL_THRESH[AWIDTH:0];
assign wfull = (wck_level == depth);
assign walmost_full = (wck_level >= (depth - full_thresh));
assign rempty = (rck_level == 0);
assign ralmost_empty = (rck_level <= empty_thresh);
always @(posedge wclk or negedge wrst_n)
begin
    if (!wrst_n) begin
        wr_ptr <= {(AWIDTH+1){1'b0}};
    end
    else if (wen && !wfull) begin
        wr_ptr <= wr_ptr + {{(AWIDTH){1'b0}}, 1'b1};
    end
end
always @(ren, rd_ptr, rck_wr_ptr)
begin
    next_rd_ptr = rd_ptr;
    if (ren && rd_ptr != rck_wr_ptr) begin
        next_rd_ptr = rd_ptr + {{(AWIDTH){1'b0}}, 1'b1};
    end
end
always @(posedge rclk or negedge rrst_n)
begin
    if (!rrst_n) begin
        rd_ptr <= {(AWIDTH+1){1'b0}};
    end
    else begin
        rd_ptr <= next_rd_ptr;
    end
end
assign wr_gray = wr_ptr ^ (wr_ptr >> 1);
assign rd_gray = rd_ptr ^ (rd_ptr >> 1);
always @(wr_gray_sync)
begin
    rck_wr_ptr[AWIDTH] = wr_gray_sync[AWIDTH];
    for (i = 0; i < AWIDTH; i = i + 1) begin
        rck_wr_ptr[AWIDTH-i-1] = rck_wr_ptr[AWIDTH-i] ^ wr_gray_sync[AWIDTH-i-1];
    end
end
always @(rd_gray_sync)
begin
    wck_rd_ptr[AWIDTH] = rd_gray_sync[AWIDTH];
    for (i = 0; i < AWIDTH; i = i + 1) begin
        wck_rd_ptr[AWIDTH-i-1] = wck_rd_ptr[AWIDTH-i] ^ rd_gray_sync[AWIDTH-i-1];
    end
end
generate
    if (CLOCK_CROSSING) begin
        always @(posedge rclk or negedge rrst_n)
        begin
            if (!rrst_n) begin
                wr_gray_meta <= {(AWIDTH+1){1'b0}};
                wr_gray_sync <= {(AWIDTH+1){1'b0}};
            end
            else begin
                wr_gray_meta <= wr_gray;
                wr_gray_sync <= wr_gray_meta;
            end
        end
        always @(posedge wclk or negedge wrst_n)
        begin
            if (!wrst_n) begin
                rd_gray_meta <= {(AWIDTH+1){1'b0}};
                rd_gray_sync <= {(AWIDTH+1){1'b0}};
            end
            else begin
                rd_gray_meta <= rd_gray;
                rd_gray_sync <= rd_gray_meta;
            end
        end
    end
    else begin
        always @(wr_gray or rd_gray)
        begin
            wr_gray_sync = wr_gray;
            rd_gray_sync = rd_gray;
        end
    end
endgenerate
assign wck_level = wr_ptr - wck_rd_ptr;
assign rck_level = rck_wr_ptr - rd_ptr;
assign  mem_waddr = wr_ptr;
assign  mem_wen = wen && !wfull;
generate
    if (EARLY_READ) begin
        assign mem_raddr = next_rd_ptr;
        assign mem_ren = 1'b1;
    end
    else begin
        assign mem_raddr = rd_ptr;
        assign mem_ren = ren;
    end
endgenerate
endmodule
module generic_mem_medium(
    wclk,
    wrst_n,
    wen,
    waddr,
    wdata,
    rclk,
    rrst_n,
    ren,
    roen,
    raddr,
    rdata
);
parameter DWIDTH = 32;
parameter AWIDTH = 3;
parameter RAM_DEPTH = (1 << AWIDTH);
parameter SYNC_WRITE = 1;
parameter SYNC_READ = 1;
parameter REGISTER_READ = 0;
input               wclk;
input               wrst_n;
input               wen;
input  [AWIDTH:0]   waddr;
input  [DWIDTH-1:0] wdata;
input               rclk;
input               rrst_n;
input               ren;
input               roen;
input  [AWIDTH:0]   raddr;
output [DWIDTH-1:0] rdata;
reg    [DWIDTH-1:0] rdata;
reg  [DWIDTH-1:0] mem_rdata;
reg  [DWIDTH-1:0] mem [0:RAM_DEPTH-1];
integer         i;
generate
    if (SYNC_WRITE) begin
        always @(posedge wclk)
        begin
            if (wen) begin
                mem[waddr[AWIDTH-1:0]] <= wdata;
            end
        end
    end
    else begin
        always @(wen, waddr, wdata)
        begin
            if (wen) begin
                mem[waddr[AWIDTH-1:0]] = wdata;
            end
        end
    end
endgenerate
generate
    if (SYNC_READ) begin
        always @(posedge rclk or negedge rrst_n)
        begin
            if (!rrst_n) begin
                mem_rdata <= {(DWIDTH){1'b0}};
            end else if (ren) begin
                mem_rdata <= mem[raddr[AWIDTH-1:0]];
            end
        end
    end
    else begin
        always @(raddr, rclk)
        begin
            mem_rdata = mem[raddr[AWIDTH-1:0]];
        end
    end
endgenerate
generate
    if (REGISTER_READ) begin
        always @(posedge rclk or negedge rrst_n)
        begin
            if (!rrst_n) begin
                rdata <= {(DWIDTH){1'b0}};
            end else if (roen) begin
                rdata <= mem_rdata;
            end
        end
    end
    else begin
        always @(mem_rdata)
        begin
            rdata = mem_rdata;
        end
    end
endgenerate
endmodule
module generic_mem_small(
    wclk,
    wrst_n,
    wen,
    waddr,
    wdata,
    rclk,
    rrst_n,
    ren,
    roen,
    raddr,
    rdata
);
parameter DWIDTH = 32;
parameter AWIDTH = 3;
parameter RAM_DEPTH = (1 << AWIDTH);
parameter SYNC_WRITE = 1;
parameter SYNC_READ = 1;
parameter REGISTER_READ = 0;
input               wclk;
input               wrst_n;
input               wen;
input  [AWIDTH:0]   waddr;
input  [DWIDTH-1:0] wdata;
input               rclk;
input               rrst_n;
input               ren;
input               roen;
input  [AWIDTH:0]   raddr;
output [DWIDTH-1:0] rdata;
reg    [DWIDTH-1:0] rdata;
reg  [DWIDTH-1:0] mem_rdata;
reg  [DWIDTH-1:0] mem [0:RAM_DEPTH-1];
integer         i;
generate
    if (SYNC_WRITE) begin
        always @(posedge wclk)
        begin
            if (wen) begin
                mem[waddr[AWIDTH-1:0]] <= wdata;
            end
        end
    end
    else begin
        always @(wen, waddr, wdata)
        begin
            if (wen) begin
                mem[waddr[AWIDTH-1:0]] = wdata;
            end
        end
    end
endgenerate
generate
    if (SYNC_READ) begin
        always @(posedge rclk or negedge rrst_n)
        begin
            if (!rrst_n) begin
                mem_rdata <= {(DWIDTH){1'b0}};
            end else if (ren) begin
                mem_rdata <= mem[raddr[AWIDTH-1:0]];
            end
        end
    end
    else begin
        always @(raddr, rclk)
        begin
            mem_rdata = mem[raddr[AWIDTH-1:0]];
        end
    end
endgenerate
generate
    if (REGISTER_READ) begin
        always @(posedge rclk or negedge rrst_n)
        begin
            if (!rrst_n) begin
                rdata <= {(DWIDTH){1'b0}};
            end else if (roen) begin
                rdata <= mem_rdata;
            end
        end
    end
    else begin
        always @(mem_rdata)
        begin
            rdata = mem_rdata;
        end
    end
endgenerate
endmodule
module meta_sync( 
  out,
  clk, reset_n, in
  );
parameter DWIDTH = 1;
parameter EDGE_DETECT = 0;
input                clk;
input                reset_n;
input  [DWIDTH-1:0]  in;
output [DWIDTH-1:0]  out;
generate
genvar               i;
    for (i = 0; i < DWIDTH; i = i + 1) begin : meta
        meta_sync_single #(.EDGE_DETECT (EDGE_DETECT))
          meta_sync_single0 (
                      .out              (out[i]),
                      .clk              (clk),
                      .reset_n          (reset_n),
                      .in               (in[i]));
    end
endgenerate
endmodule
module meta_sync_single( 
  out,
  clk, reset_n, in
  );
parameter EDGE_DETECT = 0;
input   clk;
input   reset_n;
input   in;
output  out;
reg     out;
generate
    if (EDGE_DETECT) begin
      reg   meta;
      reg   edg1;
      reg   edg2;
        always @(posedge clk or negedge reset_n) begin
            if (reset_n == 1'b0) begin
                meta <= 1'b0;
                edg1 <= 1'b0;
                edg2 <= 1'b0;
                out <= 1'b0;
            end
            else begin
                meta <= in;
                edg1 <= meta;
                edg2 <= edg1;
                out <= edg1 ^ edg2;
            end
        end
    end
    else begin
      reg   meta;
        always @(posedge clk or negedge reset_n) begin
            if (reset_n == 1'b0) begin
                meta <= 1'b0;
                out <= 1'b0;
            end
            else begin
                meta <= in;
                out <= meta;
            end
        end
    end
endgenerate
endmodule
module rx_data_fifo( 
  rxdfifo_wfull, rxdfifo_rdata, rxdfifo_rstatus, rxdfifo_rempty, 
  rxdfifo_ralmost_empty, 
  clk_xgmii_rx, clk_156m25, reset_xgmii_rx_n, reset_156m25_n, 
  rxdfifo_wdata, rxdfifo_wstatus, rxdfifo_wen, rxdfifo_ren
  );
input         clk_xgmii_rx;
input         clk_156m25;
input         reset_xgmii_rx_n;
input         reset_156m25_n;
input [63:0]  rxdfifo_wdata;
input [7:0]   rxdfifo_wstatus;
input         rxdfifo_wen;
input         rxdfifo_ren;
output        rxdfifo_wfull;
output [63:0] rxdfifo_rdata;
output [7:0]  rxdfifo_rstatus;
output        rxdfifo_rempty;
output        rxdfifo_ralmost_empty;
generic_fifo #(
  .DWIDTH (72),
  .AWIDTH (7),
  .REGISTER_READ (0),
  .EARLY_READ (1),
  .CLOCK_CROSSING (1),
  .ALMOST_EMPTY_THRESH (4),
  .MEM_TYPE (2)
)
fifo0(
    .wclk (clk_xgmii_rx),
    .wrst_n (reset_xgmii_rx_n),
    .wen (rxdfifo_wen),
    .wdata ({rxdfifo_wstatus, rxdfifo_wdata}),
    .wfull (rxdfifo_wfull),
    .walmost_full (),
    .rclk (clk_156m25),
    .rrst_n (reset_156m25_n),
    .ren (rxdfifo_ren),
    .rdata ({rxdfifo_rstatus, rxdfifo_rdata}),
    .rempty (rxdfifo_rempty),
    .ralmost_empty (rxdfifo_ralmost_empty)
);
endmodule
module rx_dequeue( 
  rxdfifo_ren, pkt_rx_data, pkt_rx_val, pkt_rx_sop, pkt_rx_eop, 
  pkt_rx_err, pkt_rx_mod, pkt_rx_avail, status_rxdfifo_udflow_tog, 
  clk_156m25, reset_156m25_n, rxdfifo_rdata, rxdfifo_rstatus, 
  rxdfifo_rempty, rxdfifo_ralmost_empty, pkt_rx_ren
  );
input         clk_156m25;
input         reset_156m25_n;
input [63:0]  rxdfifo_rdata;
input [7:0]   rxdfifo_rstatus;
input         rxdfifo_rempty;
input         rxdfifo_ralmost_empty;
input         pkt_rx_ren;
output        rxdfifo_ren;
output [63:0] pkt_rx_data;
output        pkt_rx_val;
output        pkt_rx_sop;
output        pkt_rx_eop;
output        pkt_rx_err;
output [2:0]  pkt_rx_mod;
output        pkt_rx_avail;
output        status_rxdfifo_udflow_tog;
reg                     pkt_rx_avail;
reg [63:0]              pkt_rx_data;
reg                     pkt_rx_eop;
reg                     pkt_rx_err;
reg [2:0]               pkt_rx_mod;
reg                     pkt_rx_sop;
reg                     pkt_rx_val;
reg                     status_rxdfifo_udflow_tog;
reg           end_eop;
assign rxdfifo_ren = !rxdfifo_rempty && pkt_rx_ren && !end_eop;
always @(posedge clk_156m25 or negedge reset_156m25_n) begin
    if (reset_156m25_n == 1'b0) begin
        pkt_rx_avail <= 1'b0;
        pkt_rx_data <= 64'b0;
        pkt_rx_sop <= 1'b0;
        pkt_rx_eop <= 1'b0;
        pkt_rx_err <= 1'b0;
        pkt_rx_mod <= 3'b0;
        pkt_rx_val <= 1'b0;
        end_eop <= 1'b0;
        status_rxdfifo_udflow_tog <= 1'b0;
    end
    else begin
        pkt_rx_avail <= !rxdfifo_ralmost_empty;
        pkt_rx_eop <= rxdfifo_ren && rxdfifo_rstatus[3'd6];
        pkt_rx_mod <= {3{rxdfifo_ren & rxdfifo_rstatus[3'd6]}} & rxdfifo_rstatus[2:0];
        pkt_rx_val <= rxdfifo_ren;
        if (rxdfifo_ren) begin
	    pkt_rx_data <= rxdfifo_rdata;
        end
        if (rxdfifo_ren && rxdfifo_rstatus[3'd7]) begin
            pkt_rx_sop <= 1'b1;
            pkt_rx_err <= 1'b0;
        end
        else begin
            pkt_rx_sop <= 1'b0;
            if (rxdfifo_rempty && pkt_rx_ren && !end_eop) begin
                pkt_rx_val <= 1'b1;
                pkt_rx_eop <= 1'b1;
                pkt_rx_err <= 1'b1;
            end
        end
        if (rxdfifo_ren && |(rxdfifo_rstatus[3'd5])) begin
            pkt_rx_err <= 1'b1;
        end
        if (rxdfifo_ren && rxdfifo_rstatus[3'd6]) begin
            end_eop <= 1'b1;
        end
        else if (pkt_rx_ren) begin
            end_eop <= 1'b0;
        end
        if (rxdfifo_rempty && pkt_rx_ren && !end_eop) begin
            status_rxdfifo_udflow_tog <= ~status_rxdfifo_udflow_tog;
        end
    end
end
endmodule
module rx_enqueue( 
  rxdfifo_wdata, rxdfifo_wstatus, rxdfifo_wen, rxhfifo_ren, 
  rxhfifo_wdata, rxhfifo_wstatus, rxhfifo_wen, local_fault_msg_det, 
  remote_fault_msg_det, status_crc_error_tog, 
  status_fragment_error_tog, status_rxdfifo_ovflow_tog, 
  status_pause_frame_rx_tog, 
  clk_xgmii_rx, reset_xgmii_rx_n, xgmii_rxd, xgmii_rxc, 
  rxdfifo_wfull, rxhfifo_rdata, rxhfifo_rstatus, rxhfifo_rempty, 
  rxhfifo_ralmost_empty
  );
  function [31:0] nextCRC32_D64;
    input [63:0] Data;
    input [31:0] CRC;
    reg [63:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[63] ^ D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[54] ^ D[53] ^ 
                D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[37] ^ D[34] ^ 
                D[32] ^ D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[26] ^ D[25] ^ 
                D[24] ^ D[16] ^ D[12] ^ D[10] ^ D[9] ^ D[6] ^ D[0] ^ 
                C[0] ^ C[2] ^ C[5] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                C[18] ^ C[21] ^ C[22] ^ C[23] ^ C[26] ^ C[28] ^ C[29] ^ 
                C[31];
    NewCRC[1] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ 
                D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[28] ^ D[27] ^ D[24] ^ 
                D[17] ^ D[16] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[7] ^ 
                D[6] ^ D[1] ^ D[0] ^ C[1] ^ C[2] ^ C[3] ^ C[5] ^ C[6] ^ 
                C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ 
                C[24] ^ C[26] ^ C[27] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[2] = D[59] ^ D[58] ^ D[57] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[44] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[35] ^ D[32] ^ 
                D[31] ^ D[30] ^ D[26] ^ D[24] ^ D[18] ^ D[17] ^ D[16] ^ 
                D[14] ^ D[13] ^ D[9] ^ D[8] ^ D[7] ^ D[6] ^ D[2] ^ 
                D[1] ^ D[0] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[12] ^ C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[25] ^ C[26] ^ 
                C[27];
    NewCRC[3] = D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[54] ^ D[53] ^ D[52] ^ 
                D[45] ^ D[40] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[33] ^ 
                D[32] ^ D[31] ^ D[27] ^ D[25] ^ D[19] ^ D[18] ^ D[17] ^ 
                D[15] ^ D[14] ^ D[10] ^ D[9] ^ D[8] ^ D[7] ^ D[3] ^ 
                D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[8] ^ C[13] ^ C[20] ^ C[21] ^ C[22] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28];
    NewCRC[4] = D[63] ^ D[59] ^ D[58] ^ D[57] ^ D[50] ^ D[48] ^ D[47] ^ 
                D[46] ^ D[45] ^ D[44] ^ D[41] ^ D[40] ^ D[39] ^ D[38] ^ 
                D[33] ^ D[31] ^ D[30] ^ D[29] ^ D[25] ^ D[24] ^ D[20] ^ 
                D[19] ^ D[18] ^ D[15] ^ D[12] ^ D[11] ^ D[8] ^ D[6] ^ 
                D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[1] ^ C[6] ^ C[7] ^ C[8] ^ 
                C[9] ^ C[12] ^ C[13] ^ C[14] ^ C[15] ^ C[16] ^ C[18] ^ 
                C[25] ^ C[26] ^ C[27] ^ C[31];
    NewCRC[5] = D[63] ^ D[61] ^ D[59] ^ D[55] ^ D[54] ^ D[53] ^ D[51] ^ 
                D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[39] ^ D[37] ^ D[29] ^ D[28] ^ D[24] ^ D[21] ^ D[20] ^ 
                D[19] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[3] ^ D[1] ^ D[0] ^ C[5] ^ C[7] ^ C[8] ^ C[9] ^ C[10] ^ 
                C[12] ^ C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ C[22] ^ 
                C[23] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[6] = D[62] ^ D[60] ^ D[56] ^ D[55] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[38] ^ D[30] ^ D[29] ^ D[25] ^ D[22] ^ D[21] ^ D[20] ^ 
                D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[2] ^ D[1] ^ C[6] ^ C[8] ^ C[9] ^ C[10] ^ C[11] ^ 
                C[13] ^ C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[23] ^ 
                C[24] ^ C[28] ^ C[30];
    NewCRC[7] = D[60] ^ D[58] ^ D[57] ^ D[56] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ 
                D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[29] ^ D[28] ^ D[25] ^ 
                D[24] ^ D[23] ^ D[22] ^ D[21] ^ D[16] ^ D[15] ^ D[10] ^ 
                D[8] ^ D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[2] ^ 
                C[5] ^ C[7] ^ C[9] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[28];
    NewCRC[8] = D[63] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[40] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[31] ^ D[28] ^ 
                D[23] ^ D[22] ^ D[17] ^ D[12] ^ D[11] ^ D[10] ^ D[8] ^ 
                D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ 
                C[5] ^ C[6] ^ C[8] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ 
                C[31];
    NewCRC[9] = D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ D[39] ^ D[38] ^ 
                D[36] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[29] ^ D[24] ^ 
                D[23] ^ D[18] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[5] ^ 
                D[4] ^ D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ C[4] ^ 
                C[6] ^ C[7] ^ C[9] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ 
                C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[26] ^ C[28] ^ C[29];
    NewCRC[10] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[52] ^ D[50] ^ D[42] ^ D[40] ^ D[39] ^ D[36] ^ D[35] ^ 
                 D[33] ^ D[32] ^ D[31] ^ D[29] ^ D[28] ^ D[26] ^ D[19] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[9] ^ D[5] ^ D[3] ^ D[2] ^ 
                 D[0] ^ C[0] ^ C[1] ^ C[3] ^ C[4] ^ C[7] ^ C[8] ^ C[10] ^ 
                 C[18] ^ C[20] ^ C[23] ^ C[24] ^ C[26] ^ C[27] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[11] = D[59] ^ D[58] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[36] ^ D[33] ^ D[31] ^ D[28] ^ D[27] ^ D[26] ^ 
                 D[25] ^ D[24] ^ D[20] ^ D[17] ^ D[16] ^ D[15] ^ D[14] ^ 
                 D[12] ^ D[9] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[1] ^ C[4] ^ 
                 C[8] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                 C[18] ^ C[19] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[27];
    NewCRC[12] = D[63] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[42] ^ 
                 D[41] ^ D[31] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[18] ^ 
                 D[17] ^ D[15] ^ D[13] ^ D[12] ^ D[9] ^ D[6] ^ D[5] ^ 
                 D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[9] ^ C[10] ^ C[14] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ 
                 C[24] ^ C[25] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[13] = D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[42] ^ 
                 D[32] ^ D[31] ^ D[28] ^ D[25] ^ D[22] ^ D[19] ^ D[18] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ 
                 D[3] ^ D[2] ^ D[1] ^ C[0] ^ C[10] ^ C[11] ^ C[15] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[30];
    NewCRC[14] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[51] ^ D[49] ^ D[48] ^ D[44] ^ D[43] ^ 
                 D[33] ^ D[32] ^ D[29] ^ D[26] ^ D[23] ^ D[20] ^ D[19] ^ 
                 D[17] ^ D[15] ^ D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[2] ^ C[0] ^ C[1] ^ C[11] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[24] ^ C[26] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[15] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[50] ^ D[49] ^ D[45] ^ D[44] ^ D[34] ^ 
                 D[33] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[20] ^ D[18] ^ 
                 D[16] ^ D[15] ^ D[12] ^ D[9] ^ D[8] ^ D[7] ^ D[5] ^ 
                 D[4] ^ D[3] ^ C[1] ^ C[2] ^ C[12] ^ C[13] ^ C[17] ^ 
                 C[18] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[16] = D[57] ^ D[56] ^ D[51] ^ D[48] ^ D[47] ^ D[46] ^ D[44] ^ 
                 D[37] ^ D[35] ^ D[32] ^ D[30] ^ D[29] ^ D[26] ^ D[24] ^ 
                 D[22] ^ D[21] ^ D[19] ^ D[17] ^ D[13] ^ D[12] ^ D[8] ^ 
                 D[5] ^ D[4] ^ D[0] ^ C[0] ^ C[3] ^ C[5] ^ C[12] ^ C[14] ^ 
                 C[15] ^ C[16] ^ C[19] ^ C[24] ^ C[25];
    NewCRC[17] = D[58] ^ D[57] ^ D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[45] ^ 
                 D[38] ^ D[36] ^ D[33] ^ D[31] ^ D[30] ^ D[27] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[18] ^ D[14] ^ D[13] ^ D[9] ^ 
                 D[6] ^ D[5] ^ D[1] ^ C[1] ^ C[4] ^ C[6] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[17] ^ C[20] ^ C[25] ^ C[26];
    NewCRC[18] = D[59] ^ D[58] ^ D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[46] ^ 
                 D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[31] ^ D[28] ^ D[26] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[19] ^ D[15] ^ D[14] ^ D[10] ^ 
                 D[7] ^ D[6] ^ D[2] ^ C[0] ^ C[2] ^ C[5] ^ C[7] ^ C[14] ^ 
                 C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[26] ^ C[27];
    NewCRC[19] = D[60] ^ D[59] ^ D[54] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ 
                 D[40] ^ D[38] ^ D[35] ^ D[33] ^ D[32] ^ D[29] ^ D[27] ^ 
                 D[25] ^ D[24] ^ D[22] ^ D[20] ^ D[16] ^ D[15] ^ D[11] ^ 
                 D[8] ^ D[7] ^ D[3] ^ C[0] ^ C[1] ^ C[3] ^ C[6] ^ C[8] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[27] ^ C[28];
    NewCRC[20] = D[61] ^ D[60] ^ D[55] ^ D[52] ^ D[51] ^ D[50] ^ D[48] ^ 
                 D[41] ^ D[39] ^ D[36] ^ D[34] ^ D[33] ^ D[30] ^ D[28] ^ 
                 D[26] ^ D[25] ^ D[23] ^ D[21] ^ D[17] ^ D[16] ^ D[12] ^ 
                 D[9] ^ D[8] ^ D[4] ^ C[1] ^ C[2] ^ C[4] ^ C[7] ^ C[9] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[28] ^ C[29];
    NewCRC[21] = D[62] ^ D[61] ^ D[56] ^ D[53] ^ D[52] ^ D[51] ^ D[49] ^ 
                 D[42] ^ D[40] ^ D[37] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ 
                 D[27] ^ D[26] ^ D[24] ^ D[22] ^ D[18] ^ D[17] ^ D[13] ^ 
                 D[10] ^ D[9] ^ D[5] ^ C[2] ^ C[3] ^ C[5] ^ C[8] ^ C[10] ^ 
                 C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[29] ^ C[30];
    NewCRC[22] = D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ D[38] ^ 
                 D[37] ^ D[36] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ 
                 D[26] ^ D[24] ^ D[23] ^ D[19] ^ D[18] ^ D[16] ^ D[14] ^ 
                 D[12] ^ D[11] ^ D[9] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ 
                 C[5] ^ C[6] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ C[29] ^ 
                 C[30];
    NewCRC[23] = D[62] ^ D[60] ^ D[59] ^ D[56] ^ D[55] ^ D[54] ^ D[50] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[42] ^ D[39] ^ D[38] ^ D[36] ^ 
                 D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[20] ^ 
                 D[19] ^ D[17] ^ D[16] ^ D[15] ^ D[13] ^ D[9] ^ D[6] ^ 
                 D[1] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ C[6] ^ C[7] ^ C[10] ^ 
                 C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[22] ^ C[23] ^ C[24] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[24] = D[63] ^ D[61] ^ D[60] ^ D[57] ^ D[56] ^ D[55] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[40] ^ D[39] ^ D[37] ^ 
                 D[36] ^ D[35] ^ D[32] ^ D[30] ^ D[28] ^ D[27] ^ D[21] ^ 
                 D[20] ^ D[18] ^ D[17] ^ D[16] ^ D[14] ^ D[10] ^ D[7] ^ 
                 D[2] ^ D[1] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[7] ^ C[8] ^ 
                 C[11] ^ C[15] ^ C[16] ^ C[18] ^ C[19] ^ C[23] ^ C[24] ^ 
                 C[25] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[25] = D[62] ^ D[61] ^ D[58] ^ D[57] ^ D[56] ^ D[52] ^ D[51] ^ 
                 D[49] ^ D[48] ^ D[44] ^ D[41] ^ D[40] ^ D[38] ^ D[37] ^ 
                 D[36] ^ D[33] ^ D[31] ^ D[29] ^ D[28] ^ D[22] ^ D[21] ^ 
                 D[19] ^ D[18] ^ D[17] ^ D[15] ^ D[11] ^ D[8] ^ D[3] ^ 
                 D[2] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[8] ^ C[9] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[29] ^ C[30];
    NewCRC[26] = D[62] ^ D[61] ^ D[60] ^ D[59] ^ D[57] ^ D[55] ^ D[54] ^ 
                 D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[39] ^ D[38] ^ D[31] ^ D[28] ^ D[26] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[19] ^ D[18] ^ D[10] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[0] ^ C[6] ^ C[7] ^ C[9] ^ C[10] ^ C[12] ^ 
                 C[15] ^ C[16] ^ C[17] ^ C[20] ^ C[22] ^ C[23] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[27] = D[63] ^ D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[45] ^ D[43] ^ D[42] ^ 
                 D[40] ^ D[39] ^ D[32] ^ D[29] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[20] ^ D[19] ^ D[11] ^ D[7] ^ 
                 D[5] ^ D[4] ^ D[1] ^ C[0] ^ C[7] ^ C[8] ^ C[10] ^ C[11] ^ 
                 C[13] ^ C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[23] ^ C[24] ^ 
                 C[26] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[28] = D[63] ^ D[62] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ 
                 D[51] ^ D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[33] ^ D[30] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[22] ^ D[21] ^ D[20] ^ D[12] ^ D[8] ^ D[6] ^ 
                 D[5] ^ D[2] ^ C[1] ^ C[8] ^ C[9] ^ C[11] ^ C[12] ^ 
                 C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[29] = D[63] ^ D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[51] ^ D[50] ^ D[47] ^ D[45] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[34] ^ D[31] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[21] ^ D[13] ^ D[9] ^ D[7] ^ D[6] ^ 
                 D[3] ^ C[2] ^ C[9] ^ C[10] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[30] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ D[52] ^ 
                 D[51] ^ D[48] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[35] ^ 
                 D[32] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[14] ^ D[10] ^ D[8] ^ D[7] ^ D[4] ^ 
                 C[0] ^ C[3] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ C[16] ^ 
                 C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[26] ^ C[27] ^ C[29] ^ 
                 C[31];
    NewCRC[31] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[53] ^ D[52] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[36] ^ D[33] ^ 
                 D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[15] ^ D[11] ^ D[9] ^ D[8] ^ D[5] ^ C[1] ^ 
                 C[4] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[20] ^ 
                 C[21] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ C[30];
    nextCRC32_D64 = NewCRC;
  end
  endfunction
  function [31:0] nextCRC32_D8;
    input [7:0] Data;
    input [31:0] CRC;
    reg [7:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[6] ^ D[0] ^ C[24] ^ C[30];
    NewCRC[1] = D[7] ^ D[6] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ C[30] ^ 
                C[31];
    NewCRC[2] = D[7] ^ D[6] ^ D[2] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[30] ^ C[31];
    NewCRC[3] = D[7] ^ D[3] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ C[27] ^ 
                C[31];
    NewCRC[4] = D[6] ^ D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28] ^ C[30];
    NewCRC[5] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[24] ^ 
                C[25] ^ C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[6] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[7] = D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[29] ^ C[31];
    NewCRC[8] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[24] ^ C[25] ^ 
                C[27] ^ C[28];
    NewCRC[9] = D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29];
    NewCRC[10] = D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[2] ^ C[24] ^ C[26] ^ 
                 C[27] ^ C[29];
    NewCRC[11] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[3] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28];
    NewCRC[12] = D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[4] ^ C[24] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[13] = D[7] ^ D[6] ^ D[5] ^ D[3] ^ D[2] ^ D[1] ^ C[5] ^ C[25] ^ 
                 C[26] ^ C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[14] = D[7] ^ D[6] ^ D[4] ^ D[3] ^ D[2] ^ C[6] ^ C[26] ^ C[27] ^ 
                 C[28] ^ C[30] ^ C[31];
    NewCRC[15] = D[7] ^ D[5] ^ D[4] ^ D[3] ^ C[7] ^ C[27] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[16] = D[5] ^ D[4] ^ D[0] ^ C[8] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[17] = D[6] ^ D[5] ^ D[1] ^ C[9] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[18] = D[7] ^ D[6] ^ D[2] ^ C[10] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[19] = D[7] ^ D[3] ^ C[11] ^ C[27] ^ C[31];
    NewCRC[20] = D[4] ^ C[12] ^ C[28];
    NewCRC[21] = D[5] ^ C[13] ^ C[29];
    NewCRC[22] = D[0] ^ C[14] ^ C[24];
    NewCRC[23] = D[6] ^ D[1] ^ D[0] ^ C[15] ^ C[24] ^ C[25] ^ C[30];
    NewCRC[24] = D[7] ^ D[2] ^ D[1] ^ C[16] ^ C[25] ^ C[26] ^ C[31];
    NewCRC[25] = D[3] ^ D[2] ^ C[17] ^ C[26] ^ C[27];
    NewCRC[26] = D[6] ^ D[4] ^ D[3] ^ D[0] ^ C[18] ^ C[24] ^ C[27] ^ 
                 C[28] ^ C[30];
    NewCRC[27] = D[7] ^ D[5] ^ D[4] ^ D[1] ^ C[19] ^ C[25] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[28] = D[6] ^ D[5] ^ D[2] ^ C[20] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[29] = D[7] ^ D[6] ^ D[3] ^ C[21] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[30] = D[7] ^ D[4] ^ C[22] ^ C[28] ^ C[31];
    NewCRC[31] = D[5] ^ C[23] ^ C[29];
    nextCRC32_D8 = NewCRC;
  end
  endfunction
function [63:0] reverse_64b;
  input [63:0]   data;
  integer        i;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            reverse_64b[i] = data[63 - i];
        end
    end
endfunction
function [31:0] reverse_32b;
  input [31:0]   data;
  integer        i;
    begin
        for (i = 0; i < 32; i = i + 1) begin
            reverse_32b[i] = data[31 - i];
        end
    end
endfunction
function [7:0] reverse_8b;
  input [7:0]   data;
  integer        i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_8b[i] = data[7 - i];
        end
    end
endfunction
input         clk_xgmii_rx;
input         reset_xgmii_rx_n;
input  [63:0] xgmii_rxd;
input  [7:0]  xgmii_rxc;
input         rxdfifo_wfull;
input  [63:0] rxhfifo_rdata;
input  [7:0]  rxhfifo_rstatus;
input         rxhfifo_rempty;
input         rxhfifo_ralmost_empty;
output [63:0] rxdfifo_wdata;
output [7:0]  rxdfifo_wstatus;
output        rxdfifo_wen;   
output        rxhfifo_ren;
output [63:0] rxhfifo_wdata;
output [7:0]  rxhfifo_wstatus;
output        rxhfifo_wen;
output [1:0]  local_fault_msg_det;
output [1:0]  remote_fault_msg_det;
output        status_crc_error_tog;
output        status_fragment_error_tog;
output        status_rxdfifo_ovflow_tog;
output        status_pause_frame_rx_tog;
reg [1:0]               local_fault_msg_det;
reg [1:0]               remote_fault_msg_det;
reg [63:0]              rxdfifo_wdata;
reg                     rxdfifo_wen;
reg [7:0]               rxdfifo_wstatus;
reg                     rxhfifo_ren;
reg [63:0]              rxhfifo_wdata;
reg                     rxhfifo_wen;
reg [7:0]               rxhfifo_wstatus;
reg                     status_crc_error_tog;
reg                     status_fragment_error_tog;
reg                     status_pause_frame_rx_tog;
reg                     status_rxdfifo_ovflow_tog;
reg [63:32]   xgmii_rxd_d1;
reg [7:4]     xgmii_rxc_d1;
reg [63:0]    xgxs_rxd_barrel;
reg [7:0]     xgxs_rxc_barrel;
reg [63:0]    xgxs_rxd_barrel_d1;
reg [7:0]     xgxs_rxc_barrel_d1;
reg           barrel_shift;
reg [31:0]    crc32_d64;
reg [31:0]    crc32_d8;
reg [3:0]     crc_bytes;
reg [3:0]     next_crc_bytes;
reg [63:0]    crc_shift_data;
reg           crc_start_8b;
reg           crc_done;
reg	      crc_good;
reg           crc_clear;
reg [31:0]    crc_rx;
reg [31:0]    next_crc_rx;
reg [2:0]     curr_state;
reg [2:0]     next_state;
reg [13:0]    curr_byte_cnt;
reg [13:0]    next_byte_cnt;
reg           fragment_error;
reg           rxd_ovflow_error;
reg           coding_error;
reg           next_coding_error;
reg [7:0]     addmask;
reg [7:0]     datamask;
reg           pause_frame;
reg           next_pause_frame;
reg           pause_frame_hold;
reg           good_pause_frame;
reg           drop_data;
reg           next_drop_data;
reg           pkt_pending;
reg           rxhfifo_ren_d1;
reg           rxhfifo_ralmost_empty_d1;
parameter [2:0]
             SM_IDLE = 3'd0,
             SM_RX = 3'd1;
always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if (reset_xgmii_rx_n == 1'b0) begin
        xgmii_rxd_d1 <= 32'b0;
        xgmii_rxc_d1 <= 4'b0;
        xgxs_rxd_barrel <= 64'b0;
        xgxs_rxc_barrel <= 8'b0;
        xgxs_rxd_barrel_d1 <= 64'b0;
        xgxs_rxc_barrel_d1 <= 8'b0;
        barrel_shift <= 1'b0;
        local_fault_msg_det <= 2'b0;
        remote_fault_msg_det <= 2'b0;
        crc32_d64 <= 32'b0;
        crc32_d8 <= 32'b0;
        crc_bytes <= 4'b0;
        crc_shift_data <= 64'b0;
        crc_done <= 1'b0;
        crc_rx <= 32'b0;
        pause_frame_hold <= 1'b0;
        status_crc_error_tog <= 1'b0;
        status_fragment_error_tog <= 1'b0;
        status_rxdfifo_ovflow_tog <= 1'b0;
        status_pause_frame_rx_tog <= 1'b0;
    end
    else begin
        local_fault_msg_det[1] <= (xgmii_rxd[63:32] ==
                                   {8'd1, 8'h0, 8'h0, 8'h9c} &&
                                   xgmii_rxc[7:4] == 4'b0001);
        local_fault_msg_det[0] <= (xgmii_rxd[31:0] ==
                                   {8'd1, 8'h0, 8'h0, 8'h9c} &&
                                   xgmii_rxc[3:0] == 4'b0001);
        remote_fault_msg_det[1] <= (xgmii_rxd[63:32] ==
                                    {8'd2, 8'h0, 8'h0, 8'h9c} &&
                                    xgmii_rxc[7:4] == 4'b0001);
        remote_fault_msg_det[0] <= (xgmii_rxd[31:0] ==
                                    {8'd2, 8'h0, 8'h0, 8'h9c} &&
                                    xgmii_rxc[3:0] == 4'b0001);
        xgmii_rxd_d1[63:32] <= xgmii_rxd[63:32];
        xgmii_rxc_d1[7:4] <= xgmii_rxc[7:4];
        if (xgmii_rxd[7:0] == 8'hfb && xgmii_rxc[0]) begin
            xgxs_rxd_barrel <= xgmii_rxd;
            xgxs_rxc_barrel <= xgmii_rxc;
            barrel_shift <= 1'b0;
        end
        else if (xgmii_rxd[39:32] == 8'hfb && xgmii_rxc[4]) begin
            xgxs_rxd_barrel <= {xgmii_rxd[31:0], xgmii_rxd_d1[63:32]};
            xgxs_rxc_barrel <= {xgmii_rxc[3:0], xgmii_rxc_d1[7:4]};
            barrel_shift <= 1'b1;
        end
        else if (barrel_shift) begin
            xgxs_rxd_barrel <= {xgmii_rxd[31:0], xgmii_rxd_d1[63:32]};
            xgxs_rxc_barrel <= {xgmii_rxc[3:0], xgmii_rxc_d1[7:4]};
        end
        else begin
            xgxs_rxd_barrel <= xgmii_rxd;
            xgxs_rxc_barrel <= xgmii_rxc;
        end
        xgxs_rxd_barrel_d1 <= xgxs_rxd_barrel;
        xgxs_rxc_barrel_d1 <= xgxs_rxc_barrel;
        if (crc_start_8b) begin
            pause_frame_hold <= pause_frame;
        end
        crc_rx <= next_crc_rx;
        if (crc_clear) begin
            crc32_d64 <= 32'hffffffff;
        end
        else begin
            crc32_d64 <= nextCRC32_D64(reverse_64b(xgxs_rxd_barrel_d1), crc32_d64);
        end
        if (crc_bytes != 4'b0) begin
            if (crc_bytes == 4'b1) begin
                crc_done <= 1'b1;
            end
            crc32_d8 <= nextCRC32_D8(reverse_8b(crc_shift_data[7:0]), crc32_d8);
            crc_shift_data <= {8'h00, crc_shift_data[63:8]};
            crc_bytes <= crc_bytes - 4'b1;
        end
        else if (crc_bytes == 4'b0) begin
            if (coding_error || next_coding_error) begin
                crc32_d8 <= ~crc32_d64;
            end
            else begin
                crc32_d8 <= crc32_d64;
            end
            crc_done <= 1'b0;
            crc_shift_data <= xgxs_rxd_barrel_d1;
            crc_bytes <= next_crc_bytes;
        end
        if (crc_done && !crc_good) begin
            status_crc_error_tog <= ~status_crc_error_tog;
        end
        if (fragment_error) begin
            status_fragment_error_tog <= ~status_fragment_error_tog;
        end
        if (rxd_ovflow_error) begin
            status_rxdfifo_ovflow_tog <= ~status_rxdfifo_ovflow_tog;
        end
        if (good_pause_frame) begin
            status_pause_frame_rx_tog <= ~status_pause_frame_rx_tog;
        end
    end
end
always @( crc32_d8 or crc_done or crc_rx or pause_frame_hold) begin
    crc_good = 1'b0;
    good_pause_frame = 1'b0;
    if (crc_done) begin
        if (crc_rx == ~reverse_32b(crc32_d8)) begin
            crc_good = 1'b1;
            good_pause_frame = pause_frame_hold;
        end
    end
end
always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if (reset_xgmii_rx_n == 1'b0) begin
        curr_state <= SM_IDLE;
        curr_byte_cnt <= 14'b0;
        coding_error <= 1'b0;
        pause_frame <= 1'b0;
    end
    else begin
        curr_state <= next_state;
        curr_byte_cnt <= next_byte_cnt;
        coding_error <= next_coding_error;
        pause_frame <= next_pause_frame;
    end
end
always @( coding_error or crc_rx or curr_byte_cnt or curr_state
         or pause_frame or xgxs_rxc_barrel or xgxs_rxc_barrel_d1
         or xgxs_rxd_barrel or xgxs_rxd_barrel_d1) begin
    next_state = curr_state;
    rxhfifo_wdata = xgxs_rxd_barrel_d1;
    rxhfifo_wstatus = 8'h0;
    rxhfifo_wen = 1'b0;
    addmask[0] = !(xgxs_rxd_barrel_d1[7:0] == 8'hfd && xgxs_rxc_barrel_d1[0]);
    addmask[1] = !(xgxs_rxd_barrel_d1[15:8] == 8'hfd && xgxs_rxc_barrel_d1[1]);
    addmask[2] = !(xgxs_rxd_barrel_d1[23:16] == 8'hfd && xgxs_rxc_barrel_d1[2]);
    addmask[3] = !(xgxs_rxd_barrel_d1[31:24] == 8'hfd && xgxs_rxc_barrel_d1[3]);
    addmask[4] = !(xgxs_rxd_barrel_d1[39:32] == 8'hfd && xgxs_rxc_barrel_d1[4]);
    addmask[5] = !(xgxs_rxd_barrel_d1[47:40] == 8'hfd && xgxs_rxc_barrel_d1[5]);
    addmask[6] = !(xgxs_rxd_barrel_d1[55:48] == 8'hfd && xgxs_rxc_barrel_d1[6]);
    addmask[7] = !(xgxs_rxd_barrel_d1[63:56] == 8'hfd && xgxs_rxc_barrel_d1[7]);
    datamask[0] = addmask[0];
    datamask[1] = &addmask[1:0];
    datamask[2] = &addmask[2:0];
    datamask[3] = &addmask[3:0];
    datamask[4] = &addmask[4:0];
    datamask[5] = &addmask[5:0];
    datamask[6] = &addmask[6:0];
    datamask[7] = &addmask[7:0];
    next_crc_bytes = 4'b0;
    next_crc_rx = crc_rx;
    crc_start_8b = 1'b0;
    crc_clear = 1'b0;
    next_byte_cnt = curr_byte_cnt;
    fragment_error = 1'b0;
    next_coding_error = coding_error;
    next_pause_frame = pause_frame;
    case (curr_state)
        SM_IDLE:
          begin
              next_byte_cnt = 14'b0;
              crc_clear = 1'b1;
              next_coding_error = 1'b0;
              next_pause_frame = 1'b0;
              if (xgxs_rxd_barrel_d1[7:0] == 8'hfb && xgxs_rxc_barrel_d1[0] &&
                  xgxs_rxd_barrel_d1[15:8] == 8'h55 && !xgxs_rxc_barrel_d1[1] &&
                  xgxs_rxd_barrel_d1[23:16] == 8'h55 && !xgxs_rxc_barrel_d1[2] &&
                  xgxs_rxd_barrel_d1[31:24] == 8'h55 && !xgxs_rxc_barrel_d1[3] &&
                  xgxs_rxd_barrel_d1[39:32] == 8'h55 && !xgxs_rxc_barrel_d1[4] &&
                  xgxs_rxd_barrel_d1[47:40] == 8'h55 && !xgxs_rxc_barrel_d1[5] &&
                  xgxs_rxd_barrel_d1[55:48] == 8'h55 && !xgxs_rxc_barrel_d1[6] &&
                  xgxs_rxd_barrel_d1[63:56] == 8'hd5 && !xgxs_rxc_barrel_d1[7]) begin
                  next_state = SM_RX;
              end
          end
        SM_RX:
          begin
              rxhfifo_wen = !pause_frame;
              if (xgxs_rxd_barrel_d1[7:0] == 8'hfb && xgxs_rxc_barrel_d1[0] &&
                  xgxs_rxd_barrel_d1[63:56] == 8'hd5 && !xgxs_rxc_barrel_d1[7]) begin
                  next_byte_cnt = 14'b0;
                  crc_clear = 1'b1;
                  next_coding_error = 1'b0;
                  fragment_error = 1'b1;
                  rxhfifo_wstatus[3'd5] = 1'b1;
                  if (curr_byte_cnt == 14'b0) begin
                      rxhfifo_wen = 1'b0;
                  end
                  else begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                  end
              end
              else if (curr_byte_cnt > 14'd9900) begin
                  fragment_error = 1'b1;
                  rxhfifo_wstatus[3'd5] = 1'b1;
                  rxhfifo_wstatus[3'd6] = 1'b1;
                  next_state = SM_IDLE;
              end
              else begin
                  if (curr_byte_cnt == 14'd0 &&
                      xgxs_rxd_barrel_d1[47:0] == 48'h010000c28001) begin
                      rxhfifo_wen = 1'b0;
                      next_pause_frame = 1'b1;
                  end
                  if (|(xgxs_rxc_barrel_d1 & datamask)) begin
                      next_coding_error = 1'b1;
                  end
                  if (curr_byte_cnt == 14'b0) begin
                      rxhfifo_wstatus[3'd7] = 1'b1;
                  end
                  next_byte_cnt = curr_byte_cnt +
                                  addmask[0] + addmask[1] + addmask[2] + addmask[3] +
                                  addmask[4] + addmask[5] + addmask[6] + addmask[7];
                  if (xgxs_rxd_barrel[39:32] == 8'hfd && xgxs_rxc_barrel[4]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd0;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd8;
                      next_crc_rx = xgxs_rxd_barrel[31:0];
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel[31:24] == 8'hfd && xgxs_rxc_barrel[3]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd7;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd7;
                      next_crc_rx = {xgxs_rxd_barrel[23:0], xgxs_rxd_barrel_d1[63:56]};
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel[23:16] == 8'hfd && xgxs_rxc_barrel[2]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd6;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd6;
                      next_crc_rx = {xgxs_rxd_barrel[15:0], xgxs_rxd_barrel_d1[63:48]};
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel[15:8] == 8'hfd && xgxs_rxc_barrel[1]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd5;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd5;
                      next_crc_rx = {xgxs_rxd_barrel[7:0], xgxs_rxd_barrel_d1[63:40]};
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel[7:0] == 8'hfd && xgxs_rxc_barrel[0]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd4;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd4;
                      next_crc_rx = xgxs_rxd_barrel_d1[63:32];
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel_d1[63:56] == 8'hfd &&
                      xgxs_rxc_barrel_d1[7]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd3;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd3;
                      next_crc_rx = xgxs_rxd_barrel_d1[55:24];
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel_d1[55:48] == 8'hfd &&
                      xgxs_rxc_barrel_d1[6]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd2;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd2;
                      next_crc_rx = xgxs_rxd_barrel_d1[47:16];
                      next_state = SM_IDLE;
                  end
                  if (xgxs_rxd_barrel_d1[47:40] == 8'hfd &&
                      xgxs_rxc_barrel_d1[5]) begin
                      rxhfifo_wstatus[3'd6] = 1'b1;
                      rxhfifo_wstatus[2:0] = 3'd1;
                      crc_start_8b = 1'b1;
                      next_crc_bytes = 4'd1;
                      next_crc_rx = xgxs_rxd_barrel_d1[39:8];
                      next_state = SM_IDLE;
                  end
              end
          end
        default:
          begin
              next_state = SM_IDLE;
          end
    endcase
end
always @(posedge clk_xgmii_rx or negedge reset_xgmii_rx_n) begin
    if (reset_xgmii_rx_n == 1'b0) begin
        rxhfifo_ralmost_empty_d1 <= 1'b1;
        drop_data <= 1'b0;
        pkt_pending <= 1'b0;
        rxhfifo_ren_d1 <= 1'b0;
    end
    else begin
        rxhfifo_ralmost_empty_d1 <= rxhfifo_ralmost_empty;
        drop_data <= next_drop_data;
        pkt_pending <= rxhfifo_ren;
        rxhfifo_ren_d1 <= rxhfifo_ren;
    end
end
always @( crc_done or crc_good or drop_data or pkt_pending
         or rxdfifo_wfull or rxhfifo_ralmost_empty_d1 or rxhfifo_rdata
         or rxhfifo_ren_d1 or rxhfifo_rstatus) begin
    rxd_ovflow_error = 1'b0;
    rxdfifo_wdata = rxhfifo_rdata;
    rxdfifo_wstatus = rxhfifo_rstatus;
    next_drop_data = drop_data;
    rxhfifo_ren = !rxhfifo_ralmost_empty_d1 ||
                  (pkt_pending && !rxhfifo_rstatus[3'd6]);
    if (rxhfifo_ren_d1 && rxhfifo_rstatus[3'd7]) begin
        next_drop_data = 1'b0;
    end
    if (rxhfifo_ren_d1 && rxdfifo_wfull && !next_drop_data) begin
        rxd_ovflow_error = 1'b1;
        next_drop_data = 1'b1;
    end
    rxdfifo_wen = rxhfifo_ren_d1 && !next_drop_data;
    if (crc_done && !crc_good) begin
        rxdfifo_wstatus[3'd5] = 1'b1;
    end
end
endmodule
module rx_hold_fifo( 
  rxhfifo_rdata, rxhfifo_rstatus, rxhfifo_rempty, 
  rxhfifo_ralmost_empty, 
  clk_xgmii_rx, reset_xgmii_rx_n, rxhfifo_wdata, rxhfifo_wstatus, 
  rxhfifo_wen, rxhfifo_ren
  );
input         clk_xgmii_rx;
input         reset_xgmii_rx_n;
input [63:0]  rxhfifo_wdata;
input [7:0]   rxhfifo_wstatus;
input         rxhfifo_wen;
input         rxhfifo_ren;
output [63:0] rxhfifo_rdata;
output [7:0]  rxhfifo_rstatus;
output        rxhfifo_rempty;
output        rxhfifo_ralmost_empty;
generic_fifo #(
  .DWIDTH (72),
  .AWIDTH (4),
  .REGISTER_READ (1),
  .EARLY_READ (1),
  .CLOCK_CROSSING (0),
  .ALMOST_EMPTY_THRESH (7),
  .MEM_TYPE (1)
)
fifo0(
    .wclk (clk_xgmii_rx),
    .wrst_n (reset_xgmii_rx_n),
    .wen (rxhfifo_wen),
    .wdata ({rxhfifo_wstatus, rxhfifo_wdata}),
    .wfull (),
    .walmost_full (),
    .rclk (clk_xgmii_rx),
    .rrst_n (reset_xgmii_rx_n),
    .ren (rxhfifo_ren),
    .rdata ({rxhfifo_rstatus, rxhfifo_rdata}),
    .rempty (rxhfifo_rempty),
    .ralmost_empty (rxhfifo_ralmost_empty)
);
endmodule
module sync_clk_core( 
  clk_xgmii_tx, reset_xgmii_tx_n
  );
input         clk_xgmii_tx;
input         reset_xgmii_tx_n;
endmodule
module sync_clk_wb( 
  status_crc_error, status_fragment_error, status_txdfifo_ovflow, 
  status_txdfifo_udflow, status_rxdfifo_ovflow, 
  status_rxdfifo_udflow, status_pause_frame_rx, status_local_fault, 
  status_remote_fault, 
  wb_clk_i, wb_rst_i, status_crc_error_tog, 
  status_fragment_error_tog, status_txdfifo_ovflow_tog, 
  status_txdfifo_udflow_tog, status_rxdfifo_ovflow_tog, 
  status_rxdfifo_udflow_tog, status_pause_frame_rx_tog, 
  status_local_fault_crx, status_remote_fault_crx
  );
input         wb_clk_i;
input         wb_rst_i;
input         status_crc_error_tog;	
input         status_fragment_error_tog;	
input         status_txdfifo_ovflow_tog;
input         status_txdfifo_udflow_tog;
input         status_rxdfifo_ovflow_tog;
input         status_rxdfifo_udflow_tog;
input         status_pause_frame_rx_tog;
input         status_local_fault_crx;
input         status_remote_fault_crx;
output        status_crc_error;
output        status_fragment_error;
output        status_txdfifo_ovflow;
output        status_txdfifo_udflow;
output        status_rxdfifo_ovflow;
output        status_rxdfifo_udflow;
output        status_pause_frame_rx;
output        status_local_fault;
output        status_remote_fault;
wire  [6:0]             sig_out1;
wire  [1:0]             sig_out2;
assign {status_crc_error,
        status_fragment_error,
        status_txdfifo_ovflow,
        status_txdfifo_udflow,
        status_rxdfifo_ovflow,
        status_rxdfifo_udflow,
        status_pause_frame_rx} = sig_out1;
assign {status_local_fault,
        status_remote_fault} = sig_out2;
meta_sync #(.DWIDTH (7), .EDGE_DETECT (1)) meta_sync0 (
                      .out              (sig_out1),
                      .clk              (wb_clk_i),
                      .reset_n          (~wb_rst_i),
                      .in               ({
                                          status_crc_error_tog,
                                          status_fragment_error_tog,
                                          status_txdfifo_ovflow_tog,
                                          status_txdfifo_udflow_tog,
                                          status_rxdfifo_ovflow_tog,
                                          status_rxdfifo_udflow_tog,
                                          status_pause_frame_rx_tog
                                         }));
meta_sync #(.DWIDTH (2), .EDGE_DETECT (0)) meta_sync1 (
                      .out              (sig_out2),
                      .clk              (wb_clk_i),
                      .reset_n          (~wb_rst_i),
                      .in               ({
                                          status_local_fault_crx,
                                          status_remote_fault_crx
                                         }));
endmodule
module sync_clk_xgmii_tx( 
  ctrl_tx_enable_ctx, status_local_fault_ctx, 
  status_remote_fault_ctx, 
  clk_xgmii_tx, reset_xgmii_tx_n, ctrl_tx_enable, 
  status_local_fault_crx, status_remote_fault_crx
  );
input         clk_xgmii_tx;
input         reset_xgmii_tx_n;
input         ctrl_tx_enable;
input         status_local_fault_crx;
input         status_remote_fault_crx;
output        ctrl_tx_enable_ctx;
output        status_local_fault_ctx;
output        status_remote_fault_ctx;
wire  [2:0]             sig_out;
assign {ctrl_tx_enable_ctx,
        status_local_fault_ctx,
        status_remote_fault_ctx} = sig_out;
meta_sync #(.DWIDTH (3)) meta_sync0 (
                      .out              (sig_out),
                      .clk              (clk_xgmii_tx),
                      .reset_n          (reset_xgmii_tx_n),
                      .in               ({
                                          ctrl_tx_enable,
                                          status_local_fault_crx,
                                          status_remote_fault_crx
                                         }));
endmodule
module tx_data_fifo( 
  txdfifo_wfull, txdfifo_walmost_full, txdfifo_rdata, 
  txdfifo_rstatus, txdfifo_rempty, txdfifo_ralmost_empty, 
  clk_xgmii_tx, clk_156m25, reset_xgmii_tx_n, reset_156m25_n, 
  txdfifo_wdata, txdfifo_wstatus, txdfifo_wen, txdfifo_ren
  );
input         clk_xgmii_tx;
input         clk_156m25;
input         reset_xgmii_tx_n;
input         reset_156m25_n;
input [63:0]  txdfifo_wdata;
input [7:0]   txdfifo_wstatus;
input         txdfifo_wen;
input         txdfifo_ren;
output        txdfifo_wfull;
output        txdfifo_walmost_full;
output [63:0] txdfifo_rdata;
output [7:0]  txdfifo_rstatus;
output        txdfifo_rempty;
output        txdfifo_ralmost_empty;
generic_fifo #(
  .DWIDTH (72),
  .AWIDTH (7),
  .REGISTER_READ (1),
  .EARLY_READ (1),
  .CLOCK_CROSSING (1),
  .ALMOST_EMPTY_THRESH (7),
  .ALMOST_FULL_THRESH (12),
  .MEM_TYPE (2)
)
fifo0(
    .wclk (clk_156m25),
    .wrst_n (reset_156m25_n),
    .wen (txdfifo_wen),
    .wdata ({txdfifo_wstatus, txdfifo_wdata}),
    .wfull (txdfifo_wfull),
    .walmost_full (txdfifo_walmost_full),
    .rclk (clk_xgmii_tx),
    .rrst_n (reset_xgmii_tx_n),
    .ren (txdfifo_ren),
    .rdata ({txdfifo_rstatus, txdfifo_rdata}),
    .rempty (txdfifo_rempty),
    .ralmost_empty (txdfifo_ralmost_empty)
);
endmodule
module tx_dequeue( 
  txdfifo_ren, txhfifo_ren, txhfifo_wdata, txhfifo_wstatus, 
  txhfifo_wen, xgmii_txd, xgmii_txc, status_txdfifo_udflow_tog, 
  clk_xgmii_tx, reset_xgmii_tx_n, ctrl_tx_enable_ctx, 
  status_local_fault_ctx, status_remote_fault_ctx, txdfifo_rdata, 
  txdfifo_rstatus, txdfifo_rempty, txdfifo_ralmost_empty, 
  txhfifo_rdata, txhfifo_rstatus, txhfifo_rempty, 
  txhfifo_ralmost_empty, txhfifo_wfull, txhfifo_walmost_full
  );
  function [31:0] nextCRC32_D64;
    input [63:0] Data;
    input [31:0] CRC;
    reg [63:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[63] ^ D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[54] ^ D[53] ^ 
                D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[37] ^ D[34] ^ 
                D[32] ^ D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[26] ^ D[25] ^ 
                D[24] ^ D[16] ^ D[12] ^ D[10] ^ D[9] ^ D[6] ^ D[0] ^ 
                C[0] ^ C[2] ^ C[5] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                C[18] ^ C[21] ^ C[22] ^ C[23] ^ C[26] ^ C[28] ^ C[29] ^ 
                C[31];
    NewCRC[1] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ 
                D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[28] ^ D[27] ^ D[24] ^ 
                D[17] ^ D[16] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[7] ^ 
                D[6] ^ D[1] ^ D[0] ^ C[1] ^ C[2] ^ C[3] ^ C[5] ^ C[6] ^ 
                C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ 
                C[24] ^ C[26] ^ C[27] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[2] = D[59] ^ D[58] ^ D[57] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[44] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[35] ^ D[32] ^ 
                D[31] ^ D[30] ^ D[26] ^ D[24] ^ D[18] ^ D[17] ^ D[16] ^ 
                D[14] ^ D[13] ^ D[9] ^ D[8] ^ D[7] ^ D[6] ^ D[2] ^ 
                D[1] ^ D[0] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[12] ^ C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[25] ^ C[26] ^ 
                C[27];
    NewCRC[3] = D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[54] ^ D[53] ^ D[52] ^ 
                D[45] ^ D[40] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[33] ^ 
                D[32] ^ D[31] ^ D[27] ^ D[25] ^ D[19] ^ D[18] ^ D[17] ^ 
                D[15] ^ D[14] ^ D[10] ^ D[9] ^ D[8] ^ D[7] ^ D[3] ^ 
                D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[8] ^ C[13] ^ C[20] ^ C[21] ^ C[22] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28];
    NewCRC[4] = D[63] ^ D[59] ^ D[58] ^ D[57] ^ D[50] ^ D[48] ^ D[47] ^ 
                D[46] ^ D[45] ^ D[44] ^ D[41] ^ D[40] ^ D[39] ^ D[38] ^ 
                D[33] ^ D[31] ^ D[30] ^ D[29] ^ D[25] ^ D[24] ^ D[20] ^ 
                D[19] ^ D[18] ^ D[15] ^ D[12] ^ D[11] ^ D[8] ^ D[6] ^ 
                D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[1] ^ C[6] ^ C[7] ^ C[8] ^ 
                C[9] ^ C[12] ^ C[13] ^ C[14] ^ C[15] ^ C[16] ^ C[18] ^ 
                C[25] ^ C[26] ^ C[27] ^ C[31];
    NewCRC[5] = D[63] ^ D[61] ^ D[59] ^ D[55] ^ D[54] ^ D[53] ^ D[51] ^ 
                D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[39] ^ D[37] ^ D[29] ^ D[28] ^ D[24] ^ D[21] ^ D[20] ^ 
                D[19] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[3] ^ D[1] ^ D[0] ^ C[5] ^ C[7] ^ C[8] ^ C[9] ^ C[10] ^ 
                C[12] ^ C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ C[22] ^ 
                C[23] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[6] = D[62] ^ D[60] ^ D[56] ^ D[55] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[38] ^ D[30] ^ D[29] ^ D[25] ^ D[22] ^ D[21] ^ D[20] ^ 
                D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[2] ^ D[1] ^ C[6] ^ C[8] ^ C[9] ^ C[10] ^ C[11] ^ 
                C[13] ^ C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[23] ^ 
                C[24] ^ C[28] ^ C[30];
    NewCRC[7] = D[60] ^ D[58] ^ D[57] ^ D[56] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ 
                D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[29] ^ D[28] ^ D[25] ^ 
                D[24] ^ D[23] ^ D[22] ^ D[21] ^ D[16] ^ D[15] ^ D[10] ^ 
                D[8] ^ D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[2] ^ 
                C[5] ^ C[7] ^ C[9] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[28];
    NewCRC[8] = D[63] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[40] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[31] ^ D[28] ^ 
                D[23] ^ D[22] ^ D[17] ^ D[12] ^ D[11] ^ D[10] ^ D[8] ^ 
                D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ 
                C[5] ^ C[6] ^ C[8] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ 
                C[31];
    NewCRC[9] = D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ D[39] ^ D[38] ^ 
                D[36] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[29] ^ D[24] ^ 
                D[23] ^ D[18] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[5] ^ 
                D[4] ^ D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ C[4] ^ 
                C[6] ^ C[7] ^ C[9] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ 
                C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[26] ^ C[28] ^ C[29];
    NewCRC[10] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[52] ^ D[50] ^ D[42] ^ D[40] ^ D[39] ^ D[36] ^ D[35] ^ 
                 D[33] ^ D[32] ^ D[31] ^ D[29] ^ D[28] ^ D[26] ^ D[19] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[9] ^ D[5] ^ D[3] ^ D[2] ^ 
                 D[0] ^ C[0] ^ C[1] ^ C[3] ^ C[4] ^ C[7] ^ C[8] ^ C[10] ^ 
                 C[18] ^ C[20] ^ C[23] ^ C[24] ^ C[26] ^ C[27] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[11] = D[59] ^ D[58] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[36] ^ D[33] ^ D[31] ^ D[28] ^ D[27] ^ D[26] ^ 
                 D[25] ^ D[24] ^ D[20] ^ D[17] ^ D[16] ^ D[15] ^ D[14] ^ 
                 D[12] ^ D[9] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[1] ^ C[4] ^ 
                 C[8] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                 C[18] ^ C[19] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[27];
    NewCRC[12] = D[63] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[42] ^ 
                 D[41] ^ D[31] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[18] ^ 
                 D[17] ^ D[15] ^ D[13] ^ D[12] ^ D[9] ^ D[6] ^ D[5] ^ 
                 D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[9] ^ C[10] ^ C[14] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ 
                 C[24] ^ C[25] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[13] = D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[42] ^ 
                 D[32] ^ D[31] ^ D[28] ^ D[25] ^ D[22] ^ D[19] ^ D[18] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ 
                 D[3] ^ D[2] ^ D[1] ^ C[0] ^ C[10] ^ C[11] ^ C[15] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[30];
    NewCRC[14] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[51] ^ D[49] ^ D[48] ^ D[44] ^ D[43] ^ 
                 D[33] ^ D[32] ^ D[29] ^ D[26] ^ D[23] ^ D[20] ^ D[19] ^ 
                 D[17] ^ D[15] ^ D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[2] ^ C[0] ^ C[1] ^ C[11] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[24] ^ C[26] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[15] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[50] ^ D[49] ^ D[45] ^ D[44] ^ D[34] ^ 
                 D[33] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[20] ^ D[18] ^ 
                 D[16] ^ D[15] ^ D[12] ^ D[9] ^ D[8] ^ D[7] ^ D[5] ^ 
                 D[4] ^ D[3] ^ C[1] ^ C[2] ^ C[12] ^ C[13] ^ C[17] ^ 
                 C[18] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[16] = D[57] ^ D[56] ^ D[51] ^ D[48] ^ D[47] ^ D[46] ^ D[44] ^ 
                 D[37] ^ D[35] ^ D[32] ^ D[30] ^ D[29] ^ D[26] ^ D[24] ^ 
                 D[22] ^ D[21] ^ D[19] ^ D[17] ^ D[13] ^ D[12] ^ D[8] ^ 
                 D[5] ^ D[4] ^ D[0] ^ C[0] ^ C[3] ^ C[5] ^ C[12] ^ C[14] ^ 
                 C[15] ^ C[16] ^ C[19] ^ C[24] ^ C[25];
    NewCRC[17] = D[58] ^ D[57] ^ D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[45] ^ 
                 D[38] ^ D[36] ^ D[33] ^ D[31] ^ D[30] ^ D[27] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[18] ^ D[14] ^ D[13] ^ D[9] ^ 
                 D[6] ^ D[5] ^ D[1] ^ C[1] ^ C[4] ^ C[6] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[17] ^ C[20] ^ C[25] ^ C[26];
    NewCRC[18] = D[59] ^ D[58] ^ D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[46] ^ 
                 D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[31] ^ D[28] ^ D[26] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[19] ^ D[15] ^ D[14] ^ D[10] ^ 
                 D[7] ^ D[6] ^ D[2] ^ C[0] ^ C[2] ^ C[5] ^ C[7] ^ C[14] ^ 
                 C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[26] ^ C[27];
    NewCRC[19] = D[60] ^ D[59] ^ D[54] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ 
                 D[40] ^ D[38] ^ D[35] ^ D[33] ^ D[32] ^ D[29] ^ D[27] ^ 
                 D[25] ^ D[24] ^ D[22] ^ D[20] ^ D[16] ^ D[15] ^ D[11] ^ 
                 D[8] ^ D[7] ^ D[3] ^ C[0] ^ C[1] ^ C[3] ^ C[6] ^ C[8] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[27] ^ C[28];
    NewCRC[20] = D[61] ^ D[60] ^ D[55] ^ D[52] ^ D[51] ^ D[50] ^ D[48] ^ 
                 D[41] ^ D[39] ^ D[36] ^ D[34] ^ D[33] ^ D[30] ^ D[28] ^ 
                 D[26] ^ D[25] ^ D[23] ^ D[21] ^ D[17] ^ D[16] ^ D[12] ^ 
                 D[9] ^ D[8] ^ D[4] ^ C[1] ^ C[2] ^ C[4] ^ C[7] ^ C[9] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[28] ^ C[29];
    NewCRC[21] = D[62] ^ D[61] ^ D[56] ^ D[53] ^ D[52] ^ D[51] ^ D[49] ^ 
                 D[42] ^ D[40] ^ D[37] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ 
                 D[27] ^ D[26] ^ D[24] ^ D[22] ^ D[18] ^ D[17] ^ D[13] ^ 
                 D[10] ^ D[9] ^ D[5] ^ C[2] ^ C[3] ^ C[5] ^ C[8] ^ C[10] ^ 
                 C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[29] ^ C[30];
    NewCRC[22] = D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ D[38] ^ 
                 D[37] ^ D[36] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ 
                 D[26] ^ D[24] ^ D[23] ^ D[19] ^ D[18] ^ D[16] ^ D[14] ^ 
                 D[12] ^ D[11] ^ D[9] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ 
                 C[5] ^ C[6] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ C[29] ^ 
                 C[30];
    NewCRC[23] = D[62] ^ D[60] ^ D[59] ^ D[56] ^ D[55] ^ D[54] ^ D[50] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[42] ^ D[39] ^ D[38] ^ D[36] ^ 
                 D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[20] ^ 
                 D[19] ^ D[17] ^ D[16] ^ D[15] ^ D[13] ^ D[9] ^ D[6] ^ 
                 D[1] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ C[6] ^ C[7] ^ C[10] ^ 
                 C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[22] ^ C[23] ^ C[24] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[24] = D[63] ^ D[61] ^ D[60] ^ D[57] ^ D[56] ^ D[55] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[40] ^ D[39] ^ D[37] ^ 
                 D[36] ^ D[35] ^ D[32] ^ D[30] ^ D[28] ^ D[27] ^ D[21] ^ 
                 D[20] ^ D[18] ^ D[17] ^ D[16] ^ D[14] ^ D[10] ^ D[7] ^ 
                 D[2] ^ D[1] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[7] ^ C[8] ^ 
                 C[11] ^ C[15] ^ C[16] ^ C[18] ^ C[19] ^ C[23] ^ C[24] ^ 
                 C[25] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[25] = D[62] ^ D[61] ^ D[58] ^ D[57] ^ D[56] ^ D[52] ^ D[51] ^ 
                 D[49] ^ D[48] ^ D[44] ^ D[41] ^ D[40] ^ D[38] ^ D[37] ^ 
                 D[36] ^ D[33] ^ D[31] ^ D[29] ^ D[28] ^ D[22] ^ D[21] ^ 
                 D[19] ^ D[18] ^ D[17] ^ D[15] ^ D[11] ^ D[8] ^ D[3] ^ 
                 D[2] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[8] ^ C[9] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[29] ^ C[30];
    NewCRC[26] = D[62] ^ D[61] ^ D[60] ^ D[59] ^ D[57] ^ D[55] ^ D[54] ^ 
                 D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[39] ^ D[38] ^ D[31] ^ D[28] ^ D[26] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[19] ^ D[18] ^ D[10] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[0] ^ C[6] ^ C[7] ^ C[9] ^ C[10] ^ C[12] ^ 
                 C[15] ^ C[16] ^ C[17] ^ C[20] ^ C[22] ^ C[23] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[27] = D[63] ^ D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[45] ^ D[43] ^ D[42] ^ 
                 D[40] ^ D[39] ^ D[32] ^ D[29] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[20] ^ D[19] ^ D[11] ^ D[7] ^ 
                 D[5] ^ D[4] ^ D[1] ^ C[0] ^ C[7] ^ C[8] ^ C[10] ^ C[11] ^ 
                 C[13] ^ C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[23] ^ C[24] ^ 
                 C[26] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[28] = D[63] ^ D[62] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ 
                 D[51] ^ D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[33] ^ D[30] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[22] ^ D[21] ^ D[20] ^ D[12] ^ D[8] ^ D[6] ^ 
                 D[5] ^ D[2] ^ C[1] ^ C[8] ^ C[9] ^ C[11] ^ C[12] ^ 
                 C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[29] = D[63] ^ D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[51] ^ D[50] ^ D[47] ^ D[45] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[34] ^ D[31] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[21] ^ D[13] ^ D[9] ^ D[7] ^ D[6] ^ 
                 D[3] ^ C[2] ^ C[9] ^ C[10] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[30] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ D[52] ^ 
                 D[51] ^ D[48] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[35] ^ 
                 D[32] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[14] ^ D[10] ^ D[8] ^ D[7] ^ D[4] ^ 
                 C[0] ^ C[3] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ C[16] ^ 
                 C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[26] ^ C[27] ^ C[29] ^ 
                 C[31];
    NewCRC[31] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[53] ^ D[52] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[36] ^ D[33] ^ 
                 D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[15] ^ D[11] ^ D[9] ^ D[8] ^ D[5] ^ C[1] ^ 
                 C[4] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[20] ^ 
                 C[21] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ C[30];
    nextCRC32_D64 = NewCRC;
  end
  endfunction
  function [31:0] nextCRC32_D8;
    input [7:0] Data;
    input [31:0] CRC;
    reg [7:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[6] ^ D[0] ^ C[24] ^ C[30];
    NewCRC[1] = D[7] ^ D[6] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ C[30] ^ 
                C[31];
    NewCRC[2] = D[7] ^ D[6] ^ D[2] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[30] ^ C[31];
    NewCRC[3] = D[7] ^ D[3] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ C[27] ^ 
                C[31];
    NewCRC[4] = D[6] ^ D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28] ^ C[30];
    NewCRC[5] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[24] ^ 
                C[25] ^ C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[6] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[7] = D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[29] ^ C[31];
    NewCRC[8] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[24] ^ C[25] ^ 
                C[27] ^ C[28];
    NewCRC[9] = D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29];
    NewCRC[10] = D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[2] ^ C[24] ^ C[26] ^ 
                 C[27] ^ C[29];
    NewCRC[11] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[3] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28];
    NewCRC[12] = D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[4] ^ C[24] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[13] = D[7] ^ D[6] ^ D[5] ^ D[3] ^ D[2] ^ D[1] ^ C[5] ^ C[25] ^ 
                 C[26] ^ C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[14] = D[7] ^ D[6] ^ D[4] ^ D[3] ^ D[2] ^ C[6] ^ C[26] ^ C[27] ^ 
                 C[28] ^ C[30] ^ C[31];
    NewCRC[15] = D[7] ^ D[5] ^ D[4] ^ D[3] ^ C[7] ^ C[27] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[16] = D[5] ^ D[4] ^ D[0] ^ C[8] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[17] = D[6] ^ D[5] ^ D[1] ^ C[9] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[18] = D[7] ^ D[6] ^ D[2] ^ C[10] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[19] = D[7] ^ D[3] ^ C[11] ^ C[27] ^ C[31];
    NewCRC[20] = D[4] ^ C[12] ^ C[28];
    NewCRC[21] = D[5] ^ C[13] ^ C[29];
    NewCRC[22] = D[0] ^ C[14] ^ C[24];
    NewCRC[23] = D[6] ^ D[1] ^ D[0] ^ C[15] ^ C[24] ^ C[25] ^ C[30];
    NewCRC[24] = D[7] ^ D[2] ^ D[1] ^ C[16] ^ C[25] ^ C[26] ^ C[31];
    NewCRC[25] = D[3] ^ D[2] ^ C[17] ^ C[26] ^ C[27];
    NewCRC[26] = D[6] ^ D[4] ^ D[3] ^ D[0] ^ C[18] ^ C[24] ^ C[27] ^ 
                 C[28] ^ C[30];
    NewCRC[27] = D[7] ^ D[5] ^ D[4] ^ D[1] ^ C[19] ^ C[25] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[28] = D[6] ^ D[5] ^ D[2] ^ C[20] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[29] = D[7] ^ D[6] ^ D[3] ^ C[21] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[30] = D[7] ^ D[4] ^ C[22] ^ C[28] ^ C[31];
    NewCRC[31] = D[5] ^ C[23] ^ C[29];
    nextCRC32_D8 = NewCRC;
  end
  endfunction
function [63:0] reverse_64b;
  input [63:0]   data;
  integer        i;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            reverse_64b[i] = data[63 - i];
        end
    end
endfunction
function [31:0] reverse_32b;
  input [31:0]   data;
  integer        i;
    begin
        for (i = 0; i < 32; i = i + 1) begin
            reverse_32b[i] = data[31 - i];
        end
    end
endfunction
function [7:0] reverse_8b;
  input [7:0]   data;
  integer        i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_8b[i] = data[7 - i];
        end
    end
endfunction
input         clk_xgmii_tx;
input         reset_xgmii_tx_n;
input         ctrl_tx_enable_ctx;
input         status_local_fault_ctx;
input         status_remote_fault_ctx;
input  [63:0] txdfifo_rdata;
input  [7:0]  txdfifo_rstatus;
input         txdfifo_rempty;
input         txdfifo_ralmost_empty;
input  [63:0] txhfifo_rdata;
input  [7:0]  txhfifo_rstatus;
input         txhfifo_rempty;
input         txhfifo_ralmost_empty;
input         txhfifo_wfull;
input         txhfifo_walmost_full;
output        txdfifo_ren;
output        txhfifo_ren;
output [63:0] txhfifo_wdata;
output [7:0]  txhfifo_wstatus;
output        txhfifo_wen;   
output [63:0] xgmii_txd;
output [7:0]  xgmii_txc;
output        status_txdfifo_udflow_tog;
reg                     status_txdfifo_udflow_tog;
reg                     txdfifo_ren;
reg                     txhfifo_ren;
reg [63:0]              txhfifo_wdata;
reg                     txhfifo_wen;
reg [7:0]               txhfifo_wstatus;
reg [7:0]               xgmii_txc;
reg [63:0]              xgmii_txd;
reg   [63:0]    xgxs_txd;
reg   [7:0]     xgxs_txc;
reg   [63:0]    next_xgxs_txd;
reg   [7:0]     next_xgxs_txc;
reg   [2:0]     curr_state;
reg   [2:0]     next_state;
reg   [0:0]     curr_state_rd;
reg   [0:0]     next_state_rd;
reg             start_on_lane0;
reg             next_start_on_lane0;
reg   [2:0]     ifg_deficit;
reg   [2:0]     next_ifg_deficit;
reg             ifg_4b_add;
reg             next_ifg_4b_add;
reg             ifg_8b_add;
reg             next_ifg_8b_add;
reg             ifg_8b2_add;
reg             next_ifg_8b2_add;
reg   [7:0]     eop;
reg   [7:0]     next_eop;
reg   [63:32]   xgxs_txd_barrel;
reg   [7:4]     xgxs_txc_barrel;
reg   [63:0]    txhfifo_rdata_d1;
reg   [13:0]    byte_cnt;
reg   [31:0]    crc32_d64;
reg   [31:0]    crc32_d8;
reg   [31:0]    crc32_tx;
reg   [63:0]    shift_crc_data;
reg   [3:0]     shift_crc_eop;
reg   [3:0]     shift_crc_cnt;
reg   [31:0]    crc_data;
reg             frame_available;
reg             next_frame_available;
reg   [63:0]    next_txhfifo_wdata;
reg   [7:0]     next_txhfifo_wstatus;
reg             next_txhfifo_wen;   
reg             txdfifo_ren_d1;
parameter [2:0]
             SM_IDLE      = 3'd0,
             SM_PREAMBLE  = 3'd1,
             SM_TX        = 3'd2,
             SM_EOP       = 3'd3,
             SM_TERM      = 3'd4,
             SM_TERM_FAIL = 3'd5,
             SM_IFG       = 3'd6;
parameter [0:0]
             SM_RD_EQ   = 1'd0,
             SM_RD_PAD  = 1'd1;
always @(posedge clk_xgmii_tx or negedge reset_xgmii_tx_n) begin
    if (reset_xgmii_tx_n == 1'b0) begin
        xgmii_txd <= {8{8'h07}};
        xgmii_txc <= 8'hff;
    end
    else begin
        if (status_local_fault_ctx) begin
            xgmii_txd <= {8'd2, 8'h0, 8'h0, 8'h9c,
                          8'd2, 8'h0, 8'h0, 8'h9c};
            xgmii_txc <= {4'b0001, 4'b0001};
        end
        else if (status_remote_fault_ctx) begin
            xgmii_txd <= {8{8'h07}};
            xgmii_txc <= 8'hff;
        end
        else begin
            xgmii_txd <= xgxs_txd;
            xgmii_txc <= xgxs_txc;
        end
    end
end
always @(posedge clk_xgmii_tx or negedge reset_xgmii_tx_n) begin
    if (reset_xgmii_tx_n == 1'b0) begin
        curr_state <= SM_IDLE;
        start_on_lane0 <= 1'b1;
        ifg_deficit <= 3'b0;
        ifg_4b_add <= 1'b0;
        ifg_8b_add <= 1'b0;
        ifg_8b2_add <= 1'b0;
        eop <= 8'b0;
        txhfifo_rdata_d1 <= 64'b0;
        xgxs_txd_barrel <= {4{8'h07}};
        xgxs_txc_barrel <= 4'hf;
        frame_available <= 1'b0;
        xgxs_txd <= {8{8'h07}};
        xgxs_txc <= 8'hff;
        status_txdfifo_udflow_tog <= 1'b0;
    end
    else begin
        curr_state <= next_state;
        start_on_lane0 <= next_start_on_lane0;
        ifg_deficit <= next_ifg_deficit;
        ifg_4b_add <= next_ifg_4b_add;
        ifg_8b_add <= next_ifg_8b_add;
        ifg_8b2_add <= next_ifg_8b2_add;
        eop <= next_eop;
        txhfifo_rdata_d1 <= txhfifo_rdata;
        xgxs_txd_barrel <= next_xgxs_txd[63:32];
        xgxs_txc_barrel <= next_xgxs_txc[7:4];
        frame_available <= next_frame_available;
        if (next_start_on_lane0) begin
            xgxs_txd <= next_xgxs_txd;
            xgxs_txc <= next_xgxs_txc;
        end
        else begin
            xgxs_txd <= {next_xgxs_txd[31:0], xgxs_txd_barrel};
            xgxs_txc <= {next_xgxs_txc[3:0], xgxs_txc_barrel};
        end
        if (txdfifo_ren && txdfifo_rempty) begin
            status_txdfifo_udflow_tog <= ~status_txdfifo_udflow_tog;
        end
    end
end
always @( crc32_tx or ctrl_tx_enable_ctx or curr_state or eop
         or frame_available or ifg_4b_add or ifg_8b2_add or ifg_8b_add
         or ifg_deficit or start_on_lane0 or status_local_fault_ctx
         or txhfifo_ralmost_empty or txhfifo_rdata_d1
         or txhfifo_rempty or txhfifo_rstatus) begin
    next_state = curr_state;
    next_start_on_lane0 = start_on_lane0;
    next_ifg_deficit = ifg_deficit;
    next_ifg_4b_add = ifg_4b_add;
    next_ifg_8b_add = ifg_8b_add;
    next_ifg_8b2_add = ifg_8b2_add;
    next_eop = eop;
    next_xgxs_txd = {8{8'h07}};
    next_xgxs_txc = 8'hff;
    txhfifo_ren = 1'b0;
    next_frame_available = frame_available;
    case (curr_state)
        SM_IDLE:
          begin
              if (ctrl_tx_enable_ctx && frame_available &&
                  !status_local_fault_ctx && !status_local_fault_ctx) begin
                  txhfifo_ren = 1'b1;
                  next_state = SM_PREAMBLE;
              end
              else begin
                  next_frame_available = !txhfifo_ralmost_empty;
                  next_ifg_4b_add = 1'b0;
              end
          end
        SM_PREAMBLE:
         begin
             if (txhfifo_rstatus[3'd7]) begin
                 next_xgxs_txd = {8'hd5, {6{8'h55}}, 8'hfb};
                 next_xgxs_txc = 8'h01;
                 txhfifo_ren = 1'b1;
                 next_state = SM_TX;
             end
             else begin
                 next_frame_available = 1'b0;
                 next_state = SM_IDLE;
             end
             if (ifg_4b_add) begin
                 next_start_on_lane0 = 1'b0;
             end
             else begin
                 next_start_on_lane0 = 1'b1;
             end
          end
        SM_TX:
          begin
              next_xgxs_txd = txhfifo_rdata_d1;
              next_xgxs_txc = 8'h00;
              txhfifo_ren = 1'b1;
              if (txhfifo_rstatus[3'd6]) begin
                  txhfifo_ren = 1'b0;
                  next_frame_available = !txhfifo_ralmost_empty;
                  next_state = SM_EOP;
              end
              else if (txhfifo_rempty || txhfifo_rstatus[3'd7]) begin
                  next_state = SM_TERM_FAIL;
              end
              next_eop[0] = txhfifo_rstatus[2:0] == 3'd1;
              next_eop[1] = txhfifo_rstatus[2:0] == 3'd2;
              next_eop[2] = txhfifo_rstatus[2:0] == 3'd3;
              next_eop[3] = txhfifo_rstatus[2:0] == 3'd4;
              next_eop[4] = txhfifo_rstatus[2:0] == 3'd5;
              next_eop[5] = txhfifo_rstatus[2:0] == 3'd6;
              next_eop[6] = txhfifo_rstatus[2:0] == 3'd7;
              next_eop[7] = txhfifo_rstatus[2:0] == 3'd0;
          end
        SM_EOP:
          begin
              if (eop[0]) begin
                  next_xgxs_txd = {{2{8'h07}}, 8'hfd, 
                                   crc32_tx[31:0], txhfifo_rdata_d1[7:0]};
                  next_xgxs_txc = 8'b11100000;
              end
              if (eop[1]) begin
                  next_xgxs_txd = {8'h07, 8'hfd,
                                   crc32_tx[31:0], txhfifo_rdata_d1[15:0]};
                  next_xgxs_txc = 8'b11000000;
              end
              if (eop[2]) begin
                  next_xgxs_txd = {8'hfd, crc32_tx[31:0], txhfifo_rdata_d1[23:0]};
                  next_xgxs_txc = 8'b10000000;
              end
              if (eop[3]) begin
                  next_xgxs_txd = {crc32_tx[31:0], txhfifo_rdata_d1[31:0]};
                  next_xgxs_txc = 8'b00000000;
              end
              if (eop[4]) begin
                  next_xgxs_txd = {crc32_tx[23:0], txhfifo_rdata_d1[39:0]};
                  next_xgxs_txc = 8'b00000000;
              end
              if (eop[5]) begin
                  next_xgxs_txd = {crc32_tx[15:0], txhfifo_rdata_d1[47:0]};
                  next_xgxs_txc = 8'b00000000;
              end
              if (eop[6]) begin
                  next_xgxs_txd = {crc32_tx[7:0], txhfifo_rdata_d1[55:0]};
                  next_xgxs_txc = 8'b00000000;
              end
              if (eop[7]) begin
                  next_xgxs_txd = {txhfifo_rdata_d1[63:0]};
                  next_xgxs_txc = 8'b00000000;
              end
              if (!frame_available) begin
                  next_ifg_deficit = 3'b0;
              end
              else begin
                  next_ifg_deficit = ifg_deficit +
                                     {2'b0, eop[0] | eop[4]} +
                                     {1'b0, eop[1] | eop[5], 1'b0} +
                                     {1'b0, eop[2] | eop[6],
                                      eop[2] | eop[6]};
              end
              if (!frame_available) begin
                  next_ifg_4b_add = 1'b0;
                  next_ifg_8b_add = 1'b0;
                  next_ifg_8b2_add = 1'b0;
              end
              else if (next_ifg_deficit[2] == ifg_deficit[2]) begin
                  next_ifg_4b_add = (eop[0] & !start_on_lane0) |
                                    (eop[1] & !start_on_lane0) |
                                    (eop[2] & !start_on_lane0) |
                                    (eop[3] & start_on_lane0) |
                                    (eop[4] & start_on_lane0) |
                                    (eop[5] & start_on_lane0) |
                                    (eop[6] & start_on_lane0) |
                                    (eop[7] & !start_on_lane0);
                  next_ifg_8b_add = (eop[0]) |
                                    (eop[1]) |
                                    (eop[2]) |
                                    (eop[3] & !start_on_lane0) |
                                    (eop[4] & !start_on_lane0) |
                                    (eop[5] & !start_on_lane0) |
                                    (eop[6] & !start_on_lane0) |
                                    (eop[7]);
                  next_ifg_8b2_add = 1'b0;
              end
              else begin
                  next_ifg_4b_add = (eop[0] & start_on_lane0) |
                                    (eop[1] & start_on_lane0) |
                                    (eop[2] & start_on_lane0) |
                                    (eop[3] &  start_on_lane0) |
                                    (eop[4] & !start_on_lane0) |
                                    (eop[5] & !start_on_lane0) |
                                    (eop[6] & !start_on_lane0) |
                                    (eop[7] & !start_on_lane0);
                  next_ifg_8b_add = (eop[0]) |
                                    (eop[1]) |
                                    (eop[2]) |
                                    (eop[3] & !start_on_lane0) |
                                    (eop[4]) |
                                    (eop[5]) |
                                    (eop[6]) |
                                    (eop[7]);
                  next_ifg_8b2_add = (eop[0] & !start_on_lane0) |
                                     (eop[1] & !start_on_lane0) |
                                     (eop[2] & !start_on_lane0);
              end
              if (|eop[2:0]) begin
                  if (frame_available) begin
                      if (next_ifg_8b2_add) begin
                          next_state = SM_IFG;
                      end
                      else if (next_ifg_8b_add) begin
                          next_state = SM_IDLE;
                      end
                      else begin
                          txhfifo_ren = 1'b1;
                          next_state = SM_PREAMBLE;
                      end
                  end
                  else begin
                      next_state = SM_IFG;
                  end
              end
              if (|eop[7:3]) begin
                  next_state = SM_TERM;
              end
          end
        SM_TERM:
          begin
              if (eop[3]) begin
                  next_xgxs_txd = {{7{8'h07}}, 8'hfd};
                  next_xgxs_txc = 8'b11111111;
              end
              if (eop[4]) begin
                  next_xgxs_txd = {{6{8'h07}}, 8'hfd, crc32_tx[31:24]};
                  next_xgxs_txc = 8'b11111110;
              end
              if (eop[5]) begin
                  next_xgxs_txd = {{5{8'h07}}, 8'hfd, crc32_tx[31:16]};
                  next_xgxs_txc = 8'b11111100;
              end
              if (eop[6]) begin
                  next_xgxs_txd = {{4{8'h07}}, 8'hfd, crc32_tx[31:8]};
                  next_xgxs_txc = 8'b11111000;
              end
              if (eop[7]) begin
                  next_xgxs_txd = {{3{8'h07}}, 8'hfd, crc32_tx[31:0]};
                  next_xgxs_txc = 8'b11110000;
              end
              if (frame_available && !ifg_8b_add) begin
                  txhfifo_ren = 1'b1;
                  next_state = SM_PREAMBLE;
              end
              else if (frame_available) begin
                  next_state = SM_IDLE;
              end
              else begin
                  next_state = SM_IFG;
              end
          end
        SM_TERM_FAIL:
          begin
              next_xgxs_txd = {{7{8'h07}}, 8'hfd};
              next_xgxs_txc = 8'b11111111;
              next_state = SM_IFG;
          end
        SM_IFG:
          begin
              next_state = SM_IDLE;
          end
        default:
          begin
              next_state = SM_IDLE;
          end
    endcase
end
always @( crc32_d64 or txhfifo_wen or txhfifo_wstatus) begin
    if (txhfifo_wen && txhfifo_wstatus[3'd7]) begin
        crc_data = 32'hffffffff;
    end
    else begin
        crc_data = crc32_d64;
    end
end
always @( byte_cnt or curr_state_rd or txdfifo_rdata
         or txdfifo_rempty or txdfifo_ren_d1 or txdfifo_rstatus
         or txhfifo_walmost_full) begin
    next_state_rd = curr_state_rd;
    next_txhfifo_wdata = txdfifo_rdata;
    next_txhfifo_wstatus = txdfifo_rstatus;
    txdfifo_ren = 1'b0;
    next_txhfifo_wen = 1'b0;
    case (curr_state_rd)
      SM_RD_EQ: begin
          if (!txhfifo_walmost_full) begin
              txdfifo_ren = !txdfifo_rempty;
          end
          if (txdfifo_ren_d1) begin
              next_txhfifo_wen = 1'b1;
              if (txdfifo_rstatus[3'd6]) begin
                  if (byte_cnt < 14'd56) begin
                      next_txhfifo_wstatus = 8'h0;
                      txdfifo_ren = 1'b0;
                      next_state_rd = SM_RD_PAD;
                  end
                  else if (byte_cnt == 14'd56 &&
                           (txdfifo_rstatus[2:0] == 3'd1 ||
                            txdfifo_rstatus[2:0] == 3'd2 ||
                            txdfifo_rstatus[2:0] == 3'd3)) begin
                      next_txhfifo_wstatus[2:0] = 3'd4;
                      if (txdfifo_rstatus[2:0] == 3'd1)
                        next_txhfifo_wdata[31:8] = 24'b0;
                      if (txdfifo_rstatus[2:0] == 3'd2)
                        next_txhfifo_wdata[31:16] = 16'b0;
                      if (txdfifo_rstatus[2:0] == 3'd3)
                        next_txhfifo_wdata[31:24] = 8'b0;
                      txdfifo_ren = 1'b0;
                  end
                  else begin
                      txdfifo_ren = 1'b0;
                  end
              end
          end
      end
      SM_RD_PAD: begin
          if (!txhfifo_walmost_full) begin
              next_txhfifo_wdata = 64'b0;
              next_txhfifo_wstatus = 8'h0;
              next_txhfifo_wen = 1'b1;
              if (byte_cnt == 14'd56) begin
                  next_txhfifo_wstatus[3'd6] = 1'b1;
                  next_txhfifo_wstatus[2:0] = 3'd4;
                  next_state_rd = SM_RD_EQ;
              end
          end
      end
      default:
        begin
            next_state_rd = SM_RD_EQ;
        end
    endcase
end
always @(posedge clk_xgmii_tx or negedge reset_xgmii_tx_n) begin
    if (reset_xgmii_tx_n == 1'b0) begin
        curr_state_rd <= SM_RD_EQ;
        txdfifo_ren_d1 <= 1'b0;
        txhfifo_wdata <= 64'b0;
        txhfifo_wstatus <= 8'b0;
        txhfifo_wen <= 1'b0;   
        byte_cnt <= 14'b0;
        shift_crc_data <= 64'b0;
        shift_crc_eop <= 4'b0;
        shift_crc_cnt <= 4'b0;
    end
    else begin
        curr_state_rd <= next_state_rd;
        txdfifo_ren_d1 <= txdfifo_ren;
        txhfifo_wdata <= next_txhfifo_wdata;
        txhfifo_wstatus <= next_txhfifo_wstatus;
        txhfifo_wen <= next_txhfifo_wen;
        if (next_txhfifo_wen) begin
            if (next_txhfifo_wstatus[3'd7]) begin
                byte_cnt <= 14'd8;
            end
            else begin
                byte_cnt <= byte_cnt + 14'd8;
            end
        end
        if (txhfifo_wen) begin
            crc32_d64 <= nextCRC32_D64(reverse_64b(txhfifo_wdata), crc_data);
        end
        if (txhfifo_wen && txhfifo_wstatus[3'd6]) begin
            crc32_d8 <= crc32_d64;
            shift_crc_data <= txhfifo_wdata;
            shift_crc_cnt <= 4'd9;
            if (txhfifo_wstatus[2:0] == 3'b0) begin
              shift_crc_eop <= 4'd8;
            end
            else begin
                shift_crc_eop <= {1'b0, txhfifo_wstatus[2:0]};
            end
        end
        else if (shift_crc_eop != 4'b0) begin
            crc32_d8 <= nextCRC32_D8(reverse_8b(shift_crc_data[7:0]), crc32_d8);
            shift_crc_data <= {8'b0, shift_crc_data[63:8]};
            shift_crc_eop <= shift_crc_eop - 4'd1;
        end
        if (shift_crc_cnt == 4'b1) begin
            crc32_tx <= ~reverse_32b(crc32_d8);
        end
        else begin
            shift_crc_cnt <= shift_crc_cnt - 4'd1;
        end
    end
end
endmodule
module tx_enqueue( 
  pkt_tx_full, txdfifo_wdata, txdfifo_wstatus, txdfifo_wen, 
  status_txdfifo_ovflow_tog, 
  clk_156m25, reset_156m25_n, pkt_tx_data, pkt_tx_val, pkt_tx_sop, 
  pkt_tx_eop, pkt_tx_mod, txdfifo_wfull, txdfifo_walmost_full
  );
  function [31:0] nextCRC32_D64;
    input [63:0] Data;
    input [31:0] CRC;
    reg [63:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[63] ^ D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[54] ^ D[53] ^ 
                D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[37] ^ D[34] ^ 
                D[32] ^ D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[26] ^ D[25] ^ 
                D[24] ^ D[16] ^ D[12] ^ D[10] ^ D[9] ^ D[6] ^ D[0] ^ 
                C[0] ^ C[2] ^ C[5] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                C[18] ^ C[21] ^ C[22] ^ C[23] ^ C[26] ^ C[28] ^ C[29] ^ 
                C[31];
    NewCRC[1] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ 
                D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[28] ^ D[27] ^ D[24] ^ 
                D[17] ^ D[16] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[7] ^ 
                D[6] ^ D[1] ^ D[0] ^ C[1] ^ C[2] ^ C[3] ^ C[5] ^ C[6] ^ 
                C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ 
                C[24] ^ C[26] ^ C[27] ^ C[28] ^ C[30] ^ C[31];
    NewCRC[2] = D[59] ^ D[58] ^ D[57] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[44] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[35] ^ D[32] ^ 
                D[31] ^ D[30] ^ D[26] ^ D[24] ^ D[18] ^ D[17] ^ D[16] ^ 
                D[14] ^ D[13] ^ D[9] ^ D[8] ^ D[7] ^ D[6] ^ D[2] ^ 
                D[1] ^ D[0] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[12] ^ C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[25] ^ C[26] ^ 
                C[27];
    NewCRC[3] = D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[54] ^ D[53] ^ D[52] ^ 
                D[45] ^ D[40] ^ D[39] ^ D[38] ^ D[37] ^ D[36] ^ D[33] ^ 
                D[32] ^ D[31] ^ D[27] ^ D[25] ^ D[19] ^ D[18] ^ D[17] ^ 
                D[15] ^ D[14] ^ D[10] ^ D[9] ^ D[8] ^ D[7] ^ D[3] ^ 
                D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[7] ^ 
                C[8] ^ C[13] ^ C[20] ^ C[21] ^ C[22] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28];
    NewCRC[4] = D[63] ^ D[59] ^ D[58] ^ D[57] ^ D[50] ^ D[48] ^ D[47] ^ 
                D[46] ^ D[45] ^ D[44] ^ D[41] ^ D[40] ^ D[39] ^ D[38] ^ 
                D[33] ^ D[31] ^ D[30] ^ D[29] ^ D[25] ^ D[24] ^ D[20] ^ 
                D[19] ^ D[18] ^ D[15] ^ D[12] ^ D[11] ^ D[8] ^ D[6] ^ 
                D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[1] ^ C[6] ^ C[7] ^ C[8] ^ 
                C[9] ^ C[12] ^ C[13] ^ C[14] ^ C[15] ^ C[16] ^ C[18] ^ 
                C[25] ^ C[26] ^ C[27] ^ C[31];
    NewCRC[5] = D[63] ^ D[61] ^ D[59] ^ D[55] ^ D[54] ^ D[53] ^ D[51] ^ 
                D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[39] ^ D[37] ^ D[29] ^ D[28] ^ D[24] ^ D[21] ^ D[20] ^ 
                D[19] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[3] ^ D[1] ^ D[0] ^ C[5] ^ C[7] ^ C[8] ^ C[9] ^ C[10] ^ 
                C[12] ^ C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[21] ^ C[22] ^ 
                C[23] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[6] = D[62] ^ D[60] ^ D[56] ^ D[55] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ D[40] ^ 
                D[38] ^ D[30] ^ D[29] ^ D[25] ^ D[22] ^ D[21] ^ D[20] ^ 
                D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ D[5] ^ D[4] ^ 
                D[2] ^ D[1] ^ C[6] ^ C[8] ^ C[9] ^ C[10] ^ C[11] ^ 
                C[13] ^ C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[23] ^ 
                C[24] ^ C[28] ^ C[30];
    NewCRC[7] = D[60] ^ D[58] ^ D[57] ^ D[56] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[47] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[41] ^ 
                D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[29] ^ D[28] ^ D[25] ^ 
                D[24] ^ D[23] ^ D[22] ^ D[21] ^ D[16] ^ D[15] ^ D[10] ^ 
                D[8] ^ D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[0] ^ C[2] ^ 
                C[5] ^ C[7] ^ C[9] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[15] ^ C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[28];
    NewCRC[8] = D[63] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[52] ^ D[51] ^ 
                D[50] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[40] ^ D[38] ^ 
                D[37] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[31] ^ D[28] ^ 
                D[23] ^ D[22] ^ D[17] ^ D[12] ^ D[11] ^ D[10] ^ D[8] ^ 
                D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ 
                C[5] ^ C[6] ^ C[8] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ 
                C[18] ^ C[19] ^ C[20] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ 
                C[31];
    NewCRC[9] = D[61] ^ D[60] ^ D[58] ^ D[55] ^ D[53] ^ D[52] ^ D[51] ^ 
                D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ D[39] ^ D[38] ^ 
                D[36] ^ D[35] ^ D[34] ^ D[33] ^ D[32] ^ D[29] ^ D[24] ^ 
                D[23] ^ D[18] ^ D[13] ^ D[12] ^ D[11] ^ D[9] ^ D[5] ^ 
                D[4] ^ D[2] ^ D[1] ^ C[0] ^ C[1] ^ C[2] ^ C[3] ^ C[4] ^ 
                C[6] ^ C[7] ^ C[9] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ 
                C[19] ^ C[20] ^ C[21] ^ C[23] ^ C[26] ^ C[28] ^ C[29];
    NewCRC[10] = D[63] ^ D[62] ^ D[60] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[52] ^ D[50] ^ D[42] ^ D[40] ^ D[39] ^ D[36] ^ D[35] ^ 
                 D[33] ^ D[32] ^ D[31] ^ D[29] ^ D[28] ^ D[26] ^ D[19] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[9] ^ D[5] ^ D[3] ^ D[2] ^ 
                 D[0] ^ C[0] ^ C[1] ^ C[3] ^ C[4] ^ C[7] ^ C[8] ^ C[10] ^ 
                 C[18] ^ C[20] ^ C[23] ^ C[24] ^ C[26] ^ C[27] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[11] = D[59] ^ D[58] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[36] ^ D[33] ^ D[31] ^ D[28] ^ D[27] ^ D[26] ^ 
                 D[25] ^ D[24] ^ D[20] ^ D[17] ^ D[16] ^ D[15] ^ D[14] ^ 
                 D[12] ^ D[9] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[1] ^ C[4] ^ 
                 C[8] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ C[16] ^ 
                 C[18] ^ C[19] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[27];
    NewCRC[12] = D[63] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ D[46] ^ D[42] ^ 
                 D[41] ^ D[31] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[18] ^ 
                 D[17] ^ D[15] ^ D[13] ^ D[12] ^ D[9] ^ D[6] ^ D[5] ^ 
                 D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[9] ^ C[10] ^ C[14] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ 
                 C[24] ^ C[25] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[13] = D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[54] ^ D[53] ^ 
                 D[52] ^ D[51] ^ D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[42] ^ 
                 D[32] ^ D[31] ^ D[28] ^ D[25] ^ D[22] ^ D[19] ^ D[18] ^ 
                 D[16] ^ D[14] ^ D[13] ^ D[10] ^ D[7] ^ D[6] ^ D[5] ^ 
                 D[3] ^ D[2] ^ D[1] ^ C[0] ^ C[10] ^ C[11] ^ C[15] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[30];
    NewCRC[14] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[51] ^ D[49] ^ D[48] ^ D[44] ^ D[43] ^ 
                 D[33] ^ D[32] ^ D[29] ^ D[26] ^ D[23] ^ D[20] ^ D[19] ^ 
                 D[17] ^ D[15] ^ D[14] ^ D[11] ^ D[8] ^ D[7] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[2] ^ C[0] ^ C[1] ^ C[11] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ 
                 C[24] ^ C[26] ^ C[27] ^ C[29] ^ C[31];
    NewCRC[15] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[56] ^ D[55] ^ D[54] ^ 
                 D[53] ^ D[52] ^ D[50] ^ D[49] ^ D[45] ^ D[44] ^ D[34] ^ 
                 D[33] ^ D[30] ^ D[27] ^ D[24] ^ D[21] ^ D[20] ^ D[18] ^ 
                 D[16] ^ D[15] ^ D[12] ^ D[9] ^ D[8] ^ D[7] ^ D[5] ^ 
                 D[4] ^ D[3] ^ C[1] ^ C[2] ^ C[12] ^ C[13] ^ C[17] ^ 
                 C[18] ^ C[20] ^ C[21] ^ C[22] ^ C[23] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[16] = D[57] ^ D[56] ^ D[51] ^ D[48] ^ D[47] ^ D[46] ^ D[44] ^ 
                 D[37] ^ D[35] ^ D[32] ^ D[30] ^ D[29] ^ D[26] ^ D[24] ^ 
                 D[22] ^ D[21] ^ D[19] ^ D[17] ^ D[13] ^ D[12] ^ D[8] ^ 
                 D[5] ^ D[4] ^ D[0] ^ C[0] ^ C[3] ^ C[5] ^ C[12] ^ C[14] ^ 
                 C[15] ^ C[16] ^ C[19] ^ C[24] ^ C[25];
    NewCRC[17] = D[58] ^ D[57] ^ D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[45] ^ 
                 D[38] ^ D[36] ^ D[33] ^ D[31] ^ D[30] ^ D[27] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[18] ^ D[14] ^ D[13] ^ D[9] ^ 
                 D[6] ^ D[5] ^ D[1] ^ C[1] ^ C[4] ^ C[6] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[17] ^ C[20] ^ C[25] ^ C[26];
    NewCRC[18] = D[59] ^ D[58] ^ D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[46] ^ 
                 D[39] ^ D[37] ^ D[34] ^ D[32] ^ D[31] ^ D[28] ^ D[26] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[19] ^ D[15] ^ D[14] ^ D[10] ^ 
                 D[7] ^ D[6] ^ D[2] ^ C[0] ^ C[2] ^ C[5] ^ C[7] ^ C[14] ^ 
                 C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[26] ^ C[27];
    NewCRC[19] = D[60] ^ D[59] ^ D[54] ^ D[51] ^ D[50] ^ D[49] ^ D[47] ^ 
                 D[40] ^ D[38] ^ D[35] ^ D[33] ^ D[32] ^ D[29] ^ D[27] ^ 
                 D[25] ^ D[24] ^ D[22] ^ D[20] ^ D[16] ^ D[15] ^ D[11] ^ 
                 D[8] ^ D[7] ^ D[3] ^ C[0] ^ C[1] ^ C[3] ^ C[6] ^ C[8] ^ 
                 C[15] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[27] ^ C[28];
    NewCRC[20] = D[61] ^ D[60] ^ D[55] ^ D[52] ^ D[51] ^ D[50] ^ D[48] ^ 
                 D[41] ^ D[39] ^ D[36] ^ D[34] ^ D[33] ^ D[30] ^ D[28] ^ 
                 D[26] ^ D[25] ^ D[23] ^ D[21] ^ D[17] ^ D[16] ^ D[12] ^ 
                 D[9] ^ D[8] ^ D[4] ^ C[1] ^ C[2] ^ C[4] ^ C[7] ^ C[9] ^ 
                 C[16] ^ C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[28] ^ C[29];
    NewCRC[21] = D[62] ^ D[61] ^ D[56] ^ D[53] ^ D[52] ^ D[51] ^ D[49] ^ 
                 D[42] ^ D[40] ^ D[37] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ 
                 D[27] ^ D[26] ^ D[24] ^ D[22] ^ D[18] ^ D[17] ^ D[13] ^ 
                 D[10] ^ D[9] ^ D[5] ^ C[2] ^ C[3] ^ C[5] ^ C[8] ^ C[10] ^ 
                 C[17] ^ C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[29] ^ C[30];
    NewCRC[22] = D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[48] ^ D[47] ^ D[45] ^ D[44] ^ D[43] ^ D[41] ^ D[38] ^ 
                 D[37] ^ D[36] ^ D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ 
                 D[26] ^ D[24] ^ D[23] ^ D[19] ^ D[18] ^ D[16] ^ D[14] ^ 
                 D[12] ^ D[11] ^ D[9] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ 
                 C[5] ^ C[6] ^ C[9] ^ C[11] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[16] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ C[29] ^ 
                 C[30];
    NewCRC[23] = D[62] ^ D[60] ^ D[59] ^ D[56] ^ D[55] ^ D[54] ^ D[50] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[42] ^ D[39] ^ D[38] ^ D[36] ^ 
                 D[35] ^ D[34] ^ D[31] ^ D[29] ^ D[27] ^ D[26] ^ D[20] ^ 
                 D[19] ^ D[17] ^ D[16] ^ D[15] ^ D[13] ^ D[9] ^ D[6] ^ 
                 D[1] ^ D[0] ^ C[2] ^ C[3] ^ C[4] ^ C[6] ^ C[7] ^ C[10] ^ 
                 C[14] ^ C[15] ^ C[17] ^ C[18] ^ C[22] ^ C[23] ^ C[24] ^ 
                 C[27] ^ C[28] ^ C[30];
    NewCRC[24] = D[63] ^ D[61] ^ D[60] ^ D[57] ^ D[56] ^ D[55] ^ D[51] ^ 
                 D[50] ^ D[48] ^ D[47] ^ D[43] ^ D[40] ^ D[39] ^ D[37] ^ 
                 D[36] ^ D[35] ^ D[32] ^ D[30] ^ D[28] ^ D[27] ^ D[21] ^ 
                 D[20] ^ D[18] ^ D[17] ^ D[16] ^ D[14] ^ D[10] ^ D[7] ^ 
                 D[2] ^ D[1] ^ C[0] ^ C[3] ^ C[4] ^ C[5] ^ C[7] ^ C[8] ^ 
                 C[11] ^ C[15] ^ C[16] ^ C[18] ^ C[19] ^ C[23] ^ C[24] ^ 
                 C[25] ^ C[28] ^ C[29] ^ C[31];
    NewCRC[25] = D[62] ^ D[61] ^ D[58] ^ D[57] ^ D[56] ^ D[52] ^ D[51] ^ 
                 D[49] ^ D[48] ^ D[44] ^ D[41] ^ D[40] ^ D[38] ^ D[37] ^ 
                 D[36] ^ D[33] ^ D[31] ^ D[29] ^ D[28] ^ D[22] ^ D[21] ^ 
                 D[19] ^ D[18] ^ D[17] ^ D[15] ^ D[11] ^ D[8] ^ D[3] ^ 
                 D[2] ^ C[1] ^ C[4] ^ C[5] ^ C[6] ^ C[8] ^ C[9] ^ C[12] ^ 
                 C[16] ^ C[17] ^ C[19] ^ C[20] ^ C[24] ^ C[25] ^ C[26] ^ 
                 C[29] ^ C[30];
    NewCRC[26] = D[62] ^ D[61] ^ D[60] ^ D[59] ^ D[57] ^ D[55] ^ D[54] ^ 
                 D[52] ^ D[49] ^ D[48] ^ D[47] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[39] ^ D[38] ^ D[31] ^ D[28] ^ D[26] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[20] ^ D[19] ^ D[18] ^ D[10] ^ D[6] ^ 
                 D[4] ^ D[3] ^ D[0] ^ C[6] ^ C[7] ^ C[9] ^ C[10] ^ C[12] ^ 
                 C[15] ^ C[16] ^ C[17] ^ C[20] ^ C[22] ^ C[23] ^ C[25] ^ 
                 C[27] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[27] = D[63] ^ D[62] ^ D[61] ^ D[60] ^ D[58] ^ D[56] ^ D[55] ^ 
                 D[53] ^ D[50] ^ D[49] ^ D[48] ^ D[45] ^ D[43] ^ D[42] ^ 
                 D[40] ^ D[39] ^ D[32] ^ D[29] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[23] ^ D[21] ^ D[20] ^ D[19] ^ D[11] ^ D[7] ^ 
                 D[5] ^ D[4] ^ D[1] ^ C[0] ^ C[7] ^ C[8] ^ C[10] ^ C[11] ^ 
                 C[13] ^ C[16] ^ C[17] ^ C[18] ^ C[21] ^ C[23] ^ C[24] ^ 
                 C[26] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[28] = D[63] ^ D[62] ^ D[61] ^ D[59] ^ D[57] ^ D[56] ^ D[54] ^ 
                 D[51] ^ D[50] ^ D[49] ^ D[46] ^ D[44] ^ D[43] ^ D[41] ^ 
                 D[40] ^ D[33] ^ D[30] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[24] ^ D[22] ^ D[21] ^ D[20] ^ D[12] ^ D[8] ^ D[6] ^ 
                 D[5] ^ D[2] ^ C[1] ^ C[8] ^ C[9] ^ C[11] ^ C[12] ^ 
                 C[14] ^ C[17] ^ C[18] ^ C[19] ^ C[22] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[29] = D[63] ^ D[62] ^ D[60] ^ D[58] ^ D[57] ^ D[55] ^ D[52] ^ 
                 D[51] ^ D[50] ^ D[47] ^ D[45] ^ D[44] ^ D[42] ^ D[41] ^ 
                 D[34] ^ D[31] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[25] ^ 
                 D[23] ^ D[22] ^ D[21] ^ D[13] ^ D[9] ^ D[7] ^ D[6] ^ 
                 D[3] ^ C[2] ^ C[9] ^ C[10] ^ C[12] ^ C[13] ^ C[15] ^ 
                 C[18] ^ C[19] ^ C[20] ^ C[23] ^ C[25] ^ C[26] ^ C[28] ^ 
                 C[30] ^ C[31];
    NewCRC[30] = D[63] ^ D[61] ^ D[59] ^ D[58] ^ D[56] ^ D[53] ^ D[52] ^ 
                 D[51] ^ D[48] ^ D[46] ^ D[45] ^ D[43] ^ D[42] ^ D[35] ^ 
                 D[32] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[26] ^ D[24] ^ 
                 D[23] ^ D[22] ^ D[14] ^ D[10] ^ D[8] ^ D[7] ^ D[4] ^ 
                 C[0] ^ C[3] ^ C[10] ^ C[11] ^ C[13] ^ C[14] ^ C[16] ^ 
                 C[19] ^ C[20] ^ C[21] ^ C[24] ^ C[26] ^ C[27] ^ C[29] ^ 
                 C[31];
    NewCRC[31] = D[62] ^ D[60] ^ D[59] ^ D[57] ^ D[54] ^ D[53] ^ D[52] ^ 
                 D[49] ^ D[47] ^ D[46] ^ D[44] ^ D[43] ^ D[36] ^ D[33] ^ 
                 D[31] ^ D[30] ^ D[29] ^ D[28] ^ D[27] ^ D[25] ^ D[24] ^ 
                 D[23] ^ D[15] ^ D[11] ^ D[9] ^ D[8] ^ D[5] ^ C[1] ^ 
                 C[4] ^ C[11] ^ C[12] ^ C[14] ^ C[15] ^ C[17] ^ C[20] ^ 
                 C[21] ^ C[22] ^ C[25] ^ C[27] ^ C[28] ^ C[30];
    nextCRC32_D64 = NewCRC;
  end
  endfunction
  function [31:0] nextCRC32_D8;
    input [7:0] Data;
    input [31:0] CRC;
    reg [7:0] D;
    reg [31:0] C;
    reg [31:0] NewCRC;
  begin
    D = Data;
    C = CRC;
    NewCRC[0] = D[6] ^ D[0] ^ C[24] ^ C[30];
    NewCRC[1] = D[7] ^ D[6] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ C[30] ^ 
                C[31];
    NewCRC[2] = D[7] ^ D[6] ^ D[2] ^ D[1] ^ D[0] ^ C[24] ^ C[25] ^ 
                C[26] ^ C[30] ^ C[31];
    NewCRC[3] = D[7] ^ D[3] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ C[27] ^ 
                C[31];
    NewCRC[4] = D[6] ^ D[4] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[28] ^ C[30];
    NewCRC[5] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[24] ^ 
                C[25] ^ C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[6] = D[7] ^ D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[7] = D[7] ^ D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[24] ^ C[26] ^ 
                C[27] ^ C[29] ^ C[31];
    NewCRC[8] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[0] ^ C[24] ^ C[25] ^ 
                C[27] ^ C[28];
    NewCRC[9] = D[5] ^ D[4] ^ D[2] ^ D[1] ^ C[1] ^ C[25] ^ C[26] ^ 
                C[28] ^ C[29];
    NewCRC[10] = D[5] ^ D[3] ^ D[2] ^ D[0] ^ C[2] ^ C[24] ^ C[26] ^ 
                 C[27] ^ C[29];
    NewCRC[11] = D[4] ^ D[3] ^ D[1] ^ D[0] ^ C[3] ^ C[24] ^ C[25] ^ 
                 C[27] ^ C[28];
    NewCRC[12] = D[6] ^ D[5] ^ D[4] ^ D[2] ^ D[1] ^ D[0] ^ C[4] ^ C[24] ^ 
                 C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30];
    NewCRC[13] = D[7] ^ D[6] ^ D[5] ^ D[3] ^ D[2] ^ D[1] ^ C[5] ^ C[25] ^ 
                 C[26] ^ C[27] ^ C[29] ^ C[30] ^ C[31];
    NewCRC[14] = D[7] ^ D[6] ^ D[4] ^ D[3] ^ D[2] ^ C[6] ^ C[26] ^ C[27] ^ 
                 C[28] ^ C[30] ^ C[31];
    NewCRC[15] = D[7] ^ D[5] ^ D[4] ^ D[3] ^ C[7] ^ C[27] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[16] = D[5] ^ D[4] ^ D[0] ^ C[8] ^ C[24] ^ C[28] ^ C[29];
    NewCRC[17] = D[6] ^ D[5] ^ D[1] ^ C[9] ^ C[25] ^ C[29] ^ C[30];
    NewCRC[18] = D[7] ^ D[6] ^ D[2] ^ C[10] ^ C[26] ^ C[30] ^ C[31];
    NewCRC[19] = D[7] ^ D[3] ^ C[11] ^ C[27] ^ C[31];
    NewCRC[20] = D[4] ^ C[12] ^ C[28];
    NewCRC[21] = D[5] ^ C[13] ^ C[29];
    NewCRC[22] = D[0] ^ C[14] ^ C[24];
    NewCRC[23] = D[6] ^ D[1] ^ D[0] ^ C[15] ^ C[24] ^ C[25] ^ C[30];
    NewCRC[24] = D[7] ^ D[2] ^ D[1] ^ C[16] ^ C[25] ^ C[26] ^ C[31];
    NewCRC[25] = D[3] ^ D[2] ^ C[17] ^ C[26] ^ C[27];
    NewCRC[26] = D[6] ^ D[4] ^ D[3] ^ D[0] ^ C[18] ^ C[24] ^ C[27] ^ 
                 C[28] ^ C[30];
    NewCRC[27] = D[7] ^ D[5] ^ D[4] ^ D[1] ^ C[19] ^ C[25] ^ C[28] ^ 
                 C[29] ^ C[31];
    NewCRC[28] = D[6] ^ D[5] ^ D[2] ^ C[20] ^ C[26] ^ C[29] ^ C[30];
    NewCRC[29] = D[7] ^ D[6] ^ D[3] ^ C[21] ^ C[27] ^ C[30] ^ C[31];
    NewCRC[30] = D[7] ^ D[4] ^ C[22] ^ C[28] ^ C[31];
    NewCRC[31] = D[5] ^ C[23] ^ C[29];
    nextCRC32_D8 = NewCRC;
  end
  endfunction
function [63:0] reverse_64b;
  input [63:0]   data;
  integer        i;
    begin
        for (i = 0; i < 64; i = i + 1) begin
            reverse_64b[i] = data[63 - i];
        end
    end
endfunction
function [31:0] reverse_32b;
  input [31:0]   data;
  integer        i;
    begin
        for (i = 0; i < 32; i = i + 1) begin
            reverse_32b[i] = data[31 - i];
        end
    end
endfunction
function [7:0] reverse_8b;
  input [7:0]   data;
  integer        i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            reverse_8b[i] = data[7 - i];
        end
    end
endfunction
input         clk_156m25;
input         reset_156m25_n;
input  [63:0] pkt_tx_data;
input         pkt_tx_val;
input         pkt_tx_sop;
input         pkt_tx_eop;
input  [2:0]  pkt_tx_mod;
input         txdfifo_wfull;
input         txdfifo_walmost_full;
output        pkt_tx_full;
output [63:0] txdfifo_wdata;
output [7:0]  txdfifo_wstatus;
output        txdfifo_wen;
output        status_txdfifo_ovflow_tog;
reg                     status_txdfifo_ovflow_tog;
reg [63:0]              txdfifo_wdata;
reg                     txdfifo_wen;
reg [7:0]               txdfifo_wstatus;
reg             txd_ovflow;
reg             next_txd_ovflow;
assign pkt_tx_full = txdfifo_walmost_full;
always @(posedge clk_156m25 or negedge reset_156m25_n) begin
    if (reset_156m25_n == 1'b0) begin
        txd_ovflow <= 1'b0;
        status_txdfifo_ovflow_tog <= 1'b0;
    end
    else begin
        txd_ovflow <= next_txd_ovflow;
        if (next_txd_ovflow && !txd_ovflow) begin
            status_txdfifo_ovflow_tog <= ~status_txdfifo_ovflow_tog;
        end
    end
end
always @( pkt_tx_data or pkt_tx_eop or pkt_tx_mod or pkt_tx_sop
         or pkt_tx_val or txd_ovflow or txdfifo_wfull) begin
    txdfifo_wstatus = 8'h0;
    txdfifo_wdata = pkt_tx_data;
    txdfifo_wen = pkt_tx_val;
    next_txd_ovflow = txd_ovflow;
    if (pkt_tx_val && pkt_tx_sop) begin
        txdfifo_wstatus[3'd7] = 1'b1;
    end
    if (pkt_tx_val) begin
        if (pkt_tx_eop) begin
            txdfifo_wstatus[2:0] = pkt_tx_mod;
            txdfifo_wstatus[3'd6] = 1'b1;
        end
    end
    if (pkt_tx_val) begin
        if (txdfifo_wfull) begin
            next_txd_ovflow = 1'b1;
        end
        else if (pkt_tx_sop) begin
            next_txd_ovflow = 1'b0;
        end
    end
end
endmodule
module tx_hold_fifo( 
  txhfifo_wfull, txhfifo_walmost_full, txhfifo_rdata, 
  txhfifo_rstatus, txhfifo_rempty, txhfifo_ralmost_empty, 
  clk_xgmii_tx, reset_xgmii_tx_n, txhfifo_wdata, txhfifo_wstatus, 
  txhfifo_wen, txhfifo_ren
  );
input         clk_xgmii_tx;
input         reset_xgmii_tx_n;
input [63:0]  txhfifo_wdata;
input [7:0]   txhfifo_wstatus;
input         txhfifo_wen;
input         txhfifo_ren;
output        txhfifo_wfull;
output        txhfifo_walmost_full;
output [63:0] txhfifo_rdata;
output [7:0]  txhfifo_rstatus;
output        txhfifo_rempty;
output        txhfifo_ralmost_empty;
generic_fifo #(
  .DWIDTH (72),
  .AWIDTH (4),
  .REGISTER_READ (1),
  .EARLY_READ (1),
  .CLOCK_CROSSING (0),
  .ALMOST_EMPTY_THRESH (7),
  .ALMOST_FULL_THRESH (4),
  .MEM_TYPE (1)
)
fifo0(
    .wclk (clk_xgmii_tx),
    .wrst_n (reset_xgmii_tx_n),
    .wen (txhfifo_wen),
    .wdata ({txhfifo_wstatus, txhfifo_wdata}),
    .wfull (txhfifo_wfull),
    .walmost_full (txhfifo_walmost_full),
    .rclk (clk_xgmii_tx),
    .rrst_n (reset_xgmii_tx_n),
    .ren (txhfifo_ren),
    .rdata ({txhfifo_rstatus, txhfifo_rdata}),
    .rempty (txhfifo_rempty),
    .ralmost_empty (txhfifo_ralmost_empty)
);
endmodule
module wishbone_if( 
  wb_dat_o, wb_ack_o, wb_int_o, ctrl_tx_enable, 
  wb_clk_i, wb_rst_i, wb_adr_i, wb_dat_i, wb_we_i, wb_stb_i, 
  wb_cyc_i, status_crc_error, status_fragment_error, 
  status_txdfifo_ovflow, status_txdfifo_udflow, 
  status_rxdfifo_ovflow, status_rxdfifo_udflow, 
  status_pause_frame_rx, status_local_fault, status_remote_fault
  );
input         wb_clk_i;
input         wb_rst_i;
input  [7:0]  wb_adr_i;
input  [31:0] wb_dat_i;
input         wb_we_i;
input         wb_stb_i;
input         wb_cyc_i;
output [31:0] wb_dat_o;
output        wb_ack_o;
output        wb_int_o;
input         status_crc_error;
input         status_fragment_error;
input         status_txdfifo_ovflow;
input         status_txdfifo_udflow;
input         status_rxdfifo_ovflow;
input         status_rxdfifo_udflow;
input         status_pause_frame_rx;
input         status_local_fault;
input         status_remote_fault;
output        ctrl_tx_enable;
reg [31:0]              wb_dat_o;
reg                     wb_int_o;
reg  [0:0]              cpureg_config0;
reg  [8:0]              cpureg_int_pending;
reg  [8:0]              cpureg_int_mask;
reg                     cpuack;
reg                     status_remote_fault_d1;
reg                     status_local_fault_d1;
wire [8:0]             int_sources;
assign int_sources = {
                      status_fragment_error,
                      status_crc_error,
                      status_pause_frame_rx,
                      status_remote_fault ^ status_remote_fault_d1,
                      status_local_fault ^ status_local_fault_d1,
                      status_rxdfifo_udflow,
                      status_rxdfifo_ovflow,
                      status_txdfifo_udflow,
                      status_txdfifo_ovflow
                      };
assign ctrl_tx_enable = cpureg_config0[0];
assign wb_ack_o = cpuack && wb_stb_i;
always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i == 1'b1) begin
        cpureg_config0 <= 1'h1;
        cpureg_int_pending <= 9'b0;
        cpureg_int_mask <= 9'b0;
        wb_dat_o <= 32'b0;
        wb_int_o <= 1'b0;
        cpuack <= 1'b0;
        status_remote_fault_d1 <= status_remote_fault;
        status_local_fault_d1 <= status_local_fault;
    end
    else begin
        wb_int_o <= |(cpureg_int_pending & cpureg_int_mask);
        cpureg_int_pending <= cpureg_int_pending | int_sources;
        cpuack <= wb_cyc_i && wb_stb_i;
        status_remote_fault_d1 <= status_remote_fault;
        status_local_fault_d1 <= status_local_fault;
        if (wb_cyc_i && wb_stb_i && !wb_we_i) begin
            case ({wb_adr_i[7:2], 2'b0})
              8'h00: begin
                  wb_dat_o <= {31'b0, cpureg_config0};
              end
              8'h08: begin
                  wb_dat_o <= {23'b0, cpureg_int_pending};
                  cpureg_int_pending <= int_sources;
                  wb_int_o <= 1'b0;
              end
              8'h0c: begin
                  wb_dat_o <= {23'b0, int_sources};
              end
              8'h10: begin
                  wb_dat_o <= {23'b0, cpureg_int_mask};
              end
              default: begin
              end
            endcase
        end
        if (wb_cyc_i && wb_stb_i && wb_we_i) begin
            case ({wb_adr_i[7:2], 2'b0})
              8'h00: begin
                  cpureg_config0 <= wb_dat_i[0:0];
              end
              8'h08: begin
                  cpureg_int_pending <= wb_dat_i[8:0] | cpureg_int_pending | int_sources;
              end
              8'h10: begin
                  cpureg_int_mask <= wb_dat_i[8:0];
              end
              default: begin
              end
            endcase
        end
    end
end
endmodule
module xge_mac( 
  xgmii_txd, xgmii_txc, wb_int_o, wb_dat_o, wb_ack_o, pkt_tx_full, 
  pkt_rx_val, pkt_rx_sop, pkt_rx_mod, pkt_rx_err, pkt_rx_eop, 
  pkt_rx_data, pkt_rx_avail, 
  xgmii_rxd, xgmii_rxc, wb_we_i, wb_stb_i, wb_rst_i, wb_dat_i, 
  wb_cyc_i, wb_clk_i, wb_adr_i, reset_xgmii_tx_n, reset_xgmii_rx_n, 
  reset_156m25_n, pkt_tx_val, pkt_tx_sop, pkt_tx_mod, pkt_tx_eop, 
  pkt_tx_data, pkt_rx_ren, clk_xgmii_tx, clk_xgmii_rx, clk_156m25
  );
input                   clk_156m25;              
input                   clk_xgmii_rx;            
input                   clk_xgmii_tx;            
input                   pkt_rx_ren;              
input [63:0]            pkt_tx_data;             
input                   pkt_tx_eop;              
input [2:0]             pkt_tx_mod;              
input                   pkt_tx_sop;              
input                   pkt_tx_val;              
input                   reset_156m25_n;          
input                   reset_xgmii_rx_n;        
input                   reset_xgmii_tx_n;        
input [7:0]             wb_adr_i;                
input                   wb_clk_i;                
input                   wb_cyc_i;                
input [31:0]            wb_dat_i;                
input                   wb_rst_i;                
input                   wb_stb_i;                
input                   wb_we_i;                 
input [7:0]             xgmii_rxc;               
input [63:0]            xgmii_rxd;               
output                  pkt_rx_avail;            
output [63:0]           pkt_rx_data;             
output                  pkt_rx_eop;              
output                  pkt_rx_err;              
output [2:0]            pkt_rx_mod;              
output                  pkt_rx_sop;              
output                  pkt_rx_val;              
output                  pkt_tx_full;             
output                  wb_ack_o;                
output [31:0]           wb_dat_o;                
output                  wb_int_o;                
output [7:0]            xgmii_txc;               
output [63:0]           xgmii_txd;               
wire                    ctrl_tx_enable;          
wire                    ctrl_tx_enable_ctx;      
wire [1:0]              local_fault_msg_det;     
wire [1:0]              remote_fault_msg_det;    
wire                    rxdfifo_ralmost_empty;   
wire [63:0]             rxdfifo_rdata;           
wire                    rxdfifo_rempty;          
wire                    rxdfifo_ren;             
wire [7:0]              rxdfifo_rstatus;         
wire [63:0]             rxdfifo_wdata;           
wire                    rxdfifo_wen;             
wire                    rxdfifo_wfull;           
wire [7:0]              rxdfifo_wstatus;         
wire                    rxhfifo_ralmost_empty;   
wire [63:0]             rxhfifo_rdata;           
wire                    rxhfifo_rempty;          
wire                    rxhfifo_ren;             
wire [7:0]              rxhfifo_rstatus;         
wire [63:0]             rxhfifo_wdata;           
wire                    rxhfifo_wen;             
wire [7:0]              rxhfifo_wstatus;         
wire                    status_crc_error;        
wire                    status_crc_error_tog;    
wire                    status_fragment_error;   
wire                    status_fragment_error_tog; 
wire                    status_local_fault;      
wire                    status_local_fault_crx;  
wire                    status_local_fault_ctx;  
wire                    status_pause_frame_rx;   
wire                    status_pause_frame_rx_tog; 
wire                    status_remote_fault;     
wire                    status_remote_fault_crx; 
wire                    status_remote_fault_ctx; 
wire                    status_rxdfifo_ovflow;   
wire                    status_rxdfifo_ovflow_tog; 
wire                    status_rxdfifo_udflow;   
wire                    status_rxdfifo_udflow_tog; 
wire                    status_txdfifo_ovflow;   
wire                    status_txdfifo_ovflow_tog; 
wire                    status_txdfifo_udflow;   
wire                    status_txdfifo_udflow_tog; 
wire                    txdfifo_ralmost_empty;   
wire [63:0]             txdfifo_rdata;           
wire                    txdfifo_rempty;          
wire                    txdfifo_ren;             
wire [7:0]              txdfifo_rstatus;         
wire                    txdfifo_walmost_full;    
wire [63:0]             txdfifo_wdata;           
wire                    txdfifo_wen;             
wire                    txdfifo_wfull;           
wire [7:0]              txdfifo_wstatus;         
wire                    txhfifo_ralmost_empty;   
wire [63:0]             txhfifo_rdata;           
wire                    txhfifo_rempty;          
wire                    txhfifo_ren;             
wire [7:0]              txhfifo_rstatus;         
wire                    txhfifo_walmost_full;    
wire [63:0]             txhfifo_wdata;           
wire                    txhfifo_wen;             
wire                    txhfifo_wfull;           
wire [7:0]              txhfifo_wstatus;         
rx_enqueue rx_eq0( 
                  .rxdfifo_wdata        (rxdfifo_wdata[63:0]),
                  .rxdfifo_wstatus      (rxdfifo_wstatus[7:0]),
                  .rxdfifo_wen          (rxdfifo_wen),
                  .rxhfifo_ren          (rxhfifo_ren),
                  .rxhfifo_wdata        (rxhfifo_wdata[63:0]),
                  .rxhfifo_wstatus      (rxhfifo_wstatus[7:0]),
                  .rxhfifo_wen          (rxhfifo_wen),
                  .local_fault_msg_det  (local_fault_msg_det[1:0]),
                  .remote_fault_msg_det (remote_fault_msg_det[1:0]),
                  .status_crc_error_tog (status_crc_error_tog),
                  .status_fragment_error_tog(status_fragment_error_tog),
                  .status_rxdfifo_ovflow_tog(status_rxdfifo_ovflow_tog),
                  .status_pause_frame_rx_tog(status_pause_frame_rx_tog),
                  .clk_xgmii_rx         (clk_xgmii_rx),
                  .reset_xgmii_rx_n     (reset_xgmii_rx_n),
                  .xgmii_rxd            (xgmii_rxd[63:0]),
                  .xgmii_rxc            (xgmii_rxc[7:0]),
                  .rxdfifo_wfull        (rxdfifo_wfull),
                  .rxhfifo_rdata        (rxhfifo_rdata[63:0]),
                  .rxhfifo_rstatus      (rxhfifo_rstatus[7:0]),
                  .rxhfifo_rempty       (rxhfifo_rempty),
                  .rxhfifo_ralmost_empty(rxhfifo_ralmost_empty));
rx_dequeue rx_dq0( 
                  .rxdfifo_ren          (rxdfifo_ren),
                  .pkt_rx_data          (pkt_rx_data[63:0]),
                  .pkt_rx_val           (pkt_rx_val),
                  .pkt_rx_sop           (pkt_rx_sop),
                  .pkt_rx_eop           (pkt_rx_eop),
                  .pkt_rx_err           (pkt_rx_err),
                  .pkt_rx_mod           (pkt_rx_mod[2:0]),
                  .pkt_rx_avail         (pkt_rx_avail),
                  .status_rxdfifo_udflow_tog(status_rxdfifo_udflow_tog),
                  .clk_156m25           (clk_156m25),
                  .reset_156m25_n       (reset_156m25_n),
                  .rxdfifo_rdata        (rxdfifo_rdata[63:0]),
                  .rxdfifo_rstatus      (rxdfifo_rstatus[7:0]),
                  .rxdfifo_rempty       (rxdfifo_rempty),
                  .rxdfifo_ralmost_empty(rxdfifo_ralmost_empty),
                  .pkt_rx_ren           (pkt_rx_ren));
rx_data_fifo rx_data_fifo0( 
                           .rxdfifo_wfull(rxdfifo_wfull),
                           .rxdfifo_rdata(rxdfifo_rdata[63:0]),
                           .rxdfifo_rstatus(rxdfifo_rstatus[7:0]),
                           .rxdfifo_rempty(rxdfifo_rempty),
                           .rxdfifo_ralmost_empty(rxdfifo_ralmost_empty),
                           .clk_xgmii_rx(clk_xgmii_rx),
                           .clk_156m25  (clk_156m25),
                           .reset_xgmii_rx_n(reset_xgmii_rx_n),
                           .reset_156m25_n(reset_156m25_n),
                           .rxdfifo_wdata(rxdfifo_wdata[63:0]),
                           .rxdfifo_wstatus(rxdfifo_wstatus[7:0]),
                           .rxdfifo_wen (rxdfifo_wen),
                           .rxdfifo_ren (rxdfifo_ren));
rx_hold_fifo rx_hold_fifo0( 
                           .rxhfifo_rdata(rxhfifo_rdata[63:0]),
                           .rxhfifo_rstatus(rxhfifo_rstatus[7:0]),
                           .rxhfifo_rempty(rxhfifo_rempty),
                           .rxhfifo_ralmost_empty(rxhfifo_ralmost_empty),
                           .clk_xgmii_rx(clk_xgmii_rx),
                           .reset_xgmii_rx_n(reset_xgmii_rx_n),
                           .rxhfifo_wdata(rxhfifo_wdata[63:0]),
                           .rxhfifo_wstatus(rxhfifo_wstatus[7:0]),
                           .rxhfifo_wen (rxhfifo_wen),
                           .rxhfifo_ren (rxhfifo_ren));
tx_enqueue tx_eq0 ( 
                   .pkt_tx_full         (pkt_tx_full),
                   .txdfifo_wdata       (txdfifo_wdata[63:0]),
                   .txdfifo_wstatus     (txdfifo_wstatus[7:0]),
                   .txdfifo_wen         (txdfifo_wen),
                   .status_txdfifo_ovflow_tog(status_txdfifo_ovflow_tog),
                   .clk_156m25          (clk_156m25),
                   .reset_156m25_n      (reset_156m25_n),
                   .pkt_tx_data         (pkt_tx_data[63:0]),
                   .pkt_tx_val          (pkt_tx_val),
                   .pkt_tx_sop          (pkt_tx_sop),
                   .pkt_tx_eop          (pkt_tx_eop),
                   .pkt_tx_mod          (pkt_tx_mod[2:0]),
                   .txdfifo_wfull       (txdfifo_wfull),
                   .txdfifo_walmost_full(txdfifo_walmost_full));
tx_dequeue tx_dq0( 
                  .txdfifo_ren          (txdfifo_ren),
                  .txhfifo_ren          (txhfifo_ren),
                  .txhfifo_wdata        (txhfifo_wdata[63:0]),
                  .txhfifo_wstatus      (txhfifo_wstatus[7:0]),
                  .txhfifo_wen          (txhfifo_wen),
                  .xgmii_txd            (xgmii_txd[63:0]),
                  .xgmii_txc            (xgmii_txc[7:0]),
                  .status_txdfifo_udflow_tog(status_txdfifo_udflow_tog),
                  .clk_xgmii_tx         (clk_xgmii_tx),
                  .reset_xgmii_tx_n     (reset_xgmii_tx_n),
                  .ctrl_tx_enable_ctx   (ctrl_tx_enable_ctx),
                  .status_local_fault_ctx(status_local_fault_ctx),
                  .status_remote_fault_ctx(status_remote_fault_ctx),
                  .txdfifo_rdata        (txdfifo_rdata[63:0]),
                  .txdfifo_rstatus      (txdfifo_rstatus[7:0]),
                  .txdfifo_rempty       (txdfifo_rempty),
                  .txdfifo_ralmost_empty(txdfifo_ralmost_empty),
                  .txhfifo_rdata        (txhfifo_rdata[63:0]),
                  .txhfifo_rstatus      (txhfifo_rstatus[7:0]),
                  .txhfifo_rempty       (txhfifo_rempty),
                  .txhfifo_ralmost_empty(txhfifo_ralmost_empty),
                  .txhfifo_wfull        (txhfifo_wfull),
                  .txhfifo_walmost_full (txhfifo_walmost_full));
tx_data_fifo tx_data_fifo0( 
                           .txdfifo_wfull(txdfifo_wfull),
                           .txdfifo_walmost_full(txdfifo_walmost_full),
                           .txdfifo_rdata(txdfifo_rdata[63:0]),
                           .txdfifo_rstatus(txdfifo_rstatus[7:0]),
                           .txdfifo_rempty(txdfifo_rempty),
                           .txdfifo_ralmost_empty(txdfifo_ralmost_empty),
                           .clk_xgmii_tx(clk_xgmii_tx),
                           .clk_156m25  (clk_156m25),
                           .reset_xgmii_tx_n(reset_xgmii_tx_n),
                           .reset_156m25_n(reset_156m25_n),
                           .txdfifo_wdata(txdfifo_wdata[63:0]),
                           .txdfifo_wstatus(txdfifo_wstatus[7:0]),
                           .txdfifo_wen (txdfifo_wen),
                           .txdfifo_ren (txdfifo_ren));
tx_hold_fifo tx_hold_fifo0( 
                           .txhfifo_wfull(txhfifo_wfull),
                           .txhfifo_walmost_full(txhfifo_walmost_full),
                           .txhfifo_rdata(txhfifo_rdata[63:0]),
                           .txhfifo_rstatus(txhfifo_rstatus[7:0]),
                           .txhfifo_rempty(txhfifo_rempty),
                           .txhfifo_ralmost_empty(txhfifo_ralmost_empty),
                           .clk_xgmii_tx(clk_xgmii_tx),
                           .reset_xgmii_tx_n(reset_xgmii_tx_n),
                           .txhfifo_wdata(txhfifo_wdata[63:0]),
                           .txhfifo_wstatus(txhfifo_wstatus[7:0]),
                           .txhfifo_wen (txhfifo_wen),
                           .txhfifo_ren (txhfifo_ren));
fault_sm fault_sm0( 
                   .status_local_fault_crx(status_local_fault_crx),
                   .status_remote_fault_crx(status_remote_fault_crx),
                   .clk_xgmii_rx        (clk_xgmii_rx),
                   .reset_xgmii_rx_n    (reset_xgmii_rx_n),
                   .local_fault_msg_det (local_fault_msg_det[1:0]),
                   .remote_fault_msg_det(remote_fault_msg_det[1:0]));
sync_clk_wb sync_clk_wb0( 
                         .status_crc_error(status_crc_error),
                         .status_fragment_error(status_fragment_error),
                         .status_txdfifo_ovflow(status_txdfifo_ovflow),
                         .status_txdfifo_udflow(status_txdfifo_udflow),
                         .status_rxdfifo_ovflow(status_rxdfifo_ovflow),
                         .status_rxdfifo_udflow(status_rxdfifo_udflow),
                         .status_pause_frame_rx(status_pause_frame_rx),
                         .status_local_fault(status_local_fault),
                         .status_remote_fault(status_remote_fault),
                         .wb_clk_i      (wb_clk_i),
                         .wb_rst_i      (wb_rst_i),
                         .status_crc_error_tog(status_crc_error_tog),
                         .status_fragment_error_tog(status_fragment_error_tog),
                         .status_txdfifo_ovflow_tog(status_txdfifo_ovflow_tog),
                         .status_txdfifo_udflow_tog(status_txdfifo_udflow_tog),
                         .status_rxdfifo_ovflow_tog(status_rxdfifo_ovflow_tog),
                         .status_rxdfifo_udflow_tog(status_rxdfifo_udflow_tog),
                         .status_pause_frame_rx_tog(status_pause_frame_rx_tog),
                         .status_local_fault_crx(status_local_fault_crx),
                         .status_remote_fault_crx(status_remote_fault_crx));
sync_clk_xgmii_tx sync_clk_xgmii_tx0( 
                                     .ctrl_tx_enable_ctx(ctrl_tx_enable_ctx),
                                     .status_local_fault_ctx(status_local_fault_ctx),
                                     .status_remote_fault_ctx(status_remote_fault_ctx),
                                     .clk_xgmii_tx(clk_xgmii_tx),
                                     .reset_xgmii_tx_n(reset_xgmii_tx_n),
                                     .ctrl_tx_enable(ctrl_tx_enable),
                                     .status_local_fault_crx(status_local_fault_crx),
                                     .status_remote_fault_crx(status_remote_fault_crx));
sync_clk_core sync_clk_core0( 
                             .clk_xgmii_tx(clk_xgmii_tx),
                             .reset_xgmii_tx_n(reset_xgmii_tx_n));
wishbone_if wishbone_if0( 
                         .wb_dat_o      (wb_dat_o[31:0]),
                         .wb_ack_o      (wb_ack_o),
                         .wb_int_o      (wb_int_o),
                         .ctrl_tx_enable(ctrl_tx_enable),
                         .wb_clk_i      (wb_clk_i),
                         .wb_rst_i      (wb_rst_i),
                         .wb_adr_i      (wb_adr_i[7:0]),
                         .wb_dat_i      (wb_dat_i[31:0]),
                         .wb_we_i       (wb_we_i),
                         .wb_stb_i      (wb_stb_i),
                         .wb_cyc_i      (wb_cyc_i),
                         .status_crc_error(status_crc_error),
                         .status_fragment_error(status_fragment_error),
                         .status_txdfifo_ovflow(status_txdfifo_ovflow),
                         .status_txdfifo_udflow(status_txdfifo_udflow),
                         .status_rxdfifo_ovflow(status_rxdfifo_ovflow),
                         .status_rxdfifo_udflow(status_rxdfifo_udflow),
                         .status_pause_frame_rx(status_pause_frame_rx),
                         .status_local_fault(status_local_fault),
                         .status_remote_fault(status_remote_fault));
endmodule
