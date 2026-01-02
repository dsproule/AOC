module aoc4_tb;

    logic clock, reset, write_en, read_en, ack, busy;
    logic [`BANK_ADDR_WIDTH-1:0] owner_row_addr;
    logic [`TX_DATA_WIDTH-1:0]   partial_vec_in, partial_vec_out;
    logic [`COL_ADDR_WIDTH-1:0]  col_addr;

    BankController dut (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc4_tb);
    end

    int fd;
    int c;
    int done;

    initial begin
        fd = $fopen("input4.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input4.txt");

        clock    = 0;
        reset    = 1;
        read_en  = 0;
        write_en = 0;
        owner_row_addr = '0;
        partial_vec_in = '0;
        col_addr = '0;
        done     = 0;

        repeat (3) @(negedge clock);
        reset = 0;

        @(negedge clock);
        while (!done) begin
            c = $fgetc(fd);

            if (c == -1) begin
                done = 1;
            end else if (c == 10) begin
                // newline — do nothing
                
            end else begin
                // while (std::getline(file, line)) {
                //     vec = partial_row_vec_t();
                //     for (size_t col_i = 0; col_i < MAX_COLS; col_i++) {
                //         if (col_i % TX_DATA_WIDTH == 0 && col_i > 0)
                //             mem_inst.store_mem(row_i, col_i - TX_DATA_WIDTH, vec);
                //         vec[col_i % TX_DATA_WIDTH] = (line[col_i] == '@');
                //     }

                //     mem_inst.store_mem(row_i, (MAX_COLS / TX_DATA_WIDTH) * TX_DATA_WIDTH, vec);
                //     row_i++;
                // }
                
                // data_in = c - "0";
                // data_in_valid = 1'b1;
            end
            @(negedge clock);
        end

        $finish;
    end

endmodule