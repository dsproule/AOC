`include "common.svh"
`include "aoc4.svh"

// memory controller used to control single bank. `MACH_N banks exist
module mem (
    input logic clock, reset,
    input logic write_en, read_en,
    input logic [`BANK_ADDR_WIDTH-1:0] row_addr_in,
    input logic [`TX_DATA_WIDTH-1:0]   partial_vec_in,
    input logic [`COL_ADDR_WIDTH-1:0]  col_addr_in,
    
    output logic ack, busy,
    output logic [`TX_DATA_WIDTH-1:0] partial_vec_out
);
    logic [`BANK_DEPTH-1:0] dirty_list;

    logic mem_init, fetch_en, addr_saved;
    logic [`GRID_VEC_ALIGN_N-1:0] bank_read_data, bank_vec_stable;
    logic [`BANK_ADDR_WIDTH-1:0]  bank_vec_addr_saved;

    assign addr_saved = (mem_init && row_addr_in == bank_vec_addr_saved);
    assign fetch_en = (read_en || write_en) && !addr_saved;

    // inferred bram
    single_port_sync_ram #(
        .ADDR_WIDTH(`BANK_ADDR_WIDTH),
        .DEPTH(`BANK_DEPTH)
    ) data (
        .clock(clock), .addr(row_addr_in),
        // .write_data(bank_vec_stable),
        .bank_en(fetch_en), .write_en(1'b0),

        .read_data(bank_read_data)
    );

    typedef enum logic {IDLE, FETCH_SAVE} bank_fetch_t;
    bank_fetch_t fetch_state, next_fetch_state;

    // easier for timing synchronization
    always_comb begin
        next_fetch_state = fetch_state;

        case (fetch_state)
            IDLE: if (fetch_en) next_fetch_state = FETCH_SAVE;
            FETCH_SAVE:         next_fetch_state = IDLE;
        endcase
    end

    assign busy = read_en || write_en;
    assign ack = addr_saved && read_en;

    // optimization
    // assign uninit_read = (!dirty_list[row_addr_in] && fetch_en); 

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

                mem_init <= 1'b1;
            end


        end
    end
    
    assign partial_vec_out = bank_vec_stable[(col_addr_in & ~(`TX_DATA_WIDTH - 1)) +: `TX_DATA_WIDTH];
    // assign addr_fetched = (row_addr_in == bank_vec_addr) && !bank_vec_addr_invalid;
    // assign partial_vec_out = ((!addr_fetched && !prev_write) || !dirty_list[row_addr_in]) ? '0 : 
    //                          (prev_write) ? bank_vec_stable[(col_addr_in & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH] :
    //                                         bank_vec_buf[(col_addr_in & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH];

    // always_comb begin
    //     fetch_en = 1'b0;
    //     next_bank_state = bank_state;
        
    //     case (bank_state)
    //         IDLE: begin
    //             if ((read_en || write_en) && (bank_vec_addr_invalid || row_addr_in != bank_vec_addr)) begin
    //                 fetch_en = 1'b1;
    //                 next_bank_state = DATA_FETCH;
    //             end
    //         end
    //         DATA_FETCH: next_bank_state = IDLE;
    //     endcase
    // end

    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         bank_state      <= IDLE;
    //         dirty_list      <= '0;
    //         write_pending   <= 1'b0;
    //         bank_vec_addr_invalid <= 1'b1;
    //         prev_write      <= 1'b0;
    //         writeback_valid <= 1'b0;
    //         ack             <= 1'b0;
        // end else begin
    //         bank_state      <= next_bank_state;
    //         write_pending   <= write_en;
    //         writeback_valid <= 1'b0;
    //         ack             <= 1'b0;

    //         if (write_pending && addr_fetched) begin
    //             dirty_list[row_addr_in] <= 1'b1;
                
    //             if (!dirty_list[row_addr_in])
    //                 bank_vec_stable <= '0;
    //             bank_vec_stable[(col_addr_in & ~(`TX_DATA_WIDTH - 1)) + 1 +: `TX_DATA_WIDTH] <= partial_vec_in;
                
    //             // forces a refetch for any read requests
    //             bank_vec_addr_invalid <= 1'b1;
    //             prev_write            <= 1'b1;
    //             writeback_valid       <= 1'b1;
    //         end else if (read_en) prev_write <= 1'b0;

    //         if (next_bank_state == DATA_FETCH)
    //             bank_vec_addr <= row_addr_in;

    //         if (addr_fetched && writeback_valid)
    //             ack <= 1;

    //         // after first usage we can rely on the address pointed to by bank_vec_addr
    //         if (read_en || write_en)
    //             bank_vec_addr_invalid <= 1'b0;

        // end
    // end
    
endmodule