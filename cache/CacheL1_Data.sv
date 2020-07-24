`timescale 1ns/1ps

//写回总线采用预取sram模式
module CacheL1Data(
    input clk,
    input rst,
    input i_stall_req,
    output d_stall_req,
    //data sram 
    input ram_en,
    input [3:0] ram_wen,
    input [31:0] ram_addr,
    input [2:0] ram_size,
    input [31:0] ram_wdata,
    output [31:0] ram_rdata,
    input dcached,
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
    output reg [31:0] wdata,
    output reg [3 :0] wstrb,
    output reg wlast,
    output reg wvalid,
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
        UC_WADDR,UC_WDATA,UC_WRES,UC_WWAIT,
        C_RADDR,C_RDATA,
        C_WADDR,C_WDATA,C_WWAIT,
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

    reg [3:0]axi_awid;
    reg [31:0]axi_awaddr;
    reg [2:0]axi_awsize;
    reg [7:0]axi_awlen;
    reg [1:0]axi_awburst;
    reg axi_awvalid;    
    //ready
    reg [1:0] hit;
    reg uc_ready;
    wire [1:0] hit0;
    wire [31:0] addr;

    assign addr = ram_addr;

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
    assign awid    = 4'b0;
    assign awaddr  = axi_awaddr;
    assign awlen   = axi_awlen;
    assign awsize  = axi_awsize;
    assign awburst = axi_awburst;
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = axi_awvalid;

    //w
    assign wid = 4'd0;
    //b
    assign bready  = 1'b1;    

    //axi count
    reg [3:0] count;

    //data sram
    reg [1:0] data_en;
    reg [7:0] data_wen;
    reg [31:0] data0_w;
    reg [31:0] data1_w;
    wire [31:0] data0_o;
    wire [31:0] data1_o;

    //tag,LRU reg
    reg [255:0] LRU;
    reg [18:0] tagV0[0:255];
    reg [18:0] tagV1[0:255];
    reg [255:0] dirty0;
    reg [255:0] dirty1;

    reg [31:0] uc_rdata;
    reg [31:0] c_rdata;

    wire [11:0] addr_sram;

    CacheL1Data_ram dc_ram(
        clk,rst,
        addr_sram,
        //data sram
        data_en,data_wen,data0_w,data1_w,data0_o,data1_o         
    );

    assign hit0 = {ram_en && dcached && (tagV0[addr[`INDEX]][18:1]==addr[`TAG]) && tagV0[addr[`INDEX]][0],
    ram_en && dcached && (tagV1[addr[`INDEX]][18:1]==addr[`TAG]) && tagV1[addr[`INDEX]][0]};

    assign ram_rdata = ram_wen? 0:(dcached? c_rdata:uc_rdata);

    assign d_stall_req = ram_en? !(hit||uc_ready):0;

    assign addr_sram = (state==C_RDATA)? {addr[`INDEX],count}:
    ((state==C_WADDR&&awready)?{addr[`INDEX],count}:
    ((state==C_WDATA&&count<=4'hF&&count!=0)? {addr[`INDEX],count}:addr[13:2]));

    always_comb begin
        if(!rst) begin
            //data sram
            data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; c_rdata <= 0; wdata <= 0;    
        end
        else begin
            case(state)
                LOOK_UP:begin
                    //data sram
                    data_en <= {ram_en&&dcached,ram_en&&dcached}; 
                    data_wen <= (ram_en&&dcached&&hit0!=0)? ((hit0==2'b01)? {ram_wen,4'b0}:{4'b0,ram_wen}):0; 
                    data0_w <= (hit0==2'b01)? 0:(hit0==0? 0:ram_wdata); 
                    data1_w <= (hit0==2'b01)? (hit0==0? 0:ram_wdata):0;         
                    c_rdata <= 0;            
                    wdata <= 0;
                end

                C_RADDR,UC_RWAIT,UC_RADDR,UC_RDATA,
                UC_WADDR,UC_WRES,UC_WWAIT,
                C_WWAIT:begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; c_rdata <= 0; 
                    wdata <= 0;                  
                end

                HIT_UPDATE:begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; 
                    if(hit==2'b01) begin
                        c_rdata <= data1_o;
                    end
                    else if (hit==2'b10) begin
                        c_rdata <= data0_o;           
                    end      
                    wdata <= 0;             
                end

                C_RDATA:begin
                    //data sram
                    data_en <= rvalid? (LRU[addr[`INDEX]]? 2'b10:2'b01):0; 
                    data_wen <= rvalid? (LRU[addr[`INDEX]]? {4'b1111,4'b0}:{4'b0,4'b1111}):0; 
                    data0_w <= rvalid&&LRU[addr[`INDEX]]==0? rdata:0; 
                    data1_w <= rvalid&&LRU[addr[`INDEX]]==1? rdata:0;
                    c_rdata <= 0;
                    wdata <= 0;
                end

                REFILL:begin
                    //data sram
                    data_en <= LRU[addr[`INDEX]]? 2'b10:2'b01; data_wen <= LRU[addr[`INDEX]]? {ram_wen,4'b0}:{4'b0,ram_wen}; 
                    data0_w <= LRU[addr[`INDEX]]? 0:ram_wdata; data1_w <= LRU[addr[`INDEX]]? ram_wdata:0; 
                    c_rdata <= 0;     
                    wdata <= 0;             
                end

                C_WADDR:begin
                    //data sram
                    data_en <= axi_awvalid&&awready? (LRU[addr[`INDEX]]? 2'b10:2'b01):0; 
                    data_wen <= 0; 
                    data0_w <= 0; data1_w <= 0;  
                    c_rdata <= 0; 
                    wdata <= 0;                 
                end

                C_WDATA:begin
                    //data sram
                    data_en <= (count<=4'hF)? (LRU[addr[`INDEX]]? 2'b10:2'b01):0; 
                    data_wen <= 0; 
                    data0_w <= 0; data1_w <= 0;     
                    c_rdata <= 0;        
                    wdata <= wvalid? (LRU[addr[`INDEX]]? data1_o:data0_o):0;       
                end

                UC_WDATA:begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; c_rdata <= 0; wdata <= wvalid? ram_wdata:0;                     
                end

                default begin
                    //data sram
                    data_en <= 0; data_wen <= 0; data0_w <= 0; data1_w <= 0; c_rdata <= 0; wdata <= 0;                  
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
            dirty0 <= 0;
            dirty1 <= 0;
            uc_rdata <= 0; 
            count <= 0;
            hit <= 0;
            uc_ready <= 0;
            //axi
            axi_arid <= 0;  axi_araddr <= 0;    axi_arsize <= 0;    axi_arlen <= 0; 
            axi_arburst <= 0;   axi_arvalid <= 0;  

            axi_awid <= 0;  axi_awaddr <= 0;    axi_awsize <= 0;    axi_awlen <= 0; 
            axi_awburst <= 0;   axi_awvalid <= 0;
            
            wvalid <= 0; wstrb <= 4'b0; wlast <= 0;                                    
        end
        else begin
            axi_arvalid <= 0;
            axi_awvalid <= 0;
            wvalid <= 0;
            case (state)
                LOOK_UP:begin
                    count <= 0;
                    hit <= hit0;
                    uc_ready <= 0;
                    uc_rdata <= 0;

                    if(ram_en&&dcached&&hit0!=0) begin
                        state <= HIT_UPDATE;
                        LRU <= LRU;
                    end
                    else if(ram_en&&dcached) begin
                        if(ram_wen!=0) begin
                            if(LRU[addr[`INDEX]]) begin
                                state <= dirty1[addr[`INDEX]]? C_WADDR:C_RADDR;
                            end
                            else begin
                                state <= dirty0[addr[`INDEX]]? C_WADDR:C_RADDR;
                            end
                        end
                        else begin
                            state <= C_RADDR;
                        end
                        LRU <= LRU;
                    end
                    else if(ram_en&&~dcached&&ram_wen==0) begin
                        state <= UC_RADDR;
                        LRU <= LRU;
                    end
                    else if (ram_en&&~dcached&&ram_wen!=0) begin
                        state <= UC_WADDR;
                        LRU <= LRU;
                    end
                    else begin
                        state <= state;
                        LRU <= LRU;
                    end                   
                end

                HIT_UPDATE:begin
                    //暂停相关
                    state <= i_stall_req? HIT_UPDATE:LOOK_UP;

                    if(hit==2'b01&&ram_wen!=0) begin
                        dirty1[addr[`INDEX]] <= i_stall_req? dirty1[addr[`INDEX]]:1;
                        LRU[addr[`INDEX]] <= i_stall_req? LRU[addr[`INDEX]] :0;
                    end
                    else if(ram_wen!=0&&hit==2'b10) begin
                        dirty0[addr[`INDEX]] <= i_stall_req? dirty0[addr[`INDEX]]:1;
                        LRU[addr[`INDEX]] <= i_stall_req? LRU[addr[`INDEX]] :1;
                    end

                    uc_rdata <= 0;

                    count <= 0;
                    hit <= i_stall_req? hit:0;
                    uc_ready <= 0;                                       
                end

                UC_RADDR:begin
                    LRU <= LRU;  
                    uc_rdata <= 0;
                    count <= 0;
                    hit <= 0;
                    uc_ready <= 0;      

                    if(arready) begin
                        state <= UC_RDATA;
                    end
                    else begin
                        //axi
                        axi_arid <= 4'b0100;  axi_araddr <= addr;    axi_arsize <= ram_size;    axi_arlen <= 0; 
                        axi_arburst <= 1;   axi_arvalid <= 1;                    
                        state <= state;
                    end
                end

                UC_RDATA:begin
                    LRU <= LRU;  
                    uc_rdata <= rvalid&&rlast? rdata:uc_rdata;
                    count <= 0;
                    hit <= 0;
                    uc_ready <= rvalid&&rlast? 1:uc_ready;

                    if(rvalid&&rlast) begin
                        state <= UC_RWAIT;
                    end
                    else begin
                        //axi
                        axi_arid <= 4'b0100;  axi_araddr <= 0;    axi_arsize <= ram_size;    axi_arlen <= 0; 
                        axi_arburst <= 1;   axi_arvalid <= 0;                    
                        state <= state;
                    end
                end

                UC_RWAIT:begin
                    //暂停相关
                    state <= i_stall_req? UC_RWAIT:LOOK_UP;
                    uc_ready <= i_stall_req? 1:0;                   
                end

                C_RADDR:begin
                    if(arready) state <= C_RDATA;
                    else begin
                        LRU <= LRU;  
                        uc_rdata <= 0;
                        count <= 0;
                        hit <= 0;
                        uc_ready <= 0;    
                        //axi
                        axi_arid <= 4'b0101;  axi_araddr <= {addr[`TAG],addr[`INDEX],6'b0};    
                        axi_arsize <= 2;    axi_arlen <= 4'hF; 
                        axi_arburst <= 2;   axi_arvalid <= 1;                        
                    end 
                end

                C_RDATA:begin  
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
                        LRU <= LRU;  
                        uc_rdata <= 0;
                        hit <= 0;
                        uc_ready <= 0;    
                        //axi
                        axi_arid <= 4'b0101;  axi_araddr <= {addr[`TAG],addr[`INDEX],6'b0};    
                        axi_arsize <= 2;    axi_arlen <= 4'hF; 
                        axi_arburst <= 2;   axi_arvalid <= 0;                          

                        count <= rvalid? count+1:count;                        
                    end
                end

                REFILL:begin
                    count <= 0;
                    hit <= hit0;
                    uc_ready <= 0;
                    LRU <= LRU;
                    state <= HIT_UPDATE;                  
                end

                UC_WADDR:begin
                    if(axi_awvalid&&awready) state <= UC_WDATA;
                    else begin
                        LRU <= LRU;
                        uc_rdata <= 0; 
                        count <= 0;
                        hit <= 0;
                        uc_ready <= 0;
                        //axi
                        axi_awid <= 4'b0;  axi_awaddr <= addr;    
                        axi_awsize <= ram_size; 
                        axi_awlen <= 0; 
                        axi_awburst <= 0;   
                        axi_awvalid <= 1; 
                    end                    
                end

                UC_WDATA:begin
                    if(wvalid&&wready) 
                        state <= UC_WRES;
                    else begin
                        LRU <= LRU;
                        uc_rdata <= 0; 
                        count <= 0;
                        hit <= 0;
                        uc_ready <= 0;

                        //axi
                        axi_awid <= 4'b0;  axi_awaddr <= 0;    
                        axi_awsize <= ram_size;    
                        axi_awlen <= 0; 
                        axi_awburst <= 0;   
                        axi_awvalid <= 0;
                        
                        wvalid <= 1; wstrb <= ram_wen; wlast <= 1; 
                    end                    
                end

                UC_WRES:begin
                    if(bvalid) begin
                        state <= UC_WWAIT;
                        uc_ready <= 1;                        
                    end
                    uc_rdata <= 0; 
                    count <= 0;
                    hit <= 0;     
                    //axi 
                    axi_awid <= 0;  axi_awaddr <= 0;    axi_awsize <= 0;    axi_awlen <= 0; 
                    axi_awburst <= 0;   axi_awvalid <= 0;
                    
                    wvalid <= 0; wstrb <= 4'b0; wlast <= 0;                                 
                end

                UC_WWAIT:begin
                    //暂停相关
                    state <= i_stall_req? UC_WWAIT:LOOK_UP;
                    uc_ready <= i_stall_req? 1:0;                    
                end

                C_WADDR:begin
                    if(axi_awvalid&&awready) begin
                        state <= C_WDATA;
                    end
                    else begin
                        LRU <= LRU;
                        uc_rdata <= 0; 
                        count <= awready? 1:0;
                        hit <= 0;
                        uc_ready <= 0;
                        //axi 
                        axi_awaddr <= LRU[addr[`INDEX]]? {tagV1[addr[`INDEX]][18:1],addr[`INDEX],6'b0}:{tagV0[addr[`INDEX]][18:1],addr[`INDEX],6'b0};    
                        axi_awsize <= 2;    
                        axi_awlen <= 4'hF; 
                        axi_awburst <= 2;   
                        axi_awvalid <= 1;     
                    end            
                end

                C_WDATA:begin
                    if(wvalid&&wvalid) begin
                        if(count==4'hF) begin
                            state <= C_WWAIT;
                            count <= 0;
                        end
                        else count <= count+1;
                    end
                    else begin
                        LRU <= LRU;
                        uc_rdata <= 0; 
                        hit <= 0;
                        uc_ready <= 0;
                        //axi                            
                        wvalid <= 1; 
                        wstrb <= 4'hF; 
                        wlast <= count==4'hF;   
                    end                
                end

                C_WWAIT:begin
                    if(bvalid) begin
                        state <= C_RADDR;
                        count <= 0;
                        if(LRU[addr[`INDEX]]) begin
                            dirty1[addr[`INDEX]] <= 0;
                        end
                        else begin
                            dirty0[addr[`INDEX]] <= 0;
                        end
                    end
                    else begin
                        uc_ready <= 0;
                        uc_rdata <= 0;
                        hit <= 0;
                    end
                end

                default begin
                    state <= LOOK_UP;
                    LRU <= 0;
                    uc_rdata <= 0; 
                    count <= 0;
                    hit <= 0;
                    uc_ready <= 0;
                    //axi
                    axi_arid <= 0;  axi_araddr <= 0;    axi_arsize <= 0;    axi_arlen <= 0; 
                    axi_arburst <= 0;   axi_arvalid <= 0;  

                    axi_awid <= 0;  axi_awaddr <= 0;    axi_awsize <= 0;    axi_awlen <= 0; 
                    axi_awburst <= 0;   axi_awvalid <= 0;
                    
                    wvalid <= 0; wstrb <= 4'b0; wlast <= 0;                                        
                end
            endcase
        end
    end

endmodule