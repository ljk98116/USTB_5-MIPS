`timescale 1ns/1ps

module CacheL1Data_ram (
    input clk,
    input rst,
    input [11:0] addr,
    //data sram
    input [1:0] data_en,
    input [7:0] data_wen,
    input [31:0] data0_w,
    input [31:0] data1_w,
    output [31:0] data0_o,
    output [31:0] data1_o
);

CacheL1Data_one_way_ram way_0(
    clk,rst,addr,
    data_en[0],data_wen[3:0],data0_w,data0_o
);

CacheL1Data_one_way_ram way_1(
    clk,rst,addr,
    data_en[1],data_wen[7:4],data1_w,data1_o
);

endmodule //CacheL1Data_ram

module CacheL1Data_one_way_ram (
    input clk,
    input rst,
    input [11:0] addr,
    //data sram
    input data_en,
    input [3:0] data_wen,
    input [31:0] data_w,
    output [31:0] data_o   
);
  dcache_data_ram way_data (
    .clka(clk),    // input wire clka
    .rsta(~rst),    // input wire rsta
    .ena(data_en),      // input wire ena
    .wea(data_wen),      // input wire [3 : 0] wea
    .addra(addr),  // input wire [11 : 0] addra
    .dina(data_w),    // input wire [31:0] dina
    .douta(data_o)  // output wire [31:0] douta
  );

endmodule //CacheL1Data_ram