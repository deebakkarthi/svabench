module i2c_master_bit_ctrl (
    input             clk,       
    input             rst,       
    input             nReset,    
    input             ena,       
    input      [15:0] clk_cnt,   
    input      [ 3:0] cmd,       
    output reg        cmd_ack,   
    output reg        busy,      
    output reg        al,        
    input             din,
    output reg        dout,
    input             scl_i,     
    output            scl_o,     
    output            scl_oen,   
    input             sda_i,     
    output            sda_o,     
    output            sda_oen,   
    output reg        slave_adr_received,
    output reg [7:0]  slave_adr,
    input             master_mode,
    output reg        cmd_slave_ack,
    input [1:0]       slave_cmd ,
    input             sl_wait,
    output            slave_reset
);
    reg [ 1:0] cSCL, cSDA;       
    reg [ 2:0] fSCL, fSDA;       
    reg        sSCL, sSDA;       
    reg        dSCL, dSDA;       
    reg        dscl_oen;         
    reg        sda_chk;          
    reg        clk_en;           
    reg        slave_wait;       
    reg [15:0] cnt;              
    reg [13:0] filter_cnt;       
    reg [17:0] c_state;  
    reg [4:0] 	      slave_state;
    always @(posedge clk)
      dscl_oen <= scl_oen;
    always @(posedge clk or negedge nReset)
      if (!nReset) slave_wait <= 1'b0;
      else         slave_wait <= (scl_oen & ~dscl_oen & ~sSCL) | (slave_wait & ~sSCL);
    wire scl_sync   = dSCL & ~sSCL & scl_oen;
    always @(posedge clk or negedge nReset)
      if (~nReset)
      begin
          cnt    <= 16'h0;
          clk_en <= 1'b1;
      end
      else if (rst || ~|cnt || !ena || scl_sync)
      begin
          cnt    <= clk_cnt;
          clk_en <= 1'b1;
      end
      else if (slave_wait)
      begin
          cnt    <= cnt;
          clk_en <= 1'b0;
      end
      else
      begin
          cnt    <= cnt - 16'h1;
          clk_en <= 1'b0;
      end
    always @(posedge clk or negedge nReset)
      if (!nReset)
      begin
          cSCL <= 2'b00;
          cSDA <= 2'b00;
      end
      else if (rst)
      begin
          cSCL <= 2'b00;
          cSDA <= 2'b00;
      end
      else
      begin
          cSCL <= {cSCL[0],scl_i};
          cSDA <= {cSDA[0],sda_i};
      end
    always @(posedge clk or negedge nReset)
      if      (!nReset     ) filter_cnt <= 14'h0;
      else if (rst || !ena ) filter_cnt <= 14'h0;
      else if (~|filter_cnt) filter_cnt <= clk_cnt[15:2];  
      else                   filter_cnt <= filter_cnt -14'd1;
    always @(posedge clk or negedge nReset)
      if (!nReset)
      begin
          fSCL <= 3'b111;
          fSDA <= 3'b111;
      end
      else if (rst)
      begin
          fSCL <= 3'b111;
          fSDA <= 3'b111;
      end
      else if (~|filter_cnt)
      begin
          fSCL <= {fSCL[1:0],cSCL[1]};
          fSDA <= {fSDA[1:0],cSDA[1]};
      end
    always @(posedge clk or negedge nReset)
      if (~nReset)
      begin
          sSCL <= 1'b1;
          sSDA <= 1'b1;
          dSCL <= 1'b1;
          dSDA <= 1'b1;
      end
      else if (rst)
      begin
          sSCL <= 1'b1;
          sSDA <= 1'b1;
          dSCL <= 1'b1;
          dSDA <= 1'b1;
      end
      else
      begin
          sSCL <= &fSCL[2:1] | &fSCL[1:0] | (fSCL[2] & fSCL[0]);
          sSDA <= &fSDA[2:1] | &fSDA[1:0] | (fSDA[2] & fSDA[0]);
          dSCL <= sSCL;
          dSDA <= sSDA;
      end
    reg sta_condition;
    reg sto_condition;
    always @(posedge clk or negedge nReset)
      if (~nReset)
      begin
          sta_condition <= 1'b0;
          sto_condition <= 1'b0;
      end
      else if (rst)
      begin
          sta_condition <= 1'b0;
          sto_condition <= 1'b0;
      end
      else
      begin
          sta_condition <= ~sSDA &  dSDA & sSCL;
          sto_condition <=  sSDA & ~dSDA & sSCL;
      end
    always @(posedge clk or negedge nReset)
      if      (!nReset) busy <= 1'b0;
      else if (rst    ) busy <= 1'b0;
      else              busy <= (sta_condition | busy) & ~sto_condition;
    reg cmd_stop;
    always @(posedge clk or negedge nReset)
      if (~nReset)
          cmd_stop <= 1'b0;
      else if (rst)
          cmd_stop <= 1'b0;
      else if (clk_en)
          cmd_stop <= cmd == 4'b0010;
    always @(posedge clk or negedge nReset)
      if (~nReset)
          al <= 1'b0;
      else if (rst)
          al <= 1'b0;
      else
          al <= (sda_chk & ~sSDA & sda_oen) | (|c_state & sto_condition & ~cmd_stop);
    always @(posedge clk)
      if (sSCL & ~dSCL) dout <= sSDA;
    parameter [17:0] idle    = 18'b0_0000_0000_0000_0000;
    parameter [17:0] start_a = 18'b0_0000_0000_0000_0001;
    parameter [17:0] start_b = 18'b0_0000_0000_0000_0010;
    parameter [17:0] start_c = 18'b0_0000_0000_0000_0100;
    parameter [17:0] start_d = 18'b0_0000_0000_0000_1000;
    parameter [17:0] start_e = 18'b0_0000_0000_0001_0000;
    parameter [17:0] stop_a  = 18'b0_0000_0000_0010_0000;
    parameter [17:0] stop_b  = 18'b0_0000_0000_0100_0000;
    parameter [17:0] stop_c  = 18'b0_0000_0000_1000_0000;
    parameter [17:0] stop_d  = 18'b0_0000_0001_0000_0000;
    parameter [17:0] rd_a    = 18'b0_0000_0010_0000_0000;
    parameter [17:0] rd_b    = 18'b0_0000_0100_0000_0000;
    parameter [17:0] rd_c    = 18'b0_0000_1000_0000_0000;
    parameter [17:0] rd_d    = 18'b0_0001_0000_0000_0000;
    parameter [17:0] wr_a    = 18'b0_0010_0000_0000_0000;
    parameter [17:0] wr_b    = 18'b0_0100_0000_0000_0000;
    parameter [17:0] wr_c    = 18'b0_1000_0000_0000_0000;
    parameter [17:0] wr_d    = 18'b1_0000_0000_0000_0000;
    reg scl_oen_master ;
    reg sda_oen_master ;
    reg sda_oen_slave;
    reg scl_oen_slave;
    always @(posedge clk or negedge nReset)
      if (!nReset)
      begin
          c_state <= idle;
          cmd_ack <= 1'b0;
          scl_oen_master <=  1'b1;
          sda_oen_master <=  1'b1;
          sda_chk <= 1'b0;
      end
      else if (rst | al)
      begin
          c_state <= idle;
          cmd_ack <= 1'b0;
          scl_oen_master <=  1'b1;
          sda_oen_master <=  1'b1;
          sda_chk <= 1'b0;
      end
      else
      begin
          cmd_ack   <= 1'b0;  
          if (clk_en)
              case (c_state)  
                    idle:
                    begin
                        case (cmd)  
                             4'b0001: c_state <= start_a;
                             4'b0010:  c_state <= stop_a;
                             4'b0100: c_state <= wr_a;
                             4'b1000:  c_state <= rd_a;
                             default:        c_state <= idle;
                        endcase
                        scl_oen_master <= scl_oen_master;  
                        sda_oen_master <= sda_oen_master;  
                        sda_chk <= 1'b0;     
                    end
                    start_a:
                    begin
                        c_state <= start_b;
                        scl_oen_master <= scl_oen_master;  
                        sda_oen_master <= 1'b1;     
                        sda_chk <= 1'b0;     
                    end
                    start_b:
                    begin
                        c_state <= start_c;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    start_c:
                    begin
                        c_state <= start_d;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    start_d:
                    begin
                        c_state <= start_e;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    start_e:
                    begin
                        c_state <= idle;
                        cmd_ack <= 1'b1;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    stop_a:
                    begin
                        c_state <= stop_b;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    stop_b:
                    begin
                        c_state <= stop_c;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    stop_c:
                    begin
                        c_state <= stop_d;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b0;  
                        sda_chk <= 1'b0;  
                    end
                    stop_d:
                    begin
                        c_state <= idle;
                        cmd_ack <= 1'b1;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    rd_a:
                    begin
                        c_state <= rd_b;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    rd_b:
                    begin
                        c_state <= rd_c;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    rd_c:
                    begin
                        c_state <= rd_d;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    rd_d:
                    begin
                        c_state <= idle;
                        cmd_ack <= 1'b1;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= 1'b1;  
                        sda_chk <= 1'b0;  
                    end
                    wr_a:
                    begin
                        c_state <= wr_b;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= din;   
                        sda_chk <= 1'b0;  
                    end
                    wr_b:
                    begin
                        c_state <= wr_c;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= din;   
                        sda_chk <= 1'b0;  
                    end
                    wr_c:
                    begin
                        c_state <= wr_d;
                        scl_oen_master <= 1'b1;  
                        sda_oen_master <= din;
                        sda_chk <= 1'b1;  
                    end
                    wr_d:
                    begin
                        c_state <= idle;
                        cmd_ack <= 1'b1;
                        scl_oen_master <= 1'b0;  
                        sda_oen_master <= din;
                        sda_chk <= 1'b0;  
                    end
              endcase
      end
   reg [3:0] slave_cnt;
   assign sda_oen = master_mode ? sda_oen_master : sda_oen_slave ;
   assign scl_oen = master_mode ? scl_oen_master : scl_oen_slave ;
   reg 	     slave_act;
   reg 	     slave_adr_received_d;
   always @(posedge clk or negedge nReset)
     if (!nReset) begin
	slave_adr <=  8'h0;
	slave_cnt <=  4'h8;
	slave_adr_received <=  1'b0;
	slave_act <=  1'b0;
     end
     else begin
	slave_adr_received <=  1'b0;
	if ((sSCL & ~dSCL) && slave_cnt != 4'h0 && slave_act)	 begin
	   slave_adr <=  {slave_adr[6:0], sSDA};
	   slave_cnt <=  slave_cnt -4'd1;
	end
	else if (slave_cnt == 4'h0 && !sta_condition && slave_act) begin
	   slave_adr_received <=  1'b1;
	   slave_act <=  1'b0;
	end
	if (sta_condition) begin
	   slave_cnt <=  4'h8;
	   slave_adr <=  8'h0;
	   slave_adr_received <=  1'b0;
	   slave_act <=  1'b1;
	end
	if(sto_condition) begin
	   slave_adr_received <=  1'b0;
	   slave_act <=  1'b0;
	end
     end
   parameter [4:0] slave_idle    = 5'b0_0000;
   parameter [4:0] slave_wr      = 5'b0_0001;
   parameter [4:0] slave_wr_a    = 5'b0_0010;
   parameter [4:0] slave_rd      = 5'b0_0100;
   parameter [4:0] slave_rd_a    = 5'b0_1000;
   parameter [4:0] slave_wait_next_cmd_1   = 5'b1_0000;
   parameter [4:0] slave_wait_next_cmd_2   = 5'b1_0001;
   always @(posedge clk or negedge nReset)
     if (!nReset)
       begin
          slave_state <=  slave_idle;
          cmd_slave_ack   <=  1'b0;
          sda_oen_slave   <=  1'b1;
          scl_oen_slave   <=  1'b1;
       end
     else if (rst | sta_condition || !ena)
       begin
          slave_state <=  slave_idle;
          cmd_slave_ack   <=  1'b0;
          sda_oen_slave   <=  1'b1;
          scl_oen_slave   <=  1'b1;
       end
     else
       begin
          cmd_slave_ack   <=  1'b0;  
          if (sl_wait)
            scl_oen_slave   <=  1'b0;
          else
            scl_oen_slave   <=  1'b1;
          case (slave_state)
            slave_idle:
              begin
                 case (slave_cmd)  
                   2'b01: slave_state <=  slave_wr;
                   2'b10:
		     begin
			slave_state <=  slave_rd;
			sda_oen_slave <=  1'b1;
		     end
                   default:
		     begin
			slave_state <=  slave_idle;
			sda_oen_slave <=  1'b1;  
		     end
                 endcase
              end
            slave_wr:
              begin
                 if (~sSCL & ~dSCL)  begin  
                    slave_state <=  slave_wr_a;
                    sda_oen_slave <=  din;
                 end
              end
            slave_wr_a:
              begin
                 if (~sSCL & dSCL)  begin  
                    cmd_slave_ack <=  1'b1;
                    slave_state <=  slave_wait_next_cmd_1;
                 end
              end
	    slave_wait_next_cmd_1:
              slave_state <=  slave_wait_next_cmd_2;
	    slave_wait_next_cmd_2:
              slave_state <=  slave_idle;
            slave_rd:
              begin
                 if (sSCL & ~dSCL)  begin    
                    slave_state <=  slave_rd_a;
                 end
              end
            slave_rd_a:
              begin
                 if (~sSCL & dSCL)  begin        
                    cmd_slave_ack <=  1'b1;
                    slave_state <=  slave_wait_next_cmd_1;
                 end
              end
          endcase  
       end
   assign slave_reset = sta_condition | sto_condition;
    assign scl_o = 1'b0;
    assign sda_o = 1'b0;
endmodule
module i2c_master_byte_ctrl
  (
   clk, my_addr, rst, nReset, ena, clk_cnt, start, stop, read, write, ack_in,
   din, cmd_ack, ack_out, dout, i2c_busy, i2c_al, scl_i, sl_cont, scl_o,
   scl_oen, sda_i, sda_o, sda_oen,slave_dat_req, slave_en, slave_dat_avail,
   slave_act, slave_cmd_ack
   );
	input clk;      
    input [6:0] my_addr;  
	input rst;      
	input nReset;   
	input ena;      
    input sl_cont;
	input [15:0] clk_cnt;  
	input       start;
	input       stop;
	input       read;
	input       write;
	input       ack_in;
	input [7:0] din;
	output       cmd_ack;
	reg cmd_ack;
	output       ack_out;
	reg ack_out;
	output       i2c_busy;
	output       i2c_al;
	output [7:0] dout;
	input  scl_i;
	output scl_o;
	output scl_oen;
	input  sda_i;
	output sda_o;
	output sda_oen;
    input 	slave_en;
    output reg 	slave_dat_req;
    output reg 	slave_dat_avail;
    output reg 	slave_act;
    output reg 	slave_cmd_ack;
    parameter [9:0] ST_IDLE       = 10'b00_0000_0000;
    parameter [9:0] ST_START      = 10'b00_0000_0001;
    parameter [9:0] ST_READ       = 10'b00_0000_0010;
    parameter [9:0] ST_WRITE      = 10'b00_0000_0100;
    parameter [9:0] ST_ACK        = 10'b00_0000_1000;
    parameter [9:0] ST_STOP       = 10'b00_0001_0000;
    parameter [9:0] ST_SL_ACK     = 10'b00_0010_0000;
    parameter [9:0] ST_SL_RD      = 10'b00_0100_0000;
    parameter [9:0] ST_SL_WR      = 10'b00_1000_0000;
    parameter [9:0] ST_SL_WAIT    = 10'b01_0000_0000;
    parameter [9:0] ST_SL_PRELOAD = 10'b10_0000_0000;
	reg        sl_wait;
	wire [6:0] my_addr;
	reg  [3:0] core_cmd;
	reg        core_txd;
	wire       core_ack, core_rxd;
	wire   	   sl_cont;
	reg [7:0] sr;  
	reg       shift, ld;
	reg 	  master_mode;
	reg [1:0] slave_cmd_out;
	wire       go;
	reg  [2:0] dcnt;
	wire       cnt_done;
	wire       slave_ack;
	wire       slave_reset;
	wire        slave_adr_received;
	wire [7:0] 	slave_adr;
   reg [1:0] 	slave_cmd;
	i2c_master_bit_ctrl bit_controller (
		.clk     ( clk      ),
		.rst     ( rst      ),
		.nReset  ( nReset   ),
		.ena     ( ena      ),
		.clk_cnt ( clk_cnt  ),
		.cmd     ( core_cmd ),
		.cmd_ack ( core_ack ),
		.busy    ( i2c_busy ),
		.al      ( i2c_al   ),
		.din     ( core_txd ),
		.dout    ( core_rxd ),
		.scl_i   ( scl_i    ),
		.scl_o   ( scl_o    ),
		.scl_oen ( scl_oen  ),
		.sda_i   ( sda_i    ),
		.sda_o   ( sda_o    ),
		.sda_oen ( sda_oen  ),
		.slave_adr_received ( slave_adr_received  ),
		.slave_adr  ( slave_adr  ),
		.master_mode (master_mode),
		.cmd_slave_ack (slave_ack),
		.slave_cmd (slave_cmd_out),
		.sl_wait (sl_wait),
		.slave_reset (slave_reset)
	);
	reg 		slave_adr_received_d;
	assign go = (read | write | stop) & ~cmd_ack;
	assign dout = sr;
    always @(posedge clk or negedge nReset)
      if (!nReset)
        slave_adr_received_d <=  1'b0;
      else
        slave_adr_received_d <=   slave_adr_received;
	always @(posedge clk or negedge nReset)
	  if (!nReset)
	    sr <= 8'h0;
	  else if (rst)
	    sr <= 8'h0;
	  else if (ld)
	    sr <= din;
	  else if (shift)
	    sr <= {sr[6:0], core_rxd};
      else if (slave_adr_received_d & slave_act)
        sr <=  {slave_adr[7:1], 1'b0};
	always @(posedge clk or negedge nReset)
	  if (!nReset)
	    dcnt <= 3'h0;
	  else if (rst)
	    dcnt <= 3'h0;
	  else if (ld)
	    dcnt <= 3'h7;
	  else if (shift)
	    dcnt <= dcnt - 3'h1;
	assign cnt_done = ~(|dcnt);
    reg [9:0] 	c_state;  
	always @(posedge clk or negedge nReset)
	  if (!nReset)
	    begin
	        sl_wait <=  1'b0;
	        core_cmd <= 4'b0000;
	        core_txd <= 1'b0;
	        shift    <= 1'b0;
	        ld       <= 1'b0;
	        cmd_ack  <= 1'b0;
	        c_state  <= ST_IDLE;
	        ack_out  <= 1'b0;
	        master_mode <= 1'b0;
	        slave_cmd  <= 2'b0;
	        slave_dat_req	<= 1'b0;
	        slave_dat_avail	<= 1'b0;
	        slave_act <= 1'b0;
	        slave_cmd_out <= 2'b0;
	        slave_cmd_ack <= 1'b0;
	    end
     else if (rst | i2c_al | slave_reset)
	   begin
	       core_cmd <= 4'b0000;
	       core_txd <= 1'b0;
	       shift    <= 1'b0;
	       sl_wait  <=  1'b0;
	       ld       <= 1'b0;
	       cmd_ack  <= 1'b0;
	       c_state  <= ST_IDLE;
	       ack_out  <= 1'b0;
	       master_mode <=  1'b0;
	       slave_cmd  <=  2'b0;
	       slave_cmd_out <=  2'b0;
	       slave_dat_req	<=  1'b0;
          slave_dat_avail	<=  1'b0;
          slave_act <=  1'b0;
          slave_cmd_ack <=  1'b0;
	   end
	else
	  begin
	       slave_cmd_out <=  slave_cmd;
	      core_txd <= sr[7];
	      shift    <= 1'b0;
	      ld       <= 1'b0;
	      cmd_ack  <= 1'b0;
	      slave_cmd_ack <=  1'b0;
	      case (c_state)  
	        ST_IDLE:
			  begin
			     slave_act <=  1'b0;
			     if (slave_en & slave_adr_received &
				 (slave_adr[7:1] == my_addr )) begin
				c_state  <=  ST_SL_ACK;
				master_mode <=  1'b0;
				slave_act <=  1'b1;
				slave_cmd <=  2'b01;
				core_txd <=  1'b0;
			 end
		 else if (go && !slave_act )
	            begin
	                if (start)
	                  begin
	                      c_state  <= ST_START;
	                      core_cmd <= 4'b0001;
	                      master_mode <=  1'b1;
	                  end
	                else if (read)
	                  begin
	                      c_state  <= ST_READ;
	                      core_cmd <= 4'b1000;
	                  end
	                else if (write)
	                  begin
	                      c_state  <= ST_WRITE;
	                      core_cmd <= 4'b0100;
	                  end
	                else  
	                  begin
	                      c_state  <= ST_STOP;
	                      core_cmd <= 4'b0010;
	                  end
	                ld <= 1'b1;
	           end
	      end
            ST_SL_RD:  
              begin
				 slave_cmd <=  2'b00;
				 if (slave_ack) begin
					if (cnt_done) begin
					       c_state   <=  ST_SL_ACK;
					       slave_cmd <=  2'b10;
					    end
					    else
					      begin
					         c_state   <=  ST_SL_RD;
					         slave_cmd <=  2'b01;
					         shift     <=  1'b1;
					      end
				 end
              end
            ST_SL_WR:  
              begin
		 slave_cmd <=  2'b00;
		 if (slave_ack)
	           begin
	              if (cnt_done)
	                begin
	                   c_state  <=  ST_SL_ACK;
	                   slave_cmd <=  2'b01;
	                   core_txd <=  1'b0;
	                end
	              else
	                begin
	                   c_state  <=  ST_SL_WR;
	                   slave_cmd <=  2'b10;
	                end
	              shift    <=  1'b1;
	           end
	      end
            ST_SL_WAIT:  
              begin
                 sl_wait <=  1'b1;
                 if (sl_cont) begin
                    sl_wait <=  1'b0;
                    ld <=  1'b1;
                    slave_dat_req	<=  1'b0;
                    slave_dat_avail	<=  1'b0;
                    c_state   <=  ST_SL_PRELOAD;
	         end
              end
            ST_SL_PRELOAD:
              if (slave_adr[0]) begin
	         c_state   <=  ST_SL_RD;
	         slave_cmd <=  2'b01;
	      end
	      else begin
	         c_state  <=  ST_SL_WR;
	         slave_cmd <=  2'b10;
	      end
            ST_SL_ACK:
              begin
		 slave_cmd <=  2'b00;
		 if (slave_ack)  begin
                    ack_out <=  core_rxd;
                    slave_cmd_ack  <=  1'b1;
                    if (!core_rxd) begin  
                       c_state   <=  ST_SL_WAIT;
	               if (slave_adr[0]) begin  
	                  slave_dat_req	<=  1'b1;
	               end
	               else begin               
	                  slave_dat_avail	<=  1'b1;
	               end
	            end
	            else begin
	               c_state   <=  ST_IDLE;
	            end
	         end
	         else begin
	            core_txd <=  1'b0;
	         end
	            end
	        ST_START:
	          if (core_ack)
	            begin
	                if (read)
	                  begin
	                      c_state  <= ST_READ;
	                      core_cmd <= 4'b1000;
	                  end
	                else
	                  begin
	                      c_state  <= ST_WRITE;
	                      core_cmd <= 4'b0100;
	                  end
	                ld <= 1'b1;
	            end
	        ST_WRITE:
	          if (core_ack)
	            if (cnt_done)
	              begin
	                  c_state  <= ST_ACK;
	                  core_cmd <= 4'b1000;
	              end
	            else
	              begin
	                  c_state  <= ST_WRITE;        
	                  core_cmd <= 4'b0100;  
	                  shift    <= 1'b1;
	              end
	        ST_READ:
	          if (core_ack)
	            begin
	                if (cnt_done)
	                  begin
	                      c_state  <= ST_ACK;
	                      core_cmd <= 4'b0100;
	                  end
	                else
	                  begin
	                      c_state  <= ST_READ;        
	                      core_cmd <= 4'b1000;  
	                  end
	                shift    <= 1'b1;
	                core_txd <= ack_in;
	            end
	        ST_ACK:
	          if (core_ack)
	            begin
	               if (stop)
	                 begin
	                     c_state  <= ST_STOP;
	                     core_cmd <= 4'b0010;
	                 end
	               else
	                 begin
	                     c_state  <= ST_IDLE;
	                     core_cmd <= 4'b0000;
	                     cmd_ack  <= 1'b1;
	                 end
	                 ack_out <= core_rxd;
	                 core_txd <= 1'b1;
	             end
	           else
	             core_txd <= ack_in;
	        ST_STOP:
	          if (core_ack)
	            begin
	                c_state  <= ST_IDLE;
	                core_cmd <= 4'b0000;
	                cmd_ack  <= 1'b1;
	            end
	      endcase
	  end
endmodule
module i2c_master_top
  (
	wb_clk_i, wb_rst_i, arst_i, wb_adr_i, wb_dat_i, wb_dat_o,
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_inta_o,
	scl_pad_i, scl_pad_o, scl_padoen_o, sda_pad_i, sda_pad_o, sda_padoen_o );
    parameter ARST_LVL = 1'b1;  
    parameter [6:0] DEFAULT_SLAVE_ADDR  = 7'b111_1110;
	input        wb_clk_i;      
	input        wb_rst_i;      
	input        arst_i;        
	input  [2:0] wb_adr_i;      
	input  [7:0] wb_dat_i;      
	output [7:0] wb_dat_o;      
	input        wb_we_i;       
	input        wb_stb_i;      
	input        wb_cyc_i;      
	output       wb_ack_o;      
	output       wb_inta_o;     
	reg [7:0] wb_dat_o;
	reg wb_ack_o;
	reg wb_inta_o;
	input  scl_pad_i;        
	output scl_pad_o;        
	output scl_padoen_o;     
	input  sda_pad_i;        
	output sda_pad_o;        
	output sda_padoen_o;     
	reg  [15:0] prer;  
	reg  [ 7:0] ctr;   
	reg  [ 7:0] txr;   
	wire [ 7:0] rxr;   
	reg  [ 7:0] cr;    
	wire [ 7:0] sr;    
	reg  [ 6:0] sladr; 
	wire done;
	wire slave_done;
	wire core_en;
	wire ien;
	wire slave_en;
	wire slave_dat_req;
	wire slave_dat_avail;
	wire irxack;
	reg  rxack;        
	reg  tip;          
	reg  irq_flag;     
	wire i2c_busy;     
	wire i2c_al;       
	reg  al;           
	reg  slave_mode;
	wire  slave_act;
	wire rst_i = arst_i ^ ARST_LVL;
	wire wb_wacc = wb_we_i & wb_ack_o;
	always @(posedge wb_clk_i)
    wb_ack_o <=  wb_cyc_i & wb_stb_i & ~wb_ack_o;
	always @(posedge wb_clk_i)
	begin
	  case (wb_adr_i)  
	    3'b000: wb_dat_o <= prer[ 7:0];
	    3'b001: wb_dat_o <= prer[15:8];
	    3'b010: wb_dat_o <= ctr;
	    3'b011: wb_dat_o <= rxr;  
	    3'b100: wb_dat_o <= sr;   
	    3'b101: wb_dat_o <= txr;  
	    3'b110: wb_dat_o <= cr;   
	    3'b111: wb_dat_o <= {1'b0,sladr};    
	  endcase
	end
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    begin
	        prer <= 16'hffff;
	        ctr  <=  8'h0;
	        txr  <=  8'h0;
	        sladr <=  DEFAULT_SLAVE_ADDR;
	    end
	  else if (wb_rst_i)
	    begin
	        prer <= 16'hffff;
	        ctr  <=  8'h0;
	        txr  <=  8'h0;
	        sladr <=  DEFAULT_SLAVE_ADDR;
	    end
	  else
	    if (wb_wacc)
	      case (wb_adr_i)  
	         3'b000 : prer [ 7:0] <= wb_dat_i;
	         3'b001 : prer [15:8] <= wb_dat_i;
	         3'b010 : ctr         <= wb_dat_i;
	         3'b011 : txr         <= wb_dat_i;
	         3'b111 : sladr       <=  wb_dat_i[6:0];
	         default: ;
	      endcase
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    cr <= 8'h0;
	  else if (wb_rst_i)
	    cr <= 8'h0;
	  else if (wb_wacc)
	    begin
	        if (core_en & (wb_adr_i == 3'b100) )
	          cr <= wb_dat_i;
	    end
	  else
	    begin
	        cr[1] <=  1'b0;
	        if (done | i2c_al)
	          cr[7:4] <= 4'h0;            
	        cr[2] <=  1'b0;              
	        cr[0]   <= 1'b0;              
	    end
	wire sta  = cr[7];
	wire sto  = cr[6];
	wire rd   = cr[5];
	wire wr   = cr[4];
	wire ack  = cr[3];
	wire sl_cont = cr[1];
	wire iack = cr[0];
	assign core_en = ctr[7];
	assign ien = ctr[6];
	assign slave_en = ctr[5];
	i2c_master_byte_ctrl byte_controller (
		.clk      ( wb_clk_i     ),
		.my_addr  ( sladr        ),
		.rst      ( wb_rst_i     ),
		.nReset   ( rst_i        ),
		.ena      ( core_en      ),
		.clk_cnt  ( prer         ),
		.start    ( sta          ),
		.stop     ( sto          ),
		.read     ( rd           ),
		.write    ( wr           ),
		.ack_in   ( ack          ),
		.din      ( txr          ),
		.cmd_ack  ( done         ),
		.ack_out  ( irxack       ),
		.dout     ( rxr          ),
		.i2c_busy ( i2c_busy     ),
		.i2c_al   ( i2c_al       ),
		.scl_i    ( scl_pad_i    ),
		.scl_o    ( scl_pad_o    ),
		.scl_oen  ( scl_padoen_o ),
		.sda_i    ( sda_pad_i    ),
		.sda_o    ( sda_pad_o    ),
		.sda_oen  ( sda_padoen_o ),
		.sl_cont  ( sl_cont       ),
		.slave_en ( slave_en      ),
		.slave_dat_req (slave_dat_req),
		.slave_dat_avail (slave_dat_avail),
		.slave_act (slave_act),
		.slave_cmd_ack (slave_done)
	);
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    begin
	        al       <= 1'b0;
	        rxack    <= 1'b0;
	        tip      <= 1'b0;
	        irq_flag <= 1'b0;
	        slave_mode <=  1'b0;
	    end
	  else if (wb_rst_i)
	    begin
	        al       <= 1'b0;
	        rxack    <= 1'b0;
	        tip      <= 1'b0;
	        irq_flag <= 1'b0;
	        slave_mode <=  1'b0;
	    end
	  else
	    begin
	        al       <= i2c_al | (al & ~sta);
	        rxack    <= irxack;
	        tip      <= (rd | wr);
	        irq_flag <=  (done | slave_done| i2c_al | slave_dat_req |
	        		      slave_dat_avail | irq_flag) & ~iack;
	        if (done)
	          slave_mode <=  slave_act;
	    end
	always @(posedge wb_clk_i or negedge rst_i)
	  if (!rst_i)
	    wb_inta_o <= 1'b0;
	  else if (wb_rst_i)
	    wb_inta_o <= 1'b0;
	  else
        wb_inta_o <=  irq_flag && ien;
	assign sr[7]   = rxack;
	assign sr[6]   = i2c_busy;
	assign sr[5]   = al;
	assign sr[4]   = slave_mode;  
	assign sr[3]   = slave_dat_avail;
	assign sr[2]   = slave_dat_req;
	assign sr[1]   = tip;
	assign sr[0]   = irq_flag;
endmodule
