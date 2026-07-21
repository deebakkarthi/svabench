 `timescale 1ns / 1ns
module ethmac
(
  wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o, 
  wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o, wb_err_o, 
  m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
  m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
  m_wb_stb_o, m_wb_ack_i, m_wb_err_i, 
  m_wb_cti_o, m_wb_bte_o, 
  mtx_clk_pad_i, mtxd_pad_o, mtxen_pad_o, mtxerr_pad_o,
  mrx_clk_pad_i, mrxd_pad_i, mrxdv_pad_i, mrxerr_pad_i, mcoll_pad_i, mcrs_pad_i,
  mdc_pad_o, md_pad_i, md_pad_o, md_padoe_o,
  int_o
);
parameter TX_FIFO_DATA_WIDTH = 32;
parameter TX_FIFO_DEPTH      = 16;
parameter TX_FIFO_CNT_WIDTH  = 5;
parameter RX_FIFO_DATA_WIDTH = 32;
parameter RX_FIFO_DEPTH      = 16;
parameter RX_FIFO_CNT_WIDTH  = 5;
input           wb_clk_i;      
input           wb_rst_i;      
input   [31:0]  wb_dat_i;      
output  [31:0]  wb_dat_o;      
output          wb_err_o;      
input   [11:2]  wb_adr_i;      
input    [3:0]  wb_sel_i;      
input           wb_we_i;       
input           wb_cyc_i;      
input           wb_stb_i;      
output          wb_ack_o;      
output  [31:0]  m_wb_adr_o;
output   [3:0]  m_wb_sel_o;
output          m_wb_we_o;
input   [31:0]  m_wb_dat_i;
output  [31:0]  m_wb_dat_o;
output          m_wb_cyc_o;
output          m_wb_stb_o;
input           m_wb_ack_i;
input           m_wb_err_i;
wire    [29:0]  m_wb_adr_tmp;
output   [2:0]  m_wb_cti_o;    
output   [1:0]  m_wb_bte_o;    
input           mtx_clk_pad_i;  
output   [3:0]  mtxd_pad_o;     
output          mtxen_pad_o;    
output          mtxerr_pad_o;   
input           mrx_clk_pad_i;  
input    [3:0]  mrxd_pad_i;     
input           mrxdv_pad_i;    
input           mrxerr_pad_i;   
input           mcoll_pad_i;    
input           mcrs_pad_i;     
input           md_pad_i;       
output          mdc_pad_o;      
output          md_pad_o;       
output          md_padoe_o;     
output          int_o;          
wire    [31:0]  wb_dbg_dat0;
wire     [7:0]  r_ClkDiv;
wire            r_MiiNoPre;
wire    [15:0]  r_CtrlData;
wire     [4:0]  r_FIAD;
wire     [4:0]  r_RGAD;
wire            r_WCtrlData;
wire            r_RStat;
wire            r_ScanStat;
wire            NValid_stat;
wire            Busy_stat;
wire            LinkFail;
wire    [15:0]  Prsd;              
wire            WCtrlDataStart;
wire            RStatStart;
wire            UpdateMIIRX_DATAReg;
wire            TxStartFrm;
wire            TxEndFrm;
wire            TxUsedData;
wire     [7:0]  TxData;
wire            TxRetry;
wire            TxAbort;
wire            TxUnderRun;
wire            TxDone;
reg             WillSendControlFrame_sync1;
reg             WillSendControlFrame_sync2;
reg             WillSendControlFrame_sync3;
reg             RstTxPauseRq;
reg             TxPauseRq_sync1;
reg             TxPauseRq_sync2;
reg             TxPauseRq_sync3;
reg             TPauseRq;
eth_miim miim1
(
  .Clk(wb_clk_i),
  .Reset(wb_rst_i),
  .Divider(r_ClkDiv),
  .NoPre(r_MiiNoPre),
  .CtrlData(r_CtrlData),
  .Rgad(r_RGAD),
  .Fiad(r_FIAD),
  .WCtrlData(r_WCtrlData),
  .RStat(r_RStat),
  .ScanStat(r_ScanStat),
  .Mdi(md_pad_i),
  .Mdo(md_pad_o),
  .MdoEn(md_padoe_o),
  .Mdc(mdc_pad_o),
  .Busy(Busy_stat),
  .Prsd(Prsd),
  .LinkFail(LinkFail),
  .Nvalid(NValid_stat),
  .WCtrlDataStart(WCtrlDataStart),
  .RStatStart(RStatStart),
  .UpdateMIIRX_DATAReg(UpdateMIIRX_DATAReg)
);
wire  [3:0] RegCs;           
wire [31:0] RegDataOut;      
wire        r_RecSmall;      
wire        r_LoopBck;       
wire        r_TxEn;          
wire        r_RxEn;          
wire        MRxDV_Lb;        
wire        MRxErr_Lb;       
wire  [3:0] MRxD_Lb;         
wire        Transmitting;    
wire        r_HugEn;         
wire        r_DlyCrcEn;      
wire [15:0] r_MaxFL;         
wire [15:0] r_MinFL;         
wire        ShortFrame;
wire        DribbleNibble;   
wire        ReceivedPacketTooBig;  
wire [47:0] r_MAC;           
wire        LoadRxStatus;    
wire [31:0] r_HASH0;         
wire [31:0] r_HASH1;         
wire  [7:0] r_TxBDNum;       
wire  [6:0] r_IPGT;          
wire  [6:0] r_IPGR1;         
wire  [6:0] r_IPGR2;         
wire  [5:0] r_CollValid;     
wire [15:0] r_TxPauseTV;     
wire        r_TxPauseRq;     
wire  [3:0] r_MaxRet;        
wire        r_NoBckof;       
wire        r_ExDfrEn;       
wire        r_TxFlow;        
wire        r_IFG;           
wire        TxB_IRQ;         
wire        TxE_IRQ;         
wire        RxB_IRQ;         
wire        RxE_IRQ;         
wire        Busy_IRQ;        
wire        ByteSelected;
wire        BDAck;
wire [31:0] BD_WB_DAT_O;     
wire  [3:0] BDCs;            
wire        CsMiss;          
wire        r_Pad;
wire        r_CrcEn;
wire        r_FullD;
wire        r_Pro;
wire        r_Bro;
wire        r_NoPre;
wire        r_RxFlow;
wire        r_PassAll;
wire        TxCtrlEndFrm;
wire        StartTxDone;
wire        SetPauseTimer;
wire        TxUsedDataIn;
wire        TxDoneIn;
wire        TxAbortIn;
wire        PerPacketPad;
wire        PadOut;
wire        PerPacketCrcEn;
wire        CrcEnOut;
wire        TxStartFrmOut;
wire        TxEndFrmOut;
wire        ReceivedPauseFrm;
wire        ControlFrmAddressOK;
wire        RxStatusWriteLatched_sync2;
wire        LateCollision;
wire        DeferIndication;
wire        LateCollLatched;
wire        DeferLatched;
wire        RstDeferLatched;
wire        CarrierSenseLost;
wire        temp_wb_ack_o;
wire [31:0] temp_wb_dat_o;
wire        temp_wb_err_o;
  reg         temp_wb_ack_o_reg;
  reg [31:0]  temp_wb_dat_o_reg;
  reg         temp_wb_err_o_reg;
assign ByteSelected = |wb_sel_i;
assign RegCs[3] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[3];    
assign RegCs[2] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[2];    
assign RegCs[1] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[1];    
assign RegCs[0] = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] & ~wb_adr_i[10] & wb_sel_i[0];    
assign BDCs[3]  = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] &  wb_adr_i[10] & wb_sel_i[3];    
assign BDCs[2]  = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] &  wb_adr_i[10] & wb_sel_i[2];    
assign BDCs[1]  = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] &  wb_adr_i[10] & wb_sel_i[1];    
assign BDCs[0]  = wb_stb_i & wb_cyc_i & ByteSelected & ~wb_adr_i[11] &  wb_adr_i[10] & wb_sel_i[0];    
assign CsMiss = wb_stb_i & wb_cyc_i & ByteSelected & wb_adr_i[11];                    
assign temp_wb_dat_o = ((|RegCs) & ~wb_we_i)? RegDataOut : BD_WB_DAT_O;
assign temp_wb_err_o = wb_stb_i & wb_cyc_i & (~ByteSelected | CsMiss);
  assign wb_ack_o = temp_wb_ack_o_reg;
  assign wb_dat_o[31:0] = temp_wb_dat_o_reg;
  assign wb_err_o = temp_wb_err_o_reg;
  assign temp_wb_ack_o = (|RegCs) | BDAck;
  always @ (posedge wb_clk_i or posedge wb_rst_i)
  begin
    if(wb_rst_i)
      begin
        temp_wb_ack_o_reg <= 1'b0;
        temp_wb_dat_o_reg <= 32'h0;
        temp_wb_err_o_reg <= 1'b0;
      end
    else
      begin
        temp_wb_ack_o_reg <= temp_wb_ack_o & ~temp_wb_ack_o_reg;
        temp_wb_dat_o_reg <= temp_wb_dat_o;
        temp_wb_err_o_reg <= temp_wb_err_o & ~temp_wb_err_o_reg;
      end
  end
eth_registers ethreg1
(
  .DataIn(wb_dat_i),
  .Address(wb_adr_i[9:2]),
  .Rw(wb_we_i),
  .Cs(RegCs),
  .Clk(wb_clk_i),
  .Reset(wb_rst_i),
  .DataOut(RegDataOut),
  .r_RecSmall(r_RecSmall),
  .r_Pad(r_Pad),
  .r_HugEn(r_HugEn),
  .r_CrcEn(r_CrcEn),
  .r_DlyCrcEn(r_DlyCrcEn),
  .r_FullD(r_FullD),
  .r_ExDfrEn(r_ExDfrEn),
  .r_NoBckof(r_NoBckof),
  .r_LoopBck(r_LoopBck),
  .r_IFG(r_IFG),
  .r_Pro(r_Pro),
  .r_Iam(),
  .r_Bro(r_Bro),
  .r_NoPre(r_NoPre),
  .r_TxEn(r_TxEn),
  .r_RxEn(r_RxEn),
  .Busy_IRQ(Busy_IRQ),
  .RxE_IRQ(RxE_IRQ),
  .RxB_IRQ(RxB_IRQ),
  .TxE_IRQ(TxE_IRQ),
  .TxB_IRQ(TxB_IRQ),
  .r_IPGT(r_IPGT),
  .r_IPGR1(r_IPGR1),
  .r_IPGR2(r_IPGR2),
  .r_MinFL(r_MinFL),
  .r_MaxFL(r_MaxFL),
  .r_MaxRet(r_MaxRet),
  .r_CollValid(r_CollValid),
  .r_TxFlow(r_TxFlow),
  .r_RxFlow(r_RxFlow),
  .r_PassAll(r_PassAll),
  .r_MiiNoPre(r_MiiNoPre),
  .r_ClkDiv(r_ClkDiv),
  .r_WCtrlData(r_WCtrlData),
  .r_RStat(r_RStat),
  .r_ScanStat(r_ScanStat),
  .r_RGAD(r_RGAD),
  .r_FIAD(r_FIAD),
  .r_CtrlData(r_CtrlData),
  .NValid_stat(NValid_stat),
  .Busy_stat(Busy_stat),
  .LinkFail(LinkFail),
  .r_MAC(r_MAC),
  .WCtrlDataStart(WCtrlDataStart),
  .RStatStart(RStatStart),
  .UpdateMIIRX_DATAReg(UpdateMIIRX_DATAReg),
  .Prsd(Prsd),
  .r_TxBDNum(r_TxBDNum),
  .int_o(int_o),
  .r_HASH0(r_HASH0),
  .r_HASH1(r_HASH1),
  .r_TxPauseRq(r_TxPauseRq),
  .r_TxPauseTV(r_TxPauseTV),
  .RstTxPauseRq(RstTxPauseRq),
  .TxCtrlEndFrm(TxCtrlEndFrm),
  .StartTxDone(StartTxDone),
  .TxClk(mtx_clk_pad_i),
  .RxClk(mrx_clk_pad_i),
  .dbg_dat(wb_dbg_dat0),
  .SetPauseTimer(SetPauseTimer)
);
wire  [7:0] RxData;
wire        RxValid;
wire        RxStartFrm;
wire        RxEndFrm;
wire        RxAbort;
wire        WillTransmit;             
wire        ResetCollision;           
wire  [7:0] TxDataOut;                
wire        WillSendControlFrame;
wire        ReceiveEnd;
wire        ReceivedPacketGood;
wire        ReceivedLengthOK;
wire        InvalidSymbol;
wire        LatchedCrcError;
wire        RxLateCollision;
wire  [3:0] RetryCntLatched;   
wire  [3:0] RetryCnt;   
wire        StartTxAbort;   
wire        MaxCollisionOccured;   
wire        RetryLimit;   
wire        StatePreamble;   
wire  [1:0] StateData; 
eth_maccontrol maccontrol1
(
  .MTxClk(mtx_clk_pad_i),
  .TPauseRq(TPauseRq),
  .TxPauseTV(r_TxPauseTV),
  .TxDataIn(TxData),
  .TxStartFrmIn(TxStartFrm),
  .TxEndFrmIn(TxEndFrm),
  .TxUsedDataIn(TxUsedDataIn),
  .TxDoneIn(TxDoneIn),
  .TxAbortIn(TxAbortIn),
  .MRxClk(mrx_clk_pad_i),
  .RxData(RxData),
  .RxValid(RxValid),
  .RxStartFrm(RxStartFrm),
  .RxEndFrm(RxEndFrm),
  .ReceiveEnd(ReceiveEnd),
  .ReceivedPacketGood(ReceivedPacketGood),
  .TxFlow(r_TxFlow),
  .RxFlow(r_RxFlow),
  .DlyCrcEn(r_DlyCrcEn),
  .MAC(r_MAC),
  .PadIn(r_Pad | PerPacketPad),
  .PadOut(PadOut),
  .CrcEnIn(r_CrcEn | PerPacketCrcEn),
  .CrcEnOut(CrcEnOut),
  .TxReset(wb_rst_i),
  .RxReset(wb_rst_i),
  .ReceivedLengthOK(ReceivedLengthOK),
  .TxDataOut(TxDataOut),
  .TxStartFrmOut(TxStartFrmOut),
  .TxEndFrmOut(TxEndFrmOut),
  .TxUsedDataOut(TxUsedData),
  .TxDoneOut(TxDone),
  .TxAbortOut(TxAbort),
  .WillSendControlFrame(WillSendControlFrame),
  .TxCtrlEndFrm(TxCtrlEndFrm),
  .ReceivedPauseFrm(ReceivedPauseFrm),
  .ControlFrmAddressOK(ControlFrmAddressOK),
  .SetPauseTimer(SetPauseTimer),
  .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2),
  .r_PassAll(r_PassAll)
);
wire TxCarrierSense;           
wire Collision;                
reg CarrierSense_Tx1;
reg CarrierSense_Tx2;
reg Collision_Tx1;
reg Collision_Tx2;
reg RxEnSync;                  
reg WillTransmit_q;
reg WillTransmit_q2;
assign MRxDV_Lb = r_LoopBck? mtxen_pad_o : mrxdv_pad_i & RxEnSync;
assign MRxErr_Lb = r_LoopBck? mtxerr_pad_o : mrxerr_pad_i & RxEnSync;
assign MRxD_Lb[3:0] = r_LoopBck? mtxd_pad_o[3:0] : mrxd_pad_i[3:0];
eth_txethmac txethmac1
(
  .MTxClk(mtx_clk_pad_i),
  .Reset(wb_rst_i),
  .CarrierSense(TxCarrierSense),
  .Collision(Collision),
  .TxData(TxDataOut),
  .TxStartFrm(TxStartFrmOut),
  .TxUnderRun(TxUnderRun),
  .TxEndFrm(TxEndFrmOut),
  .Pad(PadOut),
  .MinFL(r_MinFL),
  .CrcEn(CrcEnOut),
  .FullD(r_FullD),
  .HugEn(r_HugEn),
  .DlyCrcEn(r_DlyCrcEn),
  .IPGT(r_IPGT),
  .IPGR1(r_IPGR1),
  .IPGR2(r_IPGR2),
  .CollValid(r_CollValid),
  .MaxRet(r_MaxRet),
  .NoBckof(r_NoBckof),
  .ExDfrEn(r_ExDfrEn),
  .MaxFL(r_MaxFL),
  .MTxEn(mtxen_pad_o),
  .MTxD(mtxd_pad_o),
  .MTxErr(mtxerr_pad_o),
  .TxUsedData(TxUsedDataIn),
  .TxDone(TxDoneIn),
  .TxRetry(TxRetry),
  .TxAbort(TxAbortIn),
  .WillTransmit(WillTransmit),
  .ResetCollision(ResetCollision),
  .RetryCnt(RetryCnt),
  .StartTxDone(StartTxDone),
  .StartTxAbort(StartTxAbort),
  .MaxCollisionOccured(MaxCollisionOccured),
  .LateCollision(LateCollision),
  .DeferIndication(DeferIndication),
  .StatePreamble(StatePreamble),
  .StateData(StateData)   
);
wire  [15:0]  RxByteCnt;
wire          RxByteCntEq0;
wire          RxByteCntGreat2;
wire          RxByteCntMaxFrame;
wire          RxCrcError;
wire          RxStateIdle;
wire          RxStatePreamble;
wire          RxStateSFD;
wire   [1:0]  RxStateData;
wire          AddressMiss;
eth_rxethmac rxethmac1
(
  .MRxClk(mrx_clk_pad_i),
  .MRxDV(MRxDV_Lb),
  .MRxD(MRxD_Lb),
  .Transmitting(Transmitting),
  .HugEn(r_HugEn),
  .DlyCrcEn(r_DlyCrcEn),
  .MaxFL(r_MaxFL),
  .r_IFG(r_IFG),
  .Reset(wb_rst_i),
  .RxData(RxData),
  .RxValid(RxValid),
  .RxStartFrm(RxStartFrm),
  .RxEndFrm(RxEndFrm),
  .ByteCnt(RxByteCnt),
  .ByteCntEq0(RxByteCntEq0),
  .ByteCntGreat2(RxByteCntGreat2),
  .ByteCntMaxFrame(RxByteCntMaxFrame),
  .CrcError(RxCrcError),
  .StateIdle(RxStateIdle),
  .StatePreamble(RxStatePreamble),
  .StateSFD(RxStateSFD),
  .StateData(RxStateData),
  .MAC(r_MAC),
  .r_Pro(r_Pro),
  .r_Bro(r_Bro),
  .r_HASH0(r_HASH0),
  .r_HASH1(r_HASH1),
  .RxAbort(RxAbort),
  .AddressMiss(AddressMiss),
  .PassAll(r_PassAll),
  .ControlFrmAddressOK(ControlFrmAddressOK)
);
always @ (posedge mtx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      CarrierSense_Tx1 <=  1'b0;
      CarrierSense_Tx2 <=  1'b0;
    end
  else
    begin
      CarrierSense_Tx1 <=  mcrs_pad_i;
      CarrierSense_Tx2 <=  CarrierSense_Tx1;
    end
end
assign TxCarrierSense = ~r_FullD & CarrierSense_Tx2;
always @ (posedge mtx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      Collision_Tx1 <=  1'b0;
      Collision_Tx2 <=  1'b0;
    end
  else
    begin
      Collision_Tx1 <=  mcoll_pad_i;
      if(ResetCollision)
        Collision_Tx2 <=  1'b0;
      else
      if(Collision_Tx1)
        Collision_Tx2 <=  1'b1;
    end
end
assign Collision = ~r_FullD & Collision_Tx2;
always @ (posedge mrx_clk_pad_i)
begin
  WillTransmit_q <=  WillTransmit;
  WillTransmit_q2 <=  WillTransmit_q;
end 
assign Transmitting = ~r_FullD & WillTransmit_q2;
always @ (posedge mrx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    RxEnSync <=  1'b0;
  else
  if(~mrxdv_pad_i)
    RxEnSync <=  r_RxEn;
end 
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    WillSendControlFrame_sync1 <= 1'b0;
  else
    WillSendControlFrame_sync1 <= WillSendControlFrame;
end
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    WillSendControlFrame_sync2 <= 1'b0;
  else
    WillSendControlFrame_sync2 <= WillSendControlFrame_sync1;
end
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    WillSendControlFrame_sync3 <= 1'b0;
  else
    WillSendControlFrame_sync3 <= WillSendControlFrame_sync2;
end
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    RstTxPauseRq <= 1'b0;
  else
    RstTxPauseRq <= WillSendControlFrame_sync2 & ~WillSendControlFrame_sync3;
end
always @ (posedge mtx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      TxPauseRq_sync1 <=  1'b0;
      TxPauseRq_sync2 <=  1'b0;
      TxPauseRq_sync3 <=  1'b0;
    end
  else
    begin
      TxPauseRq_sync1 <=  (r_TxPauseRq & r_TxFlow);
      TxPauseRq_sync2 <=  TxPauseRq_sync1;
      TxPauseRq_sync3 <=  TxPauseRq_sync2;
    end
end
always @ (posedge mtx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    TPauseRq <=  1'b0;
  else
    TPauseRq <=  TxPauseRq_sync2 & (~TxPauseRq_sync3);
end
wire LatchedMRxErr;
reg RxAbort_latch;
reg RxAbort_sync1;
reg RxAbort_wb;
reg RxAbortRst_sync1;
reg RxAbortRst;
always @ (posedge mrx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    RxAbort_latch <=  1'b0;
  else if(RxAbort | (ShortFrame & ~r_RecSmall) | LatchedMRxErr &
          ~InvalidSymbol | (ReceivedPauseFrm & (~r_PassAll)))
    RxAbort_latch <=  1'b1;
  else if(RxAbortRst)
    RxAbort_latch <=  1'b0;
end
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      RxAbort_sync1 <=  1'b0;
      RxAbort_wb    <=  1'b0;
      RxAbort_wb    <=  1'b0;
    end
  else
    begin
      RxAbort_sync1 <=  RxAbort_latch;
      RxAbort_wb    <=  RxAbort_sync1;
    end
end
always @ (posedge mrx_clk_pad_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      RxAbortRst_sync1 <=  1'b0;
      RxAbortRst       <=  1'b0;
    end
  else
    begin
      RxAbortRst_sync1 <=  RxAbort_wb;
      RxAbortRst       <=  RxAbortRst_sync1;
    end
end
eth_wishbone #(.TX_FIFO_DATA_WIDTH(TX_FIFO_DATA_WIDTH),
	       .TX_FIFO_DEPTH     (TX_FIFO_DEPTH),
	       .TX_FIFO_CNT_WIDTH (TX_FIFO_CNT_WIDTH),
	       .RX_FIFO_DATA_WIDTH(RX_FIFO_DATA_WIDTH),
	       .RX_FIFO_DEPTH     (RX_FIFO_DEPTH),
	       .RX_FIFO_CNT_WIDTH (RX_FIFO_CNT_WIDTH))
wishbone
(
  .WB_CLK_I(wb_clk_i),
  .WB_DAT_I(wb_dat_i),
  .WB_DAT_O(BD_WB_DAT_O),
  .WB_ADR_I(wb_adr_i[9:2]),
  .WB_WE_I(wb_we_i),
  .BDCs(BDCs),
  .WB_ACK_O(BDAck),
  .Reset(wb_rst_i),
  .m_wb_adr_o(m_wb_adr_tmp),
  .m_wb_sel_o(m_wb_sel_o),
  .m_wb_we_o(m_wb_we_o),
  .m_wb_dat_i(m_wb_dat_i),
  .m_wb_dat_o(m_wb_dat_o),
  .m_wb_cyc_o(m_wb_cyc_o),
  .m_wb_stb_o(m_wb_stb_o),
  .m_wb_ack_i(m_wb_ack_i),
  .m_wb_err_i(m_wb_err_i),
  .m_wb_cti_o(m_wb_cti_o),
  .m_wb_bte_o(m_wb_bte_o), 
  .MTxClk(mtx_clk_pad_i),
  .TxStartFrm(TxStartFrm),
  .TxEndFrm(TxEndFrm),
  .TxUsedData(TxUsedData),
  .TxData(TxData),
  .TxRetry(TxRetry),
  .TxAbort(TxAbort),
  .TxUnderRun(TxUnderRun),
  .TxDone(TxDone),
  .PerPacketCrcEn(PerPacketCrcEn),
  .PerPacketPad(PerPacketPad),
  .r_TxEn(r_TxEn),
  .r_RxEn(r_RxEn),
  .r_TxBDNum(r_TxBDNum),
  .r_RxFlow(r_RxFlow),
  .r_PassAll(r_PassAll), 
  .MRxClk(mrx_clk_pad_i),
  .RxData(RxData),
  .RxValid(RxValid),
  .RxStartFrm(RxStartFrm),
  .RxEndFrm(RxEndFrm),
  .Busy_IRQ(Busy_IRQ),
  .RxE_IRQ(RxE_IRQ),
  .RxB_IRQ(RxB_IRQ),
  .TxE_IRQ(TxE_IRQ),
  .TxB_IRQ(TxB_IRQ), 
  .RxAbort(RxAbort_wb),
  .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2), 
  .InvalidSymbol(InvalidSymbol),
  .LatchedCrcError(LatchedCrcError),
  .RxLength(RxByteCnt),
  .RxLateCollision(RxLateCollision),
  .ShortFrame(ShortFrame),
  .DribbleNibble(DribbleNibble),
  .ReceivedPacketTooBig(ReceivedPacketTooBig),
  .LoadRxStatus(LoadRxStatus),
  .RetryCntLatched(RetryCntLatched),
  .RetryLimit(RetryLimit),
  .LateCollLatched(LateCollLatched),
  .DeferLatched(DeferLatched),
  .RstDeferLatched(RstDeferLatched),
  .CarrierSenseLost(CarrierSenseLost),
  .ReceivedPacketGood(ReceivedPacketGood),
  .AddressMiss(AddressMiss),
  .ReceivedPauseFrm(ReceivedPauseFrm)
);
assign m_wb_adr_o = {m_wb_adr_tmp, 2'h0};
eth_macstatus macstatus1 
(
  .MRxClk(mrx_clk_pad_i),
  .Reset(wb_rst_i),
  .ReceiveEnd(ReceiveEnd),
  .ReceivedPacketGood(ReceivedPacketGood),
     .ReceivedLengthOK(ReceivedLengthOK),
  .RxCrcError(RxCrcError),
  .MRxErr(MRxErr_Lb),
  .MRxDV(MRxDV_Lb),
  .RxStateSFD(RxStateSFD),
  .RxStateData(RxStateData),
  .RxStatePreamble(RxStatePreamble),
  .RxStateIdle(RxStateIdle),
  .Transmitting(Transmitting),
  .RxByteCnt(RxByteCnt),
  .RxByteCntEq0(RxByteCntEq0),
  .RxByteCntGreat2(RxByteCntGreat2),
  .RxByteCntMaxFrame(RxByteCntMaxFrame),
  .InvalidSymbol(InvalidSymbol),
  .MRxD(MRxD_Lb),
  .LatchedCrcError(LatchedCrcError),
  .Collision(mcoll_pad_i),
  .CollValid(r_CollValid),
  .RxLateCollision(RxLateCollision),
  .r_RecSmall(r_RecSmall),
  .r_MinFL(r_MinFL),
  .r_MaxFL(r_MaxFL),
  .ShortFrame(ShortFrame),
  .DribbleNibble(DribbleNibble),
  .ReceivedPacketTooBig(ReceivedPacketTooBig),
  .r_HugEn(r_HugEn),
  .LoadRxStatus(LoadRxStatus),
  .RetryCnt(RetryCnt),
  .StartTxDone(StartTxDone),
  .StartTxAbort(StartTxAbort),
  .RetryCntLatched(RetryCntLatched),
  .MTxClk(mtx_clk_pad_i),
  .MaxCollisionOccured(MaxCollisionOccured),
  .RetryLimit(RetryLimit),
  .LateCollision(LateCollision),
  .LateCollLatched(LateCollLatched),
  .DeferIndication(DeferIndication),
  .DeferLatched(DeferLatched),
  .RstDeferLatched(RstDeferLatched),
  .TxStartFrm(TxStartFrmOut),
  .StatePreamble(StatePreamble),
  .StateData(StateData),
  .CarrierSense(CarrierSense_Tx2),
  .CarrierSenseLost(CarrierSenseLost),
  .TxUsedData(TxUsedDataIn),
  .LatchedMRxErr(LatchedMRxErr),
  .Loopback(r_LoopBck),
  .r_FullD(r_FullD)
);
endmodule
 `timescale 1ns / 1ns
module eth_clockgen(Clk, Reset, Divider, MdcEn, MdcEn_n, Mdc);
input       Clk;               
input       Reset;             
input [7:0] Divider;           
output      Mdc;               
output      MdcEn;             
output      MdcEn_n;           
reg         Mdc;
reg   [7:0] Counter;
wire        CountEq0;
wire  [7:0] CounterPreset;
wire  [7:0] TempDivider;
assign TempDivider[7:0]   = (Divider[7:0]<2)? 8'h02 : Divider[7:0];  
assign CounterPreset[7:0] = (TempDivider[7:0]>>1) - 8'b1;            
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    Counter[7:0] <=  8'h1;
  else
    begin
      if(CountEq0)
        begin
          Counter[7:0] <=  CounterPreset[7:0];
        end
      else
        Counter[7:0] <=  Counter - 8'h1;
    end
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    Mdc <=  1'b0;
  else
    begin
      if(CountEq0)
        Mdc <=  ~Mdc;
    end
end
assign CountEq0 = Counter == 8'h0;
assign MdcEn = CountEq0 & ~Mdc;
assign MdcEn_n = CountEq0 & Mdc;
endmodule
 `timescale 1ns / 1ns
module eth_cop
(
  wb_clk_i, wb_rst_i, 
  m1_wb_adr_i, m1_wb_sel_i, m1_wb_we_i,  m1_wb_dat_o, 
  m1_wb_dat_i, m1_wb_cyc_i, m1_wb_stb_i, m1_wb_ack_o, 
  m1_wb_err_o, 
  m2_wb_adr_i, m2_wb_sel_i, m2_wb_we_i,  m2_wb_dat_o, 
  m2_wb_dat_i, m2_wb_cyc_i, m2_wb_stb_i, m2_wb_ack_o, 
  m2_wb_err_o, 
 	s1_wb_adr_o, s1_wb_sel_o, s1_wb_we_o,  s1_wb_cyc_o, 
 	s1_wb_stb_o, s1_wb_ack_i, s1_wb_err_i, s1_wb_dat_i,
 	s1_wb_dat_o, 
 	s2_wb_adr_o, s2_wb_sel_o, s2_wb_we_o,  s2_wb_cyc_o, 
 	s2_wb_stb_o, s2_wb_ack_i, s2_wb_err_i, s2_wb_dat_i,
 	s2_wb_dat_o
);
parameter ETH_BASE     = 32'hd0000000;
parameter ETH_WIDTH    = 32'h800;
parameter MEMORY_BASE  = 32'h2000;
parameter MEMORY_WIDTH = 32'h10000;
input wb_clk_i, wb_rst_i;
input  [31:0] m1_wb_adr_i, m1_wb_dat_i;
input   [3:0] m1_wb_sel_i;
input         m1_wb_cyc_i, m1_wb_stb_i, m1_wb_we_i;
output [31:0] m1_wb_dat_o;
output        m1_wb_ack_o, m1_wb_err_o;
input  [31:0] m2_wb_adr_i, m2_wb_dat_i;
input   [3:0] m2_wb_sel_i;
input         m2_wb_cyc_i, m2_wb_stb_i, m2_wb_we_i;
output [31:0] m2_wb_dat_o;
output        m2_wb_ack_o, m2_wb_err_o;
input  [31:0] s1_wb_dat_i;
input         s1_wb_ack_i, s1_wb_err_i;
output [31:0] s1_wb_adr_o, s1_wb_dat_o;
output  [3:0] s1_wb_sel_o;
output        s1_wb_we_o,  s1_wb_cyc_o, s1_wb_stb_o;
input  [31:0] s2_wb_dat_i;
input         s2_wb_ack_i, s2_wb_err_i;
output [31:0] s2_wb_adr_o, s2_wb_dat_o;
output  [3:0] s2_wb_sel_o;
output        s2_wb_we_o,  s2_wb_cyc_o, s2_wb_stb_o;
reg           m1_in_progress;
reg           m2_in_progress;
reg    [31:0] s1_wb_adr_o;
reg     [3:0] s1_wb_sel_o;
reg           s1_wb_we_o;
reg    [31:0] s1_wb_dat_o;
reg           s1_wb_cyc_o;
reg           s1_wb_stb_o;
reg    [31:0] s2_wb_adr_o;
reg     [3:0] s2_wb_sel_o;
reg           s2_wb_we_o;
reg    [31:0] s2_wb_dat_o;
reg           s2_wb_cyc_o;
reg           s2_wb_stb_o;
reg           m1_wb_ack_o;
reg    [31:0] m1_wb_dat_o;
reg           m2_wb_ack_o;
reg    [31:0] m2_wb_dat_o;
reg           m1_wb_err_o;
reg           m2_wb_err_o;
wire m_wb_access_finished;
wire m1_addressed_s1 = (m1_wb_adr_i >= ETH_BASE) &
                       (m1_wb_adr_i < (ETH_BASE + ETH_WIDTH));
wire m1_addressed_s2 = (m1_wb_adr_i >= MEMORY_BASE) &
                       (m1_wb_adr_i < (MEMORY_BASE + MEMORY_WIDTH));
wire m2_addressed_s1 = (m2_wb_adr_i >= ETH_BASE) &
                       (m2_wb_adr_i < (ETH_BASE + ETH_WIDTH));
wire m2_addressed_s2 = (m2_wb_adr_i >= MEMORY_BASE) &
                       (m2_wb_adr_i < (MEMORY_BASE + MEMORY_WIDTH));
wire m1_req = m1_wb_cyc_i & m1_wb_stb_i & (m1_addressed_s1 | m1_addressed_s2);
wire m2_req = m2_wb_cyc_i & m2_wb_stb_i & (m2_addressed_s1 | m2_addressed_s2);
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    begin
      m1_in_progress <= 0;
      m2_in_progress <= 0;
      s1_wb_adr_o    <= 0;
      s1_wb_sel_o    <= 0;
      s1_wb_we_o     <= 0;
      s1_wb_dat_o    <= 0;
      s1_wb_cyc_o    <= 0;
      s1_wb_stb_o    <= 0;
      s2_wb_adr_o    <= 0;
      s2_wb_sel_o    <= 0;
      s2_wb_we_o     <= 0;
      s2_wb_dat_o    <= 0;
      s2_wb_cyc_o    <= 0;
      s2_wb_stb_o    <= 0;
    end
  else
    begin
      case({m1_in_progress, m2_in_progress, m1_req, m2_req, m_wb_access_finished})  
        5'b00_10_0, 5'b00_11_0 :
          begin
            m1_in_progress <= 1'b1;   
            if(m1_addressed_s1)
              begin
                s1_wb_adr_o <= m1_wb_adr_i;
                s1_wb_sel_o <= m1_wb_sel_i;
                s1_wb_we_o  <= m1_wb_we_i;
                s1_wb_dat_o <= m1_wb_dat_i;
                s1_wb_cyc_o <= 1'b1;
                s1_wb_stb_o <= 1'b1;
              end
            else if(m1_addressed_s2)
              begin
                s2_wb_adr_o <= m1_wb_adr_i;
                s2_wb_sel_o <= m1_wb_sel_i;
                s2_wb_we_o  <= m1_wb_we_i;
                s2_wb_dat_o <= m1_wb_dat_i;
                s2_wb_cyc_o <= 1'b1;
                s2_wb_stb_o <= 1'b1;
              end
            else
              $display("(%t)(%m)WISHBONE ERROR: Unspecified address space accessed", $time);
          end
        5'b00_01_0 :
          begin
            m2_in_progress <= 1'b1;   
            if(m2_addressed_s1)
              begin
                s1_wb_adr_o <= m2_wb_adr_i;
                s1_wb_sel_o <= m2_wb_sel_i;
                s1_wb_we_o  <= m2_wb_we_i;
                s1_wb_dat_o <= m2_wb_dat_i;
                s1_wb_cyc_o <= 1'b1;
                s1_wb_stb_o <= 1'b1;
              end
            else if(m2_addressed_s2)
              begin
                s2_wb_adr_o <= m2_wb_adr_i;
                s2_wb_sel_o <= m2_wb_sel_i;
                s2_wb_we_o  <= m2_wb_we_i;
                s2_wb_dat_o <= m2_wb_dat_i;
                s2_wb_cyc_o <= 1'b1;
                s2_wb_stb_o <= 1'b1;
              end
            else
              $display("(%t)(%m)WISHBONE ERROR: Unspecified address space accessed", $time);
          end
        5'b10_10_1, 5'b10_11_1 :
          begin
            m1_in_progress <= 1'b0;   
            if(m1_addressed_s1)
              begin
                s1_wb_cyc_o <= 1'b0;
                s1_wb_stb_o <= 1'b0;
              end
            else if(m1_addressed_s2)
              begin
                s2_wb_cyc_o <= 1'b0;
                s2_wb_stb_o <= 1'b0;
              end
          end
        5'b01_01_1, 5'b01_11_1 :
          begin
            m2_in_progress <= 1'b0;   
            if(m2_addressed_s1)
              begin
                s1_wb_cyc_o <= 1'b0;
                s1_wb_stb_o <= 1'b0;
              end
            else if(m2_addressed_s2)
              begin
                s2_wb_cyc_o <= 1'b0;
                s2_wb_stb_o <= 1'b0;
              end
          end
      endcase
    end
end
always @ (m1_in_progress or m1_wb_adr_i or s1_wb_ack_i or s2_wb_ack_i or s1_wb_dat_i or s2_wb_dat_i or m1_addressed_s1 or m1_addressed_s2)
begin
  if(m1_in_progress)
    begin
      if(m1_addressed_s1) begin
        m1_wb_ack_o <= s1_wb_ack_i;
        m1_wb_dat_o <= s1_wb_dat_i;
      end
      else if(m1_addressed_s2) begin
        m1_wb_ack_o <= s2_wb_ack_i;
        m1_wb_dat_o <= s2_wb_dat_i;
      end
    end
  else
    m1_wb_ack_o <= 0;
end
always @ (m2_in_progress or m2_wb_adr_i or s1_wb_ack_i or s2_wb_ack_i or s1_wb_dat_i or s2_wb_dat_i or m2_addressed_s1 or m2_addressed_s2)
begin
  if(m2_in_progress)
    begin
      if(m2_addressed_s1) begin
        m2_wb_ack_o <= s1_wb_ack_i;
        m2_wb_dat_o <= s1_wb_dat_i;
      end
      else if(m2_addressed_s2) begin
        m2_wb_ack_o <= s2_wb_ack_i;
        m2_wb_dat_o <= s2_wb_dat_i;
      end
    end
  else
    m2_wb_ack_o <= 0;
end
always @ (m1_in_progress or m1_wb_adr_i or s1_wb_err_i or s2_wb_err_i or m2_addressed_s1 or m2_addressed_s2 or
          m1_wb_cyc_i or m1_wb_stb_i)
begin
  if(m1_in_progress)  begin
    if(m1_addressed_s1)
      m1_wb_err_o <= s1_wb_err_i;
    else if(m1_addressed_s2)
      m1_wb_err_o <= s2_wb_err_i;
  end
  else if(m1_wb_cyc_i & m1_wb_stb_i & ~m1_addressed_s1 & ~m1_addressed_s2)
    m1_wb_err_o <= 1'b1;
  else
    m1_wb_err_o <= 1'b0;
end
always @ (m2_in_progress or m2_wb_adr_i or s1_wb_err_i or s2_wb_err_i or m2_addressed_s1 or m2_addressed_s2 or
          m2_wb_cyc_i or m2_wb_stb_i)
begin
  if(m2_in_progress)  begin
    if(m2_addressed_s1)
      m2_wb_err_o <= s1_wb_err_i;
    else if(m2_addressed_s2)
      m2_wb_err_o <= s2_wb_err_i;
  end
  else if(m2_wb_cyc_i & m2_wb_stb_i & ~m2_addressed_s1 & ~m2_addressed_s2)
    m2_wb_err_o <= 1'b1;
  else
    m2_wb_err_o <= 1'b0;
end
assign m_wb_access_finished = m1_wb_ack_o | m1_wb_err_o | m2_wb_ack_o | m2_wb_err_o;
integer cnt;
always @ (posedge wb_clk_i or posedge wb_rst_i)
begin
  if(wb_rst_i)
    cnt <= 0;
  else
  if(s1_wb_ack_i | s1_wb_err_i | s2_wb_ack_i | s2_wb_err_i)
    cnt <= 0;
  else
  if(s1_wb_cyc_o | s2_wb_cyc_o)
    cnt <= cnt+1;
end
always @ (posedge wb_clk_i)
begin
  if(cnt==1000) begin
    $display("(%0t)(%m) ERROR: WB activity ??? ", $time);
    if(s1_wb_cyc_o) begin
      $display("s1_wb_dat_o = 0x%0x", s1_wb_dat_o);
      $display("s1_wb_adr_o = 0x%0x", s1_wb_adr_o);
      $display("s1_wb_sel_o = 0x%0x", s1_wb_sel_o);
      $display("s1_wb_we_o = 0x%0x", s1_wb_we_o);
    end
    else if(s2_wb_cyc_o) begin
      $display("s2_wb_dat_o = 0x%0x", s2_wb_dat_o);
      $display("s2_wb_adr_o = 0x%0x", s2_wb_adr_o);
      $display("s2_wb_sel_o = 0x%0x", s2_wb_sel_o);
      $display("s2_wb_we_o = 0x%0x", s2_wb_we_o);
    end
    $stop;
  end
end
always @ (posedge wb_clk_i)
begin
  if(s1_wb_err_i & s1_wb_cyc_o) begin
    $display("(%0t) ERROR: WB cycle finished with error acknowledge ", $time);
    $display("s1_wb_dat_o = 0x%0x", s1_wb_dat_o);
    $display("s1_wb_adr_o = 0x%0x", s1_wb_adr_o);
    $display("s1_wb_sel_o = 0x%0x", s1_wb_sel_o);
    $display("s1_wb_we_o = 0x%0x", s1_wb_we_o);
    $stop;
  end
  if(s2_wb_err_i & s2_wb_cyc_o) begin
    $display("(%0t) ERROR: WB cycle finished with error acknowledge ", $time);
    $display("s2_wb_dat_o = 0x%0x", s2_wb_dat_o);
    $display("s2_wb_adr_o = 0x%0x", s2_wb_adr_o);
    $display("s2_wb_sel_o = 0x%0x", s2_wb_sel_o);
    $display("s2_wb_we_o = 0x%0x", s2_wb_we_o);
    $stop;
  end
end
endmodule
 `timescale 1ns / 1ns
module eth_crc (Clk, Reset, Data, Enable, Initialize, Crc, CrcError);
input Clk;
input Reset;
input [3:0] Data;
input Enable;
input Initialize;
output [31:0] Crc;
output CrcError;
reg  [31:0] Crc;
wire [31:0] CrcNext;
assign CrcNext[0] = Enable & (Data[0] ^ Crc[28]); 
assign CrcNext[1] = Enable & (Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29]); 
assign CrcNext[2] = Enable & (Data[2] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^ Crc[30]); 
assign CrcNext[3] = Enable & (Data[3] ^ Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30] ^ Crc[31]); 
assign CrcNext[4] = (Enable & (Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^ Crc[31])) ^ Crc[0]; 
assign CrcNext[5] = (Enable & (Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^ Crc[31])) ^ Crc[1]; 
assign CrcNext[6] = (Enable & (Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30])) ^ Crc[ 2]; 
assign CrcNext[7] = (Enable & (Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^ Crc[31])) ^ Crc[3]; 
assign CrcNext[8] = (Enable & (Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^ Crc[31])) ^ Crc[4]; 
assign CrcNext[9] = (Enable & (Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30])) ^ Crc[5]; 
assign CrcNext[10] = (Enable & (Data[3] ^ Data[2] ^ Data[0] ^ Crc[28] ^ Crc[30] ^ Crc[31])) ^ Crc[6]; 
assign CrcNext[11] = (Enable & (Data[3] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^ Crc[31])) ^ Crc[7]; 
assign CrcNext[12] = (Enable & (Data[2] ^ Data[1] ^ Data[0] ^ Crc[28] ^ Crc[29] ^ Crc[30])) ^ Crc[8]; 
assign CrcNext[13] = (Enable & (Data[3] ^ Data[2] ^ Data[1] ^ Crc[29] ^ Crc[30] ^ Crc[31])) ^ Crc[9]; 
assign CrcNext[14] = (Enable & (Data[3] ^ Data[2] ^ Crc[30] ^ Crc[31])) ^ Crc[10]; 
assign CrcNext[15] = (Enable & (Data[3] ^ Crc[31])) ^ Crc[11]; 
assign CrcNext[16] = (Enable & (Data[0] ^ Crc[28])) ^ Crc[12]; 
assign CrcNext[17] = (Enable & (Data[1] ^ Crc[29])) ^ Crc[13]; 
assign CrcNext[18] = (Enable & (Data[2] ^ Crc[30])) ^ Crc[14]; 
assign CrcNext[19] = (Enable & (Data[3] ^ Crc[31])) ^ Crc[15]; 
assign CrcNext[20] = Crc[16]; 
assign CrcNext[21] = Crc[17]; 
assign CrcNext[22] = (Enable & (Data[0] ^ Crc[28])) ^ Crc[18]; 
assign CrcNext[23] = (Enable & (Data[1] ^ Data[0] ^ Crc[29] ^ Crc[28])) ^ Crc[19]; 
assign CrcNext[24] = (Enable & (Data[2] ^ Data[1] ^ Crc[30] ^ Crc[29])) ^ Crc[20]; 
assign CrcNext[25] = (Enable & (Data[3] ^ Data[2] ^ Crc[31] ^ Crc[30])) ^ Crc[21]; 
assign CrcNext[26] = (Enable & (Data[3] ^ Data[0] ^ Crc[31] ^ Crc[28])) ^ Crc[22]; 
assign CrcNext[27] = (Enable & (Data[1] ^ Crc[29])) ^ Crc[23]; 
assign CrcNext[28] = (Enable & (Data[2] ^ Crc[30])) ^ Crc[24]; 
assign CrcNext[29] = (Enable & (Data[3] ^ Crc[31])) ^ Crc[25]; 
assign CrcNext[30] = Crc[26]; 
assign CrcNext[31] = Crc[27]; 
always @ (posedge Clk or posedge Reset)
begin
  if (Reset)
    Crc <=  32'hffffffff;
  else
  if(Initialize)
    Crc <=  32'hffffffff;
  else
    Crc <=  CrcNext;
end
assign CrcError = Crc[31:0] != 32'hc704dd7b;   
endmodule
 `timescale 1ns / 1ns
module eth_fifo (data_in, data_out, clk, reset, write, read, clear,
                 almost_full, full, almost_empty, empty, cnt);
parameter DATA_WIDTH    = 32;
parameter DEPTH         = 8;
parameter CNT_WIDTH     = 4;
input                     clk;
input                     reset;
input                     write;
input                     read;
input                     clear;
input   [DATA_WIDTH-1:0]  data_in;
output  [DATA_WIDTH-1:0]  data_out;
output                    almost_full;
output                    full;
output                    almost_empty;
output                    empty;
output  [CNT_WIDTH-1:0]   cnt;
    reg     [DATA_WIDTH-1:0]  fifo  [0:DEPTH-1];
    reg     [DATA_WIDTH-1:0]  data_out;
reg     [CNT_WIDTH-1:0]   cnt;
reg     [CNT_WIDTH-2:0]   read_pointer;
reg     [CNT_WIDTH-2:0]   write_pointer;
always @ (posedge clk or posedge reset)
begin
  if(reset)
    cnt <= 0;
  else
  if(clear)
    cnt <= { {(CNT_WIDTH-1){1'b0}}, read^write};
  else
  if(read ^ write)
    if(read)
      cnt <= cnt - 1;
    else
      cnt <= cnt + 1;
end
always @ (posedge clk or posedge reset)
begin
  if(reset)
    read_pointer <= 0;
  else
  if(clear)
    read_pointer <= { {(CNT_WIDTH-2){1'b0}}, read};
  else
  if(read & ~empty)
    read_pointer <= read_pointer + 1'b1;
end
always @ (posedge clk or posedge reset)
begin
  if(reset)
    write_pointer <= 0;
  else
  if(clear)
    write_pointer <= { {(CNT_WIDTH-2){1'b0}}, write};
  else
  if(write & ~full)
    write_pointer <= write_pointer + 1'b1;
end
assign empty = ~(|cnt);
assign almost_empty = cnt == 1;
assign full  = cnt == DEPTH;
assign almost_full  = &cnt[CNT_WIDTH-2:0];
  always @ (posedge clk)
  begin
    if(write & clear)
      fifo[0] <= data_in;
    else
   if(write & ~full)
      fifo[write_pointer] <= data_in;
  end
  always @ (posedge clk)
  begin
    if(clear)
      data_out <= fifo[0];
    else
      data_out <= fifo[read_pointer];
  end
endmodule
 `timescale 1ns / 1ns
module eth_maccontrol (MTxClk, MRxClk, TxReset, RxReset, TPauseRq, TxDataIn, TxStartFrmIn, TxUsedDataIn, 
                       TxEndFrmIn, TxDoneIn, TxAbortIn, RxData, RxValid, RxStartFrm, RxEndFrm, ReceiveEnd, 
                       ReceivedPacketGood, ReceivedLengthOK, TxFlow, RxFlow, DlyCrcEn, TxPauseTV, 
                       MAC, PadIn, PadOut, CrcEnIn, CrcEnOut, TxDataOut, TxStartFrmOut, TxEndFrmOut, 
                       TxDoneOut, TxAbortOut, TxUsedDataOut, WillSendControlFrame, TxCtrlEndFrm, 
                       ReceivedPauseFrm, ControlFrmAddressOK, SetPauseTimer, r_PassAll, RxStatusWriteLatched_sync2
                      );
input         MTxClk;                    
input         MRxClk;                    
input         TxReset;                   
input         RxReset;                   
input         TPauseRq;                  
input   [7:0] TxDataIn;                  
input         TxStartFrmIn;              
input         TxUsedDataIn;              
input         TxEndFrmIn;                
input         TxDoneIn;                  
input         TxAbortIn;                 
input         PadIn;                     
input         CrcEnIn;                   
input   [7:0] RxData;                    
input         RxValid;                   
input         RxStartFrm;                
input         RxEndFrm;                  
input         ReceiveEnd;                
input         ReceivedPacketGood;        
input         ReceivedLengthOK;          
input         TxFlow;                    
input         RxFlow;                    
input         DlyCrcEn;                  
input  [15:0] TxPauseTV;                 
input  [47:0] MAC;                       
input         RxStatusWriteLatched_sync2;
input         r_PassAll;
output  [7:0] TxDataOut;                 
output        TxStartFrmOut;             
output        TxEndFrmOut;               
output        TxDoneOut;                 
output        TxAbortOut;                
output        TxUsedDataOut;             
output        PadOut;                    
output        CrcEnOut;                  
output        WillSendControlFrame;
output        TxCtrlEndFrm;
output        ReceivedPauseFrm;
output        ControlFrmAddressOK;
output        SetPauseTimer;
reg           TxUsedDataOutDetected;    
reg           TxAbortInLatched;         
reg           TxDoneInLatched;          
reg           MuxedDone;                
reg           MuxedAbort;               
wire          Pause;                    
wire          TxCtrlStartFrm;
wire    [7:0] ControlData;              
wire          CtrlMux;                  
wire          SendingCtrlFrm;            
wire          BlockTxDone;
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    TxUsedDataOutDetected <=  1'b0;
  else
  if(TxDoneIn | TxAbortIn)
    TxUsedDataOutDetected <=  1'b0;
  else
  if(TxUsedDataOut)
    TxUsedDataOutDetected <=  1'b1;
end    
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    begin
      TxAbortInLatched <=  1'b0;
      TxDoneInLatched  <=  1'b0;
    end
  else
    begin
      TxAbortInLatched <=  TxAbortIn;
      TxDoneInLatched  <=  TxDoneIn;
    end
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    MuxedAbort <=  1'b0;
  else
  if(TxStartFrmIn)
    MuxedAbort <=  1'b0;
  else
  if(TxAbortIn & ~TxAbortInLatched & TxUsedDataOutDetected)
    MuxedAbort <=  1'b1;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    MuxedDone <=  1'b0;
  else
  if(TxStartFrmIn)
    MuxedDone <=  1'b0;
  else
  if(TxDoneIn & (~TxDoneInLatched) & TxUsedDataOutDetected)
    MuxedDone <=  1'b1;
end
assign TxDoneOut  = CtrlMux? ((~TxStartFrmIn) & (~BlockTxDone) & MuxedDone) : 
                             ((~TxStartFrmIn) & (~BlockTxDone) & TxDoneIn);
assign TxAbortOut  = CtrlMux? ((~TxStartFrmIn) & (~BlockTxDone) & MuxedAbort) :
                              ((~TxStartFrmIn) & (~BlockTxDone) & TxAbortIn);
assign TxUsedDataOut  = ~CtrlMux & TxUsedDataIn;
assign TxStartFrmOut = CtrlMux? TxCtrlStartFrm : (TxStartFrmIn & ~Pause);
assign TxEndFrmOut = CtrlMux? TxCtrlEndFrm : TxEndFrmIn;
assign TxDataOut[7:0] = CtrlMux? ControlData[7:0] : TxDataIn[7:0];
assign PadOut = PadIn | SendingCtrlFrm;
assign CrcEnOut = CrcEnIn | SendingCtrlFrm;
eth_receivecontrol receivecontrol1 
(
 .MTxClk(MTxClk), .MRxClk(MRxClk), .TxReset(TxReset), .RxReset(RxReset), .RxData(RxData), 
 .RxValid(RxValid), .RxStartFrm(RxStartFrm), .RxEndFrm(RxEndFrm), .RxFlow(RxFlow), 
 .ReceiveEnd(ReceiveEnd), .MAC(MAC), .DlyCrcEn(DlyCrcEn), .TxDoneIn(TxDoneIn), 
 .TxAbortIn(TxAbortIn), .TxStartFrmOut(TxStartFrmOut), .ReceivedLengthOK(ReceivedLengthOK), 
 .ReceivedPacketGood(ReceivedPacketGood), .TxUsedDataOutDetected(TxUsedDataOutDetected), 
 .Pause(Pause), .ReceivedPauseFrm(ReceivedPauseFrm), .AddressOK(ControlFrmAddressOK), 
 .r_PassAll(r_PassAll), .RxStatusWriteLatched_sync2(RxStatusWriteLatched_sync2), .SetPauseTimer(SetPauseTimer)
);
eth_transmitcontrol transmitcontrol1
(
 .MTxClk(MTxClk), .TxReset(TxReset), .TxUsedDataIn(TxUsedDataIn), .TxUsedDataOut(TxUsedDataOut), 
 .TxDoneIn(TxDoneIn), .TxAbortIn(TxAbortIn), .TxStartFrmIn(TxStartFrmIn), .TPauseRq(TPauseRq), 
 .TxUsedDataOutDetected(TxUsedDataOutDetected), .TxFlow(TxFlow), .DlyCrcEn(DlyCrcEn), .TxPauseTV(TxPauseTV), 
 .MAC(MAC), .TxCtrlStartFrm(TxCtrlStartFrm), .TxCtrlEndFrm(TxCtrlEndFrm), .SendingCtrlFrm(SendingCtrlFrm), 
 .CtrlMux(CtrlMux), .ControlData(ControlData), .WillSendControlFrame(WillSendControlFrame), .BlockTxDone(BlockTxDone)
);
endmodule
 `timescale 1ns / 1ns
module eth_macstatus(
                      MRxClk, Reset, ReceivedLengthOK, ReceiveEnd, ReceivedPacketGood, RxCrcError, 
                      MRxErr, MRxDV, RxStateSFD, RxStateData, RxStatePreamble, RxStateIdle, Transmitting, 
                      RxByteCnt, RxByteCntEq0, RxByteCntGreat2, RxByteCntMaxFrame, 
                      InvalidSymbol, MRxD, LatchedCrcError, Collision, CollValid, RxLateCollision,
                      r_RecSmall, r_MinFL, r_MaxFL, ShortFrame, DribbleNibble, ReceivedPacketTooBig, r_HugEn,
                      LoadRxStatus, StartTxDone, StartTxAbort, RetryCnt, RetryCntLatched, MTxClk, MaxCollisionOccured, 
                      RetryLimit, LateCollision, LateCollLatched, DeferIndication, DeferLatched, RstDeferLatched, TxStartFrm,
                      StatePreamble, StateData, CarrierSense, CarrierSenseLost, TxUsedData, LatchedMRxErr, Loopback, 
                      r_FullD
                    );
input         MRxClk;
input         Reset;
input         RxCrcError;
input         MRxErr;
input         MRxDV;
input         RxStateSFD;
input   [1:0] RxStateData;
input         RxStatePreamble;
input         RxStateIdle;
input         Transmitting;
input  [15:0] RxByteCnt;
input         RxByteCntEq0;
input         RxByteCntGreat2;
input         RxByteCntMaxFrame;
input   [3:0] MRxD;
input         Collision;
input   [5:0] CollValid;
input         r_RecSmall;
input  [15:0] r_MinFL;
input  [15:0] r_MaxFL;
input         r_HugEn;
input         StartTxDone;
input         StartTxAbort;
input   [3:0] RetryCnt;
input         MTxClk;
input         MaxCollisionOccured;
input         LateCollision;
input         DeferIndication;
input         TxStartFrm;
input         StatePreamble;
input   [1:0] StateData;
input         CarrierSense;
input         TxUsedData;
input         Loopback;
input         r_FullD;
output        ReceivedLengthOK;
output        ReceiveEnd;
output        ReceivedPacketGood;
output        InvalidSymbol;
output        LatchedCrcError;
output        RxLateCollision;
output        ShortFrame;
output        DribbleNibble;
output        ReceivedPacketTooBig;
output        LoadRxStatus;
output  [3:0] RetryCntLatched;
output        RetryLimit;
output        LateCollLatched;
output        DeferLatched;
input         RstDeferLatched;
output        CarrierSenseLost;
output        LatchedMRxErr;
reg           ReceiveEnd;
reg           LatchedCrcError;
reg           LatchedMRxErr;
reg           LoadRxStatus;
reg           InvalidSymbol;
reg     [3:0] RetryCntLatched;
reg           RetryLimit;
reg           LateCollLatched;
reg           DeferLatched;
reg           CarrierSenseLost;
wire          TakeSample;
wire          SetInvalidSymbol;  
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedCrcError <= 1'b0;
  else
  if(RxStateSFD)
    LatchedCrcError <= 1'b0;
  else
  if(RxStateData[0])
    LatchedCrcError <= RxCrcError & ~RxByteCntEq0;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedMRxErr <= 1'b0;
  else
  if(MRxErr & MRxDV & (RxStatePreamble | RxStateSFD | (|RxStateData) | RxStateIdle & ~Transmitting))
    LatchedMRxErr <= 1'b1;
  else
    LatchedMRxErr <= 1'b0;
end
assign ReceivedPacketGood = ~LatchedCrcError;
assign ReceivedLengthOK = RxByteCnt[15:0] >= r_MinFL[15:0] & RxByteCnt[15:0] <= r_MaxFL[15:0];
assign TakeSample = (|RxStateData)   & (~MRxDV)                    |
                      RxStateData[0] &   MRxDV & RxByteCntMaxFrame;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LoadRxStatus <= 1'b0;
  else
    LoadRxStatus <= TakeSample;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ReceiveEnd  <= 1'b0;
  else
    ReceiveEnd  <= LoadRxStatus;                     
end
assign SetInvalidSymbol = MRxDV & MRxErr & MRxD[3:0] == 4'he;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    InvalidSymbol <= 1'b0;
  else
  if(LoadRxStatus & ~SetInvalidSymbol)
    InvalidSymbol <= 1'b0;
  else
  if(SetInvalidSymbol)
    InvalidSymbol <= 1'b1;
end
reg RxLateCollision;
reg RxColWindow;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxLateCollision <= 1'b0;
  else
  if(LoadRxStatus)
    RxLateCollision <= 1'b0;
  else
  if(Collision & (~r_FullD) & (~RxColWindow | r_RecSmall))
    RxLateCollision <= 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxColWindow <= 1'b1;
  else
  if(~Collision & RxByteCnt[5:0] == CollValid[5:0] & RxStateData[1])
    RxColWindow <= 1'b0;
  else
  if(RxStateIdle)
    RxColWindow <= 1'b1;
end
reg ShortFrame;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShortFrame <= 1'b0;
  else
  if(LoadRxStatus)
    ShortFrame <= 1'b0;
  else
  if(TakeSample)
    ShortFrame <= RxByteCnt[15:0] < r_MinFL[15:0];
end
reg DribbleNibble;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    DribbleNibble <= 1'b0;
  else
  if(RxStateSFD)
    DribbleNibble <= 1'b0;
  else
  if(~MRxDV & RxStateData[1])
    DribbleNibble <= 1'b1;
end
reg ReceivedPacketTooBig;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ReceivedPacketTooBig <= 1'b0;
  else
  if(LoadRxStatus)
    ReceivedPacketTooBig <= 1'b0;
  else
  if(TakeSample)
    ReceivedPacketTooBig <= ~r_HugEn & RxByteCnt[15:0] > r_MaxFL[15:0];
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    RetryCntLatched <= 4'h0;
  else
  if(StartTxDone | StartTxAbort)
    RetryCntLatched <= RetryCnt;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    RetryLimit <= 1'h0;
  else
  if(StartTxDone | StartTxAbort)
    RetryLimit <= MaxCollisionOccured;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    LateCollLatched <= 1'b0;
  else
  if(StartTxDone | StartTxAbort)
    LateCollLatched <= LateCollision;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    DeferLatched <= 1'b0;
  else
  if(DeferIndication)
    DeferLatched <= 1'b1;
  else
  if(RstDeferLatched)
    DeferLatched <= 1'b0;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    CarrierSenseLost <= 1'b0;
  else
  if((StatePreamble | (|StateData)) & ~CarrierSense & ~Loopback & ~Collision & ~r_FullD)
    CarrierSenseLost <= 1'b1;
  else
  if(TxStartFrm)
    CarrierSenseLost <= 1'b0;
end
endmodule
 `timescale 1ns / 1ns
module eth_miim
(
  Clk,
  Reset,
  Divider,
  NoPre,
  CtrlData,
  Rgad,
  Fiad,
  WCtrlData,
  RStat,
  ScanStat,
  Mdi,
  Mdo,
  MdoEn,
  Mdc,
  Busy,
  Prsd,
  LinkFail,
  Nvalid,
  WCtrlDataStart,
  RStatStart,
  UpdateMIIRX_DATAReg
);
input         Clk;                 
input         Reset;               
input   [7:0] Divider;             
input  [15:0] CtrlData;            
input   [4:0] Rgad;                
input   [4:0] Fiad;                
input         NoPre;               
input         WCtrlData;           
input         RStat;               
input         ScanStat;            
input         Mdi;                 
output        Mdc;                 
output        Mdo;                 
output        MdoEn;               
output        Busy;                
output        LinkFail;            
output        Nvalid;              
output [15:0] Prsd;                
output        WCtrlDataStart;      
output        RStatStart;          
output        UpdateMIIRX_DATAReg; 
reg           Nvalid;
reg           EndBusy_d;           
reg           EndBusy;             
reg           WCtrlData_q1;        
reg           WCtrlData_q2;        
reg           WCtrlData_q3;        
reg           WCtrlDataStart;      
reg           WCtrlDataStart_q;
reg           WCtrlDataStart_q1;   
reg           WCtrlDataStart_q2;   
reg           RStat_q1;            
reg           RStat_q2;            
reg           RStat_q3;            
reg           RStatStart;          
reg           RStatStart_q1;       
reg           RStatStart_q2;       
reg           ScanStat_q1;         
reg           ScanStat_q2;         
reg           SyncStatMdcEn;       
wire          WriteDataOp;         
wire          ReadStatusOp;        
wire          ScanStatusOp;        
wire          StartOp;             
wire          EndOp;               
reg           InProgress;          
reg           InProgress_q1;       
reg           InProgress_q2;       
reg           InProgress_q3;       
reg           WriteOp;             
reg     [6:0] BitCounter;          
wire    [3:0] ByteSelect;          
wire          MdcEn;               
wire          ShiftedBit;          
wire          MdcEn_n;
wire          LatchByte1_d2;
wire          LatchByte0_d2;
reg           LatchByte1_d;
reg           LatchByte0_d;
reg     [1:0] LatchByte;           
reg           UpdateMIIRX_DATAReg; 
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      EndBusy_d <=  1'b0;
      EndBusy <=  1'b0;
    end
  else
    begin
      EndBusy_d <=  ~InProgress_q2 & InProgress_q3;
      EndBusy   <=  EndBusy_d;
    end
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    UpdateMIIRX_DATAReg <=  0;
  else
  if(EndBusy & ~WCtrlDataStart_q)
    UpdateMIIRX_DATAReg <=  1;
  else
    UpdateMIIRX_DATAReg <=  0;    
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      WCtrlData_q1 <=  1'b0;
      WCtrlData_q2 <=  1'b0;
      WCtrlData_q3 <=  1'b0;
      RStat_q1 <=  1'b0;
      RStat_q2 <=  1'b0;
      RStat_q3 <=  1'b0;
      ScanStat_q1  <=  1'b0;
      ScanStat_q2  <=  1'b0;
      SyncStatMdcEn <=  1'b0;
    end
  else
    begin
      WCtrlData_q1 <=  WCtrlData;
      WCtrlData_q2 <=  WCtrlData_q1;
      WCtrlData_q3 <=  WCtrlData_q2;
      RStat_q1 <=  RStat;
      RStat_q2 <=  RStat_q1;
      RStat_q3 <=  RStat_q2;
      ScanStat_q1  <=  ScanStat;
      ScanStat_q2  <=  ScanStat_q1;
      if(MdcEn)
        SyncStatMdcEn  <=  ScanStat_q2;
    end
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      WCtrlDataStart <=  1'b0;
      WCtrlDataStart_q <=  1'b0;
      RStatStart <=  1'b0;
    end
  else
    begin
      if(EndBusy)
        begin
          WCtrlDataStart <=  1'b0;
          RStatStart <=  1'b0;
        end
      else
        begin
          if(WCtrlData_q2 & ~WCtrlData_q3)
            WCtrlDataStart <=  1'b1;
          if(RStat_q2 & ~RStat_q3)
            RStatStart <=  1'b1;
          WCtrlDataStart_q <=  WCtrlDataStart;
        end
    end
end 
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    Nvalid <=  1'b0;
  else
    begin
      if(~InProgress_q2 & InProgress_q3)
        begin
          Nvalid <=  1'b0;
        end
      else
        begin
          if(ScanStat_q2  & ~SyncStatMdcEn)
            Nvalid <=  1'b1;
        end
    end
end 
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      WCtrlDataStart_q1 <=  1'b0;
      WCtrlDataStart_q2 <=  1'b0;
      RStatStart_q1 <=  1'b0;
      RStatStart_q2 <=  1'b0;
      InProgress_q1 <=  1'b0;
      InProgress_q2 <=  1'b0;
      InProgress_q3 <=  1'b0;
  	  LatchByte0_d <=  1'b0;
  	  LatchByte1_d <=  1'b0;
  	  LatchByte <=  2'b00;
    end
  else
    begin
      if(MdcEn)
        begin
          WCtrlDataStart_q1 <=  WCtrlDataStart;
          WCtrlDataStart_q2 <=  WCtrlDataStart_q1;
          RStatStart_q1 <=  RStatStart;
          RStatStart_q2 <=  RStatStart_q1;
          LatchByte[0] <=  LatchByte0_d;
          LatchByte[1] <=  LatchByte1_d;
          LatchByte0_d <=  LatchByte0_d2;
          LatchByte1_d <=  LatchByte1_d2;
          InProgress_q1 <=  InProgress;
          InProgress_q2 <=  InProgress_q1;
          InProgress_q3 <=  InProgress_q2;
        end
    end
end 
assign WriteDataOp  = WCtrlDataStart_q1 & ~WCtrlDataStart_q2;    
assign ReadStatusOp = RStatStart_q1     & ~RStatStart_q2;
assign ScanStatusOp = SyncStatMdcEn     & ~InProgress & ~InProgress_q1 & ~InProgress_q2;
assign StartOp      = WriteDataOp | ReadStatusOp | ScanStatusOp;
assign Busy = WCtrlData | WCtrlDataStart | RStat | RStatStart | SyncStatMdcEn | EndBusy | InProgress | InProgress_q3 | Nvalid;
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      InProgress <=  1'b0;
      WriteOp <=  1'b0;
    end
  else
    begin
      if(MdcEn)
        begin
          if(StartOp)
            begin
              if(~InProgress)
                WriteOp <=  WriteDataOp;
              InProgress <=  1'b1;
            end
          else
            begin
              if(EndOp)
                begin
                  InProgress <=  1'b0;
                  WriteOp <=  1'b0;
                end
            end
        end
    end
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    BitCounter[6:0] <=  7'h0;
  else
    begin
      if(MdcEn)
        begin
          if(InProgress)
            begin
              if(NoPre & ( BitCounter == 7'h0 ))
                BitCounter[6:0] <=  7'h21;
              else
                BitCounter[6:0] <=  BitCounter[6:0] + 1;
            end
          else
            BitCounter[6:0] <=  7'h0;
        end
    end
end
assign EndOp = BitCounter==63;
assign ByteSelect[0] = InProgress & ((NoPre & (BitCounter == 7'h0)) | (~NoPre & (BitCounter == 7'h20)));
assign ByteSelect[1] = InProgress & (BitCounter == 7'h28);
assign ByteSelect[2] = InProgress & WriteOp & (BitCounter == 7'h30);
assign ByteSelect[3] = InProgress & WriteOp & (BitCounter == 7'h38);
assign LatchByte1_d2 = InProgress & ~WriteOp & BitCounter == 7'h37;
assign LatchByte0_d2 = InProgress & ~WriteOp & BitCounter == 7'h3F;
eth_clockgen clkgen(.Clk(Clk), .Reset(Reset), .Divider(Divider[7:0]), .MdcEn(MdcEn), .MdcEn_n(MdcEn_n), .Mdc(Mdc) 
                   );
eth_shiftreg shftrg(.Clk(Clk), .Reset(Reset), .MdcEn_n(MdcEn_n), .Mdi(Mdi), .Fiad(Fiad), .Rgad(Rgad), 
                    .CtrlData(CtrlData), .WriteOp(WriteOp), .ByteSelect(ByteSelect), .LatchByte(LatchByte), 
                    .ShiftedBit(ShiftedBit), .Prsd(Prsd), .LinkFail(LinkFail)
                   );
eth_outputcontrol outctrl(.Clk(Clk), .Reset(Reset), .MdcEn_n(MdcEn_n), .InProgress(InProgress), 
                          .ShiftedBit(ShiftedBit), .BitCounter(BitCounter), .WriteOp(WriteOp), .NoPre(NoPre), 
                          .Mdo(Mdo), .MdoEn(MdoEn)
                         );
endmodule
 `timescale 1ns / 1ns
module eth_outputcontrol(Clk, Reset, InProgress, ShiftedBit, BitCounter, WriteOp, NoPre, MdcEn_n, Mdo, MdoEn);
input         Clk;                 
input         Reset;               
input         WriteOp;             
input         NoPre;               
input         InProgress;          
input         ShiftedBit;          
input   [6:0] BitCounter;          
input         MdcEn_n;             
output        Mdo;                 
output        MdoEn;               
wire          SerialEn;
reg           MdoEn_2d;
reg           MdoEn_d;
reg           MdoEn;
reg           Mdo_2d;
reg           Mdo_d;
reg           Mdo;                 
assign SerialEn =  WriteOp & InProgress & ( BitCounter>31 | ( ( BitCounter == 0 ) & NoPre ) )
                | ~WriteOp & InProgress & (( BitCounter>31 & BitCounter<46 ) | ( ( BitCounter == 0 ) & NoPre ));
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      MdoEn_2d <=  1'b0;
      MdoEn_d <=  1'b0;
      MdoEn <=  1'b0;
    end
  else
    begin
      if(MdcEn_n)
        begin
          MdoEn_2d <=  SerialEn | InProgress & BitCounter<32;
          MdoEn_d <=  MdoEn_2d;
          MdoEn <=  MdoEn_d;
        end
    end
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    begin
      Mdo_2d <=  1'b0;
      Mdo_d <=  1'b0;
      Mdo <=  1'b0;
    end
  else
    begin
      if(MdcEn_n)
        begin
          Mdo_2d <=  ~SerialEn & BitCounter<32;
          Mdo_d <=  ShiftedBit | Mdo_2d;
          Mdo <=  Mdo_d;
        end
    end
end
endmodule
 `timescale 1ns / 1ns
module eth_random (MTxClk, Reset, StateJam, StateJam_q, RetryCnt, NibCnt, ByteCnt, 
                   RandomEq0, RandomEqByteCnt);
input MTxClk;
input Reset;
input StateJam;
input StateJam_q;
input [3:0] RetryCnt;
input [15:0] NibCnt;
input [9:0] ByteCnt;
output RandomEq0;
output RandomEqByteCnt;
wire Feedback;
reg [9:0] x;
wire [9:0] Random;
reg  [9:0] RandomLatched;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    x[9:0] <=  0;
  else
    x[9:0] <=  {x[8:0], Feedback};
end
assign Feedback = ~(x[2] ^ x[9]);
assign Random [0] = x[0];
assign Random [1] = (RetryCnt > 1) ? x[1] : 1'b0;
assign Random [2] = (RetryCnt > 2) ? x[2] : 1'b0;
assign Random [3] = (RetryCnt > 3) ? x[3] : 1'b0;
assign Random [4] = (RetryCnt > 4) ? x[4] : 1'b0;
assign Random [5] = (RetryCnt > 5) ? x[5] : 1'b0;
assign Random [6] = (RetryCnt > 6) ? x[6] : 1'b0;
assign Random [7] = (RetryCnt > 7) ? x[7] : 1'b0;
assign Random [8] = (RetryCnt > 8) ? x[8] : 1'b0;
assign Random [9] = (RetryCnt > 9) ? x[9] : 1'b0;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    RandomLatched <=  10'h000;
  else
    begin
      if(StateJam & StateJam_q)
        RandomLatched <=  Random;
    end
end
assign RandomEq0 = RandomLatched == 10'h0; 
assign RandomEqByteCnt = ByteCnt[9:0] == RandomLatched & (&NibCnt[6:0]);
endmodule
 `timescale 1ns / 1ns
module eth_receivecontrol (MTxClk, MRxClk, TxReset, RxReset, RxData, RxValid, RxStartFrm, 
                           RxEndFrm, RxFlow, ReceiveEnd, MAC, DlyCrcEn, TxDoneIn, 
                           TxAbortIn, TxStartFrmOut, ReceivedLengthOK, ReceivedPacketGood, 
                           TxUsedDataOutDetected, Pause, ReceivedPauseFrm, AddressOK, 
                           RxStatusWriteLatched_sync2, r_PassAll, SetPauseTimer
                          );
input       MTxClk;
input       MRxClk;
input       TxReset; 
input       RxReset; 
input [7:0] RxData;
input       RxValid;
input       RxStartFrm;
input       RxEndFrm;
input       RxFlow;
input       ReceiveEnd;
input [47:0]MAC;
input       DlyCrcEn;
input       TxDoneIn;
input       TxAbortIn;
input       TxStartFrmOut;
input       ReceivedLengthOK;
input       ReceivedPacketGood;
input       TxUsedDataOutDetected;
input       RxStatusWriteLatched_sync2;
input       r_PassAll;
output      Pause;
output      ReceivedPauseFrm;
output      AddressOK;
output      SetPauseTimer;
reg         Pause;
reg         AddressOK;                 
reg         TypeLengthOK;              
reg         DetectionWindow;           
reg         OpCodeOK;                  
reg  [2:0]  DlyCrcCnt;
reg  [4:0]  ByteCnt;
reg [15:0]  AssembledTimerValue;
reg [15:0]  LatchedTimerValue;
reg         ReceivedPauseFrm;
reg         ReceivedPauseFrmWAddr;
reg         PauseTimerEq0_sync1;
reg         PauseTimerEq0_sync2;
reg [15:0]  PauseTimer;
reg         Divider2;
reg  [5:0]  SlotTimer;
wire [47:0] ReservedMulticast;         
wire [15:0] TypeLength;                
wire        ResetByteCnt;              
wire        IncrementByteCnt;          
wire        ByteCntEq0;                
wire        ByteCntEq1;                
wire        ByteCntEq2;                
wire        ByteCntEq3;                
wire        ByteCntEq4;                
wire        ByteCntEq5;                
wire        ByteCntEq12;               
wire        ByteCntEq13;               
wire        ByteCntEq14;               
wire        ByteCntEq15;               
wire        ByteCntEq16;               
wire        ByteCntEq17;               
wire        ByteCntEq18;               
wire        DecrementPauseTimer;       
wire        PauseTimerEq0;             
wire        ResetSlotTimer;            
wire        IncrementSlotTimer;        
wire        SlotFinished;              
assign ReservedMulticast = 48'h0180C2000001;
assign TypeLength = 16'h8808;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    AddressOK <=  1'b0;
  else
  if(DetectionWindow & ByteCntEq0)
    AddressOK <=   RxData[7:0] == ReservedMulticast[47:40] | RxData[7:0] == MAC[47:40];
  else
  if(DetectionWindow & ByteCntEq1)
    AddressOK <=  (RxData[7:0] == ReservedMulticast[39:32] | RxData[7:0] == MAC[39:32]) & AddressOK;
  else
  if(DetectionWindow & ByteCntEq2)
    AddressOK <=  (RxData[7:0] == ReservedMulticast[31:24] | RxData[7:0] == MAC[31:24]) & AddressOK;
  else
  if(DetectionWindow & ByteCntEq3)
    AddressOK <=  (RxData[7:0] == ReservedMulticast[23:16] | RxData[7:0] == MAC[23:16]) & AddressOK;
  else
  if(DetectionWindow & ByteCntEq4)
    AddressOK <=  (RxData[7:0] == ReservedMulticast[15:8]  | RxData[7:0] == MAC[15:8])  & AddressOK;
  else
  if(DetectionWindow & ByteCntEq5)
    AddressOK <=  (RxData[7:0] == ReservedMulticast[7:0]   | RxData[7:0] == MAC[7:0])   & AddressOK;
  else
  if(ReceiveEnd)
    AddressOK <=  1'b0;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    TypeLengthOK <=  1'b0;
  else
  if(DetectionWindow & ByteCntEq12)
    TypeLengthOK <=  ByteCntEq12 & (RxData[7:0] == TypeLength[15:8]);
  else
  if(DetectionWindow & ByteCntEq13)
    TypeLengthOK <=  ByteCntEq13 & (RxData[7:0] == TypeLength[7:0]) & TypeLengthOK;
  else
  if(ReceiveEnd)
    TypeLengthOK <=  1'b0;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    OpCodeOK <=  1'b0;
  else
  if(ByteCntEq16)
    OpCodeOK <=  1'b0;
  else
    begin
      if(DetectionWindow & ByteCntEq14)
        OpCodeOK <=  ByteCntEq14 & RxData[7:0] == 8'h00;
      if(DetectionWindow & ByteCntEq15)
        OpCodeOK <=  ByteCntEq15 & RxData[7:0] == 8'h01 & OpCodeOK;
    end
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    ReceivedPauseFrmWAddr <=  1'b0;
  else
  if(ReceiveEnd)
    ReceivedPauseFrmWAddr <=  1'b0;
  else
  if(ByteCntEq16 & TypeLengthOK & OpCodeOK & AddressOK)
    ReceivedPauseFrmWAddr <=  1'b1;        
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    AssembledTimerValue[15:0] <=  16'h0;
  else
  if(RxStartFrm)
    AssembledTimerValue[15:0] <=  16'h0;
  else
    begin
      if(DetectionWindow & ByteCntEq16)
        AssembledTimerValue[15:8] <=  RxData[7:0];
      if(DetectionWindow & ByteCntEq17)
        AssembledTimerValue[7:0] <=  RxData[7:0];
    end
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    DetectionWindow <=  1'b1;
  else
  if(ByteCntEq18)
    DetectionWindow <=  1'b0;
  else
  if(ReceiveEnd)
    DetectionWindow <=  1'b1;
end
always @ (posedge MRxClk or posedge RxReset )
begin
  if(RxReset)
    LatchedTimerValue[15:0] <=  16'h0;
  else
  if(DetectionWindow &  ReceivedPauseFrmWAddr &  ByteCntEq18)
    LatchedTimerValue[15:0] <=  AssembledTimerValue[15:0];
  else
  if(ReceiveEnd)
    LatchedTimerValue[15:0] <=  16'h0;
end
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    DlyCrcCnt <=  3'h0;
  else
  if(RxValid & RxEndFrm)
    DlyCrcCnt <=  3'h0;
  else
  if(RxValid & ~RxEndFrm & ~DlyCrcCnt[2])
    DlyCrcCnt <=  DlyCrcCnt + 3'd1;
end
assign ResetByteCnt = RxEndFrm;
assign IncrementByteCnt = RxValid & DetectionWindow & ~ByteCntEq18 & 
			  (~DlyCrcEn | DlyCrcEn & DlyCrcCnt[2]);
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    ByteCnt[4:0] <=  5'h0;
  else
  if(ResetByteCnt)
    ByteCnt[4:0] <=  5'h0;
  else
  if(IncrementByteCnt)
    ByteCnt[4:0] <=  ByteCnt[4:0] + 5'd1;
end
assign ByteCntEq0 = RxValid & ByteCnt[4:0] == 5'h0;
assign ByteCntEq1 = RxValid & ByteCnt[4:0] == 5'h1;
assign ByteCntEq2 = RxValid & ByteCnt[4:0] == 5'h2;
assign ByteCntEq3 = RxValid & ByteCnt[4:0] == 5'h3;
assign ByteCntEq4 = RxValid & ByteCnt[4:0] == 5'h4;
assign ByteCntEq5 = RxValid & ByteCnt[4:0] == 5'h5;
assign ByteCntEq12 = RxValid & ByteCnt[4:0] == 5'h0C;
assign ByteCntEq13 = RxValid & ByteCnt[4:0] == 5'h0D;
assign ByteCntEq14 = RxValid & ByteCnt[4:0] == 5'h0E;
assign ByteCntEq15 = RxValid & ByteCnt[4:0] == 5'h0F;
assign ByteCntEq16 = RxValid & ByteCnt[4:0] == 5'h10;
assign ByteCntEq17 = RxValid & ByteCnt[4:0] == 5'h11;
assign ByteCntEq18 = RxValid & ByteCnt[4:0] == 5'h12 & DetectionWindow;
assign SetPauseTimer = ReceiveEnd & ReceivedPauseFrmWAddr & ReceivedPacketGood & ReceivedLengthOK & RxFlow;
assign DecrementPauseTimer = SlotFinished & |PauseTimer;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    PauseTimer[15:0] <=  16'h0;
  else
  if(SetPauseTimer)
    PauseTimer[15:0] <=  LatchedTimerValue[15:0];
  else
  if(DecrementPauseTimer)
    PauseTimer[15:0] <=  PauseTimer[15:0] - 16'd1;
end
assign PauseTimerEq0 = ~(|PauseTimer[15:0]);
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    begin
      PauseTimerEq0_sync1 <=  1'b1;
      PauseTimerEq0_sync2 <=  1'b1;
    end
  else
    begin
      PauseTimerEq0_sync1 <=  PauseTimerEq0;
      PauseTimerEq0_sync2 <=  PauseTimerEq0_sync1;
    end
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    Pause <=  1'b0;
  else
  if((TxDoneIn | TxAbortIn | ~TxUsedDataOutDetected) & ~TxStartFrmOut)
    Pause <=  RxFlow & ~PauseTimerEq0_sync2;
end
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    Divider2 <=  1'b0;
  else
  if(|PauseTimer[15:0] & RxFlow)
    Divider2 <=  ~Divider2;
  else
    Divider2 <=  1'b0;
end
assign ResetSlotTimer = RxReset;
assign IncrementSlotTimer =  Pause & RxFlow & Divider2;
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    SlotTimer[5:0] <=  6'h0;
  else
  if(ResetSlotTimer)
    SlotTimer[5:0] <=  6'h0;
  else
  if(IncrementSlotTimer)
    SlotTimer[5:0] <=  SlotTimer[5:0] + 6'd1;
end
assign SlotFinished = &SlotTimer[5:0] & IncrementSlotTimer;   
always @ (posedge MRxClk or posedge RxReset)
begin
  if(RxReset)
    ReceivedPauseFrm <= 1'b0;
  else
  if(RxStatusWriteLatched_sync2 & r_PassAll | ReceivedPauseFrm & (~r_PassAll))
    ReceivedPauseFrm <= 1'b0;
  else
  if(ByteCntEq16 & TypeLengthOK & OpCodeOK)
    ReceivedPauseFrm <= 1'b1;        
end
endmodule
 `timescale 1ns / 1ns
module eth_registers( DataIn, Address, Rw, Cs, Clk, Reset, DataOut, 
                      r_RecSmall, r_Pad, r_HugEn, r_CrcEn, r_DlyCrcEn, 
                      r_FullD, r_ExDfrEn, r_NoBckof, r_LoopBck, r_IFG, 
                      r_Pro, r_Iam, r_Bro, r_NoPre, r_TxEn, r_RxEn, 
                      TxB_IRQ, TxE_IRQ, RxB_IRQ, RxE_IRQ, Busy_IRQ, 
                      r_IPGT, r_IPGR1, r_IPGR2, r_MinFL, r_MaxFL, r_MaxRet, 
                      r_CollValid, r_TxFlow, r_RxFlow, r_PassAll, 
                      r_MiiNoPre, r_ClkDiv, r_WCtrlData, r_RStat, r_ScanStat, 
                      r_RGAD, r_FIAD, r_CtrlData, NValid_stat, Busy_stat, 
                      LinkFail, r_MAC, WCtrlDataStart, RStatStart,
                      UpdateMIIRX_DATAReg, Prsd, r_TxBDNum, int_o,
                      r_HASH0, r_HASH1, r_TxPauseTV, r_TxPauseRq, RstTxPauseRq, TxCtrlEndFrm,
                      dbg_dat,
                      StartTxDone, TxClk, RxClk, SetPauseTimer
                    );
input [31:0] DataIn;
input [7:0] Address;
input Rw;
input [3:0] Cs;
input Clk;
input Reset;
input WCtrlDataStart;
input RStatStart;
input UpdateMIIRX_DATAReg;
input [15:0] Prsd;
output [31:0] DataOut;
reg    [31:0] DataOut;
output r_RecSmall;
output r_Pad;
output r_HugEn;
output r_CrcEn;
output r_DlyCrcEn;
output r_FullD;
output r_ExDfrEn;
output r_NoBckof;
output r_LoopBck;
output r_IFG;
output r_Pro;
output r_Iam;
output r_Bro;
output r_NoPre;
output r_TxEn;
output r_RxEn;
output [31:0] r_HASH0;
output [31:0] r_HASH1;
input TxB_IRQ;
input TxE_IRQ;
input RxB_IRQ;
input RxE_IRQ;
input Busy_IRQ;
output [6:0] r_IPGT;
output [6:0] r_IPGR1;
output [6:0] r_IPGR2;
output [15:0] r_MinFL;
output [15:0] r_MaxFL;
output [3:0] r_MaxRet;
output [5:0] r_CollValid;
output r_TxFlow;
output r_RxFlow;
output r_PassAll;
output r_MiiNoPre;
output [7:0] r_ClkDiv;
output r_WCtrlData;
output r_RStat;
output r_ScanStat;
output [4:0] r_RGAD;
output [4:0] r_FIAD;
output [15:0]r_CtrlData;
input NValid_stat;
input Busy_stat;
input LinkFail;
output [47:0]r_MAC;
output [7:0] r_TxBDNum;
output       int_o;
output [15:0]r_TxPauseTV;
output       r_TxPauseRq;
input        RstTxPauseRq;
input        TxCtrlEndFrm;
input        StartTxDone;
input        TxClk;
input        RxClk;
input        SetPauseTimer;
input [31:0] dbg_dat;  
reg          irq_txb;
reg          irq_txe;
reg          irq_rxb;
reg          irq_rxe;
reg          irq_busy;
reg          irq_txc;
reg          irq_rxc;
reg SetTxCIrq_txclk;
reg SetTxCIrq_sync1, SetTxCIrq_sync2, SetTxCIrq_sync3;
reg SetTxCIrq;
reg ResetTxCIrq_sync1, ResetTxCIrq_sync2;
reg SetRxCIrq_rxclk;
reg SetRxCIrq_sync1, SetRxCIrq_sync2, SetRxCIrq_sync3;
reg SetRxCIrq;
reg ResetRxCIrq_sync1;
reg ResetRxCIrq_sync2;
reg ResetRxCIrq_sync3;
wire [3:0] Write =   Cs  & {4{Rw}};
wire       Read  = (|Cs) &   ~Rw;
wire MODER_Sel      = (Address == 8'h0       );
wire INT_SOURCE_Sel = (Address == 8'h1  );
wire INT_MASK_Sel   = (Address == 8'h2    );
wire IPGT_Sel       = (Address == 8'h3        );
wire IPGR1_Sel      = (Address == 8'h4       );
wire IPGR2_Sel      = (Address == 8'h5       );
wire PACKETLEN_Sel  = (Address == 8'h6   );
wire COLLCONF_Sel   = (Address == 8'h7    );
wire CTRLMODER_Sel  = (Address == 8'h9   );
wire MIIMODER_Sel   = (Address == 8'hA    );
wire MIICOMMAND_Sel = (Address == 8'hB  );
wire MIIADDRESS_Sel = (Address == 8'hC  );
wire MIITX_DATA_Sel = (Address == 8'hD  );
wire MAC_ADDR0_Sel  = (Address == 8'h10   );
wire MAC_ADDR1_Sel  = (Address == 8'h11   );
wire HASH0_Sel      = (Address == 8'h12       );
wire HASH1_Sel      = (Address == 8'h13       );
wire TXCTRL_Sel     = (Address == 8'h14     );
wire RXCTRL_Sel     = (Address == 8'h15     );
wire DBG_REG_Sel    = (Address == 8'h16         );
wire TX_BD_NUM_Sel  = (Address == 8'h8   );
wire [2:0] MODER_Wr;
wire [0:0] INT_SOURCE_Wr;
wire [0:0] INT_MASK_Wr;
wire [0:0] IPGT_Wr;
wire [0:0] IPGR1_Wr;
wire [0:0] IPGR2_Wr;
wire [3:0] PACKETLEN_Wr;
wire [2:0] COLLCONF_Wr;
wire [0:0] CTRLMODER_Wr;
wire [1:0] MIIMODER_Wr;
wire [0:0] MIICOMMAND_Wr;
wire [1:0] MIIADDRESS_Wr;
wire [1:0] MIITX_DATA_Wr;
wire       MIIRX_DATA_Wr;
wire [3:0] MAC_ADDR0_Wr;
wire [1:0] MAC_ADDR1_Wr;
wire [3:0] HASH0_Wr;
wire [3:0] HASH1_Wr;
wire [2:0] TXCTRL_Wr;
wire [0:0] TX_BD_NUM_Wr;
assign MODER_Wr[0]       = Write[0]  & MODER_Sel; 
assign MODER_Wr[1]       = Write[1]  & MODER_Sel; 
assign MODER_Wr[2]       = Write[2]  & MODER_Sel; 
assign INT_SOURCE_Wr[0]  = Write[0]  & INT_SOURCE_Sel; 
assign INT_MASK_Wr[0]    = Write[0]  & INT_MASK_Sel; 
assign IPGT_Wr[0]        = Write[0]  & IPGT_Sel; 
assign IPGR1_Wr[0]       = Write[0]  & IPGR1_Sel; 
assign IPGR2_Wr[0]       = Write[0]  & IPGR2_Sel; 
assign PACKETLEN_Wr[0]   = Write[0]  & PACKETLEN_Sel; 
assign PACKETLEN_Wr[1]   = Write[1]  & PACKETLEN_Sel; 
assign PACKETLEN_Wr[2]   = Write[2]  & PACKETLEN_Sel; 
assign PACKETLEN_Wr[3]   = Write[3]  & PACKETLEN_Sel; 
assign COLLCONF_Wr[0]    = Write[0]  & COLLCONF_Sel; 
assign COLLCONF_Wr[1]    = 1'b0;   
assign COLLCONF_Wr[2]    = Write[2]  & COLLCONF_Sel; 
assign CTRLMODER_Wr[0]   = Write[0]  & CTRLMODER_Sel; 
assign MIIMODER_Wr[0]    = Write[0]  & MIIMODER_Sel; 
assign MIIMODER_Wr[1]    = Write[1]  & MIIMODER_Sel; 
assign MIICOMMAND_Wr[0]  = Write[0]  & MIICOMMAND_Sel; 
assign MIIADDRESS_Wr[0]  = Write[0]  & MIIADDRESS_Sel; 
assign MIIADDRESS_Wr[1]  = Write[1]  & MIIADDRESS_Sel; 
assign MIITX_DATA_Wr[0]  = Write[0]  & MIITX_DATA_Sel; 
assign MIITX_DATA_Wr[1]  = Write[1]  & MIITX_DATA_Sel; 
assign MIIRX_DATA_Wr     = UpdateMIIRX_DATAReg;     
assign MAC_ADDR0_Wr[0]   = Write[0]  & MAC_ADDR0_Sel; 
assign MAC_ADDR0_Wr[1]   = Write[1]  & MAC_ADDR0_Sel; 
assign MAC_ADDR0_Wr[2]   = Write[2]  & MAC_ADDR0_Sel; 
assign MAC_ADDR0_Wr[3]   = Write[3]  & MAC_ADDR0_Sel; 
assign MAC_ADDR1_Wr[0]   = Write[0]  & MAC_ADDR1_Sel; 
assign MAC_ADDR1_Wr[1]   = Write[1]  & MAC_ADDR1_Sel; 
assign HASH0_Wr[0]       = Write[0]  & HASH0_Sel; 
assign HASH0_Wr[1]       = Write[1]  & HASH0_Sel; 
assign HASH0_Wr[2]       = Write[2]  & HASH0_Sel; 
assign HASH0_Wr[3]       = Write[3]  & HASH0_Sel; 
assign HASH1_Wr[0]       = Write[0]  & HASH1_Sel; 
assign HASH1_Wr[1]       = Write[1]  & HASH1_Sel; 
assign HASH1_Wr[2]       = Write[2]  & HASH1_Sel; 
assign HASH1_Wr[3]       = Write[3]  & HASH1_Sel; 
assign TXCTRL_Wr[0]      = Write[0]  & TXCTRL_Sel; 
assign TXCTRL_Wr[1]      = Write[1]  & TXCTRL_Sel; 
assign TXCTRL_Wr[2]      = Write[2]  & TXCTRL_Sel; 
assign TX_BD_NUM_Wr[0]   = Write[0]  & TX_BD_NUM_Sel & (DataIn<='h80); 
wire [31:0] MODEROut;
wire [31:0] INT_SOURCEOut;
wire [31:0] INT_MASKOut;
wire [31:0] IPGTOut;
wire [31:0] IPGR1Out;
wire [31:0] IPGR2Out;
wire [31:0] PACKETLENOut;
wire [31:0] COLLCONFOut;
wire [31:0] CTRLMODEROut;
wire [31:0] MIIMODEROut;
wire [31:0] MIICOMMANDOut;
wire [31:0] MIIADDRESSOut;
wire [31:0] MIITX_DATAOut;
wire [31:0] MIIRX_DATAOut;
wire [31:0] MIISTATUSOut;
wire [31:0] MAC_ADDR0Out;
wire [31:0] MAC_ADDR1Out;
wire [31:0] TX_BD_NUMOut;
wire [31:0] HASH0Out;
wire [31:0] HASH1Out;
wire [31:0] TXCTRLOut;
wire [31:0] DBGOut;
eth_register #(8, 8'h00)        MODER_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (MODEROut[8 - 1:0]),
   .Write     (MODER_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'hA0)        MODER_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (MODEROut[8 + 7:8]),
   .Write     (MODER_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(1, 1'h0)        MODER_2
  (
   .DataIn    (DataIn[1 + 15:16]),
   .DataOut   (MODEROut[1 + 15:16]),
   .Write     (MODER_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MODEROut[31:1 + 16] = 0;
eth_register #(7, 7'h0)  INT_MASK_0
  (
   .DataIn    (DataIn[7 - 1:0]),  
   .DataOut   (INT_MASKOut[7 - 1:0]),
   .Write     (INT_MASK_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign INT_MASKOut[31:7] = 0;
eth_register #(7, 7'h12)          IPGT_0
  (
   .DataIn    (DataIn[7 - 1:0]),
   .DataOut   (IPGTOut[7 - 1:0]),
   .Write     (IPGT_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign IPGTOut[31:7] = 0;
eth_register #(7, 7'h0C)        IPGR1_0
  (
   .DataIn    (DataIn[7 - 1:0]),
   .DataOut   (IPGR1Out[7 - 1:0]),
   .Write     (IPGR1_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign IPGR1Out[31:7] = 0;
eth_register #(7, 7'h12)        IPGR2_0
  (
   .DataIn    (DataIn[7 - 1:0]),
   .DataOut   (IPGR2Out[7 - 1:0]),
   .Write     (IPGR2_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign IPGR2Out[31:7] = 0;
eth_register #(8, 8'h00) PACKETLEN_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (PACKETLENOut[8 - 1:0]),
   .Write     (PACKETLEN_Wr[0]),
   .Clk       (Clk), 
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h06) PACKETLEN_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (PACKETLENOut[8 + 7:8]),
   .Write     (PACKETLEN_Wr[1]),
   .Clk       (Clk), 
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h40) PACKETLEN_2
  (
   .DataIn    (DataIn[8 + 15:16]),
   .DataOut   (PACKETLENOut[8 + 15:16]),
   .Write     (PACKETLEN_Wr[2]),
   .Clk       (Clk), 
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00) PACKETLEN_3
  (
   .DataIn    (DataIn[8 + 23:24]),
   .DataOut   (PACKETLENOut[8 + 23:24]),
   .Write     (PACKETLEN_Wr[3]),
   .Clk       (Clk), 
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(6, 6'h3f)   COLLCONF_0
  (
   .DataIn    (DataIn[6 - 1:0]),
   .DataOut   (COLLCONFOut[6 - 1:0]),
   .Write     (COLLCONF_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(4, 4'hF)   COLLCONF_2
  (
   .DataIn    (DataIn[4 + 15:16]),
   .DataOut   (COLLCONFOut[4 + 15:16]),
   .Write     (COLLCONF_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign COLLCONFOut[15:6] = 0;
assign COLLCONFOut[31:4 + 16] = 0;
eth_register #(8, 8'h40) TX_BD_NUM_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (TX_BD_NUMOut[8 - 1:0]),
   .Write     (TX_BD_NUM_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign TX_BD_NUMOut[31:8] = 0;
eth_register #(3, 3'h0)  CTRLMODER_0
  (
   .DataIn    (DataIn[3 - 1:0]),
   .DataOut   (CTRLMODEROut[3 - 1:0]),
   .Write     (CTRLMODER_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign CTRLMODEROut[31:3] = 0;
eth_register #(8, 8'h64)    MIIMODER_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (MIIMODEROut[8 - 1:0]),
   .Write     (MIIMODER_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(1, 1'h0)    MIIMODER_1
  (
   .DataIn    (DataIn[1 + 7:8]),
   .DataOut   (MIIMODEROut[1 + 7:8]),
   .Write     (MIIMODER_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MIIMODEROut[31:1 + 8] = 0;
eth_register #(1, 0)                                      MIICOMMAND0
  (
   .DataIn    (DataIn[0]),
   .DataOut   (MIICOMMANDOut[0]),
   .Write     (MIICOMMAND_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(1, 0)                                      MIICOMMAND1
  (
   .DataIn    (DataIn[1]),
   .DataOut   (MIICOMMANDOut[1]),
   .Write     (MIICOMMAND_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (RStatStart)
  );
eth_register #(1, 0)                                      MIICOMMAND2
  (
   .DataIn    (DataIn[2]),
   .DataOut   (MIICOMMANDOut[2]),
   .Write     (MIICOMMAND_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (WCtrlDataStart)
  );
assign MIICOMMANDOut[31:3] = 29'h0;
eth_register #(5, 5'h00) MIIADDRESS_0
  (
   .DataIn    (DataIn[5 - 1:0]),
   .DataOut   (MIIADDRESSOut[5 - 1:0]),
   .Write     (MIIADDRESS_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(5, 5'h00) MIIADDRESS_1
  (
   .DataIn    (DataIn[5 + 7:8]),
   .DataOut   (MIIADDRESSOut[5 + 7:8]),
   .Write     (MIIADDRESS_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MIIADDRESSOut[7:5] = 0;
assign MIIADDRESSOut[31:5 + 8] = 0;
eth_register #(8, 8'h00) MIITX_DATA_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (MIITX_DATAOut[8 - 1:0]), 
   .Write     (MIITX_DATA_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00) MIITX_DATA_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (MIITX_DATAOut[8 + 7:8]), 
   .Write     (MIITX_DATA_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MIITX_DATAOut[31:8 + 8] = 0;
eth_register #(16, 16'h0000) MIIRX_DATA
  (
   .DataIn    (Prsd[16-1:0]),
   .DataOut   (MIIRX_DATAOut[16-1:0]),
   .Write     (MIIRX_DATA_Wr),  
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MIIRX_DATAOut[31:16] = 0;
eth_register #(8, 8'h00)  MAC_ADDR0_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (MAC_ADDR0Out[8 - 1:0]),
   .Write     (MAC_ADDR0_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  MAC_ADDR0_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (MAC_ADDR0Out[8 + 7:8]),
   .Write     (MAC_ADDR0_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  MAC_ADDR0_2
  (
   .DataIn    (DataIn[8 + 15:16]),
   .DataOut   (MAC_ADDR0Out[8 + 15:16]),
   .Write     (MAC_ADDR0_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  MAC_ADDR0_3
  (
   .DataIn    (DataIn[8 + 23:24]),
   .DataOut   (MAC_ADDR0Out[8 + 23:24]),
   .Write     (MAC_ADDR0_Wr[3]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  MAC_ADDR1_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (MAC_ADDR1Out[8 - 1:0]),
   .Write     (MAC_ADDR1_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  MAC_ADDR1_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (MAC_ADDR1Out[8 + 7:8]),
   .Write     (MAC_ADDR1_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
assign MAC_ADDR1Out[31:8 + 8] = 0;
eth_register #(8, 8'h00)          RXHASH0_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (HASH0Out[8 - 1:0]),
   .Write     (HASH0_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH0_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (HASH0Out[8 + 7:8]),
   .Write     (HASH0_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH0_2
  (
   .DataIn    (DataIn[8 + 15:16]),
   .DataOut   (HASH0Out[8 + 15:16]),
   .Write     (HASH0_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH0_3
  (
   .DataIn    (DataIn[8 + 23:24]),
   .DataOut   (HASH0Out[8 + 23:24]),
   .Write     (HASH0_Wr[3]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH1_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (HASH1Out[8 - 1:0]),
   .Write     (HASH1_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH1_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (HASH1Out[8 + 7:8]),
   .Write     (HASH1_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH1_2
  (
   .DataIn    (DataIn[8 + 15:16]),
   .DataOut   (HASH1Out[8 + 15:16]),
   .Write     (HASH1_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)          RXHASH1_3
  (
   .DataIn    (DataIn[8 + 23:24]),
   .DataOut   (HASH1Out[8 + 23:24]),
   .Write     (HASH1_Wr[3]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  TXCTRL_0
  (
   .DataIn    (DataIn[8 - 1:0]),
   .DataOut   (TXCTRLOut[8 - 1:0]),
   .Write     (TXCTRL_Wr[0]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(8, 8'h00)  TXCTRL_1
  (
   .DataIn    (DataIn[8 + 7:8]),
   .DataOut   (TXCTRLOut[8 + 7:8]),
   .Write     (TXCTRL_Wr[1]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (1'b0)
  );
eth_register #(1, 1'h0)  TXCTRL_2  
  (
   .DataIn    (DataIn[1 + 15:16]),
   .DataOut   (TXCTRLOut[1 + 15:16]),
   .Write     (TXCTRL_Wr[2]),
   .Clk       (Clk),
   .Reset     (Reset),
   .SyncReset (RstTxPauseRq)
  );
assign TXCTRLOut[31:1 + 16] = 0;
always @ (Address       or Read           or MODEROut       or INT_SOURCEOut  or
          INT_MASKOut   or IPGTOut        or IPGR1Out       or IPGR2Out       or
          PACKETLENOut  or COLLCONFOut    or CTRLMODEROut   or MIIMODEROut    or
          MIICOMMANDOut or MIIADDRESSOut  or MIITX_DATAOut  or MIIRX_DATAOut  or 
          MIISTATUSOut  or MAC_ADDR0Out   or MAC_ADDR1Out   or TX_BD_NUMOut   or
          HASH0Out      or HASH1Out       or TXCTRLOut       
         )
begin
  if(Read)   
    begin
      case(Address)
        8'h0        :  DataOut=MODEROut;
        8'h1   :  DataOut=INT_SOURCEOut;
        8'h2     :  DataOut=INT_MASKOut;
        8'h3         :  DataOut=IPGTOut;
        8'h4        :  DataOut=IPGR1Out;
        8'h5        :  DataOut=IPGR2Out;
        8'h6    :  DataOut=PACKETLENOut;
        8'h7     :  DataOut=COLLCONFOut;
        8'h9    :  DataOut=CTRLMODEROut;
        8'hA     :  DataOut=MIIMODEROut;
        8'hB   :  DataOut=MIICOMMANDOut;
        8'hC   :  DataOut=MIIADDRESSOut;
        8'hD   :  DataOut=MIITX_DATAOut;
        8'hE   :  DataOut=MIIRX_DATAOut;
        8'hF    :  DataOut=MIISTATUSOut;
        8'h10    :  DataOut=MAC_ADDR0Out;
        8'h11    :  DataOut=MAC_ADDR1Out;
        8'h8    :  DataOut=TX_BD_NUMOut;
        8'h12        :  DataOut=HASH0Out;
        8'h13        :  DataOut=HASH1Out;
        8'h14      :  DataOut=TXCTRLOut;
        8'h16          :  DataOut=dbg_dat;
        default:             DataOut=32'h0;
      endcase
    end
  else
    DataOut=32'h0;
end
assign r_RecSmall         = MODEROut[16];
assign r_Pad              = MODEROut[15];
assign r_HugEn            = MODEROut[14];
assign r_CrcEn            = MODEROut[13];
assign r_DlyCrcEn         = MODEROut[12];
assign r_FullD            = MODEROut[10];
assign r_ExDfrEn          = MODEROut[9];
assign r_NoBckof          = MODEROut[8];
assign r_LoopBck          = MODEROut[7];
assign r_IFG              = MODEROut[6];
assign r_Pro              = MODEROut[5];
assign r_Iam              = MODEROut[4];
assign r_Bro              = MODEROut[3];
assign r_NoPre            = MODEROut[2];
assign r_TxEn             = MODEROut[1] & (TX_BD_NUMOut>0);      
assign r_RxEn             = MODEROut[0] & (TX_BD_NUMOut<'h80);   
assign r_IPGT[6:0]        = IPGTOut[6:0];
assign r_IPGR1[6:0]       = IPGR1Out[6:0];
assign r_IPGR2[6:0]       = IPGR2Out[6:0];
assign r_MinFL[15:0]      = PACKETLENOut[31:16];
assign r_MaxFL[15:0]      = PACKETLENOut[15:0];
assign r_MaxRet[3:0]      = COLLCONFOut[19:16];
assign r_CollValid[5:0]   = COLLCONFOut[5:0];
assign r_TxFlow           = CTRLMODEROut[2];
assign r_RxFlow           = CTRLMODEROut[1];
assign r_PassAll          = CTRLMODEROut[0];
assign r_MiiNoPre         = MIIMODEROut[8];
assign r_ClkDiv[7:0]      = MIIMODEROut[7:0];
assign r_WCtrlData        = MIICOMMANDOut[2];
assign r_RStat            = MIICOMMANDOut[1];
assign r_ScanStat         = MIICOMMANDOut[0];
assign r_RGAD[4:0]        = MIIADDRESSOut[12:8];
assign r_FIAD[4:0]        = MIIADDRESSOut[4:0];
assign r_CtrlData[15:0]   = MIITX_DATAOut[15:0];
assign MIISTATUSOut[31:3] = 0; 
assign MIISTATUSOut[2]    = NValid_stat         ; 
assign MIISTATUSOut[1]    = Busy_stat           ; 
assign MIISTATUSOut[0]    = LinkFail            ; 
assign r_MAC[31:0]        = MAC_ADDR0Out[31:0];
assign r_MAC[47:32]       = MAC_ADDR1Out[15:0];
assign r_HASH1[31:0]      = HASH1Out;
assign r_HASH0[31:0]      = HASH0Out;
assign r_TxBDNum[7:0]     = TX_BD_NUMOut[7:0];
assign r_TxPauseTV[15:0]  = TXCTRLOut[15:0];
assign r_TxPauseRq        = TXCTRLOut[16];
always @ (posedge TxClk or posedge Reset)
begin
  if(Reset)
    SetTxCIrq_txclk <= 1'b0;
  else
  if(TxCtrlEndFrm & StartTxDone & r_TxFlow)
    SetTxCIrq_txclk <= 1'b1;
  else
  if(ResetTxCIrq_sync2)
    SetTxCIrq_txclk <= 1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetTxCIrq_sync1 <= 1'b0;
  else
    SetTxCIrq_sync1 <= SetTxCIrq_txclk;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetTxCIrq_sync2 <= 1'b0;
  else
    SetTxCIrq_sync2 <= SetTxCIrq_sync1;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetTxCIrq_sync3 <= 1'b0;
  else
    SetTxCIrq_sync3 <= SetTxCIrq_sync2;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetTxCIrq <= 1'b0;
  else
    SetTxCIrq <= SetTxCIrq_sync2 & ~SetTxCIrq_sync3;
end
always @ (posedge TxClk or posedge Reset)
begin
  if(Reset)
    ResetTxCIrq_sync1 <= 1'b0;
  else
    ResetTxCIrq_sync1 <= SetTxCIrq_sync2;
end
always @ (posedge TxClk or posedge Reset)
begin
  if(Reset)
    ResetTxCIrq_sync2 <= 1'b0;
  else
    ResetTxCIrq_sync2 <= SetTxCIrq_sync1;
end
always @ (posedge RxClk or posedge Reset)
begin
  if(Reset)
    SetRxCIrq_rxclk <= 1'b0;
  else
  if(SetPauseTimer & r_RxFlow)
    SetRxCIrq_rxclk <= 1'b1;
  else
  if(ResetRxCIrq_sync2 & (~ResetRxCIrq_sync3))
    SetRxCIrq_rxclk <= 1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetRxCIrq_sync1 <= 1'b0;
  else
    SetRxCIrq_sync1 <= SetRxCIrq_rxclk;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetRxCIrq_sync2 <= 1'b0;
  else
    SetRxCIrq_sync2 <= SetRxCIrq_sync1;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetRxCIrq_sync3 <= 1'b0;
  else
    SetRxCIrq_sync3 <= SetRxCIrq_sync2;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    SetRxCIrq <= 1'b0;
  else
    SetRxCIrq <= SetRxCIrq_sync2 & ~SetRxCIrq_sync3;
end
always @ (posedge RxClk or posedge Reset)
begin
  if(Reset)
    ResetRxCIrq_sync1 <= 1'b0;
  else
    ResetRxCIrq_sync1 <= SetRxCIrq_sync2;
end
always @ (posedge RxClk or posedge Reset)
begin
  if(Reset)
    ResetRxCIrq_sync2 <= 1'b0;
  else
    ResetRxCIrq_sync2 <= ResetRxCIrq_sync1;
end
always @ (posedge RxClk or posedge Reset)
begin
  if(Reset)
    ResetRxCIrq_sync3 <= 1'b0;
  else
    ResetRxCIrq_sync3 <= ResetRxCIrq_sync2;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_txb <= 1'b0;
  else
  if(TxB_IRQ)
    irq_txb <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[0])
    irq_txb <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_txe <= 1'b0;
  else
  if(TxE_IRQ)
    irq_txe <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[1])
    irq_txe <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_rxb <= 1'b0;
  else
  if(RxB_IRQ)
    irq_rxb <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[2])
    irq_rxb <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_rxe <= 1'b0;
  else
  if(RxE_IRQ)
    irq_rxe <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[3])
    irq_rxe <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_busy <= 1'b0;
  else
  if(Busy_IRQ)
    irq_busy <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[4])
    irq_busy <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_txc <= 1'b0;
  else
  if(SetTxCIrq)
    irq_txc <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[5])
    irq_txc <=  1'b0;
end
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    irq_rxc <= 1'b0;
  else
  if(SetRxCIrq)
    irq_rxc <=  1'b1;
  else
  if(INT_SOURCE_Wr[0] & DataIn[6])
    irq_rxc <=  1'b0;
end
assign int_o = irq_txb  & INT_MASKOut[0] | 
               irq_txe  & INT_MASKOut[1] | 
               irq_rxb  & INT_MASKOut[2] | 
               irq_rxe  & INT_MASKOut[3] | 
               irq_busy & INT_MASKOut[4] | 
               irq_txc  & INT_MASKOut[5] | 
               irq_rxc  & INT_MASKOut[6] ;
assign INT_SOURCEOut = {{(32-7){1'b0}}, irq_rxc, irq_txc, irq_busy, irq_rxe, irq_rxb, irq_txe, irq_txb};
endmodule
 `timescale 1ns / 1ns
module eth_rxaddrcheck(MRxClk,  Reset, RxData, Broadcast ,r_Bro ,r_Pro,
                       ByteCntEq2, ByteCntEq3, ByteCntEq4, ByteCntEq5,
                       ByteCntEq6, ByteCntEq7, HASH0, HASH1, ByteCntEq0,
                       CrcHash,    CrcHashGood, StateData, RxEndFrm,
                       Multicast, MAC, RxAbort, AddressMiss, PassAll,
                       ControlFrmAddressOK
                      );
  input        MRxClk; 
  input        Reset; 
  input [7:0]  RxData; 
  input        Broadcast; 
  input        r_Bro; 
  input        r_Pro; 
  input        ByteCntEq0;
  input        ByteCntEq2;
  input        ByteCntEq3;
  input        ByteCntEq4;
  input        ByteCntEq5;
  input        ByteCntEq6;
  input        ByteCntEq7;
  input [31:0] HASH0; 
  input [31:0] HASH1; 
  input [5:0]  CrcHash; 
  input        CrcHashGood; 
  input        Multicast; 
  input [47:0] MAC;
  input [1:0]  StateData;
  input        RxEndFrm;
  input        PassAll;
  input        ControlFrmAddressOK;
  output       RxAbort;
  output       AddressMiss;
 wire BroadcastOK;
 wire ByteCntEq2;
 wire ByteCntEq3;
 wire ByteCntEq4; 
 wire ByteCntEq5;
 wire RxAddressInvalid;
 wire RxCheckEn;
 wire HashBit;
 wire [31:0] IntHash;
 reg [7:0]  ByteHash;
 reg MulticastOK;
 reg UnicastOK;
 reg RxAbort;
 reg AddressMiss;
assign RxAddressInvalid = ~(UnicastOK | BroadcastOK | MulticastOK | r_Pro);
assign BroadcastOK = Broadcast & ~r_Bro;
assign RxCheckEn   = | StateData;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbort <=  1'b0;
  else if(RxAddressInvalid & ByteCntEq7 & RxCheckEn)
    RxAbort <=  1'b1;
  else
    RxAbort <=  1'b0;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    AddressMiss <=  1'b0;
  else if(ByteCntEq0)
    AddressMiss <=  1'b0;
  else if(ByteCntEq7 & RxCheckEn)
    AddressMiss <=  (~(UnicastOK | BroadcastOK | MulticastOK | (PassAll & ControlFrmAddressOK)));
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    MulticastOK <=  1'b0;
  else if(RxEndFrm | RxAbort)
    MulticastOK <=  1'b0;
  else if(CrcHashGood & Multicast)
    MulticastOK <=  HashBit;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    UnicastOK <=  1'b0;
  else
  if(RxCheckEn & ByteCntEq2)
    UnicastOK <=    RxData[7:0] == MAC[47:40];
  else
  if(RxCheckEn & ByteCntEq3)
    UnicastOK <=  ( RxData[7:0] == MAC[39:32]) & UnicastOK;
  else
  if(RxCheckEn & ByteCntEq4)
    UnicastOK <=  ( RxData[7:0] == MAC[31:24]) & UnicastOK;
  else
  if(RxCheckEn & ByteCntEq5)
    UnicastOK <=  ( RxData[7:0] == MAC[23:16]) & UnicastOK;
  else
  if(RxCheckEn & ByteCntEq6)
    UnicastOK <=  ( RxData[7:0] == MAC[15:8])  & UnicastOK;
  else
  if(RxCheckEn & ByteCntEq7)
    UnicastOK <=  ( RxData[7:0] == MAC[7:0])   & UnicastOK;
  else
  if(RxEndFrm | RxAbort)
    UnicastOK <=  1'b0;
end
assign IntHash = (CrcHash[5])? HASH1 : HASH0;
always@(CrcHash or IntHash)
begin
  case(CrcHash[4:3])
    2'b00: ByteHash = IntHash[7:0];
    2'b01: ByteHash = IntHash[15:8];
    2'b10: ByteHash = IntHash[23:16];
    2'b11: ByteHash = IntHash[31:24];
  endcase
end
assign HashBit = ByteHash[CrcHash[2:0]];
endmodule
 `timescale 1ns / 1ns
module eth_rxcounters 
  (
   MRxClk, Reset, MRxDV, StateIdle, StateSFD, StateData, StateDrop, StatePreamble, 
   MRxDEqD, DlyCrcEn, DlyCrcCnt, Transmitting, MaxFL, r_IFG, HugEn, IFGCounterEq24, 
   ByteCntEq0, ByteCntEq1, ByteCntEq2,ByteCntEq3,ByteCntEq4,ByteCntEq5, ByteCntEq6,
   ByteCntEq7, ByteCntGreat2, ByteCntSmall7, ByteCntMaxFrame, ByteCntOut
   );
input         MRxClk;
input         Reset;
input         MRxDV;
input         StateSFD;
input [1:0]   StateData;
input         MRxDEqD;
input         StateIdle;
input         StateDrop;
input         DlyCrcEn;
input         StatePreamble;
input         Transmitting;
input         HugEn;
input [15:0]  MaxFL;
input         r_IFG;
output        IFGCounterEq24;            
output [3:0]  DlyCrcCnt;                 
output        ByteCntEq0;                
output        ByteCntEq1;                
output        ByteCntEq2;                
output        ByteCntEq3;                
output        ByteCntEq4;                
output        ByteCntEq5;                
output        ByteCntEq6;                
output        ByteCntEq7;                
output        ByteCntGreat2;             
output        ByteCntSmall7;             
output        ByteCntMaxFrame;           
output [15:0] ByteCntOut;                
wire          ResetByteCounter;
wire          IncrementByteCounter;
wire          ResetIFGCounter;
wire          IncrementIFGCounter;
wire          ByteCntMax;
reg   [15:0]  ByteCnt;
reg   [3:0]   DlyCrcCnt;
reg   [4:0]   IFGCounter;
wire  [15:0]  ByteCntDelayed;
assign ResetByteCounter = MRxDV & (StateSFD & MRxDEqD | StateData[0] & ByteCntMaxFrame);
assign IncrementByteCounter = ~ResetByteCounter & MRxDV & 
                              (StatePreamble | StateSFD | StateIdle & ~Transmitting |
                               StateData[1] & ~ByteCntMax & ~(DlyCrcEn & |DlyCrcCnt)
                              );
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ByteCnt[15:0] <=  16'd0;
  else
    begin
      if(ResetByteCounter)
        ByteCnt[15:0] <=  16'd0;
      else
      if(IncrementByteCounter)
        ByteCnt[15:0] <=  ByteCnt[15:0] + 16'd1;
     end
end
assign ByteCntDelayed = ByteCnt + 16'd4;
assign ByteCntOut = DlyCrcEn ? ByteCntDelayed : ByteCnt;
assign ByteCntEq0       = ByteCnt == 16'd0;
assign ByteCntEq1       = ByteCnt == 16'd1;
assign ByteCntEq2       = ByteCnt == 16'd2; 
assign ByteCntEq3       = ByteCnt == 16'd3; 
assign ByteCntEq4       = ByteCnt == 16'd4; 
assign ByteCntEq5       = ByteCnt == 16'd5; 
assign ByteCntEq6       = ByteCnt == 16'd6;
assign ByteCntEq7       = ByteCnt == 16'd7;
assign ByteCntGreat2    = ByteCnt >  16'd2;
assign ByteCntSmall7    = ByteCnt <  16'd7;
assign ByteCntMax       = ByteCnt == 16'hffff;
assign ByteCntMaxFrame  = ByteCnt == MaxFL[15:0] & ~HugEn;
assign ResetIFGCounter = StateSFD  &  MRxDV & MRxDEqD | StateDrop;
assign IncrementIFGCounter = ~ResetIFGCounter & (StateDrop | StateIdle | StatePreamble | StateSFD) & ~IFGCounterEq24;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    IFGCounter[4:0] <=  5'h0;
  else
    begin
      if(ResetIFGCounter)
        IFGCounter[4:0] <=  5'h0;
      else
      if(IncrementIFGCounter)
        IFGCounter[4:0] <=  IFGCounter[4:0] + 5'd1; 
    end
end
assign IFGCounterEq24 = (IFGCounter[4:0] == 5'h18) | r_IFG;  
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    DlyCrcCnt[3:0] <=  4'h0;
  else
    begin
      if(DlyCrcCnt[3:0] == 4'h9)
        DlyCrcCnt[3:0] <=  4'h0;
      else
      if(DlyCrcEn & StateSFD)
        DlyCrcCnt[3:0] <=  4'h1;
      else
      if(DlyCrcEn & (|DlyCrcCnt[3:0]))
        DlyCrcCnt[3:0] <=  DlyCrcCnt[3:0] + 4'd1;
    end
end
endmodule
 `timescale 1ns / 1ns
module eth_register(DataIn, DataOut, Write, Clk, Reset, SyncReset);
parameter WIDTH = 8;  
parameter RESET_VALUE = 0;
input [WIDTH-1:0] DataIn;
input Write;
input Clk;
input Reset;
input SyncReset;
output [WIDTH-1:0] DataOut;
reg    [WIDTH-1:0] DataOut;
always @ (posedge Clk or posedge Reset)
begin
  if(Reset)
    DataOut<= RESET_VALUE;
  else
  if(SyncReset)
    DataOut<= RESET_VALUE;
  else
  if(Write)                          
    DataOut<= DataIn;
end
endmodule    
 `timescale 1ns / 1ns
module eth_rxethmac (MRxClk, MRxDV, MRxD, Reset, Transmitting, MaxFL, r_IFG,
                     HugEn, DlyCrcEn, RxData, RxValid, RxStartFrm, RxEndFrm,
                     ByteCnt, ByteCntEq0, ByteCntGreat2, ByteCntMaxFrame,
                     CrcError, StateIdle, StatePreamble, StateSFD, StateData,
                     MAC, r_Pro, r_Bro,r_HASH0, r_HASH1, RxAbort, AddressMiss,
                     PassAll, ControlFrmAddressOK
                    );
input         MRxClk;
input         MRxDV;
input   [3:0] MRxD;
input         Transmitting;
input         HugEn;
input         DlyCrcEn;
input  [15:0] MaxFL;
input         r_IFG;
input         Reset;
input  [47:0] MAC;      
input         r_Bro;    
input         r_Pro;    
input [31:0]  r_HASH0;  
input [31:0]  r_HASH1;  
input         PassAll;
input         ControlFrmAddressOK;
output  [7:0] RxData;
output        RxValid;
output        RxStartFrm;
output        RxEndFrm;
output [15:0] ByteCnt;
output        ByteCntEq0;
output        ByteCntGreat2;
output        ByteCntMaxFrame;
output        CrcError;
output        StateIdle;
output        StatePreamble;
output        StateSFD;
output  [1:0] StateData;
output        RxAbort;
output        AddressMiss;
reg     [7:0] RxData;
reg           RxValid;
reg           RxStartFrm;
reg           RxEndFrm;
reg           Broadcast;
reg           Multicast;
reg     [5:0] CrcHash;
reg           CrcHashGood;
reg           DelayData;
reg     [7:0] LatchedByte;
reg     [7:0] RxData_d;
reg           RxValid_d;
reg           RxStartFrm_d;
reg           RxEndFrm_d;
wire          MRxDEqD;
wire          MRxDEq5;
wire          StateDrop;
wire          ByteCntEq1;
wire          ByteCntEq2;
wire          ByteCntEq3;
wire          ByteCntEq4;
wire          ByteCntEq5;
wire          ByteCntEq6;
wire          ByteCntEq7;
wire          ByteCntSmall7;
wire   [31:0] Crc;
wire          Enable_Crc;
wire          Initialize_Crc;
wire    [3:0] Data_Crc;
wire          GenerateRxValid;
wire          GenerateRxStartFrm;
wire          GenerateRxEndFrm;
wire          DribbleRxEndFrm;
wire    [3:0] DlyCrcCnt;
wire          IFGCounterEq24;
assign MRxDEqD = MRxD == 4'hd;
assign MRxDEq5 = MRxD == 4'h5;
eth_rxstatem rxstatem1
  (.MRxClk(MRxClk),
   .Reset(Reset),
   .MRxDV(MRxDV),
   .ByteCntEq0(ByteCntEq0),
   .ByteCntGreat2(ByteCntGreat2),
   .Transmitting(Transmitting),
   .MRxDEq5(MRxDEq5),
   .MRxDEqD(MRxDEqD),
   .IFGCounterEq24(IFGCounterEq24),
   .ByteCntMaxFrame(ByteCntMaxFrame),
   .StateData(StateData),
   .StateIdle(StateIdle),
   .StatePreamble(StatePreamble),
   .StateSFD(StateSFD),
   .StateDrop(StateDrop)
   );
eth_rxcounters rxcounters1
  (.MRxClk(MRxClk),
   .Reset(Reset),
   .MRxDV(MRxDV),
   .StateIdle(StateIdle),
   .StateSFD(StateSFD),
   .StateData(StateData),
   .StateDrop(StateDrop),
   .StatePreamble(StatePreamble),
   .MRxDEqD(MRxDEqD),
   .DlyCrcEn(DlyCrcEn),
   .DlyCrcCnt(DlyCrcCnt),
   .Transmitting(Transmitting),
   .MaxFL(MaxFL),
   .r_IFG(r_IFG),
   .HugEn(HugEn),
   .IFGCounterEq24(IFGCounterEq24),
   .ByteCntEq0(ByteCntEq0),
   .ByteCntEq1(ByteCntEq1),
   .ByteCntEq2(ByteCntEq2),
   .ByteCntEq3(ByteCntEq3),
   .ByteCntEq4(ByteCntEq4),
   .ByteCntEq5(ByteCntEq5),
   .ByteCntEq6(ByteCntEq6),
   .ByteCntEq7(ByteCntEq7),
   .ByteCntGreat2(ByteCntGreat2),
   .ByteCntSmall7(ByteCntSmall7),
   .ByteCntMaxFrame(ByteCntMaxFrame),
   .ByteCntOut(ByteCnt)
   );
eth_rxaddrcheck rxaddrcheck1
  (.MRxClk(MRxClk),
   .Reset( Reset),
   .RxData(RxData),
   .Broadcast (Broadcast),
   .r_Bro (r_Bro),
   .r_Pro(r_Pro),
   .ByteCntEq6(ByteCntEq6),
   .ByteCntEq7(ByteCntEq7),
   .ByteCntEq2(ByteCntEq2),
   .ByteCntEq3(ByteCntEq3),
   .ByteCntEq4(ByteCntEq4),
   .ByteCntEq5(ByteCntEq5),
   .HASH0(r_HASH0),
   .HASH1(r_HASH1),
   .ByteCntEq0(ByteCntEq0),
   .CrcHash(CrcHash),
   .CrcHashGood(CrcHashGood),
   .StateData(StateData),
   .Multicast(Multicast),
   .MAC(MAC),
   .RxAbort(RxAbort),
   .RxEndFrm(RxEndFrm),
   .AddressMiss(AddressMiss),
   .PassAll(PassAll),
   .ControlFrmAddressOK(ControlFrmAddressOK)
   );
assign Enable_Crc = MRxDV & (|StateData & ~ByteCntMaxFrame);
assign Initialize_Crc = StateSFD | DlyCrcEn & (|DlyCrcCnt[3:0]) &
                        DlyCrcCnt[3:0] < 4'h9;
assign Data_Crc[0] = MRxD[3];
assign Data_Crc[1] = MRxD[2];
assign Data_Crc[2] = MRxD[1];
assign Data_Crc[3] = MRxD[0];
eth_crc crcrx
  (.Clk(MRxClk),
   .Reset(Reset),
   .Data(Data_Crc),
   .Enable(Enable_Crc),
   .Initialize(Initialize_Crc), 
   .Crc(Crc),
   .CrcError(CrcError)
   );
always @ (posedge MRxClk)
begin
  CrcHashGood <=  StateData[0] & ByteCntEq6;
end
always @ (posedge MRxClk)
begin
  if(Reset | StateIdle)
    CrcHash[5:0] <=  6'h0;
  else
  if(StateData[0] & ByteCntEq6)
    CrcHash[5:0] <=  Crc[31:26];
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxData_d[7:0]      <=  8'h0;
      DelayData          <=  1'b0;
      LatchedByte[7:0]   <=  8'h0;
      RxData[7:0]        <=  8'h0;
    end
  else
    begin
      LatchedByte[7:0]   <=  {MRxD[3:0], LatchedByte[7:4]};
      DelayData          <=  StateData[0];
      if(GenerateRxValid)
        RxData_d[7:0] <=  LatchedByte[7:0] & {8{|StateData}};
      else
      if(~DelayData)
        RxData_d[7:0] <=  8'h0;
      RxData[7:0] <=  RxData_d[7:0];           
    end
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    Broadcast <=  1'b0;
  else
    begin      
      if(StateData[0] & ~(&LatchedByte[7:0]) & ByteCntSmall7)
        Broadcast <=  1'b0;
      else
      if(StateData[0] & (&LatchedByte[7:0]) & ByteCntEq1)
        Broadcast <=  1'b1;
      else
      if(RxAbort | RxEndFrm)
        Broadcast <=  1'b0;
    end
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    Multicast <=  1'b0;
  else
    begin      
      if(StateData[0] & ByteCntEq1 & LatchedByte[0])
        Multicast <=  1'b1;
      else if(RxAbort | RxEndFrm)
      Multicast <=  1'b0;
    end
end
assign GenerateRxValid = StateData[0] & (~ByteCntEq0 | DlyCrcCnt >= 4'h3);
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxValid_d <=  1'b0;
      RxValid   <=  1'b0;
    end
  else
    begin
      RxValid_d <=  GenerateRxValid;
      RxValid   <=  RxValid_d;
    end
end
assign GenerateRxStartFrm = StateData[0] &
                            ((ByteCntEq1 & ~DlyCrcEn) |
                            ((DlyCrcCnt == 4'h3) & DlyCrcEn));
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxStartFrm_d <=  1'b0;
      RxStartFrm   <=  1'b0;
    end
  else
    begin
      RxStartFrm_d <=  GenerateRxStartFrm;
      RxStartFrm   <=  RxStartFrm_d;
    end
end
assign GenerateRxEndFrm = StateData[0] &
                          (~MRxDV & ByteCntGreat2 | ByteCntMaxFrame);
assign DribbleRxEndFrm  = StateData[1] &  ~MRxDV & ByteCntGreat2;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxEndFrm_d <=  1'b0;
      RxEndFrm   <=  1'b0;
    end
  else
    begin
      RxEndFrm_d <=  GenerateRxEndFrm;
      RxEndFrm   <=  RxEndFrm_d | DribbleRxEndFrm;
    end
end
endmodule
 `timescale 1ns / 1ns
module eth_rxstatem (MRxClk, Reset, MRxDV, ByteCntEq0, ByteCntGreat2, Transmitting, MRxDEq5, MRxDEqD, 
                     IFGCounterEq24, ByteCntMaxFrame, StateData, StateIdle, StatePreamble, StateSFD, 
                     StateDrop
                    );
input         MRxClk;
input         Reset;
input         MRxDV;
input         ByteCntEq0;
input         ByteCntGreat2;
input         MRxDEq5;
input         Transmitting;
input         MRxDEqD;
input         IFGCounterEq24;
input         ByteCntMaxFrame;
output [1:0]  StateData;
output        StateIdle;
output        StateDrop;
output        StatePreamble;
output        StateSFD;
reg           StateData0;
reg           StateData1;
reg           StateIdle;
reg           StateDrop;
reg           StatePreamble;
reg           StateSFD;
wire          StartIdle;
wire          StartDrop;
wire          StartData0;
wire          StartData1;
wire          StartPreamble;
wire          StartSFD;
assign StartIdle = ~MRxDV & (StateDrop | StatePreamble | StateSFD | (|StateData));
assign StartPreamble = MRxDV & ~MRxDEq5 & (StateIdle & ~Transmitting);
assign StartSFD = MRxDV & MRxDEq5 & (StateIdle & ~Transmitting | StatePreamble);
assign StartData0 = MRxDV & (StateSFD & MRxDEqD & IFGCounterEq24 | StateData1);
assign StartData1 = MRxDV & StateData0 & (~ByteCntMaxFrame);
assign StartDrop = MRxDV & (StateIdle & Transmitting | StateSFD & ~IFGCounterEq24 &
                   MRxDEqD |  StateData0 &  ByteCntMaxFrame);
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      StateIdle     <=  1'b0;
      StateDrop     <=  1'b1;
      StatePreamble <=  1'b0;
      StateSFD      <=  1'b0;
      StateData0    <=  1'b0;
      StateData1    <=  1'b0;
    end
  else
    begin
      if(StartPreamble | StartSFD | StartDrop)
        StateIdle <=  1'b0;
      else
      if(StartIdle)
        StateIdle <=  1'b1;
      if(StartIdle)
        StateDrop <=  1'b0;
      else
      if(StartDrop)
        StateDrop <=  1'b1;
      if(StartSFD | StartIdle | StartDrop)
        StatePreamble <=  1'b0;
      else
      if(StartPreamble)
        StatePreamble <=  1'b1;
      if(StartPreamble | StartIdle | StartData0 | StartDrop)
        StateSFD <=  1'b0;
      else
      if(StartSFD)
        StateSFD <=  1'b1;
      if(StartIdle | StartData1 | StartDrop)
        StateData0 <=  1'b0;
      else
      if(StartData0)
        StateData0 <=  1'b1;
      if(StartIdle | StartData0 | StartDrop)
        StateData1 <=  1'b0;
      else
      if(StartData1)
        StateData1 <=  1'b1;
    end
end
assign StateData[1:0] = {StateData1, StateData0};
endmodule
 `timescale 1ns / 1ns
module eth_spram_256x32(
	clk, rst, ce, we, oe, addr, di, dato
);
   input           clk;   
   input           rst;   
   input           ce;    
   input  [3:0]    we;    
   input           oe;    
   input  [7:0]    addr;  
   input  [31:0]   di;    
   output [31:0]   dato;    
   reg  [ 7: 0] mem0 [255:0];  
   reg  [15: 8] mem1 [255:0];  
   reg  [23:16] mem2 [255:0];  
   reg  [31:24] mem3 [255:0];  
   wire [31:0]  q;             
   reg   [7:0]   raddr;         
   assign dato = (oe & ce) ? q : {32{1'bz}};
   always@(posedge clk)
     if (ce)
       raddr <=  addr;  
   assign  q = rst ? {32{1'b0}} : {mem3[raddr],
                                   mem2[raddr],
                                   mem1[raddr],
                                   mem0[raddr]};
    always@(posedge clk)
    begin
		if (ce && we[3])
		  mem3[addr] <=  di[31:24];
		if (ce && we[2])
		  mem2[addr] <=  di[23:16];
		if (ce && we[1])
		  mem1[addr] <=  di[15: 8];
		if (ce && we[0])
		  mem0[addr] <=  di[ 7: 0];
	     end
   task print_ram;
      input [7:0] start;
      input [7:0] finish;
      integer     rnum;
      begin
    	 for (rnum={24'd0,start};rnum<={24'd0,finish};rnum=rnum+1)
           $display("Addr %h = %0h %0h %0h %0h",rnum,mem3[rnum],mem2[rnum],mem1[rnum],mem0[rnum]);
      end
   endtask
endmodule
 `timescale 1ns / 1ns
module eth_shiftreg(Clk, Reset, MdcEn_n, Mdi, Fiad, Rgad, CtrlData, WriteOp, ByteSelect, 
                    LatchByte, ShiftedBit, Prsd, LinkFail);
input       Clk;               
input       Reset;             
input       MdcEn_n;           
input       Mdi;               
input [4:0] Fiad;              
input [4:0] Rgad;              
input [15:0]CtrlData;          
input       WriteOp;           
input [3:0] ByteSelect;        
input [1:0] LatchByte;         
output      ShiftedBit;        
output[15:0]Prsd;              
output      LinkFail;          
reg   [7:0] ShiftReg;          
reg   [15:0]Prsd;
reg         LinkFail;
always @ (posedge Clk or posedge Reset) 
begin
  if(Reset)
    begin
      ShiftReg[7:0] <=  8'h0;
      Prsd[15:0] <=  16'h0;
      LinkFail <=  1'b0;
    end
  else
    begin
      if(MdcEn_n)
        begin 
          if(|ByteSelect)
            begin
              case (ByteSelect[3:0])   
                4'h1 :    ShiftReg[7:0] <=  {2'b01, ~WriteOp, WriteOp, Fiad[4:1]};
                4'h2 :    ShiftReg[7:0] <=  {Fiad[0], Rgad[4:0], 2'b10};
                4'h4 :    ShiftReg[7:0] <=  CtrlData[15:8];
                4'h8 :    ShiftReg[7:0] <=  CtrlData[7:0];
              endcase  
            end 
          else
            begin
              ShiftReg[7:0] <=  {ShiftReg[6:0], Mdi};
              if(LatchByte[0])
                begin
                  Prsd[7:0] <=  {ShiftReg[6:0], Mdi};
                  if(Rgad == 5'h01)
                    LinkFail <=  ~ShiftReg[1];   
                end
              else
                begin
                  if(LatchByte[1])
                    Prsd[15:8] <=  {ShiftReg[6:0], Mdi};
                end
            end
        end
    end
end
assign ShiftedBit = ShiftReg[7];
endmodule
 `timescale 1ns / 1ns
module eth_transmitcontrol (MTxClk, TxReset, TxUsedDataIn, TxUsedDataOut, TxDoneIn, TxAbortIn, 
                            TxStartFrmIn, TPauseRq, TxUsedDataOutDetected, TxFlow, DlyCrcEn, 
                            TxPauseTV, MAC, TxCtrlStartFrm, TxCtrlEndFrm, SendingCtrlFrm, CtrlMux, 
                            ControlData, WillSendControlFrame, BlockTxDone
                           );
input         MTxClk;
input         TxReset;
input         TxUsedDataIn;
input         TxUsedDataOut;
input         TxDoneIn;
input         TxAbortIn;
input         TxStartFrmIn;
input         TPauseRq;
input         TxUsedDataOutDetected;
input         TxFlow;
input         DlyCrcEn;
input  [15:0] TxPauseTV;
input  [47:0] MAC;
output        TxCtrlStartFrm;
output        TxCtrlEndFrm;
output        SendingCtrlFrm;
output        CtrlMux;
output [7:0]  ControlData;
output        WillSendControlFrame;
output        BlockTxDone;
reg           SendingCtrlFrm;
reg           CtrlMux;
reg           WillSendControlFrame;
reg    [3:0]  DlyCrcCnt;
reg    [5:0]  ByteCnt;
reg           ControlEnd_q;
reg    [7:0]  MuxedCtrlData;
reg           TxCtrlStartFrm;
reg           TxCtrlStartFrm_q;
reg           TxCtrlEndFrm;
reg    [7:0]  ControlData;
reg           TxUsedDataIn_q;
reg           BlockTxDone;
wire          IncrementDlyCrcCnt;
wire          ResetByteCnt;
wire          IncrementByteCnt;
wire          ControlEnd;
wire          IncrementByteCntBy2;
wire          EnableCnt;
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    WillSendControlFrame <=  1'b0;
  else
  if(TxCtrlEndFrm & CtrlMux)
    WillSendControlFrame <=  1'b0;
  else
  if(TPauseRq & TxFlow)
    WillSendControlFrame <=  1'b1;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    TxCtrlStartFrm <=  1'b0;
  else
  if(TxUsedDataIn_q & CtrlMux)
    TxCtrlStartFrm <=  1'b0;
  else
  if(WillSendControlFrame & ~TxUsedDataOut & (TxDoneIn | TxAbortIn | TxStartFrmIn | (~TxUsedDataOutDetected)))
    TxCtrlStartFrm <=  1'b1;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    TxCtrlEndFrm <=  1'b0;
  else
  if(ControlEnd | ControlEnd_q)
    TxCtrlEndFrm <=  1'b1;
  else
    TxCtrlEndFrm <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    CtrlMux <=  1'b0;
  else
  if(WillSendControlFrame & ~TxUsedDataOut)
    CtrlMux <=  1'b1;
  else
  if(TxDoneIn)
    CtrlMux <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    SendingCtrlFrm <=  1'b0;
  else
  if(WillSendControlFrame & TxCtrlStartFrm)
    SendingCtrlFrm <=  1'b1;
  else
  if(TxDoneIn)
    SendingCtrlFrm <=  1'b0;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    TxUsedDataIn_q <=  1'b0;
  else
    TxUsedDataIn_q <=  TxUsedDataIn;
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    BlockTxDone <=  1'b0;
  else
  if(TxCtrlStartFrm)
    BlockTxDone <=  1'b1;
  else
  if(TxStartFrmIn)
    BlockTxDone <=  1'b0;
end
always @ (posedge MTxClk)
begin
  ControlEnd_q     <=  ControlEnd;
  TxCtrlStartFrm_q <=  TxCtrlStartFrm;
end
assign IncrementDlyCrcCnt = CtrlMux & TxUsedDataIn &  ~DlyCrcCnt[2];
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    DlyCrcCnt <=  4'h0;
  else
  if(ResetByteCnt)
    DlyCrcCnt <=  4'h0;
  else
  if(IncrementDlyCrcCnt)
    DlyCrcCnt <=  DlyCrcCnt + 4'd1;
end
assign ResetByteCnt = TxReset | (~TxCtrlStartFrm & (TxDoneIn | TxAbortIn));
assign IncrementByteCnt = CtrlMux & (TxCtrlStartFrm & ~TxCtrlStartFrm_q & ~TxUsedDataIn | TxUsedDataIn & ~ControlEnd);
assign IncrementByteCntBy2 = CtrlMux & TxCtrlStartFrm & (~TxCtrlStartFrm_q) & TxUsedDataIn;      
assign EnableCnt = (~DlyCrcEn | DlyCrcEn & (&DlyCrcCnt[1:0]));
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ByteCnt <=  6'h0;
  else
  if(ResetByteCnt)
    ByteCnt <=  6'h0;
  else
  if(IncrementByteCntBy2 & EnableCnt)
    ByteCnt <=  (ByteCnt[5:0] ) + 6'd2;
  else
  if(IncrementByteCnt & EnableCnt)
    ByteCnt <=  (ByteCnt[5:0] ) + 6'd1;
end
assign ControlEnd = ByteCnt[5:0] == 6'h22;
always @ (ByteCnt or DlyCrcEn or MAC or TxPauseTV or DlyCrcCnt)
begin
  case(ByteCnt)
    6'h0:    if(~DlyCrcEn | DlyCrcEn & (&DlyCrcCnt[1:0]))
               MuxedCtrlData[7:0] = 8'h01;                    
             else
						 	 MuxedCtrlData[7:0] = 8'h0;
    6'h2:      MuxedCtrlData[7:0] = 8'h80;
    6'h4:      MuxedCtrlData[7:0] = 8'hC2;
    6'h6:      MuxedCtrlData[7:0] = 8'h00;
    6'h8:      MuxedCtrlData[7:0] = 8'h00;
    6'hA:      MuxedCtrlData[7:0] = 8'h01;
    6'hC:      MuxedCtrlData[7:0] = MAC[47:40];
    6'hE:      MuxedCtrlData[7:0] = MAC[39:32];
    6'h10:     MuxedCtrlData[7:0] = MAC[31:24];
    6'h12:     MuxedCtrlData[7:0] = MAC[23:16];
    6'h14:     MuxedCtrlData[7:0] = MAC[15:8];
    6'h16:     MuxedCtrlData[7:0] = MAC[7:0];
    6'h18:     MuxedCtrlData[7:0] = 8'h88;                    
    6'h1A:     MuxedCtrlData[7:0] = 8'h08;
    6'h1C:     MuxedCtrlData[7:0] = 8'h00;                    
    6'h1E:     MuxedCtrlData[7:0] = 8'h01;
    6'h20:     MuxedCtrlData[7:0] = TxPauseTV[15:8];          
    6'h22:     MuxedCtrlData[7:0] = TxPauseTV[7:0];
    default:   MuxedCtrlData[7:0] = 8'h0;
  endcase
end
always @ (posedge MTxClk or posedge TxReset)
begin
  if(TxReset)
    ControlData[7:0] <=  8'h0;
  else
  if(~ByteCnt[0])
    ControlData[7:0] <=  MuxedCtrlData[7:0];
end
endmodule
 `timescale 1ns / 1ns
module eth_txcounters (StatePreamble, StateIPG, StateData, StatePAD, StateFCS, StateJam, 
                       StateBackOff, StateDefer, StateIdle, StartDefer, StartIPG, StartFCS, 
                       StartJam, StartBackoff, TxStartFrm, MTxClk, Reset, MinFL, MaxFL, HugEn, 
                       ExDfrEn, PacketFinished_q, DlyCrcEn, StateSFD, ByteCnt, NibCnt, 
                       ExcessiveDefer, NibCntEq7, NibCntEq15, MaxFrame, NibbleMinFl, DlyCrcCnt
                      );
input MTxClk;              
input Reset;               
input StatePreamble;       
input StateIPG;            
input [1:0] StateData;     
input StatePAD;            
input StateFCS;            
input StateJam;            
input StateBackOff;        
input StateDefer;          
input StateIdle;           
input StateSFD;            
input StartDefer;          
input StartIPG;            
input StartFCS;            
input StartJam;            
input StartBackoff;        
input TxStartFrm;          
input [15:0] MinFL;        
input [15:0] MaxFL;        
input HugEn;               
input ExDfrEn;             
input PacketFinished_q;             
input DlyCrcEn;            
output [15:0] ByteCnt;     
output [15:0] NibCnt;      
output ExcessiveDefer;     
output NibCntEq7;          
output NibCntEq15;         
output MaxFrame;           
output NibbleMinFl;        
output [2:0] DlyCrcCnt;    
wire ExcessiveDeferCnt;
wire ResetNibCnt;
wire IncrementNibCnt;
wire ResetByteCnt;
wire IncrementByteCnt;
wire ByteCntMax;
reg [15:0] NibCnt;
reg [15:0] ByteCnt;
reg  [2:0] DlyCrcCnt;
assign IncrementNibCnt = StateIPG | StatePreamble | (|StateData) | StatePAD 
                       | StateFCS | StateJam | StateBackOff | StateDefer & ~ExcessiveDefer & TxStartFrm;
assign ResetNibCnt = StateDefer & ExcessiveDefer & ~TxStartFrm | StatePreamble & NibCntEq15 
                   | StateJam & NibCntEq7 | StateIdle | StartDefer | StartIPG | StartFCS | StartJam;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    NibCnt <=  16'h0;
  else
    begin
      if(ResetNibCnt)
        NibCnt <=  16'h0;
      else
      if(IncrementNibCnt)
        NibCnt <=  NibCnt + 16'd1;
     end
end
assign NibCntEq7   = &NibCnt[2:0];
assign NibCntEq15  = &NibCnt[3:0];
assign NibbleMinFl = NibCnt >= (((MinFL-16'd4)<<1) -1);   
assign ExcessiveDeferCnt = NibCnt[13:0] == 14'h17b7;
assign ExcessiveDefer  = NibCnt[13:0] == 14'h17b7 & ~ExDfrEn;    
assign IncrementByteCnt = StateData[1] & ~ByteCntMax
                        | StateBackOff & (&NibCnt[6:0])
                        | (StatePAD | StateFCS) & NibCnt[0] & ~ByteCntMax;
assign ResetByteCnt = StartBackoff | StateIdle & TxStartFrm | PacketFinished_q;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ByteCnt[15:0] <=  16'h0;
  else
    begin
      if(ResetByteCnt)
        ByteCnt[15:0] <=  16'h0;
      else
      if(IncrementByteCnt)
        ByteCnt[15:0] <=  ByteCnt[15:0] + 16'd1;
    end
end
assign MaxFrame = ByteCnt[15:0] == MaxFL[15:0] & ~HugEn;
assign ByteCntMax = &ByteCnt[15:0];
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    DlyCrcCnt <=  3'h0;
  else
    begin        
      if(StateData[1] & DlyCrcCnt == 3'h4 | StartJam | PacketFinished_q)
        DlyCrcCnt <=  3'h0;
      else
      if(DlyCrcEn & (StateSFD | StateData[1] & (|DlyCrcCnt[2:0])))
        DlyCrcCnt <=  DlyCrcCnt + 3'd1;
    end
end
endmodule
 `timescale 1ns / 1ns
module eth_txethmac (MTxClk, Reset, TxStartFrm, TxEndFrm, TxUnderRun, TxData, CarrierSense, 
                     Collision, Pad, CrcEn, FullD, HugEn, DlyCrcEn, MinFL, MaxFL, IPGT, 
                     IPGR1, IPGR2, CollValid, MaxRet, NoBckof, ExDfrEn, 
                     MTxD, MTxEn, MTxErr, TxDone, TxRetry, TxAbort, TxUsedData, WillTransmit, 
                     ResetCollision, RetryCnt, StartTxDone, StartTxAbort, MaxCollisionOccured,
                     LateCollision, DeferIndication, StatePreamble, StateData
                    );
input MTxClk;                    
input Reset;                     
input TxStartFrm;                
input TxEndFrm;                  
input TxUnderRun;                
input [7:0] TxData;              
input CarrierSense;              
input Collision;                 
input Pad;                       
input CrcEn;                     
input FullD;                     
input HugEn;                     
input DlyCrcEn;                  
input [15:0] MinFL;              
input [15:0] MaxFL;              
input [6:0] IPGT;                
input [6:0] IPGR1;               
input [6:0] IPGR2;               
input [5:0] CollValid;           
input [3:0] MaxRet;              
input NoBckof;                   
input ExDfrEn;                   
output [3:0] MTxD;               
output MTxEn;                    
output MTxErr;                   
output TxDone;                   
output TxRetry;                  
output TxAbort;                  
output TxUsedData;               
output WillTransmit;             
output ResetCollision;           
output [3:0] RetryCnt;           
output StartTxDone;
output StartTxAbort;
output MaxCollisionOccured;
output LateCollision;
output DeferIndication;
output StatePreamble;
output [1:0] StateData;
reg [3:0] MTxD;
reg MTxEn;
reg MTxErr;
reg TxDone;
reg TxRetry;
reg TxAbort;
reg TxUsedData;
reg WillTransmit;
reg ColWindow;
reg StopExcessiveDeferOccured;
reg [3:0] RetryCnt;
reg [3:0] MTxD_d;
reg StatusLatch;
reg PacketFinished_q;
reg PacketFinished;
wire ExcessiveDeferOccured;
wire StartIPG;
wire StartPreamble;
wire [1:0] StartData;
wire StartFCS;
wire StartJam;
wire StartDefer;
wire StartBackoff;
wire StateDefer;
wire StateIPG;
wire StateIdle;
wire StatePAD;
wire StateFCS;
wire StateJam;
wire StateJam_q;
wire StateBackOff;
wire StateSFD;
wire StartTxRetry;
wire UnderRun;
wire TooBig;
wire [31:0] Crc;
wire CrcError;
wire [2:0] DlyCrcCnt;
wire [15:0] NibCnt;
wire NibCntEq7;
wire NibCntEq15;
wire NibbleMinFl;
wire ExcessiveDefer;
wire [15:0] ByteCnt;
wire MaxFrame;
wire RetryMax;
wire RandomEq0;
wire RandomEqByteCnt;
wire PacketFinished_d;
assign ResetCollision = ~(StatePreamble | (|StateData) | StatePAD | StateFCS);
assign ExcessiveDeferOccured = TxStartFrm & StateDefer & ExcessiveDefer & ~StopExcessiveDeferOccured;
assign StartTxDone = ~Collision & (StateFCS & NibCntEq7 | StateData[1] & TxEndFrm & (~Pad | Pad & NibbleMinFl) & ~CrcEn);
assign UnderRun = StateData[0] & TxUnderRun & ~Collision;
assign TooBig = ~Collision & MaxFrame & (StateData[0] & ~TxUnderRun | StateFCS);
assign StartTxRetry = StartJam & (ColWindow & ~RetryMax) & ~UnderRun;
assign LateCollision = StartJam & ~ColWindow & ~UnderRun;
assign MaxCollisionOccured = StartJam & ColWindow & RetryMax;
assign StateSFD = StatePreamble & NibCntEq15;
assign StartTxAbort = TooBig | UnderRun | ExcessiveDeferOccured | LateCollision | MaxCollisionOccured;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    StopExcessiveDeferOccured <=  1'b0;
  else
    begin
      if(~TxStartFrm)
        StopExcessiveDeferOccured <=  1'b0;
      else
      if(ExcessiveDeferOccured)
        StopExcessiveDeferOccured <=  1'b1;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ColWindow <=  1'b1;
  else
    begin  
      if(~Collision & ByteCnt[5:0] == CollValid[5:0] & (StateData[1] | StatePAD & NibCnt[0] | StateFCS & NibCnt[0]))
        ColWindow <=  1'b0;
      else
      if(StateIdle | StateIPG)
        ColWindow <=  1'b1;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    StatusLatch <=  1'b0;
  else
    begin
      if(~TxStartFrm)
        StatusLatch <=  1'b0;
      else
      if(ExcessiveDeferOccured | StateIdle)
        StatusLatch <=  1'b1;
     end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxUsedData <=  1'b0;
  else
    TxUsedData <=  |StartData;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxDone <=  1'b0;
  else
    begin
      if(TxStartFrm & ~StatusLatch)
        TxDone <=  1'b0;
      else
      if(StartTxDone)
        TxDone <=  1'b1;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxRetry <=  1'b0;
  else
    begin
      if(TxStartFrm & ~StatusLatch)
        TxRetry <=  1'b0;
      else
      if(StartTxRetry)
        TxRetry <=  1'b1;
     end
end                                    
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxAbort <=  1'b0;
  else
    begin
      if(TxStartFrm & ~StatusLatch & ~ExcessiveDeferOccured)
        TxAbort <=  1'b0;
      else
      if(StartTxAbort)
        TxAbort <=  1'b1;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    RetryCnt[3:0] <=  4'h0;
  else
    begin
      if(ExcessiveDeferOccured | UnderRun | TooBig | StartTxDone | TxUnderRun 
          | StateJam & NibCntEq7 & (~ColWindow | RetryMax))
        RetryCnt[3:0] <=  4'h0;
      else
      if(StateJam & NibCntEq7 & ColWindow & (RandomEq0 | NoBckof) | StateBackOff & RandomEqByteCnt)
        RetryCnt[3:0] <=  RetryCnt[3:0] + 1;
    end
end
assign RetryMax = RetryCnt[3:0] == MaxRet[3:0];
always @ (StatePreamble or StateData or StateData or StateFCS or StateJam or StateSFD or TxData or 
          Crc or NibCntEq15)
begin
  if(StateData[0])
    MTxD_d[3:0] = TxData[3:0];                                   
  else
  if(StateData[1])
    MTxD_d[3:0] = TxData[7:4];                                   
  else
  if(StateFCS)
    MTxD_d[3:0] = {~Crc[28], ~Crc[29], ~Crc[30], ~Crc[31]};      
  else
  if(StateJam)
    MTxD_d[3:0] = 4'h9;                                          
  else
  if(StatePreamble)
    if(NibCntEq15)
      MTxD_d[3:0] = 4'hd;                                        
    else
      MTxD_d[3:0] = 4'h5;                                        
  else
    MTxD_d[3:0] = 4'h0;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    MTxEn <=  1'b0;
  else
    MTxEn <=  StatePreamble | (|StateData) | StatePAD | StateFCS | StateJam;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    MTxD[3:0] <=  4'h0;
  else
    MTxD[3:0] <=  MTxD_d[3:0];
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    MTxErr <=  1'b0;
  else
    MTxErr <=  TooBig | UnderRun;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    WillTransmit <=   1'b0;
  else
    WillTransmit <=  StartPreamble | StatePreamble | (|StateData) | StatePAD | StateFCS | StateJam;
end
assign PacketFinished_d = StartTxDone | TooBig | UnderRun | LateCollision | MaxCollisionOccured | ExcessiveDeferOccured;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    begin
      PacketFinished <=  1'b0;
      PacketFinished_q  <=  1'b0;
    end
  else
    begin
      PacketFinished <=  PacketFinished_d;
      PacketFinished_q  <=  PacketFinished;
    end
end
eth_txcounters txcounters1 (.StatePreamble(StatePreamble), .StateIPG(StateIPG), .StateData(StateData), 
                            .StatePAD(StatePAD), .StateFCS(StateFCS), .StateJam(StateJam), .StateBackOff(StateBackOff), 
                            .StateDefer(StateDefer), .StateIdle(StateIdle), .StartDefer(StartDefer), .StartIPG(StartIPG), 
                            .StartFCS(StartFCS), .StartJam(StartJam), .TxStartFrm(TxStartFrm), .MTxClk(MTxClk), 
                            .Reset(Reset), .MinFL(MinFL), .MaxFL(MaxFL), .HugEn(HugEn), .ExDfrEn(ExDfrEn), 
                            .PacketFinished_q(PacketFinished_q), .DlyCrcEn(DlyCrcEn), .StartBackoff(StartBackoff), 
                            .StateSFD(StateSFD), .ByteCnt(ByteCnt), .NibCnt(NibCnt), .ExcessiveDefer(ExcessiveDefer), 
                            .NibCntEq7(NibCntEq7), .NibCntEq15(NibCntEq15), .MaxFrame(MaxFrame), .NibbleMinFl(NibbleMinFl), 
                            .DlyCrcCnt(DlyCrcCnt)
                           );
eth_txstatem txstatem1 (.MTxClk(MTxClk), .Reset(Reset), .ExcessiveDefer(ExcessiveDefer), .CarrierSense(CarrierSense), 
                        .NibCnt(NibCnt[6:0]), .IPGT(IPGT), .IPGR1(IPGR1), .IPGR2(IPGR2), .FullD(FullD), 
                        .TxStartFrm(TxStartFrm), .TxEndFrm(TxEndFrm), .TxUnderRun(TxUnderRun), .Collision(Collision), 
                        .UnderRun(UnderRun), .StartTxDone(StartTxDone), .TooBig(TooBig), .NibCntEq7(NibCntEq7), 
                        .NibCntEq15(NibCntEq15), .MaxFrame(MaxFrame), .Pad(Pad), .CrcEn(CrcEn), 
                        .NibbleMinFl(NibbleMinFl), .RandomEq0(RandomEq0), .ColWindow(ColWindow), .RetryMax(RetryMax), 
                        .NoBckof(NoBckof), .RandomEqByteCnt(RandomEqByteCnt), .StateIdle(StateIdle), 
                        .StateIPG(StateIPG), .StatePreamble(StatePreamble), .StateData(StateData), .StatePAD(StatePAD), 
                        .StateFCS(StateFCS), .StateJam(StateJam), .StateJam_q(StateJam_q), .StateBackOff(StateBackOff), 
                        .StateDefer(StateDefer), .StartFCS(StartFCS), .StartJam(StartJam), .StartBackoff(StartBackoff), 
                        .StartDefer(StartDefer), .DeferIndication(DeferIndication), .StartPreamble(StartPreamble), .StartData(StartData), .StartIPG(StartIPG)
                       );
wire Enable_Crc;
wire [3:0] Data_Crc;
wire Initialize_Crc;
assign Enable_Crc = ~StateFCS;
assign Data_Crc[0] = StateData[0]? TxData[3] : StateData[1]? TxData[7] : 1'b0;
assign Data_Crc[1] = StateData[0]? TxData[2] : StateData[1]? TxData[6] : 1'b0;
assign Data_Crc[2] = StateData[0]? TxData[1] : StateData[1]? TxData[5] : 1'b0;
assign Data_Crc[3] = StateData[0]? TxData[0] : StateData[1]? TxData[4] : 1'b0;
assign Initialize_Crc = StateIdle | StatePreamble | (|DlyCrcCnt);
eth_crc txcrc (.Clk(MTxClk), .Reset(Reset), .Data(Data_Crc), .Enable(Enable_Crc), .Initialize(Initialize_Crc), 
               .Crc(Crc), .CrcError(CrcError)
              );
eth_random random1 (.MTxClk(MTxClk), .Reset(Reset), .StateJam(StateJam), .StateJam_q(StateJam_q), .RetryCnt(RetryCnt), 
                    .NibCnt(NibCnt), .ByteCnt(ByteCnt[9:0]), .RandomEq0(RandomEq0), .RandomEqByteCnt(RandomEqByteCnt));
endmodule
 `timescale 1ns / 1ns
module eth_txstatem  (MTxClk, Reset, ExcessiveDefer, CarrierSense, NibCnt, IPGT, IPGR1, 
                      IPGR2, FullD, TxStartFrm, TxEndFrm, TxUnderRun, Collision, UnderRun, 
                      StartTxDone, TooBig, NibCntEq7, NibCntEq15, MaxFrame, Pad, CrcEn, 
                      NibbleMinFl, RandomEq0, ColWindow, RetryMax, NoBckof, RandomEqByteCnt,
                      StateIdle, StateIPG, StatePreamble, StateData, StatePAD, StateFCS, 
                      StateJam, StateJam_q, StateBackOff, StateDefer, StartFCS, StartJam, 
                      StartBackoff, StartDefer, DeferIndication, StartPreamble, StartData, StartIPG
                     );
input MTxClk;
input Reset;
input ExcessiveDefer;
input CarrierSense;
input [6:0] NibCnt;
input [6:0] IPGT;
input [6:0] IPGR1;
input [6:0] IPGR2;
input FullD;
input TxStartFrm;
input TxEndFrm;
input TxUnderRun;
input Collision;
input UnderRun;
input StartTxDone; 
input TooBig;
input NibCntEq7;
input NibCntEq15;
input MaxFrame;
input Pad;
input CrcEn;
input NibbleMinFl;
input RandomEq0;
input ColWindow;
input RetryMax;
input NoBckof;
input RandomEqByteCnt;
output StateIdle;          
output StateIPG;           
output StatePreamble;      
output [1:0] StateData;    
output StatePAD;           
output StateFCS;           
output StateJam;           
output StateJam_q;         
output StateBackOff;       
output StateDefer;         
output StartFCS;           
output StartJam;           
output StartBackoff;       
output StartDefer;         
output DeferIndication;
output StartPreamble;      
output [1:0] StartData;    
output StartIPG;           
wire StartIdle;            
wire StartPAD;             
reg StateIdle;
reg StateIPG;
reg StatePreamble;
reg [1:0] StateData;
reg StatePAD;
reg StateFCS;
reg StateJam;
reg StateJam_q;
reg StateBackOff;
reg StateDefer;
reg Rule1;
assign StartIPG = StateDefer & ~ExcessiveDefer & ~CarrierSense;
assign StartIdle = StateIPG & (Rule1 & NibCnt[6:0] >= IPGT | ~Rule1 & NibCnt[6:0] >= IPGR2);
assign StartPreamble = StateIdle & TxStartFrm & ~CarrierSense;
assign StartData[0] = ~Collision & (StatePreamble & NibCntEq15 | StateData[1] & ~TxEndFrm);
assign StartData[1] = ~Collision & StateData[0] & ~TxUnderRun & ~MaxFrame;
assign StartPAD = ~Collision & StateData[1] & TxEndFrm & Pad & ~NibbleMinFl;
assign StartFCS = ~Collision & StateData[1] & TxEndFrm & (~Pad | Pad & NibbleMinFl) & CrcEn
                | ~Collision & StatePAD & NibbleMinFl & CrcEn;
assign StartJam = (Collision | UnderRun) & ((StatePreamble & NibCntEq15) | (|StateData[1:0]) | StatePAD | StateFCS);
assign StartBackoff = StateJam & ~RandomEq0 & ColWindow & ~RetryMax & NibCntEq7 & ~NoBckof;
assign StartDefer = StateIPG & ~Rule1 & CarrierSense & NibCnt[6:0] <= IPGR1 & NibCnt[6:0] != IPGR2
                  | StateIdle & CarrierSense 
                  | StateJam & NibCntEq7 & (NoBckof | RandomEq0 | ~ColWindow | RetryMax)
                  | StateBackOff & (TxUnderRun | RandomEqByteCnt)
                  | StartTxDone | TooBig;
assign DeferIndication = StateIdle & CarrierSense;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    begin
      StateIPG        <=  1'b0;
      StateIdle       <=  1'b0;
      StatePreamble   <=  1'b0;
      StateData[1:0]  <=  2'b0;
      StatePAD        <=  1'b0;
      StateFCS        <=  1'b0;
      StateJam        <=  1'b0;
      StateJam_q      <=  1'b0;
      StateBackOff    <=  1'b0;
      StateDefer      <=  1'b1;
    end
  else
    begin
      StateData[1:0] <=  StartData[1:0];
      StateJam_q <=  StateJam;
      if(StartDefer | StartIdle)
        StateIPG <=  1'b0;
      else
      if(StartIPG)
        StateIPG <=  1'b1;
      if(StartDefer | StartPreamble)
        StateIdle <=  1'b0;
      else
      if(StartIdle)
        StateIdle <=  1'b1;
      if(StartData[0] | StartJam)
        StatePreamble <=  1'b0;
      else
      if(StartPreamble)
        StatePreamble <=  1'b1;
      if(StartFCS | StartJam)
        StatePAD <=  1'b0;
      else
      if(StartPAD)
        StatePAD <=  1'b1;
      if(StartJam | StartDefer)
        StateFCS <=  1'b0;
      else
      if(StartFCS)
        StateFCS <=  1'b1;
      if(StartBackoff | StartDefer)
        StateJam <=  1'b0;
      else
      if(StartJam)
        StateJam <=  1'b1;
      if(StartDefer)
        StateBackOff <=  1'b0;
      else
      if(StartBackoff)
        StateBackOff <=  1'b1;
      if(StartIPG)
        StateDefer <=  1'b0;
      else
      if(StartDefer)
        StateDefer <=  1'b1;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    Rule1 <=  1'b0;
  else
    begin
      if(StateIdle | StateBackOff)
        Rule1 <=  1'b0;
      else
      if(StatePreamble | FullD)
        Rule1 <=  1'b1;
    end
end
endmodule
 `timescale 1ns / 1ns
module eth_wishbone
  (
   WB_CLK_I, WB_DAT_I, WB_DAT_O, 
   WB_ADR_I, WB_WE_I, WB_ACK_O, 
   BDCs, 
   Reset, 
   m_wb_adr_o, m_wb_sel_o, m_wb_we_o, 
   m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o, 
   m_wb_stb_o, m_wb_ack_i, m_wb_err_i, 
   m_wb_cti_o, m_wb_bte_o, 
   MTxClk, TxStartFrm, TxEndFrm, TxUsedData, TxData, 
   TxRetry, TxAbort, TxUnderRun, TxDone, PerPacketCrcEn, 
   PerPacketPad, 
   MRxClk, RxData, RxValid, RxStartFrm, RxEndFrm, RxAbort,
   RxStatusWriteLatched_sync2, 
   r_TxEn, r_RxEn, r_TxBDNum, r_RxFlow, r_PassAll, 
   TxB_IRQ, TxE_IRQ, RxB_IRQ, RxE_IRQ, Busy_IRQ, 
   InvalidSymbol, LatchedCrcError, RxLateCollision, ShortFrame, DribbleNibble,
   ReceivedPacketTooBig, RxLength, LoadRxStatus, ReceivedPacketGood,
   AddressMiss, 
   ReceivedPauseFrm, 
   RetryCntLatched, RetryLimit, LateCollLatched, DeferLatched, RstDeferLatched,
   CarrierSenseLost
   );
parameter TX_FIFO_DATA_WIDTH = 32;
parameter TX_FIFO_DEPTH      = 16;
parameter TX_FIFO_CNT_WIDTH  = 5;
parameter RX_FIFO_DATA_WIDTH = 32;
parameter RX_FIFO_DEPTH      = 16;
parameter RX_FIFO_CNT_WIDTH  = 5;
input           WB_CLK_I;        
input  [31:0]   WB_DAT_I;        
output [31:0]   WB_DAT_O;        
input   [9:2]   WB_ADR_I;        
input           WB_WE_I;         
input   [3:0]   BDCs;            
output          WB_ACK_O;        
output  [29:0]  m_wb_adr_o;      
output   [3:0]  m_wb_sel_o;      
output          m_wb_we_o;       
output  [31:0]  m_wb_dat_o;      
output          m_wb_cyc_o;      
output          m_wb_stb_o;      
input   [31:0]  m_wb_dat_i;      
input           m_wb_ack_i;      
input           m_wb_err_i;      
output   [2:0]  m_wb_cti_o;      
output   [1:0]  m_wb_bte_o;      
reg      [2:0]  m_wb_cti_o;      
input           Reset;        
input           InvalidSymbol;     
input           LatchedCrcError;   
input           RxLateCollision;   
input           ShortFrame;        
input           DribbleNibble;     
input           ReceivedPacketTooBig; 
input    [15:0] RxLength;          
input           LoadRxStatus;      
input           ReceivedPacketGood;   
input           AddressMiss;       
input           r_RxFlow;
input           r_PassAll;
input           ReceivedPauseFrm;
input     [3:0] RetryCntLatched;   
input           RetryLimit;        
input           LateCollLatched;   
input           DeferLatched;      
output          RstDeferLatched;
input           CarrierSenseLost;  
input           MTxClk;          
input           TxUsedData;      
input           TxRetry;         
input           TxAbort;         
input           TxDone;          
output          TxStartFrm;      
output          TxEndFrm;        
output  [7:0]   TxData;          
output          TxUnderRun;      
output          PerPacketCrcEn;  
output          PerPacketPad;    
input           MRxClk;          
input   [7:0]   RxData;          
input           RxValid;         
input           RxStartFrm;      
input           RxEndFrm;        
input           RxAbort;         
output          RxStatusWriteLatched_sync2;
input           r_TxEn;          
input           r_RxEn;          
input   [7:0]   r_TxBDNum;       
output TxB_IRQ;
output TxE_IRQ;
output RxB_IRQ;
output RxE_IRQ;
output Busy_IRQ;
reg TxB_IRQ;
reg TxE_IRQ;
reg RxB_IRQ;
reg RxE_IRQ;
reg             TxStartFrm;
reg             TxEndFrm;
reg     [7:0]   TxData;
reg             TxUnderRun;
reg             TxUnderRun_wb;
reg             TxBDRead;
wire            TxStatusWrite;
reg     [1:0]   TxValidBytesLatched;
reg    [15:0]   TxLength;
reg    [15:0]   LatchedTxLength;
reg   [14:11]   TxStatus;
reg   [14:13]   RxStatus;
reg             TxStartFrm_wb;
reg             TxRetry_wb;
reg             TxAbort_wb;
reg             TxDone_wb;
reg             TxDone_wb_q;
reg             TxAbort_wb_q;
reg             TxRetry_wb_q;
reg             TxRetryPacket;
reg             TxRetryPacket_NotCleared;
reg             TxDonePacket;
reg             TxDonePacket_NotCleared;
reg             TxAbortPacket;
reg             TxAbortPacket_NotCleared;
reg             RxBDReady;
reg             RxReady;
reg             TxBDReady;
reg             RxBDRead;
reg    [31:0]   TxDataLatched;
reg     [1:0]   TxByteCnt;
reg             LastWord;
reg             ReadTxDataFromFifo_tck;
reg             BlockingTxStatusWrite;
reg             BlockingTxBDRead;
reg             Flop;
reg     [7:1]   TxBDAddress;
reg     [7:1]   RxBDAddress;
reg             TxRetrySync1;
reg             TxAbortSync1;
reg             TxDoneSync1;
reg             TxAbort_q;
reg             TxRetry_q;
reg             TxUsedData_q;
reg    [31:0]   RxDataLatched2;
reg    [31:8]   RxDataLatched1;      
reg     [1:0]   RxValidBytes;
reg     [1:0]   RxByteCnt;
reg             LastByteIn;
reg             ShiftWillEnd;
reg             WriteRxDataToFifo;
reg    [15:0]   LatchedRxLength;
reg             RxAbortLatched;
reg             ShiftEnded;
reg             RxOverrun;
reg     [3:0]   BDWrite;                     
reg             BDRead;                      
wire   [31:0]   RxBDDataIn;                  
wire   [31:0]   TxBDDataIn;                  
reg             TxEndFrm_wb;
wire            TxRetryPulse;
wire            TxDonePulse;
wire            TxAbortPulse;
wire            StartRxBDRead;
wire            StartTxBDRead;
wire            TxIRQEn;
wire            WrapTxStatusBit;
wire            RxIRQEn;
wire            WrapRxStatusBit;
wire    [1:0]   TxValidBytes;
wire    [7:1]   TempTxBDAddress;
wire    [7:1]   TempRxBDAddress;
wire            RxStatusWrite;
wire            RxBufferFull;
wire            RxBufferAlmostEmpty;
wire            RxBufferEmpty;
reg             WB_ACK_O;
wire    [8:0]   RxStatusIn;
reg     [8:0]   RxStatusInLatched;
reg WbEn, WbEn_q;
reg RxEn, RxEn_q;
reg TxEn, TxEn_q;
reg r_TxEn_q;
reg r_RxEn_q;
wire ram_ce;
wire [3:0]  ram_we;
wire ram_oe;
reg [7:0]   ram_addr;
reg [31:0]  ram_di;
wire [31:0] ram_do;
wire StartTxPointerRead;
reg TxPointerRead;
reg TxEn_needed;
reg RxEn_needed;
wire StartRxPointerRead;
reg RxPointerRead;
reg ShiftEnded_rck;
reg ShiftEndedSync1;
reg ShiftEndedSync2;
reg ShiftEndedSync3;
reg ShiftEndedSync_c1;
reg ShiftEndedSync_c2;
wire StartShiftWillEnd;
reg StartOccured;
reg TxStartFrm_sync1;
reg TxStartFrm_sync2;
reg TxStartFrm_syncb1;
reg TxStartFrm_syncb2;
wire TxFifoClear;
wire TxBufferAlmostFull;
wire TxBufferFull;
wire TxBufferEmpty;
wire TxBufferAlmostEmpty;
wire SetReadTxDataFromMemory;
reg BlockReadTxDataFromMemory;
reg tx_burst_en;
reg rx_burst_en;
reg  [3-1:0] tx_burst_cnt;
wire ReadTxDataFromMemory_2;
wire tx_burst;
wire [31:0] TxData_wb;
wire ReadTxDataFromFifo_wb;
wire [TX_FIFO_CNT_WIDTH-1:0] txfifo_cnt;
wire [RX_FIFO_CNT_WIDTH-1:0] rxfifo_cnt;
reg  [3-1:0] rx_burst_cnt;
wire rx_burst;
wire enough_data_in_rxfifo_for_burst;
wire enough_data_in_rxfifo_for_burst_plus1;
reg ReadTxDataFromMemory;
wire WriteRxDataToMemory;
reg MasterWbTX;
reg MasterWbRX;
reg [29:0] m_wb_adr_o;
reg        m_wb_cyc_o;
reg  [3:0] m_wb_sel_o;
reg        m_wb_we_o;
wire TxLengthEq0;
wire TxLengthLt4;
reg BlockingIncrementTxPointer;
reg [31:2] TxPointerMSB;
reg [1:0]  TxPointerLSB;
reg [1:0]  TxPointerLSB_rst;
reg [31:2] RxPointerMSB;
reg [1:0]  RxPointerLSB_rst;
wire RxBurstAcc;
wire RxWordAcc;
wire RxHalfAcc;
wire RxByteAcc;
wire ResetTxBDReady;
reg BlockingTxStatusWrite_sync1;
reg BlockingTxStatusWrite_sync2;
reg BlockingTxStatusWrite_sync3;
reg cyc_cleared;
reg IncrTxPointer;
reg  [3:0] RxByteSel;
wire MasterAccessFinished;
reg LatchValidBytes;
reg LatchValidBytes_q;
reg ReadTxDataFromFifo_sync1;
reg ReadTxDataFromFifo_sync2;
reg ReadTxDataFromFifo_sync3;
reg ReadTxDataFromFifo_syncb1;
reg ReadTxDataFromFifo_syncb2;
reg ReadTxDataFromFifo_syncb3;
reg RxAbortSync1;
reg RxAbortSync2;
reg RxAbortSync3;
reg RxAbortSync4;
reg RxAbortSyncb1;
reg RxAbortSyncb2;
reg RxEnableWindow;
wire SetWriteRxDataToFifo;
reg WriteRxDataToFifoSync1;
reg WriteRxDataToFifoSync2;
reg WriteRxDataToFifoSync3;
wire WriteRxDataToFifo_wb;
reg LatchedRxStartFrm;
reg SyncRxStartFrm;
reg SyncRxStartFrm_q;
reg SyncRxStartFrm_q2;
wire RxFifoReset;
wire TxError;
wire RxError;
reg RxStatusWriteLatched;
reg RxStatusWriteLatched_sync1;
reg RxStatusWriteLatched_sync2;
reg RxStatusWriteLatched_syncb1;
reg RxStatusWriteLatched_syncb2;
assign m_wb_bte_o = 2'b00;     
assign m_wb_stb_o = m_wb_cyc_o;
always @ (posedge WB_CLK_I)
begin
  WB_ACK_O <= (|BDWrite) & WbEn & WbEn_q | BDRead & WbEn & ~WbEn_q;
end
assign WB_DAT_O = ram_do;
eth_spram_256x32
     bd_ram
     (
      .clk     (WB_CLK_I),
      .rst     (Reset),
      .ce      (ram_ce),
      .we      (ram_we),
      .oe      (ram_oe),
      .addr    (ram_addr),
      .di      (ram_di),
      .dato    (ram_do)
      );
assign ram_ce = 1'b1;
assign ram_we = (BDWrite & {4{(WbEn & WbEn_q)}}) |
                {4{(TxStatusWrite | RxStatusWrite)}};
assign ram_oe = BDRead & WbEn & WbEn_q | TxEn & TxEn_q &
                (TxBDRead | TxPointerRead) | RxEn & RxEn_q &
                (RxBDRead | RxPointerRead);
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxEn_needed <= 1'b0;
  else
  if(~TxBDReady & r_TxEn & WbEn & ~WbEn_q)
    TxEn_needed <= 1'b1;
  else
  if(TxPointerRead & TxEn & TxEn_q)
    TxEn_needed <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      WbEn <= 1'b1;
      RxEn <= 1'b0;
      TxEn <= 1'b0;
      ram_addr <= 8'h0;
      ram_di <= 32'h0;
      BDRead <= 1'b0;
      BDWrite <= 0;
    end
  else
    begin
      case ({WbEn_q, RxEn_q, TxEn_q, RxEn_needed, TxEn_needed})   
        5'b100_10, 5'b100_11 :
          begin
            WbEn <= 1'b0;
            RxEn <= 1'b1;   
            TxEn <= 1'b0;
            ram_addr <= {RxBDAddress, RxPointerRead};
            ram_di <= RxBDDataIn;
          end
        5'b100_01 :
          begin
            WbEn <= 1'b0;
            RxEn <= 1'b0;
            TxEn <= 1'b1;   
            ram_addr <= {TxBDAddress, TxPointerRead};
            ram_di <= TxBDDataIn;
          end
        5'b010_00, 5'b010_10 :
          begin
            WbEn <= 1'b1;   
            RxEn <= 1'b0;
            TxEn <= 1'b0;
            ram_addr <= WB_ADR_I[9:2];
            ram_di <= WB_DAT_I;
            BDWrite <= BDCs[3:0] & {4{WB_WE_I}};
            BDRead <= (|BDCs) & ~WB_WE_I;
          end
        5'b010_01, 5'b010_11 :
          begin
            WbEn <= 1'b0;
            RxEn <= 1'b0;
            TxEn <= 1'b1;   
            ram_addr <= {TxBDAddress, TxPointerRead};
            ram_di <= TxBDDataIn;
          end
        5'b001_00, 5'b001_01, 5'b001_10, 5'b001_11 :
          begin
            WbEn <= 1'b1;   
            RxEn <= 1'b0;
            TxEn <= 1'b0;
            ram_addr <= WB_ADR_I[9:2];
            ram_di <= WB_DAT_I;
            BDWrite <= BDCs[3:0] & {4{WB_WE_I}};
            BDRead <= (|BDCs) & ~WB_WE_I;
          end
        5'b100_00 :
          begin
            WbEn <= 1'b0;   
          end
        5'b000_00 :
          begin
            WbEn <= 1'b1;   
            RxEn <= 1'b0;
            TxEn <= 1'b0;
            ram_addr <= WB_ADR_I[9:2];
            ram_di <= WB_DAT_I;
            BDWrite <= BDCs[3:0] & {4{WB_WE_I}};
            BDRead <= (|BDCs) & ~WB_WE_I;
          end
      endcase
    end
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      WbEn_q <= 1'b0;
      RxEn_q <= 1'b0;
      TxEn_q <= 1'b0;
      r_TxEn_q <= 1'b0;
      r_RxEn_q <= 1'b0;
    end
  else
    begin
      WbEn_q <= WbEn;
      RxEn_q <= RxEn;
      TxEn_q <= TxEn;
      r_TxEn_q <= r_TxEn;
      r_RxEn_q <= r_RxEn;
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    Flop <= 1'b0;
  else
  if(TxDone | TxAbort | TxRetry_q)
    Flop <= 1'b0;
  else
  if(TxUsedData)
    Flop <= ~Flop;
end
assign ResetTxBDReady = TxDonePulse | TxAbortPulse | TxRetryPulse;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxBDReady <= 1'b0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxBDReady <= ram_do[15] & (ram_do[31:16] > 4);
  else
  if(ResetTxBDReady)
    TxBDReady <= 1'b0;
end
assign StartTxBDRead = (TxRetryPacket_NotCleared | TxStatusWrite) &
                       ~BlockingTxBDRead & ~TxBDReady;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxBDRead <= 1'b1;
  else
  if(StartTxBDRead)
    TxBDRead <= 1'b1;
  else
  if(TxBDReady)
    TxBDRead <= 1'b0;
end
assign StartTxPointerRead = TxBDRead & TxBDReady;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxPointerRead <= 1'b0;
  else
  if(StartTxPointerRead)
    TxPointerRead <= 1'b1;
  else
  if(TxEn_q)
    TxPointerRead <= 1'b0;
end
assign TxStatusWrite = (TxDonePacket_NotCleared | TxAbortPacket_NotCleared) &
                       TxEn & TxEn_q & ~BlockingTxStatusWrite;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingTxStatusWrite <= 1'b0;
  else
  if(~TxDone_wb & ~TxAbort_wb)
    BlockingTxStatusWrite <= 1'b0;
  else
  if(TxStatusWrite)
    BlockingTxStatusWrite <= 1'b1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    BlockingTxStatusWrite_sync1 <= 1'b0;
  else
    BlockingTxStatusWrite_sync1 <= BlockingTxStatusWrite;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    BlockingTxStatusWrite_sync2 <= 1'b0;
  else
    BlockingTxStatusWrite_sync2 <= BlockingTxStatusWrite_sync1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    BlockingTxStatusWrite_sync3 <= 1'b0;
  else
    BlockingTxStatusWrite_sync3 <= BlockingTxStatusWrite_sync2;
end
assign RstDeferLatched = BlockingTxStatusWrite_sync2 &
                         ~BlockingTxStatusWrite_sync3;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingTxBDRead <= 1'b0;
  else
  if(StartTxBDRead)
    BlockingTxBDRead <= 1'b1;
  else
  if(~StartTxBDRead & ~TxBDReady)
    BlockingTxBDRead <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStatus <= 4'h0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxStatus <= ram_do[14:11];
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxLength <= 16'h0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    TxLength <= ram_do[31:16];
  else
  if(MasterWbTX & m_wb_ack_i)
    begin
      if(TxLengthLt4)
        TxLength <= 16'h0;
      else if(TxPointerLSB_rst==2'h0)
        TxLength <= TxLength - 16'd4;     
      else if(TxPointerLSB_rst==2'h1)
        TxLength <= TxLength - 16'd3;     
      else if(TxPointerLSB_rst==2'h2)
        TxLength <= TxLength - 16'd2;     
      else if(TxPointerLSB_rst==2'h3)
        TxLength <= TxLength - 16'd1;     
    end
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    LatchedTxLength <= 16'h0;
  else
  if(TxEn & TxEn_q & TxBDRead)
    LatchedTxLength <= ram_do[31:16];
end
assign TxLengthEq0 = TxLength == 0;
assign TxLengthLt4 = TxLength < 4;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxPointerMSB <= 30'h0;
  else
  if(TxEn & TxEn_q & TxPointerRead)
    TxPointerMSB <= ram_do[31:2];
  else
  if(IncrTxPointer & ~BlockingIncrementTxPointer)
    TxPointerMSB <= TxPointerMSB + 1'b1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxPointerLSB[1:0] <= 0;
  else
  if(TxEn & TxEn_q & TxPointerRead)
    TxPointerLSB[1:0] <= ram_do[1:0];
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxPointerLSB_rst[1:0] <= 0;
  else
  if(TxEn & TxEn_q & TxPointerRead)
    TxPointerLSB_rst[1:0] <= ram_do[1:0];
  else
  if(MasterWbTX & m_wb_ack_i)
    TxPointerLSB_rst[1:0] <= 0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockingIncrementTxPointer <= 0;
  else
  if(MasterAccessFinished)
    BlockingIncrementTxPointer <= 0;
  else
  if(IncrTxPointer)
    BlockingIncrementTxPointer <= 1'b1;
end
assign SetReadTxDataFromMemory = TxEn & TxEn_q & TxPointerRead;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromMemory <= 1'b0;
  else
  if(TxLengthEq0 | TxAbortPulse | TxRetryPulse)
    ReadTxDataFromMemory <= 1'b0;
  else
  if(SetReadTxDataFromMemory)
    ReadTxDataFromMemory <= 1'b1;
end
assign ReadTxDataFromMemory_2 = ReadTxDataFromMemory &
                                ~BlockReadTxDataFromMemory;
assign tx_burst = ReadTxDataFromMemory_2 & tx_burst_en;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    BlockReadTxDataFromMemory <= 1'b0;
  else
  if((TxBufferAlmostFull | TxLength <= 4) & MasterWbTX & (~cyc_cleared) &
     (!(TxAbortPacket_NotCleared | TxRetryPacket_NotCleared)))
    BlockReadTxDataFromMemory <= 1'b1;
  else
  if(ReadTxDataFromFifo_wb | TxDonePacket | TxAbortPacket | TxRetryPacket)
    BlockReadTxDataFromMemory <= 1'b0;
end
assign MasterAccessFinished = m_wb_ack_i | m_wb_err_i;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      MasterWbTX <= 1'b0;
      MasterWbRX <= 1'b0;
      m_wb_adr_o <= 30'h0;
      m_wb_cyc_o <= 1'b0;
      m_wb_we_o  <= 1'b0;
      m_wb_sel_o <= 4'h0;
      cyc_cleared<= 1'b0;
      tx_burst_cnt<= 0;
      rx_burst_cnt<= 0;
      IncrTxPointer<= 1'b0;
      tx_burst_en<= 1'b1;
      rx_burst_en<= 1'b0;
      m_wb_cti_o <= 3'b0;
    end
  else
    begin
      casez ({MasterWbTX,
             MasterWbRX,
             ReadTxDataFromMemory_2,
             WriteRxDataToMemory,
             MasterAccessFinished,
             cyc_cleared,
             tx_burst,
             rx_burst})   
        8'b00_10_00_10,  
        8'b10_1?_10_1?,  
        8'b10_10_01_10,  
        8'b01_1?_01_1?:  
          begin
            MasterWbTX <= 1'b1;   
            MasterWbRX <= 1'b0;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b0;
            m_wb_sel_o <= 4'hf;
            cyc_cleared<= 1'b0;
            IncrTxPointer<= 1'b1;
            tx_burst_cnt <= tx_burst_cnt+3'h1;
            if(tx_burst_cnt==0)
              m_wb_adr_o <= TxPointerMSB;
            else
              m_wb_adr_o <= m_wb_adr_o + 1'b1;
            if(tx_burst_cnt==(4-1))
              begin
                tx_burst_en<= 1'b0;
                m_wb_cti_o <= 3'b111;
              end
            else
              begin
                m_wb_cti_o <= 3'b010;
              end
          end
        8'b00_?1_00_?1,              
        8'b01_?1_10_?1,              
        8'b01_01_01_01,              
        8'b10_?1_01_?1 :             
          begin
            MasterWbTX <= 1'b0;   
            MasterWbRX <= 1'b1;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b1;
            m_wb_sel_o <= RxByteSel;
            IncrTxPointer<= 1'b0;
            cyc_cleared<= 1'b0;
            rx_burst_cnt <= rx_burst_cnt+3'h1;
            if(rx_burst_cnt==0)
              m_wb_adr_o <= RxPointerMSB;
            else
              m_wb_adr_o <= m_wb_adr_o+1'b1;
            if(rx_burst_cnt==(4-1))
              begin
                rx_burst_en<= 1'b0;
                m_wb_cti_o <= 3'b111;
              end
            else
              begin
                m_wb_cti_o <= 3'b010;
              end
          end
        8'b00_?1_00_?0 : 
          begin
            MasterWbTX <= 1'b0;
            MasterWbRX <= 1'b1;
            m_wb_adr_o <= RxPointerMSB;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b1;
            m_wb_sel_o <= RxByteSel;
            IncrTxPointer<= 1'b0;
          end
        8'b00_10_00_00 :  
          begin
            MasterWbTX <= 1'b1;
            MasterWbRX <= 1'b0;
            m_wb_adr_o <= TxPointerMSB;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b0;
            m_wb_sel_o <= 4'hf;
            IncrTxPointer<= 1'b1;
          end
        8'b10_10_01_00, 
        8'b01_1?_01_0?  : 
          begin
            MasterWbTX <= 1'b1;
            MasterWbRX <= 1'b0;
            m_wb_adr_o <= TxPointerMSB;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b0;
            m_wb_sel_o <= 4'hf;
            cyc_cleared<= 1'b0;
            IncrTxPointer<= 1'b1;
          end
        8'b01_01_01_00, 
        8'b10_?1_01_?0 : 
          begin
            MasterWbTX <= 1'b0;
            MasterWbRX <= 1'b1;
            m_wb_adr_o <= RxPointerMSB;
            m_wb_cyc_o <= 1'b1;
            m_wb_we_o  <= 1'b1;
            m_wb_sel_o <= RxByteSel;
            cyc_cleared<= 1'b0;
            IncrTxPointer<= 1'b0;
          end
        8'b01_01_10_00, 
        8'b01_1?_10_?0, 
        8'b10_10_10_00, 
        8'b10_?1_10_0? : 
          begin
            m_wb_cyc_o <= 1'b0; 
            cyc_cleared<= 1'b1;
            IncrTxPointer<= 1'b0;
            tx_burst_cnt<= 0;
            tx_burst_en<= txfifo_cnt<(TX_FIFO_DEPTH-4) & (TxLength>(4*4+4));
            rx_burst_cnt<= 0;
            rx_burst_en<= MasterWbRX ? enough_data_in_rxfifo_for_burst_plus1 : enough_data_in_rxfifo_for_burst;   
              m_wb_cti_o <= 3'b0;
          end
        8'b??_00_10_00, 
        8'b??_00_01_00 :  
          begin
            MasterWbTX <= 1'b0;
            MasterWbRX <= 1'b0;
            m_wb_cyc_o <= 1'b0;
            cyc_cleared<= 1'b0;
            IncrTxPointer<= 1'b0;
            rx_burst_cnt<= 0;
            rx_burst_en<= MasterWbRX ? enough_data_in_rxfifo_for_burst_plus1 :
                                       enough_data_in_rxfifo_for_burst;
            m_wb_cti_o <= 3'b0;
          end
        8'b00_00_00_00:   
          begin
            tx_burst_cnt<= 0;
            tx_burst_en<= txfifo_cnt<(TX_FIFO_DEPTH-4) & (TxLength>(4*4+4));
          end
        default:                     
          begin
            MasterWbTX <= MasterWbTX;
            MasterWbRX <= MasterWbRX;
            m_wb_cyc_o <= m_wb_cyc_o;
            m_wb_sel_o <= m_wb_sel_o;
            IncrTxPointer<= IncrTxPointer;
          end
      endcase
    end
end
assign TxFifoClear = (TxAbortPacket | TxRetryPacket);
eth_fifo
     #(
       .DATA_WIDTH(TX_FIFO_DATA_WIDTH),
       .DEPTH(TX_FIFO_DEPTH),
       .CNT_WIDTH(TX_FIFO_CNT_WIDTH))
tx_fifo (
       .data_in(m_wb_dat_i),
       .data_out(TxData_wb),
       .clk(WB_CLK_I),
       .reset(Reset),
       .write(MasterWbTX & m_wb_ack_i),
       .read(ReadTxDataFromFifo_wb & ~TxBufferEmpty),
       .clear(TxFifoClear),
       .full(TxBufferFull), 
       .almost_full(TxBufferAlmostFull),
       .almost_empty(TxBufferAlmostEmpty),
       .empty(TxBufferEmpty),
       .cnt(txfifo_cnt)
       );
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_wb <= 1'b0;
  else
  if(TxBDReady & ~StartOccured & (TxBufferFull | TxLengthEq0))
    TxStartFrm_wb <= 1'b1;
  else
  if(TxStartFrm_syncb2)
    TxStartFrm_wb <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    StartOccured <= 1'b0;
  else
  if(TxStartFrm_wb)
    StartOccured <= 1'b1;
  else
  if(ResetTxBDReady)
    StartOccured <= 1'b0;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxStartFrm_sync1 <= 1'b0;
  else
    TxStartFrm_sync1 <= TxStartFrm_wb;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxStartFrm_sync2 <= 1'b0;
  else
    TxStartFrm_sync2 <= TxStartFrm_sync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_syncb1 <= 1'b0;
  else
    TxStartFrm_syncb1 <= TxStartFrm_sync2;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxStartFrm_syncb2 <= 1'b0;
  else
    TxStartFrm_syncb2 <= TxStartFrm_syncb1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxStartFrm <= 1'b0;
  else
  if(TxStartFrm_sync2)
    TxStartFrm <= 1'b1;
  else
  if(TxUsedData_q | ~TxStartFrm_sync2 &
     (TxRetry & (~TxRetry_q) | TxAbort & (~TxAbort_q)))
    TxStartFrm <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxEndFrm_wb <= 1'b0;
  else
  if(TxLengthEq0 & TxBufferAlmostEmpty & TxUsedData)
    TxEndFrm_wb <= 1'b1;
  else
  if(TxRetryPulse | TxDonePulse | TxAbortPulse)
    TxEndFrm_wb <= 1'b0;
end
assign TxValidBytes = TxLengthLt4 ? TxLength[1:0] : 2'b0;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    LatchValidBytes <= 1'b0;
  else
  if(TxLengthLt4 & TxBDReady)
    LatchValidBytes <= 1'b1;
  else
    LatchValidBytes <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    LatchValidBytes_q <= 1'b0;
  else
    LatchValidBytes_q <= LatchValidBytes;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxValidBytesLatched <= 2'h0;
  else
  if(LatchValidBytes & ~LatchValidBytes_q)
    TxValidBytesLatched <= TxValidBytes;
  else
  if(TxRetryPulse | TxDonePulse | TxAbortPulse)
    TxValidBytesLatched <= 2'h0;
end
assign TxIRQEn          = TxStatus[14];
assign WrapTxStatusBit  = TxStatus[13];
assign PerPacketPad     = TxStatus[12];
assign PerPacketCrcEn   = TxStatus[11];
assign RxIRQEn         = RxStatus[14];
assign WrapRxStatusBit = RxStatus[13];
assign TempTxBDAddress[7:1] = {7{ TxStatusWrite  & ~WrapTxStatusBit}} &
                              (TxBDAddress + 1'b1);  
assign TempRxBDAddress[7:1] = 
  {7{ WrapRxStatusBit}} & (r_TxBDNum[6:0]) |  
  {7{~WrapRxStatusBit}} & (RxBDAddress + 1'b1);  
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxBDAddress <= 7'h0;
  else if (r_TxEn & (~r_TxEn_q))
    TxBDAddress <= 7'h0;
  else if (TxStatusWrite)
    TxBDAddress <= TempTxBDAddress;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDAddress <= 7'h0;
  else if(r_RxEn & (~r_RxEn_q))
    RxBDAddress <= r_TxBDNum[6:0];
  else if(RxStatusWrite)
    RxBDAddress <= TempRxBDAddress;
end
wire [8:0] TxStatusInLatched = {TxUnderRun, RetryCntLatched[3:0],
                                RetryLimit, LateCollLatched, DeferLatched,
                                CarrierSenseLost};
assign RxBDDataIn = {LatchedRxLength, 1'b0, RxStatus, 4'h0, RxStatusInLatched};
assign TxBDDataIn = {LatchedTxLength, 1'b0, TxStatus, 2'h0, TxStatusInLatched};
assign TxRetryPulse   = TxRetry_wb   & ~TxRetry_wb_q;
assign TxDonePulse    = TxDone_wb    & ~TxDone_wb_q;
assign TxAbortPulse   = TxAbort_wb   & ~TxAbort_wb_q;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    begin
      TxAbort_q      <= 1'b0;
      TxRetry_q      <= 1'b0;
      TxUsedData_q   <= 1'b0;
    end
  else
    begin
      TxAbort_q      <= TxAbort;
      TxRetry_q      <= TxRetry;
      TxUsedData_q   <= TxUsedData;
    end
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      TxDone_wb_q   <= 1'b0;
      TxAbort_wb_q  <= 1'b0;
      TxRetry_wb_q  <= 1'b0;
    end
  else
    begin
      TxDone_wb_q   <= TxDone_wb;
      TxAbort_wb_q  <= TxAbort_wb;
      TxRetry_wb_q  <= TxRetry_wb;
    end
end
reg TxAbortPacketBlocked;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbortPacket <= 1'b0;
  else
  if(TxAbort_wb & (~tx_burst_en) & MasterWbTX & MasterAccessFinished &
    (~TxAbortPacketBlocked) | TxAbort_wb & (~MasterWbTX) &
    (~TxAbortPacketBlocked))
    TxAbortPacket <= 1'b1;
  else
    TxAbortPacket <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbortPacket_NotCleared <= 1'b0;
  else
  if(TxEn & TxEn_q & TxAbortPacket_NotCleared)
    TxAbortPacket_NotCleared <= 1'b0;
  else
  if(TxAbort_wb & (~tx_burst_en) & MasterWbTX & MasterAccessFinished &
     (~TxAbortPacketBlocked) | TxAbort_wb & (~MasterWbTX) &
     (~TxAbortPacketBlocked))
    TxAbortPacket_NotCleared <= 1'b1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbortPacketBlocked <= 1'b0;
  else
  if(!TxAbort_wb & TxAbort_wb_q)
    TxAbortPacketBlocked <= 1'b0;
  else
  if(TxAbortPacket)
    TxAbortPacketBlocked <= 1'b1;
end
reg TxRetryPacketBlocked;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetryPacket <= 1'b0;
  else
  if(TxRetry_wb & !tx_burst_en & MasterWbTX & MasterAccessFinished &
     !TxRetryPacketBlocked | TxRetry_wb & !MasterWbTX & !TxRetryPacketBlocked)
    TxRetryPacket <= 1'b1;
  else
    TxRetryPacket <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetryPacket_NotCleared <= 1'b0;
  else
  if(StartTxBDRead)
    TxRetryPacket_NotCleared <= 1'b0;
  else
  if(TxRetry_wb & !tx_burst_en & MasterWbTX & MasterAccessFinished &
     !TxRetryPacketBlocked | TxRetry_wb & !MasterWbTX & !TxRetryPacketBlocked)
    TxRetryPacket_NotCleared <= 1'b1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetryPacketBlocked <= 1'b0;
  else
  if(!TxRetry_wb & TxRetry_wb_q)
    TxRetryPacketBlocked <= 1'b0;
  else
  if(TxRetryPacket)
    TxRetryPacketBlocked <= 1'b1;
end
reg TxDonePacketBlocked;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDonePacket <= 1'b0;
  else
  if(TxDone_wb & !tx_burst_en & MasterWbTX & MasterAccessFinished &
     !TxDonePacketBlocked | TxDone_wb & !MasterWbTX & !TxDonePacketBlocked)
    TxDonePacket <= 1'b1;
  else
    TxDonePacket <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDonePacket_NotCleared <= 1'b0;
  else
  if(TxEn & TxEn_q & TxDonePacket_NotCleared)
    TxDonePacket_NotCleared <= 1'b0;
  else
  if(TxDone_wb & !tx_burst_en & MasterWbTX & MasterAccessFinished &
     (~TxDonePacketBlocked) | TxDone_wb & !MasterWbTX & (~TxDonePacketBlocked))
    TxDonePacket_NotCleared <= 1'b1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDonePacketBlocked <= 1'b0;
  else
  if(!TxDone_wb & TxDone_wb_q)
    TxDonePacketBlocked <= 1'b0;
  else
  if(TxDonePacket)
    TxDonePacketBlocked <= 1'b1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    LastWord <= 1'b0;
  else
  if((TxEndFrm | TxAbort | TxRetry) & Flop)
    LastWord <= 1'b0;
  else
  if(TxUsedData & Flop & TxByteCnt == 2'h3)
    LastWord <= TxEndFrm_wb;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxEndFrm <= 1'b0;
  else
  if(Flop & TxEndFrm | TxAbort | TxRetry_q)
    TxEndFrm <= 1'b0;        
  else
  if(Flop & LastWord)
    begin
      case (TxValidBytesLatched)   
        1 : TxEndFrm <= TxByteCnt == 2'h0;
        2 : TxEndFrm <= TxByteCnt == 2'h1;
        3 : TxEndFrm <= TxByteCnt == 2'h2;
        0 : TxEndFrm <= TxByteCnt == 2'h3;
        default : TxEndFrm <= 1'b0;
      endcase
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxData <= 0;
  else
  if(TxStartFrm_sync2 & ~TxStartFrm)
    case(TxPointerLSB)   
      2'h0 : TxData <= TxData_wb[31:24]; 
      2'h1 : TxData <= TxData_wb[23:16]; 
      2'h2 : TxData <= TxData_wb[15:08]; 
      2'h3 : TxData <= TxData_wb[07:00]; 
    endcase
  else
  if(TxStartFrm & TxUsedData & TxPointerLSB==2'h3)
    TxData <= TxData_wb[31:24]; 
  else
  if(TxUsedData & Flop)
    begin
      case(TxByteCnt)   
        0 : TxData <= TxDataLatched[31:24]; 
        1 : TxData <= TxDataLatched[23:16];
        2 : TxData <= TxDataLatched[15:8];
        3 : TxData <= TxDataLatched[7:0];
      endcase
    end
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxDataLatched[31:0] <= 32'h0;
  else
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3 |
     TxStartFrm & TxUsedData & Flop & TxByteCnt == 2'h0)
    TxDataLatched[31:0] <= TxData_wb[31:0];
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxUnderRun_wb <= 1'b0;
  else
  if(TxAbortPulse)
    TxUnderRun_wb <= 1'b0;
  else
  if(TxBufferEmpty & ReadTxDataFromFifo_wb)
    TxUnderRun_wb <= 1'b1;
end
reg TxUnderRun_sync1;
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxUnderRun_sync1 <= 1'b0;
  else
  if(TxUnderRun_wb)
    TxUnderRun_sync1 <= 1'b1;
  else
  if(BlockingTxStatusWrite_sync2)
    TxUnderRun_sync1 <= 1'b0;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxUnderRun <= 1'b0;
  else
  if(BlockingTxStatusWrite_sync2)
    TxUnderRun <= 1'b0;
  else
  if(TxUnderRun_sync1)
    TxUnderRun <= 1'b1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    TxByteCnt <= 2'h0;
  else
  if(TxAbort_q | TxRetry_q)
    TxByteCnt <= 2'h0;
  else
  if(TxStartFrm & ~TxUsedData)
    case(TxPointerLSB)   
      2'h0 : TxByteCnt <= 2'h1;
      2'h1 : TxByteCnt <= 2'h2;
      2'h2 : TxByteCnt <= 2'h3;
      2'h3 : TxByteCnt <= 2'h0;
    endcase
  else
  if(TxUsedData & Flop)
    TxByteCnt <= TxByteCnt + 1'b1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_tck <= 1'b0;
  else
  if(TxStartFrm_sync2 & ~TxStartFrm | TxUsedData & Flop & TxByteCnt == 2'h3 &
     ~LastWord | TxStartFrm & TxUsedData & Flop & TxByteCnt == 2'h0)
     ReadTxDataFromFifo_tck <= 1'b1;
  else
  if(ReadTxDataFromFifo_syncb2 & ~ReadTxDataFromFifo_syncb3)
    ReadTxDataFromFifo_tck <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync1 <= 1'b0;
  else
    ReadTxDataFromFifo_sync1 <= ReadTxDataFromFifo_tck;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync2 <= 1'b0;
  else
    ReadTxDataFromFifo_sync2 <= ReadTxDataFromFifo_sync1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_syncb1 <= 1'b0;
  else
    ReadTxDataFromFifo_syncb1 <= ReadTxDataFromFifo_sync2;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_syncb2 <= 1'b0;
  else
    ReadTxDataFromFifo_syncb2 <= ReadTxDataFromFifo_syncb1;
end
always @ (posedge MTxClk or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_syncb3 <= 1'b0;
  else
    ReadTxDataFromFifo_syncb3 <= ReadTxDataFromFifo_syncb2;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ReadTxDataFromFifo_sync3 <= 1'b0;
  else
    ReadTxDataFromFifo_sync3 <= ReadTxDataFromFifo_sync2;
end
assign ReadTxDataFromFifo_wb = ReadTxDataFromFifo_sync2 &
                               ~ReadTxDataFromFifo_sync3;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetrySync1 <= 1'b0;
  else
    TxRetrySync1 <= TxRetry;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxRetry_wb <= 1'b0;
  else
    TxRetry_wb <= TxRetrySync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDoneSync1 <= 1'b0;
  else
    TxDoneSync1 <= TxDone;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxDone_wb <= 1'b0;
  else
    TxDone_wb <= TxDoneSync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbortSync1 <= 1'b0;
  else
    TxAbortSync1 <= TxAbort;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxAbort_wb <= 1'b0;
  else
    TxAbort_wb <= TxAbortSync1;
end
assign StartRxBDRead = RxStatusWrite | RxAbortSync3 & ~RxAbortSync4 |
                       r_RxEn & ~r_RxEn_q;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDRead <= 1'b0;
  else
  if(StartRxBDRead & ~RxReady)
    RxBDRead <= 1'b1;
  else
  if(RxBDReady)
    RxBDRead <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxBDReady <= 1'b0;
  else
  if(RxPointerRead)
    RxBDReady <= 1'b0;
  else
  if(RxEn & RxEn_q & RxBDRead)
    RxBDReady <= ram_do[15]; 
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxStatus <= 2'h0;
  else
  if(RxEn & RxEn_q & RxBDRead)
    RxStatus <= ram_do[14:13];
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxReady <= 1'b0;
  else if(ShiftEnded | RxAbortSync2 & ~RxAbortSync3 | ~r_RxEn & r_RxEn_q)
    RxReady <= 1'b0;
  else if(RxEn & RxEn_q & RxPointerRead)
    RxReady <= 1'b1;
end
assign StartRxPointerRead = RxBDRead & RxBDReady;
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxPointerRead <= 1'b0;
  else
  if(StartRxPointerRead)
    RxPointerRead <= 1'b1;
  else
  if(RxEn & RxEn_q)
    RxPointerRead <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxPointerMSB <= 30'h0;
  else
  if(RxEn & RxEn_q & RxPointerRead)
    RxPointerMSB <= ram_do[31:2];
  else
  if(MasterWbRX & m_wb_ack_i)
      RxPointerMSB <= RxPointerMSB + 1'b1;  
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxPointerLSB_rst[1:0] <= 0;
  else
  if(MasterWbRX & m_wb_ack_i)  
    RxPointerLSB_rst[1:0] <= 0;
  else
  if(RxEn & RxEn_q & RxPointerRead)
    RxPointerLSB_rst[1:0] <= ram_do[1:0];
end
always @ (RxPointerLSB_rst)
begin
  case(RxPointerLSB_rst[1:0])   
    2'h0 : RxByteSel[3:0] = 4'hf;
    2'h1 : RxByteSel[3:0] = 4'h7;
    2'h2 : RxByteSel[3:0] = 4'h3;
    2'h3 : RxByteSel[3:0] = 4'h1;
  endcase
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxEn_needed <= 1'b0;
  else if(~RxReady & r_RxEn & WbEn & ~WbEn_q)
    RxEn_needed <= 1'b1;
  else if(RxPointerRead & RxEn & RxEn_q)
    RxEn_needed <= 1'b0;
end
assign RxStatusWrite = ShiftEnded & RxEn & RxEn_q;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LastByteIn <= 1'b0;
  else
  if(ShiftWillEnd & (&RxByteCnt) | RxAbort)
    LastByteIn <= 1'b0;
  else
  if(RxValid & RxReady & RxEndFrm & ~(&RxByteCnt) & RxEnableWindow)
    LastByteIn <= 1'b1;
end
assign StartShiftWillEnd = LastByteIn  | RxValid & RxEndFrm & (&RxByteCnt) &
                           RxEnableWindow;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftWillEnd <= 1'b0;
  else
  if(ShiftEnded_rck | RxAbort)
    ShiftWillEnd <= 1'b0;
  else
  if(StartShiftWillEnd)
    ShiftWillEnd <= 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxByteCnt <= 2'h0;
  else
  if(ShiftEnded_rck | RxAbort)
    RxByteCnt <= 2'h0;
  else
  if(RxValid & RxStartFrm & RxReady)
    case(RxPointerLSB_rst)   
      2'h0 : RxByteCnt <= 2'h1;
      2'h1 : RxByteCnt <= 2'h2;
      2'h2 : RxByteCnt <= 2'h3;
      2'h3 : RxByteCnt <= 2'h0;
    endcase
  else
  if(RxValid & RxEnableWindow & RxReady | LastByteIn)
    RxByteCnt <= RxByteCnt + 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxValidBytes <= 2'h1;
  else
  if(RxValid & RxStartFrm)
    case(RxPointerLSB_rst)   
      2'h0 : RxValidBytes <= 2'h1;
      2'h1 : RxValidBytes <= 2'h2;
      2'h2 : RxValidBytes <= 2'h3;
      2'h3 : RxValidBytes <= 2'h0;
    endcase
  else
  if(RxValid & ~LastByteIn & ~RxStartFrm & RxEnableWindow)
    RxValidBytes <= RxValidBytes + 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxDataLatched1       <= 24'h0;
  else
  if(RxValid & RxReady & ~LastByteIn)
    if(RxStartFrm)
    begin
      case(RxPointerLSB_rst)      
        2'h0:        RxDataLatched1[31:24] <= RxData;
        2'h1:        RxDataLatched1[23:16] <= RxData;
        2'h2:        RxDataLatched1[15:8]  <= RxData;
        2'h3:        RxDataLatched1        <= RxDataLatched1;
      endcase
    end
    else if (RxEnableWindow)
    begin
      case(RxByteCnt)      
        2'h0:        RxDataLatched1[31:24] <= RxData;
        2'h1:        RxDataLatched1[23:16] <= RxData;
        2'h2:        RxDataLatched1[15:8]  <= RxData;
        2'h3:        RxDataLatched1        <= RxDataLatched1;
      endcase
    end
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxDataLatched2 <= 32'h0;
  else
  if(SetWriteRxDataToFifo & ~ShiftWillEnd)
    RxDataLatched2 <= {RxDataLatched1[31:8], RxData};
  else
  if(SetWriteRxDataToFifo & ShiftWillEnd)
    case(RxValidBytes)   
      0 : RxDataLatched2 <= {RxDataLatched1[31:8],  RxData};
      1 : RxDataLatched2 <= {RxDataLatched1[31:24], 24'h0};
      2 : RxDataLatched2 <= {RxDataLatched1[31:16], 16'h0};
      3 : RxDataLatched2 <= {RxDataLatched1[31:8],   8'h0};
    endcase
end
assign SetWriteRxDataToFifo = (RxValid & RxReady & ~RxStartFrm &
                              RxEnableWindow & (&RxByteCnt))
                              |(RxValid & RxReady &  RxStartFrm &
                              (&RxPointerLSB_rst))
                              |(ShiftWillEnd & LastByteIn & (&RxByteCnt));
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifo <= 1'b0;
  else
  if(SetWriteRxDataToFifo & ~RxAbort)
    WriteRxDataToFifo <= 1'b1;
  else
  if(WriteRxDataToFifoSync2 | RxAbort)
    WriteRxDataToFifo <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifoSync1 <= 1'b0;
  else
  if(WriteRxDataToFifo)
    WriteRxDataToFifoSync1 <= 1'b1;
  else
    WriteRxDataToFifoSync1 <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifoSync2 <= 1'b0;
  else
    WriteRxDataToFifoSync2 <= WriteRxDataToFifoSync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    WriteRxDataToFifoSync3 <= 1'b0;
  else
    WriteRxDataToFifoSync3 <= WriteRxDataToFifoSync2;
end
assign WriteRxDataToFifo_wb = WriteRxDataToFifoSync2 &
                              ~WriteRxDataToFifoSync3;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedRxStartFrm <= 0;
  else
  if(RxStartFrm & ~SyncRxStartFrm_q)
    LatchedRxStartFrm <= 1;
  else
  if(SyncRxStartFrm_q)
    LatchedRxStartFrm <= 0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    SyncRxStartFrm <= 0;
  else
  if(LatchedRxStartFrm)
    SyncRxStartFrm <= 1;
  else
    SyncRxStartFrm <= 0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    SyncRxStartFrm_q <= 0;
  else
    SyncRxStartFrm_q <= SyncRxStartFrm;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    SyncRxStartFrm_q2 <= 0;
  else
    SyncRxStartFrm_q2 <= SyncRxStartFrm_q;
end
assign RxFifoReset = SyncRxStartFrm_q & ~SyncRxStartFrm_q2;
eth_fifo #(
           .DATA_WIDTH(RX_FIFO_DATA_WIDTH),
           .DEPTH(RX_FIFO_DEPTH),
           .CNT_WIDTH(RX_FIFO_CNT_WIDTH))
rx_fifo (
         .clk            (WB_CLK_I),
         .reset          (Reset),
         .data_in        (RxDataLatched2),
         .write          (WriteRxDataToFifo_wb & ~RxBufferFull),
         .read           (MasterWbRX & m_wb_ack_i),
         .clear          (RxFifoReset),
         .data_out       (m_wb_dat_o), 
         .full           (RxBufferFull),
         .almost_full    (),
         .almost_empty   (RxBufferAlmostEmpty), 
         .empty          (RxBufferEmpty),
         .cnt            (rxfifo_cnt)
        );
assign enough_data_in_rxfifo_for_burst = rxfifo_cnt>=4;
assign enough_data_in_rxfifo_for_burst_plus1 = rxfifo_cnt>4;
assign WriteRxDataToMemory = ~RxBufferEmpty;
assign rx_burst = rx_burst_en & WriteRxDataToMemory;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftEnded_rck <= 1'b0;
  else
  if(~RxAbort & SetWriteRxDataToFifo & StartShiftWillEnd)
    ShiftEnded_rck <= 1'b1;
  else
  if(RxAbort | ShiftEndedSync_c1 & ShiftEndedSync_c2)
    ShiftEnded_rck <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync1 <= 1'b0;
  else
    ShiftEndedSync1 <= ShiftEnded_rck;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync2 <= 1'b0;
  else
    ShiftEndedSync2 <= ShiftEndedSync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync3 <= 1'b0;
  else
  if(ShiftEndedSync1 & ~ShiftEndedSync2)
    ShiftEndedSync3 <= 1'b1;
  else
  if(ShiftEnded)
    ShiftEndedSync3 <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    ShiftEnded <= 1'b0;
  else
  if(ShiftEndedSync3 & MasterWbRX & m_wb_ack_i & RxBufferAlmostEmpty & ~ShiftEnded)
    ShiftEnded <= 1'b1;
  else
  if(RxStatusWrite)
    ShiftEnded <= 1'b0;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync_c1 <= 1'b0;
  else
    ShiftEndedSync_c1 <= ShiftEndedSync2;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    ShiftEndedSync_c2 <= 1'b0;
  else
    ShiftEndedSync_c2 <= ShiftEndedSync_c1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxEnableWindow <= 1'b0;
  else if(RxStartFrm)
    RxEnableWindow <= 1'b1;
  else if(RxEndFrm | RxAbort)
    RxEnableWindow <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync1 <= 1'b0;
  else
    RxAbortSync1 <= RxAbortLatched;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync2 <= 1'b0;
  else
    RxAbortSync2 <= RxAbortSync1;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync3 <= 1'b0;
  else
    RxAbortSync3 <= RxAbortSync2;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxAbortSync4 <= 1'b0;
  else
    RxAbortSync4 <= RxAbortSync3;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbortSyncb1 <= 1'b0;
  else
    RxAbortSyncb1 <= RxAbortSync2;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbortSyncb2 <= 1'b0;
  else
    RxAbortSyncb2 <= RxAbortSyncb1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxAbortLatched <= 1'b0;
  else
  if(RxAbortSyncb2)
    RxAbortLatched <= 1'b0;
  else
  if(RxAbort)
    RxAbortLatched <= 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    LatchedRxLength[15:0] <= 16'h0;
  else
  if(LoadRxStatus)
    LatchedRxLength[15:0] <= RxLength[15:0];
end
assign RxStatusIn = {ReceivedPauseFrm,
                     AddressMiss,
                     RxOverrun,
                     InvalidSymbol,
                     DribbleNibble,
                     ReceivedPacketTooBig,
                     ShortFrame,
                     LatchedCrcError,
                     RxLateCollision};
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    RxStatusInLatched <= 'h0;
  else
  if(LoadRxStatus)
    RxStatusInLatched <= RxStatusIn;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxOverrun <= 1'b0;
  else if(RxStatusWrite)
    RxOverrun <= 1'b0;
  else if(RxBufferFull & WriteRxDataToFifo_wb)
    RxOverrun <= 1'b1;
end
assign TxError = TxUnderRun | RetryLimit | LateCollLatched | CarrierSenseLost;
assign RxError = (|RxStatusInLatched[6:3]) | (|RxStatusInLatched[1:0]);
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxStatusWriteLatched <= 1'b0;
  else
  if(RxStatusWriteLatched_syncb2)
    RxStatusWriteLatched <= 1'b0;        
  else
  if(RxStatusWrite)
    RxStatusWriteLatched <= 1'b1;
end
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    begin
      RxStatusWriteLatched_sync1 <= 1'b0;
      RxStatusWriteLatched_sync2 <= 1'b0;
    end
  else
    begin
      RxStatusWriteLatched_sync1 <= RxStatusWriteLatched;
      RxStatusWriteLatched_sync2 <= RxStatusWriteLatched_sync1;
    end
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    begin
      RxStatusWriteLatched_syncb1 <= 1'b0;
      RxStatusWriteLatched_syncb2 <= 1'b0;
    end
  else
    begin
      RxStatusWriteLatched_syncb1 <= RxStatusWriteLatched_sync2;
      RxStatusWriteLatched_syncb2 <= RxStatusWriteLatched_syncb1;
    end
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxB_IRQ <= 1'b0;
  else
  if(TxStatusWrite & TxIRQEn)
    TxB_IRQ <= ~TxError;
  else
    TxB_IRQ <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    TxE_IRQ <= 1'b0;
  else
  if(TxStatusWrite & TxIRQEn)
    TxE_IRQ <= TxError;
  else
    TxE_IRQ <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxB_IRQ <= 1'b0;
  else
  if(RxStatusWrite & RxIRQEn & ReceivedPacketGood &
     (~ReceivedPauseFrm | ReceivedPauseFrm & r_PassAll & (~r_RxFlow)))
    RxB_IRQ <= (~RxError);
  else
    RxB_IRQ <= 1'b0;
end
always @ (posedge WB_CLK_I or posedge Reset)
begin
  if(Reset)
    RxE_IRQ <= 1'b0;
  else
  if(RxStatusWrite & RxIRQEn & (~ReceivedPauseFrm | ReceivedPauseFrm
     & r_PassAll & (~r_RxFlow)))
    RxE_IRQ <= RxError;
  else
    RxE_IRQ <= 1'b0;
end
reg Busy_IRQ_rck;
reg Busy_IRQ_sync1;
reg Busy_IRQ_sync2;
reg Busy_IRQ_sync3;
reg Busy_IRQ_syncb1;
reg Busy_IRQ_syncb2;
always @ (posedge MRxClk or posedge Reset)
begin
  if(Reset)
    Busy_IRQ_rck <= 1'b0;
  else
  if(RxValid & RxStartFrm & ~RxReady)
    Busy_IRQ_rck <= 1'b1;
  else
  if(Busy_IRQ_syncb2)
    Busy_IRQ_rck <= 1'b0;
end
always @ (posedge WB_CLK_I)
begin
    Busy_IRQ_sync1 <= Busy_IRQ_rck;
    Busy_IRQ_sync2 <= Busy_IRQ_sync1;
    Busy_IRQ_sync3 <= Busy_IRQ_sync2;
end
always @ (posedge MRxClk)
begin
    Busy_IRQ_syncb1 <= Busy_IRQ_sync2;
    Busy_IRQ_syncb2 <= Busy_IRQ_syncb1;
end
assign Busy_IRQ = Busy_IRQ_sync2 & ~Busy_IRQ_sync3;
endmodule
`timescale 1ns / 1ns
