module sd_bd (
input clk,
input rst,
input we_m,
input [16-1:0] dat_in_m, 
output reg [5-1 :0] free_bd,
input  re_s,
output reg ack_o_s,
input a_cmp,
output reg[16-1:0] dat_out_s
);
 reg new_bw;
reg last_a_cmp;
reg [ 16 -1:0] bd_mem [ 32 -1 :0];   
reg [1:0]write_cnt; 
reg [1:0]read_s_cnt;
reg read_cnt;
reg [5 -1 :0] m_wr_pnt;
reg [5 -1 :0] s_rd_pnt ;
always @(posedge clk or posedge rst )
begin
   new_bw <=0;  
  if (rst) begin
    m_wr_pnt<=0;
    write_cnt<=0;
    new_bw <=0; 
    read_cnt<=0;
  end
  else if (we_m) begin    
    if (free_bd >0) begin
      write_cnt <=write_cnt+1;
      m_wr_pnt<=m_wr_pnt+1;
      if (!write_cnt[1]) begin       
        bd_mem[m_wr_pnt]<=dat_in_m;             
      end
      else begin         
        bd_mem[m_wr_pnt]<=dat_in_m;
        new_bw <=write_cnt[0];       
      end
     end
  end   
end
always @(posedge clk or posedge rst)
begin
  if (rst) begin  
    free_bd <=(32  /4);
    last_a_cmp<=0;
  end
  else if (new_bw ) begin
    free_bd <= free_bd-1;
  end  
  else if  (a_cmp) begin
    last_a_cmp <=a_cmp;
    if (!last_a_cmp)
     free_bd <= free_bd+1;
  end
 else
  last_a_cmp <=a_cmp;
end
always @(posedge clk or posedge rst)
begin
  if (rst) begin
    s_rd_pnt<=0;
	  read_s_cnt<=0;
	  ack_o_s<=0;
  end
  else if (re_s) begin
    read_s_cnt <=read_s_cnt+1;
    s_rd_pnt<=s_rd_pnt+1;
    ack_o_s<=1;
     if (!read_s_cnt[1])        
        dat_out_s<= bd_mem[s_rd_pnt];           
      else          
        dat_out_s<= bd_mem[s_rd_pnt];
  end  
  else
    ack_o_s<=0;
end
endmodule
module sd_clock_divider (
  input wire CLK,
  input  [7:0] DIVIDER,
  input wire RST,
  output  SD_CLK 
  );
  reg [7:0] ClockDiv;
  reg SD_CLK_O;
   assign SD_CLK = SD_CLK_O;
always @ (posedge CLK or posedge RST)
begin
 if (RST) begin
    ClockDiv <=8'b0000_0000;
    SD_CLK_O  <= 0;
 end 
 else if (ClockDiv == DIVIDER )begin
    ClockDiv  <= 0;
    SD_CLK_O <=  ~SD_CLK_O;
 end else begin
    ClockDiv  <= ClockDiv + 1;
    SD_CLK_O <=  SD_CLK_O;
end
end
 endmodule
module sd_cmd_master(
input CLK_PAD_IO,
input RST_PAD_I,
input New_CMD,
input data_write,
input data_read,
input [31:0]ARG_REG,
input [13:0]CMD_SET_REG,
input [15:0] TIMEOUT_REG,
output reg [15:0] STATUS_REG,
output reg [31:0] RESP_1_REG,
output reg [4:0] ERR_INT_REG, 
output reg [15:0] NORMAL_INT_REG, 
input ERR_INT_RST,
input NORMAL_INT_RST,
output reg [15:0] settings,
output reg go_idle_o,
output reg  [39:0] cmd_out,
output reg req_out,
output reg ack_out,
input req_in,
input ack_in,
input [39:0] cmd_in,
input [7:0] serial_status,
input card_detect
);
reg CRC_check_enable;
reg index_check_enable;
reg [6:0]response_size;
reg card_present;
reg [3:0]debounce;
reg [15:0]status;
reg [15:0]  Watchdog_Cnt;
reg complete;
parameter SIZE = 3;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;
parameter IDLE   =  3'b001;
parameter SETUP   =  3'b010;
parameter EXECUTE  =  3'b100;
reg ack_in_int;
reg ack_q;
reg req_q;
reg req_in_int;
always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    req_q<=0;
    req_in_int<=0;
 end 
else begin
  req_q<=req_in;  
  req_in_int<=req_q;
end
end  
always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    debounce<=0;
    card_present<=0;
 end 
else begin
	if (!card_detect) begin 
		if (debounce!=4'b1111)
			debounce<=debounce+1'b1;
	end
	else	
		 debounce<=0;
	if (debounce==4'b1111)
       card_present<=1'b1;
	else 
	   card_present<=1'b0;
end
end  
always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin
  if (RST_PAD_I) begin
    ack_q<=0;
    ack_in_int<=0;
 end 
else begin
  ack_q<=ack_in;
  ack_in_int<=ack_q;
end
end
always @ ( state or New_CMD or complete or ack_in_int )
begin : FSM_COMBO
    next_state = 0;
 case(state)
 IDLE:   begin
      if (New_CMD) begin
          next_state = SETUP;
      end     
      else begin
         next_state = IDLE;
      end   
 end       
 SETUP:begin
    if (ack_in_int)             
       next_state = EXECUTE;  
     else   
       next_state = SETUP;
   end  
 EXECUTE:    begin
       if (complete) begin
          next_state = IDLE;
      end     
      else begin
         next_state = EXECUTE;
      end
 end       
 default : next_state  = IDLE;
 endcase 
end
always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin : FSM_SEQ
  if (RST_PAD_I ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end
always @ (posedge CLK_PAD_IO or posedge RST_PAD_I   )
begin  
 if (RST_PAD_I ) begin 
    CRC_check_enable=0;
    complete =0;
    RESP_1_REG = 0;
    ERR_INT_REG =0;
    NORMAL_INT_REG=0;
    STATUS_REG=0;
    status=0; 
    cmd_out =0 ;
    settings=0;
    response_size=0;
    req_out=0;
    index_check_enable=0; 
    ack_out=0; 
    Watchdog_Cnt=0;
    ERR_INT_REG[1]=0;
    NORMAL_INT_REG[15] = 0;
    NORMAL_INT_REG[0] = 0; 
     go_idle_o=0;  
 end 
 else begin
 NORMAL_INT_REG[1] = card_present;
 NORMAL_INT_REG[2] = ~card_present;
 complete=0;
 case(state)
 IDLE: begin
    go_idle_o=0;  
    req_out=0;
		ack_out =0;
		STATUS_REG[0] =0; 
    if ( req_in_int == 1) begin      
        status=serial_status;
        ack_out = 1;
    end
 end
 SETUP:  begin
     NORMAL_INT_REG=0; 
     ERR_INT_REG =0;
     index_check_enable = CMD_SET_REG[4]; 
     CRC_check_enable = CMD_SET_REG[3];
    if ( (CMD_SET_REG[1:0]  == 2'b10 ) || ( CMD_SET_REG[1:0] == 2'b11)) begin
      response_size =  7'b0101000; 
    end
    else if (CMD_SET_REG[1:0] == 2'b01) begin
      response_size = 7'b1111111; 
    end    
    else begin
       response_size=0;
    end    
    cmd_out[39:38]=2'b01;         
    cmd_out[37:32]=CMD_SET_REG[13:8];   
    cmd_out[31:0]= ARG_REG;            
    settings[14:13]=CMD_SET_REG[7:6];              
    settings[12] = data_read;  
    settings[11] = data_write;
    settings[10:8]=3'b111;             
    settings[7]=CMD_SET_REG[3];          
    settings[6:0]=response_size;    
    Watchdog_Cnt = 0;
    STATUS_REG[0] =1;    
 end   
 EXECUTE: begin   
    Watchdog_Cnt = Watchdog_Cnt +1;
    if (Watchdog_Cnt>TIMEOUT_REG) begin
      ERR_INT_REG[0]=1;
      NORMAL_INT_REG[15] = 1;
      if (ack_in == 1) begin
         complete=1;
      end   
      go_idle_o=1; 
    end
    req_out=0;
		ack_out =0;
   	if (ack_in_int == 1) begin	    	     
	    		req_out =1;	   			   		
	  end	
	  else if ( req_in_int == 1) begin   
        status=serial_status;
        ack_out = 1; 
        if ( status[6] ) begin  
           complete=1;
            NORMAL_INT_REG[15] = 0;
           if (CRC_check_enable & ~status[5]) begin 
            ERR_INT_REG[1]=1;
            NORMAL_INT_REG[15] = 1;
           end 
           if (index_check_enable &  (cmd_out[37:32] != cmd_in [37:32]) ) begin
            ERR_INT_REG[3]=1;
            NORMAL_INT_REG[15] = 1;
           end
             NORMAL_INT_REG[0] = 1;  
             if (response_size !=0)
              RESP_1_REG=cmd_in[31:0];
         end  
       end  
     end  
   endcase
   if (ERR_INT_RST)
     ERR_INT_REG=0;
   if (NORMAL_INT_RST)
     NORMAL_INT_REG=0;
  end
end
endmodule
module sd_cmd_serial_host ( SD_CLK_IN, RST_IN, SETTING_IN ,CMD_IN, REQ_IN, ACK_OUT, REQ_OUT,ACK_IN, CMD_OUT, STATUS, cmd_dat_i, cmd_out_o, cmd_oe_o, st_dat_t);
input SD_CLK_IN;
input  RST_IN;
input [15:0] SETTING_IN;   
input [39:0] CMD_IN;
input   REQ_IN;
input ACK_IN;
input cmd_dat_i;
output [39:0] CMD_OUT;
output ACK_OUT;
output REQ_OUT;
output [7:0] STATUS;
output reg cmd_oe_o; 
output reg cmd_out_o;
output reg [1:0] st_dat_t;
wire SD_CLK_IN;
wire RST_IN;
wire [15:0] SETTING_IN;
wire [39:0] CMD_IN;
wire REQ_IN;
wire ACK_IN;
reg  [39:0] CMD_OUT;
wire ACK_OUT  ;
reg  [7:0] STATUS;
reg  REQ_OUT;
parameter SEND_SIZE = 48;
parameter SIZE = 10;
parameter CONTENT_SIZE = 40;
parameter 
    INIT   =  10'b0000_0000_01,
    IDLE   =  10'b0000_0000_10,
    WRITE_WR	    =  10'b0000_0001_00,
    DLY_WR       =  10'b0000_0010_00,
    READ_WR      =  10'b0000_0100_00,
	  DLY_READ    	=  10'b0000_1000_00, 
 	  ACK_WR		     =  10'b0001_0000_00, 
	  WRITE_WO	    =  10'b0010_0000_00, 
	  DLY_WO	      =  10'b0100_0000_00, 
	  ACK_WO	      =  10'b1000_0000_00;
parameter Read_Delay = 7;	
parameter EIGHT_PAD = 8;
reg [6:0] Response_Size;
reg [2:0] Delay_Cycler;
reg [CONTENT_SIZE-1:0] In_Buff; 
reg [39:0] Out_Buff;
reg Write_Read;
reg Write_Only; 
reg [4:0] word_select_counter;
reg CRC_RST;
reg [6:0]CRC_IN;
wire [6:0] CRC_VAL; 
reg CRC_Enable;
reg CRC_OUT;
reg CRC_Check_On;
reg Crc_Buffering;
reg CRC_Valid;
reg [7:0]Cmd_Cnt;  
reg [2:0]Delay_Cnt;  
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;
reg block_write;
reg block_read;
reg [1:0]word_select;
reg FSM_ACK;
reg DECODER_ACK;
reg q;
reg Req_internal_in;
reg q1;
reg Ack_internal_in;
sd_crc_7 CRC_7( 
CRC_OUT,
CRC_Enable,
SD_CLK_IN,
CRC_RST,
CRC_VAL);
always @ (state or Delay_Cnt or Write_Read or Cmd_Cnt or Write_Only or Ack_internal_in or  cmd_dat_i or Response_Size or Delay_Cycler)
begin : FSM_COMBO
 next_state  = 0;   
case(state)  
INIT: begin
  if (Cmd_Cnt >= 2 )begin
     next_state = IDLE;
  end
  else begin
      next_state = INIT;
  end
end
IDLE: begin        
	 if (Write_Read ) begin 
        next_state = WRITE_WR;
      end   
      else if (Write_Only  ) begin
        next_state = WRITE_WO;
      end
      else begin
         next_state = IDLE;
      end
end
WRITE_WR: 
      if (Cmd_Cnt >=SEND_SIZE-1) begin
        next_state = DLY_WR;
      end      
      else begin
        next_state = WRITE_WR; 
      end 
WRITE_WO: 
      if (Cmd_Cnt >= SEND_SIZE-1) begin
        next_state = DLY_WO;
      end      
      else begin
        next_state = WRITE_WO; 
      end 	  
DLY_WR : 
      if ( (Delay_Cnt >= 2) && ( !cmd_dat_i)) begin
        next_state = READ_WR;
      end      
      else begin
        next_state = DLY_WR; 
      end 	  
DLY_WO :
       if (Delay_Cnt >= Delay_Cycler) begin
        next_state = ACK_WO;
      end      
      else begin
        next_state = DLY_WO; 
      end 
READ_WR : 
      if (Cmd_Cnt >= (Response_Size+EIGHT_PAD)) begin
        next_state = DLY_READ;
      end      
      else begin
        next_state = READ_WR; 
      end 
ACK_WO : 
      next_state = IDLE; 
DLY_READ :
     if (Ack_internal_in ) begin
        next_state = ACK_WR;
      end      
      else begin
        next_state = DLY_READ; 
      end 	  
ACK_WR  :
        next_state = IDLE; 
default : next_state  = INIT;
 endcase     
end 
always @ (posedge SD_CLK_IN or posedge RST_IN)
begin : REQ_SYNC
	if  (RST_IN ) begin
		Req_internal_in <=1'b0;
		q <=1'b0;
	end
	else begin  
		q<=REQ_IN;
		Req_internal_in<=q;
	end
end
always @ (posedge SD_CLK_IN or posedge RST_IN)
begin :ACK_SYNC
	if  (RST_IN ) begin
		Ack_internal_in <=1'b0;
		q1 <=1'b0;
	end
	else begin  
		q1<=ACK_IN;
		Ack_internal_in<=q1;
	end
end
always @ (posedge SD_CLK_IN or posedge RST_IN )
  begin:COMMAND_DECODER
  if (RST_IN ) begin
		  Delay_Cycler <=3'b0;
		  Response_Size <=7'b0; 
		  DECODER_ACK <= 1;
		  Write_Read<=1'b0;
	    Write_Only<=1'b0;
	    CRC_Check_On <=0;
	    In_Buff <=0;
	    block_write<=0;
	    block_read <=0;
	    word_select<=0;
   end
   else begin
			if (Req_internal_in == 1) begin
				Response_Size[6:0] <=  SETTING_IN [6:0];
				CRC_Check_On <= SETTING_IN [7];
				Delay_Cycler[2:0] <= SETTING_IN [10:8];
				block_write <= SETTING_IN [11];
				block_read <= SETTING_IN [12];
				word_select <=SETTING_IN [14:13];
				In_Buff <= CMD_IN;
				DECODER_ACK<=0;	
				if (SETTING_IN [6:0]>0) begin
				   Write_Read<=1'b1;
				   Write_Only<=1'b0;
				end
				else begin
					Write_Read<=1'b0;
				  Write_Only<=1'b1;
				end
			end
			else begin
				Write_Read<=1'b0;
				Write_Only<=1'b0;
				DECODER_ACK <= 1;			
			end	
    end
 end
assign ACK_OUT = FSM_ACK & DECODER_ACK;
always @ (posedge SD_CLK_IN or posedge RST_IN   )
begin : FSM_SEQ
  if (RST_IN ) begin
    state <= #1 INIT;
 end 
 else begin
    state <= #1 next_state;
 end
end
always @ (posedge SD_CLK_IN or posedge RST_IN   )
begin : FSM_OUT
 if (RST_IN ) begin    
	    CRC_Enable=0;
	    word_select_counter<=0;
	    Delay_Cnt =0;
	   	cmd_oe_o=1; 		
	    cmd_out_o = 1;  
	  	 Out_Buff =0;
	   	FSM_ACK=1;
		REQ_OUT =0;
		  CRC_RST =1;
		  CRC_OUT =0;
		  CRC_IN =0;
		  CMD_OUT =0;	
	   	Crc_Buffering =0; 
	   	STATUS = 0;
	   	CRC_Valid=0;
	   	Cmd_Cnt=0;
	   	st_dat_t<=0;
 end 
 else begin
  case(state)
	INIT : begin
		Cmd_Cnt=Cmd_Cnt+1;
		cmd_oe_o=1; 		
		cmd_out_o = 1;  
	end
	IDLE : begin
		cmd_oe_o=0;       
		Delay_Cnt =0;
		Cmd_Cnt =0;
		CRC_RST =1;
		CRC_Enable=0; 
		CMD_OUT=0;
		st_dat_t<=0;
		word_select_counter<=0;		   
	end  
	WRITE_WR:   begin 
	   FSM_ACK=0;
       CRC_RST =0;
	   CRC_Enable=1;  
     if (Cmd_Cnt==0) begin
       STATUS = 16'b0000_0000_0000_0001;
       REQ_OUT=1;
     end 
     else if (Ack_internal_in) begin
       REQ_OUT=0;
     end 
     if (Crc_Buffering==1)  begin
        cmd_oe_o =1;
        if ((SEND_SIZE-Cmd_Cnt) > 8 ) begin   
				   cmd_out_o = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)]; 
				   if ((SEND_SIZE-Cmd_Cnt) > 9 ) begin  
			       CRC_OUT = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)-1];
			     end else begin
			       CRC_Enable=0;  
				   end    
			  end
			  else if ( ((SEND_SIZE-Cmd_Cnt) <=8) && ((SEND_SIZE-Cmd_Cnt) >=2) ) begin			 	
				  CRC_Enable=0; 
				  cmd_out_o = CRC_VAL[((SEND_SIZE-Cmd_Cnt))-2];	
		    	  if (block_read & block_write)
		    	    st_dat_t<=2'b11;
		    	  else  if  (block_read)
		    	    st_dat_t<=2'b10;    				
			  end
			  else begin        
				  cmd_out_o =1'b1;
			  end		
			  Cmd_Cnt = Cmd_Cnt+1 ;
		end		
	  else begin  
		    Crc_Buffering=1;
	   	  CRC_OUT = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)];
	  end	  
 	end 	
	WRITE_WO:  begin 
	   FSM_ACK=0;
     CRC_RST =0;
	   CRC_Enable=1;  
     if (Cmd_Cnt==0) begin
       STATUS[3:0] = 16'b0000_0000_0000_0010;
       REQ_OUT=1;
     end 
     else if (Ack_internal_in) begin
       REQ_OUT=0;
     end 
     if (Crc_Buffering==1)  begin
        cmd_oe_o =1;  
        if ((SEND_SIZE-Cmd_Cnt) > 8 ) begin   
			     cmd_out_o = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)]; 
			     if ((SEND_SIZE-Cmd_Cnt) > 9 ) begin  
			        CRC_OUT = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)-1];
			     end 
           else begin
			        CRC_Enable=0;  
			     end    
		    end
		    else if( ((SEND_SIZE-Cmd_Cnt) <=8) && ((SEND_SIZE-Cmd_Cnt) >=2) ) begin			 	
			     CRC_Enable=0; 
		       cmd_out_o = CRC_VAL[((SEND_SIZE-Cmd_Cnt))-2];	
		       if  (block_read)
		    	    st_dat_t<=2'b10;			
		    end		 
	  	   else begin        
		  	    cmd_out_o =1'b1;
		    end		
			  Cmd_Cnt = Cmd_Cnt+1;	
		end		
		else begin  
		   Crc_Buffering=1;
	   	 CRC_OUT = In_Buff[(CONTENT_SIZE-1-Cmd_Cnt)];
	  end	  
 	end 	
	DLY_WR :  begin 
	   if (Delay_Cnt==0) begin
         STATUS[3:0] = 4'b0011;
         REQ_OUT=1;
      end  
      else if (Ack_internal_in) begin
       REQ_OUT=0;
     end      
		  CRC_Enable=0;
		  CRC_RST =1;
		  Cmd_Cnt = 1; 
		  cmd_oe_o=0; 	
		  if (Delay_Cnt<3'b111)
		    Delay_Cnt =Delay_Cnt+1;  
		  Crc_Buffering=0;
    end
    DLY_WO :  begin  
      if (Delay_Cnt==0) begin
         STATUS[3:0] = 4'b0100;
         STATUS[5] = 0;
         STATUS[6] = 1;
         REQ_OUT=1;
      end  
      else if (Ack_internal_in) begin
       REQ_OUT=0;
     end   
		  CRC_Enable=0;
		  CRC_RST =1;
		  Cmd_Cnt = 0; 
		  cmd_oe_o=0;
	    Delay_Cnt =Delay_Cnt+1;  
	    Crc_Buffering=0;     
    end	
    READ_WR :  begin
      Delay_Cnt =0;
      CRC_RST =0;
	    CRC_Enable=1;        
      cmd_oe_o =0;
	   if (Cmd_Cnt==1) begin
       STATUS[3:0] = 16'b0000_0000_0000_0101;
       REQ_OUT=1;
       Out_Buff[39]=0;  
     end 
     else if (Ack_internal_in) begin
       REQ_OUT=0;
     end  
      if (Cmd_Cnt < (Response_Size))begin
        if (Cmd_Cnt<8 )  
          Out_Buff[39-Cmd_Cnt] = cmd_dat_i; 
        else begin
          if (word_select == 2'b00) begin
            if(Cmd_Cnt<40) begin
		          word_select_counter<= word_select_counter+1;
		          Out_Buff[31-word_select_counter] = cmd_dat_i;
		         end 
		      end    
          else if (word_select == 2'b01) begin
            if ( (Cmd_Cnt>=40) && (Cmd_Cnt<72) )begin
		          word_select_counter<= word_select_counter+1;
		          Out_Buff[31-word_select_counter] = cmd_dat_i;
		         end 
		      end 
          else if  (word_select == 2'b10) begin
           if ( (Cmd_Cnt>=72) && (Cmd_Cnt<104) )begin
		          word_select_counter<= word_select_counter+1;
		          Out_Buff[31-word_select_counter] = cmd_dat_i;
		         end 
		      end	     
          else if  (word_select == 2'b11) begin
           if ( (Cmd_Cnt>=104) && (Cmd_Cnt<128) )begin
		          word_select_counter<= word_select_counter+1;
		          Out_Buff[31-word_select_counter] = cmd_dat_i;
		         end 
		      end	  
		    end
		    CRC_OUT = cmd_dat_i;  
      end       
      else if ( Cmd_Cnt - Response_Size <=6 ) begin
			  CRC_IN [(Response_Size+6)-(Cmd_Cnt)] = cmd_dat_i;
			  CRC_Enable=0;  
      end
      else begin
			   if ((CRC_IN != CRC_VAL) && ( CRC_Check_On == 1)) begin
				   CRC_Valid=0;	
				   CRC_Enable=0;			  			
		    	end  
		    	else begin
		    	CRC_Valid=1;
		    	CRC_Enable=0;
		    	end 
		    	if (block_read & block_write)
		    	    st_dat_t<=2'b11;
		    	else if (block_write)
		    	  st_dat_t<=2'b01;
      end        
       Cmd_Cnt = Cmd_Cnt+1;
   end
   DLY_READ:  begin
     if (Delay_Cnt==0) begin
       STATUS[3:0] = 4'b0110;
       STATUS[5] = CRC_Valid;
       STATUS[6] = 1;
       REQ_OUT=1;
     end 
     else if (Ack_internal_in) begin
       REQ_OUT=0;
     end  
		  CRC_Enable=0;
		  CRC_RST =1;
		  Cmd_Cnt = 0; 		 
		  cmd_oe_o=0; 
      CMD_OUT[39:0]=Out_Buff;
		  Delay_Cnt =Delay_Cnt+1;       
    end	
	ACK_WO:  begin    
		  FSM_ACK=1;
    end	
	ACK_WR:  begin    
		  FSM_ACK=1;
		  REQ_OUT =0;	
    end	
   endcase
  end
end
endmodule
module sd_controller_wb(
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, 
  we_m_tx_bd, new_cmd,
  we_m_rx_bd, 
  we_ack, int_ack, cmd_int_busy,
  Bd_isr_reset,
  normal_isr_reset,
  error_isr_reset,
  int_busy,
  dat_in_m_tx_bd,
  dat_in_m_rx_bd,
  write_req_s,
  cmd_set_s,
  cmd_arg_s,
  argument_reg,
  cmd_setting_reg,
  status_reg,
  cmd_resp_1,
  software_reset_reg,
  time_out_reg,
  normal_int_status_reg,
  error_int_status_reg,
  normal_int_signal_enable_reg,
  error_int_signal_enable_reg,
  clock_divider,
  Bd_Status_reg,
  Bd_isr_reg,
  Bd_isr_enable_reg
  );
input           wb_clk_i;      
input           wb_rst_i;      
input   [31:0]  wb_dat_i;      
output reg [31:0]  wb_dat_o;      
input   [7:0]  wb_adr_i;      
input    [3:0]  wb_sel_i;      
input           wb_we_i;       
input           wb_cyc_i;      
input           wb_stb_i;      
output reg         wb_ack_o;      
output reg we_m_tx_bd;
output reg new_cmd;
output reg we_ack;  
output reg int_ack;  
output reg cmd_int_busy;
output reg we_m_rx_bd;  
output reg int_busy;
input write_req_s;
input wire [15:0] cmd_set_s;
input wire [31:0] cmd_arg_s;
   parameter power_controll_reg  = 8'b0000_111_1;
parameter block_size_reg = 512 ;  
     parameter controll_setting_reg =16'b0000_0000_0000_0010;
     parameter capabilies_reg =16'b0000_0000_0000_0000;
output reg [31:0] argument_reg;
output reg [15:0] cmd_setting_reg;
input  wire [15:0] status_reg;
input wire [31:0] cmd_resp_1;
output reg [7:0] software_reset_reg; 
output reg [15:0] time_out_reg;   
input wire [15:0]normal_int_status_reg; 
input wire [15:0]error_int_status_reg;
output reg [15:0]normal_int_signal_enable_reg;
output reg [15:0]error_int_signal_enable_reg;
output reg [7:0] clock_divider;
input  wire [15:0] Bd_Status_reg;   
input  wire [7:0] Bd_isr_reg;
output reg [7:0] Bd_isr_enable_reg;
output reg Bd_isr_reset;
output reg normal_isr_reset;
output reg error_isr_reset;
output reg [16-1:0] dat_in_m_rx_bd;  
output reg [16-1:0] dat_in_m_tx_bd;
reg [1:0] we;
always @(posedge wb_clk_i or posedge wb_rst_i)
	begin
	  we_m_rx_bd <= 0;
   	we_m_tx_bd <= 0;
	  new_cmd<= 1'b0 ;
	  we_ack <= 0;
	  int_ack =  1;
	  cmd_int_busy<=0;
     if ( wb_rst_i )begin
	    argument_reg <=0;
      cmd_setting_reg <= 0;
	    software_reset_reg <= 0;
	    time_out_reg <= 0;
	    normal_int_signal_enable_reg <= 0;
	    error_int_signal_enable_reg <= 0;	  
	    clock_divider <=0;
	    int_ack=1 ;
	    we<=0;
	    int_busy <=0;
	    we_ack <=0;
	    wb_ack_o=0;
	    cmd_int_busy<=0;
	    Bd_isr_reset<=0;
	    dat_in_m_tx_bd<=0;
	    dat_in_m_rx_bd<=0;
	    Bd_isr_enable_reg<=0;
	    normal_isr_reset<=0;
	    error_isr_reset<=0;
	  end
	  else if ((wb_stb_i  & wb_cyc_i) || wb_ack_o )begin 
	    Bd_isr_reset<=0; 
	     normal_isr_reset<=  0;
	    error_isr_reset<=  0;
	    if (wb_we_i) begin
	      case (wb_adr_i) 
	        8'h00: begin  
	            argument_reg  <=  wb_dat_i;
	            new_cmd <=  1'b1 ;	            
	         end
	        8'h04 : begin 
	            cmd_setting_reg  <=  wb_dat_i;
	            int_busy <= 1;
	        end
          8'h28 : software_reset_reg <=  wb_dat_i;
          8'h2c : time_out_reg  <=  wb_dat_i;
          8'h38 : normal_int_signal_enable_reg <=  wb_dat_i;
          8'h3c : error_int_signal_enable_reg  <=  wb_dat_i;
          8'h30 : normal_isr_reset<=  1;
          8'h34:  error_isr_reset<=  1;
	        8'h4c: clock_divider  <=  wb_dat_i;
	        8'h54: Bd_isr_reset<=  1;	    
	        8'h58 : Bd_isr_enable_reg <= wb_dat_i ;     
	        8'h60: begin
	             we <= we+1;	           
	             we_m_rx_bd <= 1;
	             int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_rx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_rx_bd <=  wb_dat_i[15:0];	                    
	           else if ( we[1:0]==2'b10) 
	             dat_in_m_rx_bd <=  wb_dat_i[31:16];	            
	           else begin
	             int_ack =  1; 
	              we<= 0;
	              we_m_rx_bd <= 0;
	            end
	        end
	        8'h80: begin
	           we <= we+1;	           
	           we_m_tx_bd <= 1;
	           int_ack =  0;	
	           if  (we[1:0]==2'b00)
	             we_m_tx_bd <= 0;
	           else if  (we[1:0]==2'b01) 
	            dat_in_m_tx_bd <=  wb_dat_i[15:0];	                    
	           else if ( we[1:0]==2'b10) 
	             dat_in_m_tx_bd <=  wb_dat_i[31:16];	            
	           else begin
	             int_ack =  1; 
	              we<= 0;
	              we_m_tx_bd <= 0;
	            end
	        end
	      endcase
	    end     	     
	wb_ack_o =   wb_cyc_i & wb_stb_i & ~wb_ack_o & int_ack; 
	 end
	    else if (write_req_s) begin
	       new_cmd <=  1'b1 ; 
	       cmd_setting_reg <=   cmd_set_s; 
	       argument_reg  <=  cmd_arg_s ; 
	       cmd_int_busy<=  1; 
	       we_ack <= 1;
	    end  
	 if (status_reg[0])
	    int_busy <=  0; 
end
always @(posedge wb_clk_i )begin
   if (wb_stb_i  & wb_cyc_i) begin  
      case (wb_adr_i)
	         8'h00:  wb_dat_o  <=   argument_reg ;
	         8'h04 : wb_dat_o <=  cmd_setting_reg ;
	         8'h08 : wb_dat_o <=  status_reg ;
           8'h0c : wb_dat_o <=  cmd_resp_1 ;   
           8'h1c : wb_dat_o <=  controll_setting_reg ;
           8'h20 :  wb_dat_o <=  block_size_reg ;
           8'h24 : wb_dat_o <=  power_controll_reg ;
           8'h28 : wb_dat_o  <=  software_reset_reg ;
           8'h2c : wb_dat_o  <=  time_out_reg ;
           8'h30 : wb_dat_o <=  normal_int_status_reg ;
           8'h34 : wb_dat_o  <=  error_int_status_reg ;
           8'h38 : wb_dat_o <=  normal_int_signal_enable_reg ;
           8'h3c : wb_dat_o  <=  error_int_signal_enable_reg ;
            8'h4c : wb_dat_o  <= clock_divider;
	         8'h48  : wb_dat_o  <=  capabilies_reg ; 
	         8'h50 : wb_dat_o  <=  Bd_Status_reg; 
	         8'h54 : wb_dat_o  <=  Bd_isr_reg ; 
	         8'h58 : wb_dat_o  <=  Bd_isr_enable_reg ; 
	    endcase
	  end 
end
endmodule
module sd_crc_7(BITVAL, Enable, CLK, RST, CRC);
   input        BITVAL; 
   input Enable;
   input        CLK;                            
   input        RST;                              
   output [6:0] CRC;                                
   reg    [6:0] CRC;   
   wire         inv;
   assign inv = BITVAL ^ CRC[6];                    
    always @(posedge CLK or posedge RST) begin
		if (RST) begin
			CRC = 0;   
        end
		else begin
			if (Enable==1) begin
				CRC[6] = CRC[5];
				CRC[5] = CRC[4];
				CRC[4] = CRC[3];
				CRC[3] = CRC[2] ^ inv;
				CRC[2] = CRC[1];
				CRC[1] = CRC[0];
				CRC[0] = inv;
			end
		end
     end
endmodule
module sd_crc_16(BITVAL, Enable, CLK, RST, CRC);
 input        BITVAL; 
   input Enable;
   input        CLK;                            
   input        RST;                              
   output reg [15:0] CRC;                                
   wire         inv;
   assign inv = BITVAL ^ CRC[15];                    
  always @(posedge CLK or posedge RST) begin
		if (RST) begin
			CRC = 0;   
        end
      else begin
        if (Enable==1) begin
         CRC[15] = CRC[14];
         CRC[14] = CRC[13];
         CRC[13] = CRC[12];
         CRC[12] = CRC[11] ^ inv;
         CRC[11] = CRC[10];
         CRC[10] = CRC[9];
         CRC[9] = CRC[8];
         CRC[8] = CRC[7];
         CRC[7] = CRC[6];
         CRC[6] = CRC[5];
         CRC[5] = CRC[4] ^ inv;
         CRC[4] = CRC[3];
         CRC[3] = CRC[2];
         CRC[2] = CRC[1];
         CRC[1] = CRC[0];
         CRC[0] = inv;
        end
         end
      end
endmodule
module sd_data_master (
  input clk,
  input rst,
  input [16-1:0] dat_in_tx,
  input [5-1:0] free_tx_bd,
  input ack_i_s_tx,
  output reg re_s_tx,
  output reg a_cmp_tx,
  input [16-1:0] dat_in_rx,
  input [5-1:0] free_rx_bd,
  input ack_i_s_rx,
  output reg re_s_rx,
  output reg a_cmp_rx,
  input  cmd_busy,  
  output reg we_req,
  input we_ack,
  output reg d_write,
  output reg d_read,
  output reg [31:0] cmd_arg,
  output reg [15:0] cmd_set,
  input cmd_tsf_err,
  input [4:0] card_status,
  output reg start_tx_fifo,
  output reg start_rx_fifo,
  output reg [31:0] sys_adr,
  input tx_empt,
  input tx_full,
  input rx_full,
  input busy_n     ,
  input transm_complete ,
  input crc_ok,
  output reg ack_transfer, 
  output reg  [7:0] Dat_Int_Status ,
  input Dat_Int_Status_rst,
  output reg  CIDAT,
  input [1:0] transfer_type
  );
       reg [2:0] bd_cnt;
reg send_done;
reg rec_done;
reg rec_failed;
reg tx_cycle;
reg rx_cycle;
reg [2:0] resend_try_cnt;
parameter CMD24 = 16'h181A ;  
parameter CMD17 = 16'h111A;  
parameter CMD12 = 16'hC1A ;  
parameter ACMD13 = 16'hD1A ;  
parameter ACMD51 = 16'h331A ;  
parameter SIZE = 9;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;  
parameter IDLE             =  9'b000000001;
parameter GET_TX_BD        =  9'b000000010;
parameter GET_RX_BD        =  9'b000000100;
parameter SEND_CMD         =  9'b000001000;
parameter RECIVE_CMD       =  9'b000010000;
parameter DATA_TRANSFER    =  9'b000100000;
parameter STOP             =  9'b001000000;
parameter STOP_SEND        =  9'b010000000;
parameter STOP_RECIVE_CMD  =  9'b100000000;
reg trans_done;
reg trans_failed;
reg internal_transm_complete;
reg transm_complete_q;
always @ (posedge clk or posedge rst )
begin
	if  (rst) begin
		internal_transm_complete <=1'b0;
		transm_complete_q<=0;
	end
	else begin  
		transm_complete_q<=transm_complete;
		internal_transm_complete<=transm_complete_q;
	end
end
always @ (state or resend_try_cnt or tx_full or free_tx_bd or free_rx_bd or bd_cnt or send_done or rec_done or rec_failed or trans_done or trans_failed)
begin : FSM_COMBO
 next_state  = 0;   
case(state)  
  IDLE: begin
   if (free_tx_bd !=(32  /4))begin
      next_state = GET_TX_BD;
   end
   else if (free_rx_bd !=(32  /4)) begin
      next_state = GET_RX_BD;
   end  
   else begin
      next_state = IDLE;
   end
  end
  GET_TX_BD: begin
    if ( ( bd_cnt> 4-1) && (tx_full==1) )begin
     next_state = SEND_CMD;
    end   
    else begin
     next_state = GET_TX_BD;
    end
  end   
  GET_RX_BD: begin  
    if (bd_cnt >= (4-1))begin
     next_state = SEND_CMD;
    end   
    else begin
     next_state = GET_RX_BD;
    end
  end
  SEND_CMD: begin 
   if (send_done)begin
     next_state = RECIVE_CMD;
    end   
    else begin
     next_state = SEND_CMD;
    end 
  end
 RECIVE_CMD: begin 
    if (rec_done)
      next_state = DATA_TRANSFER;       
    else if (rec_failed)
      next_state =  SEND_CMD;
    else 
      next_state = RECIVE_CMD;    
   end 
  DATA_TRANSFER: begin
    if (trans_done)
      next_state = IDLE;
   else if (trans_failed)
      next_state = STOP;
   else
      next_state = DATA_TRANSFER;
   end
  STOP: begin 
     next_state = STOP_SEND;     
   end
   STOP_SEND: begin
    if (send_done)begin
     next_state =IDLE;
    end   
    else begin
     next_state = STOP_SEND;
    end  
   end
   STOP_RECIVE_CMD : begin
    if (rec_done)
      next_state = SEND_CMD;       
    else if (rec_failed)
      next_state =  STOP;
    else if (resend_try_cnt>=3)
      next_state = IDLE;
    else 
      next_state = STOP_RECIVE_CMD;    
   end 
 default : next_state  = IDLE; 
 endcase
end
always @ (posedge clk or posedge rst   )
begin : FSM_SEQ
  if (rst ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end
always @ (posedge clk or posedge rst   )
begin  
 if (rst) begin
      send_done<=0;
      bd_cnt<=0;
      sys_adr<=0;
      cmd_arg<=0;
      rec_done<=0;
      start_tx_fifo<=0;
      start_rx_fifo<=0;
      send_done<=0;
      rec_failed<=0;
      d_write <=0;  
      d_read <=0;  
      trans_failed<=0;
      trans_done<=0;
      tx_cycle <=0;
      rx_cycle <=0;
      ack_transfer<=0;
      a_cmp_tx<=0;           
      a_cmp_rx<=0;
      CIDAT<=0;
      Dat_Int_Status<=0;
      we_req<=0;
      re_s_tx<=0;
      re_s_rx<=0;
      cmd_set<=0;
      resend_try_cnt=0;
 end
 else begin
  case(state)
     IDLE: begin
      send_done<=0;
      bd_cnt<=0;
      sys_adr<=0;
      cmd_arg<=0;
      rec_done<=0;
      rec_failed<=0;
      start_tx_fifo<=0;
      start_rx_fifo<=0;
      send_done<=0;     
      d_write <=0;  
      d_read <=0; 
      trans_failed<=0;
      trans_done<=0;
      tx_cycle <=0;
      rx_cycle <=0;
      ack_transfer<=0;
      a_cmp_tx<=0;           
      a_cmp_rx<=0;
      resend_try_cnt=0;
     end
     GET_RX_BD: begin                 
      re_s_rx <= 1;
      	if (ack_i_s_rx) begin        
	        if( bd_cnt == 2'b00) begin
	           sys_adr [15:0] <= dat_in_rx; 
	        end
	        else if ( bd_cnt == 2'b01)  begin
	           sys_adr [31:16] <= dat_in_rx; 
	        end
	        else if ( bd_cnt == 2) begin
	          cmd_arg [15:0] <= dat_in_rx;
	          re_s_rx <= 0; 
	        end
	        else if ( bd_cnt == 3) begin
	           cmd_arg [31:16] <= dat_in_rx;
	           re_s_rx <= 0;
	         end
	         bd_cnt <= bd_cnt+1;       
	   	end
      if (transfer_type==2'b00)
		   cmd_set <= CMD17;
		else if (transfer_type==2'b01)
		   cmd_set <= ACMD13;	 
		else 
      	   cmd_set <= ACMD51;
      rx_cycle<=1;  
     end
     GET_TX_BD:  begin             
      re_s_tx <= 1;
      if ( bd_cnt == 4)
        re_s_tx <= 0;
      if (ack_i_s_tx) begin
        if( bd_cnt == 0) begin
           sys_adr [15:0] <= dat_in_tx; 
           bd_cnt <= bd_cnt+1;   end
        else if ( bd_cnt == 1)  begin
           sys_adr [31:16] <= dat_in_tx;
           bd_cnt <= bd_cnt+1;    end
        else if ( bd_cnt == 2) begin
          cmd_arg [15:0] <= dat_in_tx;
          re_s_tx <= 0;
          bd_cnt <= bd_cnt+1;    end
        else if ( bd_cnt == 3) begin
           cmd_arg [31:16] <= dat_in_tx;
           re_s_tx <= 0;
           bd_cnt <= bd_cnt+1;
		   start_tx_fifo<=1;  
         end
       end
      cmd_set <= CMD24;  
      tx_cycle <=1;   
   end  
     SEND_CMD : begin  
       rec_done<=0;     
       if (rx_cycle)    begin     
         re_s_rx <=0; 
         d_read<=1;
       end
       else begin
         re_s_tx <=0; 
         d_write<=1;
        end
       start_rx_fifo<=0;  
       if (!cmd_busy) begin
         we_req <= 1;  
       end   
       if (we_ack) begin     
           send_done<=1;
           we_req <= 1;  
       end       
    end   
    RECIVE_CMD : begin
        if (rx_cycle)
         start_rx_fifo<=1;  
         we_req <= 0;  
         send_done<=0;
       if (!cmd_busy) begin  
         d_read<=0; 
         d_write<=0;  
         if (!cmd_tsf_err) begin
           if (card_status[0]) begin
                if ( (card_status[4:1] == 4'b0100) || (card_status[4:1] == 4'b0110) || (card_status[4:1] == 4'b0101) )
                    rec_done<=1;
                else begin
                    rec_failed<=1;
                    Dat_Int_Status[4] <=1; 
                       start_tx_fifo<=0;  
                end 
          end
         end
         else begin
             rec_failed<=1;   
                start_tx_fifo<=0;  
                end
       end  
    end
    DATA_TRANSFER: begin
       CIDAT<=1;
     if (tx_cycle) begin 
      if (tx_empt) begin
         Dat_Int_Status[2] <=1;
         trans_failed<=1;  
       end
     end
     else begin 
       if (rx_full) begin
         Dat_Int_Status[2] <=1; 
         trans_failed<=1; 
      end
    end            
      if (internal_transm_complete) begin  
         ack_transfer<=1;
         if ((!crc_ok) && (busy_n))  begin  
            Dat_Int_Status[5] <=1; 
            trans_failed<=1;
         end 
         else if ((crc_ok) && (busy_n)) begin  
           trans_done <=1;       
			if (tx_cycle) begin
				a_cmp_tx<=1;
				if (free_tx_bd ==(32  /4)-1 )
					Dat_Int_Status[0]<=1;
			end 
			else begin
				a_cmp_rx<=1;                        
				if (free_rx_bd ==(32  /4)-1)
					Dat_Int_Status[0]<=1;
			end
       end
  end
  end
  STOP: begin
    cmd_set <= CMD12;
    rec_done<=0;
    rec_failed<=0;     
    send_done<=0;  
    trans_failed<=0;
    trans_done<=0;    
    d_read<=1; 
    d_write<=1; 
    start_rx_fifo <=0;
    start_tx_fifo <=0;         
  end
   STOP_SEND: begin
      resend_try_cnt=resend_try_cnt+1;
      if (resend_try_cnt==3)
          Dat_Int_Status[1]<=1;
      if (!cmd_busy) 
         we_req <= 1;      
      if (we_ack)      
           send_done<=1;    
   end  
   STOP_RECIVE_CMD: begin
     we_req <= 0; 
    end
  endcase  
  if (Dat_Int_Status_rst)
    Dat_Int_Status<=0;
 end 
end  
endmodule 
module sd_data_serial_host(
input sd_clk,
input rst,
input [31:0] data_in ,
output reg rd,
output  reg  [4-1:0] data_out ,
output reg we,
output reg DAT_oe_o,
output reg[4-1:0] DAT_dat_o,
input  [4-1:0] DAT_dat_i,
input [1:0] start_dat,
input ack_transfer,
output reg busy_n,
output reg transm_complete,
output reg crc_ok
);
reg [4-1:0] crc_in;
reg crc_en;
reg crc_rst;
wire [15:0] crc_out [4-1:0];
reg  [4-1:0] temp_in;
reg [10:0] transf_cnt;
parameter SIZE = 6;
reg [SIZE-1:0] state;
reg [SIZE-1:0] next_state;
parameter IDLE        = 6'b000001;
parameter WRITE_DAT   = 6'b000010;
parameter WRITE_CRC   = 6'b000100;
parameter WRITE_BUSY  = 6'b001000;
parameter READ_WAIT   = 6'b010000;      
parameter READ_DAT    = 6'b100000;
reg [2:0] crc_status; 
reg busy_int;   
genvar i;
generate
for(i=0; i<4; i=i+1) begin:CRC_16_gen
  sd_crc_16 CRC_16_i (crc_in[i],crc_en, sd_clk, crc_rst, crc_out[i]);
end
endgenerate
reg ack_transfer_int;
reg ack_q;
always @ (posedge sd_clk or posedge rst   )
begin: ACK_SYNC
if (rst) begin
  ack_transfer_int <=0;
  ack_q<=0;end
else begin
  ack_q<=ack_transfer;
  ack_transfer_int<=ack_q;
  end
end
reg q_start_bit;
always @ (state or start_dat or q_start_bit or  transf_cnt or crc_status or busy_int or DAT_dat_i or ack_transfer_int)
begin : FSM_COMBO
 next_state  = 0;   
case(state)
  IDLE: begin
   if (start_dat == 2'b01) 
      next_state=WRITE_DAT;
    else if  (start_dat == 2'b10) 
      next_state=READ_WAIT;
    else 
      next_state=IDLE;
    end
  WRITE_DAT: begin
    if (transf_cnt >= 1044) 
       next_state= WRITE_CRC;
   else if (start_dat == 2'b11)
        next_state=IDLE;
    else 
       next_state=WRITE_DAT;
  end
  WRITE_CRC: begin
    if (crc_status ==0) 
       next_state= WRITE_BUSY;
    else 
       next_state=WRITE_CRC;
  end
  WRITE_BUSY: begin
      if ( (busy_int ==1)  & ack_transfer_int)
       next_state= IDLE;
    else 
       next_state  = WRITE_BUSY;
  end
  READ_WAIT: begin
    if (q_start_bit== 0 ) 
       next_state= READ_DAT;
    else 
       next_state=READ_WAIT;
  end
  READ_DAT: begin
    if ( ack_transfer_int)   
       next_state= IDLE;
    else if (start_dat == 2'b11)
        next_state=IDLE;   
    else 
       next_state=READ_DAT;
    end
 endcase
end 
always @ (posedge sd_clk or posedge rst   )
 begin :START_SYNC
  if (rst ) begin
    q_start_bit<=1;
 end 
 else begin
    if (!DAT_dat_i[0] & state == READ_WAIT)
    q_start_bit <= 0;
    else
    q_start_bit <= 1;
 end
end
always @ (posedge sd_clk or posedge rst   )
begin : FSM_SEQ
  if (rst ) begin
    state <= #1 IDLE;
 end 
 else begin
    state <= #1 next_state;
 end
end
reg [4:0] crc_c;
reg [3:0] last_din;
reg [2:0] crc_s ;
reg [31:0] write_buf_0,write_buf_1, sd_data_out;
reg out_buff_ptr,in_buff_ptr;
reg [2:0] data_send_index;
always @ (negedge sd_clk or posedge rst   )
begin  : FSM_OUT
 if (rst) begin
write_buf_0<=0;
write_buf_1<=0;
   DAT_oe_o<=0;
   crc_en<=0;
   crc_rst<=1;
   transf_cnt<=0;
   crc_c<=15;
   rd<=0;
   last_din<=0;
   crc_c<=0;
   crc_in<=0;
   DAT_dat_o<=0;
   crc_status<=7;
   crc_s<=0;
   transm_complete<=0;
   busy_n<=1;
   we<=0;
   data_out<=0;
   crc_ok<=0;
   busy_int<=0;
     data_send_index<=0;
        out_buff_ptr<=0;
        in_buff_ptr<=0;
 end
 else begin
 case(state)
   IDLE: begin
      DAT_oe_o<=0;
      DAT_dat_o<=4'b1111;
      crc_en<=0;
      crc_rst<=1;
      transf_cnt<=0;
      crc_c<=16;
      crc_status<=7;
      crc_s<=0;
      we<=0;
      rd<=0;
      busy_n<=1;
        data_send_index<=0;
        out_buff_ptr<=0;
        in_buff_ptr<=0;
   end
   WRITE_DAT: begin    
      transm_complete <=0;  
      busy_n<=0;
      crc_ok<=0;
      transf_cnt<=transf_cnt+1; 
       rd<=0; 
      if ( (in_buff_ptr != out_buff_ptr) ||  (!transf_cnt) ) begin
        rd <=1;           
       if (!in_buff_ptr)
         write_buf_0<=data_in;         
       else
        write_buf_1 <=data_in;    
       in_buff_ptr<=in_buff_ptr+1;
     end
      if (!out_buff_ptr)
        sd_data_out<=write_buf_0;
      else
       sd_data_out<=write_buf_1;
        if (transf_cnt==1) begin
          crc_rst<=0;
          crc_en<=1;
          	last_din <=write_buf_0[31:28]; 
          	crc_in<= write_buf_0[31:28]; 
          DAT_oe_o<=1;  
          DAT_dat_o<=0;
          data_send_index<=1;    
        end
        else if ( (transf_cnt>=2) && (transf_cnt<=1044-19 )) begin                 
          DAT_oe_o<=1;    
        case (data_send_index) 
           0:begin 
              last_din <=sd_data_out[31:28];
              crc_in <=sd_data_out[31:28];
           end
           1:begin 
              last_din <=sd_data_out[27:24];
              crc_in <=sd_data_out[27:24];
           end
           2:begin 
              last_din <=sd_data_out[23:20];
              crc_in <=sd_data_out[23:20];
           end
           3:begin 
              last_din <=sd_data_out[19:16];
              crc_in <=sd_data_out[19:16];
           end
           4:begin 
              last_din <=sd_data_out[15:12];
              crc_in <=sd_data_out[15:12];
           end
           5:begin 
              last_din <=sd_data_out[11:8];
              crc_in <=sd_data_out[11:8];
           end
           6:begin 
              last_din <=sd_data_out[7:4];
              crc_in <=sd_data_out[7:4];
              out_buff_ptr<=out_buff_ptr+1;
           end
           7:begin 
              last_din <=sd_data_out[3:0];
              crc_in <=sd_data_out[3:0];              
           end
         endcase 
          data_send_index<=data_send_index+1;
          DAT_dat_o<= last_din; 
          if ( transf_cnt >=1044-19 ) begin
             crc_en<=0;             
         end
       end
       else if (transf_cnt>1044-19 & crc_c!=0) begin
        rd<=0;
         crc_en<=0;
         crc_c<=crc_c-1;      
         DAT_oe_o<=1; 
         DAT_dat_o[0]<=crc_out[0][crc_c-1];
         DAT_dat_o[1]<=crc_out[1][crc_c-1];
         DAT_dat_o[2]<=crc_out[2][crc_c-1];
         DAT_dat_o[3]<=crc_out[3][crc_c-1];         
       end
       else if (transf_cnt==1044-2) begin
          DAT_oe_o<=1; 
          DAT_dat_o<=4'b1111;
           rd<=0;
      end   
       else if (transf_cnt !=0) begin
         DAT_oe_o<=0; 
         rd<=0;
         end
   end
   WRITE_CRC : begin
      rd<=0;
      DAT_oe_o<=0; 
      crc_status<=crc_status-1;
      if  (( crc_status<=4) && ( crc_status>=2) )
      crc_s[crc_status-2] <=DAT_dat_i[0];    
   end
   WRITE_BUSY : begin
       transm_complete <=1;
     if (crc_s == 3'b010) 
       crc_ok<=1;     
     else 
       crc_ok<=0;  
       busy_int<=DAT_dat_i[0];
   end
   READ_WAIT:begin
      DAT_oe_o<=0;
      crc_rst<=0;
      crc_en<=1;
      crc_in<=0; 
      crc_c<=15; 
      busy_n<=0;
      transm_complete<=0; 
   end
   READ_DAT: begin
     if (transf_cnt<1024) begin
       we<=1;
       data_out<=DAT_dat_i;
       crc_in<=DAT_dat_i;
       crc_ok<=1;
       transf_cnt<=transf_cnt+1; 
     end  
     else if  ( transf_cnt <= (1024 +16)) begin
       transf_cnt<=transf_cnt+1; 
       crc_en<=0;  
       last_din <=DAT_dat_i; 
       if (transf_cnt> 1024) begin       
        crc_c<=crc_c-1;
          we<=0;
          if  (crc_out[0][crc_c] != last_din[0])
           crc_ok<=0;
          if  (crc_out[1][crc_c] != last_din[1])
           crc_ok<=0;
          if  (crc_out[2][crc_c] != last_din[2])
           crc_ok<=0;
          if  (crc_out[3][crc_c] != last_din[3])
           crc_ok<=0;  
          crc_ok<=1;
         if (crc_c==0) begin
          transm_complete <=1;
          busy_n<=0;
           we<=0;
         end
      end
    end  
  end
 endcase 
 end
end 
endmodule
module sd_fifo_rx_filler
( 
input clk,
input rst,
output  [31:0]  m_wb_adr_o,
output  reg        m_wb_we_o,
output reg [31:0]  m_wb_dat_o,
output    reg      m_wb_cyc_o,
output   reg       m_wb_stb_o,
input           m_wb_ack_i,
output  reg	[2:0] m_wb_cti_o,
output	reg [1:0]	 m_wb_bte_o,
input en,
input [31:0] adr,
input sd_clk,
input [4-1:0] dat_i, 
input wr,
output full
);
 wire [31:0] dat_o;
reg rd;
reg reset_rx_fifo;
sd_rx_fifo Rx_Fifo (
.d ( dat_i ),
.wr  (  wr ),
.wclk  (sd_clk),
.q ( dat_o),
.rd (rd),
.full (full),
.empty (empty),
.mem_empt (),
.rclk (clk),
.rst  (rst | reset_rx_fifo)
);
reg [8:0] offset;
assign  m_wb_adr_o = adr+offset;
reg wb_free;
always @(posedge clk or posedge rst )begin
 if (rst) begin
  offset<=0;
  m_wb_we_o <=0;
	m_wb_cyc_o <= 0;
	m_wb_stb_o <= 0;
	wb_free<=1;
	m_wb_dat_o<=0;
	rd<=0;
	reset_rx_fifo<=1;
	m_wb_bte_o <= 2'b00;
		m_wb_cti_o <= 3'b000;
 end
 else if (en)  begin 
    rd<=0;
    reset_rx_fifo<=0;
  if (!empty & wb_free) begin
    rd<=1;
    m_wb_dat_o<=#1 dat_o;
    m_wb_we_o <=#1 1;
		m_wb_cyc_o <=#1 1;
		m_wb_stb_o <=#1 1; 
    wb_free<=0;   
  end
  if(  !wb_free & m_wb_ack_i) begin
    m_wb_we_o <=0;
		m_wb_cyc_o <= 0;
		m_wb_stb_o <= 0;
		offset<=offset+4;
		wb_free<=1;
	end	 
end
else begin
   reset_rx_fifo<=1;
    rd<=0;
   offset<=0;
    	m_wb_cyc_o <= 0;
			m_wb_stb_o <= 0; 
			m_wb_we_o <=0; 
			wb_free<=1;
  end
end  
endmodule
module sd_fifo_tx_filler
( 
input clk,
input rst,
output  [31:0]  m_wb_adr_o,
output  reg        m_wb_we_o,
input   [31:0]  m_wb_dat_i,
output    reg      m_wb_cyc_o,
output   reg       m_wb_stb_o,
input           m_wb_ack_i,
output  reg	[2:0] m_wb_cti_o,
output	reg [1:0]	 m_wb_bte_o,
input en,
input [31:0] adr,
input sd_clk,
output [31:0] dat_o, 
input rd,
output empty,
output fe
);
reg reset_tx_fifo;
reg [31:0] din;
reg wr_tx;
reg [8:0] we;
reg [8:0] offset;
wire [5:0]mem_empt;
sd_tx_fifo Tx_Fifo (
.d ( din ),
.wr  (  wr_tx ),
.wclk  (clk),
.q ( dat_o),
.rd (rd),
.full (fe),
.empty (empty),
.mem_empt (mem_empt),
.rclk (sd_clk),
.rst  (rst | reset_tx_fifo)
);
assign  m_wb_adr_o = adr+offset;
reg first;
reg ackd;
reg delay;
always @(posedge clk or posedge rst )begin
 if (rst) begin
	offset <=0;
	we <= 8'h1;
	m_wb_we_o <=0;
	m_wb_cyc_o <= 0;
	m_wb_stb_o <= 0;
	wr_tx<=0;
	ackd <=1;
	delay<=0;
	reset_tx_fifo<=1;
	first<=1;
	din<=0;
		m_wb_bte_o <= 2'b00;
		m_wb_cti_o <= 3'b000;
 end
 else if (en) begin  
    reset_tx_fifo<=0;
	  if (m_wb_ack_i) begin 		  
		  wr_tx <=1;
		  din <=m_wb_dat_i;	
		  m_wb_cyc_o <= 0;
		  m_wb_stb_o <= 0; 
		  delay<=~ delay;   
		end 
		else begin
			wr_tx <=0;
		end
	  if (delay)begin
	     offset<=offset+4;	
	     ackd<=~ackd;
	     delay<=~ delay;
	     wr_tx <=0; 
	  end
		if ( !m_wb_ack_i & !fe & ackd  ) begin  
		  m_wb_we_o <=0;
			m_wb_cyc_o <= 1;
			m_wb_stb_o <= 1; 
			ackd<=0;   
		end 
 end 
 else begin
   offset <=0;
   reset_tx_fifo<=1;
   m_wb_cyc_o <= 0;
   m_wb_stb_o <= 0; 
   m_wb_we_o <=0; 
 end 
end 
endmodule
 `timescale 1ns / 1ns
module sd_rx_fifo
  (
   input [4-1:0] d,
   input wr,
   input wclk,
   output [32-1:0] q,
   input rd,
   output full,
   output empty,
   output [1:0] mem_empt,
   input rclk,
   input rst
   );
   reg [32-1:0] ram [0:8-1];  
   reg [4-1:0] adr_i, adr_o;
   wire ram_we;
   wire [32-1:0] ram_din;
   reg [8-1:0] we;
   reg [4*(8)-1:0] tmp;
   reg ft;
   always @ (posedge wclk or posedge rst)
     if (rst)
       we <= 8'h1;
     else
       if (wr)
	 we <= {we[8-2:0],we[8-1]};
   always @ (posedge wclk or posedge rst)
     if (rst) begin
       tmp <= {4*(8-1){1'b0}};
         ft<=0; 
   end    
     else
       begin
	  if (wr & we[7]) begin
	    tmp[4*1-1:4*0] <= d;	 
	    ft<=1; end 
	  if (wr & we[6])
	    tmp[4*2-1:4*1] <= d; 
	  if (wr & we[5])
	    tmp[4*3-1:4*2] <= d;	  
	  if (wr & we[4])
	    tmp[4*4-1:4*3] <= d;	  
	  if (wr & we[3])
	    tmp[4*5-1:4*4] <= d;	  
	  if (wr & we[2])
	    tmp[4*6-1:4*5] <= d;	  
	  if (wr & we[1]) 
	    tmp[4*7-1:4*6] <= d;	 
 	  if (wr & we[0]) 
	    tmp[4*8-1:4*7] <= d;	 
  end
   assign ram_we = wr & we[0] &ft;
   assign ram_din = tmp;
   always @ (posedge wclk)
     if (ram_we)
       ram[adr_i[4-2:0]] <= ram_din;
   always @ (posedge wclk or posedge rst)
     if (rst)
       adr_i <= 4'h0;
     else
       if (ram_we)
	 if (adr_i == 8-1) begin
	   adr_i[4-2:0] <=0;	   
	   adr_i[4-1]<=~adr_i[4-1];
	 end  
	 else
	   adr_i <= adr_i + 4'h1;
   always @ (posedge rclk or posedge rst)
     if (rst)
       adr_o <= 4'h0;
     else
       if (!empty & rd)
	 if (adr_o == 8-1) begin
	    adr_o[4-2:0] <=0;
	    adr_o[4-1] <=~adr_o[4-1];
	 end  
	 else
	   adr_o <= adr_o + 4'h1;
   assign full =  (adr_i[4-2:0] == adr_o[4-2:0] ) & (adr_i[4-1] ^ adr_o[4-1]) ;
   assign empty = (adr_i == adr_o) ;
   assign mem_empt = ( adr_i-adr_o);
   assign q = ram[adr_o[4-2:0]];
endmodule
 `timescale 1ns / 1ns
module sd_tx_fifo
  (
   input [32-1:0] d,
   input wr,
   input wclk,
   output [32-1:0] q,
   input rd,
   output full,
   output empty,
   output [5:0] mem_empt,
   input rclk,
   input rst
   );
   reg [32-1:0] ram [0:8-1];  
   reg [4-1:0] adr_i, adr_o;
   wire ram_we;
   wire [32-1:0] ram_din;
   assign ram_we = wr & ~full;
   assign ram_din = d;
   always @ (posedge wclk)
     if (ram_we)
       ram[adr_i[4-2:0]] <= ram_din;
   always @ (posedge wclk or posedge rst)
     if (rst)
       adr_i <= 4'h0;
     else
       if (ram_we)
      	 if (adr_i == 8-1) begin
	        adr_i[4-2:0] <=0;	   
	        adr_i[4-1]<=~adr_i[4-1];
	    end  
	     else
	      adr_i <= adr_i + 4'h1;
   always @ (posedge rclk or posedge rst)
     if (rst)
       adr_o <= 4'h0;
     else
       if (!empty & rd) begin
	 if (adr_o == 8-1) begin
	    adr_o[4-2:0] <=0;
	    adr_o[4-1] <=~adr_o[4-1];
	 end  
	 else
	   adr_o <= adr_o + 4'h1;
	 end
   assign full=  ( adr_i[4-2:0] == adr_o[4-2:0] ) &  (adr_i[4-1] ^ adr_o[4-1]) ;
   assign empty = (adr_i == adr_o) ;
   assign mem_empt = ( adr_i-adr_o);
   assign q = ram[adr_o[4-2:0]];
endmodule
module sdc_controller(
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, 
  m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
  m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
  m_wb_stb_o, m_wb_ack_i, 
  m_wb_cti_o, m_wb_bte_o,
  sd_cmd_dat_i,sd_cmd_out_o,  sd_cmd_oe_o, card_detect,
  sd_dat_dat_i, sd_dat_out_o , sd_dat_oe_o, sd_clk_o_pad
   ,int_a, int_b, int_c  
);
input           wb_clk_i;      
input           wb_rst_i;      
input   [31:0]  wb_dat_i;      
output  [31:0]  wb_dat_o;      
input 			card_detect;
input   [7:0]  wb_adr_i;      
input   [3:0]  wb_sel_i;      
input          wb_we_i;       
input          wb_cyc_i;      
input          wb_stb_i;      
output          wb_ack_o;      
output  [31:0]  m_wb_adr_o;
output  [3:0]   m_wb_sel_o;
output          m_wb_we_o;
input   [31:0]  m_wb_dat_i;
output  [31:0]  m_wb_dat_o;
output          m_wb_cyc_o;
output          m_wb_stb_o;
input           m_wb_ack_i;
output  [2:0]   m_wb_cti_o;
output	[1:0]	m_wb_bte_o;
input  wire [3:0] sd_dat_dat_i;    
output wire [3:0] sd_dat_out_o;  
output wire sd_dat_oe_o;  
input  wire sd_cmd_dat_i;  
output wire sd_cmd_out_o;  
output wire sd_cmd_oe_o;  
output sd_clk_o_pad;
   output int_a, int_b, int_c ; 
wire int_busy;
wire [15:0] status_reg_w;
wire [31:0] cmd_resp_1_w;
wire [15:0]normal_int_status_reg_w;
wire [4:0]error_int_status_reg_w; 
wire[31:0]  argument_reg;
wire[15:0]  cmd_setting_reg;
reg[15:0]   status_reg;
reg[31:0]   cmd_resp_1;
wire[7:0]   software_reset_reg; 
wire[15:0]  time_out_reg;   
reg[15:0]   normal_int_status_reg; 
reg[15:0]   error_int_status_reg;
wire[15:0]  normal_int_signal_enable_reg;
wire[15:0]  error_int_signal_enable_reg;
wire[7:0]   clock_divider;
reg[15:0]   Bd_Status_reg;   
reg[7:0]    Bd_isr_reg;
wire[7:0]   Bd_isr_enable_reg;
wire [5-1 :0] free_bd_rx_bd;  
wire new_rx_bd;   
wire [16-1:0] dat_out_s_rx_bd;  
wire [16-1:0] dat_in_m_rx_bd;  
wire [16-1:0] dat_in_m_tx_bd;
wire [5-1 :0] free_bd_tx_bd;
wire new_tx_bd;
wire [16-1:0] dat_out_s_tx_bd;
wire [7:0] bd_int_st_w;  
wire re_s_tx_bd_w;
wire a_cmp_tx_bd_w;
wire re_s_rx_bd_w;
wire a_cmp_rx_bd_w;
wire write_req_s;  
wire cmd_busy;  
wire [31:0] cmd_arg_s;  
wire [15:0] cmd_set_s;  
wire [31:0] sys_adr;  
wire [1:0]start_dat_t;  
assign cmd_busy = int_busy | status_reg[0];
wire status_reg_busy;
wire [4 -1 : 0 ]data_in_rx_fifo;
wire [31: 0 ] data_fout_tx_fifo;
wire [31:0] m_wb_dat_o_rx;
wire [3:0] m_wb_sel_o_tx;
wire [31:0] m_wb_adr_o_tx;
wire [31:0] m_wb_adr_o_rx;
wire sd_clk_i;  
wire sd_clk_o;  
  assign sd_clk_i = wb_clk_i;
  sd_clock_divider clock_divider_1 (
 .CLK (sd_clk_i),
 .DIVIDER (clock_divider),
 .RST  (wb_rst_i | software_reset_reg[0]),
 .SD_CLK  (sd_clk_o)  
);
assign sd_clk_o_pad  = sd_clk_o ;
wire [15:0] settings;
wire [7:0] serial_status;
wire [39:0] cmd_out_master;
wire [39:0] cmd_in_host;
sd_cmd_master cmd_master_1
(
    .CLK_PAD_IO     (wb_clk_i),
    .RST_PAD_I      (wb_rst_i | software_reset_reg[0]),
    .New_CMD        (new_cmd),
    .data_write     (d_write),
    .data_read      (d_read),
    .ARG_REG        (argument_reg),
    .CMD_SET_REG    (cmd_setting_reg[13:0]),
    .STATUS_REG     (status_reg_w),
    .TIMEOUT_REG    (time_out_reg),
    .RESP_1_REG     (cmd_resp_1_w),
    .ERR_INT_REG    (error_int_status_reg_w),
    .NORMAL_INT_REG (normal_int_status_reg_w),
    .ERR_INT_RST    (error_isr_reset),
    .NORMAL_INT_RST (normal_isr_reset),
    .settings       (settings),
    .go_idle_o      (go_idle),
    .cmd_out        (cmd_out_master ),
    .req_out        (req_out_master ),
    .ack_out        (ack_out_master ),
    .req_in         (req_in_host),
    .ack_in         (ack_in_host),
    .cmd_in         (cmd_in_host),
    .serial_status (serial_status),
    .card_detect (card_detect)
);
sd_cmd_serial_host cmd_serial_host_1(
    .SD_CLK_IN  (sd_clk_o), 
    .RST_IN     (wb_rst_i | software_reset_reg[0] | go_idle),
    .SETTING_IN (settings),
    .CMD_IN     (cmd_out_master),
    .REQ_IN     (req_out_master),
    .ACK_IN     (ack_out_master),
    .REQ_OUT    (req_in_host), 
    .ACK_OUT    (ack_in_host),
    .CMD_OUT    (cmd_in_host),
    .STATUS     (serial_status),
    .cmd_dat_i  (sd_cmd_dat_i),
    .cmd_out_o  (sd_cmd_out_o),
    .cmd_oe_o   ( sd_cmd_oe_o),
    .st_dat_t   (start_dat_t)
);
sd_data_master data_master_1 
(
    .clk            (wb_clk_i),
    .rst            (wb_rst_i | software_reset_reg[0]),
    .dat_in_tx      (dat_out_s_tx_bd),
    .free_tx_bd     (free_bd_tx_bd),
    .ack_i_s_tx     (ack_o_s_tx ),
    .re_s_tx        (re_s_tx_bd_w), 
    .a_cmp_tx       (a_cmp_tx_bd_w),
    .dat_in_rx      (dat_out_s_rx_bd),
    .free_rx_bd     (free_bd_rx_bd),
    .ack_i_s_rx     (ack_o_s_rx),
    .re_s_rx        (re_s_rx_bd_w), 
    .a_cmp_rx       (a_cmp_rx_bd_w),
    .cmd_busy       (cmd_busy),
    .we_req         (write_req_s),
    .we_ack         (we_ack),
    .d_write        (d_write),
    .d_read         (d_read),
    .cmd_arg        (cmd_arg_s),
    .cmd_set        (cmd_set_s),
    .cmd_tsf_err    (normal_int_status_reg[15]) ,
    .card_status    (cmd_resp_1[12:8])   ,
    .start_tx_fifo  (start_tx_fifo),
    .start_rx_fifo  (start_rx_fifo),
    .sys_adr        (sys_adr),
    .tx_empt        (tx_e ),
    .tx_full        (tx_f ),
    .rx_full        (full_rx ),
    .busy_n         (busy_n),
    .transm_complete(trans_complete ),
    .crc_ok         (crc_ok),
    .ack_transfer   (ack_transfer),
    .Dat_Int_Status (bd_int_st_w),
    .Dat_Int_Status_rst (Bd_isr_reset),
    .CIDAT           (cidat_w),
	.transfer_type  (cmd_setting_reg[15:14])
);
wire [31:0] data_out_tx_fifo;
sd_data_serial_host sd_data_serial_host_1(
    .sd_clk         (sd_clk_o),
    .rst            (wb_rst_i | software_reset_reg[0]),
    .data_in        (data_out_tx_fifo),
    .rd             (rd), 
    .data_out       (data_in_rx_fifo),
    .we             (we_rx),
    .DAT_oe_o       (sd_dat_oe_o),
    .DAT_dat_o      (sd_dat_out_o),
    .DAT_dat_i      (sd_dat_dat_i),
    .start_dat      (start_dat_t),
    .ack_transfer   (ack_transfer),
    .busy_n         (busy_n),
    .transm_complete(trans_complete ),
    .crc_ok         (crc_ok)
);
sd_bd rx_bd
(
    .clk        (wb_clk_i),
    .rst       (wb_rst_i | software_reset_reg[0]),
    .we_m      (we_m_rx_bd),
    .dat_in_m  (dat_in_m_rx_bd),
    .free_bd   (free_bd_rx_bd),
    .re_s      (re_s_rx_bd_w),
    .ack_o_s   (ack_o_s_rx),
    .a_cmp     (a_cmp_rx_bd_w),
    .dat_out_s (dat_out_s_rx_bd)
);
sd_bd tx_bd
(
    .clk       (wb_clk_i),
    .rst       (wb_rst_i | software_reset_reg[0]),
    .we_m      (we_m_tx_bd),
    .dat_in_m  (dat_in_m_tx_bd),
    .free_bd   (free_bd_tx_bd),
    .ack_o_s   (ack_o_s_tx),
    .re_s      (re_s_tx_bd_w),
    .a_cmp     (a_cmp_tx_bd_w),
    .dat_out_s (dat_out_s_tx_bd)
);
sd_fifo_tx_filler fifo_filer_tx (
    .clk        (wb_clk_i),
    .rst        (wb_rst_i | software_reset_reg[0]),
    .m_wb_adr_o (m_wb_adr_o_tx),
    .m_wb_we_o  (m_wb_we_o_tx),
    .m_wb_dat_i (m_wb_dat_i),
    .m_wb_cyc_o (m_wb_cyc_o_tx),
    .m_wb_stb_o (m_wb_stb_o_tx),
    .m_wb_ack_i (m_wb_ack_i),
    .m_wb_cti_o (m_wb_cti_o_tx),
	.m_wb_bte_o (m_wb_bte_o_tx),
    .en         (start_tx_fifo),
    .adr        (sys_adr),
    .sd_clk     (sd_clk_o),
    .dat_o      (data_out_tx_fifo   ),
    .rd         (rd),
    .empty      (tx_e),
    .fe         (tx_f)
);
sd_fifo_rx_filler fifo_filer_rx (
    .clk        (wb_clk_i),
    .rst        (wb_rst_i | software_reset_reg[0]),
    .m_wb_adr_o (m_wb_adr_o_rx),
    .m_wb_we_o  (m_wb_we_o_rx),
    .m_wb_dat_o (m_wb_dat_o),
    .m_wb_cyc_o (m_wb_cyc_o_rx),
    .m_wb_stb_o (m_wb_stb_o_rx),
    .m_wb_ack_i (m_wb_ack_i),
    .m_wb_cti_o (m_wb_cti_o_rx),
	.m_wb_bte_o (m_wb_bte_o_rx),
    .en         (start_rx_fifo),
    .adr        (sys_adr),
    .sd_clk     (sd_clk_o),
    .dat_i      (data_in_rx_fifo   ),
    .wr         (we_rx),
    .full       (full_rx)
);
sd_controller_wb sd_controller_wb0
	(
	 .wb_clk_i          (wb_clk_i),
	 .wb_rst_i          (wb_rst_i),
	 .wb_dat_i          (wb_dat_i),
	 .wb_dat_o          (wb_dat_o),
	 .wb_adr_i          (wb_adr_i[7:0]),
	 .wb_sel_i          (wb_sel_i),
	 .wb_we_i           (wb_we_i),
	 .wb_stb_i          (wb_stb_i),
	 .wb_cyc_i          (wb_cyc_i),
	 .wb_ack_o          (wb_ack_o),
   	 .we_m_tx_bd        (we_m_tx_bd),
     .new_cmd           (new_cmd), 
     .we_m_rx_bd        (we_m_rx_bd),   
    .we_ack             (we_ack),
    .int_ack            (int_ack),
    .cmd_int_busy       (cmd_int_busy),
    .Bd_isr_reset       (Bd_isr_reset),     
    .normal_isr_reset   (normal_isr_reset),
    .error_isr_reset    (error_isr_reset),
    .int_busy           (int_busy),
    .dat_in_m_tx_bd     (dat_in_m_tx_bd),
    .dat_in_m_rx_bd     (dat_in_m_rx_bd),
    .write_req_s        (write_req_s),
    .cmd_set_s          (cmd_set_s),
    .cmd_arg_s          (cmd_arg_s),
    .argument_reg       (argument_reg),
    .cmd_setting_reg    (cmd_setting_reg),
    .status_reg         (status_reg),
    .cmd_resp_1         (cmd_resp_1),
    .software_reset_reg (software_reset_reg ),
    .time_out_reg       (time_out_reg ),
    .normal_int_status_reg  (normal_int_status_reg),
    .error_int_status_reg   (error_int_status_reg ),
    .normal_int_signal_enable_reg   (normal_int_signal_enable_reg),
    .error_int_signal_enable_reg    (error_int_signal_enable_reg),
    .clock_divider                  (clock_divider ),
    .Bd_Status_reg                  (Bd_Status_reg),
    .Bd_isr_reg                     (Bd_isr_reg ),
    .Bd_isr_enable_reg              (Bd_isr_enable_reg)
	 );
assign m_wb_cyc_o = start_tx_fifo ? m_wb_cyc_o_tx :start_rx_fifo ?m_wb_cyc_o_rx: 0;
assign m_wb_stb_o = start_tx_fifo ? m_wb_stb_o_tx :start_rx_fifo ?m_wb_stb_o_rx: 0;
assign m_wb_cti_o = start_tx_fifo ? m_wb_cti_o_tx :start_rx_fifo ?m_wb_cti_o_rx: 0;
assign m_wb_bte = start_tx_fifo ? m_wb_bte_o_tx :start_rx_fifo ?m_wb_bte_o_rx: 0;
assign m_wb_we_o = start_tx_fifo ? m_wb_we_o_tx :start_rx_fifo ?m_wb_we_o_rx: 0;
assign m_wb_adr_o = start_tx_fifo ? m_wb_adr_o_tx :start_rx_fifo ?m_wb_adr_o_rx: 0;
assign int_a =  |(normal_int_status_reg &  normal_int_signal_enable_reg) ;
assign int_b =  |(error_int_status_reg & error_int_signal_enable_reg);
assign int_c =  |(Bd_isr_reg & Bd_isr_enable_reg);
assign m_wb_sel_o = 4'b1111;
always @ (posedge wb_clk_i ) begin
  Bd_Status_reg[15:8]=free_bd_rx_bd;
  Bd_Status_reg[7:0]=free_bd_tx_bd;
  cmd_resp_1<= cmd_resp_1_w;
  normal_int_status_reg<= normal_int_status_reg_w  ;
  error_int_status_reg<= error_int_status_reg_w  ;
  status_reg[0]<= status_reg_busy;
  status_reg[15:1]<=  status_reg_w[15:1]; 
  status_reg[1] <= cidat_w; 
  Bd_isr_reg<=bd_int_st_w;
end
assign status_reg_busy = cmd_int_busy ? 1'b1: status_reg_w[0];
endmodule
