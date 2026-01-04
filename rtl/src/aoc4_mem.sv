`include "common.svh"
`include "aoc4.svh"

// memory controller used to control single bank. `MACH_N banks exist
module mem (
    input logic clock, reset,
    input logic write_en, read_en, pad_en, 
    input logic [`BANK_ADDR_WIDTH-1:0] row_addr_in,
    input logic [`TX_DATA_WIDTH-1:0]   partial_vec_in,
    input logic [`COL_ADDR_WIDTH-1:0]  col_addr_in,
    
    output logic ack, busy,
    output logic [`TX_DATA_WIDTH-1:0] partial_vec_out
);

    logic [`BANK_DEPTH-1:0] dirty_list;

    logic mem_init, fetch_en, addr_saved, writeback_commit;
    logic [`GRID_VEC_ALIGN_N-1:0] bank_read_data, bank_vec_stable;
    logic [`BANK_ADDR_WIDTH-1:0]  bank_vec_addr_saved;

    assign addr_saved = (mem_init && row_addr_in == bank_vec_addr_saved);
    assign fetch_en = (read_en || write_en) && !addr_saved;

    assign writeback_commit = fetch_state == WRITEBACK;

    // inferred bram
    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH),
        .DEPTH(`BANK_DEPTH)
    ) data (
        .clock(clock), .addr(row_addr_in),
        .write_data(bank_vec_stable),
        .bank_en(fetch_en || writeback_commit), .write_en(writeback_commit),

        .read_data(bank_read_data)
    );

    typedef enum logic [1:0] {IDLE, FETCH_SAVE, WRITEBACK} bank_fetch_t;
    bank_fetch_t fetch_state, next_fetch_state;

    // easier for timing synchronization. Also simulator disallows ternary assignments with types
    always_comb begin
        next_fetch_state = fetch_state;

        case (fetch_state)
            IDLE: if (fetch_en) next_fetch_state = FETCH_SAVE; 
                  else if (addr_saved && write_en) next_fetch_state = WRITEBACK;
            FETCH_SAVE: if (write_en) next_fetch_state = WRITEBACK; 
                        else next_fetch_state = IDLE;
            WRITEBACK: next_fetch_state = IDLE;
        endcase
    end

    assign busy = read_en || write_en || writeback_commit;
    assign ack  = (addr_saved && read_en) || writeback_commit;

    always_ff @(posedge clock) begin
        if (reset) begin
            fetch_state <= IDLE;
            mem_init    <= 1'b0;
            dirty_list  <=  '0;
        end else begin
            fetch_state <= next_fetch_state;

            if (fetch_state == FETCH_SAVE) begin
                bank_vec_stable     <= (!dirty_list[row_addr_in]) ? '0 : bank_read_data;
                bank_vec_addr_saved <= row_addr_in;     // assumed to not change during fetch
                if (write_en) begin

                    bank_vec_stable[`VEC_OFFSET(col_addr_in) + pad_en +: `TX_DATA_WIDTH] <= partial_vec_in;
                    dirty_list[row_addr_in] <= 1'b1;
                end

                mem_init <= 1'b1;
            end else if (addr_saved && write_en && fetch_state == IDLE) bank_vec_stable[`VEC_OFFSET(col_addr_in) + pad_en +: `TX_DATA_WIDTH] <= partial_vec_in;
        end
    end
    
    assign partial_vec_out = bank_vec_stable[`VEC_OFFSET(col_addr_in) +: `TX_DATA_WIDTH];

endmodule