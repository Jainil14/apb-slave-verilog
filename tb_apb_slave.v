`timescale 1ns / 1ps

module tb_apb_slave();
reg pclk,prstn,pwrite,psel,penable;
reg[3:0] paddr;
reg [31:0] pwdata;
wire pready;
wire [31:0] prdata;

apb_slave dut(.pclk(pclk),.prstn(prstn),.pwrite(pwrite),.psel(psel),.penable(penable),.paddr(paddr),.pwdata(pwdata),.pready(pready),.prdata(prdata));
always #5 pclk=~pclk;

task write_apb(input [3:0]addr,input [31:0]wdata);
begin
 @(posedge pclk)
 paddr=addr;
 pwdata=wdata;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 
 @(posedge pclk)
 penable=1'b1;
 
 wait(dut.count_done==1);
 
 @(posedge pclk)
 penable=1'b0;
 psel=1'b0;
 
end
endtask

task read_apb(input [3:0]addr);
begin
 @(posedge pclk)
 paddr=addr;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b0;

 
 @(posedge pclk)
 penable=1'b1;
 
 wait(dut.count_done==1);
 
 @(posedge pclk)
 penable=1'b0;
 psel=1'b0;
 
end
endtask


initial begin

//init.
pclk=1'b0;
prstn=1'b0;
pwrite=1'b0;
psel=1'b0;
penable=1'b0;
//TESTCASES : 

//1.RESET init
@(posedge pclk);
prstn=1'b0;
#20;
if(dut.state==2'b00 && dut.m5.reg_0==32'b0 && dut.m5.reg_1==32'b0 && dut.m5.reg_2==32'b0 && dut.m5.reg_3==32'b0)
$display("the TEST-1 :RESET init is passed");
else
$display("the TEST-1 :RESET init is failed");

@(posedge pclk);
prstn=1'b1;

//2.Normal Write
write_apb(4'hC,32'h6996);
read_apb(4'hC);
if(prdata==32'h6996)
 $display("TEST-2 : Normal WRITE passed");
 else
 $display("TEST-2 : Normal WRITE failed");
#20;

//3.Normal read
write_apb(4'h8,32'habcd1234);
read_apb(4'h8);
if(prdata==32'habcd1234)
 $display("TEST-3 : Normal READ passed");
 else
 $display("TEST-3 : Normal READ passed");
 
//4.continous write to 4 position
@(posedge pclk);
#1
psel=1'b1;
pwrite=1'b1;
penable=1'b0;
paddr=4'h0;
pwdata=32'h01234567;

@(posedge pclk);
#1
penable=1'b1;
wait(pready==1);

@(posedge pclk);
#1
penable=1'b0;
paddr=4'h4;
pwdata=32'h89abcdef;

@(posedge pclk);
#1
penable=1'b1;
wait(pready==1);

@(posedge pclk);
#1
penable=1'b0;
paddr=4'h8;
pwdata=32'h01020304;

@(posedge pclk);
#1  
penable=1'b1;
wait(pready==1);

@(posedge pclk);
#1
penable=1'b0;
paddr=4'hc;
pwdata=32'h05060708;

@(posedge pclk);
#1
penable=1'b1;
wait(pready==1);


@(posedge pclk);
#1;
if(dut.m5.reg_0==32'h01234567 && dut.m5.reg_1==32'h89abcdef && dut.m5.reg_2==32'h01020304 && dut.m5.reg_3==32'h05060708)
 $display("TEST-4 : cont 4  WRITE passed");
else
 $display("TEST-4 : cont 4  WRITE failed");
psel=1'b0;
penable=1'b0;
pwrite=1'b0;

//5.continous read 4 position
$display("TEST-5 cont 4 read");
@(posedge pclk);
#1;
psel=1'b1;
penable=1'b0;
pwrite=1'b0;
paddr=4'hc;

@(posedge pclk);
#1;
penable=1'b1;
wait(pready==1);

#1;
if(prdata==32'h05060708)
$display("Test 5.1 is passed");
else
$display("Test 5.1 is failed");

@(posedge pclk);
#1;
penable=1'b0;
paddr=4'h8;

@(posedge pclk);
#1;
penable=1'b1;
wait(pready==1);

#1;
if(prdata==32'h01020304)
$display("Test 5.2 is passed");
else
$display("Test 5.2 is failed");

@(posedge pclk);
#1;
penable=1'b0;
paddr=4'h4;

@(posedge pclk);
#1;
penable=1'b1;
wait(pready==1);

#1;
if(prdata==32'h89abcdef)
$display("Test 5.3 is passed");
else
$display("Test 5.3 is failed");

@(posedge pclk);
#1;
penable=1'b0;
paddr=4'h0;

@(posedge pclk);
#1;
penable=1'b1;
wait(pready==1);

#1;
if(prdata==32'h01234567)
$display("Test 5.4 is passed");
else
$display("Test 5.4 is failed");

//6.write to invalid addr

write_apb(4'h6,32'haaaabbbb);
$display("TEST-6 invalid write");
$display("Status of all 4 regs after illegal write  : ");
$display("reg_0 : %h |reg_1 : %h |reg_2 : %h |reg_3 : %h ",dut.m5.reg_0,dut.m5.reg_1,dut.m5.reg_2,dut.m5.reg_3);

//7.reading from illegal addr

read_apb(4'ha);
$display("TEST-7 invalid read");
if(prdata==32'b0)
$display("Test-7 is passed  : prdata = %h",prdata);
else
$display("Test-7 is failed : prdata =%h",prdata);

//8.extreme data write 
write_apb(4'h0,32'hffffffff);
read_apb(4'h0);
if(prdata==32'hffffffff)
 $display("TEST-8 : extreme data  WRITE passed");
 else
 $display("TEST-8 :  extreme data write  failed");
 
//9.reset in setup phase 
@(posedge pclk);
#1;
psel=0;
penable=0;
pwrite=0;
paddr=4'hc;
pwdata=32'h987789;
@(posedge pclk);
#1;
psel=1'b1;
penable=1'b0;
pwrite=1'b1;
prstn=1'b0;
@(posedge pclk);
#1;
if(dut.state==2'b00)
 $display("TEST-9 : RESET in SETUP passed");
else
 $display("TEST-9 : RESET in SETUP failed");
 
 
 //10.reset in access phase 
 @(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 paddr=4'h8;
 prstn=1'b1;
 pwdata=32'h88888888;
 
 @(posedge pclk);
 #1;
 penable=1'b1;
 prstn=1'b0;
 
 @(posedge pclk);
 #1;
 if(dut.state==2'b00 && dut.m5.reg_2==32'b0)
  $display("TEST-10 : RESET in ACCESS passed");
else
 $display("TEST-10 : RESET in ACCESS failed");
 
 //11.simultaneously pen and psel asserting in SETUP phase
 
 @(posedge pclk);
 #1;
 prstn=1'b1;
 psel=1'b1;
 pwrite=1'b1;
 paddr=4'hc;
 pwdata=32'h78789696;
 penable=1'b1;
 
 @(posedge pclk);
 #1;
 if(dut.state==2'b00)
  $display("TEST-11 PSEL & PENABLE BOTH 1 in setup  passed and data in reg_3 : %h",dut.m5.reg_3);
 else
  $display("TEST-11 PSEL & PENABLE BOTH 1 in setup  failed and data in reg_3 : %h",dut.m5.reg_3);
 
 //12. stalling in SETUP phase
 
 @(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwdata=32'h12121212;
 pwdata=4'h0;
 pwrite=1'b1;
 
 @(posedge pclk);
 @(posedge pclk);
 
 if(dut.state==2'b01)
  $display("TEST-12 STALL IN SETUP is passed : state=%b",dut.state);
 else 
  $display("TEST-12 STALL IN SETUP FAILED : state=%b",dut.state);


//13. psel=0 in ACCESS phase

@(posedge pclk);
#1;
psel=1'b1;
penable=1'b0;
pwdata=32'h77667766;
paddr=4'h4;
pwrite=1'b1;

@(posedge pclk);
#1;
psel=1'b0;
penable=1'b1;

@(posedge pclk);
#1;
if(dut.state==2'b00)
  $display("TEST-13  psel=0 in ACCESS phase is passed | state=%b",dut.state);
 else 
  $display("TEST-13  psel=0 in ACCESS phase FAILED  | state=%b",dut.state);
  
 //14. GLITCH DATA in access phase
 @(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 paddr=4'h8;
 pwdata=32'h12ab34cd;
 
 @(posedge pclk);
 #1;
 penable=1'b1;
 pwdata=32'hffffffff;

 
 @(posedge pclk);
 #1;
 pwdata=32'hdddddddd;
 
 wait(pready==1);
 @(posedge pclk);
 #1;
 if(dut.m5.reg_2==32'hdddddddd)
 $display("TEST-14 glitch data in access phase is passed , reg_2 :%h",dut.m5.reg_2);
 else
 $display("TEST-14 glitch data in access phase is failed , reg_2 :%h",dut.m5.reg_2);
 psel=0; penable=0; pwrite=0;
 
//15. glitch address in access phase
 @(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 paddr=4'h8;
 pwdata=32'h12ab34cd;
 
 @(posedge pclk);
 #1;
 penable=1'b1;
 paddr=4'hc;
 
 @(posedge pclk);
 #1;
 paddr=4'h0;
 
 
 
 wait(pready==1);
 @(posedge pclk);
 #1;
 if(dut.m5.reg_0==32'h12ab34cd)
 $display("TEST-15 glitch addr is passed , reg_0 :%h|reg_1 :%h|reg_2 :%h| reg_3 :%h",dut.m5.reg_0,dut.m5.reg_1,dut.m5.reg_2,dut.m5.reg_3);
 else
 $display("TEST-15 glitch addr is failed , reg_0 :%h|reg_1 :%h|reg_2 :%h| reg_3 :%h",dut.m5.reg_0,dut.m5.reg_1,dut.m5.reg_2,dut.m5.reg_3);
 psel=0; penable=0; pwrite=0;


//16.penable goes low in access phase

@(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 paddr=4'h8;
 pwdata=32'h12ab34cd;
 
 @(posedge pclk);
 #1;
 penable=1'b1;
 
 @(posedge pclk);
 #1;
 penable=1'b0;
 
 @(posedge pclk);
 #1;
 if(dut.state==2'b00)
  $display("TEST-16 penable=0 in access phase is passed , state :%b",dut.state);
 else
  $display("TEST-16 penable=0 in access phase is failed , state :%b",dut.state);
  
 //17.pwrite goes to 0 in access phase
 
 @(posedge pclk);
 #1;
 psel=1'b1;
 penable=1'b0;
 pwrite=1'b1;
 paddr=4'h4;
 pwdata=32'h1111111;
 
 @(posedge pclk);
 #1;
 penable=1'b1;
 pwrite=1'b0;
 
 wait(pready==1);
 @(posedge pclk);
 
 if(dut.m5.reg_1==32'b00)
  $display("TEST-17 pwrite=0 in access phase is passed , reg_1 :%h",dut.m5.reg_1);
 else
  $display("TEST-17 pwrite=0 in access phase is failed , reg_1 :%h",dut.m5.reg_1);
  
 
 
 
 
 
 
 
 
 
 
 
 end
endmodule