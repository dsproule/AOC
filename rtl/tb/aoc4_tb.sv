`include "common.svh"

module aoc4_tb;

    logic clock, reset;
    logic [`BANK_ADDR_WIDTH-1:0] row_addr_in, tb_row_addr_in, mach_row_addr_out;
    logic tb_write_en, tb_read_en, mach_write_en, mach_read_en, ack, busy;
    logic [`TX_DATA_WIDTH-1:0]   partial_vec_in, tb_partial_vec_in, bank_partial_vec_out, mach_partial_vec_out;
    logic [`COL_ADDR_WIDTH-1:0]  col_addr_in, tb_col_addr_in, mach_col_addr_out;

    mem main_mem (
        .clock(clock), .reset(reset),
        .write_en(write_en), .read_en(read_en),
        .row_addr_in(row_addr_in),
        .partial_vec_in(partial_vec_in),
        .col_addr_in(col_addr_in),
    
        .ack(ack), .busy(busy),
        .partial_vec_out(bank_partial_vec_out)
    );

    logic run;
    freemachine #(.start_row(0), .end_row(`BANK_DEPTH) ) mach (
        .clock(clock), .reset(reset),
        .partial_vec_in(bank_partial_vec_out),
        .run(run), .ack_in(ack && done),

        .changed_out(), .done_out(), .write_en_out(mach_write_en), .read_en_out(mach_read_en),
        .row_addr_out(mach_row_addr_out), .col_addr_out(mach_col_addr_out),
        .partial_vec_out(mach_partial_vec_out)
    );

    assign partial_vec_in = (!done) ? tb_partial_vec_in : mach_partial_vec_out;
    assign row_addr_in    = (!done) ? tb_row_addr_in : mach_row_addr_out;
    assign col_addr_in    = (!done) ? tb_col_addr_in : mach_col_addr_out;
    assign read_en        = (!done) ? tb_read_en : mach_read_en;
    assign write_en        = (!done) ? tb_write_en : mach_write_en;

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc4_tb);
    end

    task print_mem;
        for (int i = 0; i < `BANK_DEPTH; i++) begin
            $display("%0d: %1b", i, main_mem.data.mem[i]);
        end
    endtask
    
    task print_regs;
        for (int i = 0; i < 3; i++) begin
            $display("%0d: %1b", i, mach.regs[i]);
        end
    endtask

    task write_mem(input logic [`TX_DATA_WIDTH-1:0] partial_vec, 
                    input logic [`BANK_ADDR_WIDTH-1:0] row_i, 
                    input logic [`COL_ADDR_WIDTH-1:0] col_i);
        @(negedge clock);
        tb_write_en = 1'b1;
        tb_read_en = 1'b0;
        tb_partial_vec_in = partial_vec;
        tb_row_addr_in = row_i;
        tb_col_addr_in = col_i;
        if (!ack) @(posedge ack);
        tb_write_en = 1'b0;
        if (busy) @(negedge ack);
    endtask

    int fd;
    int c;
    int done;

    int row_i, col_i;
    logic [`TX_DATA_WIDTH-1:0] partial_row_vec;

    initial begin
        fd = $fopen("input4.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input4.txt");

        clock    = 0;
        reset    = 1;
        tb_row_addr_in = '0;
        tb_partial_vec_in = '0;
        tb_col_addr_in = 0;
        done     = 0;
        row_i    = 0;
        col_i    = 0;
        partial_row_vec = '0;
        run = 0;
        tb_read_en  = 0;
        tb_write_en = 0;

        repeat (3) @(negedge clock);
        reset = 0;

        // initialization of banks
        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);

            if (c == -1) begin
                done = 1;
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

        // deploy the machines
        run = 1;
        @(negedge clock);
        run = 0;

        @(negedge mach.regs_valid);
        repeat (1000) @(negedge clock);
        $display();
        print_regs;
        $finish;
    end

endmodule