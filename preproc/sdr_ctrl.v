module sdrc_top 
           (
                    cfg_sdr_width       ,
                    cfg_colbits         ,
                    wb_rst_i            ,
                    wb_clk_i            ,
                    wb_stb_i            ,
                    wb_ack_o            ,
                    wb_addr_i           ,
                    wb_we_i             ,
                    wb_dat_i            ,
                    wb_sel_i            ,
                    wb_dat_o            ,
                    wb_cyc_i            ,
                    wb_cti_i            , 
                    sdram_clk           ,
                    sdram_resetn        ,
                    sdr_cs_n            ,
                    sdr_cke             ,
                    sdr_ras_n           ,
                    sdr_cas_n           ,
                    sdr_we_n            ,
                    sdr_dqm             ,
                    sdr_ba              ,
                    sdr_addr            , 
                    sdr_dq              ,
                    sdr_init_done       ,
                    cfg_req_depth       ,	         
                    cfg_sdr_en          ,
                    cfg_sdr_mode_reg    ,
                    cfg_sdr_tras_d      ,
                    cfg_sdr_trp_d       ,
                    cfg_sdr_trcd_d      ,
                    cfg_sdr_cas         ,
                    cfg_sdr_trcar_d     ,
                    cfg_sdr_twr_d       ,
                    cfg_sdr_rfsh        ,
	            cfg_sdr_rfmax
	    );
parameter      APP_AW   = 26;   
parameter      APP_DW   = 32;   
parameter      APP_BW   = 4;    
parameter      APP_RW   = 9;    
parameter      SDR_DW   = 16;   
parameter      SDR_BW   = 2;    
parameter      dw       = 32;   
parameter      tw       = 8;    
parameter      bl       = 9;    
input                   sdram_clk          ;  
input                   sdram_resetn       ;  
input [1:0]             cfg_sdr_width      ;  
input [1:0]             cfg_colbits        ;  
input                   wb_rst_i           ;
input                   wb_clk_i           ;
input                   wb_stb_i           ;
output                  wb_ack_o           ;
input [APP_AW-1:0]            wb_addr_i          ;
input                   wb_we_i            ;  
input [dw-1:0]          wb_dat_i           ;
input [dw/8-1:0]        wb_sel_i           ;  
output [dw-1:0]         wb_dat_o           ;
input                   wb_cyc_i           ;
input  [2:0]            wb_cti_i           ;
output                  sdr_cke             ;  
output 			sdr_cs_n            ;  
output                  sdr_ras_n           ;  
output                  sdr_cas_n           ;  
output			sdr_we_n            ;  
output [SDR_BW-1:0] 	sdr_dqm             ;  
output [1:0] 		sdr_ba              ;  
output [12:0] 		sdr_addr            ;  
inout [SDR_DW-1:0] 	sdr_dq              ;  
output                  sdr_init_done       ;  
input [3:0] 		cfg_sdr_tras_d      ;  
input [3:0]             cfg_sdr_trp_d       ;  
input [3:0]             cfg_sdr_trcd_d      ;  
input 			cfg_sdr_en          ;  
input [1:0] 		cfg_req_depth       ;  
input [12:0] 		cfg_sdr_mode_reg    ;
input [2:0] 		cfg_sdr_cas         ;  
input [3:0] 		cfg_sdr_trcar_d     ;  
input [3:0]             cfg_sdr_twr_d       ;  
input [12-1 : 0] cfg_sdr_rfsh;
input [3 -1 : 0] cfg_sdr_rfmax;
wire                  app_req            ;  
wire [APP_AW-1:0]     app_req_addr       ;  
wire [bl-1:0]         app_req_len        ;
wire                  app_req_wr_n       ;  
wire                  app_req_ack        ;  
wire                  app_busy_n         ;  
wire [dw/8-1:0]       app_wr_en_n        ;  
wire                  app_wr_next_req    ;  
wire                  app_rd_valid       ;  
wire                  app_last_rd        ;  
wire                  app_last_wr        ;  
wire [dw-1:0]         app_wr_data        ;  
wire  [dw-1:0]        app_rd_data        ;  
wire  [SDR_DW-1:0]    pad_sdr_din         ;  
wire  [SDR_DW-1:0]    sdr_dout            ;  
wire  [SDR_BW-1:0]    sdr_den_n           ;  
assign   sdr_dq = (&sdr_den_n == 1'b0) ? sdr_dout :  {SDR_DW{1'bz}}; 
assign   pad_sdr_din = sdr_dq;
wire #(1.0) sdram_pad_clk = sdram_clk;
wb2sdrc #(.dw(dw),.tw(tw),.bl(bl)) u_wb2sdrc (
          .wb_rst_i           (wb_rst_i           ) ,
          .wb_clk_i           (wb_clk_i           ) ,
          .wb_stb_i           (wb_stb_i           ) ,
          .wb_ack_o           (wb_ack_o           ) ,
          .wb_addr_i          (wb_addr_i          ) ,
          .wb_we_i            (wb_we_i            ) ,
          .wb_dat_i           (wb_dat_i           ) ,
          .wb_sel_i           (wb_sel_i           ) ,
          .wb_dat_o           (wb_dat_o           ) ,
          .wb_cyc_i           (wb_cyc_i           ) ,
          .wb_cti_i           (wb_cti_i           ) , 
          .sdram_clk          (sdram_clk          ) ,
          .sdram_resetn       (sdram_resetn       ) ,
          .sdr_req            (app_req            ) ,
          .sdr_req_addr       (app_req_addr       ) ,
          .sdr_req_len        (app_req_len        ) ,
          .sdr_req_wr_n       (app_req_wr_n       ) ,
          .sdr_req_ack        (app_req_ack        ) ,
          .sdr_busy_n         (app_busy_n         ) ,
          .sdr_wr_en_n        (app_wr_en_n        ) ,
          .sdr_wr_next        (app_wr_next_req    ) ,
          .sdr_rd_valid       (app_rd_valid       ) ,
          .sdr_last_rd        (app_last_rd        ) ,
          .sdr_wr_data        (app_wr_data        ) ,
          .sdr_rd_data        (app_rd_data        ) 
      ); 
sdrc_core #(.SDR_DW(SDR_DW) , .SDR_BW(SDR_BW)) u_sdrc_core (
          .clk                (sdram_clk          ) ,
          .pad_clk            (sdram_pad_clk      ) ,
          .reset_n            (sdram_resetn       ) ,
          .sdr_width          (cfg_sdr_width      ) ,
          .cfg_colbits        (cfg_colbits        ) ,
          .app_req            (app_req            ) , 
          .app_req_addr       (app_req_addr       ) , 
          .app_req_len        (app_req_len        ) , 
          .app_req_wrap       (1'b0               ) , 
          .app_req_wr_n       (app_req_wr_n       ) , 
          .app_req_ack        (app_req_ack        ) , 
          .cfg_req_depth      (cfg_req_depth      ) , 
          .app_wr_data        (app_wr_data        ) ,
          .app_wr_en_n        (app_wr_en_n        ) ,
          .app_rd_data        (app_rd_data        ) ,
          .app_rd_valid       (app_rd_valid       ) ,
	  .app_last_rd        (app_last_rd        ) ,
          .app_last_wr        (app_last_wr        ) ,
          .app_wr_next_req    (app_wr_next_req    ) ,
          .sdr_init_done      (sdr_init_done      ) ,
          .app_req_dma_last   (app_req            ) ,
          .sdr_cs_n           (sdr_cs_n           ) ,
          .sdr_cke            (sdr_cke            ) ,
          .sdr_ras_n          (sdr_ras_n          ) ,
          .sdr_cas_n          (sdr_cas_n          ) ,
          .sdr_we_n           (sdr_we_n           ) ,
          .sdr_dqm            (sdr_dqm            ) ,
          .sdr_ba             (sdr_ba             ) ,
          .sdr_addr           (sdr_addr           ) , 
          .pad_sdr_din        (pad_sdr_din        ) ,
          .sdr_dout           (sdr_dout           ) ,
          .sdr_den_n          (sdr_den_n          ) ,
          .cfg_sdr_en         (cfg_sdr_en         ) ,
          .cfg_sdr_mode_reg   (cfg_sdr_mode_reg   ) ,
          .cfg_sdr_tras_d     (cfg_sdr_tras_d     ) ,
          .cfg_sdr_trp_d      (cfg_sdr_trp_d      ) ,
          .cfg_sdr_trcd_d     (cfg_sdr_trcd_d     ) ,
          .cfg_sdr_cas        (cfg_sdr_cas        ) ,
          .cfg_sdr_trcar_d    (cfg_sdr_trcar_d    ) ,
          .cfg_sdr_twr_d      (cfg_sdr_twr_d      ) ,
          .cfg_sdr_rfsh       (cfg_sdr_rfsh       ) ,
          .cfg_sdr_rfmax      (cfg_sdr_rfmax      ) 
	       );
endmodule  
module wb2sdrc (
                    wb_rst_i            ,
                    wb_clk_i            ,
                    wb_stb_i            ,
                    wb_ack_o            ,
                    wb_addr_i           ,
                    wb_we_i             ,
                    wb_dat_i            ,
                    wb_sel_i            ,
                    wb_dat_o            ,
                    wb_cyc_i            ,
                    wb_cti_i            , 
                    sdram_clk           ,
                    sdram_resetn        ,
                    sdr_req             ,
                    sdr_req_addr        ,
                    sdr_req_len         ,
                    sdr_req_wr_n        ,
                    sdr_req_ack         ,
                    sdr_busy_n          ,
                    sdr_wr_en_n         ,
                    sdr_wr_next         ,
                    sdr_rd_valid        ,
                    sdr_last_rd         ,
                    sdr_wr_data         ,
                    sdr_rd_data        
      ); 
parameter      dw              = 32;   
parameter      tw              = 8;    
parameter      bl              = 9;    
parameter      APP_AW          = 26;   
input                   wb_rst_i           ;
input                   wb_clk_i           ;
input                   wb_stb_i           ;
output                  wb_ack_o           ;
input [APP_AW-1:0]      wb_addr_i          ;
input                   wb_we_i            ;  
input [dw-1:0]          wb_dat_i           ;
input [dw/8-1:0]        wb_sel_i           ;  
output [dw-1:0]         wb_dat_o           ;
input                   wb_cyc_i           ;
input  [2:0]            wb_cti_i           ;
input                   sdram_clk          ;  
input                   sdram_resetn       ;  
output                  sdr_req            ;  
output [APP_AW-1:0]           sdr_req_addr       ;  
output [bl-1:0]         sdr_req_len        ;
output                  sdr_req_wr_n       ;  
input                   sdr_req_ack        ;  
input                   sdr_busy_n         ;  
output [dw/8-1:0]       sdr_wr_en_n        ;  
input                   sdr_wr_next        ;  
input                   sdr_rd_valid       ;  
input                   sdr_last_rd        ;  
output [dw-1:0]         sdr_wr_data        ;  
input  [dw-1:0]         sdr_rd_data        ;  
wire                    cmdfifo_full       ;
wire                    cmdfifo_empty      ;
wire                    wrdatafifo_full    ;
wire                    wrdatafifo_empty   ;
wire                    tagfifo_full       ;
wire                    tagfifo_empty      ;
wire                    rddatafifo_empty   ;
wire                    rddatafifo_full    ;
reg                     pending_read       ;
assign wb_ack_o = (wb_stb_i && wb_cyc_i && wb_we_i) ?   
	                  ((!cmdfifo_full) && (!wrdatafifo_full)) :
		  (wb_stb_i && wb_cyc_i && !wb_we_i) ?  
		           !rddatafifo_empty : 1'b0;
wire           cmdfifo_wr   = (wb_stb_i && wb_cyc_i && wb_we_i && (!cmdfifo_full) ) ? wb_ack_o :
	                      (wb_stb_i && wb_cyc_i && !wb_we_i && (!cmdfifo_full)) ? !pending_read: 1'b0 ; 
wire           cmdfifo_rd   = sdr_req_ack;
assign         sdr_req      = !cmdfifo_empty;
wire [bl-1:0]  burst_length  = 1;   
always @(posedge wb_rst_i or posedge wb_clk_i) begin
   if(wb_rst_i) begin
       pending_read <= 1'b0;
   end else begin
      pending_read <=   (cmdfifo_wr && !wb_we_i) ? 1'b1:
	                (wb_stb_i & wb_cyc_i & !wb_we_i & wb_ack_o) ? 1'b0: pending_read;
   end
end
    async_fifo #(.W(APP_AW+bl+1),.DP(4),.WR_FAST(1'b0), .RD_FAST(1'b0)) u_cmdfifo (
          .wr_clk             (wb_clk_i           ),
          .wr_reset_n         (!wb_rst_i          ),
          .wr_en              (cmdfifo_wr         ),
          .wr_data            ({burst_length, 
	                        !wb_we_i, 
				wb_addr_i}        ),
          .afull              (                   ),
          .full               (cmdfifo_full       ),
          .rd_clk             (sdram_clk          ),
          .rd_reset_n         (sdram_resetn       ),
          .aempty             (                   ),
          .empty              (cmdfifo_empty      ),
          .rd_en              (cmdfifo_rd         ),
          .rd_data            ({sdr_req_len,
	                        sdr_req_wr_n,
		                sdr_req_addr}     )
     );
always @(posedge wb_clk_i) begin
  if (cmdfifo_full == 1'b1 && cmdfifo_wr == 1'b1)  begin
     $display("ERROR:%m COMMAND FIFO WRITE OVERFLOW");
  end 
end 
always @(posedge sdram_clk) begin
   if (cmdfifo_empty == 1'b1 && cmdfifo_rd == 1'b1) begin
      $display("ERROR:%m COMMAND FIFO READ OVERFLOW");
   end
end 
wire  wrdatafifo_wr  = wb_ack_o & wb_we_i ;
wire  wrdatafifo_rd  = sdr_wr_next;
    async_fifo #(.W(dw+(dw/8)), .DP(8), .WR_FAST(1'b0), .RD_FAST(1'b1)) u_wrdatafifo (
          .wr_clk             (wb_clk_i           ),
          .wr_reset_n         (!wb_rst_i          ),
          .wr_en              (wrdatafifo_wr      ),
          .wr_data            ({~wb_sel_i, 
	                         wb_dat_i}        ),
          .afull              (                   ),
          .full               (wrdatafifo_full    ),
          .rd_clk             (sdram_clk          ),
          .rd_reset_n         (sdram_resetn       ),
          .aempty             (                   ),
          .empty              (wrdatafifo_empty   ),
          .rd_en              (wrdatafifo_rd      ),
          .rd_data            ({sdr_wr_en_n,
                                sdr_wr_data}      )
     );
always @(posedge wb_clk_i) begin
  if (wrdatafifo_full == 1'b1 && wrdatafifo_wr == 1'b1)  begin
     $display("ERROR:%m WRITE DATA FIFO WRITE OVERFLOW");
  end 
end 
always @(posedge sdram_clk) begin
   if (wrdatafifo_empty == 1'b1 && wrdatafifo_rd == 1'b1) begin
      $display("ERROR:%m WRITE DATA FIFO READ OVERFLOW");
   end
end 
wire    rd_eop;  
wire    rddatafifo_wr = sdr_rd_valid;
wire    rddatafifo_rd = wb_ack_o & !wb_we_i;
    async_fifo #(.W(dw+1), .DP(4), .WR_FAST(1'b0), .RD_FAST(1'b1) ) u_rddatafifo (
          .wr_clk             (sdram_clk          ),
          .wr_reset_n         (sdram_resetn       ),
          .wr_en              (rddatafifo_wr      ),
          .wr_data            ({sdr_last_rd,
	                        sdr_rd_data}      ),
          .afull              (                   ),
          .full               (rddatafifo_full    ),
          .rd_clk             (wb_clk_i           ),
          .rd_reset_n         (!wb_rst_i          ),
          .empty              (rddatafifo_empty   ),
          .aempty             (                   ),
          .rd_en              (rddatafifo_rd      ),
          .rd_data            ({rd_eop,
                                wb_dat_o}         )
     );
always @(posedge sdram_clk) begin
  if (rddatafifo_full == 1'b1 && rddatafifo_wr == 1'b1)  begin
     $display("ERROR:%m READ DATA FIFO WRITE OVERFLOW");
  end 
end 
always @(posedge wb_clk_i) begin
   if (rddatafifo_empty == 1'b1 && rddatafifo_rd == 1'b1) begin
      $display("ERROR:%m READ DATA FIFO READ OVERFLOW");
   end
end 
endmodule
module async_fifo (wr_clk,
                   wr_reset_n,
                   wr_en,
                   wr_data,
                   full,                  
                   afull,                  
                   rd_clk,
                   rd_reset_n,
                   rd_en,
                   empty,                 
                   aempty,                 
                   rd_data);
   parameter W = 4'd8;
   parameter DP = 3'd4;
   parameter WR_FAST = 1'b1;
   parameter RD_FAST = 1'b1;
   parameter FULL_DP = DP;
   parameter EMPTY_DP = 1'b0;
   parameter AW = (DP == 2)   ? 1 : 
		  (DP == 4)   ? 2 :
                  (DP == 8)   ? 3 :
                  (DP == 16)  ? 4 :
                  (DP == 32)  ? 5 :
                  (DP == 64)  ? 6 :
                  (DP == 128) ? 7 :
                  (DP == 256) ? 8 : 0;
   output [W-1 : 0]  rd_data;
   input [W-1 : 0]   wr_data;
   input             wr_clk, wr_reset_n, wr_en, rd_clk, rd_reset_n,
                     rd_en;
   output            full, empty;
   output            afull, aempty;        
   initial begin
      if (AW == 0) begin
         $display ("%m : ERROR!!! Fifo depth %d not in range 2 to 256", DP);
      end  
   end  
   reg [W-1 : 0]    mem[DP-1 : 0];
   reg [AW:0] sync_rd_ptr_0, sync_rd_ptr_1; 
   wire [AW:0] sync_rd_ptr;
   reg [AW:0] wr_ptr, grey_wr_ptr;
   reg [AW:0] grey_rd_ptr;
   reg full_q;
   wire full_c;
   wire afull_c;
   wire [AW:0] wr_ptr_inc = wr_ptr + 1'b1;
   wire [AW:0] wr_cnt = get_cnt(wr_ptr, sync_rd_ptr);
   assign full_c  = (wr_cnt == FULL_DP) ? 1'b1 : 1'b0;
   assign afull_c = (wr_cnt == FULL_DP-1) ? 1'b1 : 1'b0;
   always @(posedge wr_clk or negedge wr_reset_n) begin
	if (!wr_reset_n) begin
		wr_ptr <= 0;
		grey_wr_ptr <= 0;
		full_q <= 0;	
	end
	else if (wr_en) begin
		wr_ptr <= wr_ptr_inc;
		grey_wr_ptr <= bin2grey(wr_ptr_inc);
		if (wr_cnt == (FULL_DP-1)) begin
			full_q <= 1'b1;
		end
	end
	else begin
	    	if (full_q && (wr_cnt<FULL_DP)) begin
			full_q <= 1'b0;
	     	end
	end
    end
    assign full  = (WR_FAST == 1) ? full_c : full_q;
    assign afull = afull_c;
    always @(posedge wr_clk) begin
	if (wr_en) begin
		mem[wr_ptr[AW-1:0]] <= wr_data;
	end
    end
    wire [AW:0] grey_rd_ptr_dly ;
    assign #1 grey_rd_ptr_dly = grey_rd_ptr;
    always @(posedge wr_clk or negedge wr_reset_n) begin
	if (!wr_reset_n) begin
		sync_rd_ptr_0 <= 0;
		sync_rd_ptr_1 <= 0;
	end
	else begin
		sync_rd_ptr_0 <= grey_rd_ptr_dly;		
		sync_rd_ptr_1 <= sync_rd_ptr_0;
	end
    end
    assign sync_rd_ptr = grey2bin(sync_rd_ptr_1);
   reg [AW:0] sync_wr_ptr_0, sync_wr_ptr_1; 
   wire [AW:0] sync_wr_ptr;
   reg [AW:0] rd_ptr;
   reg empty_q;
   wire empty_c;
   wire aempty_c;
   wire [AW:0] rd_ptr_inc = rd_ptr + 1'b1;
   wire [AW:0] sync_wr_ptr_dec = sync_wr_ptr - 1'b1;
   wire [AW:0] rd_cnt = get_cnt(sync_wr_ptr, rd_ptr);
   assign empty_c  = (rd_cnt == 0) ? 1'b1 : 1'b0;
   assign aempty_c = (rd_cnt == 1) ? 1'b1 : 1'b0;
   always @(posedge rd_clk or negedge rd_reset_n) begin
      if (!rd_reset_n) begin
         rd_ptr <= 0;
	 grey_rd_ptr <= 0;
	 empty_q <= 1'b1;
      end
      else begin
         if (rd_en) begin
            rd_ptr <= rd_ptr_inc;
            grey_rd_ptr <= bin2grey(rd_ptr_inc);
            if (rd_cnt==(EMPTY_DP+1)) begin
               empty_q <= 1'b1;
            end
         end
         else begin
            if (empty_q && (rd_cnt!=EMPTY_DP)) begin
	      empty_q <= 1'b0;
	    end
         end
       end
    end
    assign empty  = (RD_FAST == 1) ? empty_c : empty_q;
    assign aempty = aempty_c;
    reg [W-1 : 0]  rd_data_q;
   wire [W-1 : 0] rd_data_c = mem[rd_ptr[AW-1:0]];
   always @(posedge rd_clk) begin
	rd_data_q <= rd_data_c;
   end
   assign rd_data  = (RD_FAST == 1) ? rd_data_c : rd_data_q;
    wire [AW:0] grey_wr_ptr_dly ;
    assign #1 grey_wr_ptr_dly =  grey_wr_ptr;
    always @(posedge rd_clk or negedge rd_reset_n) begin
	if (!rd_reset_n) begin
	   sync_wr_ptr_0 <= 0;
	   sync_wr_ptr_1 <= 0;
	end
	else begin
	   sync_wr_ptr_0 <= grey_wr_ptr_dly;		
	   sync_wr_ptr_1 <= sync_wr_ptr_0;
	end
    end
    assign sync_wr_ptr = grey2bin(sync_wr_ptr_1);
function [AW:0] bin2grey;
input [AW:0] bin;
reg [8:0] bin_8;
reg [8:0] grey_8;
begin
	bin_8 = bin;
	grey_8[1:0] = do_grey(bin_8[2:0]);
	grey_8[3:2] = do_grey(bin_8[4:2]);
	grey_8[5:4] = do_grey(bin_8[6:4]);
	grey_8[7:6] = do_grey(bin_8[8:6]);
	grey_8[8] = bin_8[8];
	bin2grey = grey_8;
end
endfunction
function [AW:0] grey2bin;
input [AW:0] grey;
reg [8:0] grey_8;
reg [8:0] bin_8;
begin
	grey_8 = grey;
	bin_8[8] = grey_8[8];
	bin_8[7:6] = do_bin({bin_8[8], grey_8[7:6]});
	bin_8[5:4] = do_bin({bin_8[6], grey_8[5:4]});
	bin_8[3:2] = do_bin({bin_8[4], grey_8[3:2]});
	bin_8[1:0] = do_bin({bin_8[2], grey_8[1:0]});
	grey2bin = bin_8;
end
endfunction
function [1:0] do_grey;
input [2:0] bin;
begin
	if (bin[2]) begin   
		case (bin[1:0]) 
			2'b00: do_grey = 2'b10;
			2'b01: do_grey = 2'b11;
			2'b10: do_grey = 2'b01;
			2'b11: do_grey = 2'b00;
		endcase
	end
	else begin
		case (bin[1:0]) 
			2'b00: do_grey = 2'b00;
			2'b01: do_grey = 2'b01;
			2'b10: do_grey = 2'b11;
			2'b11: do_grey = 2'b10;
		endcase
	end
end
endfunction
function [1:0] do_bin;
input [2:0] grey;
begin
	if (grey[2]) begin	 
		case (grey[1:0])
			2'b10: do_bin = 2'b00;
			2'b11: do_bin = 2'b01;
			2'b01: do_bin = 2'b10;
			2'b00: do_bin = 2'b11;
		endcase
	end
	else begin
		case (grey[1:0])
			2'b00: do_bin = 2'b00;
			2'b01: do_bin = 2'b01;
			2'b11: do_bin = 2'b10;
			2'b10: do_bin = 2'b11;
		endcase
	end
end
endfunction
function [AW:0] get_cnt;
input [AW:0] wr_ptr, rd_ptr;
begin
	if (wr_ptr >= rd_ptr) begin
		get_cnt = (wr_ptr - rd_ptr);	
	end
	else begin
		get_cnt = DP*2 - (rd_ptr - wr_ptr);
	end
end
endfunction
always @(posedge wr_clk) begin
   if (wr_en && full) begin
      $display($time, "%m Error! afifo overflow!");
      $stop;
   end
end
always @(posedge rd_clk) begin
   if (rd_en && empty) begin
      $display($time, "%m error! afifo underflow!");
      $stop;
   end
end
endmodule
module sdrc_core 
           (
		clk,
                pad_clk,
		reset_n,
                sdr_width,
		cfg_colbits,
		app_req,	         
		app_req_addr,	         
		app_req_len,	         
		app_req_wrap,	         
		app_req_wr_n,	         
		app_req_ack,	         
		cfg_req_depth,	         
		app_wr_data,
                app_wr_en_n,
		app_last_wr,
		app_rd_data,
		app_rd_valid,
		app_last_rd,
		app_wr_next_req,
		sdr_init_done,
		app_req_dma_last,
		sdr_cs_n,
		sdr_cke,
		sdr_ras_n,
		sdr_cas_n,
		sdr_we_n,
		sdr_dqm,
		sdr_ba,
		sdr_addr, 
		pad_sdr_din,
		sdr_dout,
		sdr_den_n,
		cfg_sdr_en,
		cfg_sdr_mode_reg,
		cfg_sdr_tras_d,
		cfg_sdr_trp_d,
		cfg_sdr_trcd_d,
		cfg_sdr_cas,
		cfg_sdr_trcar_d,
		cfg_sdr_twr_d,
		cfg_sdr_rfsh,
		cfg_sdr_rfmax);
parameter  APP_AW   = 26;   
parameter  APP_DW   = 32;   
parameter  APP_BW   = 4;    
parameter  APP_RW   = 9;    
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
input                   clk                 ;  
input                   pad_clk             ;  
input                   reset_n             ;  
input [1:0]             sdr_width           ;  
input [1:0]             cfg_colbits         ;  
input 			app_req             ;  
input [APP_AW-1:0] 	app_req_addr        ;  
input 			app_req_wr_n        ;  
input                   app_req_wrap        ;  
output                  app_req_ack         ;  
input [APP_DW-1:0] 	app_wr_data         ;  
output 		        app_wr_next_req     ;  
input [APP_BW-1:0] 	app_wr_en_n         ;  
output                  app_last_wr         ;  
output [APP_DW-1:0] 	app_rd_data         ;  
output                  app_rd_valid        ;  
output                  app_last_rd         ;  
output                  sdr_cke             ;  
output 			sdr_cs_n            ;  
output                  sdr_ras_n           ;  
output                  sdr_cas_n           ;  
output			sdr_we_n            ;  
output [SDR_BW-1:0] 	sdr_dqm             ;  
output [1:0] 		sdr_ba              ;  
output [12:0] 		sdr_addr            ;  
input [SDR_DW-1:0] 	pad_sdr_din         ;  
output [SDR_DW-1:0] 	sdr_dout            ;  
output [SDR_BW-1:0] 	sdr_den_n           ;  
output                  sdr_init_done       ;  
input [3:0] 		cfg_sdr_tras_d      ;  
input [3:0]             cfg_sdr_trp_d       ;  
input [3:0]             cfg_sdr_trcd_d      ;  
input 			cfg_sdr_en          ;  
input [1:0] 		cfg_req_depth       ;  
input [APP_RW-1:0]	app_req_len         ;  
input [12:0] 		cfg_sdr_mode_reg    ;
input [2:0] 		cfg_sdr_cas         ;  
input [3:0] 		cfg_sdr_trcar_d     ;  
input [3:0]             cfg_sdr_twr_d       ;  
input [12-1 : 0] cfg_sdr_rfsh;
input [3 -1 : 0] cfg_sdr_rfmax;
input                   app_req_dma_last;     
wire [4-1:0]r2b_req_id;
wire [1:0] 		r2b_ba;
wire [12:0] 		r2b_raddr;
wire [12:0] 		r2b_caddr;
wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	r2b_len;
wire [4-1:0]b2x_id;
wire [1:0] 		b2x_ba;
wire [12:0] 		b2x_addr;
wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
wire [1:0] 		b2x_cmd;
wire [3:0] 		x2b_pre_ok;
wire [4-1:0]xfr_id;
wire [APP_DW-1:0] 	app_rd_data;
wire 			sdr_cs_n, sdr_cke, sdr_ras_n, sdr_cas_n, sdr_we_n; 
wire [SDR_BW-1:0] 	sdr_dqm;
wire [1:0] 		sdr_ba;
wire [12:0] 		sdr_addr;
wire [SDR_DW-1:0] 	sdr_dout;
wire [SDR_DW-1:0] 	sdr_dout_int;
wire [SDR_BW-1:0] 	sdr_den_n;
wire [SDR_BW-1:0] 	sdr_den_n_int;
wire [1:0] 		xfr_bank_sel;
wire [APP_AW-1:0]        app_req_addr;
wire [APP_RW-1:0]        app_req_len;
wire [APP_DW-1:0]        app_wr_data;
wire [SDR_DW-1:0]        a2x_wrdt       ;
wire [APP_BW-1:0]        app_wr_en_n;
wire [SDR_BW-1:0]        a2x_wren_n;
wire [SDR_DW-1:0]        x2a_rddt;
   wire [3:0]           sdr_cmd;
   assign sdr_cmd = {sdr_cs_n, sdr_ras_n, sdr_cas_n, sdr_we_n}; 
assign sdr_den_n = sdr_den_n_int ; 
assign sdr_dout  = sdr_dout_int ;
reg [SDR_DW-1:0] pad_sdr_din1;
reg [SDR_DW-1:0] pad_sdr_din2;
always@(posedge pad_clk) begin
   pad_sdr_din1 <= pad_sdr_din;
end
always@(posedge clk) begin
   pad_sdr_din2 <= pad_sdr_din1;
end
sdrc_req_gen #(.SDR_DW(SDR_DW) , .SDR_BW(SDR_BW)) u_req_gen (
          .clk                (clk          ),
          .reset_n            (reset_n            ),
	  .cfg_colbits        (cfg_colbits        ),
          .sdr_width          (sdr_width          ),
          .r2x_idle           (r2x_idle           ),
          .req                (app_req            ),
          .req_id             (4'b0               ),
          .req_addr           (app_req_addr       ),
          .req_len            (app_req_len        ),
          .req_wrap           (app_req_wrap       ),
          .req_wr_n           (app_req_wr_n       ),
          .req_ack            (app_req_ack        ),
          .r2b_req            (r2b_req            ),
          .r2b_req_id         (r2b_req_id         ),
          .r2b_start          (r2b_start          ),
          .r2b_last           (r2b_last           ),
          .r2b_wrap           (r2b_wrap           ),
          .r2b_ba             (r2b_ba             ),
          .r2b_raddr          (r2b_raddr          ),
          .r2b_caddr          (r2b_caddr          ),
          .r2b_len            (r2b_len            ),
          .r2b_write          (r2b_write          ),
          .b2r_ack            (b2r_ack            ),
          .b2r_arb_ok         (b2r_arb_ok         )
     );
sdrc_bank_ctl #(.SDR_DW(SDR_DW) ,  .SDR_BW(SDR_BW)) u_bank_ctl (
          .clk                (clk          ),
          .reset_n            (reset_n            ),
          .a2b_req_depth      (cfg_req_depth      ),
          .r2b_req            (r2b_req            ),
          .r2b_req_id         (r2b_req_id         ),
          .r2b_start          (r2b_start          ),
          .r2b_last           (r2b_last           ),
          .r2b_wrap           (r2b_wrap           ),
          .r2b_ba             (r2b_ba             ),
          .r2b_raddr          (r2b_raddr          ),
          .r2b_caddr          (r2b_caddr          ),
          .r2b_len            (r2b_len            ),
          .r2b_write          (r2b_write          ),
          .b2r_arb_ok         (b2r_arb_ok         ),
          .b2r_ack            (b2r_ack            ),
          .b2x_idle           (b2x_idle           ),
          .b2x_req            (b2x_req            ),
          .b2x_start          (b2x_start          ),
          .b2x_last           (b2x_last           ),
          .b2x_wrap           (b2x_wrap           ),
          .b2x_id             (b2x_id             ),
          .b2x_ba             (b2x_ba             ),
          .b2x_addr           (b2x_addr           ),
          .b2x_len            (b2x_len            ),
          .b2x_cmd            (b2x_cmd            ),
          .x2b_ack            (x2b_ack            ),
          .b2x_tras_ok        (b2x_tras_ok        ),
          .x2b_refresh        (x2b_refresh        ),
          .x2b_pre_ok         (x2b_pre_ok         ),
          .x2b_act_ok         (x2b_act_ok         ),
          .x2b_rdok           (x2b_rdok           ),
          .x2b_wrok           (x2b_wrok           ),
          .sdr_req_norm_dma_last(app_req_dma_last),
          .xfr_bank_sel       (xfr_bank_sel       ),
          .tras_delay         (cfg_sdr_tras_d     ),
          .trp_delay          (cfg_sdr_trp_d      ),
          .trcd_delay         (cfg_sdr_trcd_d     )
      );
sdrc_xfr_ctl #(.SDR_DW(SDR_DW) ,  .SDR_BW(SDR_BW)) u_xfr_ctl (
          .clk                (clk          ),
          .reset_n            (reset_n            ),
          .r2x_idle           (r2x_idle           ),
          .b2x_idle           (b2x_idle           ),
          .b2x_req            (b2x_req            ),
          .b2x_start          (b2x_start          ),
          .b2x_last           (b2x_last           ),
          .b2x_wrap           (b2x_wrap           ),
          .b2x_id             (b2x_id             ),
          .b2x_ba             (b2x_ba             ),
          .b2x_addr           (b2x_addr           ),
          .b2x_len            (b2x_len            ),
          .b2x_cmd            (b2x_cmd            ),
          .x2b_ack            (x2b_ack            ),
          .b2x_tras_ok        (b2x_tras_ok        ),
          .x2b_refresh        (x2b_refresh        ),
          .x2b_pre_ok         (x2b_pre_ok         ),
          .x2b_act_ok         (x2b_act_ok         ),
          .x2b_rdok           (x2b_rdok           ),
          .x2b_wrok           (x2b_wrok           ),
          .sdr_cs_n           (sdr_cs_n           ),
          .sdr_cke            (sdr_cke            ),
          .sdr_ras_n          (sdr_ras_n          ),
          .sdr_cas_n          (sdr_cas_n          ),
          .sdr_we_n           (sdr_we_n           ),
          .sdr_dqm            (sdr_dqm            ),
          .sdr_ba             (sdr_ba             ),
          .sdr_addr           (sdr_addr           ),
          .sdr_din            (pad_sdr_din2       ),
          .sdr_dout           (sdr_dout_int       ),
          .sdr_den_n          (sdr_den_n_int      ),
          .x2a_rdstart        (x2a_rdstart        ),
          .x2a_wrstart        (x2a_wrstart        ),
          .x2a_id             (xfr_id             ),
          .x2a_rdlast         (x2a_rdlast         ),
          .x2a_wrlast         (x2a_wrlast         ),
          .a2x_wrdt           (a2x_wrdt           ),
          .a2x_wren_n         (a2x_wren_n         ),
          .x2a_wrnext         (x2a_wrnext         ),
          .x2a_rddt           (x2a_rddt           ),
          .x2a_rdok           (x2a_rdok           ),
          .sdr_init_done      (sdr_init_done      ),
          .sdram_enable       (cfg_sdr_en         ),
          .sdram_mode_reg     (cfg_sdr_mode_reg   ),
          .xfr_bank_sel       (xfr_bank_sel       ),
          .cas_latency        (cfg_sdr_cas        ),
          .trp_delay          (cfg_sdr_trp_d      ),
          .trcar_delay        (cfg_sdr_trcar_d    ),
          .twr_delay          (cfg_sdr_twr_d      ),
          .rfsh_time          (cfg_sdr_rfsh       ),
          .rfsh_rmax          (cfg_sdr_rfmax      )
    );
sdrc_bs_convert #(.SDR_DW(SDR_DW) ,  .SDR_BW(SDR_BW)) u_bs_convert (
          .clk                (clk          ),
          .reset_n            (reset_n            ),
          .sdr_width          (sdr_width          ),
          .x2a_rdstart        (x2a_rdstart        ),
          .x2a_rdlast         (x2a_rdlast         ),
          .x2a_rdok           (x2a_rdok           ),
          .x2a_rddt           (x2a_rddt           ),
          .x2a_wrstart        (x2a_wrstart        ),
          .x2a_wrlast         (x2a_wrlast         ),
          .x2a_wrnext         (x2a_wrnext         ),
          .a2x_wrdt           (a2x_wrdt           ),
          .a2x_wren_n         (a2x_wren_n         ),
          .app_wr_data        (app_wr_data        ),
          .app_wr_en_n        (app_wr_en_n        ),
          .app_wr_next        (app_wr_next_req    ),
	  .app_last_wr        (app_last_wr        ),
          .app_rd_data        (app_rd_data        ),
          .app_rd_valid       (app_rd_valid       ),
	  .app_last_rd        (app_last_rd        )
       );   
endmodule  
module sdrc_bank_ctl (clk,
		     reset_n,
		     a2b_req_depth,   
		     r2b_req,	    
		     r2b_req_id,    
		     r2b_start,	    
		     r2b_last,	    
		     r2b_wrap,
		     r2b_ba,	    
		     r2b_raddr,	    
		     r2b_caddr,	    
		     r2b_len,	    
		     r2b_write,	    
		     b2r_arb_ok,    
		     b2r_ack,
		     b2x_idle,	    
		     b2x_req,	    
		     b2x_start,	    
		     b2x_last,	    
		     b2x_wrap,
		     b2x_id,	    
		     b2x_ba,	    
		     b2x_addr,	    
		     b2x_len,	    
		     b2x_cmd,	    
		     x2b_ack,	    
		     b2x_tras_ok,   
		     x2b_refresh,   
		     x2b_pre_ok,    
		     x2b_act_ok,    
		     x2b_rdok,	    
		     x2b_wrok,	    
		     xfr_bank_sel,
                     sdr_req_norm_dma_last,
		     tras_delay,    
		     trp_delay,	    
		     trcd_delay);   
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
   input                        clk, reset_n;
   input [1:0] 			a2b_req_depth;
   input 			r2b_req, r2b_start, r2b_last,
				r2b_write, r2b_wrap;
   input [4-1:0] 	r2b_req_id;
   input [1:0] 			r2b_ba;
   input [12:0] 		r2b_raddr;
   input [12:0] 		r2b_caddr;
   input [(1'b0 == 1'b0) ? 6 : 12-1:0] 	        r2b_len;
   output 			b2r_arb_ok, b2r_ack;
   input                        sdr_req_norm_dma_last;
   output 			b2x_idle, b2x_req, b2x_start, b2x_last,
				b2x_tras_ok, b2x_wrap;
   output [4-1:0] 	b2x_id;
   output [1:0] 		b2x_ba;
   output [12:0] 		b2x_addr;
   output [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
   output [1:0] 		b2x_cmd;
   input 			x2b_ack;
   input [3:0] 			x2b_pre_ok;
   input 			x2b_refresh, x2b_act_ok, x2b_rdok,
				x2b_wrok;
   input [3:0] 			tras_delay, trp_delay, trcd_delay;
   input [1:0] xfr_bank_sel;
   wire [3:0] 			r2i_req, i2r_ack, i2x_req, 
				i2x_start, i2x_last, i2x_wrap, tras_ok;
   wire [12:0] 			i2x_addr0, i2x_addr1, i2x_addr2, i2x_addr3;
   wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	i2x_len0, i2x_len1, i2x_len2, i2x_len3;
   wire [1:0] 			i2x_cmd0, i2x_cmd1, i2x_cmd2, i2x_cmd3;
   wire [4-1:0] 	i2x_id0, i2x_id1, i2x_id2, i2x_id3;
   reg 				b2x_req;
   wire 			b2x_idle, b2x_start, b2x_last, b2x_wrap;
   wire [4-1:0] 	b2x_id;
   wire [12:0] 			b2x_addr;
   wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
   wire [1:0] 			b2x_cmd;
   wire [3:0] 			x2i_ack;
   reg [1:0] 			b2x_ba;
   reg [4-1:0] 	curr_id;
   wire [1:0] 			xfr_ba;
   wire  			xfr_ba_last;
   wire [3:0] 			xfr_ok;
   reg [7:0] 			rank_ba;
   reg [3:0] 			rank_ba_last;
   reg [2:0] 			rank_cnt;
   wire [3:0] 			rank_req, rank_wr_sel;
   wire 			rank_fifo_wr, rank_fifo_rd;
   wire 			rank_fifo_full, rank_fifo_mt;
   wire [12:0] bank0_row, bank1_row, bank2_row, bank3_row;
   assign  b2x_tras_ok        = &tras_ok;
   assign r2i_req[0] = (r2b_ba == 2'b00) ? r2b_req & ~rank_fifo_full : 1'b0;
   assign r2i_req[1] = (r2b_ba == 2'b01) ? r2b_req & ~rank_fifo_full : 1'b0;
   assign r2i_req[2] = (r2b_ba == 2'b10) ? r2b_req & ~rank_fifo_full : 1'b0;
   assign r2i_req[3] = (r2b_ba == 2'b11) ? r2b_req & ~rank_fifo_full : 1'b0;
   assign b2r_ack  =|i2r_ack; 
   assign b2r_arb_ok = ~rank_fifo_full;
   assign xfr_ba = (1'b0 == 1'b0) ? rank_ba[1:0]:
	           ((rank_fifo_mt) ? r2b_ba : rank_ba[1:0]);
   assign xfr_ba_last = (1'b0 == 1'b0) ? rank_ba_last[0]:
	                ((rank_fifo_mt) ? sdr_req_norm_dma_last : rank_ba_last[0]);
   assign rank_req[0] = i2x_req[xfr_ba];      
   assign rank_req[1] = (rank_cnt < 3'h2) ? 1'b0 :
			(rank_ba[3:2] == 2'b00) ? i2x_req[0] & ~i2x_cmd0[1] :
			(rank_ba[3:2] == 2'b01) ? i2x_req[1] & ~i2x_cmd1[1] :
			(rank_ba[3:2] == 2'b10) ? i2x_req[2] & ~i2x_cmd2[1] : 
			i2x_req[3] & ~i2x_cmd3[1];
   assign rank_req[2] = (rank_cnt < 3'h3) ? 1'b0 :
			(rank_ba[5:4] == 2'b00) ? i2x_req[0] & ~i2x_cmd0[1] :
			(rank_ba[5:4] == 2'b01) ? i2x_req[1] & ~i2x_cmd1[1] :
			(rank_ba[5:4] == 2'b10) ? i2x_req[2] & ~i2x_cmd2[1] : 
			i2x_req[3] & ~i2x_cmd3[1];
   assign rank_req[3] = (rank_cnt < 3'h4) ? 1'b0 :
			(rank_ba[7:6] == 2'b00) ? i2x_req[0] & ~i2x_cmd0[1] :
			(rank_ba[7:6] == 2'b01) ? i2x_req[1] & ~i2x_cmd1[1] :
			(rank_ba[7:6] == 2'b10) ? i2x_req[2] & ~i2x_cmd2[1] : 
			i2x_req[3] & ~i2x_cmd3[1];
   always @ (*) begin
      b2x_req = 1'b0;
      b2x_ba =   xfr_ba;
      if(1'b0 == 1'b1) begin  
         if (rank_req[0]) begin 
	    b2x_req = 1'b1;
	    b2x_ba = xfr_ba;
         end  
	 else if (rank_req[1]) begin 
	   b2x_req = 1'b1;
	   b2x_ba = rank_ba[3:2];
        end  
        else if (rank_req[2]) begin 
	  b2x_req = 1'b1;
	  b2x_ba = rank_ba[5:4];
        end  
        else if (rank_req[3]) begin 
	  b2x_req = 1'b1;
	  b2x_ba = rank_ba[7:6];
        end  
      end else begin  
         if (rank_req[0]) begin 
	    b2x_req = 1'b1;
	 end
      end
  end  
   assign b2x_idle = rank_fifo_mt;
   assign b2x_start = i2x_start[b2x_ba];
   assign b2x_last = i2x_last[b2x_ba];
   assign b2x_wrap = i2x_wrap[b2x_ba];
   assign b2x_addr = (b2x_ba == 2'b11) ? i2x_addr3 :
		     (b2x_ba == 2'b10) ? i2x_addr2 :
		     (b2x_ba == 2'b01) ? i2x_addr1 : i2x_addr0;
   assign b2x_len = (b2x_ba == 2'b11) ? i2x_len3 :
		    (b2x_ba == 2'b10) ? i2x_len2 :
		    (b2x_ba == 2'b01) ? i2x_len1 : i2x_len0;
   assign b2x_cmd = (b2x_ba == 2'b11) ? i2x_cmd3 :
		    (b2x_ba == 2'b10) ? i2x_cmd2 :
		    (b2x_ba == 2'b01) ? i2x_cmd1 : i2x_cmd0;
   assign b2x_id = (b2x_ba == 2'b11) ? i2x_id3 :
		   (b2x_ba == 2'b10) ? i2x_id2 :
		   (b2x_ba == 2'b01) ? i2x_id1 : i2x_id0;
   assign x2i_ack[0] = (b2x_ba == 2'b00) ? x2b_ack : 1'b0;
   assign x2i_ack[1] = (b2x_ba == 2'b01) ? x2b_ack : 1'b0;
   assign x2i_ack[2] = (b2x_ba == 2'b10) ? x2b_ack : 1'b0;
   assign x2i_ack[3] = (b2x_ba == 2'b11) ? x2b_ack : 1'b0;
   assign rank_fifo_wr = b2r_ack;
   assign rank_fifo_rd = b2x_req & b2x_cmd[1] & x2b_ack;
   assign rank_wr_sel[0] = (rank_cnt == 3'h0) ? rank_fifo_wr : 
			   (rank_cnt == 3'h1) ? rank_fifo_wr & rank_fifo_rd : 
			   1'b0;
   assign rank_wr_sel[1] = (rank_cnt == 3'h1) ? rank_fifo_wr & ~rank_fifo_rd :
			   (rank_cnt == 3'h2) ? rank_fifo_wr & rank_fifo_rd :
			   1'b0; 
   assign rank_wr_sel[2] = (rank_cnt == 3'h2) ? rank_fifo_wr & ~rank_fifo_rd :
			   (rank_cnt == 3'h3) ? rank_fifo_wr & rank_fifo_rd :
			   1'b0; 
   assign rank_wr_sel[3] = (rank_cnt == 3'h3) ? rank_fifo_wr & ~rank_fifo_rd :
			   (rank_cnt == 3'h4) ? rank_fifo_wr & rank_fifo_rd :
			   1'b0; 
   assign rank_fifo_mt = (rank_cnt == 3'b0) ? 1'b1 : 1'b0;
   assign rank_fifo_full = (rank_cnt[2]) ? 1'b1 : 
			   (rank_cnt[1:0] == a2b_req_depth) ? 1'b1 : 1'b0; 
   always @ (posedge clk) begin
      if (~rank_fifo_wr & rank_fifo_rd && rank_cnt == 3'h0) begin
	 $display ("%t: %m: ERROR!!! Read from empty Fifo", $time);
	 $stop;
      end  
      if (rank_fifo_wr && ~rank_fifo_rd && rank_cnt == 3'h4) begin
	 $display ("%t: %m: ERROR!!! Write to full Fifo", $time);
	 $stop;
      end  
   end  
   always @ (posedge clk)
      if (~reset_n) begin
	 rank_cnt <= 3'b0;
	 rank_ba <= 8'b0;
	 rank_ba_last <= 4'b0;
      end  
      else begin
	 rank_cnt <= (rank_fifo_wr & ~rank_fifo_rd) ? rank_cnt + 3'b1 :
		     (~rank_fifo_wr & rank_fifo_rd) ? rank_cnt - 3'b1 :
		     rank_cnt;
	 rank_ba[1:0] <= (rank_wr_sel[0]) ? r2b_ba :
			 (rank_fifo_rd) ? rank_ba[3:2] : rank_ba[1:0];
	 rank_ba[3:2] <= (rank_wr_sel[1]) ? r2b_ba :
			 (rank_fifo_rd) ? rank_ba[5:4] : rank_ba[3:2];
	 rank_ba[5:4] <= (rank_wr_sel[2]) ? r2b_ba :
			 (rank_fifo_rd) ? rank_ba[7:6] : rank_ba[5:4];
	 rank_ba[7:6] <= (rank_wr_sel[3]) ? r2b_ba :
			 (rank_fifo_rd) ? 2'b00 : rank_ba[7:6];
	 if(1'b0 == 1'b1) begin  
            rank_ba_last[0] <= (rank_wr_sel[0]) ? sdr_req_norm_dma_last :
                            (rank_fifo_rd) ?  rank_ba_last[1] : rank_ba_last[0];
            rank_ba_last[1] <= (rank_wr_sel[1]) ? sdr_req_norm_dma_last :
                               (rank_fifo_rd) ?  rank_ba_last[2] : rank_ba_last[1];
            rank_ba_last[2] <= (rank_wr_sel[2]) ? sdr_req_norm_dma_last :
                               (rank_fifo_rd) ?  rank_ba_last[3] : rank_ba_last[2];
            rank_ba_last[3] <= (rank_wr_sel[3]) ? sdr_req_norm_dma_last :
                               (rank_fifo_rd) ?  1'b0 : rank_ba_last[3];
         end
      end  
   assign xfr_ok[0] = (xfr_ba == 2'b00) ? 1'b1 : 1'b0;
   assign xfr_ok[1] = (xfr_ba == 2'b01) ? 1'b1 : 1'b0;
   assign xfr_ok[2] = (xfr_ba == 2'b10) ? 1'b1 : 1'b0;
   assign xfr_ok[3] = (xfr_ba == 2'b11) ? 1'b1 : 1'b0;
   sdrc_bank_fsm bank0_fsm (.clk (clk),
			   .reset_n (reset_n),
			   .r2b_req (r2i_req[0]),
			   .r2b_req_id (r2b_req_id),
			   .r2b_start (r2b_start),
			   .r2b_last (r2b_last),
			   .r2b_wrap (r2b_wrap),
			   .r2b_raddr (r2b_raddr),
			   .r2b_caddr (r2b_caddr),
			   .r2b_len (r2b_len),
			   .r2b_write (r2b_write),
			   .b2r_ack (i2r_ack[0]),
                           .sdr_dma_last(rank_ba_last[0]),
			   .b2x_req (i2x_req[0]),
			   .b2x_start (i2x_start[0]),
			   .b2x_last (i2x_last[0]),
			   .b2x_wrap (i2x_wrap[0]),
			   .b2x_id (i2x_id0),
			   .b2x_addr (i2x_addr0),
			   .b2x_len (i2x_len0),
			   .b2x_cmd (i2x_cmd0),
			   .x2b_ack (x2i_ack[0]),
			   .tras_ok (tras_ok[0]),
			   .xfr_ok (xfr_ok[0]),
			   .x2b_refresh (x2b_refresh),
			   .x2b_pre_ok (x2b_pre_ok[0]),
			   .x2b_act_ok (x2b_act_ok),
			   .x2b_rdok (x2b_rdok),
			   .x2b_wrok (x2b_wrok),
			   .bank_row(bank0_row),
			   .tras_delay (tras_delay),
			   .trp_delay (trp_delay),
			   .trcd_delay (trcd_delay));
   sdrc_bank_fsm bank1_fsm (.clk (clk),
			   .reset_n (reset_n),
			   .r2b_req (r2i_req[1]),
			   .r2b_req_id (r2b_req_id),
			   .r2b_start (r2b_start),
			   .r2b_last (r2b_last),
			   .r2b_wrap (r2b_wrap),
			   .r2b_raddr (r2b_raddr),
			   .r2b_caddr (r2b_caddr),
			   .r2b_len (r2b_len),
			   .r2b_write (r2b_write),
			   .b2r_ack (i2r_ack[1]),
                           .sdr_dma_last(rank_ba_last[1]),
			   .b2x_req (i2x_req[1]),
			   .b2x_start (i2x_start[1]),
			   .b2x_last (i2x_last[1]),
			   .b2x_wrap (i2x_wrap[1]),
			   .b2x_id (i2x_id1),
			   .b2x_addr (i2x_addr1),
			   .b2x_len (i2x_len1),
			   .b2x_cmd (i2x_cmd1),
			   .x2b_ack (x2i_ack[1]),
			   .tras_ok (tras_ok[1]),           
			   .xfr_ok (xfr_ok[1]),
			   .x2b_refresh (x2b_refresh),
			   .x2b_pre_ok (x2b_pre_ok[1]),
			   .x2b_act_ok (x2b_act_ok),
			   .x2b_rdok (x2b_rdok),
			   .x2b_wrok (x2b_wrok),
			   .bank_row(bank1_row),
			   .tras_delay (tras_delay),
			   .trp_delay (trp_delay),
			   .trcd_delay (trcd_delay));
   sdrc_bank_fsm bank2_fsm (.clk (clk),
			   .reset_n (reset_n),
			   .r2b_req (r2i_req[2]),
			   .r2b_req_id (r2b_req_id),
			   .r2b_start (r2b_start),
			   .r2b_last (r2b_last),
			   .r2b_wrap (r2b_wrap),
			   .r2b_raddr (r2b_raddr),
			   .r2b_caddr (r2b_caddr),
			   .r2b_len (r2b_len),
			   .r2b_write (r2b_write),
			   .b2r_ack (i2r_ack[2]),
                           .sdr_dma_last(rank_ba_last[2]),
			   .b2x_req (i2x_req[2]),
			   .b2x_start (i2x_start[2]),
			   .b2x_last (i2x_last[2]),
			   .b2x_wrap (i2x_wrap[2]),
			   .b2x_id (i2x_id2),
			   .b2x_addr (i2x_addr2),
			   .b2x_len (i2x_len2),
			   .b2x_cmd (i2x_cmd2),
			   .x2b_ack (x2i_ack[2]),
			   .tras_ok (tras_ok[2]),           
			   .xfr_ok (xfr_ok[2]),
			   .x2b_refresh (x2b_refresh),
			   .x2b_pre_ok (x2b_pre_ok[2]),
			   .x2b_act_ok (x2b_act_ok),
			   .x2b_rdok (x2b_rdok),
			   .x2b_wrok (x2b_wrok),
			   .bank_row(bank2_row),
			   .tras_delay (tras_delay),
			   .trp_delay (trp_delay),
			   .trcd_delay (trcd_delay));
   sdrc_bank_fsm bank3_fsm (.clk (clk),
			   .reset_n (reset_n),
			   .r2b_req (r2i_req[3]),
			   .r2b_req_id (r2b_req_id),
			   .r2b_start (r2b_start),
			   .r2b_last (r2b_last),
			   .r2b_wrap (r2b_wrap),
			   .r2b_raddr (r2b_raddr),
			   .r2b_caddr (r2b_caddr),
			   .r2b_len (r2b_len),
			   .r2b_write (r2b_write),
			   .b2r_ack (i2r_ack[3]),
                           .sdr_dma_last(rank_ba_last[3]),
			   .b2x_req (i2x_req[3]),
			   .b2x_start (i2x_start[3]),
			   .b2x_last (i2x_last[3]),
			   .b2x_wrap (i2x_wrap[3]),
			   .b2x_id (i2x_id3),
			   .b2x_addr (i2x_addr3),
			   .b2x_len (i2x_len3),
			   .b2x_cmd (i2x_cmd3),
			   .x2b_ack (x2i_ack[3]),
			   .tras_ok (tras_ok[3]),           
			   .xfr_ok (xfr_ok[3]),
			   .x2b_refresh (x2b_refresh),
			   .x2b_pre_ok (x2b_pre_ok[3]),
			   .x2b_act_ok (x2b_act_ok),
			   .x2b_rdok (x2b_rdok),
			   .x2b_wrok (x2b_wrok),
			   .bank_row(bank3_row),
			   .tras_delay (tras_delay),
			   .trp_delay (trp_delay),
			   .trcd_delay (trcd_delay));
wire [12:0] cur_row = (xfr_bank_sel==3) ? bank3_row:
			(xfr_bank_sel==2) ? bank2_row: 
			(xfr_bank_sel==1) ? bank1_row: bank0_row; 
endmodule  
module sdrc_bank_fsm (clk,
		     reset_n,
		     r2b_req,	    
		     r2b_req_id,    
		     r2b_start,	    
		     r2b_last,	    
		     r2b_wrap,
		     r2b_raddr,	    
		     r2b_caddr,	    
		     r2b_len,	    
		     r2b_write,	    
		     b2r_ack,
                     sdr_dma_last,
		     b2x_req,	    
		     b2x_start,	    
		     b2x_last,	    
		     b2x_wrap,
		     b2x_id,	    
		     b2x_addr,	    
		     b2x_len,	    
		     b2x_cmd,	    
		     x2b_ack,	    
		     tras_ok,       
		     xfr_ok,
		     x2b_refresh,   
		     x2b_pre_ok,    
		     x2b_act_ok,    
		     x2b_rdok,	    
		     x2b_wrok,	    
		     bank_row,
		     tras_delay,    
		     trp_delay,	    
		     trcd_delay);   
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
   input                        clk, reset_n;
   input 			r2b_req, r2b_start, r2b_last,
				r2b_write, r2b_wrap;
   input [4-1:0] 	r2b_req_id;
   input [12:0] 		r2b_raddr;
   input [12:0] 		r2b_caddr;
   input [(1'b0 == 1'b0) ? 6 : 12-1:0] 	r2b_len;
   output 			b2r_ack;
   input                        sdr_dma_last;
   output 			b2x_req, b2x_start, b2x_last,
				tras_ok, b2x_wrap;
   output [4-1:0] 	b2x_id;
   output [12:0] 		b2x_addr;
   output [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
   output [1:0] 		b2x_cmd;
   input 			x2b_ack;
   input 			x2b_refresh, x2b_act_ok, x2b_rdok,
				x2b_wrok, x2b_pre_ok, xfr_ok;
   input [3:0] 			tras_delay, trp_delay, trcd_delay;
   output [12:0] 			bank_row;
   reg [2:0] 			bank_st, next_bank_st;
   wire 			b2x_start, b2x_last;
   reg 				l_start, l_last;
   reg 				b2x_req, b2r_ack;
   wire [4-1:0] 	b2x_id;
   reg [4-1:0] 	l_id;
   reg [12:0] 			b2x_addr;
   reg [(1'b0 == 1'b0) ? 6 : 12-1:0] 	l_len;
   wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
   reg [1:0] 			b2x_cmd_t;
   reg  			bank_valid;
   reg [12:0] 			bank_row;
   reg [3:0] 			tras_cntr, timer0;
   reg 				l_wrap, l_write;
   wire 			b2x_wrap;
   reg [12:0] 			l_raddr;
   reg [12:0] 			l_caddr;
   reg                          l_sdr_dma_last;
   reg                          bank_prech_page_closed;
   wire  			tras_ok_internal, tras_ok, activate_bank;
   wire 			page_hit, timer0_tc_t, ld_trp, ld_trcd;
   reg	x2b_wrok_r, xfr_ok_r , x2b_rdok_r;
   reg [1:0] b2x_cmd_r,timer0_tc_r,tras_ok_r,x2b_pre_ok_r,x2b_act_ok_r;
   always @ (posedge clk)
      if (~reset_n) begin
	 x2b_wrok_r <= 1'b0;
	 xfr_ok_r   <= 1'b0;
	 x2b_rdok_r <= 1'b0;
	 b2x_cmd_r  <= 2'b0;
	 timer0_tc_r  <= 1'b0;
	 tras_ok_r    <= 1'b0;
	 x2b_pre_ok_r <= 1'b0;
	 x2b_act_ok_r <= 1'b0;
      end
      else begin
	 x2b_wrok_r <= x2b_wrok;
	 xfr_ok_r   <= xfr_ok;
	 x2b_rdok_r <= x2b_rdok;
	 b2x_cmd_r  <= b2x_cmd_t;
	 timer0_tc_r <= (ld_trp | ld_trcd) ? 1'b0 : timer0_tc_t;
	 tras_ok_r   <= tras_ok_internal;
	 x2b_pre_ok_r  <= x2b_pre_ok;
	 x2b_act_ok_r  <= x2b_act_ok;
      end
 wire  x2b_wrok_t     = (1'b0 == 1'b0) ? x2b_wrok_r : x2b_wrok;
 wire  xfr_ok_t       = (1'b0 == 1'b0) ? xfr_ok_r : xfr_ok;
 wire  x2b_rdok_t     = (1'b0 == 1'b0) ? x2b_rdok_r : x2b_rdok;
 wire [1:0] b2x_cmd   = (1'b0 == 1'b0) ? b2x_cmd_r : b2x_cmd_t;
 wire  timer0_tc      = (1'b0 == 1'b0) ? timer0_tc_r : timer0_tc_t;
 assign  tras_ok      = (1'b0 == 1'b0) ? tras_ok_r : tras_ok_internal;
 wire  x2b_pre_ok_t   = (1'b0 == 1'b0) ? x2b_pre_ok_r : x2b_pre_ok;
 wire  x2b_act_ok_t   = (1'b0 == 1'b0) ? x2b_act_ok_r : x2b_act_ok;
   always @ (posedge clk)
      if (~reset_n) begin
	 bank_valid <= 1'b0;
	 tras_cntr <= 4'b0;
	 timer0 <= 4'b0;
	 bank_st <= 3'b000;
      end  
      else begin
	 bank_valid <= (x2b_refresh || bank_prech_page_closed) ? 1'b0 :   
		       (activate_bank) ? 1'b1 : bank_valid;
	 tras_cntr <= (activate_bank) ? tras_delay :
		      (~tras_ok_internal) ? tras_cntr - 4'b1 : 4'b0;
	 timer0 <= (ld_trp) ? trp_delay :
		   (ld_trcd) ? trcd_delay :
		   (timer0 != 'h0) ? timer0 - 4'b1 : timer0;
	 bank_st <= next_bank_st;
      end  
   always @ (posedge clk) begin 
      bank_row <= (bank_st == 3'b010) ? b2x_addr : bank_row;
      if (~reset_n) begin
	 l_start <= 1'b0;
	 l_last <= 1'b0;
	 l_id <= 1'b0;
	 l_len <= 1'b0;
	 l_wrap <= 1'b0;
	 l_write <= 1'b0;
	 l_raddr <= 1'b0;
	 l_caddr <= 1'b0;
         l_sdr_dma_last <= 1'b0;
      end
      else begin
        if (b2r_ack) begin
  	   l_start <= r2b_start;
  	   l_last <= r2b_last;
  	   l_id <= r2b_req_id;
  	   l_len <= r2b_len;
  	   l_wrap <= r2b_wrap;
  	   l_write <= r2b_write;
  	   l_raddr <= r2b_raddr;
  	   l_caddr <= r2b_caddr;
           l_sdr_dma_last <= sdr_dma_last;
        end  
      end
   end  
   assign tras_ok_internal = ~|tras_cntr;
   assign activate_bank = (b2x_cmd == 2'b01) & x2b_ack;
   assign page_hit = (r2b_raddr == bank_row) ? bank_valid : 1'b0;     
   assign timer0_tc_t = ~|timer0;
   assign ld_trp = (b2x_cmd == 2'b00) ? x2b_ack : 1'b0;
   assign ld_trcd = (b2x_cmd == 2'b01) ? x2b_ack : 1'b0;
   always @ (*) begin
       bank_prech_page_closed = 1'b0;
       b2x_req = 1'b0;
       b2x_cmd_t = 2'bx;
       b2r_ack = 1'b0;
       b2x_addr = 13'bx;
       next_bank_st = bank_st;
      case (bank_st)
	3'b000 : begin
		if(1'b0 == 1'b0) begin  
	             if (~r2b_req) begin
	                next_bank_st = 3'b000;
	             end  
	             else if (page_hit) begin 
	                b2r_ack = 1'b1;
	                b2x_cmd_t = (r2b_write) ? 2'b11 : 2'b10;
	                next_bank_st = 3'b011;  
	             end  
	             else begin   
	                b2r_ack = 1'b1;
	                b2x_cmd_t = 2'b00;
	                next_bank_st = 3'b001;   
	             end  
		end else begin  
	             if (~r2b_req) begin
                        bank_prech_page_closed = 1'b0;
	                b2x_req = 1'b0;
	                b2x_cmd_t = 2'bx;
	                b2r_ack = 1'b0;
	                b2x_addr = 13'bx;
	                next_bank_st = 3'b000;
	             end  
	             else if (page_hit) begin 
	                b2x_req = (r2b_write) ? x2b_wrok_t & xfr_ok_t : 
			                       x2b_rdok_t & xfr_ok_t;
	                b2x_cmd_t = (r2b_write) ? 2'b11 : 2'b10;
	                b2r_ack = 1'b1;
	                b2x_addr = r2b_caddr;
	                next_bank_st = (x2b_ack) ? 3'b000 : 3'b011;   
	             end  
	             else begin   
	                b2x_req = tras_ok & x2b_pre_ok_t;
	                b2x_cmd_t = 2'b00;
	                b2r_ack = 1'b1;
	                b2x_addr = r2b_raddr & 13'hBFF;	    
	                next_bank_st = (l_sdr_dma_last) ? 3'b001 : (x2b_ack) ? 3'b010 : 3'b001;   
	             end  
	        end
	end  
	3'b001 : begin
	   b2x_req = tras_ok & x2b_pre_ok_t;
	   b2x_cmd_t = 2'b00;
	   b2r_ack = 1'b0;
	   b2x_addr = l_raddr & 13'hBFF;	    
           bank_prech_page_closed = 1'b0;
	   next_bank_st = (x2b_ack) ? 3'b010 : 3'b001;
	end  
	3'b010 : begin
	   b2x_req = timer0_tc & x2b_act_ok_t;
	   b2x_cmd_t = 2'b01;
	   b2r_ack = 1'b0;
	   b2x_addr = l_raddr;
           bank_prech_page_closed = 1'b0;
	   next_bank_st = (x2b_ack) ? 3'b011 : 3'b010;
	end  
	3'b011 : begin
	   b2x_req = (l_write) ? timer0_tc & x2b_wrok_t & xfr_ok_t :
		     timer0_tc & x2b_rdok_t & xfr_ok_t; 
	   b2x_cmd_t = (l_write) ? 2'b11 : 2'b10;
	   b2r_ack = 1'b0;
	   b2x_addr = l_caddr;
           bank_prech_page_closed = 1'b0;
	   next_bank_st = (x2b_refresh) ? 3'b010 : 
                          (x2b_ack & l_sdr_dma_last) ? 3'b100 :
			  (x2b_ack) ? 3'b000 : 3'b011;
	end  
        3'b100 : begin
	   b2x_req = tras_ok & x2b_pre_ok_t;
	   b2x_cmd_t = 2'b00;
	   b2r_ack = 1'b0;
	   b2x_addr = l_raddr & 13'hBFF;	    
           bank_prech_page_closed = 1'b1;
	   next_bank_st = (x2b_ack) ? 3'b000 : 3'b100;
	end  
      endcase  
   end  
   assign b2x_start = (bank_st == 3'b000) ? r2b_start : l_start;
   assign b2x_last = (bank_st == 3'b000) ? r2b_last : l_last;
   assign b2x_id = (bank_st == 3'b000) ? r2b_req_id : l_id;
   assign b2x_len = (bank_st == 3'b000) ? r2b_len : l_len;
   assign b2x_wrap = (bank_st == 3'b000) ? r2b_wrap : l_wrap;
endmodule  
module sdrc_bs_convert (
                    clk                 ,
                    reset_n             ,
                    sdr_width           ,
                    x2a_rdstart         ,
                    x2a_wrstart         ,
                    x2a_rdlast          ,
                    x2a_wrlast          ,
                    x2a_rddt            ,
                    x2a_rdok            ,
                    a2x_wrdt            ,
                    a2x_wren_n          ,
                    x2a_wrnext          ,
                    app_wr_data         ,
                    app_wr_en_n         ,
                    app_wr_next         ,
                    app_last_wr         ,
                    app_rd_data         ,
                    app_rd_valid        ,
		    app_last_rd
		);
parameter  APP_AW   = 30;   
parameter  APP_DW   = 32;   
parameter  APP_BW   = 4;    
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
input                    clk              ;
input                    reset_n          ;
input [1:0]              sdr_width        ;  
input                    x2a_rdstart      ;  
input                    x2a_rdlast       ;  
input [SDR_DW-1:0]       x2a_rddt         ;
input                    x2a_rdok         ;
input                    x2a_wrstart      ;  
input                    x2a_wrlast       ;  
input                    x2a_wrnext       ;
output [SDR_DW-1:0]      a2x_wrdt         ;
output [SDR_BW-1:0]      a2x_wren_n       ;
input  [APP_DW-1:0]      app_wr_data      ;
input  [APP_BW-1:0]      app_wr_en_n      ;
output                   app_wr_next      ;
output                   app_last_wr      ;  
output [APP_DW-1:0]      app_rd_data      ;
output                   app_rd_valid     ;
output                   app_last_rd      ;  
reg [APP_DW-1:0]         app_rd_data      ;
reg                      app_rd_valid     ;
reg [SDR_DW-1:0]         a2x_wrdt         ;
reg [SDR_BW-1:0]         a2x_wren_n       ;
reg                      app_wr_next      ;
reg [23:0]               saved_rd_data    ;
reg [1:0]                rd_xfr_count     ;
reg [1:0]                wr_xfr_count     ;
assign  app_last_wr = x2a_wrlast;
assign  app_last_rd = x2a_rdlast;
always @(*) begin
        if(sdr_width == 2'b00)  
          begin
            a2x_wrdt             = app_wr_data;
            a2x_wren_n           = app_wr_en_n;
            app_wr_next          = x2a_wrnext;
            app_rd_data          = x2a_rddt;
            app_rd_valid         = x2a_rdok;
          end
        else if(sdr_width == 2'b01)  
        begin
            app_wr_next          = (x2a_wrnext & wr_xfr_count[0]);
            app_rd_valid         = (x2a_rdok & rd_xfr_count[0]);
            if(wr_xfr_count[0] == 1'b1)
              begin
                a2x_wren_n      = app_wr_en_n[3:2];
                a2x_wrdt        = app_wr_data[31:16];
              end
            else
              begin
                a2x_wren_n      = app_wr_en_n[1:0];
                a2x_wrdt        = app_wr_data[15:0];
              end
            app_rd_data = {x2a_rddt,saved_rd_data[15:0]};
        end else   
        begin
            app_wr_next         = (x2a_wrnext & (wr_xfr_count[1:0]== 2'b11));
            app_rd_valid        = (x2a_rdok &   (rd_xfr_count[1:0]== 2'b11));
            if(wr_xfr_count[1:0] == 2'b11)
            begin
                a2x_wren_n      = app_wr_en_n[3];
                a2x_wrdt        = app_wr_data[31:24];
            end
            else if(wr_xfr_count[1:0] == 2'b10)
            begin
                a2x_wren_n      = app_wr_en_n[2];
                a2x_wrdt        = app_wr_data[23:16];
            end
            else if(wr_xfr_count[1:0] == 2'b01)
            begin
                a2x_wren_n      = app_wr_en_n[1];
                a2x_wrdt        = app_wr_data[15:8];
            end
            else begin
                a2x_wren_n      = app_wr_en_n[0];
                a2x_wrdt        = app_wr_data[7:0];
            end
            app_rd_data         = {x2a_rddt,saved_rd_data[23:0]};
          end
     end
always @(posedge clk)
  begin
    if(!reset_n)
      begin
        rd_xfr_count    <= 8'b0;
        wr_xfr_count    <= 8'b0;
	saved_rd_data   <= 24'h0;
      end
    else begin
        if(x2a_wrlast) begin
           wr_xfr_count    <= 0;
        end
        else if(x2a_wrnext) begin
           wr_xfr_count <= wr_xfr_count + 1'b1;
        end
        if(x2a_rdlast) begin
           rd_xfr_count    <= 0;
        end
        else if(x2a_rdok) begin
           rd_xfr_count   <= rd_xfr_count + 1'b1;
	end
        if(x2a_rdok) begin
	   if(sdr_width == 2'b01)  
	      saved_rd_data[15:0]  <= x2a_rddt;
            else begin 
	       if(rd_xfr_count[1:0] == 2'b00)      saved_rd_data[7:0]   <= x2a_rddt[7:0];
	       else if(rd_xfr_count[1:0] == 2'b01) saved_rd_data[15:8]  <= x2a_rddt[7:0];
	       else if(rd_xfr_count[1:0] == 2'b10) saved_rd_data[23:16] <= x2a_rddt[7:0];
	    end
        end
    end
end
endmodule  
module sdrc_req_gen (clk,
		    reset_n,
		    cfg_colbits,
		    sdr_width,
		    req,	         
		    req_id,	         
		    req_addr,	         
		    req_len,	         
		    req_wrap,	         
		    req_wr_n,	         
		    req_ack,	         
		    r2x_idle,
		    r2b_req,	         
		    r2b_req_id,	         
		    r2b_start,	         
		    r2b_last,	         
		    r2b_wrap,	         
		    r2b_ba,	         
		    r2b_raddr,	         
		    r2b_caddr,	         
		    r2b_len,	         
		    r2b_write,	         
		    b2r_ack,
		    b2r_arb_ok
		    );
parameter  APP_AW   = 26;   
parameter  APP_DW   = 32;   
parameter  APP_BW   = 4;    
parameter  APP_RW   = 9;    
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
input                   clk           ;
input                   reset_n       ;
input [1:0]             cfg_colbits   ;  
input 			req           ;  
input [4-1:0] req_id      ;  
input [APP_AW-1:0] 	req_addr      ;  
input [APP_RW-1:0] 	req_len       ;  
input 			req_wr_n      ;  
input                   req_wrap      ;  
output 			req_ack       ;  
output 			r2x_idle      ; 
output                  r2b_req       ;  
output                  r2b_start     ;  
output                  r2b_last      ;  
output                  r2b_write     ;  
output                  r2b_wrap      ;  
output [4-1:0] 	r2b_req_id;
output [1:0] 		r2b_ba        ;  
output [12:0] 		r2b_raddr     ;  
output [12:0] 		r2b_caddr     ;  
output [(1'b0 == 1'b0) ? 6 : 12-1:0] 	r2b_len       ;  
input 			b2r_ack       ;  
input                   b2r_arb_ok    ;  
input [1:0] 	        sdr_width;  
   reg  [1:0]		req_st, next_req_st;
   reg 			r2x_idle, req_ack, r2b_req, r2b_start, 
			r2b_write, req_idle, req_ld, lcl_wrap;
   reg [4-1:0] 	r2b_req_id;
   reg [(1'b0 == 1'b0) ? 6 : 12-1:0] 	lcl_req_len;
   wire 		r2b_last, page_ovflw;
   reg page_ovflw_r;
   wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	r2b_len, next_req_len;
   wire [12:0] 	        max_r2b_len;
   reg  [12:0] 	        max_r2b_len_r;
   reg [1:0] 		r2b_ba;
   reg [12:0] 		r2b_raddr;
   reg [12:0] 		r2b_caddr;
   reg [APP_AW-1:0] 	curr_sdr_addr ;
   wire [APP_AW-1:0] 	next_sdr_addr ;
reg [APP_AW:0]           req_addr_int;
reg [APP_RW-1:0]         req_len_int;
always @(*) begin
   if(sdr_width == 2'b00) begin  
      req_addr_int     = {1'b0,req_addr};
      req_len_int      = req_len;
   end else if(sdr_width == 2'b01) begin  
      req_addr_int     = {req_addr,1'b0};
      req_len_int      = {req_len,1'b0};
   end else  begin  
      req_addr_int    = {req_addr,2'b0};
      req_len_int     = {req_len,2'b0};
   end
end
   assign max_r2b_len = (cfg_colbits == 2'b00) ? (12'h100 - {4'b0, req_addr_int[7:0]}) :
	                (cfg_colbits == 2'b01) ? (12'h200 - {3'b0, req_addr_int[8:0]}) :
			(cfg_colbits == 2'b10) ? (12'h400 - {2'b0, req_addr_int[9:0]}) : (12'h800 - {1'b0, req_addr_int[10:0]});
   assign page_ovflw = ({1'b0, req_len_int} > max_r2b_len) ? ~r2b_wrap : 1'b0;
   assign r2b_len = r2b_start ? ((page_ovflw_r) ? max_r2b_len_r : lcl_req_len) :
                      lcl_req_len;
   assign next_req_len = lcl_req_len - r2b_len;
   assign next_sdr_addr = curr_sdr_addr + r2b_len;
   assign r2b_wrap = lcl_wrap;
   assign r2b_last = (r2b_start & !page_ovflw_r) | (req_st == 2'b10);
   always @ (posedge clk) begin
      page_ovflw_r   <= (req_ack) ? page_ovflw: 'h0;
      max_r2b_len_r  <= (req_ack) ? max_r2b_len: 'h0;
      r2b_start      <= (req_ack) ? 1'b1 :
		        (b2r_ack) ? 1'b0 : r2b_start;
      r2b_write      <= (req_ack) ? ~req_wr_n : r2b_write;
      r2b_req_id     <= (req_ack) ? req_id : r2b_req_id;
      lcl_wrap       <= (req_ack) ? req_wrap : lcl_wrap;
      lcl_req_len    <= (req_ack) ? req_len_int  :
		        (req_ld) ? next_req_len : lcl_req_len;
      curr_sdr_addr  <= (req_ack) ? req_addr_int :
		        (req_ld) ? next_sdr_addr : curr_sdr_addr;
   end  
   always @ (*) begin
      r2x_idle    = 1'b0;
      req_idle    = 1'b0;
      req_ack     = 1'b0;
      req_ld      = 1'b0;
      r2b_req     = 1'b0;
      next_req_st = 2'b00;
      case (req_st)       
	2'b00 : begin
	   r2x_idle = ~req;
	   req_idle = 1'b1;
	   req_ack = req & b2r_arb_ok;
	   req_ld = 1'b0;
	   r2b_req = 1'b0;
	   next_req_st = (req & b2r_arb_ok) ? 2'b01 : 2'b00;
	end  
	2'b01 : begin
	   r2x_idle = 1'b0;
	   req_idle = 1'b0;
	   req_ack = 1'b0;
	   req_ld = b2r_ack;
	   r2b_req = 1'b1;                        
	   next_req_st = (b2r_ack ) ? ((page_ovflw_r) ? 2'b10 :2'b00) : 2'b01;
	end  
	2'b10 : begin
	   r2x_idle = 1'b0;
	   req_idle = 1'b0;
	   req_ack  = 1'b0;
	   req_ld = b2r_ack;
	   r2b_req = 1'b1;                        
	   next_req_st = (b2r_ack) ? 2'b00 : 2'b10;
	end  
      endcase  
   end  
   always @ (posedge clk)
      if (~reset_n) begin
	 req_st <= 2'b00;
      end  
      else begin
	 req_st <= next_req_st;
      end  
wire [APP_AW-1:0] 	map_address ;
assign      map_address  = (req_ack) ? req_addr_int :
		           (req_ld)  ? next_sdr_addr : curr_sdr_addr;
always @ (posedge clk) begin
    r2b_ba <= (cfg_colbits == 2'b00) ? {map_address[9:8]}   :
	      (cfg_colbits == 2'b01) ? {map_address[10:9]}  :
	      (cfg_colbits == 2'b10) ? {map_address[11:10]} : map_address[12:11];
    r2b_caddr <= (cfg_colbits == 2'b00) ? {5'b0, map_address[7:0]} :
	         (cfg_colbits == 2'b01) ? {4'b0, map_address[8:0]} :
	         (cfg_colbits == 2'b10) ? {3'b0, map_address[9:0]} : {2'b0, map_address[10:0]};
    r2b_raddr <= (cfg_colbits == 2'b00)  ? map_address[22:10] :
	         (cfg_colbits == 2'b01)  ? map_address[23:11] :
	         (cfg_colbits == 2'b10)  ? map_address[24:12] : map_address[25:13];
end	   
endmodule  
module sdrc_xfr_ctl (clk,
		    reset_n,
		    r2x_idle,	    
		    b2x_idle,       
		    b2x_req,	    
		    b2x_start,	    
		    b2x_last,	    
		    b2x_id,	    
		    b2x_ba,	    
		    b2x_addr,	    
		    b2x_len,	    
		    b2x_cmd,	    
		    b2x_wrap,	    
		    x2b_ack,	    
		    b2x_tras_ok,    
		    x2b_refresh,    
		    x2b_pre_ok,	    
		    x2b_act_ok,	    
		    x2b_rdok,	    
		    x2b_wrok,	    
		    sdr_cs_n,
		    sdr_cke,
		    sdr_ras_n,
		    sdr_cas_n,
		    sdr_we_n,
		    sdr_dqm,
		    sdr_ba,
		    sdr_addr, 
		    sdr_din,
		    sdr_dout,
		    sdr_den_n,
		    x2a_rdstart,
		    x2a_wrstart,
		    x2a_rdlast,
		    x2a_wrlast,
		    x2a_id,
		    a2x_wrdt,
		    a2x_wren_n,
		    x2a_wrnext,
		    x2a_rddt,
		    x2a_rdok,
		    sdr_init_done,
		    sdram_enable,
		    sdram_mode_reg,
		    xfr_bank_sel,
		    cas_latency,
		    trp_delay,	    
		    trcar_delay,    
		    twr_delay,	    
		    rfsh_time,	    
		    rfsh_rmax);	    
parameter  SDR_DW   = 16;   
parameter  SDR_BW   = 2;    
input            clk, reset_n; 
input 			b2x_req, b2x_start, b2x_last, b2x_tras_ok,
				b2x_wrap, r2x_idle, b2x_idle; 
input [4-1:0] 	b2x_id;
input [1:0] 			b2x_ba;
input [12:0] 		b2x_addr;
input [(1'b0 == 1'b0) ? 6 : 12-1:0] 	b2x_len;
input [1:0] 			b2x_cmd;
output 			x2b_ack;
output [3:0] 		x2b_pre_ok;
output 			x2b_refresh, x2b_act_ok, x2b_rdok,
				x2b_wrok;
output 			x2a_rdstart, x2a_wrstart, x2a_rdlast, x2a_wrlast;
output [4-1:0] 	x2a_id;
input [SDR_DW-1:0] 	a2x_wrdt;
input [SDR_BW-1:0] 	a2x_wren_n;
output [SDR_DW-1:0] 	x2a_rddt;
output 			x2a_wrnext, x2a_rdok, sdr_init_done;
output 			sdr_cs_n, sdr_cke, sdr_ras_n, sdr_cas_n,
				sdr_we_n; 
output [SDR_BW-1:0] 	sdr_dqm;
output [1:0] 		sdr_ba;
output [12:0] 		sdr_addr;
input [SDR_DW-1:0] 	sdr_din;
output [SDR_DW-1:0] 	sdr_dout;
output [SDR_BW-1:0] 	sdr_den_n;
   output [1:0]			xfr_bank_sel;
   input 			sdram_enable;
   input [12:0] 		sdram_mode_reg;
   input [2:0] 			cas_latency;
   input [3:0] 			trp_delay, trcar_delay, twr_delay;
   input [12-1 : 0] rfsh_time;
   input [3-1:0] rfsh_rmax;
   reg [1:0] 			xfr_st, next_xfr_st;
   reg [12:0] 			xfr_caddr;
   wire 			last_burst;
   wire 			x2a_rdstart, x2a_wrstart, x2a_rdlast, x2a_wrlast;
   reg 				l_start, l_last, l_wrap;
   wire [4-1:0] 	x2a_id;
   reg [4-1:0] 	l_id;
   wire [1:0] 			xfr_ba;
   reg [1:0] 			l_ba;
   wire [12:0] 			xfr_addr;
   wire [(1'b0 == 1'b0) ? 6 : 12-1:0] 	xfr_len, next_xfr_len;
   reg [(1'b0 == 1'b0) ? 6 : 12-1:0] 	l_len;
   reg 				mgmt_idle, mgmt_req;
   reg [3:0] 			mgmt_cmd;
   reg [12:0] 			mgmt_addr;
   reg [1:0] 			mgmt_ba;
   reg 				sel_mgmt, sel_b2x;
   reg 				cb_pre_ok, rdok, wrok, wr_next,
				rd_next, sdr_init_done, act_cmd, d_act_cmd;
   wire [3:0] 			b2x_sdr_cmd, xfr_cmd;
   reg [3:0] 			i_xfr_cmd;
   wire 			mgmt_ack, x2b_ack, b2x_read, b2x_write, 
				b2x_prechg, d_rd_next, dt_next, xfr_end,
				rd_pipe_mt, ld_xfr, rd_last, d_rd_last, 
				wr_last, l_xfr_end, rd_start, d_rd_start,
				wr_start, page_hit, burst_bdry, xfr_wrap,
				b2x_prechg_hit;
   reg [6:0] 			l_rd_next, l_rd_start, l_rd_last;
   assign b2x_read = (b2x_cmd == 2'b10) ? 1'b1 : 1'b0;
   assign b2x_write = (b2x_cmd == 2'b11) ? 1'b1 : 1'b0;
   assign b2x_prechg = (b2x_cmd == 2'b00) ? 1'b1 : 1'b0;
   assign b2x_sdr_cmd = (b2x_cmd == 2'b00) ? 4'b0010 :
			(b2x_cmd == 2'b01) ? 4'b0011 :
			(b2x_cmd == 2'b10) ? 4'b0101 :
			(b2x_cmd == 2'b11) ? 4'b0100 : 4'b1111;
   assign page_hit = (b2x_ba == l_ba) ? 1'b1 : 1'b0;
   assign b2x_prechg_hit = b2x_prechg & page_hit;
   assign xfr_cmd = (sel_mgmt) ? mgmt_cmd :
		    (sel_b2x) ? b2x_sdr_cmd : i_xfr_cmd;
   assign xfr_addr = (sel_mgmt) ? mgmt_addr : 
		     (sel_b2x) ? b2x_addr : xfr_caddr+1;
   assign mgmt_ack = sel_mgmt;
   assign x2b_ack = sel_b2x;
   assign ld_xfr = sel_b2x & (b2x_read | b2x_write);
   assign xfr_len = (ld_xfr) ? b2x_len : l_len;
   assign next_xfr_len = (ld_xfr) ? b2x_len : 
	                 (l_xfr_end) ? l_len:  l_len - 1;
   assign d_rd_next = (cas_latency == 3'b001) ? l_rd_next[2] :
		      (cas_latency == 3'b010) ? l_rd_next[3] :
		      (cas_latency == 3'b011) ? l_rd_next[4] :
		      (cas_latency == 3'b100) ? l_rd_next[5] :
		      l_rd_next[6];
   assign d_rd_last = (cas_latency == 3'b001) ? l_rd_last[2] :
		      (cas_latency == 3'b010) ? l_rd_last[3] :
		      (cas_latency == 3'b011) ? l_rd_last[4] :
		      (cas_latency == 3'b100) ? l_rd_last[5] :
		      l_rd_last[6];
   assign d_rd_start = (cas_latency == 3'b001) ? l_rd_start[2] :
		       (cas_latency == 3'b010) ? l_rd_start[3] :
		       (cas_latency == 3'b011) ? l_rd_start[4] :
		       (cas_latency == 3'b100) ? l_rd_start[5] :
		       l_rd_start[6];
   assign rd_pipe_mt = (cas_latency == 3'b001) ? ~|l_rd_next[1:0] :
		       (cas_latency == 3'b010) ? ~|l_rd_next[2:0] :
		       (cas_latency == 3'b011) ? ~|l_rd_next[3:0] :
		       (cas_latency == 3'b100) ? ~|l_rd_next[4:0] :
		       ~|l_rd_next[5:0];
   assign dt_next = wr_next | d_rd_next;
   assign xfr_end = ~|xfr_len;
   assign l_xfr_end = ~|(l_len-1);
   assign rd_start = ld_xfr & b2x_read & b2x_start;
   assign wr_start = ld_xfr & b2x_write & b2x_start;
   assign rd_last = rd_next & last_burst & ~|xfr_len[(1'b0 == 1'b0) ? 6 : 12-1:1];
   assign wr_last = last_burst & ~|xfr_len[(1'b0 == 1'b0) ? 6 : 12-1:1];
   assign xfr_ba = (sel_mgmt) ? mgmt_ba : 
		   (sel_b2x) ? b2x_ba : l_ba;
   assign xfr_wrap = (ld_xfr) ? b2x_wrap : l_wrap;
   wire [1:0] xfr_caddr_lsb = (xfr_caddr[1:0]+1);
   assign burst_bdry = ~|(xfr_caddr_lsb[1:0]);
   always @ (posedge clk) begin
      if (~reset_n) begin
	 xfr_caddr <= 13'b0;
	 l_start <= 1'b0;
	 l_last <= 1'b0;
	 l_wrap <= 1'b0;
	 l_id <= 0;
	 l_ba <= 0;
	 l_len <= 0;
	 l_rd_next <= 7'b0;
	 l_rd_start <= 7'b0;
	 l_rd_last <= 7'b0;
	 act_cmd <= 1'b0;
	 d_act_cmd <= 1'b0;
	 xfr_st <= 2'b00;
      end  
      else begin
	 xfr_caddr <= (ld_xfr) ? b2x_addr :
		      (rd_next | wr_next) ? xfr_caddr + 1 : xfr_caddr; 
	 l_start <= (dt_next) ? 1'b0 : 
		   (ld_xfr) ? b2x_start : l_start;
	 l_last <= (ld_xfr) ? b2x_last : l_last;
	 l_wrap <= (ld_xfr) ? b2x_wrap : l_wrap;
	 l_id <= (ld_xfr) ? b2x_id : l_id;
	 l_ba <= (ld_xfr) ? b2x_ba : l_ba;
	 l_len <= next_xfr_len;
	 l_rd_next <= {l_rd_next[5:0], rd_next};
	 l_rd_start <= {l_rd_start[5:0], rd_start};
	 l_rd_last <= {l_rd_last[5:0], rd_last};
	 act_cmd <= (xfr_cmd == 4'b0011) ? 1'b1 : 1'b0;
	 d_act_cmd <= act_cmd;
	 xfr_st <= next_xfr_st;
      end  
   end  
   always @ (*) begin 
      case (xfr_st)
	2'b00 : begin
	   sel_mgmt = mgmt_req;
	   sel_b2x = ~mgmt_req & sdr_init_done & b2x_req;
	   i_xfr_cmd = 4'b1111;
	   rd_next = ~mgmt_req & sdr_init_done & b2x_req & b2x_read;
	   wr_next = ~mgmt_req & sdr_init_done & b2x_req & b2x_write;
	   rdok = ~mgmt_req;
	   cb_pre_ok = 1'b1;
	   wrok = ~mgmt_req;
	   next_xfr_st = (mgmt_req | ~sdr_init_done) ? 2'b00 :
			 (~b2x_req) ? 2'b00 :
			 (b2x_read) ? 2'b10 :
			 (b2x_write) ? 2'b01 : 2'b00;
	end  
	2'b10 : begin
	   rd_next = ~l_xfr_end |
		     l_xfr_end & ~mgmt_req & b2x_req & b2x_read;
	   wr_next = 1'b0;
	   rdok = l_xfr_end & ~mgmt_req;
	   cb_pre_ok = (1'b0 == 1'b0) ? 1'b0 : l_xfr_end;
	   wrok = 1'b0;
	   sel_mgmt = 1'b0;
	   if (l_xfr_end) begin		   
	      if (~l_wrap) begin
		 i_xfr_cmd = 4'b0110;
		 sel_b2x = b2x_req & ~mgmt_req & (b2x_read | b2x_prechg_hit);
	      end  
	      else begin
		 i_xfr_cmd = 4'b1111;
		 sel_b2x = b2x_req & ~mgmt_req & ~b2x_write;
	      end  
	      next_xfr_st = (sdr_init_done) ? ((b2x_req & ~mgmt_req & b2x_read) ? 2'b10 : 2'b11) : 2'b00;
	   end  
	   else begin
	      i_xfr_cmd = (burst_bdry & ~l_wrap) ? 4'b0101 : 4'b1111;
	      sel_b2x = ~(burst_bdry & ~l_wrap) & b2x_req;
	      next_xfr_st = 2'b10;
	   end  
	end  
	2'b11 : begin 
	   rd_next = ~mgmt_req & b2x_req & b2x_read;
	   wr_next = rd_pipe_mt & ~mgmt_req & b2x_req & b2x_write;
	   rdok = ~mgmt_req;
	   cb_pre_ok = 1'b1;
	   wrok = rd_pipe_mt & ~mgmt_req;
	   sel_mgmt = mgmt_req;
	   sel_b2x = ~mgmt_req & b2x_req;
	   i_xfr_cmd = 4'b1111;
	   next_xfr_st = (~mgmt_req & b2x_req & b2x_read) ? 2'b10 : 
			 (~rd_pipe_mt) ? 2'b11 :
			 (~mgmt_req & b2x_req & b2x_write) ? 2'b01 : 
			 2'b00;
	end  
	2'b01 : begin
	   rd_next = l_xfr_end & ~mgmt_req & b2x_req & b2x_read;
	   wr_next = ~l_xfr_end |
		     l_xfr_end & ~mgmt_req & b2x_req & b2x_write;
	   rdok = l_xfr_end & ~mgmt_req;
	   cb_pre_ok = 1'b0;
	   wrok = l_xfr_end & ~mgmt_req;
	   sel_mgmt = 1'b0;
	   if (l_xfr_end) begin		   
	      if (~l_wrap) begin
		 sel_b2x = b2x_req & ~mgmt_req & (b2x_read | b2x_write);
		 i_xfr_cmd = 4'b0110;
	      end  
	      else begin
		 sel_b2x = b2x_req & ~mgmt_req & ~b2x_prechg_hit;
		 i_xfr_cmd = 4'b1111;
	      end  
	      next_xfr_st = (~mgmt_req & b2x_req & b2x_read) ? 2'b10 : 
			    (~mgmt_req & b2x_req & b2x_write) ? 2'b01 : 
			    2'b00;
	   end  
	   else begin
	      if (burst_bdry & ~l_wrap) begin
		 sel_b2x = 1'b0;
		 i_xfr_cmd = 4'b0100;
	      end  
	      else begin
		 sel_b2x = b2x_req & ~mgmt_req;
		 i_xfr_cmd = 4'b1111;
	      end  
	      next_xfr_st = 2'b01;
	   end  
	end  
      endcase  
   end  
   assign x2b_refresh = (xfr_cmd == 4'b0001) ? 1'b1 : 1'b0;
   assign x2b_act_ok = ~act_cmd & ~d_act_cmd;
   assign x2b_rdok = rdok;
   assign x2b_wrok = wrok;
   assign x2b_pre_ok[0] = cb_pre_ok;
   assign x2b_pre_ok[1] = cb_pre_ok;
   assign x2b_pre_ok[2] = cb_pre_ok;
   assign x2b_pre_ok[3] = cb_pre_ok;
   assign last_burst = (ld_xfr) ? b2x_last : l_last;
   wire [SDR_DW-1:0] 	x2a_rddt;
   assign x2a_rdstart = d_rd_start;
   assign x2a_wrstart = wr_start;
   assign x2a_rdlast = d_rd_last;
   assign x2a_wrlast = wr_last;
   assign x2a_id = (ld_xfr) ? b2x_id : l_id;
   assign x2a_rddt = sdr_din;
   assign x2a_wrnext = wr_next;
   assign x2a_rdok = d_rd_next;
   reg 				sdr_cs_n, sdr_cke, sdr_ras_n, sdr_cas_n,
				sdr_we_n; 
   reg [SDR_BW-1:0] 	sdr_dqm;
   reg [1:0] 			sdr_ba;
   reg [12:0] 			sdr_addr;
   reg [SDR_DW-1:0] 	sdr_dout;
   reg [SDR_BW-1:0] 	sdr_den_n;
   always @ (posedge clk)
      if (~reset_n) begin
	 sdr_cs_n <= 1'b1;
	 sdr_cke <= 1'b1;
	 sdr_ras_n <= 1'b1;
	 sdr_cas_n <= 1'b1;
	 sdr_we_n <= 1'b1;
	 sdr_dqm   <= {SDR_BW{1'b1}};
	 sdr_den_n <= {SDR_BW{1'b1}};
      end  
      else begin
	 sdr_cs_n <= xfr_cmd[3];
	 sdr_ras_n <= xfr_cmd[2];
	 sdr_cas_n <= xfr_cmd[1];
	 sdr_we_n <= xfr_cmd[0];
	 sdr_cke <= (xfr_st != 2'b00) ? 1'b1 : 
		    ~(mgmt_idle & b2x_idle & r2x_idle);
	 sdr_dqm <= (wr_next) ? a2x_wren_n : {SDR_BW{1'b0}};
         sdr_den_n <= (wr_next) ? {SDR_BW{1'b0}} : {SDR_BW{1'b1}};
      end  
   always @ (posedge clk) begin 
      if (~xfr_cmd[3]) begin 
	 sdr_addr <= xfr_addr;
	 sdr_ba <= xfr_ba;
      end  
      sdr_dout <= (wr_next) ? a2x_wrdt : sdr_dout;
   end  
   reg [2:0]       mgmt_st, next_mgmt_st;
   reg [3:0] 	   tmr0, tmr0_d;
   reg [3:0] 	   cntr1, cntr1_d;
   wire 	   tmr0_tc, cntr1_tc, rfsh_timer_tc, ref_req, precharge_ok;
   reg 		   ld_tmr0, ld_cntr1, dec_cntr1, set_sdr_init_done;
   reg [12-1 : 0]  rfsh_timer;
   reg [3-1:0]  rfsh_row_cnt;
   always @ (posedge clk) 
      if (~reset_n) begin
	 mgmt_st <= 3'b000;
	 tmr0 <= 4'b0;
	 cntr1 <= 4'h7;
	 rfsh_timer <= 0;
	 rfsh_row_cnt <= 0;
	 sdr_init_done <= 1'b0;
      end  
      else begin
	 mgmt_st <= next_mgmt_st;
	 tmr0 <= (ld_tmr0) ? tmr0_d :
		  (~tmr0_tc) ? tmr0 - 1 : tmr0;
	 cntr1 <= (ld_cntr1) ? cntr1_d :
		  (dec_cntr1) ? cntr1 - 1 : cntr1;
	 sdr_init_done <= (set_sdr_init_done | sdr_init_done) & sdram_enable;
	 rfsh_timer <= (rfsh_timer_tc) ? 0 : rfsh_timer + 1;
	 rfsh_row_cnt <= (~set_sdr_init_done) ? 0 :
			 (rfsh_timer_tc) ? rfsh_row_cnt + 1 : rfsh_row_cnt;
      end  
   assign tmr0_tc = ~|tmr0;
   assign cntr1_tc = ~|cntr1;
   assign rfsh_timer_tc = (rfsh_timer == rfsh_time) ? 1'b1 : 1'b0;
   assign ref_req = (rfsh_row_cnt >= rfsh_rmax) ? 1'b1 : 1'b0;
   assign precharge_ok = cb_pre_ok & b2x_tras_ok;
   assign xfr_bank_sel = l_ba;
   always @ (mgmt_st or sdram_enable or mgmt_ack or trp_delay or tmr0_tc or
	     cntr1_tc or trcar_delay or rfsh_row_cnt or ref_req or sdr_init_done
	     or precharge_ok or sdram_mode_reg) begin 
      case (mgmt_st)           
	3'b000 : begin
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b0;
	   mgmt_cmd = 4'b1111;
	   mgmt_ba = 2'b0;
	   mgmt_addr = 13'h400;     
	   ld_tmr0 = 1'b0;
	   tmr0_d = 4'b0;
	   dec_cntr1 = 1'b0;
	   ld_cntr1 = 1'b1;
	   cntr1_d = 4'hf;  
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (sdram_enable) ? 3'b001 : 3'b000; 
	end  
	3'b001 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = (precharge_ok) ? 4'b0010 : 4'b1111;
	   mgmt_ba = 2'b0;
	   mgmt_addr = 13'h400;	    
	   ld_tmr0 = mgmt_ack;
	   tmr0_d = trp_delay;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'h7;
	   dec_cntr1 = 1'b0;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (precharge_ok & mgmt_ack) ? 3'b010 : 3'b001;
	end  
	3'b010 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = 4'b1111;
	   mgmt_ba = 2'b0;
	   mgmt_addr = 13'h400;	    
	   ld_tmr0 = 1'b0;
	   tmr0_d = trp_delay;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'b0;
	   dec_cntr1 = 1'b0;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (tmr0_tc) ? 3'b011 : 3'b010;
	end  
	3'b011 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = 4'b0001;
	   mgmt_ba = 2'b0;
	   mgmt_addr = 13'h400;	    
	   ld_tmr0 = mgmt_ack;
	   tmr0_d = trcar_delay;
	   dec_cntr1 = mgmt_ack;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'h7;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (mgmt_ack) ? 3'b100 : 3'b011;
	end  
	3'b100 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = 4'b1111;
	   mgmt_ba = 2'b0;
	   mgmt_addr = 13'h400;	    
	   ld_tmr0 = 1'b0;
	   tmr0_d = trcar_delay;
	   dec_cntr1 = 1'b0;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'h7;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (~tmr0_tc) ? 3'b100 : 
			  (~cntr1_tc) ? 3'b011 :
			  (sdr_init_done) ? 3'b111 : 3'b101;
	end  
	3'b101 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = 4'b0000;
	   mgmt_ba = {1'b0, sdram_mode_reg[11]};
	   mgmt_addr = sdram_mode_reg;
	   ld_tmr0 = mgmt_ack;
	   tmr0_d = 4'h7;
	   dec_cntr1 = 1'b0;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'h7;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (mgmt_ack) ? 3'b110 : 3'b101;
	end  
	3'b110 : begin	    
	   mgmt_idle = 1'b0;
	   mgmt_req = 1'b1;
	   mgmt_cmd = 4'b1111;
	   mgmt_ba = 2'bx;
	   mgmt_addr = 13'bx;
	   ld_tmr0 = 1'b0;
	   tmr0_d = 4'h7;
	   dec_cntr1 = 1'b0;
	   ld_cntr1 = 1'b0;
	   cntr1_d = 4'h7;
	   set_sdr_init_done = 1'b0;
	   next_mgmt_st = (~tmr0_tc) ? 3'b110 : 3'b111;
	end  
	3'b111 : begin	    
	   mgmt_idle = ~ref_req;
	   mgmt_req = 1'b0;
	   mgmt_cmd = 4'b1111;
	   mgmt_ba = 2'bx;
	   mgmt_addr = 13'bx;
	   ld_tmr0 = 1'b0;
	   tmr0_d = 4'h7;
	   dec_cntr1 = 1'b0;
	   ld_cntr1 = ref_req;
	   cntr1_d = rfsh_row_cnt;
	   set_sdr_init_done = 1'b1;
	   next_mgmt_st =  (~sdram_enable) ? 3'b000 :
                           (ref_req) ? 3'b001 : 3'b111;
	end  
      endcase  
   end  
endmodule  
