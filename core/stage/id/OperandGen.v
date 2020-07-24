`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/opcode.v"
`include "../../../include/funct.v"
`include "../../../include/regimm.v"

module OperandGen (
    input       [`ADDR_BUS]       pc,
    input       [`INST_OP_BUS]    op,
    input       [`REG_ADDR_BUS]   rt,
    input       [`FUNCT_BUS]      funct,
    input       [`HALF_DATA_BUS]  imm,
    input       [`DATA_BUS]       reg_data_1,
    input       [`DATA_BUS]       reg_data_2,

    output  reg [`DATA_BUS]       operand_1,
    output  reg [`DATA_BUS]       operand_2
);
    // calculate link addresss
    wire[`ADDR_BUS] link_addr = pc + 8;

    // extract immediate from instructions
    wire[`DATA_BUS] zero_ext_imm    = {16'b0, imm};
    wire[`DATA_BUS] zero_ext_imm_hi = {imm, 16'b0};
    wire[`DATA_BUS] sign_ext_imm    = {{16{imm[15]}}, imm};

    // generate operand_1
    always @(*) begin
        case (op)
            `OP_SPECIAL: begin
                operand_1 <= funct == `FUNCT_JALR ? link_addr : reg_data_1;
            end 
            // immediate
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU,
            `OP_ANDI, `OP_ORI, `OP_XORI, `OP_LUI,
            // memory accessing
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU,
            `OP_LHU, `OP_SB, `OP_SH, `OP_SW,
            `OP_SPECIAL2: begin
                operand_1 <= reg_data_1;
            end
            `OP_REGIMM: begin
                operand_1 <= rt == `REGIMM_BLTZAL || rt == `REGIMM_BGEZAL ? link_addr : 0;
            end
            `OP_JAL: begin
                operand_1 <= link_addr;
            end
            default: begin              //LUI
                operand_1 <= 0;
            end
        endcase
    end

    // generate operand_2
    always @(*) begin
        case (op)
            `OP_LUI: begin
                operand_2 <= zero_ext_imm_hi;
            end
            // arithmetic & logic (immediate)
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU,
            // memory accessing
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU,
            `OP_LHU, `OP_SB, `OP_SH, `OP_SW: begin
            operand_2 <= sign_ext_imm;
            end
            `OP_SPECIAL: begin
                operand_2 <= reg_data_2;
            end
            `OP_XORI, `OP_ANDI, `OP_ORI: begin
                operand_2 <= zero_ext_imm;
            end 
            default: begin
                operand_2 <= 0;
            end
        endcase
    end


endmodule // OperandGen