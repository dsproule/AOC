module aoc5_tb;

    logic clock, reset;
    logic valid_in;
    tuple_pair_t pairs_in [8];
    tuple_pair_t pairs_out [8];
    
    logic valid_out;

    sorter_8 #(.asc(1)) sort_8 (.*);

    initial forever #5 clock = ~clock;

    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc5_tb);
    end

    task clear_8_in;
        for (int i = 0; i < 8; i++)
            pairs_in[i] = '0;
    endtask

    task fill_8_in;
        for (int i = 0; i < 8; i++)
            pairs_in[i] = {`DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF), 
                           `DATA_WIDTH'(($random / 1_000_000) & 32'hFFFF_FFFF)};
    endtask

    always_ff @(posedge clock) begin
        if (1'b1 && (|sort_8.stage_valid || sort_8.valid_in || sort_8.valid_out)) begin
            $write("pairs_in(%0b): ", valid_in);
            for (int i = 0; i < 8; i++) begin
                $write("(%0d, %0d) ", 
                    pairs_in[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    pairs_in[i][`DATA_WIDTH-1:0]);
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
                $write("(%0d, %0d) ", 
                    sort_8.pairs_out[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                    sort_8.pairs_out[i][`DATA_WIDTH-1:0]);
            end
            $display("\n");
        end
    end

    tuple_pair_t pairs_out_0_dbg;
    assign pairs_out_0_dbg = pairs_out[0];

    tuple_pair_t pairs_out_1_dbg;
    assign pairs_out_1_dbg = pairs_out[1];

    tuple_pair_t pairs_out_2_dbg;
    assign pairs_out_2_dbg = pairs_out[2];

    tuple_pair_t pairs_out_3_dbg;
    assign pairs_out_3_dbg = pairs_out[3];

    tuple_pair_t pairs_out_4_dbg;
    assign pairs_out_4_dbg = pairs_out[4];

    tuple_pair_t pairs_out_5_dbg;
    assign pairs_out_5_dbg = pairs_out[5];

    tuple_pair_t pairs_out_6_dbg;
    assign pairs_out_6_dbg = pairs_out[6];

    tuple_pair_t pairs_out_7_dbg;
    assign pairs_out_7_dbg = pairs_out[7];


    task print_8_in;
        for (int i = 0; i < 8; i++) begin
            $write("(%0d, %0d) ", 
                pairs_in[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                pairs_in[i][`DATA_WIDTH-1:0]);
        end
        $display();
    endtask

    task print_8_out;
        for (int i = 0; i < 8; i++) begin
            $write("(%0d, %0d) ", 
                pairs_out[i][2*`DATA_WIDTH-1:`DATA_WIDTH],  // first
                pairs_out[i][`DATA_WIDTH-1:0]);
        end
        $display();
    endtask

    initial begin
        clock    = 0;
        reset    = 1;
        valid_in = 0;

        repeat (3) @(negedge clock);
        reset    = 0;
        @(negedge clock);

        fill_8_in;
        valid_in = 1;
        @(negedge clock);
        clear_8_in;
        valid_in = 0;

        @(posedge valid_out);
        @(negedge clock);
        // print_8_in;
        // print_8_out;
        repeat (3) @(negedge clock);

        $finish;
    end

endmodule