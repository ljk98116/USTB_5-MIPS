`timescale 1ns / 1ps

`include "../../include/bus.v"
`include "../../include/exception.v"


module PipelineController (
    // stall request signals
    input                       request_from_id,
    input                       request_from_ex,
    // stall whole pipeline
    input                       stall_all,
    // exception signals
    input       [`DATA_BUS]     cp0_epc,
    input       [`EXC_TYPE_BUS] exception_type,

    // stall signals for each mid-stage
    output                      stall_pc,
    output                      stall_if,
    output                      stall_id,
    output                      stall_ex,
    output                      stall_mem,
    output                      stall_wb,

    // exception handle signals
    output                      flush,
    output  reg [`ADDR_BUS]     exc_pc
);
    // the stall signal of PC, IF, ID, EX, MEM, WB
    reg [`STALL_BUS] stall;

    // assign the output of the stall signal
    assign {stall_wb, stall_mem, stall_ex, stall_id, stall_if, stall_pc} = stall;

    always @(*) begin
        if (stall_all) begin
            stall <= 6'b111111;
        end
        else if (request_from_id) begin
            stall <= 6'b000111;
        end
        else if (request_from_ex) begin
            stall <= 6'b001111;
        end
        else begin
            stall <= 6'b000000;
        end
    end
    
    // generate the exception handle signals
    assign flush = (exception_type != `EXC_TYPE_NULL) ? 1 : 0;

    always @(*) begin
        if(exception_type == `EXC_TYPE_ERET) begin
            exc_pc <= cp0_epc;
        end
        else if (exception_type != `EXC_TYPE_NULL) begin
            exc_pc <= 32'hbfc0_0380;
        end
        else begin
            exc_pc <= `INIT_PC;
        end
    end

endmodule // PipelineController