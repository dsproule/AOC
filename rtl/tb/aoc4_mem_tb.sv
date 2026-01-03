module aoc4_tb;

    logic clock, reset, write_en, read_en, ack, busy;
    logic [`BANK_ADDR_WIDTH-1:0] row_addr_in;
    logic [`TX_DATA_WIDTH-1:0]   partial_vec_in, partial_vec_out;
    logic [`COL_ADDR_WIDTH-1:0]  col_addr_in;

    mem dut (.*);
    
    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc4_tb);
    end

    task print_mem;
        for (int i = 0; i < `BANK_DEPTH; i++) begin
            $display("%0d: %0d", i, dut.data.mem[i]);
        end
    endtask

    task write_mem(input logic [`TX_DATA_WIDTH-1:0] partial_vec, 
                    input logic [`BANK_ADDR_WIDTH-1:0] row_i, 
                    input logic [`COL_ADDR_WIDTH-1:0] col_i);
        @(negedge clock);
        write_en = 1'b1;
        partial_vec_in = partial_vec;
        row_addr_in = row_i;
        col_addr_in = col_i;
        @(negedge clock);
        write_en = 1'b0;
        repeat (4) @(negedge clock);
    endtask
    
    task read_mem(input logic [`BANK_ADDR_WIDTH-1:0] row_i, input logic [`COL_ADDR_WIDTH-1:0] col_i);
        @(negedge clock);
        write_en = 1'b0;
        read_en = 1'b1;
        row_addr_in = row_i;
        col_addr_in = col_i;
        @(negedge clock);
        if (!ack) @(posedge ack);
        @(posedge clock);
        read_en = 1'b0;
    endtask

    initial begin
        clock = 0;
        reset = 1;
        read_en = 0;
        write_en = 0;
        row_addr_in = '0;
        partial_vec_in = '0;
        col_addr_in = '0;

        repeat (3) @(negedge clock);
        reset = 0;
        // before storing was implemented, seed with state
        dut.data.mem[0] = (1234 << 1);
        dut.data.mem[0] |= (4567 << 5);
        dut.dirty_list[0] = 1;
        // dut.data.mem[1] = (4444 << 1);
        // dut.dirty_list[1] = 1;
        // dut.data.mem[2] = (98765 << 1);
        // dut.dirty_list[2] = 1;

        @(negedge clock);
        // test for multiple polls on same line
        read_mem(0, 0);
        read_mem(0, 6);
        read_mem(0, 8);
        // read_mem(0, 6);
        // assert (partial_vec_out == 1234);
        // read_mem(0, 34);
        // assert (partial_vec_out == 4567);
        // read_mem(1, 34);
        // assert (partial_vec_out == 0);
        // read_mem(1, 0);
        // assert (partial_vec_out == 4444);
        // @(negedge clock);
        // write_mem(1234, 4, 0);
        // write_mem(1232, 4, 0);
        // assert (partial_vec_out == 1232);
        // write_mem(7777, 4, 33);
        // read_mem(4, 33);
        // assert (partial_vec_out == 7777);

        $finish;
    end

endmodule