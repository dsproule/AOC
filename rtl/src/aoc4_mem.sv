`include "common.svh"
`include "aoc4.svh"

// memory controller used to control single bank. `MACH_N banks exist
module Bank (
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
    logic bank_en;

    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH),
        .DEPTH(`BANK_DEPTH)
    ) bank (
        .clock(clock), .addr(owner_row_addr),
        // .write_data(bank_vec_stable),
        .bank_sel(bank_en), .write_en(1'b0),

        .read_data(bank_vec_buf)
    );

    
    typedef enum logic [3:0] {IDLE, DATA_FETCH} bank_states_t;
    bank_states_t bank_state, next_bank_state;

    assign busy = (bank_state != IDLE) && (bank_vec_addr == owner_row_addr);
    assign partial_vec_out = (owner_row_addr != bank_vec_addr || !dirty_list[owner_row_addr]) ? 
                        '0 : bank_vec_buf[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH];

    always_comb begin
        bank_en = 1'b0;
        next_bank_state = bank_state;
        ack = 1'b0;
        case (bank_state)
            IDLE: begin
                if (read_en) begin
                    bank_en = 1'b1;
                    next_bank_state = DATA_FETCH;
                end
            end
            DATA_FETCH: begin
                ack = 1'b1;
                next_bank_state = IDLE;
            end
            default: ;
        endcase
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            bank_state <= IDLE;
            // partial_vec_out <= '0;
            dirty_list <= '0;
        end else begin
            bank_state <= next_bank_state;
            // bank_write_commit <= 1'b0;
            // bank_vec_stable <= (!dirty_list[owner_row_addr]) ? '0 : bank_vec_buf;

            if (write_en) begin
                dirty_list[owner_row_addr] <= 1'b1;
            //     bank_vec_stable[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH] <= partial_vec_in;
            //     bank_write_commit <= 1'b1;
            //     ack <= 1'b1;
            end

            if (next_bank_state == DATA_FETCH)
                bank_vec_addr <= owner_row_addr;

            // if (read_en && ~ack && ~write_en) begin
            //     partial_vec_out <= bank_vec_stable[(col_addr & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH];
            //     ack <= 1'b1;
            // end
        end
    end
    
endmodule