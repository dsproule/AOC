`include "common.svh"
`include "aoc4.svh"

// memory controller used to control single bank. `MACH_N banks exist
module BankController (
    input logic clock, reset,
    input logic write_en, read_en,
    input logic [`BANK_ADDR_WIDTH-1:0] owner_row_addr,
    input logic [`TX_DATA_WIDTH-1:0]   partial_vec_in,
    input logic [`COL_ADDR_WIDTH-1:0]  col_addr,
    
    output logic ack, busy,
    output logic [`TX_DATA_WIDTH-1:0] partial_vec_out
);
    logic [`BANK_DEPTH-1:0] dirty_list;

    logic [`GRID_VEC_ALIGN_N-1:0] bank_vec_buf, bank_vec_stable;
    logic [`BANK_ADDR_WIDTH-1:0]  bank_vec_addr;
    logic fetch_en;

    // inferred bram
    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH),
        .DEPTH(`BANK_DEPTH)
    ) bank (
        .clock(clock), .addr(owner_row_addr),
        .write_data(bank_vec_stable),
        .bank_en(fetch_en | writeback_valid), .write_en(writeback_valid),

        .read_data(bank_vec_buf)
    );

    typedef enum logic {IDLE, DATA_FETCH} bank_fetch_t;
    bank_fetch_t bank_state, next_bank_state;

    assign busy = (bank_state != IDLE) && (bank_vec_addr == owner_row_addr);
    
    logic bank_vec_addr_invalid, addr_fetched;
    logic write_pending, prev_write, writeback_valid;
    assign addr_fetched = (owner_row_addr == bank_vec_addr) && !bank_vec_addr_invalid;
    assign partial_vec_out = ((!addr_fetched && !prev_write) || !dirty_list[owner_row_addr]) ? '0 : 
                             (prev_write) ? bank_vec_stable[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH] :
                                            bank_vec_buf[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH];

    always_comb begin
        fetch_en = 1'b0;
        next_bank_state = bank_state;
        ack = 1'b0 || ((read_en || write_en) && (owner_row_addr == bank_vec_addr) && !bank_vec_addr_invalid);
        case (bank_state)
            IDLE: begin
                if ((read_en || write_en) && (bank_vec_addr_invalid || owner_row_addr != bank_vec_addr)) begin
                    fetch_en = 1'b1;
                    next_bank_state = DATA_FETCH;
                end
            end
            DATA_FETCH: begin
                ack = 1'b1;
                next_bank_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            bank_state <= IDLE;
            write_pending <= 1'b0;
            dirty_list <= '0;
            bank_vec_addr_invalid <= 1'b1;
            prev_write <= 1'b0;
        end else begin
            bank_state      <= next_bank_state;
            write_pending   <= write_en;
            writeback_valid <= 1'b0;

            if (write_pending && addr_fetched) begin
                dirty_list[owner_row_addr] <= 1'b1;
                
                if (!dirty_list[owner_row_addr])
                    bank_vec_stable <= '0;
                bank_vec_stable[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH] <= partial_vec_in;
                
                // forces a refetch for any read requests
                bank_vec_addr_invalid <= 1'b1;
                writeback_valid <= 1'b1;
                prev_write <= 1'b1;
            end else if (read_en) prev_write <= 1'b0;

            if (next_bank_state == DATA_FETCH)
                bank_vec_addr <= owner_row_addr;

            // after first usage we can rely on the address pointed to by bank_vec_addr
            if (read_en || write_en)
                bank_vec_addr_invalid <= 1'b0;

        end
    end
    
endmodule