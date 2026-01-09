module aoc5_tb;

    logic clock, reset;
    logic valid_in, asc_in, stall_in;
    logic [`ARR_8_FLAT_WIDTH-1:0] pairs_out_flat, pairs_in_flat;
    
    logic valid_out;

    sorter_8 sort_8 (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc5_tb);
    end

    task fill_8_in;
        for (int i = 0; i < 8; i++)
            `index_flat(pairs_in_flat, i) = {`DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF), 
                                            `DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF)};
    endtask

    always_ff @(posedge clock) begin
        if (1'b1 && (|sort_8.stage_valid || sort_8.valid_in || sort_8.valid_out)) begin
            if (stall_in) $display("==== STALL ====");
            $write("pairs_in(%0b): ", valid_in);
            for (int i = 0; i < 8; i++) begin
                tuple_pair_t tmp_pair;
                tmp_pair = `index_flat(pairs_in_flat, i);

                $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
            end
            $write("\nstage_1(%0b): ", sort_8.stage_valid[1]);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    sort_8.stage_1[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.stage_1[i][`DATA_WIDTH-1:0]);
            end
            $write("\nstage_2(%0b): ", sort_8.stage_valid[2]);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    sort_8.stage_2[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.stage_2[i][`DATA_WIDTH-1:0]);
            end
            $write("\nstage_3(%0b): ", sort_8.stage_valid[3]);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    sort_8.stage_3[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.stage_3[i][`DATA_WIDTH-1:0]);
            end
            $write("\nstage_4(%0b): ", sort_8.stage_valid[4]);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    sort_8.stage_4[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.stage_4[i][`DATA_WIDTH-1:0]);
            end
            $write("\nstage_5(%0b): ", sort_8.stage_valid[5]);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    sort_8.stage_5[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.stage_5[i][`DATA_WIDTH-1:0]);
            end
            $write("\npairs_out(%0b): ", valid_out);
            for (int i = 0; i < 8; i++) begin
                tuple_pair_t tmp_pair;
                tmp_pair = `index_flat(pairs_out_flat, i);

                $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
            end
            $display("\n");
        end
    end

    initial begin
        clock    = 0;
        reset    = 1;
        valid_in = 0;
        asc_in      = 1;
        stall_in    = 0;
        pairs_in_flat = '0;

        repeat (3) @(negedge clock);
        reset    = 0;
        @(negedge clock);

        repeat (3) begin
            fill_8_in;
            valid_in = 1;
            @(negedge clock);
        end
        pairs_in_flat = '0;
        valid_in = 0;
        repeat (3) @(negedge clock);
        stall_in = 1;
        @(negedge clock);
        
        // send next one
        fill_8_in;
        valid_in = 1;
        @(negedge clock);
        pairs_in_flat = '0;
        valid_in = 0;
        repeat (3) @(negedge clock);
        stall_in = 0;

        @(negedge valid_out);
        @(negedge clock);
        // print_8_in;
        // print_8_out;
        repeat (3) @(negedge clock);

        $finish;
    end

endmodule