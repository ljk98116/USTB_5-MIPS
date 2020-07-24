`timescale 1ns/1ps

module Cache (
    input clk,
    input rst,

    //rom_req
    input rom_en,
    input [3:0] rom_wen,
    input [31:0] rom_addr,
    input [31:0] rom_wdata,
    (*mark_debug = "true"*)input i_cached,
    
    //ram_req
    (*mark_debug = "true"*)input ram_en,
    (*mark_debug = "true"*)input [3:0] ram_write_en,
    (*mark_debug = "true"*)input [31:0] ram_addr,
    (*mark_debug = "true"*)input [31:0] ram_write_data,
    (*mark_debug = "true"*)input [2:0] ram_size,
    (*mark_debug = "true"*)input d_cached,

    //other signals
    (*mark_debug = "true"*)input exception_flag,
    output halt,

    //rom_response
    (*mark_debug = "true"*)output [31:0] rom_read_data,
    (*mark_debug = "true"*)output [31:0] ram_read_data,

    //AXI3
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock       ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready                 
);

wire [3:0] i_awqos=0,d_awqos=0,i_arqos=0,d_arqos=0;

wire [3:0] i_arid,d_arid,i_awid,d_awid,i_rid,d_rid,i_wid,d_wid,i_bid,d_bid;
wire [31:0] i_araddr,d_araddr,i_awaddr,d_awaddr,i_rdata,d_rdata,i_wdata,d_wdata;
wire [7:0] i_arlen,d_arlen,i_awlen,d_awlen;
wire [2:0] i_arsize,d_arsize,i_awsize,d_awsize,i_arprot,d_arprot,i_awprot,d_awprot;
wire [1:0] i_arburst,d_arburst,i_awburst,d_awburst,i_arlock,d_arlock,i_awlock,d_awlock;
wire [1:0] i_rresp,d_rresp,i_bresp,d_bresp;
wire [3:0] i_wstrb,d_wstrb,i_arcache,d_arcache,i_awcache,d_awcache;
wire i_arvalid,d_arvalid,i_awvalid,d_awvalid;
wire i_arready,d_arready,i_awready,d_awready;
wire i_rlast,d_rlast,i_wlast,d_wlast;
wire i_rvalid,d_rvalid,i_wvalid,d_wvalid,i_bvalid,d_bvalid;
wire i_rready,d_rready,i_wready,d_wready,i_bready,d_bready;

wire [3:0] arlen_t,awlen_t;
wire [3:0] arqos,awqos;

wire d_stall_req,i_stall_req;

assign arlen = {4'b0,arlen_t};
assign awlen = {4'b0,awlen_t};

assign halt = exception_flag? 0:d_stall_req||i_stall_req;

CacheL1Inst u_ic(
    clk,
    rst,
    exception_flag,
    d_stall_req,
    i_stall_req,
    // cache control
    rom_en,
    rom_wen,
    rom_addr,
    rom_wdata,
    rom_read_data,    
    i_cached,
    //axi
    //ar
    i_arid         ,
    i_araddr       ,
    i_arlen        ,
    i_arsize       ,
    i_arburst      ,
    i_arlock       ,
    i_arcache      ,
    i_arprot       ,
    i_arvalid      ,
    i_arready      ,
    //r           
    i_rid          ,
    i_rdata        ,
    i_rresp        ,
    i_rlast        ,
    i_rvalid       ,
    i_rready       ,
    //aw          
    i_awid         ,
    i_awaddr       ,
    i_awlen        ,
    i_awsize       ,
    i_awburst      ,
    i_awlock       ,
    i_awcache      ,
    i_awprot       ,
    i_awvalid      ,
    i_awready      ,
    //w          
    i_wid          ,
    i_wdata        ,
    i_wstrb        ,
    i_wlast        ,
    i_wvalid       ,
    i_wready       ,
    //b           
    i_bid          ,
    i_bresp        ,
    i_bvalid       ,
    i_bready            
);

CacheL1Data u_dc(
    clk,
    rst,
    i_stall_req,
    d_stall_req,
    // cache control
    ram_en,
    ram_write_en,
    ram_addr,
    ram_size,
    ram_write_data,
    ram_read_data,
    d_cached,
    //axi
    //ar
    d_arid         ,
    d_araddr       ,
    d_arlen        ,
    d_arsize       ,
    d_arburst      ,
    d_arlock       ,
    d_arcache      ,
    d_arprot       ,
    d_arvalid      ,
    d_arready      ,
    //r           
    d_rid          ,
    d_rdata        ,
    d_rresp        ,
    d_rlast        ,
    d_rvalid       ,
    d_rready       ,
    //aw          
    d_awid         ,
    d_awaddr       ,
    d_awlen        ,
    d_awsize       ,
    d_awburst      ,
    d_awlock       ,
    d_awcache      ,
    d_awprot       ,
    d_awvalid      ,
    d_awready      ,
    //w          
    d_wid          ,
    d_wdata        ,
    d_wstrb        ,
    d_wlast        ,
    d_wvalid       ,
    d_wready       ,
    //b           
    d_bid          ,
    d_bresp        ,
    d_bvalid       ,
    d_bready             
);

AXI_crossbar u_crossbar (
  .aclk(clk),                    // input wire aclk
  .aresetn(rst),              // input wire aresetn
  .s_axi_awid({i_awid,d_awid}),        // input wire [7 : 0] s_axi_awid
  .s_axi_awaddr({i_awaddr,d_awaddr}),    // input wire [63 : 0] s_axi_awaddr
  .s_axi_awlen({i_awlen[3:0],d_awlen[3:0]}),      // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize({i_awsize,d_awsize}),    // input wire [5 : 0] s_axi_awsize
  .s_axi_awburst({i_awburst,d_awburst}),  // input wire [3 : 0] s_axi_awburst
  .s_axi_awlock({i_awlock,d_awlock}),    // input wire [3 : 0] s_axi_awlock
  .s_axi_awcache({i_awcache,d_awcache}),  // input wire [7 : 0] s_axi_awcache
  .s_axi_awprot({i_awprot,d_awprot}),    // input wire [5 : 0] s_axi_awprot
  .s_axi_awqos({i_awqos,d_awqos}),      // input wire [7 : 0] s_axi_awqos
  .s_axi_awvalid({i_awvalid,d_awvalid}),  // input wire [1 : 0] s_axi_awvalid
  .s_axi_awready({i_awready,d_awready}),  // output wire [1 : 0] s_axi_awready
  .s_axi_wid({i_wid,d_wid}),          // input wire [7 : 0] s_axi_wid
  .s_axi_wdata({i_wdata,d_wdata}),      // input wire [63 : 0] s_axi_wdata
  .s_axi_wstrb({i_wstrb,d_wstrb}),      // input wire [7 : 0] s_axi_wstrb
  .s_axi_wlast({i_wlast,d_wlast}),      // input wire [1 : 0] s_axi_wlast
  .s_axi_wvalid({i_wvalid,d_wvalid}),    // input wire [1 : 0] s_axi_wvalid
  .s_axi_wready({i_wready,d_wready}),    // output wire [1 : 0] s_axi_wready
  .s_axi_bid({i_bid,d_bid}),          // output wire [7 : 0] s_axi_bid
  .s_axi_bresp({i_bresp,d_bresp}),      // output wire [3 : 0] s_axi_bresp
  .s_axi_bvalid({i_bvalid,d_bvalid}),    // output wire [1 : 0] s_axi_bvalid
  .s_axi_bready({i_bready,d_bready}),    // input wire [1 : 0] s_axi_bready
  .s_axi_arid({i_arid,d_arid}),        // input wire [7 : 0] s_axi_arid
  .s_axi_araddr({i_araddr,d_araddr}),    // input wire [63 : 0] s_axi_araddr
  .s_axi_arlen({i_arlen[3:0],d_arlen[3:0]}),      // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize({i_arsize,d_arsize}),    // input wire [5 : 0] s_axi_arsize
  .s_axi_arburst({i_arburst,d_arburst}),  // input wire [3 : 0] s_axi_arburst
  .s_axi_arlock({i_arlock,d_arlock}),    // input wire [3 : 0] s_axi_arlock
  .s_axi_arcache({i_arcache,d_arcache}),  // input wire [7 : 0] s_axi_arcache
  .s_axi_arprot({i_arprot,d_arprot}),    // input wire [5 : 0] s_axi_arprot
  .s_axi_arqos({i_arqos,d_arqos}),      // input wire [7 : 0] s_axi_arqos
  .s_axi_arvalid({i_arvalid,d_arvalid}),  // input wire [1 : 0] s_axi_arvalid
  .s_axi_arready({i_arready,d_arready}),  // output wire [1 : 0] s_axi_arready
  .s_axi_rid({i_rid,d_rid}),          // output wire [7 : 0] s_axi_rid
  .s_axi_rdata({i_rdata,d_rdata}),      // output wire [63 : 0] s_axi_rdata
  .s_axi_rresp({i_rresp,d_rresp}),      // output wire [3 : 0] s_axi_rresp
  .s_axi_rlast({i_rlast,d_rlast}),      // output wire [1 : 0] s_axi_rlast
  .s_axi_rvalid({i_rvalid,d_rvalid}),    // output wire [1 : 0] s_axi_rvalid
  .s_axi_rready({i_rready,d_rready}),    // input wire [1 : 0] s_axi_rready
  .m_axi_awid(awid),        // output wire [3 : 0] m_axi_awid
  .m_axi_awaddr(awaddr),    // output wire [31 : 0] m_axi_awaddr
  .m_axi_awlen(awlen_t),      // output wire [3 : 0] m_axi_awlen
  .m_axi_awsize(awsize),    // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(awburst),  // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(awlock),    // output wire [1 : 0] m_axi_awlock
  .m_axi_awcache(awcache),  // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(awprot),    // output wire [2 : 0] m_axi_awprot
  .m_axi_awqos(awqos),      // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(awvalid),  // output wire [0 : 0] m_axi_awvalid
  .m_axi_awready(awready),  // input wire [0 : 0] m_axi_awready
  .m_axi_wid(wid),          // output wire [3 : 0] m_axi_wid
  .m_axi_wdata(wdata),      // output wire [31 : 0] m_axi_wdata
  .m_axi_wstrb(wstrb),      // output wire [3 : 0] m_axi_wstrb
  .m_axi_wlast(wlast),      // output wire [0 : 0] m_axi_wlast
  .m_axi_wvalid(wvalid),    // output wire [0 : 0] m_axi_wvalid
  .m_axi_wready(wready),    // input wire [0 : 0] m_axi_wready
  .m_axi_bid(bid),          // input wire [3 : 0] m_axi_bid
  .m_axi_bresp(bresp),      // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(bvalid),    // input wire [0 : 0] m_axi_bvalid
  .m_axi_bready(bready),    // output wire [0 : 0] m_axi_bready
  .m_axi_arid(arid),        // output wire [3 : 0] m_axi_arid
  .m_axi_araddr(araddr),    // output wire [31 : 0] m_axi_araddr
  .m_axi_arlen(arlen_t),      // output wire [3 : 0] m_axi_arlen
  .m_axi_arsize(arsize),    // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(arburst),  // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(arlock),    // output wire [1 : 0] m_axi_arlock
  .m_axi_arcache(arcache),  // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(arprot),    // output wire [2 : 0] m_axi_arprot
  .m_axi_arqos(arqos),      // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(arvalid),  // output wire [0 : 0] m_axi_arvalid
  .m_axi_arready(arready),  // input wire [0 : 0] m_axi_arready
  .m_axi_rid(rid),          // input wire [3 : 0] m_axi_rid
  .m_axi_rdata(rdata),      // input wire [31 : 0] m_axi_rdata
  .m_axi_rresp(rresp),      // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(rlast),      // input wire [0 : 0] m_axi_rlast
  .m_axi_rvalid(rvalid),    // input wire [0 : 0] m_axi_rvalid
  .m_axi_rready(rready)    // output wire [0 : 0] m_axi_rready
);

endmodule //cache