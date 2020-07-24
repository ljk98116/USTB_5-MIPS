`timescale 1ns / 1ps

`include "../../../include/bus.v"
`include "../../../include/segpos.v"

module ID (
    input                       delayslot_flag_in,
    // load related signals
    input                       load_related_1,
    input                       load_related_2,
    // from IF stage
    (*mark_debug = "true"*)input       [`ADDR_BUS]     pc,
    (*mark_debug = "true"*)input       [`INST_BUS]     inst,

    // from/to RegFile
    input       [`DATA_BUS]     reg_data_1,
    output                      reg_read_en_1,
    output      [`REG_ADDR_BUS] reg_addr_1,

    input       [`DATA_BUS]     reg_data_2,
    output                      reg_read_en_2,
    output      [`REG_ADDR_BUS] reg_addr_2,

    // from/to BTB
    input                       btb_pre_token,
    input       [`ADDR_BUS]     btb_pre_addr,
    output                      btb_set,
    output      [`ADDR_BUS]     btb_set_pc,
    output                      btb_set_taken,
    output      [`ADDR_BUS]     btb_set_target,
    output                      branch_is_error,

    // stall request
    output                      stall_request,

    //next delayslot is error(to rom selector_2_way)
    output                      next_delayslot_pc_error,

    // to IF stage
    output                      branch_flag,
    output      [`ADDR_BUS]     branch_addr,
    

    // to EX stage
    output      [`FUNCT_BUS]    ex_funct,
    output      [`SHAMT_BUS]    ex_shamt,

    output      [`DATA_BUS]     ex_operand_1,
    output      [`DATA_BUS]     ex_operand_2,
    output                      delayslot_flag_out,
    output                      next_delayslot_flag_out,

    // to MEM stage
    output                      mem_read_flag,
    output                      mem_write_flag,
    output                      mem_sign_ext_flag,
    output      [ 3: 0]         mem_sel,
    output      [`DATA_BUS]     mem_write_data,

    // to WB stage 
    output                      wb_reg_write_en,
    output      [`REG_ADDR_BUS] wb_reg_write_addr,

    // to cp0
    output                      cp0_write_en,
    output                      cp0_read_en,
    output      [`CP0_ADDR_BUS] cp0_addr,
    output      [`DATA_BUS]     cp0_write_data,

    //exception signal
    output      [`EXC_TYPE_BUS] exception_type,
    output      [`ADDR_BUS]     current_pc

);

    // extract information from instruction
    wire[`INST_OP_BUS]    inst_op     = inst[`SEG_OPCODE];
    wire[`REG_ADDR_BUS]   inst_rs     = inst[`SEG_RS];
    wire[`REG_ADDR_BUS]   inst_rt     = inst[`SEG_RT];
    wire[`REG_ADDR_BUS]   inst_rd     = inst[`SEG_RD];
    wire[`SHAMT_BUS]      inst_shamt  = inst[`SEG_SHAMT];
    wire[`FUNCT_BUS]      inst_funct  = inst[`SEG_FUNCT];
    wire[`HALF_DATA_BUS]  inst_imm    = inst[`SEG_IMM];
    
    //
    assign ex_shamt             =   inst_shamt;
    assign current_pc           =   pc;
    assign delayslot_flag_out   =   delayslot_flag_in;  
    assign stall_request        =   load_related_1 || load_related_2;

    FunctGen  u_FunctGen (
        .op                 (inst_op   ),
        .rt                 (inst_rt   ),
        .funct              (inst_funct),

        .funct_out          (ex_funct  )
    );

    OperandGen  u_OperandGen (
        .pc                 (pc          ),
        .op                 (inst_op     ),
        .rt                 (inst_rt     ),
        .funct              (inst_funct  ),
        .imm                (inst_imm    ),
        .reg_data_1         (reg_data_1  ),
        .reg_data_2         (reg_data_2  ),

        .operand_1          (ex_operand_1),
        .operand_2          (ex_operand_2)
    );

    RegGen  u_RegGen (
        .inst               (inst             ),
        .op                 (inst_op          ),
        .rs                 (inst_rs          ),
        .rt                 (inst_rt          ),
        .rd                 (inst_rd          ),

        .reg_read_en_1      (reg_read_en_1    ),
        .reg_read_en_2      (reg_read_en_2    ),
        .reg_addr_1         (reg_addr_1       ),
        .reg_addr_2         (reg_addr_2       ),
        .reg_write_en       (wb_reg_write_en  ),
        .reg_write_addr     (wb_reg_write_addr)
    );

    MemGen  u_MemGen (
        .op                 (inst_op          ),
        .reg_data_2         (reg_data_2       ),

        .mem_read_flag      (mem_read_flag    ),
        .mem_write_flag     (mem_write_flag   ),
        .mem_sign_ext_flag  (mem_sign_ext_flag),
        .mem_sel            (mem_sel          ),
        .mem_write_data     (mem_write_data   )
    );

    BranchGen  u_BranchGen (
        .pc                       ( pc                        ),
        .inst                     ( inst                      ),
        .op                       ( inst_op                   ),
        .funct                    ( inst_funct                ),
        .rt                       ( inst_rt                   ),
        .reg_data_1               ( reg_data_1                ),
        .reg_data_2               ( reg_data_2                ),
        .btb_pre_token            ( btb_pre_token             ),
        .btb_pre_addr             ( btb_pre_addr              ),

        .btb_set                  ( btb_set                   ),
        .btb_set_pc               ( btb_set_pc                ),
        .btb_set_taken            ( btb_set_taken             ),
        .btb_set_target           ( btb_set_target            ),
        .branch_flag              ( branch_flag               ),
        .branch_addr              ( branch_addr               ),
        .next_delayslot_flag_out  ( next_delayslot_flag_out   ),
        .next_delayslot_pc_error  ( next_delayslot_pc_error   ),
        .branch_is_error          ( branch_is_error)
    );

    CP0Gen  u_CP0Gen (
        .inst                    ( inst             ),
        .op                      ( inst_op          ),
        .rs                      ( inst_rs          ),
        .rd                      ( inst_rd          ),
        .reg_data_1              ( reg_data_1       ),

        .cp0_write_en            ( cp0_write_en     ),
        .cp0_read_en             ( cp0_read_en      ),
        .cp0_write_data          ( cp0_write_data   ),
        .cp0_addr                ( cp0_addr         )
    );

    wire eret_flag, syscall_flag, break_flag, 
        invalid_inst_flag, overflow_flag;
    assign exception_type ={
        eret_flag, /* ADE */ 1'b0,
        syscall_flag, break_flag, /* TP */ 1'b0,
        overflow_flag, invalid_inst_flag, /* IF */ 1'b0};
    
    ExceptionGen  u_ExceptionGen (
        .inst                    ( inst                ),
        .op                      ( inst_op                  ),
        .rs                      ( inst_rs                  ),
        .rt                      ( inst_rt                  ),
        .funct                   ( inst_funct               ),

        .eret_flag               ( eret_flag           ),
        .syscall_flag            ( syscall_flag        ),
        .break_flag              ( break_flag          ),
        .overflow_flag           ( overflow_flag       ),
        .invalid_inst_flag       ( invalid_inst_flag   )
    );


endmodule // ID