`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/funct.v"
`include "../../../include/opcode.v"
`include "../../../include/regimm.v"

module BranchGen (
    input       [`ADDR_BUS]     pc,
    input       [`INST_BUS]     inst,
    input       [`INST_OP_BUS]  op,
    input       [`FUNCT_BUS]    funct,
    input       [`REG_ADDR_BUS] rt,
    input       [`DATA_BUS]     reg_data_1,
    input       [`DATA_BUS]     reg_data_2,

    // from btb
    input                       btb_pre_token,
    input       [`ADDR_BUS]     btb_pre_addr,
    // to btb
    output                      btb_set,
    output      [`ADDR_BUS]     btb_set_pc,
    output                      btb_set_taken,
    output      [`ADDR_BUS]     btb_set_target,
    output  reg                 branch_is_error,

    // to IF
    output                      branch_flag,
    output      [`ADDR_BUS]     branch_addr,
    output  reg                 next_delayslot_flag_out,
    output  reg                 next_delayslot_pc_error
);
    
    //
    wire[`ADDR_BUS] addr_plus_4 = pc + 4;
    wire[25:0] jump_addr = inst[25:0];
    wire[`DATA_BUS] sign_ext_imm_sll2 = {{14{inst[15]}}, inst[15:0], 2'b00};


    reg [`ADDR_BUS] branch_addr_result;
    reg branch_occur;

    // branch_addr
    assign branch_addr = branch_addr_result;
    // branch_flag 
    assign branch_flag = btb_pre_token ? 
                        (branch_addr_result == btb_pre_addr ? 0 : 1) :
                        (addr_plus_4 == branch_addr_result ? 0 : 1);
    // btb_set_pc
    assign btb_set_pc = pc;
    // btb_set_target
    assign btb_set_target = branch_addr_result;
    // btb_set_taken
    assign btb_set_taken = branch_occur;
    // btb_set
    assign btb_set = branch_occur | btb_pre_token;

    reg is_branch_inst;

    // branch_addr_result
    always @(*) begin
        case (op)
            `OP_J, `OP_JAL: begin 
                branch_addr_result <= {addr_plus_4[31:28], jump_addr, 2'b0};
                branch_occur <= 1;
                is_branch_inst <= 1;
            end 
            `OP_SPECIAL, `OP_SPECIAL2: begin
                if(funct == `FUNCT_JR || funct == `FUNCT_JALR) begin 
                    branch_addr_result <= reg_data_1;
                    branch_occur <= 1;
                    is_branch_inst <= 1;
                end
                else begin
                    branch_addr_result <= addr_plus_4;
                    branch_occur <= 0;
                    is_branch_inst <= 0;
                end 
            end 
            `OP_BEQ: begin
                if (reg_data_1 == reg_data_2) begin
                    branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                    branch_occur <= 1;
                end
                else begin
                    branch_addr_result <= addr_plus_4;
                    branch_occur <= 0;
                end
                is_branch_inst <= 1;
            end 
            `OP_BGTZ: begin
                if (!reg_data_1[31] && reg_data_1) begin
                    branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                    branch_occur <= 1;
                end
                else begin
                    branch_addr_result <= addr_plus_4;
                    branch_occur <= 0;
                end
                is_branch_inst <= 1;
            end
            
            `OP_BLEZ: begin
                if (reg_data_1[31] || !reg_data_1) begin
                    branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                    branch_occur <= 1;
                end
                else begin
                    branch_addr_result <= addr_plus_4;
                    branch_occur <= 0;
                end
                is_branch_inst <= 1;
            end 
            `OP_BNE: begin
                if (reg_data_1 != reg_data_2) begin
                    branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                    branch_occur <= 1;
                end
                else begin
                    branch_addr_result <= addr_plus_4;
                    branch_occur <= 0;
                end
                is_branch_inst <= 1;
            end 
            `OP_REGIMM: begin
                case (rt)
                    `REGIMM_BLTZ, `REGIMM_BLTZAL: begin
                        if (reg_data_1[31]) begin
                            branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                            branch_occur <= 1;
                        end
                        else begin
                            branch_addr_result <= addr_plus_4;
                            branch_occur <= 0;
                        end
                        is_branch_inst <= 1;
                    end 
                    `REGIMM_BGEZ, `REGIMM_BGEZAL: begin
                        if (!reg_data_1[31]) begin
                            branch_addr_result <= addr_plus_4 + sign_ext_imm_sll2;
                            branch_occur <= 1;
                        end
                        else begin
                            branch_addr_result <= addr_plus_4;
                            branch_occur <= 0;
                        end
                        is_branch_inst <= 1;
                    end 
                    default: begin
                        branch_addr_result <= addr_plus_4;
                        branch_occur <= 0;
                        is_branch_inst <= 0;
                    end 
                endcase
            end
            default: begin
                branch_addr_result <= addr_plus_4;
                branch_occur <= 0;
                is_branch_inst <= 0;
            end 
        endcase
    end
    
    // next_delayslot_flag_out
    always @(*) begin
        if(btb_pre_token) begin
            next_delayslot_flag_out <= 0;
        end 
        else begin
            next_delayslot_flag_out <= is_branch_inst;
        end
    end

    // next_delayslot_pc_error
    always @(*) begin
        if(btb_pre_token) begin
            if(branch_occur) begin
                if (branch_addr_result != btb_pre_addr) begin
                    branch_is_error <= 1;
                    next_delayslot_pc_error <= 1;
                end 
                else begin
                    next_delayslot_pc_error <= 0;
                end
            end 
            else begin
                branch_is_error <= 1;
                next_delayslot_pc_error <= 1;
            end
        end 
        else begin
            next_delayslot_pc_error <= 0;
        end
    end


endmodule // BranchGen