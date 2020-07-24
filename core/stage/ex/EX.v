`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/funct.v"
`include "../../../include/exception.v"

module EX (
    // from ID stage
    input       [`FUNCT_BUS]    funct,
    input       [`SHAMT_BUS]    shamt,
    input       [`DATA_BUS]     operand_1,
    input       [`DATA_BUS]     operand_2,
    input                       delayslot_flag_i,
    input                       mem_read_flag_i,
    input                       mem_write_flag_i,
    input                       mem_sign_ext_flag_i,
    input       [ 3: 0]         mem_sel_i,
    input       [`DATA_BUS]     mem_write_data_i,
    input                       wb_reg_write_en_i,
    input       [`REG_ADDR_BUS] wb_reg_write_addr_i,
    input       [`ADDR_BUS]     current_pc_addr_i,
    // HI & LO data
    input       [`DATA_BUS]     hi_i,
    input       [`DATA_BUS]     lo_i,
    // MULT & DIV
    input                       mult_div_done,
    input       [63: 0]         mult_div_result,
    // from cp0
    input                       cp0_write_en_i,
    input                       cp0_read_en_i,
    input       [`CP0_ADDR_BUS] cp0_addr_i,
    input       [`DATA_BUS]     cp0_write_data_i,
    input       [`DATA_BUS]     cp0_read_data_i,
    // exception
    input       [`EXC_TYPE_BUS] exception_type_i,

    // to ID stage (solve data hazards)
    output                      ex_load_flag,
    // stall request
    output reg                  stall_request,
    // to mem
    output                      mem_read_flag_o,
    output                      mem_write_flag_o,
    output                      mem_sign_ext_flag_o,
    output      [ 3: 0]         mem_sel_o,
    output      [`DATA_BUS]     mem_write_data_o,
    // to wb
    output      [`DATA_BUS]     result_o,
    output                      wb_reg_write_en_o,
    output      [`REG_ADDR_BUS] wb_reg_write_addr_o,
    // HI & LO control
    output reg                  hilo_write_en,
    output reg  [`DATA_BUS]     hi_o,
    output reg  [`DATA_BUS]     lo_o,
    // cp0 control
    output                      cp0_write_en_o,
    output      [`DATA_BUS]     cp0_write_data_o,
    output      [`CP0_ADDR_BUS] cp0_addr_o,
    // execption signal
    output      [`EXC_TYPE_BUS] exception_type_o,
    output                      delayslot_flag_o,
    output      [`ADDR_BUS]     current_pc_addr_o
    
);
    reg write_reg_en;
    reg [`DATA_BUS] result;
    // to ID stage
    assign ex_load_flag = mem_read_flag_i;
    assign result_o = result;

    // to MEM stage
    assign mem_read_flag_o = mem_read_flag_i;
    assign mem_sel_o = mem_sel_i;
    assign mem_sign_ext_flag_o = mem_sign_ext_flag_i;
    assign mem_write_data_o = mem_write_data_i;
    assign mem_write_flag_o = mem_write_flag_i;

    // to WB stage
    assign wb_reg_write_addr_o = wb_reg_write_addr_i;
    assign wb_reg_write_en_o = write_reg_en && !mem_write_flag_i;
    assign current_pc_addr_o = current_pc_addr_i;

    // to cp0
    assign cp0_write_en_o = cp0_write_en_i;
    assign cp0_addr_o = cp0_addr_i;
    assign cp0_write_data_o = cp0_write_data_i;

    assign delayslot_flag_o = delayslot_flag_i;

    // calculate the complement of operand_2
    wire [`DATA_BUS] operand_2_mux = (funct == `FUNCT_SUB || funct == `FUNCT_SUBU || funct == `FUNCT_SLT) ? (~operand_2 + 1) : operand_2;

    // sum of op_1 and op_2
    wire [`DATA_BUS] result_sum = operand_1 + operand_2_mux;

    // flag of operand_1 < operand_2    
    wire operand_1_lt_operand_2 = funct == `FUNCT_SLT ?
            // op1 is negative & op2 is positive
            ((operand_1[31] && !operand_2[31]) ||
                // op1 & op2 is positive, op1 - op2 is negative
                (!operand_1[31] && !operand_2[31] && result_sum[31]) ||
                // op1 & op2 is negative, op1 - op2 is negative
                (operand_1[31] && operand_2[31] && result_sum[31]))
            : (operand_1 < operand_2);

    // generate expection signal
    wire overflow_sum = ((!operand_1[31] && !operand_2_mux[31]) && result_sum[31]) || 
                        ((operand_1[31] && operand_2_mux[31]) && (!result_sum[31]));
    wire overflow_exc = exception_type_i[`EXC_TYPE_POS_OV] ? overflow_sum : 0;
    assign exception_type_o = {exception_type_i[7:3], overflow_exc, exception_type_i[1:0]};

    // result
    always @(*) begin
        case (funct)
            // logicout & JALR
            `FUNCT_NOR: result <= ~(operand_1 | operand_2);
            `FUNCT_XOR: result <= operand_1 ^ operand_2;
            `FUNCT_AND: result <= operand_1 & operand_2;
            `FUNCT_JALR, `FUNCT_OR: result <= operand_1 | operand_2;
            // comparison
            `FUNCT_SLT, `FUNCT_SLTU: result <= operand_1_lt_operand_2;
            // arithmetic
            `FUNCT_ADD, `FUNCT_ADDU,
            `FUNCT_SUB, `FUNCT_SUBU: result <= result_sum;
            // move
            `FUNCT_MOVN, `FUNCT_MOVZ: result <= operand_1;
            // mult
            `FUNCT2_MUL: result <= mult_div_result[31:0];
            // HI & LO
            `FUNCT_MFHI: result <= hi_i;
            `FUNCT_MFLO: result <= lo_i;
            // shift
            `FUNCT_SLL: result <= operand_2 << shamt;
            `FUNCT_SRL: result <= operand_2 >> shamt;
            `FUNCT_SRA: result <= ({32{operand_2[31]}} << (6'd32 - {1'b0, shamt})) | operand_2 >> shamt;
            `FUNCT_SLLV: result <= operand_2 << operand_1[4:0];
            `FUNCT_SRLV: result <= operand_2 >> operand_1[4:0];
            `FUNCT_SRAV: result <= ({32{operand_2[31]}} << (6'd32 - {1'b0, operand_1[4:0]})) | operand_2 >> operand_1[4:0];
            default: result <= cp0_read_en_i ? cp0_read_data_i : 0; 
        endcase
    end

    // control register write
    always @(*) begin
        case (funct)
            `FUNCT_ADD, `FUNCT_SUB: write_reg_en <= !overflow_sum;
            `FUNCT_MULT, `FUNCT_MULTU, `FUNCT_DIV,
            // instructions that not to write register file
            `FUNCT2_MADD, `FUNCT2_MADDU, `FUNCT2_MSUB, `FUNCT2_MSUBU,
            `FUNCT_DIVU, `FUNCT_JR: write_reg_en <= 0;
            `FUNCT_MOVN: write_reg_en <= (operand_2 == 32'h0) ? 0 : 1;
            `FUNCT_MOVZ: write_reg_en <= (operand_2 == 32'h0) ? 1 : 0;
            default: write_reg_en <= wb_reg_write_en_i;
        endcase
    end

    // stall request
    always @(*) begin
        case (funct)
            `FUNCT_MULT, `FUNCT_MULTU, 
            `FUNCT_DIV, `FUNCT_DIVU, `FUNCT2_MUL: begin
                stall_request <= !mult_div_done;
            end
            default: stall_request <= 0;
        endcase
    end

    // HI & LO control
    always @(*) begin
        case (funct)
            // multplication & division
            `FUNCT_MULT, `FUNCT_MULTU, 
            `FUNCT_DIV, `FUNCT_DIVU,
            `FUNCT2_MADD, `FUNCT2_MADDU, 
            `FUNCT2_MSUB, `FUNCT2_MSUBU: begin
                hilo_write_en <= 1;
                hi_o <= mult_div_result[63:32];
                lo_o <= mult_div_result[31: 0];
            end
            // HILO move inst
            `FUNCT_MTHI: begin
                hilo_write_en <= 1;
                hi_o <= operand_1;
                lo_o <= lo_i;
            end
            `FUNCT_MTLO: begin
                hilo_write_en <= 1;
                hi_o <= hi_i;
                lo_o <= operand_1;
            end
            default: begin
                hilo_write_en <= 0;
                hi_o <= hi_i;
                lo_o <= lo_i;
            end
        endcase
    end


endmodule // EX