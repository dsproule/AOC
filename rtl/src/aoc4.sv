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

    logic ack, busy, re_run;
    logic read_en, write_en;
    logic [`BANK_ADDR_WIDTH-1:0] row_addr_in;
    logic [`TX_DATA_WIDTH-1:0]   partial_vec_in, bank_partial_vec_out;
    logic [`COL_ADDR_WIDTH-1:0]  col_addr_in;

    // Declare machine output signals as arrays
    int updates [`MACH_N-1:0];
    logic [`MACH_N-1:0] mach_changed_out, mach_done_out, mach_write_en, mach_read_en;
    logic [`BANK_ADDR_WIDTH-1:0] mach_row_addr_out [`MACH_N-1:0];
    logic [`COL_ADDR_WIDTH-1:0] mach_col_addr_out [`MACH_N-1:0];
    logic [`TX_DATA_WIDTH-1:0] mach_partial_vec_out [`MACH_N-1:0];

    mem main_mem (
        .clock(clock), .reset(reset),
        .write_en(write_en), .read_en(read_en), .pad_en(pad_en),
        .row_addr_in(row_addr_in),
        .partial_vec_in(partial_vec_in),
        .col_addr_in(col_addr_in),
        
        .ack(ack), .busy(busy),
        .partial_vec_out(bank_partial_vec_out)
    );

    assign mem_ack_out = ack;
    assign mem_busy_out = busy;

    logic [`MACH_N-1:0] reqs, gnt;
    int arb_i;

    arb arbiter(
        .clock(clock), .reset(reset),
        .reqs_in(reqs), .ack_in(ack),

        .gnt_out(gnt), .i_out(arb_i)
    );

    genvar mach_i;
    generate 
        for (mach_i = 0; mach_i < `MACH_N; mach_i++) begin : mach_gen
            int start_row_dbg, end_row_dbg;

            assign start_row_dbg = mach_i * `MACH_ROWS;
            assign end_row_dbg   = (mach_i == `MACH_N - 1) ? `MAX_ROWS : mach_i * `MACH_ROWS + `MACH_ROWS + 1;

            assign reqs[mach_i] = (mach_write_en[mach_i] | mach_read_en[mach_i]);

            freemachine #(
                .start_row(mach_i * `MACH_ROWS), .end_row((mach_i == `MACH_N - 1) ? `MAX_ROWS : mach_i * `MACH_ROWS + `MACH_ROWS + 1)
            ) mach (
                .clock(clock), .reset(reset),
                .partial_vec_in(bank_partial_vec_out),
                .run(run_in | re_run), .ack_in(gnt[mach_i] && ack && !tb_packet_in.staging),

                .changed_out(mach_changed_out[mach_i]), .done_out(mach_done_out[mach_i]),  
                .write_en_out(mach_write_en[mach_i]), .read_en_out(mach_read_en[mach_i]),
                .row_addr_out(mach_row_addr_out[mach_i]), .col_addr_out(mach_col_addr_out[mach_i]),
                .partial_vec_out(mach_partial_vec_out[mach_i]), .updates_out(updates[mach_i])
            );
        end 
    endgenerate

    logic run_started;
    always_ff @(posedge clock) begin
        if (reset) begin
            re_run      <= 1'b0;
            run_started <= 1'b0;
            done_out    <= 1'b0;
            updates_out <=   '0;
        end else if (run_started) begin
            re_run <= 1'b0;
            if (&mach_done_out) begin
                if (~|mach_changed_out) begin
                    updates_out <= updates[0];
                    done_out <= 1'b1;
                end else re_run <= 1'b1;
            end
        end else if (run_in) run_started <= 1'b1;
    end

    // MUX between testbench control and machine control
    assign partial_vec_in = (tb_packet_in.staging) ? tb_packet_in.partial_vec : mach_partial_vec_out[arb_i];
    assign row_addr_in    = (tb_packet_in.staging) ? tb_packet_in.row_addr    : mach_row_addr_out[arb_i];
    assign col_addr_in    = (tb_packet_in.staging) ? tb_packet_in.col_addr    : mach_col_addr_out[arb_i];
    assign read_en        = (tb_packet_in.staging) ? tb_packet_in.read_en     : mach_read_en[arb_i];
    assign write_en       = (tb_packet_in.staging) ? tb_packet_in.write_en    : mach_write_en[arb_i];

endmodule