`timescale 1ns / 1ps

`include "include/bus.v"

module mycpu_top(
    input         aclk,
    input         aresetn,

    input  [5:0]  ext_int,

    output [3:0]  arid,
    output [31:0] araddr,
    output [7:0]  arlen,
    output [2:0]  arsize,
    output [1:0]  arburst,
    output [1:0]  arlock,
    output [3:0]  arcache,
    output [2:0]  arprot,
    output        arvalid,
    input         arready,

    input  [3:0]  rid,
    input  [31:0] rdata,
    input  [1:0]  rresp,
    input         rlast,
    input         rvalid,
    output        rready,

    output [3:0]  awid,
    output [31:0] awaddr,
    output [7:0]  awlen,
    output [2:0]  awsize,
    output [1:0]  awburst,
    output [1:0]  awlock,
    output [3:0]  awcache,
    output [2:0]  awprot,
    output        awvalid,
    input         awready,

    output [3:0]  wid,
    output [31:0] wdata,
    output [3:0]  wstrb,
    output        wlast,
    output        wvalid,
    input         wready,

    input  [3:0]  bid,
    input  [1:0]  bresp,
    input         bvalid,
    output        bready,

    output [31:0] debug_wb_pc,
    output [3:0]  debug_wb_rf_wen,
    output [4:0]  debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);

    USTB_MIPS  u_USTB_MIPS (
        .aclk                    ( aclk                   ),
        .aresetn                 ( aresetn                ),
        .ext_int                 ( ext_int                ),
        .arready                 ( arready                ),
        .rid                     ( rid                    ),
        .rdata                   ( rdata                  ),
        .rresp                   ( rresp                  ),
        .rlast                   ( rlast                  ),
        .rvalid                  ( rvalid                 ),
        .awready                 ( awready                ),
        .wready                  ( wready                 ),
        .bid                     ( bid                    ),
        .bresp                   ( bresp                  ),
        .bvalid                  ( bvalid                 ),

        .arid                    ( arid                   ),
        .araddr                  ( araddr                 ),
        .arlen                   ( arlen                  ),
        .arsize                  ( arsize                 ),
        .arburst                 ( arburst                ),
        .arlock                  ( arlock                 ),
        .arcache                 ( arcache                ),
        .arprot                  ( arprot                 ),
        .arvalid                 ( arvalid                ),
        .rready                  ( rready                 ),
        .awid                    ( awid                   ),
        .awaddr                  ( awaddr                 ),
        .awlen                   ( awlen                  ),
        .awsize                  ( awsize                 ),
        .awburst                 ( awburst                ),
        .awlock                  ( awlock                 ),
        .awcache                 ( awcache                ),
        .awprot                  ( awprot                 ),
        .awvalid                 ( awvalid                ),
        .wid                     ( wid                    ),
        .wdata                   ( wdata                  ),
        .wstrb                   ( wstrb                  ),
        .wlast                   ( wlast                  ),
        .wvalid                  ( wvalid                 ),
        .bready                  ( bready                 ),
        .debug_pc_addr           ( debug_wb_pc            ),
        .debug_reg_write_en      ( debug_wb_rf_wen        ),
        .debug_reg_write_addr    ( debug_wb_rf_wnum       ),
        .debug_reg_write_data    ( debug_wb_rf_wdata      )
    );

endmodule