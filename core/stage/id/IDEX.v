`timescale 1ns / 1ps

`include "../../../include/bus.v"

module IDEX (
    input                       clk,
    input                       rst,
    //control
    input                       flush,
    input                       stall_current_stage,
    input                       stall_next_stage,

    //from ID
    input                       delayslot_flag_i,
    input                       next_delayslot_flag_i,
    input       [`FUNCT_BUS]    ex_funct_i,
    input       [`SHAMT_BUS]    ex_shamt_i,
    input       [`DATA_BUS]     ex_operand_1_i,
    input       [`DATA_BUS]     ex_operand_2_i,
    input                       mem_read_flag_i,
    input                       mem_write_flag_i,
    input                       mem_sign_ext_flag_i,
    input       [ 3: 0]         mem_sel_i,
    input       [`DATA_BUS]     mem_write_data_i,
    input                       wb_reg_write_en_i,
    input       [`REG_ADDR_BUS] wb_reg_write_addr_i,
    input       [`ADDR_BUS]     current_pc_addr_i,
    input                       cp0_write_en_i,
    input                       cp0_read_en_i,
    input       [`CP0_ADDR_BUS] cp0_addr_i,
    input       [`DATA_BUS]     cp0_write_data_i,
    input       [`EXC_TYPE_BUS] exception_type_i,

    //output EX
    output                      delayslot_flag_o,
    output                      next_delayslot_flag_o,
    output      [`FUNCT_BUS]    ex_funct_o,
    output      [`SHAMT_BUS]    ex_shamt_o,
    output      [`DATA_BUS]     ex_operand_1_o,
    output      [`DATA_BUS]     ex_operand_2_o,
    output                      mem_read_flag_o,
    output                      mem_write_flag_o,
    output                      mem_sign_ext_flag_o,
    output      [ 3: 0]         mem_sel_o,
    output      [`DATA_BUS]     mem_write_data_o,
    output                      wb_reg_write_en_o,
    output      [`REG_ADDR_BUS] wb_reg_write_addr_o,
    output      [`ADDR_BUS]     current_pc_addr_o,
    output                      cp0_write_en_o,
    output                      cp0_read_en_o,
    output      [`CP0_ADDR_BUS] cp0_addr_o,
    output      [`DATA_BUS]     cp0_write_data_o,
    output      [`EXC_TYPE_BUS] exception_type_o
);

    PipelineDeliver #(1) ff_delayslot_flag(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        delayslot_flag_i, delayslot_flag_o
    );

    PipelineDeliver #(1) ff_next_delayslot_flag(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        next_delayslot_flag_i, next_delayslot_flag_o
    );

    PipelineDeliver #(`FUNCT_BUS_WIDTH) ff_ex_funct(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        ex_funct_i, ex_funct_o
    );

    PipelineDeliver #(`SHAMT_BUS_WIDTH) ff_ex_shamt(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        ex_shamt_i, ex_shamt_o
    );

    PipelineDeliver #(`DATA_BUS_WIDTH) ff_ex_operand_1(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        ex_operand_1_i, ex_operand_1_o
    );

    PipelineDeliver #(`DATA_BUS_WIDTH) ff_ex_operand_2(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        ex_operand_2_i, ex_operand_2_o
    );

    PipelineDeliver #(1) ff_mem_read_flag(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        mem_read_flag_i, mem_read_flag_o
    );

    PipelineDeliver #(1) ff_mem_write_flag(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        mem_write_flag_i, mem_write_flag_o
    );

    PipelineDeliver #(1) ff_mem_sign_ext_flag(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        mem_sign_ext_flag_i, mem_sign_ext_flag_o
    );

    PipelineDeliver #(4) ff_mem_sel(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        mem_sel_i, mem_sel_o
    );

    PipelineDeliver #(`DATA_BUS_WIDTH) ff_mem_write_data(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        mem_write_data_i, mem_write_data_o
    );

    PipelineDeliver #(1) ff_wb_reg_write_en(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        wb_reg_write_en_i, wb_reg_write_en_o
    );

    PipelineDeliver #(`REG_ADDR_BUS_WIDTH) wb_reg_write_addr(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        wb_reg_write_addr_i, wb_reg_write_addr_o
    );

    PipelineDeliver #(`ADDR_BUS_WIDTH) ff_current_pc_addr(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        current_pc_addr_i, current_pc_addr_o
    );

    PipelineDeliver #(1) ff_cp0_write_en(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        cp0_write_en_i, cp0_write_en_o
    );

    PipelineDeliver #(1) ff_cp0_read_en(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        cp0_read_en_i, cp0_read_en_o
    );

    PipelineDeliver #(`CP0_ADDR_BUS_WIDTH) wb_cp0_addr(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        cp0_addr_i, cp0_addr_o
    );

    PipelineDeliver #(`DATA_BUS_WIDTH) ff_cp0_write_data(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        cp0_write_data_i, cp0_write_data_o
    );

    PipelineDeliver #(`EXC_TYPE_BUS_WIDTH) ff_exception_type(
        clk, rst, flush,
        stall_current_stage, stall_next_stage,
        exception_type_i, exception_type_o
    );
endmodule