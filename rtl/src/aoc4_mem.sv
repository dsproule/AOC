`include "common.svh"

`define MAX_ROWS 139
`define MAX_COLS `MAX_ROWS
`define BANK_WIDTH `MAX_COLS + 2
`define BANK_ROW_DEPTH (`MAX_ROWS + n_banks - 1) / n_banks

typedef enum logic [1:0] {MEM_IDLE, MEM_LD, MEM_ST} mem_cmd_t;

module Mem(
    input logic clock, reset, 
    input logic [$clog2(`BANK_ROW_DEPTH)-1:0] addr
);
    
    typedef logic [`BANK_WIDTH - 1:0] bank_vec_t;
    localparam n_banks = 3;

    logic [`MAX_ROWS-1:0] dirty_list;

    genvar bank_i;
    generate for (bank_i = 0; bank_i < n_banks; bank_i++) begin
        single_port_sync_ram #(
            .ADDR_WIDTH($clog2(`BANK_ROW_DEPTH)),
            .DATA_WIDTH(`BANK_WIDTH),
            .DEPTH(`BANK_ROW_DEPTH)
        ) bank (
            .clock(clock),
            .addr(addr), .write_data(),
            .bank_sel(addr % n_banks == bank_i), .write_en(),

            .read_data()
        );    
    end endgenerate

    bank_vec_t zero_row;

    always_ff @(posedge clock) begin
        if (reset) begin
            zero_row   <= '0;
            dirty_list <= '0;
        end else begin

        end        
    end
    

endmodule