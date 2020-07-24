`timescale 1ns / 1ps

`include "../../../include/bus.v"

module Selector_2_way(
    input       [`INST_BUS]     inst_in,       
    input                       select,
    output      [`INST_BUS]     inst_out
);
    assign inst_out = select ? 0 : inst_in;
endmodule
