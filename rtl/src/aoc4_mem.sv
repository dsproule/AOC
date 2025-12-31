// class Mem {
//  public:
//     using tile_map = std::array<std::array<bool, 3>, 3>;
//     using bank_vec_t = std::array<bool, MAX_COLS + 2>;
    
//     static constexpr size_t n_banks = 3;
//     static constexpr bank_vec_t zero_row_{};

//     void store_mem(size_t row_i, size_t col_i, bool value) {
//         bank_vec_t bank_vec = (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i % n_banks][row_i / n_banks];
//         col_i++;
        
//         dirty_list_[row_i] = true;
//         bank_vec[col_i] = value;

//         bram_banks_[row_i % n_banks][row_i / n_banks] = bank_vec;
//     }

//     bank_vec_t load_vec(size_t row_i) {
//         return (!dirty_list_[row_i]) ? zero_row_ : bram_banks_[row_i % n_banks][row_i / n_banks];
//     }

//  private: 
//     // looks much worse than it is. index by bram[bank][row][col]
//     std::array<std::array<std::array<bool, MAX_COLS + 2>, (MAX_ROWS + n_banks - 1) / n_banks>, n_banks> bram_banks_;
//     std::array<bool, MAX_ROWS> dirty_list_{};
// };
`define MAX_ROWS 139
`define MAX_COLS `MAX_ROWS
`define BANK_WIDTH `MAX_COLS + 2

typedef enum logic [1:0] {MEM_IDLE, MEM_LD, MEM_ST} mem_cmd_t;

module Mem(
    input logic clock, reset, 
    input logic [$clog2(`MAX_ROWS)-1:0] addr
);
    
    typedef logic [`MAX_COLS + 2 - 1:0] bank_vec_t;
    localparam n_lines = (`MAX_ROWS + n_banks - 1) / n_banks;
    localparam n_banks = 3;

    logic [`MAX_ROWS-1:0] dirty_list;

    genvar banks;
    generate for (banks = 0; banks < n_banks; banks++) begin
        single_port_sync_ram #(
            .ADDR_WIDTH(4),
            .DATA_WIDTH(`BANK_WIDTH),
            .DEPTH((`MAX_ROWS + n_banks - 1) / n_banks)
        ) bank (
            .clock(clock),
            .addr(addr), .write_data(`BANK_WIDTH),
            .bank_sel(), .write_en(),

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