`include "common.svh"
`include "aoc4.svh"

module Mem(
    input logic clock, reset,
    input logic [`MEM_ADDR_WIDTH-1:0] addr,
    input logic write_en, read_en, parallel_read,
    
    output logic [`TX_DATA_WIDTH-1:0] [n_banks] data_out
);
    localparam n_banks = 3;
    localparam logic [`GRID_VEC_ALIGN_N-1:0] zero_row = '0;

    logic [`GRID_VEC_ALIGN_N-1:0] bank_read_data [n_banks];
    logic [`MAX_ROWS-1:0] dirty_lines;

    genvar banks_i;
    generate for (banks_i = 0; banks_i < n_banks; banks_i++) begin
        logic [`GRID_VEC_ALIGN_N-1:0] bank_read_data_local;
        logic bank_en;

        assign bank_en = (addr % n_banks == banks_i) | parallel_read;

        single_port_sync_ram #(
            .ADDR_WIDTH(`MEM_ADDR_WIDTH),
            .DEPTH((`MAX_ROWS + n_banks - 1) / n_banks)
        ) bank (
            .clock(clock), .addr(addr),
            .write_data(bank_read_data[banks_i]),
            .bank_sel(bank_en), .write_en(),

            .read_data(bank_read_data_local)
        );

        logic read_valid;
        always_ff @(posedge clock) begin
            if (reset) begin
                read_valid <= '0;
            end else begin
                read_valid <= read_en;
                
                if (bank_en && read_valid)
                    bank_read_data[banks_i] <= (!dirty_lines[addr]) ? zero_row : bank_read_data_local;
            end
        end

        assign data_out[banks_i] = bank_read_data[addr[`MEM_ADDR_WIDTH-1:$clog2(`TX_DATA_WIDTH)]];
    end endgenerate

    always_ff @(posedge clock) begin
        if (reset) begin
            dirty_lines <= '0;
        end else begin
            if (write_en)
                dirty_lines[addr] <= 1;

        end        
    end
    
endmodule