`timescale 1ns / 1ps

`include "../include/bus.v"

module Core(
    input                         clk,
    input                         rst,
    input                         halt,
    input       [ 5: 0]           interrupt,
    // ROM control
    output                        rom_en,
    output      [`MEM_SEL_BUS]    rom_write_en,
    output      [`ADDR_BUS]       rom_addr,
    input       [`DATA_BUS]       rom_read_data,
    output      [`DATA_BUS]       rom_write_data,
    // RAM control
    output                        ram_en,
    output      [`MEM_SEL_BUS]    ram_write_en,
    output      [`ADDR_BUS]       ram_addr,
    input       [`DATA_BUS]       ram_read_data,
    output      [`DATA_BUS]       ram_write_data,
    output      [2:0]             ram_size,
    // cache control
    output                        i_cached,
    output                        d_cached,
    // debug signals
    output      [ 3: 0]           debug_reg_write_en,
    output      [`REG_ADDR_BUS]   debug_reg_write_addr,
    output      [`DATA_BUS]       debug_reg_write_data,
    output      [`ADDR_BUS]       debug_pc_addr,
    // expection flag
    output                        debug_expection_flag
);

    //stall signals
    wire stall_pc_conn, stall_if_conn, stall_id_conn,
        stall_ex_conn, stall_mem_conn, stall_wb_conn;

    // to PC stage
    wire [`ADDR_BUS] pc_branch_addr, pc_btb_pre_addr;
    wire pc_branch_flag, pc_btb_pre_taken;

    // to IFID stage
    wire [`ADDR_BUS] ifid_pc, ifid_pre_addr, pc_exc_pc;
    wire ifid_pre_taken;
    
    // expection flag
    wire flush;
    assign debug_expection_flag = flush;

    // to mmu
    wire [`ADDR_BUS] mmu_rom_addr;

    PC  u_PC (
        .clk                     ( clk              ),
        .rst                     ( rst              ),
        .flush                   ( flush            ),
        .exc_pc                  ( pc_exc_pc        ),
        .stall_pc                ( stall_pc_conn    ),
        .btb_pre_taken           ( pc_btb_pre_taken ),
        .btb_pre_addr            ( pc_btb_pre_addr  ),
        .branch_flag             ( pc_branch_flag   ),
        .branch_addr             ( pc_branch_addr   ),

        .pc                      ( ifid_pc          ),
        .pre_taken_o             ( ifid_pre_taken   ),
        .pre_addr_o              ( ifid_pre_addr    ),
        .rom_en                  ( rom_en           ),
        .rom_write_en            ( rom_write_en     ),
        .rom_addr                ( mmu_rom_addr     ),
        .rom_write_data          ( rom_write_data   )
    );

    // to BTB stage
    wire btb_set, btb_set_taken, btb_branch_is_error;
    wire [`ADDR_BUS] btb_set_pc, btb_set_target;


    BTB  #(6) u_BTB (
        .clk                     ( clk              ),
        .rst                     ( rst              ),
        .pc_i                    ( ifid_pc          ),
        .set_i                   ( btb_set        ),
        .set_pc_i                ( btb_set_pc     ),
        .set_taken_i             ( btb_set_taken  ),
        .set_target_i            ( btb_set_target ),
        .branch_is_error         ( btb_branch_is_error),

        .pre_taken_o             ( pc_btb_pre_taken ),
        .pre_target_o            ( pc_btb_pre_addr  )
    );

    // select
    wire [`INST_BUS] ifid_inst;
    wire if_next_delayslot_pc_error;

    Selector_2_way  u_Selector_2_way (
        .inst_in                 ( rom_read_data              ),
        .select                  ( if_next_delayslot_pc_error ),

        .inst_out                ( ifid_inst                  )
    );

    // to ID stage
    wire [`ADDR_BUS] id_pc, id_pre_addr;
    wire [`INST_BUS] id_inst;
    wire id_pre_taken;

    IFID  u_IFID (
        .clk                     ( clk                   ),
        .rst                     ( rst                   ),
        .flush                   ( flush                 ),
        .stall_current_stage     ( stall_if_conn         ),
        .stall_next_stage        ( stall_id_conn         ),
        .if_pc                   ( ifid_pc               ),
        .if_inst                 ( ifid_inst             ),
        .if_pre_taken            ( ifid_pre_taken        ),
        .if_pre_addr             ( ifid_pre_addr         ),

        .id_pc                   ( id_pc                 ),
        .id_inst                 ( id_inst               ),
        .id_pre_taken            ( id_pre_taken          ),
        .id_pre_addr             ( id_pre_addr           )
    );


    // to ID stage
    wire id_delayslot_flag_in, id_load_related_1, id_load_related_2;
    wire [`DATA_BUS] id_reg_data_1, id_reg_data_2;
    
    // to RegFile
    wire reg_read_en_1, reg_read_en_2;
    wire [`REG_ADDR_BUS] reg_read_addr_1, reg_read_addr_2;

    // to pipelinecontroller
    wire request_from_id, request_from_ex;

    // to IDEX
    wire [`ADDR_BUS] idex_current_pc;
    wire [`REG_ADDR_BUS] idex_wb_reg_write_addr;
    wire [`FUNCT_BUS] idex_funct;
    wire [`SHAMT_BUS] idex_shamt;
    wire [`DATA_BUS] idex_operand_1, idex_operand_2, idex_mem_write_data, idex_cp0_write_data;
    wire idex_delayslot_flag_out, idex_next_delayslot_flag_out, idex_mem_read_flag,
        idex_mem_write_flag, idex_mem_sign_ext_flag, idex_wb_reg_write_en, 
        idex_cp0_write_en, idex_cp0_read_en;
    wire [`MEM_SEL_BUS] idex_mem_sel;
    wire [`CP0_ADDR_BUS] idex_cp0_addr;
    wire [`EXC_TYPE_BUS] idex_exception_type;

    ID  u_ID (
        .delayslot_flag_in        ( id_delayslot_flag_in        ),
        .load_related_1           ( id_load_related_1           ),
        .load_related_2           ( id_load_related_2           ),
        .pc                       ( id_pc                       ),
        .inst                     ( id_inst                     ),
        .reg_data_1               ( id_reg_data_1               ),
        .reg_data_2               ( id_reg_data_2               ),
        .btb_pre_token            ( id_pre_taken                ),
        .btb_pre_addr             ( id_pre_addr                 ),

        .reg_read_en_1            ( reg_read_en_1               ),
        .reg_addr_1               ( reg_read_addr_1             ),
        .reg_read_en_2            ( reg_read_en_2               ),
        .reg_addr_2               ( reg_read_addr_2             ),
        .btb_set                  ( btb_set                     ),
        .btb_set_pc               ( btb_set_pc                  ),
        .btb_set_taken            ( btb_set_taken               ),
        .btb_set_target           ( btb_set_target              ),
        .stall_request            ( request_from_id             ),
        .next_delayslot_pc_error  ( if_next_delayslot_pc_error  ),
        .branch_flag              ( pc_branch_flag              ),
        .branch_addr              ( pc_branch_addr              ),
        .ex_funct                 ( idex_funct                  ),
        .ex_shamt                 ( idex_shamt                  ),
        .ex_operand_1             ( idex_operand_1              ),
        .ex_operand_2             ( idex_operand_2              ),
        .delayslot_flag_out       ( idex_delayslot_flag_out     ),
        .next_delayslot_flag_out  ( idex_next_delayslot_flag_out),
        .mem_read_flag            ( idex_mem_read_flag          ),
        .mem_write_flag           ( idex_mem_write_flag         ),
        .mem_sign_ext_flag        ( idex_mem_sign_ext_flag      ),
        .mem_sel                  ( idex_mem_sel                ),
        .mem_write_data           ( idex_mem_write_data         ),
        .wb_reg_write_en          ( idex_wb_reg_write_en        ),
        .wb_reg_write_addr        ( idex_wb_reg_write_addr      ),
        .current_pc               ( idex_current_pc             ),
        .branch_is_error          ( btb_branch_is_error         ),
        .cp0_write_en             ( idex_cp0_write_en     ),
        .cp0_read_en              ( idex_cp0_read_en      ),
        .cp0_addr                 ( idex_cp0_addr         ),
        .cp0_write_data           ( idex_cp0_write_data   ),
        .exception_type           ( idex_exception_type   )
    );  
    
    // to EX stage
    wire ex_delayslot_flag, ex_mem_read_flag, ex_mem_write_flag, 
        ex_mem_sign_ext_flag, ex_wb_reg_write_en, ex_cp0_write_en, 
        ex_cp0_read_en;
    wire [`FUNCT_BUS] ex_funct;
    wire [`SHAMT_BUS] ex_shamt;
    wire [`DATA_BUS] ex_operand_1, ex_operand_2, ex_mem_write_data, ex_cp0_write_data;
    wire [`MEM_SEL_BUS] ex_mem_sel;
    wire [`REG_ADDR_BUS] ex_wb_reg_write_addr;
    wire [`ADDR_BUS] ex_current_pc_addr;
    wire [`CP0_ADDR_BUS] ex_cp0_addr;
    wire [`EXC_TYPE_BUS] ex_exception_type;

    IDEX  u_IDEX (
        .clk                     ( clk                     ),
        .rst                     ( rst                     ),
        .flush                   ( flush                   ),
        .stall_current_stage     ( stall_id_conn     ),
        .stall_next_stage        ( stall_ex_conn        ),
        .delayslot_flag_i        ( idex_delayslot_flag_out        ),
        .next_delayslot_flag_i   ( idex_next_delayslot_flag_out   ),
        .ex_funct_i              ( idex_funct              ),
        .ex_shamt_i              ( idex_shamt              ),
        .ex_operand_1_i          ( idex_operand_1          ),
        .ex_operand_2_i          ( idex_operand_2          ),
        .mem_read_flag_i         ( idex_mem_read_flag         ),
        .mem_write_flag_i        ( idex_mem_write_flag        ),
        .mem_sign_ext_flag_i     ( idex_mem_sign_ext_flag     ),
        .mem_sel_i               ( idex_mem_sel               ),
        .mem_write_data_i        ( idex_mem_write_data        ),
        .wb_reg_write_en_i       ( idex_wb_reg_write_en       ),
        .wb_reg_write_addr_i     ( idex_wb_reg_write_addr     ),
        .current_pc_addr_i       ( idex_current_pc       ),
        .cp0_write_en_i          ( idex_cp0_write_en     ),
        .cp0_read_en_i           ( idex_cp0_read_en      ),
        .cp0_addr_i              ( idex_cp0_addr         ),
        .cp0_write_data_i        ( idex_cp0_write_data   ),
        .exception_type_i        ( idex_exception_type   ),

        .delayslot_flag_o        ( ex_delayslot_flag        ),
        .next_delayslot_flag_o   ( id_delayslot_flag_in   ),
        .ex_funct_o              ( ex_funct              ),
        .ex_shamt_o              ( ex_shamt              ),
        .ex_operand_1_o          ( ex_operand_1          ),
        .ex_operand_2_o          ( ex_operand_2          ),
        .mem_read_flag_o         ( ex_mem_read_flag         ),
        .mem_write_flag_o        ( ex_mem_write_flag        ),
        .mem_sign_ext_flag_o     ( ex_mem_sign_ext_flag     ),
        .mem_sel_o               ( ex_mem_sel               ),
        .mem_write_data_o        ( ex_mem_write_data        ),
        .wb_reg_write_en_o       ( ex_wb_reg_write_en       ),
        .wb_reg_write_addr_o     ( ex_wb_reg_write_addr     ),
        .current_pc_addr_o       ( ex_current_pc_addr       ),
        .cp0_write_en_o          ( ex_cp0_write_en     ),
        .cp0_read_en_o           ( ex_cp0_read_en      ),
        .cp0_addr_o              ( ex_cp0_addr         ),
        .cp0_write_data_o        ( ex_cp0_write_data   ),
        .exception_type_o        ( ex_exception_type   )
    );

    // from HILO
    wire [`DATA_BUS] ex_hi, ex_lo;
    wire [63:0] ex_result;
    wire ex_done;

    MultDiv  u_MultDiv (
        .clk                     ( clk         ),   
        .rst                     ( rst         ),   
        .flush                   ( flush       ),   
        .funct                   ( ex_funct       ),   
        .operand_1               ( ex_operand_1   ),
        .operand_2               ( ex_operand_2   ),
        .hi                      ( ex_hi          ),
        .lo                      ( ex_lo          ),

        .done                    ( ex_done        ),
        .result                  ( ex_result      )
    );

    // to RegReadProxy
    wire ex_load_flag, mem_load_flag;

    // to EX
    wire [`DATA_BUS] ex_cp0_read_data;

    // to EXMEM
    wire exmem_mem_read_flag, exmem_mem_write_flag, exmem_mem_sign_ext_flag,
        exmem_wb_reg_write_en, exmem_delayslot_flag, exmem_hilo_write_en, 
        exmem_cp0_write_en;
    wire [`MEM_SEL_BUS] exmem_mem_sel;
    wire [`DATA_BUS] exmem_mem_write_data, exmem_result, exmem_hi, exmem_lo, 
                    exmem_cp0_write_data;
    wire [`REG_ADDR_BUS] exmem_wb_reg_write_addr;
    wire [`ADDR_BUS] exmem_current_pc_addr;
    wire [`CP0_ADDR_BUS] exmem_cp0_addr;
    wire [`EXC_TYPE_BUS] exmem_exception_type;

    EX  u_EX (
        .funct                   ( ex_funct                 ),
        .shamt                   ( ex_shamt                 ),
        .operand_1               ( ex_operand_1             ),
        .operand_2               ( ex_operand_2             ),
        .delayslot_flag_i        ( ex_delayslot_flag      ),
        .mem_read_flag_i         ( ex_mem_read_flag       ),
        .mem_write_flag_i        ( ex_mem_write_flag      ),
        .mem_sign_ext_flag_i     ( ex_mem_sign_ext_flag   ),
        .mem_sel_i               ( ex_mem_sel             ),
        .mem_write_data_i        ( ex_mem_write_data      ),
        .wb_reg_write_en_i       ( ex_wb_reg_write_en     ),
        .wb_reg_write_addr_i     ( ex_wb_reg_write_addr   ),
        .current_pc_addr_i       ( ex_current_pc_addr     ),
        .hi_i                    ( ex_hi),
        .lo_i                    ( ex_lo),
        .mult_div_done           ( ex_done),
        .mult_div_result         ( ex_result),
        .cp0_write_en_i          ( ex_cp0_write_en     ),
        .cp0_read_en_i           ( ex_cp0_read_en      ),
        .cp0_addr_i              ( ex_cp0_addr         ),
        .cp0_write_data_i        ( ex_cp0_write_data   ),
        .cp0_read_data_i         ( ex_cp0_read_data    ),
        .exception_type_i        ( ex_exception_type   ),

        .ex_load_flag            ( ex_load_flag          ),
        .stall_request           ( request_from_ex          ),
        .mem_read_flag_o         ( exmem_mem_read_flag       ),
        .mem_write_flag_o        ( exmem_mem_write_flag      ),
        .mem_sign_ext_flag_o     ( exmem_mem_sign_ext_flag   ),
        .mem_sel_o               ( exmem_mem_sel             ),
        .mem_write_data_o        ( exmem_mem_write_data      ),
        .result_o                ( exmem_result                ),
        .wb_reg_write_en_o       ( exmem_wb_reg_write_en     ),
        .wb_reg_write_addr_o     ( exmem_wb_reg_write_addr   ),
        .hilo_write_en           ( exmem_hilo_write_en),
        .hi_o                    ( exmem_hi),
        .lo_o                    ( exmem_lo),
        .delayslot_flag_o        ( exmem_delayslot_flag      ),
        .current_pc_addr_o       ( exmem_current_pc_addr     ),
        .cp0_write_en_o          ( exmem_cp0_write_en     ),
        .cp0_write_data_o        ( exmem_cp0_write_data   ),
        .cp0_addr_o              ( exmem_cp0_addr         ),
        .exception_type_o        ( exmem_exception_type   )
    );

    // to MEM stage
    wire mem_read_flag, mem_write_flag, mem_sign_ext_flag, mem_cp0_write_en,
        mem_wb_reg_write_en, mem_delayslot_flag, mem_hilo_write_en;
    wire [`MEM_SEL_BUS] mem_sel;
    wire [`DATA_BUS] mem_write_data, mem_result, mem_hi, mem_lo, mem_cp0_write_data;
    wire [`REG_ADDR_BUS] mem_wb_reg_write_addr;
    wire [`ADDR_BUS] mem_current_pc_addr;
    wire [`CP0_ADDR_BUS] mem_cp0_addr;
    wire [`EXC_TYPE_BUS] mem_exception_type;

    EXMEM  u_EXMEM (
        .clk                     ( clk                   ),
        .rst                     ( rst                   ),
        .flush                   ( flush                 ),
        .stall_current_stage     ( stall_ex_conn   ),
        .stall_next_stage        ( stall_mem_conn      ),
        .mem_read_flag_i         ( exmem_mem_read_flag       ),
        .mem_write_flag_i        ( exmem_mem_write_flag      ),
        .mem_sign_ext_flag_i     ( exmem_mem_sign_ext_flag   ),
        .mem_sel_i               ( exmem_mem_sel             ),
        .mem_write_data_i        ( exmem_mem_write_data      ),
        .result_i                ( exmem_result              ),
        .wb_reg_write_en_i       ( exmem_wb_reg_write_en     ),
        .wb_reg_write_addr_i     ( exmem_wb_reg_write_addr   ),
        .delayslot_flag_i        ( exmem_delayslot_flag      ),
        .current_pc_addr_i       ( exmem_current_pc_addr     ),
        .hilo_write_en_i         ( exmem_hilo_write_en    ),
        .hi_i                    ( exmem_hi               ),
        .lo_i                    ( exmem_lo               ),
        .cp0_write_en_i          ( exmem_cp0_write_en     ),
        .cp0_write_data_i        ( exmem_cp0_write_data   ),
        .cp0_addr_i              ( exmem_cp0_addr         ),
        .exception_type_i        ( exmem_exception_type   ),

        .mem_read_flag_o         ( mem_read_flag       ),
        .mem_write_flag_o        ( mem_write_flag      ),
        .mem_sign_ext_flag_o     ( mem_sign_ext_flag   ),
        .mem_sel_o               ( mem_sel             ),
        .mem_write_data_o        ( mem_write_data      ),
        .result_o                ( mem_result              ),
        .wb_reg_write_en_o       ( mem_wb_reg_write_en     ),
        .wb_reg_write_addr_o     ( mem_wb_reg_write_addr   ),
        .delayslot_flag_o        ( mem_delayslot_flag      ),
        .current_pc_addr_o       ( mem_current_pc_addr     ),
        .hilo_write_en_o         ( mem_hilo_write_en    ),
        .hi_o                    ( mem_hi               ),
        .lo_o                    ( mem_lo               ),
        .cp0_write_en_o          ( mem_cp0_write_en     ),
        .cp0_write_data_o        ( mem_cp0_write_data   ),
        .cp0_addr_o              ( mem_cp0_addr         ),
        .exception_type_o        ( mem_exception_type   )
    );

    // to MEMWB
    wire memwb_mem_read_flag, memwb_mem_write_flag, memwb_mem_sign_ext_flag, 
        memwb_wb_reg_write_en, memwb_hilo_write_en, memwb_cp0_write_en;
    wire [`MEM_SEL_BUS] memwb_mem_sel;
    wire [`DATA_BUS] memwb_result, memwb_hi, memwb_lo, memwb_cp0_write_data;
    wire [`REG_ADDR_BUS] memwb_wb_reg_write_addr;
    wire [`ADDR_BUS] memwb_current_pc_addr;
    wire [`CP0_ADDR_BUS] memwb_cp0_addr;

    // from CP0 to mem
    wire [`DATA_BUS] mem_cp0_status, mem_cp0_cause, mem_cp0_epc;

    // to CP0
    wire cp0_delayslot_flag;
    wire [`EXC_TYPE_BUS] cp0_exception_type;
    wire [`ADDR_BUS] cp0_badvaddr_write_data;

    // to pipelineControl
    wire [`ADDR_BUS] ctrl_cp0_epc;

    // to mmu
    wire [`ADDR_BUS] mmu_ram_addr;

    MEM  u_MEM (
        .mem_read_flag_i                ( mem_read_flag       ),
        .mem_write_flag_i               ( mem_write_flag      ),
        .mem_sign_ext_flag_i            ( mem_sign_ext_flag   ),
        .mem_sel_i                      ( mem_sel             ),
        .mem_write_data                 ( mem_write_data        ),
        .result_i                       ( mem_result              ),
        .wb_reg_write_en_i              ( mem_wb_reg_write_en     ),
        .wb_reg_write_addr_i            ( mem_wb_reg_write_addr   ),
        .delayslot_flag_i               ( mem_delayslot_flag      ),
        .current_pc_addr_i              ( mem_current_pc_addr     ),
        .hilo_write_en_i                ( mem_hilo_write_en    ),
        .hi_i                           ( mem_hi               ),
        .lo_i                           ( mem_lo               ),
        .cp0_write_en_i                 ( mem_cp0_write_en               ),
        .cp0_write_data_i               ( mem_cp0_write_data             ),
        .cp0_addr_i                     ( mem_cp0_addr                   ),
        .exception_type_i               ( mem_exception_type             ),
        .cp0_status_i                   ( mem_cp0_status                 ),
        .cp0_cause_i                    ( mem_cp0_cause                  ),
        .cp0_epc_i                      ( mem_cp0_epc                    ),

        .ram_en                         ( ram_en                ),
        .ram_write_en                   ( ram_write_en          ),
        .ram_addr                       ( mmu_ram_addr          ),
        .ram_write_data                 ( ram_write_data        ),
        .ram_size                       ( ram_size              ),
        .mem_load_flag                  ( mem_load_flag         ),
        .mem_read_flag_o                ( memwb_mem_read_flag       ),
        .mem_write_flag_o               ( memwb_mem_write_flag      ),
        .mem_sign_ext_flag_o            ( memwb_mem_sign_ext_flag   ),
        .mem_sel_o                      ( memwb_mem_sel             ),
        .result_o                       ( memwb_result              ),
        .wb_reg_write_en_o              ( memwb_wb_reg_write_en     ),
        .wb_reg_write_addr_o            ( memwb_wb_reg_write_addr   ),
        .delayslot_flag_o               ( cp0_delayslot_flag      ),
        .current_pc_addr_o              ( memwb_current_pc_addr     ),
        .hilo_write_en_o                ( memwb_hilo_write_en    ),
        .hi_o                           ( memwb_hi               ),
        .lo_o                           ( memwb_lo               ),
        .cp0_write_en_o                 ( memwb_cp0_write_en       ),
        .cp0_write_data_o               ( memwb_cp0_write_data      ),
        .cp0_addr_o                     ( memwb_cp0_addr         ),
        .exception_type_o               ( cp0_exception_type        ),
        .cp0_epc_o                      ( ctrl_cp0_epc               ),
        .cp0_badvaddr_write_data_o      ( cp0_badvaddr_write_data   )
    );

    // to WB stage
    wire wb_mem_read_flag, wb_mem_write_flag, wb_mem_sign_ext_flag, 
        wb_reg_write_en, wb_hilo_write_en, wb_cp0_write_en;
    wire [`MEM_SEL_BUS] wb_mem_sel;
    wire [`DATA_BUS] wb_ram_read_data, wb_result, wb_hi, wb_lo, wb_cp0_write_data;
    wire [`ADDR_BUS] wb_current_pc_addr;
    wire [`REG_ADDR_BUS] wb_reg_write_addr;
    wire [`CP0_ADDR_BUS] wb_cp0_addr;

    MEMWB  u_MEMWB (
        .clk                     ( clk                   ),
        .rst                     ( rst                   ),
        .flush                   ( flush                 ),
        .stall_current_stage     ( stall_mem_conn       ),
        .stall_next_stage        ( stall_wb_conn        ),
        .ram_read_data_i         ( ram_read_data        ),
        .mem_read_flag_i         ( memwb_mem_read_flag       ),
        .mem_write_flag_i        ( memwb_mem_write_flag      ),
        .mem_sign_ext_flag_i     ( memwb_mem_sign_ext_flag   ),
        .mem_sel_i               ( memwb_mem_sel             ),
        .result_i                ( memwb_result              ),
        .wb_reg_write_en_i       ( memwb_wb_reg_write_en     ),
        .wb_reg_write_addr_i     ( memwb_wb_reg_write_addr   ),
        .current_pc_addr_i       ( memwb_current_pc_addr     ),
        .hilo_write_en_i         ( memwb_hilo_write_en    ),
        .hi_i                    ( memwb_hi               ),
        .lo_i                    ( memwb_lo               ),
        .cp0_write_en_i          ( memwb_cp0_write_en     ),
        .cp0_write_data_i        ( memwb_cp0_write_data   ),
        .cp0_addr_i              ( memwb_cp0_addr         ),

        .ram_read_data_o         ( wb_ram_read_data       ),
        .mem_read_flag_o         ( wb_mem_read_flag       ),
        .mem_write_flag_o        ( wb_mem_write_flag      ),
        .mem_sign_ext_flag_o     ( wb_mem_sign_ext_flag   ),
        .mem_sel_o               ( wb_mem_sel             ),
        .result_o                ( wb_result              ),
        .wb_reg_write_en_o       ( wb_reg_write_en     ),
        .wb_reg_write_addr_o     ( wb_reg_write_addr   ),
        .hilo_write_en_o         ( wb_hilo_write_en    ),
        .hi_o                    ( wb_hi               ),
        .lo_o                    ( wb_lo               ),
        .current_pc_addr_o       ( wb_current_pc_addr  ),
        .cp0_write_en_o          ( wb_cp0_write_en     ),
        .cp0_write_data_o        ( wb_cp0_write_data   ),
        .cp0_addr_o              ( wb_cp0_addr         )
    );


    // to regfile
    wire reg_write_en;
    wire [`REG_ADDR_BUS] reg_write_addr;
    wire [`DATA_BUS] reg_write_data;

    // to HILO
    wire hilo_write_en;
    wire [`DATA_BUS] hilo_hi, hilo_lo;

    // debug signal
    assign debug_reg_write_addr = reg_write_addr;
    assign debug_reg_write_data = reg_write_data;

    // to CP0
    wire cp0_write_en;
    wire [`DATA_BUS] cp0_write_data;
    wire [`CP0_ADDR_BUS] cp0_addr;


    WB  u_WB (
        .ram_read_data           ( wb_ram_read_data        ),
        .mem_read_flag_i         ( wb_mem_read_flag        ),
        .mem_write_flag_i        ( wb_mem_write_flag       ),
        .mem_sign_ext_flag_i     ( wb_mem_sign_ext_flag    ),
        .mem_sel_i               ( wb_mem_sel              ),
        .result_i                ( wb_result               ),
        .wb_reg_write_en_i       ( wb_reg_write_en         ),
        .wb_reg_write_addr_i     ( wb_reg_write_addr       ),
        .current_pc_addr_i       ( wb_current_pc_addr      ),
        .hilo_write_en_i         ( wb_hilo_write_en        ),
        .hi_i                    ( wb_hi                   ),
        .lo_i                    ( wb_lo                   ),
        .cp0_write_en_i          ( wb_cp0_write_en         ),
        .cp0_write_data_i        ( wb_cp0_write_data       ),
        .cp0_addr_i              ( wb_cp0_addr             ),

        .hilo_write_en_o         ( hilo_write_en           ),
        .hi_o                    ( hilo_hi                 ),
        .lo_o                    ( hilo_lo                 ),
        .result_o                ( reg_write_data          ),
        .wb_reg_write_en_o       ( reg_write_en            ),
        .wb_reg_write_addr_o     ( reg_write_addr          ),
        .debug_reg_write_en_o    ( debug_reg_write_en      ),
        .debug_pc_addr_o         ( debug_pc_addr           ),
        .cp0_write_en_o          ( cp0_write_en            ),
        .cp0_write_data_o        ( cp0_write_data          ),
        .cp0_addr_o              ( cp0_addr                )
    );

    // to HILOReadProxy
    wire hilo_write_en_from_mem = memwb_hilo_write_en;
    wire hilo_write_en_from_wb = hilo_write_en;
    wire [`DATA_BUS] hi_from_mem = memwb_hi;
    wire [`DATA_BUS] hi_from_wb = hilo_hi;
    wire [`DATA_BUS] lo_from_mem = memwb_lo;
    wire [`DATA_BUS] lo_from_wb = hilo_lo;
    wire [`DATA_BUS] hilo_rp_hi, hilo_rp_lo;

    HILOReadProxy  u_HILOReadProxy (
        .hi_i                    ( hilo_rp_hi          ),
        .lo_i                    ( hilo_rp_lo          ),
        .mem_hilo_write_en       ( hilo_write_en_from_mem   ),
        .mem_hi_i                ( hi_from_mem            ),
        .mem_lo_i                ( lo_from_mem            ),
        .wb_hilo_write_en        ( hilo_write_en_from_wb    ),
        .wb_hi_i                 ( hi_from_wb             ),
        .wb_lo_i                 ( lo_from_wb             ),

        .hi_o                    ( ex_hi                ),
        .lo_o                    ( ex_lo                )
    );

    // to HILOReadProxy

    HILO  u_HILO (
        .clk                     ( clk        ),
        .rst                     ( rst        ),
        .write_en                ( hilo_write_en   ),
        .hi_i                    ( hilo_hi       ),
        .lo_i                    ( hilo_lo       ),

        .hi_o                    ( hilo_rp_hi       ),
        .lo_o                    ( hilo_rp_lo       )
    );

    // to RegReadProxy
    wire [`DATA_BUS] rp_read_data_1, rp_read_data_2;

    RegFile  u_RegFile (
        .clk                     ( clk              ),
        .rst                     ( rst              ),
        .write_en                ( reg_write_en     ),
        .write_addr              ( reg_write_addr   ),
        .write_data              ( reg_write_data   ),
        .read_en_1               ( reg_read_en_1    ),
        .read_addr_1             ( reg_read_addr_1  ),
        .read_en_2               ( reg_read_en_2    ),
        .read_addr_2             ( reg_read_addr_2  ),

        .read_data_1             ( rp_read_data_1   ),
        .read_data_2             ( rp_read_data_2   )
    );


    // to RegReadProxy
    wire reg_write_en_from_ex = exmem_wb_reg_write_en; 
    wire reg_write_en_from_mem = memwb_wb_reg_write_en;
    wire [`REG_ADDR_BUS] reg_write_addr_from_ex = exmem_wb_reg_write_addr;
    wire [`REG_ADDR_BUS] reg_write_addr_from_mem = memwb_wb_reg_write_addr;
    wire [`DATA_BUS] data_from_ex = exmem_result;
    wire [`DATA_BUS] data_from_mem = memwb_result;

    RegReadProxy  u_RegReadProxy (
        .read_en_1                ( reg_read_en_1                 ),
        .read_en_2                ( reg_read_en_2                 ),
        .read_addr_1              ( reg_read_addr_1               ),
        .read_addr_2              ( reg_read_addr_2               ),
        .data_1_from_reg          ( rp_read_data_1           ),
        .data_2_from_reg          ( rp_read_data_2           ),
        .ex_load_flag             ( ex_load_flag              ),
        .reg_write_en_from_ex     ( reg_write_en_from_ex      ),
        .reg_write_addr_from_ex   ( reg_write_addr_from_ex    ),
        .data_from_ex             ( data_from_ex              ),
        .mem_load_flag            ( mem_load_flag             ),
        .reg_write_en_from_mem    ( reg_write_en_from_mem     ),
        .reg_write_addr_from_mem  ( reg_write_addr_from_mem   ),
        .data_from_mem            ( data_from_mem             ),

        .load_related_1           ( id_load_related_1            ),
        .load_related_2           ( id_load_related_2            ),
        .read_data_1              ( id_reg_data_1               ),
        .read_data_2              ( id_reg_data_2               )
    );

    wire [`DATA_BUS] data_o, count_o, status_o, cause_o, epc_o, config0_o;
    wire [`ADDR_BUS] cp0_current_pc_addr = memwb_current_pc_addr;

    CP0  u_CP0 (
        .clk                      ( clk                       ),
        .rst                      ( rst                       ),
        .cp0_write_en             ( cp0_write_en              ),
        .cp0_read_addr            ( exmem_cp0_addr            ),
        .cp0_write_addr           ( cp0_addr                  ),
        .cp0_write_data           ( cp0_write_data            ),
        .interrupt_i              ( interrupt                 ),
        .cp0_badvaddr_write_data  ( cp0_badvaddr_write_data   ),
        .exception_type           ( cp0_exception_type        ),
        .delayslot_flag           ( cp0_delayslot_flag        ),
        .current_pc_addr          ( cp0_current_pc_addr     ),

        .data_o                   ( data_o                    ),
        .count_o                  ( count_o                   ),
        .status_o                 ( status_o                  ),
        .cause_o                  ( cause_o                   ),
        .epc_o                    ( epc_o                     ),
        .config0_o                ( config0_o                 )
    );

    wire [`DATA_BUS] cp0_config0;

    CP0ReadProxy  u_CP0ReadProxy (
        .cp0_read_addr           ( exmem_cp0_addr       ),
        .cp0_count_i             ( count_o              ),
        .cp0_status_i            ( status_o             ),
        .cp0_cause_i             ( cause_o              ),
        .cp0_epc_i               ( epc_o                ),
        .cp0_config0_i           ( config0_o            ),
        .cp0_read_data_i         ( data_o               ),
        .mem_cp0_write_en        ( mem_cp0_write_en     ),
        .mem_cp0_write_addr      ( mem_cp0_addr         ),
        .mem_cp0_write_data      ( mem_cp0_write_data   ),
        .wb_cp0_write_en         ( wb_cp0_write_en      ),
        .wb_cp0_write_addr       ( wb_cp0_addr          ),
        .wb_cp0_write_data       ( wb_cp0_write_data    ),

        .cp0_count_o             (           ),
        .cp0_status_o            ( mem_cp0_status         ),
        .cp0_cause_o             ( mem_cp0_cause          ),
        .cp0_epc_o               ( mem_cp0_epc            ),
        .cp0_config0_o           ( cp0_config0            ),
        .cp0_read_data_o         ( ex_cp0_read_data       )
    );

    PipelineController  u_PipelineController (
        .request_from_id         ( request_from_id   ),
        .request_from_ex         ( request_from_ex   ),
        .stall_all               ( halt             ),
        .cp0_epc                 ( ctrl_cp0_epc      ),
        .exception_type          ( cp0_exception_type),

        .stall_pc                ( stall_pc_conn     ),
        .stall_if                ( stall_if_conn     ),
        .stall_id                ( stall_id_conn     ),
        .stall_ex                ( stall_ex_conn     ),
        .stall_mem               ( stall_mem_conn    ),
        .stall_wb                ( stall_wb_conn     ),
        .flush                   ( flush             ),
        .exc_pc                  ( pc_exc_pc         )
    );

    MMU  u_MMU (
        .rom_addr_in             ( mmu_rom_addr    ),
        .ram_addr_in             ( mmu_ram_addr    ),
        .cp0_config_in           ( cp0_config0     ),

        .rom_addr_out            ( rom_addr        ),
        .ram_addr_out            ( ram_addr        ),
        .i_cached                ( i_cached        ),
        .d_cached                ( d_cached        )
    );
    
endmodule