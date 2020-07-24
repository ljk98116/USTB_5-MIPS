`timescale 1ns / 1ps

`include "include/bus.v"

module USTB_MIPS (
    input               aclk,
    input               aresetn,

    input       [5:0]   ext_int,

    output      [3:0]   arid,
    output      [31:0]  araddr,
    output      [7:0]   arlen,
    output      [2:0]   arsize,
    output      [1:0]   arburst,
    output      [1:0]   arlock,
    output      [3:0]   arcache,
    output      [2:0]   arprot,
    output              arvalid,
    input               arready,

    input       [3:0]   rid,
    input       [31:0]  rdata,
    input       [1:0]   rresp,
    input               rlast,
    input               rvalid,
    output              rready,

    output      [3:0]   awid,
    output      [31:0]  awaddr,
    output      [7:0]   awlen,
    output      [2:0]   awsize,
    output      [1:0]   awburst,
    output      [1:0]   awlock,
    output      [3:0]   awcache,
    output      [2:0]   awprot,
    output              awvalid,
    input               awready,

    output      [3:0]   wid,
    output      [31:0]  wdata,
    output      [3:0]   wstrb,
    output              wlast,
    output              wvalid,
    input               wready,

    input       [3:0]   bid,
    input       [1:0]   bresp,
    input               bvalid,
    output              bready,

    (*mark_debug = "true"*)output      [31:0]  debug_pc_addr,
    (*mark_debug = "true"*)output      [3:0]   debug_reg_write_en,
    (*mark_debug = "true"*)output      [4:0]   debug_reg_write_addr,
    (*mark_debug = "true"*)output      [31:0]  debug_reg_write_data
);

    wire [`ADDR_BUS] rom_addr, ram_addr;
    wire i_cached, d_cached;
    wire halt;
    wire [`DATA_BUS] rom_read_data, ram_read_data, rom_wdata, ram_wdata;
    wire rom_en, ram_en;
    wire [`MEM_SEL_BUS] rom_wen, ram_wen;
    wire [31:0]  debug_pc_addr_conn;
    wire [3:0]   debug_reg_write_en_conn;
    wire [4:0]   debug_reg_write_addr_conn;
    wire [31:0]  debug_reg_write_data_conn;
    wire [2:0] ram_size;

    assign debug_pc_addr = debug_pc_addr_conn;
    assign debug_reg_write_en = halt ? 0 : debug_reg_write_en_conn;
    assign debug_reg_write_data = debug_reg_write_data_conn;
    assign debug_reg_write_addr = debug_reg_write_addr_conn;
    wire expection_flag;


    Core  u_Core (
        .clk                     ( aclk                         ),
        .rst                     ( aresetn                      ),
        .halt                    ( halt                         ),
        .interrupt               ( ext_int                      ),
        .rom_read_data           ( rom_read_data                ),
        .ram_read_data           ( ram_read_data                ),

        .i_cached                ( i_cached                     ),
        .d_cached                ( d_cached                     ),
        .rom_en                  ( rom_en                       ),
        .rom_write_en            ( rom_wen                      ),
        .rom_addr                ( rom_addr                     ),
        .rom_write_data          ( rom_wdata                    ),
        .ram_en                  ( ram_en                       ),
        .ram_write_en            ( ram_wen                      ),
        .ram_addr                ( ram_addr                     ),
        .ram_write_data          ( ram_wdata                    ),
        .ram_size                ( ram_size                     ), 
        .debug_reg_write_en      ( debug_reg_write_en_conn      ),
        .debug_reg_write_addr    ( debug_reg_write_addr_conn    ),
        .debug_reg_write_data    ( debug_reg_write_data_conn    ),
        .debug_pc_addr           ( debug_pc_addr_conn           ),
        .debug_expection_flag    ( expection_flag               )
    );


    Cache  u_Cache (
        .clk                     ( aclk             ),
        .rst                     ( aresetn          ),
        .rom_en                  ( rom_en           ),
        .rom_wen                 ( rom_wen          ),
        .rom_addr                ( rom_addr         ),
        .rom_wdata               ( rom_wdata        ),
        .i_cached                ( i_cached         ),
        .ram_en                  ( ram_en           ),
        .ram_write_en            ( ram_wen          ),
        .ram_addr                ( ram_addr         ),
        .ram_write_data          ( ram_wdata        ),
        .ram_size                ( ram_size         ),
        .d_cached                ( d_cached         ),
        .exception_flag          ( expection_flag   ),
        .arready                 ( arready          ),
        .rid                     ( rid              ),
        .rdata                   ( rdata            ),
        .rresp                   ( rresp            ),
        .rlast                   ( rlast            ),
        .rvalid                  ( rvalid           ),
        .awready                 ( awready          ),
        .wready                  ( wready           ),
        .bid                     ( bid              ),
        .bresp                   ( bresp            ),
        .bvalid                  ( bvalid           ),

        .halt                    ( halt             ),
        .rom_read_data           ( rom_read_data    ),
        .ram_read_data           ( ram_read_data    ),
        .arid                    ( arid             ),
        .araddr                  ( araddr           ),
        .arlen                   ( arlen            ),
        .arsize                  ( arsize           ),
        .arburst                 ( arburst          ),
        .arlock                  ( arlock           ),
        .arcache                 ( arcache          ),
        .arprot                  ( arprot           ),
        .arvalid                 ( arvalid          ),
        .rready                  ( rready           ),
        .awid                    ( awid             ),
        .awaddr                  ( awaddr           ),
        .awlen                   ( awlen            ),
        .awsize                  ( awsize           ),
        .awburst                 ( awburst          ),
        .awlock                  ( awlock           ),
        .awcache                 ( awcache          ),
        .awprot                  ( awprot           ),
        .awvalid                 ( awvalid          ),
        .wid                     ( wid              ),
        .wdata                   ( wdata            ),
        .wstrb                   ( wstrb            ),
        .wlast                   ( wlast            ),
        .wvalid                  ( wvalid           ),
        .bready                  ( bready           )
    );

endmodule