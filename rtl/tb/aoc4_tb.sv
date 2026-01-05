`include "common.svh"
`include "aoc4.svh"

module aoc4_tb;

    logic clock, reset, run, done, changed;
    logic pad_en, mem_ack_out, mem_busy_out;
    int updates;
    tb_packet_t tb_packet;

    logic [`BANK_ADDR_WIDTH-1:0] tb_row_addr_dbg;
    logic [`TX_DATA_WIDTH-1:0]   tb_partial_vec_dbg;
    logic [`COL_ADDR_WIDTH-1:0]  tb_col_addr_dbg;

    logic tb_write_en_dbg;
    logic tb_read_en_dbg;
    logic tb_staging_dbg;

    assign tb_row_addr_dbg    = tb_packet.row_addr;
    assign tb_col_addr_dbg    = tb_packet.col_addr;
    assign tb_partial_vec_dbg = tb_packet.partial_vec;

    assign tb_write_en_dbg    = tb_packet.write_en;
    assign tb_read_en_dbg     = tb_packet.read_en;
    assign tb_staging_dbg     = tb_packet.staging;

    top dut(
        .clock(clock), .reset(reset), 
        .run_in(run), .pad_en(pad_en),
        .tb_packet_in(tb_packet),

        .mem_ack_out(mem_ack_out), .mem_busy_out(mem_busy_out),
        .done_out(done), .updates_out(updates)
    );

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc4_tb);
    end

    task print_mem;
        for (int i = 0; i < `BANK_DEPTH; i++) begin
            $display("%0d: %1b", i, dut.main_mem.data.mem[i]);
        end
    endtask

    task write_mem(
        input logic [`TX_DATA_WIDTH-1:0] partial_vec, 
        input logic [`BANK_ADDR_WIDTH-1:0] row_i, 
        input logic [`COL_ADDR_WIDTH-1:0] col_i
    );
        @(negedge clock);
        pad_en = 1'b1;
        tb_packet.write_en = 1'b1;
        tb_packet.read_en = 1'b0;
        tb_packet.partial_vec = partial_vec;
        tb_packet.row_addr = row_i;
        tb_packet.col_addr = col_i;
        if (!mem_ack_out) @(posedge mem_ack_out);
        tb_packet.write_en = 1'b0;
        pad_en = 1'b0;
        if (mem_busy_out) @(negedge mem_ack_out);
    endtask

    int fd;
    int c;
    int row_i, col_i;
    logic [`TX_DATA_WIDTH-1:0] partial_row_vec;

    initial begin
        fd = $fopen("input4.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input4.txt");

        // Initialize signals
        clock = 0;
        reset = 1;
        tb_packet.row_addr    = '0;
        tb_packet.partial_vec = '0;
        tb_packet.col_addr    = 0;
        tb_packet.staging     = 1'b1;
        row_i = 0;
        col_i = 0;
        partial_row_vec = '0;
        run = 0;
        tb_packet.read_en  = 0;
        tb_packet.write_en = 0;

        repeat (3) @(negedge clock);
        reset = 0;

        // Load memory from file
        @(negedge clock);
        while (tb_packet.staging) begin
            c = $fgetc(fd);

            if (c == -1) begin
                tb_packet.staging = 1'b0;
            end else if (c == 10) begin
                write_mem(partial_row_vec, row_i, (`MAX_COLS / `TX_DATA_WIDTH) * `TX_DATA_WIDTH);
                col_i = 0;
                row_i++;
            end else begin
                if (col_i % `TX_DATA_WIDTH == 0 && col_i > 0) begin
                    write_mem(partial_row_vec, row_i, col_i - `TX_DATA_WIDTH);
                    partial_row_vec = '0;
                end
                partial_row_vec[col_i % `TX_DATA_WIDTH] = (c == "@");
                col_i++;
            end
        end
        
        if (col_i != 0) write_mem(partial_row_vec, row_i, (`MAX_COLS / `TX_DATA_WIDTH) * `TX_DATA_WIDTH);
        
        @(negedge clock);
        print_mem;

        // Run the machine
        run = 1;
        @(negedge clock);
        run = 0;
        @(posedge done);
        @(posedge clock);

        $display();
        print_mem;
        $display("Updates: %0d", updates);
        
        $finish;
    end

endmodule