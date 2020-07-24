`timescale 1ns / 1ps

`include "../../../include/funct.v"
`include "../../../include/opcode.v"
`include "../../../include/bus.v"
`include "../../../include/regimm.v"

module FunctGen (
    input       [`INST_OP_BUS]  op,
    input       [`REG_ADDR_BUS] rt,
    input       [`FUNCT_BUS]    funct,
    
    output  reg [`FUNCT_BUS]    funct_out
);

    always @(*) begin
        // funct_out <= `FUNCT_NOP;
        case (op)
            `OP_SPECIAL : funct_out <= funct;

            `OP_SPECIAL2: begin
                case (funct)
                    `FUNCT_MADD:    funct_out <= `FUNCT2_MADD;
                    `FUNCT_MADDU:   funct_out <= `FUNCT2_MADDU;
                    `FUNCT_MUL:     funct_out <= `FUNCT2_MUL;
                    `FUNCT_MSUB:    funct_out <= `FUNCT2_MSUB;
                    `FUNCT_MSUBU:   funct_out <= `FUNCT2_MSUBU;
                    `FUNCT_CLZ:     funct_out <= `FUNCT2_CLZ;
                    `FUNCT_CLO:     funct_out <= `FUNCT2_CLO;
                    default:        funct_out <= `FUNCT_NOP;
                endcase
            end

            `OP_ANDI: funct_out <= `FUNCT_AND;

            `OP_LUI, `OP_ORI, `OP_JAL: funct_out <= `FUNCT_OR;

            `OP_XORI: funct_out <= `FUNCT_XOR;

            `OP_LB, `OP_LBU, `OP_LH, `OP_LHU, `OP_LW,
            `OP_SB, `OP_SH, `OP_SW, `OP_ADDI: funct_out <= `FUNCT_ADD;

            `OP_ADDIU: funct_out <= `FUNCT_ADDU;

            `OP_SLTI: funct_out <= `FUNCT_SLT;

            `OP_SLTIU: funct_out <= `FUNCT_SLTU;

            `OP_REGIMM: begin
                case(rt)
                    `REGIMM_BLTZAL, `REGIMM_BGEZAL: funct_out <= `FUNCT_OR;
                    default: funct_out <= `FUNCT_NOP;
                endcase
            end

            default: funct_out <= `FUNCT_NOP;
        endcase
    end
    
endmodule // FunctGen