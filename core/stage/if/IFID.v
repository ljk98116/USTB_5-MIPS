`timescale 1ns / 1ps

`include "../../../include/bus.v"

module IFID (
    input                       clk,
    input                       rst,
    
    //control
    input                       flush,
    input                       stall_current_stage,
    input                       stall_next_stage,

    //from IF
    input       [`ADDR_BUS]     if_pc,
    input       [`INST_BUS]     if_inst,
    input                       if_pre_taken,
    input       [`ADDR_BUS]     if_pre_addr,

    //output ID
    output      [`ADDR_BUS]     id_pc,
    output      [`INST_BUS]     id_inst,
    output                      id_pre_taken,
    output      [`ADDR_BUS]     id_pre_addr
);

    PipelineDeliver #(`ADDR_BUS_WIDTH) ff_pc(
        clk, rst, flush,
        stall_current_stage, stall_next_stage, 
        if_pc, id_pc
    );

    PipelineDeliver #(`INST_BUS_WIDTH) ff_inst(
        clk, rst, flush,
        stall_current_stage, stall_next_stage, 
        if_inst, id_inst
    );

    PipelineDeliver #(1) ff_pre_taken(
        clk, rst, flush,
        stall_current_stage, stall_next_stage, 
        if_pre_taken, id_pre_taken
    );

    PipelineDeliver #(`ADDR_BUS_WIDTH) ff_pre_addr(
        clk, rst, flush,
        stall_current_stage, stall_next_stage, 
        if_pre_addr, id_pre_addr
    );
    
endmodule // IFID