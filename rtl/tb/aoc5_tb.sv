`include "common.svh"
`include "aoc5.svh"

module aoc5_tb;
    logic clock, reset, data_valid_in, stream_done_in;
    logic [`BANK_ADDR_WIDTH-1:0] tb_addr_in;
    tuple_pair_t even_data_in, odd_data_in;
    
    top dut(.*);
    
    initial forever #5 clock = ~clock;
    
    initial begin
        $dumpfile("aoc.vcd");
        $dumpvars(0, aoc5_tb);
    end

    // always_ff @(posedge dut.sort_16_in_valid) begin
        // $write("\npairs_in(%0b): ", dut.sort_16_in_valid);
        //     for (int i = 0; i < 16; i++) begin
        //         tuple_pair_t tmp_pair;
        //         tmp_pair = `index_flat(dut.sort_16_pairs_in_flat, i);

        //         $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
        //     end
        // $display("\n");
    // end

    always_ff @(posedge clock) begin
    //     if (dut.sort_16.bitonics_ready == 2'b11) begin
    //         $display();
    //         $write("top_stage: ");
    //         for (int i = 0; i < 8; i++) begin
    //             tuple_pair_t tmp_pair;
    //             tmp_pair = `index_flat(dut.sort_16.top_stage, i);

    //             $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
    //         end
    //         $display("");
    //         $write("low_stage: ");
    //         for (int i = 0; i < 8; i++) begin
    //             tuple_pair_t tmp_pair;
    //             tmp_pair = `index_flat(dut.sort_16.low_stage, i);

    //             $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
    //         end
    //         $display("\n");
    //     end

        // if (dut.sort_16_out_valid) begin
        //     $write("\npairs_out(%0b): ", dut.sort_16_out_valid);
        //         for (int i = 0; i < 16; i++) begin
        //             tuple_pair_t tmp_pair;
        //             tmp_pair = `index_flat(dut.sort_16_pairs_out_flat, i);

        //             $write("(%0d, %0d) ", tmp_pair.first, tmp_pair.second);
        //         end
        //     $display("\n");
        // end
    end

    task print_ping;
        tuple_pair_t pair;
        for (int i = 0; i < (`BANK_DEPTH); i = i + 2) begin
            pair = dut.mem_ping.bank_even.mem[i];
            $display("%0d-%0d", pair.first, pair.second);
            pair = dut.mem_ping.bank_odd.mem[i];
            $display("%0d-%0d", pair.first, pair.second);
        end
    endtask
    
    task print_pong(input int print_depth);
        tuple_pair_t pair;
        for (int i = 0; i < print_depth; i = i + 2) begin
            pair = dut.mem_pong.bank_even.mem[i];
            $display("%3d: %0d-%0d", i, pair.first, pair.second);
            pair = dut.mem_pong.bank_odd.mem[i];
            $display("%3d: %0d-%0d", i + 1, pair.first, pair.second);
        end
    endtask
    
    task print_merge_regs;
        // tuple_pair_t pair;
        // pair = dut.write_back_regs[0];
        // $display("reg[0]: %0d-%0d", pair.first, pair.second);
        // pair = dut.write_back_regs[1];
        // $display("reg[1]: %0d-%0d\n", pair.first, pair.second);
    endtask

    always_ff @(posedge clock) begin
        // if (dut.write_back_valid) begin
            // print_merge_regs;
        // end
    end 
    
    int fd;
    int c;
    int done;
    logic [`DATA_WIDTH-1:0] nums [4];  // Store 4 numbers: even_first, even_second, odd_first, odd_second
    int num_idx, digit_val;
    
    initial begin
        fd = $fopen("input5.txt", "r");
        if (fd == 0) $fatal(1, "ERROR: Could not open input5.txt");
        
        clock = 0;
        reset = 1;
        data_valid_in = 0;
        tb_addr_in = 0;
        stream_done_in = 0;
        
        repeat (3) @(negedge clock);
        reset = 0;
        done = 0;
        
        while (!done) begin
            // Parse first line (even): xxx-xxx
            num_idx = 0;
            nums[0] = 0;
            nums[1] = 0;
            
            // Read first number
            c = $fgetc(fd);
            while (c >= "0" && c <= "9") begin
                nums[0] = nums[0] * 10 + (c - "0");
                c = $fgetc(fd);
            end
            
            // Skip the '-'
            if (c == "-") c = $fgetc(fd);
            
            // Read second number
            while (c >= "0" && c <= "9") begin
                nums[1] = nums[1] * 10 + (c - "0");
                c = $fgetc(fd);
            end
            
            // Skip to end of line
            while (c != 10 && c != -1) c = $fgetc(fd);
            
            // Check for empty line (end condition)
            c = $fgetc(fd);
            if (c == 10 || c == -1) begin
                done = 1;
            end else begin
            
                // Parse second line (odd): zzz-zzz
                nums[2] = 0;
                nums[3] = 0;
                
                // Read first number
                while (c >= "0" && c <= "9") begin
                    nums[2] = nums[2] * 10 + (c - "0");
                    c = $fgetc(fd);
                end
                
                // Skip the '-'
                if (c == "-") c = $fgetc(fd);
                
                // Read second number
                while (c >= "0" && c <= "9") begin
                    nums[3] = nums[3] * 10 + (c - "0");
                    c = $fgetc(fd);
                end
                
                // Skip to end of line
                while (c != 10 && c != -1) c = $fgetc(fd);
                
                // Pack into tuple_pair_t structures
                even_data_in.first  = nums[0];
                even_data_in.second = nums[1];
                odd_data_in.first   = nums[2];
                odd_data_in.second  = nums[3];
                // $display("%0d-%0d", even_data_in.first, even_data_in.second);
                // $display("%0d-%0d", odd_data_in.first, odd_data_in.second);
                
                // Assert valid and wait
                data_valid_in = 1'b1;
                @(negedge clock);
                data_valid_in = 1'b0;
                
                tb_addr_in = tb_addr_in + 2;
            end 
        end
        stream_done_in = 1;
        repeat (200) @(negedge clock);
        
        // print_mem;
        // print_merge_regs;
        print_pong(205);
        // print_ping;
        $display("Done loading data");
        $fclose(fd);
        $finish;
    end
endmodule