module f_permutation(clk, reset, in, in_ready, ack, out, out_ready);
    input               clk, reset;
    input      [575:0]  in;
    input               in_ready;
    output              ack;
    output reg [1599:0] out;
    output reg          out_ready;
    reg        [10:0]   i;  
    wire       [1599:0] round_in, round_out;
    wire       [63:0]   rc1, rc2;
    wire                update;
    wire                accept;
    reg                 calc;  
    assign accept = in_ready & (~ calc);  
    always @ (posedge clk)
      if (reset) i <= 0;
      else       i <= {i[9:0], accept};
    always @ (posedge clk)
      if (reset) calc <= 0;
      else       calc <= (calc & (~ i[10])) | accept;
    assign update = calc | accept;
    assign ack = accept;
    always @ (posedge clk)
      if (reset)
        out_ready <= 0;
      else if (accept)
        out_ready <= 0;
      else if (i[10])  
        out_ready <= 1;
    assign round_in = accept ? {in ^ out[1599:1599-575], out[1599-576:0]} : out;
    rconst2in1
      rconst_ ({i, accept}, rc1, rc2);
    round2in1
      round_ (round_in, rc1, rc2, round_out);
    always @ (posedge clk)
      if (reset)
        out <= 0;
      else if (update)
        out <= round_out;
endmodule
module keccak(clk, reset, in, in_ready, is_last, byte_num, buffer_full, out, out_ready);
    input              clk, reset;
    input      [63:0]  in;
    input              in_ready, is_last;
    input      [2:0]   byte_num;
    output             buffer_full;  
    output     [511:0] out;
    output reg         out_ready;
    reg                state;     
    wire       [575:0] padder_out,
                       padder_out_1;  
    wire               padder_out_ready;
    wire               f_ack;
    wire      [1599:0] f_out;
    wire               f_out_ready;
    wire       [511:0] out1;       
    reg        [10:0]  i;          
    genvar w, b;
    assign out1 = f_out[1599:1599-511];
    always @ (posedge clk)
      if (reset)
        i <= 0;
      else
        i <= {i[9:0], state & f_ack};
    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;
    generate
      for(w=0; w<8; w=w+1)
        begin : L0
          for(b=0; b<8; b=b+1)
            begin : L1
              assign out[(((w)*64 + (b)*8) + 7):((w)*64 + (b)*8)] = out1[(((w)*64 + (7-b)*8) + 7):((w)*64 + (7-b)*8)];
            end
        end
    endgenerate
    generate
      for(w=0; w<9; w=w+1)
        begin : L2
          for(b=0; b<8; b=b+1)
            begin : L3
              assign padder_out[(((w)*64 + (b)*8) + 7):((w)*64 + (b)*8)] = padder_out_1[(((w)*64 + (7-b)*8) + 7):((w)*64 + (7-b)*8)];
            end
        end
    endgenerate
    always @ (posedge clk)
      if (reset)
        out_ready <= 0;
      else if (i[10])
        out_ready <= 1;
    padder
      padder_ (clk, reset, in, in_ready, is_last, byte_num, buffer_full, padder_out_1, padder_out_ready, f_ack);
    f_permutation
      f_permutation_ (clk, reset, padder_out, padder_out_ready, f_ack, f_out, f_out_ready);
endmodule
module padder(clk, reset, in, in_ready, is_last, byte_num, buffer_full, out, out_ready, f_ack);
    input              clk, reset;
    input      [63:0]  in;
    input              in_ready, is_last;
    input      [2:0]   byte_num;
    output             buffer_full;  
    output reg [575:0] out;          
    output             out_ready;    
    input              f_ack;        
    reg                state;       
    reg                done;         
    reg        [8:0]   i;            
    wire       [63:0]  v0;           
    reg        [63:0]  v1;           
    wire               accept,       
                       update;
    assign buffer_full = i[8];
    assign out_ready = buffer_full;
    assign accept = (~ state) & in_ready & (~ buffer_full);  
    assign update = (accept | (state & (~ buffer_full))) & (~ done);  
    always @ (posedge clk)
      if (reset)
        out <= 0;
      else if (update)
        out <= {out[575-64:0], v1};
    always @ (posedge clk)
      if (reset)
        i <= 0;
      else if (f_ack | update)
        i <= {i[7:0], 1'b1} & {9{~ f_ack}};
    always @ (posedge clk)
      if (reset)
        state <= 0;
      else if (is_last)
        state <= 1;
    always @ (posedge clk)
      if (reset)
        done <= 0;
      else if (state & out_ready)
        done <= 1;
    padder1 p0 (in, byte_num, v0);
    always @ (*)
      begin
        if (state)
          begin
            v1 = 0;
            v1[7] = v1[7] | i[7];  
          end
        else if (is_last == 0)
          v1 = in;
        else
          begin
            v1 = v0;
            v1[7] = v1[7] | i[7];
          end
      end
endmodule
module padder1(in, byte_num, out);
    input      [63:0] in;
    input      [2:0]  byte_num;
    output reg [63:0] out;
    always @ (*)
      case (byte_num)
        0: out =             64'h0100000000000000;
        1: out = {in[63:56], 56'h01000000000000};
        2: out = {in[63:48], 48'h010000000000};
        3: out = {in[63:40], 40'h0100000000};
        4: out = {in[63:32], 32'h01000000};
        5: out = {in[63:24], 24'h010000};
        6: out = {in[63:16], 16'h0100};
        7: out = {in[63:8],   8'h01};
      endcase
endmodule
module rconst2in1(i, rc1, rc2);
    input  [11:0] i;
    output [63:0] rc1, rc2;
    reg    [63:0] rc1, rc2;
    always @ (i)
      begin
        rc1 = 0;
        rc1[0] = i[0] | i[2] | i[3] | i[5] | i[6] | i[7] | i[10] | i[11];
        rc1[1] = i[1] | i[2] | i[4] | i[6] | i[8] | i[9];
        rc1[3] = i[1] | i[2] | i[4] | i[5] | i[6] | i[7] | i[9];
        rc1[7] = i[1] | i[2] | i[3] | i[4] | i[6] | i[7] | i[10];
        rc1[15] = i[1] | i[2] | i[3] | i[5] | i[6] | i[7] | i[8] | i[9] | i[10];
        rc1[31] = i[3] | i[5] | i[6] | i[10] | i[11];
        rc1[63] = i[1] | i[3] | i[7] | i[8] | i[10];
      end
    always @ (i)
      begin
        rc2 = 0;
        rc2[0] = i[2] | i[3] | i[6] | i[7];
        rc2[1] = i[0] | i[5] | i[6] | i[7] | i[9];
        rc2[3] = i[3] | i[4] | i[5] | i[6] | i[9] | i[11];
        rc2[7] = i[0] | i[4] | i[6] | i[8] | i[10];
        rc2[15] = i[0] | i[1] | i[3] | i[7] | i[10] | i[11];
        rc2[31] = i[1] | i[2] | i[5] | i[9] | i[11];
        rc2[63] = i[1] | i[3] | i[6] | i[7] | i[8] | i[9] | i[10] | i[11];
      end
endmodule
module round2in1(in, round_const_1, round_const_2, out);
    input  [1599:0] in;
    input  [63:0]   round_const_1, round_const_2;
    output [1599:0] out;
    wire   [63:0]   a[4:0][4:0];
    wire   [63:0]   b[4:0];
    wire   [63:0]   c[4:0][4:0], d[4:0][4:0], e[4:0][4:0], f[4:0][4:0], g[4:0][4:0];
    wire   [63:0]   bb[4:0];
    wire   [63:0]   cc[4:0][4:0], dd[4:0][4:0], ee[4:0][4:0], ff[4:0][4:0], gg[4:0][4:0];
    genvar x, y;
    generate
      for(y=0; y<5; y=y+1)
        begin : L0
          for(x=0; x<5; x=x+1)
            begin : L1
              assign a[x][y] = in[1599 - 64*(5*y+x) : 1599 - 64*(5*y+x) - 63];
            end
        end
    endgenerate
    generate
      for(x=0; x<5; x=x+1)
        begin : L2
          assign b[x] = a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4];
        end
    endgenerate
    generate
      for(y=0; y<5; y=y+1)
        begin : L3
          for(x=0; x<5; x=x+1)
            begin : L4
              assign c[x][y] = a[x][y] ^ b[(x == 0 ? 4 : x - 1)] ^ {b[(x == 4 ? 0 : x + 1)][62:0], b[(x == 4 ? 0 : x + 1)][63]};
            end
        end
    endgenerate
    assign d[0][0] = c[0][0];
    assign d[1][0] = {c[1][0][62:0], c[1][0][63]};
    assign d[2][0] = {c[2][0][63-62:0], c[2][0][63:63-62+1]};
    assign d[3][0] = {c[3][0][63-28:0], c[3][0][63:63-28+1]};
    assign d[4][0] = {c[4][0][63-27:0], c[4][0][63:63-27+1]};
    assign d[0][1] = {c[0][1][63-36:0], c[0][1][63:63-36+1]};
    assign d[1][1] = {c[1][1][63-44:0], c[1][1][63:63-44+1]};
    assign d[2][1] = {c[2][1][63-6:0], c[2][1][63:63-6+1]};
    assign d[3][1] = {c[3][1][63-55:0], c[3][1][63:63-55+1]};
    assign d[4][1] = {c[4][1][63-20:0], c[4][1][63:63-20+1]};
    assign d[0][2] = {c[0][2][63-3:0], c[0][2][63:63-3+1]};
    assign d[1][2] = {c[1][2][63-10:0], c[1][2][63:63-10+1]};
    assign d[2][2] = {c[2][2][63-43:0], c[2][2][63:63-43+1]};
    assign d[3][2] = {c[3][2][63-25:0], c[3][2][63:63-25+1]};
    assign d[4][2] = {c[4][2][63-39:0], c[4][2][63:63-39+1]};
    assign d[0][3] = {c[0][3][63-41:0], c[0][3][63:63-41+1]};
    assign d[1][3] = {c[1][3][63-45:0], c[1][3][63:63-45+1]};
    assign d[2][3] = {c[2][3][63-15:0], c[2][3][63:63-15+1]};
    assign d[3][3] = {c[3][3][63-21:0], c[3][3][63:63-21+1]};
    assign d[4][3] = {c[4][3][63-8:0], c[4][3][63:63-8+1]};
    assign d[0][4] = {c[0][4][63-18:0], c[0][4][63:63-18+1]};
    assign d[1][4] = {c[1][4][63-2:0], c[1][4][63:63-2+1]};
    assign d[2][4] = {c[2][4][63-61:0], c[2][4][63:63-61+1]};
    assign d[3][4] = {c[3][4][63-56:0], c[3][4][63:63-56+1]};
    assign d[4][4] = {c[4][4][63-14:0], c[4][4][63:63-14+1]};
    assign e[0][0] = d[0][0];
    assign e[0][2] = d[1][0];
    assign e[0][4] = d[2][0];
    assign e[0][1] = d[3][0];
    assign e[0][3] = d[4][0];
    assign e[1][3] = d[0][1];
    assign e[1][0] = d[1][1];
    assign e[1][2] = d[2][1];
    assign e[1][4] = d[3][1];
    assign e[1][1] = d[4][1];
    assign e[2][1] = d[0][2];
    assign e[2][3] = d[1][2];
    assign e[2][0] = d[2][2];
    assign e[2][2] = d[3][2];
    assign e[2][4] = d[4][2];
    assign e[3][4] = d[0][3];
    assign e[3][1] = d[1][3];
    assign e[3][3] = d[2][3];
    assign e[3][0] = d[3][3];
    assign e[3][2] = d[4][3];
    assign e[4][2] = d[0][4];
    assign e[4][4] = d[1][4];
    assign e[4][1] = d[2][4];
    assign e[4][3] = d[3][4];
    assign e[4][0] = d[4][4];
    generate
      for(y=0; y<5; y=y+1)
        begin : L5
          for(x=0; x<5; x=x+1)
            begin : L6
              assign f[x][y] = e[x][y] ^ ((~ e[(x == 4 ? 0 : x + 1)][y]) & e[(x == 3 ? 0 : x == 4 ? 1 : x + 2)][y]);
            end
        end
    endgenerate
    generate
      for(x=0; x<64; x=x+1)
        begin : L60
          if(x==0 || x==1 || x==3 || x==7 || x==15 || x==31 || x==63)
            assign g[0][0][x] = f[0][0][x] ^ round_const_1[x];
          else
            assign g[0][0][x] = f[0][0][x];
        end
    endgenerate
    generate
      for(y=0; y<5; y=y+1)
        begin : L7
          for(x=0; x<5; x=x+1)
            begin : L8
              if(x!=0 || y!=0)
                assign g[x][y] = f[x][y];
            end
        end
    endgenerate
    generate
      for(x=0; x<5; x=x+1)
        begin : L12
          assign bb[x] = g[x][0] ^ g[x][1] ^ g[x][2] ^ g[x][3] ^ g[x][4];
        end
    endgenerate
    generate
      for(y=0; y<5; y=y+1)
        begin : L13
          for(x=0; x<5; x=x+1)
            begin : L14
              assign cc[x][y] = g[x][y] ^ bb[(x == 0 ? 4 : x - 1)] ^ {bb[(x == 4 ? 0 : x + 1)][62:0], bb[(x == 4 ? 0 : x + 1)][63]};
            end
        end
    endgenerate
    assign dd[0][0] = cc[0][0];
    assign dd[1][0] = {cc[1][0][62:0], cc[1][0][63]};
    assign dd[2][0] = {cc[2][0][63-62:0], cc[2][0][63:63-62+1]};
    assign dd[3][0] = {cc[3][0][63-28:0], cc[3][0][63:63-28+1]};
    assign dd[4][0] = {cc[4][0][63-27:0], cc[4][0][63:63-27+1]};
    assign dd[0][1] = {cc[0][1][63-36:0], cc[0][1][63:63-36+1]};
    assign dd[1][1] = {cc[1][1][63-44:0], cc[1][1][63:63-44+1]};
    assign dd[2][1] = {cc[2][1][63-6:0], cc[2][1][63:63-6+1]};
    assign dd[3][1] = {cc[3][1][63-55:0], cc[3][1][63:63-55+1]};
    assign dd[4][1] = {cc[4][1][63-20:0], cc[4][1][63:63-20+1]};
    assign dd[0][2] = {cc[0][2][63-3:0], cc[0][2][63:63-3+1]};
    assign dd[1][2] = {cc[1][2][63-10:0], cc[1][2][63:63-10+1]};
    assign dd[2][2] = {cc[2][2][63-43:0], cc[2][2][63:63-43+1]};
    assign dd[3][2] = {cc[3][2][63-25:0], cc[3][2][63:63-25+1]};
    assign dd[4][2] = {cc[4][2][63-39:0], cc[4][2][63:63-39+1]};
    assign dd[0][3] = {cc[0][3][63-41:0], cc[0][3][63:63-41+1]};
    assign dd[1][3] = {cc[1][3][63-45:0], cc[1][3][63:63-45+1]};
    assign dd[2][3] = {cc[2][3][63-15:0], cc[2][3][63:63-15+1]};
    assign dd[3][3] = {cc[3][3][63-21:0], cc[3][3][63:63-21+1]};
    assign dd[4][3] = {cc[4][3][63-8:0], cc[4][3][63:63-8+1]};
    assign dd[0][4] = {cc[0][4][63-18:0], cc[0][4][63:63-18+1]};
    assign dd[1][4] = {cc[1][4][63-2:0], cc[1][4][63:63-2+1]};
    assign dd[2][4] = {cc[2][4][63-61:0], cc[2][4][63:63-61+1]};
    assign dd[3][4] = {cc[3][4][63-56:0], cc[3][4][63:63-56+1]};
    assign dd[4][4] = {cc[4][4][63-14:0], cc[4][4][63:63-14+1]};
    assign ee[0][0] = dd[0][0];
    assign ee[0][2] = dd[1][0];
    assign ee[0][4] = dd[2][0];
    assign ee[0][1] = dd[3][0];
    assign ee[0][3] = dd[4][0];
    assign ee[1][3] = dd[0][1];
    assign ee[1][0] = dd[1][1];
    assign ee[1][2] = dd[2][1];
    assign ee[1][4] = dd[3][1];
    assign ee[1][1] = dd[4][1];
    assign ee[2][1] = dd[0][2];
    assign ee[2][3] = dd[1][2];
    assign ee[2][0] = dd[2][2];
    assign ee[2][2] = dd[3][2];
    assign ee[2][4] = dd[4][2];
    assign ee[3][4] = dd[0][3];
    assign ee[3][1] = dd[1][3];
    assign ee[3][3] = dd[2][3];
    assign ee[3][0] = dd[3][3];
    assign ee[3][2] = dd[4][3];
    assign ee[4][2] = dd[0][4];
    assign ee[4][4] = dd[1][4];
    assign ee[4][1] = dd[2][4];
    assign ee[4][3] = dd[3][4];
    assign ee[4][0] = dd[4][4];
    generate
      for(y=0; y<5; y=y+1)
        begin : L15
          for(x=0; x<5; x=x+1)
            begin : L16
              assign ff[x][y] = ee[x][y] ^ ((~ ee[(x == 4 ? 0 : x + 1)][y]) & ee[(x == 3 ? 0 : x == 4 ? 1 : x + 2)][y]);
            end
        end
    endgenerate
    generate
      for(x=0; x<64; x=x+1)
        begin : L160
          if(x==0 || x==1 || x==3 || x==7 || x==15 || x==31 || x==63)
            assign gg[0][0][x] = ff[0][0][x] ^ round_const_2[x];
          else
            assign gg[0][0][x] = ff[0][0][x];
        end
    endgenerate
    generate
      for(y=0; y<5; y=y+1)
        begin : L17
          for(x=0; x<5; x=x+1)
            begin : L18
              if(x!=0 || y!=0)
                assign gg[x][y] = ff[x][y];
            end
        end
    endgenerate
    generate
      for(y=0; y<5; y=y+1)
        begin : L99
          for(x=0; x<5; x=x+1)
            begin : L100
              assign out[1599 - 64*(5*y+x) : 1599 - 64*(5*y+x) - 63] = gg[x][y];
            end
        end
    endgenerate
endmodule
