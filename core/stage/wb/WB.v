`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/opcode.v"

module WB (
    // input                       d_cached,
    // data from RAM
    (*mark_debug = "true"*)input       [`DATA_BUS]     ram_read_data,
    // memory accessing signalss
    input                       mem_read_flag_i,
    input                       mem_write_flag_i,
    input                       mem_sign_ext_flag_i,
    input       [`MEM_SEL_BUS]  mem_sel_i,
    // from MEM stage
    input       [`DATA_BUS]     result_i,
    input                       wb_reg_write_en_i,
    input       [`REG_ADDR_BUS] wb_reg_write_addr_i,
    input       [`ADDR_BUS]     current_pc_addr_i,
    input                       hilo_write_en_i,
    input       [`DATA_BUS]     hi_i,
    input       [`DATA_BUS]     lo_i,
    input                       cp0_write_en_i,
    input       [`DATA_BUS]     cp0_write_data_i,
    input       [`CP0_ADDR_BUS] cp0_addr_i,

    // HI & LO control
    output                      hilo_write_en_o,
    output      [`DATA_BUS]     hi_o,
    output      [`DATA_BUS]     lo_o,

    // cp0 control
    output                      cp0_write_en_o,
    output      [`DATA_BUS]     cp0_write_data_o,
    output      [`CP0_ADDR_BUS] cp0_addr_o,

    // regfile control
    output  reg [`DATA_BUS]     result_o,
    output                      wb_reg_write_en_o,
    output      [`REG_ADDR_BUS] wb_reg_write_addr_o,

    //debug signal
    output      [ 3: 0]         debug_reg_write_en_o,
    output      [`ADDR_BUS]     debug_pc_addr_o
    
);
    assign cp0_write_data_o = cp0_write_data_i;
    assign cp0_addr_o = cp0_addr_i;
    assign cp0_write_en_o = cp0_write_en_i;

    // HI & LO control
    assign hilo_write_en_o = hilo_write_en_i;
    assign hi_o = hi_i;
    assign lo_o = lo_i;

    //regfile control
    assign wb_reg_write_en_o = wb_reg_write_en_i;
    assign wb_reg_write_addr_o = wb_reg_write_addr_i;

    //debug signal
    assign debug_reg_write_en_o = {4{wb_reg_write_en_o}};
    assign debug_pc_addr_o = current_pc_addr_i;

    wire [`ADDR_BUS] address = result_i;
    

    // generate result_o signal
    always @(*) begin
        if(mem_read_flag_i) begin
            // if (d_cached) begin
            //     if(mem_sel_i == 4'b0001) begin
            //         result_o <= mem_sign_ext_flag_i ? {{24{ram_read_data[7]}}  , ram_read_data[7:0]}  : {24'b0, ram_read_data[7:0]};
            //     end
            //     else if (mem_sel_i == 4'b0011) begin
            //         result_o <= mem_sign_ext_flag_i ? {{16{ram_read_data[15]}}, ram_read_data[15:0]}  : {16'b0, ram_read_data[15:0]};
            //     end
            //     else if (mem_sel_i == 4'b1111) begin
            //         result_o <= ram_read_data;
            //     end
            //     else begin
            //         result_o <= 0;
            //     end
            // end
            // else begin
                if(mem_sel_i == 4'b0001) begin
                    case (address[1:0])
                        2'b00:   result_o <= mem_sign_ext_flag_i ? {{24{ram_read_data[7]}}, ram_read_data[7:0]} : {24'b0, ram_read_data[7:0]};
                        2'b01:   result_o <= mem_sign_ext_flag_i ? {{24{ram_read_data[15]}}, ram_read_data[15:8]} : {24'b0, ram_read_data[15:8]};
                        2'b10:   result_o <= mem_sign_ext_flag_i ? {{24{ram_read_data[23]}}, ram_read_data[23:16]} : {24'b0, ram_read_data[23:16]};
                        2'b11:   result_o <= mem_sign_ext_flag_i ? {{24{ram_read_data[31]}}, ram_read_data[31:24]} : {24'b0, ram_read_data[31:24]};
                        default: result_o <= 0;
                    endcase
                end
                else if(mem_sel_i == 4'b0011) begin
                    case (address[1:0])
                        2'b00:   result_o <= mem_sign_ext_flag_i ? {{16{ram_read_data[15]}}, ram_read_data[15:0]} : {16'b0, ram_read_data[15:0]};
                        2'b10:   result_o <= mem_sign_ext_flag_i ? {{16{ram_read_data[31]}}, ram_read_data[31:16]} : {16'b0, ram_read_data[31:16]};
                        default: result_o <= 0;
                    endcase
                end
                else if (mem_sel_i == 4'b1111) begin
                    case (address[1:0])
                        2'b00: result_o <= ram_read_data;
                        default: result_o <= 0;
                    endcase
                end
                else begin
                    result_o <= 0;
                end
            // end
            
        end
        else if(mem_write_flag_i) begin
            result_o <= 0;
        end
        else begin
            result_o <= result_i;
        end
    end


endmodule // WB