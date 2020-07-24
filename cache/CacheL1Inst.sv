`timescale 1ns/1ps
module CacheL1Inst(
    input clk,
    input rst,
    input exception_flag,
    input d_stall_req,
    output i_stall_req,
    //inst sram 
    input rom_en,
    input [3:0] rom_wen,
    input [31:0] rom_addr,
    input [31:0] rom_wdata,
    output [31:0] rom_rdata,
    input icached,
    //axi
    //ar
    output [3 :0] arid,
    output [31:0] araddr,
    output [7 :0] arlen,
    output [2 :0] arsize,
    output [1 :0] arburst,
    output [1 :0] arlock,
    output [3 :0] arcache,
    output [2 :0] arprot,
    output arvalid,
    input arready,
    //r  
    input  [3 :0] rid ,
    input  [31:0] rdata,
    input  [1 :0] rresp,
    input rlast,
    input rvalid,
    output rready,
    //aw 
    output [3 :0] awid,
    output [31:0] awaddr,
    output [7 :0] awlen,
    output [2 :0] awsize,
    output [1 :0] awburst,
    output [1 :0] awlock,
    output [3 :0] awcache,
    output [2 :0] awprot,
    output awvalid,
    input awready,
    //w 
    output [3 :0] wid ,
    output [31:0] wdata,
    output [3 :0] wstrb,
    output wlast,
    output wvalid,
    input wready,
    //b  
    input [3 :0] bid ,
    input [1 :0] bresp,
    input bvalid,
    output bready     
);
    `define TAG 31:14
    `define INDEX 13:6
    `define OFFSET 5:2

    typedef enum{  
        LOOK_UP,HIT_UPDATE,
        UC_RADDR,UC_RDATA,UC_RWAIT,
        C_RADDR,C_RDATA,
        REFILL
    }state_t; 

    (*mark_debug = "true"*)state_t state;
    //axi
    reg [3:0]axi_arid;
    reg [31:0]axi_araddr;
    reg [2:0]axi_arsize;
    reg [7:0]axi_arlen;
    reg [1:0]axi_arburst;
    reg axi_arvalid;
    //ready
    reg [1:0] hit;
    reg uc_ready;
    wire [1:0] hit0;

    assign i_stall_req =   rom_en&&~(hit||uc_ready);

    //ar
    assign arid    = axi_arid;
    assign araddr  = axi_araddr;
    assign arlen   = axi_arlen;
    assign arsize  = axi_arsize;
    assign arburst = axi_arburst;
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = axi_arvalid;
    //r
    assign rready  = 1'b1;

    //aw
    assign awid = 0;
    assign awaddr  = 0;
    assign awlen   = 8'd0;
    assign awsize  = 0;
    assign awburst = 2'd0;
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = 0;
    //w
    assign wid    = 4'd0;
    assign wdata  = 0;
    assign wstrb  = 4'd0;
    assign wlast  = 0;
    assign wvalid = 0;
    //b
    assign bready  = 1'b1;    

    //axi count
    reg [3:0] count;

    reg [31:0] c_rdata,uc_rdata;
    //data sram
    reg [1:0] data_en;
    reg [1:0] data_wen;
    reg [31:0] data0_w;
    reg [31:0] data1_w;
    wire [31:0] data0_o;
    wire [31:0] data1_o;

    //tag,LRU reg
    reg [255:0] LRU;
    reg [18:0] tagV0[0:255];
    reg [18:0] tagV1[0:255];

    wire [11:0] addr_sram;

    CacheL1Inst_ram ic_ram(
        clk,rst,addr_sram,
        //data sram
        data_en,data_wen,data0_w,data1_w,data0_o,data1_o         
    );

    wire [31:0] addr;

    assign addr = rom_addr;

    assign hit0 = {rom_en && icached && (tagV0[addr[`INDEX]][18:1]==addr[`TAG]) && tagV0[addr[`INDEX]][0],
    rom_en && icached && (tagV1[addr[`INDEX]][18:1]==addr[`TAG]) && tagV1[addr[`INDEX]][0]};

    assign rom_rdata = icached? c_rdata:uc_rdata;

    assign addr_sram = (state==C_RDATA)? {addr[`INDEX],count}:addr[13:2];

    always_comb begin
        if(!rst) begin
            //data sram
            data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; c_rdata <= 0;         
        end
        else begin
            case(state)
                LOOK_UP:begin
                    //data sram
                    data_en <= {rom_en&&icached,rom_en&&icached}; 
                    data_wen <= 0; data0_w <= 0; data1_w <= 0;  
                    c_rdata <= 0;                
                end

                C_RADDR,UC_RADDR,UC_RDATA,UC_RWAIT:begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0;  c_rdata <= 0;                  
                end

                HIT_UPDATE:begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0;  
                    c_rdata <= (hit==2'b01)? data1_o:((hit==0)?0:data0_o);                   
                end

                C_RDATA:begin
                    //data sram
                    data_en <= rvalid? (LRU[addr[`INDEX]]? 2'b10:2'b01):0; 
                    data_wen <= rvalid? (LRU[addr[`INDEX]]? 2'b10:2'b01):0; 
                    data0_w <= rvalid&&LRU[addr[`INDEX]]==0? rdata:0; 
                    data1_w <= rvalid&&LRU[addr[`INDEX]]==1? rdata:0;
                    c_rdata <= 0;                   
                end

                REFILL:begin
                    //data sram
                    data_en <= LRU[addr[`INDEX]]? 2'b10:2'b01; data_wen <= 0; data0_w <= 0; data1_w <= 0;
                    c_rdata <= 0;                 
                end

                default begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0;        
                    c_rdata <= 0;             
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if(!rst) begin
            for(int i=0;i<256;i=i+1) begin
                tagV0[i] <= 0;
                tagV1[i] <= 0;
            end
            state <= LOOK_UP;
            LRU <= 0;
            count <= 0;
            hit <= 0;
            uc_ready <= 0;
            uc_rdata <= 0;
            //axi
            axi_arid <= 0;  axi_araddr <= 0;    axi_arsize <= 0;    axi_arlen <= 0; 
            axi_arburst <= 0;   axi_arvalid <= 0;              
        end
        else begin
            axi_arvalid <= 0;
            case (state)
                LOOK_UP:begin
                    count <= 0;
                    hit <= exception_flag? 0:hit0;
                    uc_ready <= 0;
                    uc_rdata <= 0;
                    if(exception_flag) begin
                        state <= LOOK_UP;
                        LRU <= LRU;
                    end
                    else if(rom_en&&icached&&hit0!=0) begin
                        state <= HIT_UPDATE;
                        LRU[addr[`INDEX]] <= (hit0==2'b01)? 0:1;
                    end
                    else if(rom_en&&icached) begin
                        state <= C_RADDR;
                        LRU <= LRU;
                    end
                    else if(rom_en&&~icached) begin
                        state <= UC_RADDR;
                        LRU <= LRU;
                    end
                    else begin
                        state <= state;
                        LRU <= LRU;
                    end                    
                end

                HIT_UPDATE:begin
                    //暂坜相关
                    state <= d_stall_req? HIT_UPDATE:LOOK_UP;
                    LRU[addr[`INDEX]] <= d_stall_req? LRU[addr[`INDEX]]:((hit==2'b01)? 0:1); 
                    count <= 0;
                    hit <= d_stall_req? hit:0;
                    uc_ready <= 0;
                    uc_rdata <= 0;                                                         
                end

                UC_RADDR:begin
                    LRU <= LRU;  
                    count <= 0;
                    hit <= 0;
                    uc_ready <= 0;
                    uc_rdata <= 0;   

                    if(arready) begin
                        state <= UC_RDATA;
                    end
                    else begin
                        //axi
                        axi_arid <= 4'b0010;  axi_araddr <= addr;    axi_arsize <= 2;    axi_arlen <= 0; 
                        axi_arburst <= 0;   axi_arvalid <= 1;                    
                        state <= state;
                    end
                end

                UC_RDATA:begin
                    LRU <= LRU;  
                    count <= 0;
                    hit <= 0;
                    uc_ready <= rvalid&&rlast? 1:uc_ready;
                    uc_rdata <= rvalid&&rlast? rdata:uc_rdata;

                    if(rvalid&&rlast) begin
                        state <= UC_RWAIT;
                    end
                    else begin
                    //axi
                        axi_arid <= 4'b0010;  axi_araddr <= 0;    axi_arsize <= 2;    axi_arlen <= 0; 
                        axi_arburst <= 0;   axi_arvalid <= 0;                    
                        state <= state;
                    end
                end

                UC_RWAIT:begin
                    state <= d_stall_req? UC_RWAIT:LOOK_UP;
                    uc_ready <= d_stall_req? uc_ready:0;                                      
                end
                
                C_RADDR:begin
                    LRU <= LRU;  
                    count <= 0;
                    hit <= 0;
                    uc_ready <= 0; 
                    uc_rdata <= 0;   

                    if(arready) begin
                        state <= C_RDATA;
                    end
                    else begin
                        //axi
                        axi_arid <= 4'b0011;  axi_araddr <= {addr[`TAG],addr[`INDEX],6'b0};    
                        axi_arsize <= 2;    axi_arlen <= 4'hF; 
                        axi_arburst <= 2;   axi_arvalid <= 1;                    
                        state <= state;
                    end
                end

                C_RDATA:begin
                    LRU <= LRU;  
                    hit <= 0;
                    uc_ready <= 0;
                    uc_rdata <= 0;   
                    count <= rvalid? count+1:count;      

                    if(rvalid&&rlast) begin
                        state <= REFILL;
                        if(LRU[addr[`INDEX]]) begin
                            tagV1[addr[`INDEX]] <= {addr[`TAG],1'b1};
                        end                     
                        else begin
                            tagV0[addr[`INDEX]] <= {addr[`TAG],1'b1};
                        end                        
                    end
                    else begin
                        //axi
                        axi_arid <= 4'b0011;  axi_araddr <= 0;    
                        axi_arsize <= 2;    axi_arlen <= 4'hF; 
                        axi_arburst <= 2;   axi_arvalid <= 0;                    
                        state <= state;
                    end
                end

                REFILL:begin
                    count <= 0;
                    hit <= hit0;
                    uc_ready <= 0;
                    uc_rdata <= 0;
                    LRU <= LRU;               
                    state <= HIT_UPDATE;                                      
                end

                default begin
                    state <= LOOK_UP;
                    LRU <= 0;
                    count <= 0;
                    hit <= 0;
                    uc_rdata <= 0;
                    uc_ready <= 0;
                    //axi
                    axi_arid <= 0;  axi_araddr <= 0;    axi_arsize <= 0;    axi_arlen <= 0; 
                    axi_arburst <= 0;   axi_arvalid <= 0;                     
                end
            endcase
        end
    end

endmodule