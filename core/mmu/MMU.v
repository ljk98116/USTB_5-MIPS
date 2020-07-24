`timescale 1ns / 1ps

`include "../../include/bus.v"

`define HI_IN_RANGE(v, l, u)  (v[31:28] >= (l) && v[31:28] <= (u))

//config
`define     K23     30:28
`define     KU      27:25
`define     K0      2:0

module MMU(
    input       [`ADDR_BUS]     rom_addr_in,
    input       [`ADDR_BUS]     ram_addr_in,
    input       [`DATA_BUS]     cp0_config_in,

    output  reg [`ADDR_BUS]     rom_addr_out,
    output  reg [`ADDR_BUS]     ram_addr_out,
    output  reg                 i_cached,
    output  reg                 d_cached
);


    always @(*) begin
        if (rom_addr_in[31:28] <= 4'h7) begin
            rom_addr_out <= rom_addr_in;
            i_cached <= cp0_config_in[`K23] == 3'd3;
        end
        else if (`HI_IN_RANGE(rom_addr_in, 4'h8, 4'h9)) begin
            rom_addr_out <= {rom_addr_in[31:28] - 4'h8, rom_addr_in[27:0]};
            i_cached <= cp0_config_in[`K0] == 3'd3;
        end
        else if (`HI_IN_RANGE(rom_addr_in, 4'ha, 4'hb)) begin
            rom_addr_out <= {rom_addr_in[31:28] - 4'ha, rom_addr_in[27:0]};
            i_cached <= 0;
        end
        else if (`HI_IN_RANGE(rom_addr_in, 4'hc, 4'hd)) begin
            rom_addr_out <= rom_addr_in;
            i_cached <= cp0_config_in[`K23] == 3'd3;
        end
        else begin  // 32'he000_0000, 32'hffff_ffff
            rom_addr_out <= rom_addr_in;
            i_cached <= cp0_config_in[`K23] == 3'd3;
        end
    end

    always @(*) begin
        if (ram_addr_in[31:28] <= 4'h7) begin
            ram_addr_out <= ram_addr_in;
            d_cached <= cp0_config_in[`K23] == 3'd3;
        end
        else if (`HI_IN_RANGE(ram_addr_in, 4'h8, 4'h9)) begin
            ram_addr_out <= {ram_addr_in[31:28] - 4'h8, ram_addr_in[27:0]};
            d_cached <= cp0_config_in[`K0] == 3'd3;
        end
        else if (`HI_IN_RANGE(ram_addr_in, 4'ha, 4'hb)) begin
            ram_addr_out <= {ram_addr_in[31:28] - 4'ha, ram_addr_in[27:0]};
            d_cached <= 0;
        end
        else if (`HI_IN_RANGE(ram_addr_in, 4'hc, 4'hd)) begin
            ram_addr_out <= ram_addr_in;
            d_cached <= cp0_config_in[`K23] == 3'd3;
        end
        else begin  // 32'he000_0000, 32'hffff_ffff
            ram_addr_out <= ram_addr_in;
            d_cached <= cp0_config_in[`K23] == 3'd3;
        end
    end

endmodule //  MMU
