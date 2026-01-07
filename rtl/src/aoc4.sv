`include "common.svh"
`include "aoc4.svh"

module top(
    input logic clock, reset, 
    input tb_packet_t tb_packet_in,
    input logic run_in, pad_en,

    output logic mem_ack_out, mem_busy_out,
    output logic done_out, 
    output int   updates_out
);

    // Declare machine output signals as arrays
    logic [`MACH_N-1:0] ack;
    logic re_run, sync_active;

    assign sync_active = (sync != '0);
    // int updates [`MACH_N-1:0];
    // logic [`MACH_N-1:0] mach_changed_out, mach_done_out, mach_write_en, mach_read_en;
    logic [`MACH_N-1:0] mach_changed_out, mach_done_out;
    // logic [`BANK_ADDR_WIDTH-1:0] mach_row_addr_out [`MACH_N-1:0];
    logic [`COL_ADDR_WIDTH-1:0]  sync_col_addr_out;
    logic [`TX_DATA_WIDTH-1:0]   bank_partial_vec_out [`MACH_N-1:0];

    assign mem_ack_out = |ack;

    // Debug signals
    logic tb_packet_write_en_dbg;
    logic [$clog2(`MAX_ROWS)-1:0] tb_packet_row_addr_dbg;

    assign tb_packet_row_addr_dbg = tb_packet_in.row_addr;
    assign tb_packet_write_en_dbg = tb_packet_in.write_en;

    genvar mach_i;
    generate 
        for (mach_i = 0; mach_i < `MACH_N; mach_i++) begin : mach_gen
            logic read_en, write_en;
            logic mach_changed_out, mach_done_out, mach_write_en, local_read_en;

            logic [`BANK_ADDR_WIDTH-1:0] row_addr_in, local_row_addr_out;
            logic [`TX_DATA_WIDTH-1:0]   partial_vec_in, mach_partial_vec_out, local_bank_partial_vec_out;
            logic [`COL_ADDR_WIDTH-1:0] col_addr_in, local_col_addr_out;
                
            localparam start_row = (mach_i == '0)          ?     '0    : mach_i * `BANK_DEPTH;
            localparam end_row   = (mach_i == `MACH_N - 1) ? `MAX_ROWS : mach_i * `BANK_DEPTH + `BANK_DEPTH;

            if (mach_i == 1)
                assign sync_col_addr_out = local_col_addr_out;
            assign bank_partial_vec_out[mach_i] = local_bank_partial_vec_out;

            freemachine #(
                .start_row(start_row), .end_row(end_row)
            ) mach (
                .clock(clock), .reset(reset),
                .partial_vec_in((sync_active) ? bank_partial_vec_out[mach_i - 1] : local_bank_partial_vec_out),
                .run(), .ack_in((sync_active) ? ack[mach_i - 1] : ack[mach_i]), .sync_in(sync_active),

                .changed_out(), .done_out(),
                .write_en_out(mach_write_en), .read_en_out(local_read_en), 
                .row_addr_out(local_row_addr_out), .col_addr_out(local_col_addr_out),
                .partial_vec_out(mach_partial_vec_out), .updates_out()
            );

            logic tb_packet_in_range;
            assign tb_packet_in_range = tb_packet_in.staging && (start_row <= tb_packet_in.row_addr && tb_packet_in.row_addr < end_row);

            // MUX between testbench control and machine control
            always_comb begin
                if (tb_packet_in.staging) begin
                    partial_vec_in = tb_packet_in.partial_vec;
                    row_addr_in    = tb_packet_in.row_addr;
                    col_addr_in    = tb_packet_in.col_addr;
                    read_en        = tb_packet_in.read_en;
                    write_en       = (tb_packet_in_range) ? tb_packet_in.write_en    : 1'b0;
                end else begin
                    partial_vec_in = mach_partial_vec_out;
                    row_addr_in    = local_row_addr_out;
                    col_addr_in    = (sync_active && sync == 2'b01) ? sync_col_addr_out : local_col_addr_out;
                    read_en        = (sync_active) || local_read_en;
                    write_en       = mach_write_en;
                end
            end

            // create bank that fits within space
            mem bank (
                .clock(clock), .reset(reset),
                .write_en(write_en), .read_en(read_en), .pad_en(pad_en),
                .row_addr_in((sync_active) ? -1 : row_addr_in),
                .partial_vec_in(partial_vec_in),
                .col_addr_in(col_addr_in),
                
                .ack_out(ack[mach_i]),
                .partial_vec_out(local_bank_partial_vec_out)
            );
        end 
    endgenerate

    logic [1:0] sync;
    always_ff @(posedge clock) begin
        if (reset) begin
            sync <= '0;
        end if (run_in) begin
            sync <= 2'b01;
        end if (sync_active) begin
            // if (&sync_ack_out)
        end
    end

    // int add_i;
    // logic run_started, final_sum;
    // always_ff @(posedge clock) begin
    //     if (reset) begin
    //         re_run      <= 1'b0;
    // //         run_started <= 1'b0;
    // //         updates_out <=   '0;
    // //         add_i       <=   '0;
    // //         final_sum   <= 1'b0;
    //     end else if (final_sum && add_i < `MACH_N) begin
    // //         add_i       <= add_i + 1;
    // //         updates_out <= updates_out + updates[add_i];
    //     end else if (run_started) begin
    // //         re_run <= 1'b0;
    // //         if (&mach_done_out) begin
    // //             if (~|mach_changed_out) final_sum <= 1'b1;
    // //             else re_run <= 1'b1;
    //         // end
    //     end else if (run_in) run_started <= 1'b1;
    // end

    // assign done_out = (add_i == `MACH_N);


endmodule