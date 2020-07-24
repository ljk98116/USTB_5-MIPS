`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/exception.v"
`include "../../../include/cp0.v"

module MEM (
    // memory accessing signals
    input                       mem_read_flag_i,
    input                       mem_write_flag_i,
    input                       mem_sign_ext_flag_i,
    input       [`MEM_SEL_BUS]  mem_sel_i,
    input       [`DATA_BUS]     mem_write_data,
    // from EX stage
    input       [`DATA_BUS]     result_i,
    input                       wb_reg_write_en_i,
    input       [`REG_ADDR_BUS] wb_reg_write_addr_i,
    input                       delayslot_flag_i,
    input       [`ADDR_BUS]     current_pc_addr_i,
    input                       hilo_write_en_i,
    input       [`DATA_BUS]     hi_i,
    input       [`DATA_BUS]     lo_i,
    input                       cp0_write_en_i,
    input       [`DATA_BUS]     cp0_write_data_i,
    input       [`CP0_ADDR_BUS] cp0_addr_i,
    // exception signalss
    input       [`EXC_TYPE_BUS] exception_type_i,
    input       [`DATA_BUS]     cp0_status_i,
    input       [`DATA_BUS]     cp0_cause_i,
    input       [`DATA_BUS]     cp0_epc_i,

    // RAM contril singals
    output                      ram_en,
    output      [`MEM_SEL_BUS]  ram_write_en,
    output      [`ADDR_BUS]     ram_addr,
    output  reg [`DATA_BUS]     ram_write_data,
    output      [2:0]           ram_size,
    // to ID stage
    output                      mem_load_flag,
    // to WB stage
    output                      mem_read_flag_o,
    output                      mem_write_flag_o,
    output                      mem_sign_ext_flag_o,
    output      [`MEM_SEL_BUS]  mem_sel_o,
    output      [`DATA_BUS]     result_o,
    output                      wb_reg_write_en_o,
    output      [`REG_ADDR_BUS] wb_reg_write_addr_o,
    output                      delayslot_flag_o,
    (*mark_debug = "true"*)output      [`ADDR_BUS]     current_pc_addr_o,
    output                      hilo_write_en_o,
    output      [`DATA_BUS]     hi_o,
    output      [`DATA_BUS]     lo_o,
    output                      cp0_write_en_o,
    output      [`DATA_BUS]     cp0_write_data_o,
    output      [`CP0_ADDR_BUS] cp0_addr_o,
    // exception signalss
    (*mark_debug = "true"*)output  reg [`EXC_TYPE_BUS] exception_type_o,
    output      [`ADDR_BUS]     cp0_epc_o,
    output  reg [`DATA_BUS]     cp0_badvaddr_write_data_o
);

    reg [`MEM_SEL_BUS] ram_write_sel;

    // to ID stage
    assign mem_load_flag = mem_read_flag_i;

    // to WB stage
    assign current_pc_addr_o = current_pc_addr_i;
    assign mem_read_flag_o = mem_read_flag_i;
    assign mem_write_flag_o = mem_write_flag_i;
    assign mem_sign_ext_flag_o = mem_sign_ext_flag_i;
    assign mem_sel_o = mem_sel_i;
    assign result_o = result_i;
    assign wb_reg_write_addr_o = wb_reg_write_addr_i;
    assign wb_reg_write_en_o = wb_reg_write_en_i;
    
    // HI & LO control
    assign hilo_write_en_o = hilo_write_en_i;
    assign hi_o = hi_i;
    assign lo_o = lo_i;

    // CP0 control
    assign cp0_write_data_o = cp0_write_data_i;
    assign cp0_addr_o = cp0_addr_i;
    assign cp0_write_en_o = cp0_write_en_i;

    wire [`ADDR_BUS] address = result_i;

    // generate ram_en signal
    assign ram_en = ((mem_write_flag_i || mem_read_flag_i) && exception_type_o == `EXC_TYPE_NULL) ? 1 : 0;

    // generate ram_write_en signal
    assign ram_write_en = mem_write_flag_i ? ram_write_sel : 0;

    // generate ram_addr signal
    assign ram_addr = mem_write_flag_i || mem_read_flag_i ? address : 0;

    // generate ram_sel signal
    assign ram_size = (mem_sel_i == 4'b0001) ? 3'b000 : 
                      (mem_sel_i == 4'b0011) ? 3'b001 : 3'b010;

    // generate ram_write_sel signal
    always @(*) begin
        if(mem_write_flag_i) begin
            if(mem_sel_i == 4'b0001) begin //byte
                case (address[1:0])
                    2'b00:   ram_write_sel <= 4'b0001; 
                    2'b01:   ram_write_sel <= 4'b0010;
                    2'b10:   ram_write_sel <= 4'b0100;
                    2'b11:   ram_write_sel <= 4'b1000;
                    default: ram_write_sel <= 4'b0000;
                endcase
            end 
            else if (mem_sel_i == 4'b0011) begin
                case (address[1:0])
                    2'b00:   ram_write_sel <= 4'b0011; 
                    2'b10:   ram_write_sel <= 4'b1100;
                    default: ram_write_sel <= 4'b0000;
                endcase
            end
            else if (mem_sel_i == 4'b1111) begin
                case (address[1:0])
                    2'b00:   ram_write_sel <= 4'b1111;
                    default: ram_write_sel <= 4'b0000;
                endcase
            end
            else begin
                ram_write_sel <= 4'b0000;
            end
        end
        else begin
            ram_write_sel <= 4'b0000;
        end
    end

    // generate ram_write_data signal
    always @(*) begin
        if(mem_write_flag_i) begin
            if(mem_sel_i == 4'b0001) begin
                case (address[1:0])
                    2'b00:   ram_write_data <= mem_write_data;
                    2'b01:   ram_write_data <= mem_write_data << 8;
                    2'b10:   ram_write_data <= mem_write_data << 16;
                    2'b11:   ram_write_data <= mem_write_data << 24;
                    default: ram_write_data <= 0;
                endcase
            end
            else if (mem_sel_i == 4'b0011) begin
                case (address[1:0])
                    2'b00:   ram_write_data <= mem_write_data;
                    2'b10:   ram_write_data <= mem_write_data << 16;
                    default: ram_write_data <= 0;
                endcase
            end
            else if (mem_sel_i == 4'b1111) begin
                case (address[1:0])
                    2'b00: ram_write_data <= mem_write_data;
                    default: ram_write_data <= 0;
                endcase
            end
            else begin
                ram_write_data <= 0;
            end
        end 
        else begin
            ram_write_data <= 0;
        end
    end

    // generate exception signalss
    reg adel_flag, ades_flag;
    assign cp0_epc_o = cp0_epc_i;
    assign delayslot_flag_o = delayslot_flag_i;
    assign int_occured = |(cp0_cause_i[`CP0_SEG_INT] & cp0_status_i[`CP0_SEG_IM]);
    assign int_enabled = !cp0_status_i[`CP0_SEG_EXL] && cp0_status_i[`CP0_SEG_IE];

    // adel, ades
    always @(*) begin
        if(|current_pc_addr_i[1:0]) begin
            {adel_flag, ades_flag} <= 2'b10;
            cp0_badvaddr_write_data_o <= current_pc_addr_i;
        end
        else if(mem_sel_i == 4'b0011 && address[0]) begin
            {adel_flag, ades_flag} <= {mem_read_flag_i, mem_write_flag_i};
            cp0_badvaddr_write_data_o <= address;
        end
        else if (mem_sel_i == 4'b1111 && |address[1:0]) begin
            {adel_flag, ades_flag} <= {mem_read_flag_i, mem_write_flag_i};
            cp0_badvaddr_write_data_o <= address;
        end
        else begin
            {adel_flag, ades_flag} <= 2'b00;
            cp0_badvaddr_write_data_o <= 0;
        end
    end

    // exception_type_o
    always @(*) begin
        if(int_occured && int_enabled) begin
            exception_type_o <= `EXC_TYPE_INT;
        end
        else if (|current_pc_addr_i[1:0]) begin
            exception_type_o <= `EXC_TYPE_IF;
        end
        else if (exception_type_i[`EXC_TYPE_POS_RI]) begin
            exception_type_o <= `EXC_TYPE_RI;
        end 
        else if (exception_type_i[`EXC_TYPE_POS_OV]) begin
            exception_type_o <= `EXC_TYPE_OV;
        end
        else if (exception_type_i[`EXC_TYPE_POS_BP]) begin
            exception_type_o <= `EXC_TYPE_BP;
        end
        else if (exception_type_i[`EXC_TYPE_POS_SYS]) begin
            exception_type_o <= `EXC_TYPE_SYS;
        end
        else if (adel_flag) begin
            exception_type_o <= `EXC_TYPE_ADEL;
        end
        else if (ades_flag) begin
            exception_type_o <= `EXC_TYPE_ADES;
        end
        else if (exception_type_i[`EXC_TYPE_POS_ERET]) begin
            exception_type_o <= `EXC_TYPE_ERET;
        end
        else begin
            exception_type_o <= `EXC_TYPE_NULL;
        end
    end



endmodule // MEM