`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/opcode.v"
`include "../../../include/regimm.v"
`include "../../../include/cp0.v"
`include "../../../include/segpos.v"

module RegGen(
    input       [`INST_BUS]     inst,
    input       [`INST_OP_BUS]  op,
    input       [`REG_ADDR_BUS] rs,
    input       [`REG_ADDR_BUS] rt,
    input       [`REG_ADDR_BUS] rd,

    output  reg                 reg_read_en_1,
    output  reg                 reg_read_en_2,
    output  reg [`REG_ADDR_BUS] reg_addr_1,
    output  reg [`REG_ADDR_BUS] reg_addr_2,
    output  reg                 reg_write_en,
    output  reg [`REG_ADDR_BUS] reg_write_addr
);
    
    // generate read address
    always @(*) begin
        case (op)
            // branch
            `OP_BEQ, `OP_BNE, `OP_BLEZ, `OP_BGTZ,
            // memory accessing
            `OP_SB, `OP_SH, `OP_SW,
            // r-type
            `OP_SPECIAL, `OP_SPECIAL2: begin
                reg_read_en_1   <= 1;
                reg_addr_1      <= rs;    
                reg_read_en_2   <= 1;
                reg_addr_2      <= rt;
            end
            // arithmetic & logic (immediate)
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU,
            `OP_ANDI, `OP_ORI, `OP_XORI,
            // memory accessing
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU: begin
                reg_read_en_1   <= 1;
                reg_addr_1      <= rs;    
                reg_read_en_2   <= 0;
                reg_addr_2      <= 0;
            end 
            // reg-imm
            `OP_REGIMM: begin
                case(rt)
                    `REGIMM_BLTZ, `REGIMM_BLTZAL,
                    `REGIMM_BGEZ, `REGIMM_BGEZAL: begin
                        reg_read_en_1   <= 1;
                        reg_addr_1      <= rs;    
                        reg_read_en_2   <= 0;
                        reg_addr_2      <= 0;
                    end
                    default: begin
                        reg_read_en_1   <= 0;
                        reg_addr_1      <= 0;    
                        reg_read_en_2   <= 0;
                        reg_addr_2      <= 0;
                    end
                endcase
            end
            `OP_CP0: begin
                reg_read_en_1   <= 1;
                reg_addr_1      <= rt;    
                reg_read_en_2   <= 0;
                reg_addr_2      <= 0;
            end
            default: begin              //LUI, JAL, J
                reg_read_en_1   <= 0;
                reg_addr_1      <= 0;    
                reg_read_en_2   <= 0;
                reg_addr_2      <= 0;
            end 
        endcase
    end


    // generate write address
    always @(*) begin
        case (op)
            `OP_SPECIAL, `OP_SPECIAL2: begin
                reg_write_en    <= 1;
                reg_write_addr  <= rd;
            end
            // load
            `OP_LB, `OP_LBU, `OP_LH, `OP_LHU, `OP_LW,
            // immediate
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU,
            `OP_ANDI, `OP_ORI, `OP_XORI, `OP_LUI: begin
                reg_write_en    <= 1;
                reg_write_addr  <= rt;
            end 
            `OP_JAL: begin
                reg_write_en    <= 1;
                reg_write_addr  <= 31;
            end
            `OP_REGIMM: begin
                case(rt) 
                    `REGIMM_BGEZAL, `REGIMM_BLTZAL: begin
                        reg_write_en    <= 1;
                        reg_write_addr  <= 31;
                    end
                    default: begin
                        reg_write_en    <= 0;
                        reg_write_addr  <= 0;
                    end
                endcase
            end
            `OP_CP0: begin
                if(rs == `CP0_MFC0 && inst[10 : 3] == 0) begin
                    reg_write_en    <= 1;
                    reg_write_addr  <= rt;
                end
                else begin
                    reg_write_en    <= 0;
                    reg_write_addr  <= 0;
                end
            end
            default: begin
                reg_write_en    <= 0;
                reg_write_addr  <= 0;
            end
        endcase
    end

endmodule // RegGen