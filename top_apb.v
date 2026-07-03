module apb_slave(input pclk,prstn,pwrite,psel,penable,
input wire[3:0] paddr,
input wire [31:0] pwdata,
output pready,
output wire [31:0] prdata);
reg [1:0] state,nstate;
wire count_done;
wire count_en;
wire [3:0] reg_sel;
wire [3:0] reg_we;
wire access_en;
wire [31:0] reg_0,reg_1,reg_2,reg_3;

assign pready=count_done;

add_dec m1(.paddr(paddr),.reg_sel(reg_sel));
wait_counter m2(.count_en(count_en),.pclk(pclk),.prstn(prstn),.count_done(count_done));
write_enable m3(.psel(psel),.pwrite(pwrite),.access_en(access_en),.count_done(count_done),.reg_sel(reg_sel),.reg_we(reg_we));
read_mux m4(.psel(psel),.pwrite(pwrite),.reg_sel(reg_sel),.reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3),.prdata(prdata));
reg_block m5(.pclk(pclk),.prstn(prstn),.pwdata(pwdata),.reg_we(reg_we),.reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3));

parameter idle=2'b00;
parameter setup=2'b01;
parameter access=2'b10;

always@(posedge pclk or negedge prstn)
begin
if(!prstn)
state<=idle;
else
state<=nstate;
end

always@(*)
begin
nstate=state;
 case(state)
 idle  : begin
         if(psel==1 && penable==0)
           nstate=setup;
         else
           nstate=idle;
           end
 setup : begin
        if(penable==1 && psel==1)
           begin
            nstate=access;
            //count_en=1;
            end
            else if(psel==0)
            nstate=idle;
            else 
            nstate=setup;
         end
 access: begin
         if(count_done==1)
            begin
            if(psel==1)
            begin
             nstate=setup;
            
             end
            else
            begin
             nstate=idle;
           
             end
            end
          else if(penable==1'b0)
            nstate=idle;
          else
            nstate=access;
          end
 default :nstate=idle;
 endcase
end
assign access_en=(state==access);
assign count_en=(state==access);

endmodule

module add_dec(input [3:0]paddr,
output reg [3:0] reg_sel);

always@(*)
begin
case(paddr)
  4'hc: reg_sel=4'b1000;
  4'h8: reg_sel=4'b0100;
  4'h4: reg_sel=4'b0010;
  4'h0: reg_sel=4'b0001;
 default : reg_sel=0;
endcase
end
endmodule

module wait_counter(input count_en,pclk,prstn,
output  count_done);

parameter wait_cyc=2;
reg [1:0] state_cnt;
always@(posedge pclk or negedge prstn)
begin
  if(!prstn)
   state_cnt<=0;
  else 
  begin
    if(count_en && state_cnt<=wait_cyc)
        state_cnt<=state_cnt+1;
    else 
        state_cnt<=0;
    end
    end
  assign count_done = (state_cnt==wait_cyc);
  endmodule
  
module write_enable(input psel,pwrite,access_en,count_done,
input [3:0] reg_sel,
output [3:0]reg_we);

assign reg_we[0]=(psel)&(pwrite)&(access_en)&(count_done)&(reg_sel[0]);
assign reg_we[1]=(psel)&(pwrite)&(access_en)&(count_done)&(reg_sel[1]);
assign reg_we[2]=(psel)&(pwrite)&(access_en)&(count_done)&(reg_sel[2]);
assign reg_we[3]=(psel)&(pwrite)&(access_en)&(count_done)&(reg_sel[3]);
endmodule

module read_mux(input psel,pwrite,
input [3:0] reg_sel,
input [31:0] reg_0,reg_1,reg_2,reg_3,
output reg [31:0]prdata);
always@(*)
begin
prdata = 32'd0;
if(psel==1 && pwrite==0)
 begin
 case(reg_sel)
  4'b1000 :prdata=reg_3;
  4'b0100 :prdata=reg_2;
  4'b0010 :prdata=reg_1;
  4'b0001 :prdata=reg_0;
  default : prdata=32'b0;
  endcase
 end
end
endmodule

module reg_block(input pclk,prstn,
input [31:0]pwdata,
input [3:0]reg_we,
output reg [31:0] reg_0,reg_1,reg_2,reg_3);

always@(posedge pclk or negedge prstn)begin

if(!prstn)
 begin
 reg_0<=32'b0;
 reg_1<=32'b0;
 reg_2<=32'b0;
 reg_3<=32'b0;
 end
 else
 begin
 if(reg_we[0])
   reg_0<=pwdata;
 if(reg_we[1])
   reg_1<=pwdata;
 if(reg_we[2])
   reg_2<=pwdata;
 if(reg_we[3])
   reg_3<=pwdata;
   end
 end
endmodule