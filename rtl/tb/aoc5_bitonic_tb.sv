module aoc5_tb;

    logic clock, reset;
    logic valid_in, valid_out, stall_in;
    logic [`ARR_16_FLAT_WIDTH-1:0] pairs_out_flat, pairs_in_flat;

    bitonic_sort_16 sort_16 (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc5_tb);
    end

    task fill_16_in;
        for (int i = 0; i < 16; i++)
            `index_flat(pairs_in_flat, i) = {`DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF), 
                                            `DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF)};
    endtask

    always_ff @(posedge clock) begin
        if (1'b0 && sort_16.sort_8_done) begin
            for (int i = 0; i < 8; i++) begin
                tuple_pair_t tmp_pair;
                tmp_pair = `index_flat(sort_16.monotonic_stage, i);

                $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
            end
            $display("");
        end

        if (sort_16.bitonics_ready == 2'b11) begin
            $write("top_stage: ");
            for (int i = 0; i < 8; i++) begin
                tuple_pair_t tmp_pair;
                tmp_pair = `index_flat(sort_16.top_stage, i);

                $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
            end
            $display("");
            $write("low_stage: ");
            for (int i = 0; i < 8; i++) begin
                tuple_pair_t tmp_pair;
                tmp_pair = `index_flat(sort_16.low_stage, i);

                $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
            end
            $display("");
        end

        if (valid_out) begin
            $write("\npairs_out(%0b): ", valid_out);
                for (int i = 0; i < 16; i++) begin
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
        pairs_in_flat = '0;
        stall_in = 0;

        repeat (3) @(negedge clock);
        reset    = 0;
        @(negedge clock);

        fill_16_in;
        valid_in = 1;
        repeat (2) @(negedge clock);
        pairs_in_flat = '0;
        valid_in = 0;

        @(posedge valid_out);
        // repeat (50) @(negedge clock);
        // print_8_in;
        // print_8_out;
        repeat (3) @(negedge clock);

        $finish;
    end

endmodule