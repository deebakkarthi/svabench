 `timescale 1ns / 10ps
module generic_dpram(
	rclk, rrst, rce, oe, raddr, do,
	wclk, wrst, wce, we, waddr, di
);
	parameter aw = 5;   
	parameter dw = 16;  
	input           rclk;   
	input           rrst;   
	input           rce;    
	input           oe;	    
	input  [aw-1:0] raddr;  
	output [dw-1:0] do;     
	input          wclk;   
	input          wrst;   
	input          wce;    
	input          we;     
	input [aw-1:0] waddr;  
	input [dw-1:0] di;     
	reg [dw-1:0] mem [(1<<aw) -1:0]  ;
	reg [aw-1:0] ra;                 
	always @(posedge rclk)
	  if (rce)
	    ra <= #1 raddr;
    assign do = mem[ra];
	always @(posedge wclk)
		if (we && wce)
			mem[waddr] <= #1 di;
endmodule
 `timescale 1ns / 10ps
module generic_spram(
	clk, rst, ce, we, oe, addr, di, do
);
	parameter aw = 6;  
	parameter dw = 8;  
	input           clk;   
	input           rst;   
	input           ce;    
	input           we;    
	input           oe;    
	input  [aw-1:0] addr;  
	input  [dw-1:0] di;    
	output [dw-1:0] do;    
	reg [dw-1:0] mem [(1<<aw) -1:0]  ;
	reg [aw-1:0] ra;
	always @(posedge clk)
	  if (ce)
	    ra <= #1 addr;      
	assign #1 do = mem[ra];
	always @(posedge clk)
	  if (we && ce)
	    mem[addr] <= #1 di;
endmodule
`timescale 1ns / 10ps
 `timescale 1ns / 10ps
module vga_clkgen (
	pclk_i, rst_i, pclk_o, dvi_pclk_p_o, dvi_pclk_m_o, pclk_ena_o
);
	input  pclk_i;        
	input  rst_i;         
	output pclk_o;        
	output dvi_pclk_p_o;  
	output dvi_pclk_m_o;  
	output pclk_ena_o;    
	reg dvi_pclk_p_o;
	reg dvi_pclk_m_o;
	always @(posedge pclk_i)
	  if (rst_i) begin
	    dvi_pclk_p_o <= #1 1'b0;
	    dvi_pclk_m_o <= #1 1'b0;
	  end else begin
	    dvi_pclk_p_o <= #1 ~dvi_pclk_p_o;
	    dvi_pclk_m_o <= #1 dvi_pclk_p_o;
	  end
	assign pclk_o     = pclk_i;
	assign pclk_ena_o = 1'b1;
endmodule
 `timescale 1ns / 10ps
module vga_colproc(clk, srst, vdat_buffer_di, ColorDepth, PseudoColor, 
	vdat_buffer_empty, vdat_buffer_rreq, rgb_fifo_full,
	rgb_fifo_wreq, r, g, b,
	clut_req, clut_ack, clut_offs, clut_q
	);
	input clk;                     
	input srst;                    
	input [31:0] vdat_buffer_di;   
	input [1:0] ColorDepth;        
	input       PseudoColor;       
	input  vdat_buffer_empty;
	output vdat_buffer_rreq;       
	reg    vdat_buffer_rreq;
	input  rgb_fifo_full;
	output rgb_fifo_wreq;
	reg    rgb_fifo_wreq;
	output [7:0] r, g, b;          
	reg    [7:0] r, g, b;
	output        clut_req;        
	reg clut_req;
	input         clut_ack;        
	output [ 7:0] clut_offs;       
	reg [7:0] clut_offs;
	input  [23:0] clut_q;          
	reg [31:0] DataBuffer;
	reg [7:0] Ra, Ga, Ba;
	reg [1:0] colcnt;
	reg RGBbuf_wreq;
	always @(posedge clk)
		if (vdat_buffer_rreq)
			DataBuffer <= #1 vdat_buffer_di;
	parameter idle        = 7'b000_0000, 
	          fill_buf    = 7'b000_0001,
	          bw_8bpp     = 7'b000_0010,
	          col_8bpp    = 7'b000_0100,
	          col_16bpp_a = 7'b000_1000,
	          col_16bpp_b = 7'b001_0000,
	          col_24bpp   = 7'b010_0000,
	          col_32bpp   = 7'b100_0000;
	reg [6:0] c_state;    
	reg [6:0] nxt_state;  
	always @(c_state or vdat_buffer_empty or ColorDepth or PseudoColor or rgb_fifo_full or colcnt or clut_ack)
	begin : nxt_state_decoder
		nxt_state = c_state;
		case (c_state)  
			idle:
				if (!vdat_buffer_empty && !rgb_fifo_full)
					nxt_state = fill_buf;
			fill_buf:
				case (ColorDepth)  
					2'b00: 
						if (PseudoColor)
							nxt_state = col_8bpp;
						else
							nxt_state = bw_8bpp;
					2'b01:
						nxt_state = col_16bpp_a;
					2'b10:
						nxt_state = col_24bpp;
					2'b11:
						nxt_state = col_32bpp;
				endcase
			bw_8bpp:
				if (!rgb_fifo_full && !(|colcnt) )
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_8bpp:
				if (!(|colcnt))
					if (!vdat_buffer_empty && !rgb_fifo_full)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_16bpp_a:
				if (!rgb_fifo_full)
					nxt_state = col_16bpp_b;
			col_16bpp_b:
				if (!rgb_fifo_full)
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_24bpp:
				if (!rgb_fifo_full)
					if (colcnt == 2'h1)  
						nxt_state = col_24bpp;  
					else if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
			col_32bpp:
				if (!rgb_fifo_full)
					if (!vdat_buffer_empty)
						nxt_state = fill_buf;
					else
						nxt_state = idle;
		endcase
	end  
	always @(posedge clk)
			if (srst)
				c_state <= #1 idle;
			else
				c_state <= #1 nxt_state;
	reg iclut_req;
	reg ivdat_buf_rreq;
	reg [7:0] iR, iG, iB, iRa, iGa, iBa;
	always @(c_state or vdat_buffer_empty or colcnt or DataBuffer or rgb_fifo_full or clut_ack or clut_q or Ba or Ga or Ra)
	begin : output_decoder
		ivdat_buf_rreq = 1'b0;
		RGBbuf_wreq = 1'b0;
		iclut_req = 1'b0;
		iR  = 'h0;
		iG  = 'h0;
		iB  = 'h0;
		iRa = 'h0;
		iGa = 'h0;
		iBa = 'h0;
		case (c_state)  
			idle:
				begin
					if (!rgb_fifo_full)
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					RGBbuf_wreq = clut_ack;
					iR = clut_q[23:16];
					iG = clut_q[15: 8];
					iB = clut_q[ 7: 0];
				end
			fill_buf:
				begin
					RGBbuf_wreq = clut_ack;
					iR = clut_q[23:16];
					iG = clut_q[15: 8];
					iB = clut_q[ 7: 0];
				end
			bw_8bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if ( (!vdat_buffer_empty) && !(|colcnt) )
							ivdat_buf_rreq = 1'b1;
					end
				case (colcnt)  
					2'b11:
					begin
						iR = DataBuffer[31:24];
						iG = DataBuffer[31:24];
						iB = DataBuffer[31:24];
					end
					2'b10:
					begin
						iR = DataBuffer[23:16];
						iG = DataBuffer[23:16];
						iB = DataBuffer[23:16];
					end
					2'b01:
					begin
						iR = DataBuffer[15:8];
						iG = DataBuffer[15:8];
						iB = DataBuffer[15:8];
					end
					default:
					begin
						iR = DataBuffer[7:0];
						iG = DataBuffer[7:0];
						iB = DataBuffer[7:0];
					end
				endcase
			end
			col_8bpp:
			begin
				if (!(|colcnt))
					if (!vdat_buffer_empty && !rgb_fifo_full)
						ivdat_buf_rreq = 1'b1;
				RGBbuf_wreq = clut_ack;
				iR = clut_q[23:16];
				iG = clut_q[15: 8];
				iB = clut_q[ 7: 0];
				iclut_req = !rgb_fifo_full || (colcnt[1] ^ colcnt[0]);
			end
			col_16bpp_a:
			begin
				if (!rgb_fifo_full)
					RGBbuf_wreq = 1'b1;
				iR[7:3] = DataBuffer[31:27];
				iG[7:2] = DataBuffer[26:21];
				iB[7:3] = DataBuffer[20:16];
			end
			col_16bpp_b:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				iR[7:3] = DataBuffer[15:11];
				iG[7:2] = DataBuffer[10: 5];
				iB[7:3] = DataBuffer[ 4: 0];
			end
			col_24bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if ( (colcnt != 2'h1) && !vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				case (colcnt)  
					2'b11:
					begin
						iR  = DataBuffer[31:24];
						iG  = DataBuffer[23:16];
						iB  = DataBuffer[15: 8];
						iRa = DataBuffer[ 7: 0];
					end
					2'b10:
					begin
						iR  = Ra;
						iG  = DataBuffer[31:24];
						iB  = DataBuffer[23:16];
						iRa = DataBuffer[15: 8];
						iGa = DataBuffer[ 7: 0];
					end
					2'b01:
					begin
						iR  = Ra;
						iG  = Ga;
						iB  = DataBuffer[31:24];
						iRa = DataBuffer[23:16];
						iGa = DataBuffer[15: 8];
						iBa = DataBuffer[ 7: 0];
					end
					default:
					begin
						iR = Ra;
						iG = Ga;
						iB = Ba;
					end
				endcase
			end
			col_32bpp:
			begin
				if (!rgb_fifo_full)
					begin
						RGBbuf_wreq = 1'b1;
						if (!vdat_buffer_empty)
							ivdat_buf_rreq = 1'b1;
					end
				iR[7:0] = DataBuffer[23:16];
				iG[7:0] = DataBuffer[15:8];
				iB[7:0] = DataBuffer[7:0];
			end
		endcase
	end  
	always @(posedge clk)
		begin
			r  <= #1 iR;
			g  <= #1 iG;
			b  <= #1 iB;
			if (RGBbuf_wreq)
				begin
					Ra <= #1 iRa;
					Ba <= #1 iBa;
					Ga <= #1 iGa;
				end
			if (srst)
				begin
					vdat_buffer_rreq <= #1 1'b0;
					rgb_fifo_wreq <= #1 1'b0;
					clut_req <= #1 1'b0;
				end
			else
				begin
					vdat_buffer_rreq <= #1 ivdat_buf_rreq;
					rgb_fifo_wreq <= #1 RGBbuf_wreq;
					clut_req <= #1 iclut_req;
				end
	end
	always @(colcnt or DataBuffer)
	  case (colcnt)  
	      2'b11: clut_offs = DataBuffer[31:24];
	      2'b10: clut_offs = DataBuffer[23:16];
	      2'b01: clut_offs = DataBuffer[15: 8];
	      2'b00: clut_offs = DataBuffer[ 7: 0];
	  endcase
	always @(posedge clk)
	  if (srst)
	    colcnt <= #1 2'b11;
	  else if (RGBbuf_wreq)
	    colcnt <= #1 colcnt -2'h1;
endmodule
 `timescale 1ns / 10ps
module vga_csm_pb (clk_i, req0_i, ack0_o, adr0_i, dat0_i, dat0_o, we0_i, req1_i, ack1_o, adr1_i, dat1_i, dat1_o, we1_i);
	parameter DWIDTH = 32;  
	parameter AWIDTH = 8;   
	input clk_i;                     
	input  [ AWIDTH   -1:0] adr0_i;  
	input  [ DWIDTH   -1:0] dat0_i;  
	output [ DWIDTH   -1:0] dat0_o;  
	input                   we0_i;   
	input                   req0_i;  
	output                  ack0_o;  
	input  [ AWIDTH   -1:0] adr1_i;  
	input  [ DWIDTH   -1:0] dat1_i;  
	output [ DWIDTH   -1:0] dat1_o;  
	input                   we1_i;   
	input                   req1_i;  
	output                  ack1_o;  
	wire acc0, acc1;
	reg  dacc0, dacc1;
	wire sel0, sel1;
	reg  ack0, ack1;
	wire [DWIDTH -1:0] mem_q;
	assign acc0 = req0_i;
	assign acc1 = req1_i && !sel0;
	always@(posedge clk_i)
		begin
			dacc0 <= #1 acc0 & !ack0_o;
			dacc1 <= #1 acc1 & !ack1_o;
		end
	assign sel0 = acc0 && !dacc0;
	assign sel1 = acc1 && !dacc1;
	always@(posedge clk_i)
		begin
			ack0 <= #1 sel0 && !ack0_o;
			ack1 <= #1 sel1 && !ack1_o;
		end
	wire [AWIDTH -1:0] mem_adr = sel0 ? adr0_i : adr1_i;
	wire [DWIDTH -1:0] mem_d   = sel0 ? dat0_i : dat1_i;
	wire               mem_we  = sel0 ? req0_i && we0_i : req1_i && we1_i;
	generic_spram #(AWIDTH, DWIDTH) clut_mem(
		.clk(clk_i),
		.rst(1'b0),        
		.ce(1'b1),         
		.we(mem_we),
		.oe(1'b1),         
		.addr(mem_adr),
		.di(mem_d),
		.do(mem_q)
	);
	assign dat0_o = mem_q;
	assign dat1_o = mem_q;
	assign ack0_o = ( (sel0 && we0_i) || ack0 );
	assign ack1_o = ( (sel1 && we1_i) || ack1 );
endmodule
 `timescale 1ns / 10ps
module vga_cur_cregs (
	clk_i, rst_i, arst_i,
	hsel_i, hadr_i, hwe_i, hdat_i, hdat_o, hack_o,
	cadr_i, cdat_o
	);
	input         clk_i;          
	input         rst_i;          
	input         arst_i;         
	input         hsel_i;         
	input  [ 2:0] hadr_i;         
	input         hwe_i;          
	input  [31:0] hdat_i;         
	output [31:0] hdat_o;         
	output        hack_o;         
	reg [31:0] hdat_o;
	reg        hack_o;
	input  [ 3:0] cadr_i;         
	output [15:0] cdat_o;         
	reg [15:0] cdat_o;
	reg  [31:0] cregs [7:0];   
	wire [31:0] temp_cdat;
	always@(posedge clk_i)
		if (hsel_i & hwe_i)
			cregs[hadr_i] <= #1 hdat_i;
	always@(posedge clk_i)
		hdat_o <= #1 cregs[hadr_i];
	always@(posedge clk_i)
		hack_o <= #1 hsel_i & !hack_o;
	assign temp_cdat = cregs[cadr_i[3:1]];
	always@(posedge clk_i)
		cdat_o <= #1 cadr_i[0] ? temp_cdat[31:16] : temp_cdat[15:0];
endmodule
 `timescale 1ns / 10ps
module vga_curproc (clk, rst_i, Thgate, Tvgate, idat, idat_wreq, 
	cursor_xy, cursor_en, cursor_res, 
	cursor_wadr, cursor_wdat, cursor_we,
	cc_adr_o, cc_dat_i,
	rgb_fifo_wreq, rgb);
	input         clk;            
	input         rst_i;          
	input [15:0] Thgate, Tvgate;  
	input [23:0] idat;            
	input        idat_wreq;       
	input [31:0] cursor_xy;       
	input        cursor_en;       
	input        cursor_res;      
	input [ 8:0] cursor_wadr;     
	input [31:0] cursor_wdat;     
	input        cursor_we;       
	output [ 3:0] cc_adr_o;       
	reg  [ 3:0] cc_adr_o;    
	input  [15:0] cc_dat_i;       
	output        rgb_fifo_wreq;  
	reg        rgb_fifo_wreq;
	output [23:0] rgb;            
	reg [23:0] rgb;
	reg         dcursor_en, ddcursor_en, dddcursor_en;
	reg  [15:0] xcnt, ycnt;
	wire        xdone, ydone;
	wire [15:0] cursor_x, cursor_y;
	wire        cursor_isalpha;
	reg  [15:0] cdat, dcdat;
	wire [ 7:0] cursor_r, cursor_g, cursor_b, cursor_alpha;
	reg         inbox_x, inbox_y;
	wire        inbox;
	reg         dinbox, ddinbox, dddinbox;
	reg  [23:0] didat, ddidat, dddidat;
	reg         didat_wreq, ddidat_wreq;
	wire [31:0] cbuf_q;
	reg  [11:0] cbuf_ra;
	reg  [ 2:0] dcbuf_ra;
	wire [ 8:0] cbuf_a;
	reg         store1, store2;
	always@(posedge clk)
		if(rst_i || xdone)
			xcnt <= #1 16'h0;
		else if (idat_wreq)
			xcnt <= #1 xcnt + 16'h1;
	assign xdone = (xcnt == Thgate) && idat_wreq;
	always@(posedge clk)
		if(rst_i || ydone)
			ycnt <= #1 16'h0;
		else if (xdone)
			ycnt <= #1 ycnt + 16'h1;
	assign ydone = (ycnt == Tvgate) && xdone;
	assign cursor_x = cursor_xy[15: 0];
	assign cursor_y = cursor_xy[31:16];
	always@(posedge clk)
		begin
			inbox_x <= #1 (xcnt >= cursor_x) && (xcnt < (cursor_x + (cursor_res ? 16'h7f : 16'h1f) ));
			inbox_y <= #1 (ycnt >= cursor_y) && (ycnt < (cursor_y + (cursor_res ? 16'h7f : 16'h1f) ));
		end
	assign inbox = inbox_x && inbox_y;
	always@(posedge clk)
		dinbox <= #1 inbox;
	always@(posedge clk)
		if (didat_wreq)
			ddinbox <= #1 dinbox;
	always@(posedge clk)
		dddinbox <= #1 ddinbox;
	always@(posedge clk)
		if (!cursor_en || ydone)
			cbuf_ra <= #1 12'h0;
		else if (inbox && idat_wreq)
			cbuf_ra <= #1 cbuf_ra +12'h1;
	always@(posedge clk)
		dcbuf_ra <= #1 cbuf_ra[2:0];
	assign cbuf_a = cursor_we ? cursor_wadr : cursor_res ? cbuf_ra[11:3] : cbuf_ra[9:1];
	generic_spram #(9, 32) cbuf(
		.clk(clk),
		.rst(1'b0),        
		.ce(1'b1),         
		.we(cursor_we),
		.oe(1'b1),         
		.addr(cbuf_a),
		.di(cursor_wdat),
		.do(cbuf_q)
	);
	always@(posedge clk)
		if (didat_wreq)
			cdat <= #1 dcbuf_ra[0] ? cbuf_q[31:16] : cbuf_q[15:0];
	always@(posedge clk)
		dcdat <= #1 cdat;
	always@(posedge clk)
		if (didat_wreq)
			case (dcbuf_ra)
				3'b000: cc_adr_o <= cbuf_q[ 3: 0];
				3'b001: cc_adr_o <= cbuf_q[ 7: 4];
				3'b010: cc_adr_o <= cbuf_q[11: 8];
				3'b011: cc_adr_o <= cbuf_q[15:12];
				3'b100: cc_adr_o <= cbuf_q[19:16];
				3'b101: cc_adr_o <= cbuf_q[23:20];
				3'b110: cc_adr_o <= cbuf_q[27:24];
				3'b111: cc_adr_o <= cbuf_q[31:28];
			endcase
	assign cursor_isalpha =  cursor_res ? cc_dat_i[15]    : dcdat[15];
	assign cursor_alpha   =  cursor_res ? cc_dat_i[7:0]   : dcdat[7:0];
	assign cursor_r       = {cursor_res ? cc_dat_i[14:10] : dcdat[14:10], 3'h0};
	assign cursor_g       = {cursor_res ? cc_dat_i[ 9: 5] : dcdat[ 9: 5], 3'h0};
	assign cursor_b       = {cursor_res ? cc_dat_i[ 4: 0] : dcdat[ 4: 0], 3'h0};
	always@(posedge clk)
		didat <= #1 idat;
	always@(posedge clk)
		if (didat_wreq)
			ddidat <= #1 didat;
	always@(posedge clk)
		dddidat <= #1 ddidat;
	always@(posedge clk)
		begin
			didat_wreq  <= #1 idat_wreq;
			ddidat_wreq <= #1 didat_wreq;
		end
	always@(posedge clk)
		dcursor_en <= #1 cursor_en;
	always@(posedge clk)
		if (didat_wreq)
			ddcursor_en <= #1 dcursor_en;
	always@(posedge clk)
		dddcursor_en <= #1 ddcursor_en;
	always@(posedge clk)
		if (ddidat_wreq)
			if (!dddcursor_en || !dddinbox)
				rgb <= #1 dddidat;
			else if (cursor_isalpha)
					rgb <= #1 dddidat;
			else
				rgb <= #1 {cursor_r, cursor_g, cursor_b};
	always@(posedge clk)
		if (rst_i)
		begin
			store1 <= #1 1'b0;
			store2 <= #1 1'b0;
		end
		else
		begin
			store1 <= #1  didat_wreq           | store1;
			store2 <= #1 (didat_wreq & store1) | store2;
		end
	always@(posedge clk)
		rgb_fifo_wreq <= #1 ddidat_wreq & store2;
endmodule
 `timescale 1ns / 10ps
module vga_enh_top (
	wb_clk_i, wb_rst_i, rst_i, wb_inta_o,
	wbs_adr_i, wbs_dat_i, wbs_dat_o, wbs_sel_i, wbs_we_i, wbs_stb_i, wbs_cyc_i, wbs_ack_o, wbs_rty_o, wbs_err_o,
	wbm_adr_o, wbm_dat_i, wbm_cti_o, wbm_bte_o, wbm_sel_o, wbm_we_o, wbm_stb_o, wbm_cyc_o, wbm_ack_i, wbm_err_i,
	clk_p_i,
	clk_p_o, hsync_pad_o, vsync_pad_o, csync_pad_o, blank_pad_o, r_pad_o, g_pad_o, b_pad_o
	);
	parameter ARST_LVL = 1'b0;
	parameter LINE_FIFO_AWIDTH = 7;
	input  wb_clk_i;              
	input  wb_rst_i;              
	input  rst_i;                 
	output wb_inta_o;             
	input  [11:0] wbs_adr_i;      
	input  [31:0] wbs_dat_i;      
	output [31:0] wbs_dat_o;      
	input  [ 3:0] wbs_sel_i;      
	input         wbs_we_i;       
	input         wbs_stb_i;      
	input         wbs_cyc_i;      
	output        wbs_ack_o;      
	output        wbs_rty_o;      
	output        wbs_err_o;      
	output [31:0] wbm_adr_o;      
	input  [31:0] wbm_dat_i;      
	output [ 3:0] wbm_sel_o;      
	output        wbm_we_o;       
	output        wbm_stb_o;      
	output        wbm_cyc_o;      
	output [ 2:0] wbm_cti_o;      
	output [ 1:0] wbm_bte_o;      
	input         wbm_ack_i;      
	input         wbm_err_i;      
	input         clk_p_i;                    
	output        clk_p_o;                    
	output        hsync_pad_o;                
	output        vsync_pad_o;                
	output        csync_pad_o;                
	output        blank_pad_o;                
	output [ 7:0] r_pad_o, g_pad_o, b_pad_o;  
	wire arst = rst_i ^ ARST_LVL;
	wire         ctrl_bl, ctrl_csl, ctrl_vsl, ctrl_hsl, ctrl_pc, ctrl_cbsw, ctrl_vbsw, ctrl_ven;
	wire [ 1: 0] ctrl_cd, ctrl_vbl, ctrl_dvi_odf;
	wire [ 7: 0] Thsync, Thgdel, Tvsync, Tvgdel;
	wire [15: 0] Thgate, Thlen, Tvgate, Tvlen;
	wire [31: 2] VBARa, VBARb;
	wire [ 8: 0] cursor_adr;
	wire [31: 0] cursor0_xy, cursor1_xy;
	wire         cursor0_en, cursor1_en;
	wire [31:11] cursor0_ba, cursor1_ba;
	wire         cursor0_ld, cursor1_ld;
	wire         cursor0_res, cursor1_res;
	wire [15: 0] cc0_dat_o, cc1_dat_o;
	wire stat_avmp, stat_acmp, vmem_swint, clut_swint, hint, vint, sint;
	wire wmb_busy;
	reg luint;
	wire [ 3: 0] cc0_adr_i, cc1_adr_i;
	wire        fb_data_fifo_rreq, fb_data_fifo_empty;
	wire [31:0] fb_data_fifo_q;
	wire        ImDoneFifoQ;
	wire        line_fifo_wreq, line_fifo_rreq, line_fifo_empty_rd;
	wire [23:0] line_fifo_d, line_fifo_q;
	wire        ext_clut_req, ext_clut_ack;
	wire [23:0] ext_clut_q;
	wire        cp_clut_req, cp_clut_ack;
	wire [ 8:0] cp_clut_adr;
	wire [23:0] cp_clut_q;
	vga_wb_slave wbs (
		.clk_i       ( wb_clk_i        ),
		.rst_i       ( wb_rst_i        ),
		.arst_i      ( arst            ),
		.adr_i       ( wbs_adr_i[11:2] ),
		.dat_i       ( wbs_dat_i       ),
		.dat_o       ( wbs_dat_o       ),
		.sel_i       ( wbs_sel_i       ),
		.we_i        ( wbs_we_i        ),
		.stb_i       ( wbs_stb_i       ),
		.cyc_i       ( wbs_cyc_i       ),
		.ack_o       ( wbs_ack_o       ),
		.rty_o       ( wbs_rty_o       ),
		.err_o       ( wbs_err_o       ),
		.inta_o      ( wb_inta_o       ),
		.wbm_busy    ( wbm_busy     ),  
		.dvi_odf     ( ctrl_dvi_odf ),  
		.bl          ( ctrl_bl      ),  
		.csl         ( ctrl_csl     ),  
		.vsl         ( ctrl_vsl     ),  
		.hsl         ( ctrl_hsl     ),  
		.pc          ( ctrl_pc      ),  
		.cd          ( ctrl_cd      ),  
		.vbl         ( ctrl_vbl     ),  
		.cbsw        ( ctrl_cbsw    ),  
		.vbsw        ( ctrl_vbsw    ),  
		.ven         ( ctrl_ven     ),  
		.acmp        ( stat_acmp    ),  
		.avmp        ( stat_avmp    ),  
		.cursor0_res ( cursor0_res  ),  
		.cursor0_en  ( cursor0_en   ),  
		.cursor0_xy  ( cursor0_xy   ),  
		.cursor0_ba  ( cursor0_ba   ),  
		.cursor0_ld  ( cursor0_ld   ),  
 		.cc0_adr_i   ( cc0_adr_i    ),  
		.cc0_dat_o   ( cc0_dat_o    ),  
		.cursor1_res ( cursor1_res  ),  
		.cursor1_en  ( cursor1_en   ),  
		.cursor1_xy  ( cursor1_xy   ),  
		.cursor1_ba  ( cursor1_ba   ),  
		.cursor1_ld  ( cursor1_ld   ),  
 		.cc1_adr_i   ( cc1_adr_i    ),  
		.cc1_dat_o   ( cc1_dat_o    ),  
		.vbsint_in   ( vmem_swint   ),  
		.cbsint_in   ( clut_swint   ),  
		.hint_in     ( hint         ),  
		.vint_in     ( vint         ),  
		.luint_in    ( luint        ),  
		.sint_in     ( sint         ),  
		.Thsync      ( Thsync       ),
		.Thgdel      ( Thgdel       ),
		.Thgate      ( Thgate       ),
		.Thlen       ( Thlen        ),
		.Tvsync      ( Tvsync       ),
		.Tvgdel      ( Tvgdel       ),
		.Tvgate      ( Tvgate       ),
		.Tvlen       ( Tvlen        ),
		.VBARa       ( VBARa        ),
		.VBARb       ( VBARb        ),
		.clut_acc    ( ext_clut_req ),
		.clut_ack    ( ext_clut_ack ),
		.clut_q      ( ext_clut_q   )
	);
	vga_wb_master wbm (
		.clk_i  ( wb_clk_i  ),
		.rst_i  ( wb_rst_i  ),
		.nrst_i ( arst      ),
		.cyc_o  ( wbm_cyc_o ),
		.stb_o  ( wbm_stb_o ),
		.cti_o  ( wbm_cti_o ),
		.bte_o  ( wbm_bte_o ),
		.we_o   ( wbm_we_o  ),
		.adr_o  ( wbm_adr_o ),
		.sel_o  ( wbm_sel_o ),
		.ack_i  ( wbm_ack_i ),
		.err_i  ( wbm_err_i ),
		.dat_i  ( wbm_dat_i ),
		.sint        (sint         ),
		.ctrl_ven    (ctrl_ven     ),
		.ctrl_cd     (ctrl_cd      ),
		.ctrl_vbl    (ctrl_vbl     ),
		.ctrl_vbsw   (ctrl_vbsw    ),
		.busy        (wbm_busy     ),
		.VBAa        (VBARa        ),
		.VBAb        (VBARb        ),
		.Thgate      (Thgate       ),
		.Tvgate      (Tvgate       ),
		.stat_avmp   (stat_avmp    ),
		.vmem_switch (vmem_swint   ),
		.ImDoneFifoQ ( ImDoneFifoQ ),
		.cursor_adr  ( cursor_adr  ),
		.cursor0_ba  ( cursor0_ba  ),     
		.cursor0_ld  ( cursor0_ld  ),     
		.cursor1_ba  ( cursor1_ba  ),     
		.cursor1_ld  ( cursor1_ld  ),     
		.fb_data_fifo_rreq  ( fb_data_fifo_rreq  ),
		.fb_data_fifo_q     ( fb_data_fifo_q     ),
		.fb_data_fifo_empty ( fb_data_fifo_empty )
	);
	vga_csm_pb #(24, 9) clut_mem(
		.clk_i(wb_clk_i),
		.req0_i(cp_clut_req),
		.ack0_o(cp_clut_ack),
		.adr0_i(cp_clut_adr),
		.dat0_i(24'h0),
		.dat0_o(cp_clut_q),
		.we0_i(1'b0),  
		.req1_i(ext_clut_req),
		.ack1_o(ext_clut_ack),
		.adr1_i(wbs_adr_i[10:2]),
		.dat1_i(wbs_dat_i[23:0]),
		.dat1_o(ext_clut_q),
		.we1_i(wbs_we_i)
	);
	vga_pgen pixel_generator (
		.clk_i              ( wb_clk_i           ),
		.ctrl_ven           ( ctrl_ven           ),
		.ctrl_HSyncL        ( ctrl_hsl           ),
		.Thsync             ( Thsync             ),
		.Thgdel             ( Thgdel             ),
		.Thgate             ( Thgate             ),
		.Thlen              ( Thlen              ),
		.ctrl_VSyncL        ( ctrl_vsl           ),
		.Tvsync             ( Tvsync             ),
		.Tvgdel             ( Tvgdel             ),
		.Tvgate             ( Tvgate             ),
		.Tvlen              ( Tvlen              ),
		.ctrl_CSyncL        ( ctrl_csl           ),
		.ctrl_BlankL        ( ctrl_bl            ),
		.eoh                ( hint               ),
		.eov                ( vint               ),
		.fb_data_fifo_rreq  ( fb_data_fifo_rreq  ),
		.fb_data_fifo_q     ( fb_data_fifo_q     ),
		.fb_data_fifo_empty ( fb_data_fifo_empty ),
		.ImDoneFifoQ        ( ImDoneFifoQ        ),
		.stat_acmp          ( stat_acmp          ),
		.clut_req           ( cp_clut_req        ),
		.clut_ack           ( cp_clut_ack        ),
		.clut_adr           ( cp_clut_adr        ),
		.clut_q             ( cp_clut_q          ),
		.ctrl_cbsw          ( ctrl_cbsw          ),
		.clut_switch        ( clut_swint         ),
		.cursor_adr         ( cursor_adr         ),   
		.cursor0_en         ( cursor0_en         ),   
		.cursor0_res        ( cursor0_res        ),   
		.cursor0_xy         ( cursor0_xy         ),   
		.cc0_adr_o          ( cc0_adr_i          ),   
		.cc0_dat_i          ( cc0_dat_o          ),   
		.cursor1_en         ( cursor1_en         ),   
		.cursor1_res        ( cursor1_res        ),   
		.cursor1_xy         ( cursor1_xy         ),   
		.cc1_adr_o          ( cc1_adr_i          ),   
		.cc1_dat_i          ( cc1_dat_o          ),   
		.ctrl_dvi_odf       ( ctrl_dvi_odf       ),
		.ctrl_cd            ( ctrl_cd            ),
		.ctrl_pc            ( ctrl_pc            ),
		.line_fifo_wreq     ( line_fifo_wreq     ),
		.line_fifo_d        ( line_fifo_d        ),
		.line_fifo_full     ( line_fifo_full_wr  ),
		.line_fifo_rreq     ( line_fifo_rreq     ),
		.line_fifo_q        ( line_fifo_q        ),
		.pclk_i             ( clk_p_i            ),
		.pclk_o             ( clk_p_o            ),
		.hsync_o            ( hsync_pad_o        ),
		.vsync_o            ( vsync_pad_o        ),
		.csync_o            ( csync_pad_o        ),
		.blank_o            ( blank_pad_o        ),
		.r_o                ( r_pad_o            ),
		.g_o                ( g_pad_o            ),
		.b_o                ( b_pad_o            )
	);
	wire ctrl_ven_not = ~ctrl_ven;
	vga_fifo_dc #(LINE_FIFO_AWIDTH, 24) line_fifo (
		.rclk  ( clk_p_i            ),
		.wclk  ( wb_clk_i           ),
		.rclr  ( 1'b0               ),
		.wclr  ( ctrl_ven_not       ),
		.wreq  ( line_fifo_wreq     ),
		.d     ( line_fifo_d        ),
		.rreq  ( line_fifo_rreq     ),
		.q     ( line_fifo_q        ),
		.empty ( line_fifo_empty_rd ),
		.full  ( line_fifo_full_wr  )
	);
	reg luint_pclk, sluint;
	always @(posedge clk_p_i)
	  luint_pclk <= #1 line_fifo_rreq & line_fifo_empty_rd;
	always @(posedge wb_clk_i)
	  if (!ctrl_ven)
	    begin
	        sluint <= #1 1'b0;
	        luint  <= #1 1'b0;
	    end
	  else
	    begin
	        sluint <= #1 luint_pclk;   
	        luint  <= #1 sluint;       
	    end
endmodule
 `timescale 1ns / 10ps
module vga_fifo (
	clk,
	aclr,
	sclr,
	wreq,
	rreq,
	d,
	q,
	nword,
	empty,
	full,
	aempty,
	afull
	);
	parameter aw =  3;                          
	parameter dw =  8;                          
	input             clk;                      
	input             aclr;                     
	input             sclr;                     
	input             wreq;                     
	input             rreq;                     
	input  [dw:1]     d;                        
	output [dw:1]     q;                        
	output [aw:0]     nword;                    
	output            empty;                    
	output            full;                     
	output            aempty;                   
	output            afull;                    
	reg [aw:0] nword;
	reg        empty, full;
	reg  [aw:1] rp, wp;
	wire [dw:1] ramq;
	wire fwreq, frreq;
	function lsb;
	   input [aw:1] q;
	   case (aw)
	       2: lsb = ~q[2];
	       3: lsb = &q[aw-1:1] ^ ~(q[3] ^ q[2]);
	       4: lsb = &q[aw-1:1] ^ ~(q[4] ^ q[3]);
	       5: lsb = &q[aw-1:1] ^ ~(q[5] ^ q[3]);
	       6: lsb = &q[aw-1:1] ^ ~(q[6] ^ q[5]);
	       7: lsb = &q[aw-1:1] ^ ~(q[7] ^ q[6]);
	       8: lsb = &q[aw-1:1] ^ ~(q[8] ^ q[6] ^ q[5] ^ q[4]);
	       9: lsb = &q[aw-1:1] ^ ~(q[9] ^ q[5]);
	      10: lsb = &q[aw-1:1] ^ ~(q[10] ^ q[7]);
	      11: lsb = &q[aw-1:1] ^ ~(q[11] ^ q[9]);
	      12: lsb = &q[aw-1:1] ^ ~(q[12] ^ q[6] ^ q[4] ^ q[1]);
	      13: lsb = &q[aw-1:1] ^ ~(q[13] ^ q[4] ^ q[3] ^ q[1]);
	      14: lsb = &q[aw-1:1] ^ ~(q[14] ^ q[5] ^ q[3] ^ q[1]);
	      15: lsb = &q[aw-1:1] ^ ~(q[15] ^ q[14]);
	      16: lsb = &q[aw-1:1] ^ ~(q[16] ^ q[15] ^ q[13] ^ q[4]);
	   endcase
	endfunction
  assign fwreq = wreq;
  assign frreq = rreq;
	always @(posedge clk or negedge aclr)
	  if (~aclr)      rp <= #1 0;
	  else if (sclr)  rp <= #1 0;
	  else if (frreq) rp <= #1 {rp[aw-1:1], lsb(rp)};
	always @(posedge clk or negedge aclr)
	  if (~aclr)      wp <= #1 0;
	  else if (sclr)  wp <= #1 0;
	  else if (fwreq) wp <= #1 {wp[aw-1:1], lsb(wp)};
	reg [dw:1] mem [(1<<aw) -1:0];
	always @(posedge clk)
	  if (fwreq)
	    mem[wp] <= #1 d;
	assign q = mem[rp];
	assign aempty = (rp[aw-1:1] == wp[aw:2]) & (lsb(rp) == wp[1]) & frreq & ~fwreq;
	always @(posedge clk or negedge aclr)
	  if (~aclr)
	    empty <= #1 1'b1;
	  else if (sclr)
	    empty <= #1 1'b1;
	  else
	    empty <= #1 aempty | (empty & (~fwreq + frreq));
	assign afull = (wp[aw-1:1] == rp[aw:2]) & (lsb(wp) == rp[1]) & fwreq & ~frreq;
	always @(posedge clk or negedge aclr)
	  if (~aclr)
	    full <= #1 1'b0;
	  else if (sclr)
	    full <= #1 1'b0;
	  else
	    full <= #1 afull | ( full & (~frreq + fwreq) );
	always @(posedge clk or negedge aclr)
	  if (~aclr)
	    nword <= #1 0;
	  else if (sclr)
	    nword <= #1 0;
	  else
	    begin
	        if (wreq & !rreq)
	          nword <= #1 nword +1;
	        else if (rreq & !wreq)
	          nword <= #1 nword -1;
	    end
	always @(posedge clk)
	  if (full & fwreq)
	    $display("Writing while FIFO full (%m)\n");
	always @(posedge clk)
	  if (empty & frreq)
	    $display("Reading while FIFO empty (%m)\n");
endmodule
 `timescale 1ns / 10ps
module vga_fifo_dc (rclk, wclk, rclr, wclr, wreq, d, rreq, q, empty, full);
	parameter AWIDTH = 7;   
	parameter DWIDTH = 16;  
	input rclk;              
	input wclk;              
	input rclr;              
	input wclr;              
	input wreq;              
	input [DWIDTH -1:0] d;   
	input rreq;              
	output [DWIDTH -1:0] q;  
	output empty;            
	reg empty;
	output full;             
	reg full;
	reg rrst, wrst, srclr, ssrclr, swclr, sswclr;
	reg [AWIDTH -1:0] rptr, wptr, rptr_gray, wptr_gray;
	function [AWIDTH:1] bin2gray;
		input [AWIDTH:1] bin;
		integer n;
	begin
		for (n=1; n<AWIDTH; n=n+1)
			bin2gray[n] = bin[n+1] ^ bin[n];
		bin2gray[AWIDTH] = bin[AWIDTH];
	end
	endfunction
	function [AWIDTH:1] gray2bin;
		input [AWIDTH:1] gray;
	begin
		gray2bin = bin2gray(gray);
	end
	endfunction
	always @(posedge rclk)
	begin
	    swclr  <= #1 wclr;
	    sswclr <= #1 swclr;
	    rrst   <= #1 rclr | sswclr;
	end
	always @(posedge wclk)
	begin
	    srclr  <= #1 rclr;
	    ssrclr <= #1 srclr;
	    wrst   <= #1 wclr | ssrclr;
	end
	always @(posedge rclk)
	  if (rrst) begin
	      rptr      <= #1 0;
	      rptr_gray <= #1 0;
	  end else if (rreq) begin
	      rptr      <= #1 rptr +1'h1;
	      rptr_gray <= #1 bin2gray(rptr +1'h1);
	  end
	always @(posedge wclk)
	  if (wrst) begin
	      wptr      <= #1 0;
	      wptr_gray <= #1 0;
	  end else if (wreq) begin
	      wptr      <= #1 wptr +1'h1;
	      wptr_gray <= #1 bin2gray(wptr +1'h1);
	  end
	reg [AWIDTH-1:0] srptr_gray, ssrptr_gray;
	reg [AWIDTH-1:0] swptr_gray, sswptr_gray;
	always @(posedge rclk)
	begin
	    swptr_gray  <= #1 wptr_gray;
	    sswptr_gray <= #1 swptr_gray;
	end
	always @(posedge wclk)
	begin
	    srptr_gray  <= #1 rptr_gray;
	    ssrptr_gray <= #1 srptr_gray;
	end
	always @(posedge rclk)
	  if (rrst)
	    empty <= #1 1'b1;
	  else if (rreq)
	    empty <= #1 bin2gray(rptr +1'h1) == sswptr_gray;
	  else
	    empty <= #1 empty & (rptr_gray == sswptr_gray);
	always @(posedge wclk)
	  if (wrst)
	    full <= #1 1'b0;
	  else if (wreq)
	    full <= #1 bin2gray(wptr +2'h2) == ssrptr_gray;
	  else
	    full <= #1 full & (bin2gray(wptr + 2'h1) == ssrptr_gray);
	generic_dpram #(AWIDTH, DWIDTH) fifo_dc_mem(
		.rclk(rclk),
		.rrst(1'b0),
		.rce(1'b1),
		.oe(1'b1),
		.raddr(rptr),
		.do(q),
		.wclk(wclk),
		.wrst(1'b0),
		.wce(1'b1),
		.we(wreq),
		.waddr(wptr),
		.di(d)
	);
endmodule
 `timescale 1ns / 10ps
module vga_pgen (
	clk_i, ctrl_ven, ctrl_HSyncL, Thsync, Thgdel, Thgate, Thlen,
	ctrl_VSyncL, Tvsync, Tvgdel, Tvgate, Tvlen, ctrl_CSyncL, ctrl_BlankL,
	eoh, eov,
	ctrl_dvi_odf, ctrl_cd, ctrl_pc,
	fb_data_fifo_rreq, fb_data_fifo_empty, fb_data_fifo_q, ImDoneFifoQ,
	stat_acmp, clut_req, clut_adr, clut_q, clut_ack, ctrl_cbsw, clut_switch,
	cursor_adr,
	cursor0_en, cursor0_res, cursor0_xy, cc0_adr_o, cc0_dat_i,
	cursor1_en, cursor1_res, cursor1_xy, cc1_adr_o, cc1_dat_i,
	line_fifo_wreq, line_fifo_full, line_fifo_d, line_fifo_rreq, line_fifo_q,
	pclk_i,
	pclk_o, hsync_o, vsync_o, csync_o, blank_o, r_o, g_o, b_o
);
	input clk_i;  
	input ctrl_ven;            
	input        ctrl_HSyncL;  
	input [ 7:0] Thsync;       
	input [ 7:0] Thgdel;       
	input [15:0] Thgate;       
	input [15:0] Thlen;        
	input        ctrl_VSyncL;  
	input [ 7:0] Tvsync;       
	input [ 7:0] Tvgdel;       
	input [15:0] Tvgate;       
	input [15:0] Tvlen;        
	input ctrl_CSyncL;         
	input ctrl_BlankL;         
	output eoh;                
	reg eoh;
	output eov;                
	reg eov;
	input  [ 1: 0] ctrl_dvi_odf;
	input  [ 1: 0] ctrl_cd;
	input          ctrl_pc;
	input  [31: 0] fb_data_fifo_q;
	input          fb_data_fifo_empty;
	output         fb_data_fifo_rreq;
	input          ImDoneFifoQ;
	output         stat_acmp;    
	reg stat_acmp;
	output         clut_req;
	output [ 8: 0] clut_adr;
	input  [23: 0] clut_q;
	input          clut_ack;
	input          ctrl_cbsw;    
	output         clut_switch;  
	input  [ 8: 0] cursor_adr;   
	input          cursor0_en;   
	input          cursor0_res;  
	input  [31: 0] cursor0_xy;   
	output [ 3: 0] cc0_adr_o;    
	input  [15: 0] cc0_dat_i;    
	input          cursor1_en;   
	input          cursor1_res;  
	input  [31: 0] cursor1_xy;   
	output [ 3: 0] cc1_adr_o;    
	input  [15: 0] cc1_dat_i;    
	input          line_fifo_full;
	output         line_fifo_wreq;
	output [23: 0] line_fifo_d;
	output         line_fifo_rreq;
	input  [23: 0] line_fifo_q;
	input  pclk_i;             
	output pclk_o;             
	output hsync_o;            
	output vsync_o;            
	output csync_o;            
	output blank_o;            
	output [ 7:0] r_o, g_o, b_o;
	reg       hsync_o, vsync_o, csync_o, blank_o;
	reg [7:0] r_o, g_o, b_o;
	reg nVen;  
	wire eol, eof;
	wire ihsync, ivsync, icsync, iblank;
	wire pclk_ena;
	always @(posedge pclk_i)
	  nVen <= #1 ~ctrl_ven;
	vga_clkgen clk_gen(
	  .pclk_i       ( pclk_i       ),
	  .rst_i        ( nVen         ),
	  .pclk_o       ( pclk_o       ),
	  .dvi_pclk_p_o ( dvi_pclk_p_o ),
	  .dvi_pclk_m_o ( dvi_pclk_m_o ),
	  .pclk_ena_o   ( pclk_ena     )
	);
	vga_tgen vtgen(
		.clk(pclk_i),
		.clk_ena ( pclk_ena    ),
		.rst     ( nVen        ),
		.Thsync  ( Thsync      ),
		.Thgdel  ( Thgdel      ),
		.Thgate  ( Thgate      ),
		.Thlen   ( Thlen       ),
		.Tvsync  ( Tvsync      ),
		.Tvgdel  ( Tvgdel      ),
		.Tvgate  ( Tvgate      ),
		.Tvlen   ( Tvlen       ),
		.eol     ( eol         ),
		.eof     ( eof         ),
		.gate    ( gate        ),
		.hsync   ( ihsync      ),
		.vsync   ( ivsync      ),
		.csync   ( icsync      ),
		.blank   ( iblank      )
	);
	reg seol, seof;    
	reg dseol, dseof;  
	always @(posedge clk_i)
	  if (~ctrl_ven)
	    begin
	        seol  <= #1 1'b0;
	        dseol <= #1 1'b0;
	        seof  <= #1 1'b0;
	        dseof <= #1 1'b0;
	        eoh   <= #1 1'b0;
	        eov   <= #1 1'b0;
	    end
	  else
	    begin
	        seol  <= #1 eol;
	        dseol <= #1 seol;
	        seof  <= #1 eof;
	        dseof <= #1 seof;
	        eoh   <= #1 seol & !dseol;
	        eov   <= #1 seof & !dseof;
	    end
	reg hsync, vsync, csync, blank;
	always @(posedge pclk_i)
	    begin
	        hsync <= #1 ihsync ^ ctrl_HSyncL;
	        vsync <= #1 ivsync ^ ctrl_VSyncL;
	        csync <= #1 icsync ^ ctrl_CSyncL;
	        blank <= #1 iblank ^ ctrl_BlankL;
	        hsync_o <= #1 hsync;
	        vsync_o <= #1 vsync;
	        csync_o <= #1 csync;
	        blank_o <= #1 blank;
	    end
	wire [23:0] color_proc_q;            
	wire        color_proc_wreq;
	wire [ 7:0] clut_offs;                
	wire ImDoneFifoQ;
	reg  dImDoneFifoQ, ddImDoneFifoQ;
	wire [23:0] cur1_q;
	wire        cur1_wreq;
	wire [23:0] rgb_fifo_d;
	wire        rgb_fifo_empty, rgb_fifo_full, rgb_fifo_rreq, rgb_fifo_wreq;
	wire sclr = ~ctrl_ven;
	vga_colproc color_proc (
		.clk               ( clk_i               ),
		.srst              ( sclr                ),
		.vdat_buffer_di    ( fb_data_fifo_q      ),  
		.ColorDepth        ( ctrl_cd             ),
		.PseudoColor       ( ctrl_pc             ),
		.vdat_buffer_empty ( fb_data_fifo_empty  ),  
		.vdat_buffer_rreq  ( fb_data_fifo_rreq   ),  
		.rgb_fifo_full     ( rgb_fifo_full       ),
		.rgb_fifo_wreq     ( color_proc_wreq     ),
		.r                 ( color_proc_q[23:16] ),
		.g                 ( color_proc_q[15: 8] ),
		.b                 ( color_proc_q[ 7: 0] ),
		.clut_req          ( clut_req            ),
		.clut_ack          ( clut_ack            ),
		.clut_offs         ( clut_offs           ),
		.clut_q            ( clut_q              )
	);
	always @(posedge clk_i)
	  if (sclr)
	    dImDoneFifoQ <= #1 1'b0;
	  else if (fb_data_fifo_rreq)
	    dImDoneFifoQ <= #1 ImDoneFifoQ;
	always @(posedge clk_i)
	  if (sclr)
	    ddImDoneFifoQ <= #1 1'b0;
	  else
	    ddImDoneFifoQ <= #1 dImDoneFifoQ;
	assign clut_switch = ddImDoneFifoQ & !dImDoneFifoQ;
	always @(posedge clk_i)
	  if (sclr)
	    stat_acmp <= #1 1'b0;
	  else if (ctrl_cbsw)
	    stat_acmp <= #1 stat_acmp ^ clut_switch;   
	assign clut_adr = {stat_acmp, clut_offs};
	assign cur1_wreq = color_proc_wreq;
	assign cur1_q    = color_proc_q;
	assign cc1_adr_o  = 4'h0;
	assign rgb_fifo_wreq = cur1_wreq;
	assign rgb_fifo_d = cur1_q;
	assign cc0_adr_o  = 4'h0;
	wire [4:0] rgb_fifo_nword;
	vga_fifo #(4, 24) rgb_fifo (
		.clk    ( clk_i          ),
		.aclr   ( 1'b1           ),
		.sclr   ( sclr           ),
		.d      ( rgb_fifo_d     ),
		.wreq   ( rgb_fifo_wreq  ),
		.q      ( line_fifo_d    ),
		.rreq   ( rgb_fifo_rreq  ),
		.empty  ( rgb_fifo_empty ),
		.nword  ( rgb_fifo_nword ),
		.full   ( ),
		.aempty ( ),
		.afull  ( )
	);
	assign rgb_fifo_full = rgb_fifo_nword[3];  
	assign line_fifo_rreq = gate & pclk_ena;
	assign rgb_fifo_rreq = ~line_fifo_full & ~rgb_fifo_empty;
	assign line_fifo_wreq = rgb_fifo_rreq;
	wire [7:0] r = line_fifo_q[23:16];
	wire [7:0] g = line_fifo_q[15: 8];
	wire [7:0] b = line_fifo_q[ 7: 0];
	always @(posedge pclk_i)
	  if (pclk_ena) begin
	    r_o <= #1 r;
	    g_o <= #1 g;
	    b_o <= #1 b;
	  end
endmodule
 `timescale 1ns / 10ps
module vga_tgen(
	clk, clk_ena, rst,
	Thsync, Thgdel, Thgate, Thlen, Tvsync, Tvgdel, Tvgate, Tvlen,
	eol, eof, gate, hsync, vsync, csync, blank
	);
	input clk;
	input clk_ena;
	input rst;
	input [ 7:0] Thsync;  
	input [ 7:0] Thgdel;  
	input [15:0] Thgate;  
	input [15:0] Thlen;   
	input [ 7:0] Tvsync;  
	input [ 7:0] Tvgdel;  
	input [15:0] Tvgate;  
	input [15:0] Tvlen;   
	output eol;   
	output eof;   
	output gate;  
	output hsync;  
	output vsync;  
	output csync;  
	output blank;  
	wire Hgate, Vgate;
	wire Hdone;
	vga_vtim hor_gen(
		.clk(clk),
		.ena(clk_ena),
		.rst(rst),
		.Tsync(Thsync),
		.Tgdel(Thgdel),
		.Tgate(Thgate),
		.Tlen(Thlen),
		.Sync(hsync),
		.Gate(Hgate),
		.Done(Hdone)
	);
	wire vclk_ena = Hdone & clk_ena;
	vga_vtim ver_gen(
		.clk(clk),
		.ena(vclk_ena),
		.rst(rst),
		.Tsync(Tvsync),
		.Tgdel(Tvgdel),
		.Tgate(Tvgate),
		.Tlen(Tvlen),
		.Sync(vsync),
		.Gate(Vgate),
		.Done(eof)
	);
	assign eol  = Hdone;
	assign gate = Hgate & Vgate;
	assign csync = hsync | vsync;
	assign blank = ~gate;
endmodule
 `timescale 1ns / 10ps
module vga_vtim(clk, ena, rst, Tsync, Tgdel, Tgate, Tlen, Sync, Gate, Done);
	input clk;  
	input ena;  
	input rst;  
	input [ 7:0] Tsync;  
	input [ 7:0] Tgdel;  
	input [15:0] Tgate;  
	input [15:0] Tlen;   
	output Sync;  
	output Gate;  
	output Done;  
	reg Sync;
	reg Gate;
	reg Done;
	reg  [15:0] cnt, cnt_len;
	wire [16:0] cnt_nxt, cnt_len_nxt;
	wire        cnt_done, cnt_len_done;
	assign cnt_nxt = {1'b0, cnt} -17'h1;
	assign cnt_done = cnt_nxt[16];
	assign cnt_len_nxt = {1'b0, cnt_len} -17'h1;
	assign cnt_len_done = cnt_len_nxt[16];
	reg [4:0] state;
	parameter [4:0] idle_state = 5'b00001;
	parameter [4:0] sync_state = 5'b00010;
	parameter [4:0] gdel_state = 5'b00100;
	parameter [4:0] gate_state = 5'b01000;
	parameter [4:0] len_state  = 5'b10000;
	always @(posedge clk)
	  if (rst)
	    begin
	        state   <= #1 idle_state;
	        cnt     <= #1 16'h0;
	        cnt_len <= #1 16'b0;
	        Sync    <= #1 1'b0;
	        Gate    <= #1 1'b0;
	        Done    <= #1 1'b0;
	    end
	  else if (ena)
	    begin
	        cnt     <= #1 cnt_nxt[15:0];
	        cnt_len <= #1 cnt_len_nxt[15:0];
	        Done    <= #1 1'b0;
	        case (state)  
	          idle_state:
	            begin
	                state   <= #1 sync_state;
	                cnt     <= #1 Tsync;
	                cnt_len <= #1 Tlen;
	                Sync    <= #1 1'b1;
	            end
	          sync_state:
	            if (cnt_done)
	              begin
	                  state <= #1 gdel_state;
	                  cnt   <= #1 Tgdel;
	                  Sync  <= #1 1'b0;
	              end
	          gdel_state:
	            if (cnt_done)
	              begin
	                  state <= #1 gate_state;
	                  cnt   <= #1 Tgate;
	                  Gate  <= #1 1'b1;
	              end
	          gate_state:
	            if (cnt_done)
	              begin
	                  state <= #1 len_state;
	                  Gate  <= #1 1'b0;
	              end
	          len_state:
	            if (cnt_len_done)
	              begin
	                  state   <= #1 sync_state;
	                  cnt     <= #1 Tsync;
	                  cnt_len <= #1 Tlen;
	                  Sync    <= #1 1'b1;
	                  Done    <= #1 1'b1;
	              end
	        endcase
	    end
endmodule
 `timescale 1ns / 10ps
module vga_wb_master (clk_i, rst_i, nrst_i,
	cyc_o, stb_o, cti_o, bte_o, we_o, adr_o, sel_o, ack_i, err_i, dat_i, sint,
	ctrl_ven, ctrl_cd, ctrl_vbl, ctrl_vbsw, busy,
	VBAa, VBAb, Thgate, Tvgate,
	stat_avmp, vmem_switch, ImDoneFifoQ,
	cursor_adr, cursor0_ba, cursor1_ba, cursor0_ld, cursor1_ld,
	fb_data_fifo_rreq, fb_data_fifo_q, fb_data_fifo_empty);
	input         clk_i;     
	input         rst_i;     
	input         nrst_i;    
	output        cyc_o;     
	reg cyc_o;
	output        stb_o;     
	reg stb_o;
	output [ 2:0] cti_o;     
	reg [2:0] cti_o;
	output [ 1:0] bte_o;     
	reg [1:0] bte_o;
	output        we_o;      
	reg we_o;
	output [31:0] adr_o;     
	output [ 3:0] sel_o;     
	reg [3:0] sel_o;
	input         ack_i;     
	input         err_i;     
	input [31:0]  dat_i;     
	output        sint;      
	input       ctrl_ven;    
	input [1:0] ctrl_cd;     
	input [1:0] ctrl_vbl;    
	input       ctrl_vbsw;   
	output      busy;        
	input [31: 2] VBAa;      
	input [31: 2] VBAb;      
	input [15:0] Thgate;     
	input [15:0] Tvgate;     
	output stat_avmp;        
	output vmem_switch;      
	output ImDoneFifoQ;
	output [ 8: 0] cursor_adr;  
	input  [31:11] cursor0_ba;
	input  [31:11] cursor1_ba;
	input          cursor0_ld;  
	input          cursor1_ld;  
	input          fb_data_fifo_rreq;
	output [31: 0] fb_data_fifo_q;
	output         fb_data_fifo_empty;
	reg vmem_acc;                  
	wire vmem_req, vmem_ack;       
	wire ImDone;                   
	reg  dImDone;                  
	wire ImDoneStrb;               
	reg  dImDoneStrb;              
	reg sclr;                      
	reg [31:11] cursor_ba;               
	reg [ 8: 0] cursor_adr;              
	wire        cursor0_we, cursor1_we;  
	reg         ld_cursor0, ld_cursor1;  
	reg         cur_acc;                 
	reg         cur_acc_sel;             
	wire        cur_ack;                 
	wire        cur_done;                
	always @(posedge clk_i)
	  sclr <= #1 ~ctrl_ven;
	reg  [ 2:0] burst_cnt;                        
	wire        burst_done;                       
	reg         sel_VBA;                          
	reg  [31:2] vmemA;                            
	always @(posedge clk_i)
	  if (sclr)
	    vmem_acc <= #1 1'b0;  
	  else
	    vmem_acc <= #1 (vmem_req | (vmem_acc & !(burst_done & vmem_ack)) ) & !ImDone & !cur_acc;
	always @(posedge clk_i)
	  if (sclr)
	    cur_acc <= #1 1'b0;  
	  else
	    cur_acc <= #1 (cur_acc | ImDone & (ld_cursor0 | ld_cursor1)) & !cur_done;
	assign busy = vmem_acc | cur_acc;
	assign vmem_ack = ack_i & stb_o & vmem_acc;
	assign cur_ack  = ack_i & stb_o & cur_acc;
	assign sint = err_i;  
	assign vmem_switch = ImDoneStrb;
	always @(posedge clk_i)
	  if (sclr)
	    sel_VBA <= #1 1'b0;
	  else if (ctrl_vbsw)
	    sel_VBA <= #1 sel_VBA ^ vmem_switch;   
	assign stat_avmp = sel_VBA;  
	vga_fifo #(4, 1) clut_sw_fifo (
		.clk    ( clk_i             ),
		.aclr   ( 1'b1              ),
		.sclr   ( sclr              ),
		.d      ( ImDone            ),
		.wreq   ( vmem_ack          ),
		.q      ( ImDoneFifoQ       ),
		.rreq   ( fb_data_fifo_rreq ),
		.nword  ( ),
		.empty  ( ),
		.full   ( ),
		.aempty ( ),
		.afull  ( )
	);
	wire [3:0] burst_cnt_val;
	assign burst_cnt_val = {1'b0, burst_cnt} -4'h1;
	assign burst_done = burst_cnt_val[3];
	always @(posedge clk_i)
	  if ( (burst_done & vmem_ack) | !vmem_acc)
	    case (ctrl_vbl)  
	      2'b00: burst_cnt <= #1 3'b000;  
	      2'b01: burst_cnt <= #1 3'b001;  
	      2'b10: burst_cnt <= #1 3'b011;  
	      2'b11: burst_cnt <= #1 3'b111;  
	    endcase
	  else if(vmem_ack)
	    burst_cnt <= #1 burst_cnt_val[2:0];
	reg  [15:0] hgate_cnt;
	reg  [16:0] hgate_cnt_val;
	reg  [1:0]  hgate_div_cnt;
	reg  [2:0]  hgate_div_val;
	wire hdone = hgate_cnt_val[16] & vmem_ack;  
	always @(hgate_cnt or hgate_div_cnt or ctrl_cd)
	  begin
	      hgate_div_val = {1'b0, hgate_div_cnt} - 3'h1;
	      if (ctrl_cd != 2'b10)
	        hgate_cnt_val = {1'b0, hgate_cnt} - 17'h1;
	      else if ( hgate_div_val[2] )
	        hgate_cnt_val = {1'b0, hgate_cnt} - 17'h1;
	      else
	        hgate_cnt_val = {1'b0, hgate_cnt};
	  end
	always @(posedge clk_i)
	  if (sclr)
	    begin
	        case(ctrl_cd)  
	          2'b00: hgate_cnt <= #1 Thgate >> 2;  
	          2'b01: hgate_cnt <= #1 Thgate >> 1;  
	          2'b10: hgate_cnt <= #1 Thgate >> 2;  
	          2'b11: hgate_cnt <= #1 Thgate;       
	        endcase
	        hgate_div_cnt <= 2'b10;
	    end
	  else if (vmem_ack)
	    if (hdone)
	      begin
	          case(ctrl_cd)  
	            2'b00: hgate_cnt <= #1 Thgate >> 2;  
	            2'b01: hgate_cnt <= #1 Thgate >> 1;  
	            2'b10: hgate_cnt <= #1 Thgate >> 2;  
	            2'b11: hgate_cnt <= #1 Thgate;       
	          endcase
	          hgate_div_cnt <= 2'b10;
	      end
	    else  
	      begin
	          hgate_cnt <= #1 hgate_cnt_val[15:0];
	          if ( hgate_div_val[2] )
	            hgate_div_cnt <= #1 2'b10;
	          else
	            hgate_div_cnt <= #1 hgate_div_val[1:0];
	      end
	reg  [15:0] vgate_cnt;
	wire [16:0] vgate_cnt_val;
	wire        vdone;
	assign vgate_cnt_val = {1'b0, vgate_cnt} - 17'h1;
	assign vdone = vgate_cnt_val[16];
	always @(posedge clk_i)
	  if (sclr | ImDoneStrb)
	    vgate_cnt <= #1 Tvgate;
	  else if (hdone)
	    vgate_cnt <= #1 vgate_cnt_val[15:0];
	assign ImDone = hdone & vdone;
	assign ImDoneStrb = ImDone & !dImDone;
	always @(posedge clk_i)
	  begin
	      dImDone <= #1 ImDone;
	      dImDoneStrb <= #1 ImDoneStrb;
	  end
	always @(posedge clk_i)
	  if (sclr | dImDoneStrb)
	    if (!sel_VBA)
	      vmemA <= #1 VBAa;
	    else
	      vmemA <= #1 VBAb;
	  else if (vmem_ack)
	    vmemA <= #1 vmemA +30'h1;
	always @(posedge clk_i)
	  if (ImDone)
	    cur_acc_sel <= #1 ld_cursor0;  
	always @(posedge clk_i)
	if (sclr)
	  begin
	      ld_cursor0 <= #1 1'b0;
	      ld_cursor1 <= #1 1'b0;
	  end
	else
	  begin
	      ld_cursor0 <= #1 cursor0_ld | (ld_cursor0 & !(cur_done &  cur_acc_sel));
	      ld_cursor1 <= #1 cursor1_ld | (ld_cursor1 & !(cur_done & !cur_acc_sel));
	  end
	always @(posedge clk_i)
	  if (!cur_acc)
	    cursor_ba <= #1 ld_cursor0 ? cursor0_ba : cursor1_ba;
	wire [9:0] next_cursor_adr = {1'b0, cursor_adr} + 10'h1;
	assign cur_done = next_cursor_adr[9] & cur_ack;
	always @(posedge clk_i)
	  if (!cur_acc)
	    cursor_adr <= #1 9'h0;
	  else if (cur_ack)
	    cursor_adr <= #1 next_cursor_adr;
	assign cursor1_we = cur_ack & !cur_acc_sel;
	assign cursor0_we = cur_ack &  cur_acc_sel;
	assign adr_o = cur_acc ? {cursor_ba, cursor_adr, 2'b00} : {vmemA, 2'b00};
	wire wb_cycle = vmem_acc & !(burst_done & vmem_ack & !vmem_req) & !ImDone ||
	                cur_acc & !cur_done;
	always @(posedge clk_i or negedge nrst_i)
	  if (!nrst_i)
	    begin
	        cyc_o <= #1 1'b0;
	        stb_o <= #1 1'b0;
	        sel_o <= #1 4'b1111;
	        cti_o <= #1 3'b000;
	        bte_o <= #1 2'b00;
	        we_o  <= #1 1'b0;
	    end
	  else
	    if (rst_i)
	      begin
	          cyc_o <= #1 1'b0;
	          stb_o <= #1 1'b0;
	          sel_o <= #1 4'b1111;
	          cti_o <= #1 3'b000;
	          bte_o <= #1 2'b00;
	          we_o  <= #1 1'b0;
	      end
	    else
	      begin
	          cyc_o <= #1 wb_cycle;
	          stb_o <= #1 wb_cycle;
	          sel_o <= #1 4'b1111;    
	          if (wb_cycle) begin
	            if (cur_acc)
	              cti_o <= #1 &next_cursor_adr[8:0] ? 3'b111 : 3'b010;
	            else if (ctrl_vbl == 2'b00)
	              cti_o <= #1 3'b000;
	            else if (vmem_ack)
	              cti_o <= #1 (burst_cnt == 3'h1) ? 3'b111 : 3'b010;
	          end else
	            cti_o <= #1 (ctrl_vbl == 2'b00) ? 3'b000 : 3'b010;
	          bte_o <= #1 2'b00;      
	          we_o  <= #1 1'b0;       
	      end
	wire [4:0] fb_data_fifo_nword;
	vga_fifo #(4, 32) data_fifo (
		.clk    ( clk_i              ),
		.aclr   ( 1'b1               ),
		.sclr   ( sclr               ),
		.d      ( dat_i              ),
		.wreq   ( vmem_ack           ),
		.q      ( fb_data_fifo_q     ),
		.rreq   ( fb_data_fifo_rreq  ),
		.nword  ( fb_data_fifo_nword ),
		.empty  ( fb_data_fifo_empty ),
		.full   ( ), 
		.aempty ( ),
		.afull  ( )
	);
	assign vmem_req = ~fb_data_fifo_nword[4] & ~fb_data_fifo_nword[3];
endmodule
 `timescale 1ns / 10ps
module vga_wb_slave(
	clk_i, rst_i, arst_i, adr_i, dat_i, dat_o, sel_i, we_i, stb_i, cyc_i, ack_o, rty_o, err_o, inta_o,
	wbm_busy, dvi_odf, bl, csl, vsl, hsl, pc, cd, vbl, cbsw, vbsw, ven, avmp, acmp,
	cursor0_res, cursor0_en, cursor0_xy, cursor0_ba, cursor0_ld, cc0_adr_i, cc0_dat_o,
	cursor1_res, cursor1_en, cursor1_xy, cursor1_ba, cursor1_ld, cc1_adr_i, cc1_dat_o,
	vbsint_in, cbsint_in, hint_in, vint_in, luint_in, sint_in,
	Thsync, Thgdel, Thgate, Thlen, Tvsync, Tvgdel, Tvgate, Tvlen, VBARa, VBARb,
	clut_acc, clut_ack, clut_q
	);
	input         clk_i;
	input         rst_i;
	input         arst_i;
	input  [11:2] adr_i;
	input  [31:0] dat_i;
	output [31:0] dat_o;
	reg [31:0] dat_o;
	input  [ 3:0] sel_i;
	input         we_i;
	input         stb_i;
	input         cyc_i;
	output        ack_o;
	reg ack_o;
	output        rty_o;
	reg rty_o;
	output        err_o;
	reg err_o;
	output        inta_o;
	reg inta_o;
	input  wbm_busy;              
	output [1:0] dvi_odf;         
	output bl;                    
	output csl;                   
	output vsl;                   
	output hsl;                   
	output pc;                    
	output [1:0] cd;              
	output [1:0] vbl;             
	output cbsw;                  
	output vbsw;                  
	output ven;                   
	output         cursor0_res;   
	output         cursor0_en;    
	output [31: 0] cursor0_xy;    
	output [31:11] cursor0_ba;    
	output         cursor0_ld;    
	input  [ 3: 0] cc0_adr_i;     
	output [15: 0] cc0_dat_o;     
	output         cursor1_res;   
	output         cursor1_en;    
	output [31: 0] cursor1_xy;    
	output [31:11] cursor1_ba;    
	output         cursor1_ld;    
	input  [ 3: 0] cc1_adr_i;     
	output [15: 0] cc1_dat_o;     
	reg [31: 0] cursor0_xy;
	reg [31:11] cursor0_ba;
	reg         cursor0_ld;
	reg [31: 0] cursor1_xy;
	reg [31:11] cursor1_ba;
	reg         cursor1_ld;
	input avmp;           
	input acmp;           
	input vbsint_in;      
	input cbsint_in;      
	input hint_in;        
	input vint_in;        
	input luint_in;       
	input sint_in;        
	output [ 7:0] Thsync;
	output [ 7:0] Thgdel;
	output [15:0] Thgate;
	output [15:0] Thlen;
	output [ 7:0] Tvsync;
	output [ 7:0] Tvgdel;
	output [15:0] Tvgate;
	output [15:0] Tvlen;
	output [31:2] VBARa;
	reg [31:2] VBARa;
	output [31:2] VBARb;
	reg [31:2] VBARb;
	output        clut_acc;
	input         clut_ack;
	input  [23:0] clut_q;
	parameter REG_ADR_HIBIT = 7;
	wire [REG_ADR_HIBIT:0] REG_ADR  = adr_i[REG_ADR_HIBIT : 2];
	wire                   CLUT_ADR = adr_i[11];
	parameter [REG_ADR_HIBIT : 0] CTRL_ADR  = 6'b00_0000;
	parameter [REG_ADR_HIBIT : 0] STAT_ADR  = 6'b00_0001;
	parameter [REG_ADR_HIBIT : 0] HTIM_ADR  = 6'b00_0010;
	parameter [REG_ADR_HIBIT : 0] VTIM_ADR  = 6'b00_0011;
	parameter [REG_ADR_HIBIT : 0] HVLEN_ADR = 6'b00_0100;
	parameter [REG_ADR_HIBIT : 0] VBARA_ADR = 6'b00_0101;
	parameter [REG_ADR_HIBIT : 0] VBARB_ADR = 6'b00_0110;
	parameter [REG_ADR_HIBIT : 0] C0XY_ADR  = 6'b00_1100;
	parameter [REG_ADR_HIBIT : 0] C0BAR_ADR = 6'b00_1101;
	parameter [REG_ADR_HIBIT : 0] CCR0_ADR  = 6'b01_0???;
	parameter [REG_ADR_HIBIT : 0] C1XY_ADR  = 6'b01_1100;
	parameter [REG_ADR_HIBIT : 0] C1BAR_ADR = 6'b01_1101;
	parameter [REG_ADR_HIBIT : 0] CCR1_ADR  = 6'b10_0???;
	reg [31:0] ctrl, stat, htim, vtim, hvlen;
	wire hint, vint, vbsint, cbsint, luint, sint;
	wire hie, vie, vbsie, cbsie;
	wire acc, acc32, reg_acc, reg_wacc;
	wire cc0_acc, cc1_acc;
	wire [31:0] ccr0_dat_o, ccr1_dat_o;
	reg [31:0] reg_dato;  
	assign acc      =  cyc_i & stb_i;
	assign acc32    = (sel_i == 4'b1111);
	assign clut_acc =  CLUT_ADR & acc & acc32;
	assign reg_acc  = ~CLUT_ADR & acc & acc32;
	assign reg_wacc =  reg_acc & we_i;
	assign cc0_acc  = (REG_ADR == CCR0_ADR) & acc & acc32;
	assign cc1_acc  = (REG_ADR == CCR1_ADR) & acc & acc32;
	always @(posedge clk_i)
	  ack_o <= #1 ((reg_acc & acc32) | clut_ack) & ~(wbm_busy & REG_ADR == CTRL_ADR) & ~ack_o ;
	always @(posedge clk_i)
	  rty_o <= #1 ((reg_acc & acc32) | clut_ack) & (wbm_busy & REG_ADR == CTRL_ADR) & ~rty_o ;
	always @(posedge clk_i)
	  err_o <= #1 acc & ~acc32 & ~err_o;
	always @(posedge clk_i or negedge arst_i)
	begin : gen_regs
	  if (!arst_i)
	    begin
	        htim       <= #1 0;
	        vtim       <= #1 0;
	        hvlen      <= #1 0;
	        VBARa      <= #1 0;
	        VBARb      <= #1 0;
	        cursor0_xy <= #1 0;
	        cursor0_ba <= #1 0;
	        cursor1_xy <= #1 0;
	        cursor1_ba <= #1 0;
	    end
	  else if (rst_i)
	    begin
	        htim       <= #1 0;
	        vtim       <= #1 0;
	        hvlen      <= #1 0;
	        VBARa      <= #1 0;
	        VBARb      <= #1 0;
	        cursor0_xy <= #1 0;
	        cursor0_ba <= #1 0;
	        cursor1_xy <= #1 0;
	        cursor1_ba <= #1 0;
	    end
	  else if (reg_wacc)
	    case (adr_i)  
	        HTIM_ADR  : htim       <= #1 dat_i;
	        VTIM_ADR  : vtim       <= #1 dat_i;
	        HVLEN_ADR : hvlen      <= #1 dat_i;
	        VBARA_ADR : VBARa      <= #1 dat_i[31: 2];
	        VBARB_ADR : VBARb      <= #1 dat_i[31: 2];
	        C0XY_ADR  : cursor0_xy <= #1 dat_i[31: 0];
	        C0BAR_ADR : cursor0_ba <= #1 dat_i[31:11];
	        C1XY_ADR  : cursor1_xy <= #1 dat_i[31: 0];
	        C1BAR_ADR : cursor1_ba <= #1 dat_i[31:11];
	    endcase
	end
	always @(posedge clk_i)
	  begin
	     cursor0_ld <= #1 reg_wacc && (adr_i == C0BAR_ADR);
	     cursor1_ld <= #1 reg_wacc && (adr_i == C1BAR_ADR);
	  end
	always @(posedge clk_i or negedge arst_i)
	  if (!arst_i)
	    ctrl <= #1 0;
	  else if (rst_i)
	    ctrl <= #1 0;
	  else if (reg_wacc & (REG_ADR == CTRL_ADR) & ~wbm_busy )
	    ctrl <= #1 dat_i;
	  else begin
	    ctrl[6] <= #1 ctrl[6] & !cbsint_in;
	    ctrl[5] <= #1 ctrl[5] & !vbsint_in;
	  end
	always @(posedge clk_i or negedge arst_i)
	  if (!arst_i)
	    stat <= #1 0;
	  else if (rst_i)
	    stat <= #1 0;
	  else begin
	        stat[21] <= #1 1'b0;
	        stat[20] <= #1 1'b0;
	    stat[17] <= #1 acmp;
	    stat[16] <= #1 avmp;
	    if (reg_wacc & (REG_ADR == STAT_ADR) )
	      begin
	          stat[7] <= #1 cbsint_in | (stat[7] & !dat_i[7]);
	          stat[6] <= #1 vbsint_in | (stat[6] & !dat_i[6]);
	          stat[5] <= #1 hint_in   | (stat[5] & !dat_i[5]);
	          stat[4] <= #1 vint_in   | (stat[4] & !dat_i[4]);
	          stat[1] <= #1 luint_in  | (stat[3] & !dat_i[1]);
	          stat[0] <= #1 sint_in   | (stat[0] & !dat_i[0]);
	      end
	    else
	      begin
	          stat[7] <= #1 stat[7] | cbsint_in;
	          stat[6] <= #1 stat[6] | vbsint_in;
	          stat[5] <= #1 stat[5] | hint_in;
	          stat[4] <= #1 stat[4] | vint_in;
	          stat[1] <= #1 stat[1] | luint_in;
	          stat[0] <= #1 stat[0] | sint_in;
	      end
	  end
	assign dvi_odf     = ctrl[29:28];
	assign cursor1_res = ctrl[25];
	assign cursor1_en  = ctrl[24];
	assign cursor0_res = ctrl[23];
	assign cursor0_en  = ctrl[20];
	assign bl          = ctrl[15];
	assign csl         = ctrl[14];
	assign vsl         = ctrl[13];
	assign hsl         = ctrl[12];
	assign pc          = ctrl[11];
	assign cd          = ctrl[10:9];
	assign vbl         = ctrl[8:7];
	assign cbsw        = ctrl[6];
	assign vbsw        = ctrl[5];
	assign cbsie       = ctrl[4];
	assign vbsie       = ctrl[3];
	assign hie         = ctrl[2];
	assign vie         = ctrl[1];
	assign ven         = ctrl[0];
	assign cbsint = stat[7];
	assign vbsint = stat[6];
	assign hint   = stat[5];
	assign vint   = stat[4];
	assign luint  = stat[1];
	assign sint   = stat[0];
	assign Thsync = htim[31:24];
	assign Thgdel = htim[23:16];
	assign Thgate = htim[15:0];
	assign Thlen  = hvlen[31:16];
	assign Tvsync = vtim[31:24];
	assign Tvgdel = vtim[23:16];
	assign Tvgate = vtim[15:0];
	assign Tvlen  = hvlen[15:0];
		assign ccr0_dat_o = 32'h0;
		assign cc0_dat_o = 32'h0;
		assign ccr1_dat_o = 32'h0;
		assign cc1_dat_o = 32'h0;
	always @(REG_ADR or ctrl or stat or htim or vtim or hvlen or VBARa or VBARb or acmp or
		cursor0_xy or cursor0_ba or cursor1_xy or cursor1_ba or ccr0_dat_o or ccr1_dat_o)
	  casez (REG_ADR)  
	      CTRL_ADR  : reg_dato = ctrl;
	      STAT_ADR  : reg_dato = stat;
	      HTIM_ADR  : reg_dato = htim;
	      VTIM_ADR  : reg_dato = vtim;
	      HVLEN_ADR : reg_dato = hvlen;
	      VBARA_ADR : reg_dato = {VBARa, 2'b0};
	      VBARB_ADR : reg_dato = {VBARb, 2'b0};
	      C0XY_ADR  : reg_dato = cursor0_xy;
	      C0BAR_ADR : reg_dato = {cursor0_ba, 11'h0};
	      CCR0_ADR  : reg_dato = ccr0_dat_o;
	      C1XY_ADR  : reg_dato = cursor1_xy;
	      C1BAR_ADR : reg_dato = {cursor1_ba, 11'h0};
	      CCR1_ADR  : reg_dato = ccr1_dat_o;
	      default   : reg_dato = 32'h0000_0000;
	  endcase
	always @(posedge clk_i)
	  dat_o <= #1 reg_acc ? reg_dato : {8'h0, clut_q};
	always @(posedge clk_i)
	  inta_o <= #1 (hint & hie) | (vint & vie) | (vbsint & vbsie) | (cbsint & cbsie) | luint | sint;
endmodule
