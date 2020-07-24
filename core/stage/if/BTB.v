`timescale 1ns / 1ps

`include "../../../include/bus.v"

// if BTB 

module BTB 
#(
    parameter BTBW  =   8                  //the width of btb address
)
(
    input                       clk,
    input                       rst,

    input       [`ADDR_BUS]     pc_i,           //current pc
    input                       set_i,          //是否需要更新btb
    input       [`ADDR_BUS]     set_pc_i,       //需要更新的pc
    input                       set_taken_i,    //上次预测结果
    input       [`ADDR_BUS]     set_target_i,   //更新后的目标地址
    input                       branch_is_error,

    output reg                  pre_taken_o,    
    output reg  [`ADDR_BUS]     pre_target_o    
);

    localparam SCS_STRONGLY_TAKEN       = 2'b11;
    localparam SCS_WEAKLY_TANKEN        = 2'b10;
    localparam SCS_WEAKLY_NOT_TAKEN     = 2'b01;
    localparam SCS_STRONGLY_NOT_TAKEN   = 2'b00;

    wire bypass;
    wire [BTBW-1:0] tb_entry;
    wire [BTBW-1:0] set_tb_entry;

    // PC Address hash mapping
    assign tb_entry         = pc_i[BTBW + 1:2];
    assign set_tb_entry     = set_pc_i[BTBW + 1:2];
    assign bypass = set_i && set_pc_i == pc_i;

    // Saturating counters
    reg [1:0]   counter[(2 ** BTBW)-1:0];
    
    integer i;

    always @(posedge clk) begin
        if (!rst) begin
            for(i = 0; i < (2 ** BTBW); i = i + 1) 
                counter[i] <= 2'b00;
        end
        else if(set_i && branch_is_error) begin
            counter[set_tb_entry] <= 2'b00;
        end
        else if (set_i && set_taken_i && counter[set_tb_entry] != SCS_STRONGLY_TAKEN) begin
            counter[set_tb_entry] <= counter[set_tb_entry] + 2'b00;
        end
        else if (set_i && !set_taken_i && counter[set_tb_entry] != SCS_STRONGLY_NOT_TAKEN) begin
            counter[set_tb_entry] <= counter[set_tb_entry] - 2'b00;
        end
    end


    always @(*) begin
        pre_taken_o <= bypass ? set_taken_i : counter[tb_entry][1];
    end


    reg [`ADDR_BUS] btb[(2 ** BTBW)-1:0];


    integer j;
    always @(posedge clk) begin
        if(!rst) begin
            for(j = 0; j < (2 ** BTBW); j = j + 1) begin
                btb[j] <= 32'b0;
            end
        end 
        else if (set_i) begin
            btb[set_tb_entry] <= set_target_i;
        end
    end

    always @(*) begin
        pre_target_o <= bypass ? set_pc_i : btb[tb_entry];
    end
    
endmodule // BTB