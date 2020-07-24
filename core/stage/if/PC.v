`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/exception.v"

module PC (
    input                       clk,
    input                       rst, //low allow

    input                       flush,
    input       [`ADDR_BUS]     exc_pc,
    input                       stall_pc,


    // from btb (branch prediction)
    input                       btb_pre_taken,
    input       [`ADDR_BUS]     btb_pre_addr,

    // from ID (branch control)
    input                       branch_flag, 
    input       [`ADDR_BUS]     branch_addr,

    // output to ID stage
    output  reg [`ADDR_BUS]     pc,
    output                      pre_taken_o,
    output      [`ADDR_BUS]     pre_addr_o,

    // output to ROM
    output  reg                 rom_en,
    output      [3  :0]         rom_write_en,
    output      [`ADDR_BUS]     rom_addr,
    output      [`DATA_BUS]     rom_write_data
);  
    assign rom_addr         = pc;
    assign rom_write_en     = 0;
    assign rom_write_data   = 0;
    assign pre_addr_o       = btb_pre_addr;
    assign pre_taken_o      = btb_pre_taken;


    // priority : flush > stall > branch > btb_pre_taken    //test
    // pc
    always @(posedge clk) begin
        if(!rom_en) begin
            pc <= `INIT_PC;
        end
        else if (flush)begin
            pc <= exc_pc;
        end
        else begin
            if (!stall_pc) begin
                if(branch_flag) begin
                    pc <= branch_addr;
                end 
                else if (btb_pre_taken) begin
                    pc <= btb_pre_addr;
                end
                else begin
                    pc <= pc + 4;
                end
            end else begin
                pc <= pc;
            end
        end
    end

    // rom control
    always @(posedge clk) begin
        rom_en = rst;
    end


endmodule //PC