module merge_phase(
    input logic clock, reset, 
    input logic en_in,

    // read path
    input  tuple_pair_t even_data_in, odd_data_in,
    output logic [`BANK_ADDR_WIDTH-1:0] read_addr_out,
    output logic read_en_out,

    // write path
    output tuple_pair_t even_data_out, odd_data_out,
    output logic [`BANK_ADDR_WIDTH-1:0] write_addr_out,
    output logic write_en_out,

    output logic phase_done_out, pingpong
);
    localparam start_width = 16;

    logic merge_width_done;
    int merge_width;
    
    logic [`BANK_ADDR_WIDTH-1:0] ptr_head [2], ptr_end [2];
    logic [`BANK_ADDR_WIDTH-1:0] ptr_head_0_dbg, ptr_head_1_dbg;
    logic [`BANK_ADDR_WIDTH-1:0] ptr_end_0_dbg, ptr_end_1_dbg;
    
    assign ptr_head_0_dbg = ptr_head[0];
    assign ptr_head_1_dbg = ptr_head[1];
    assign ptr_end_0_dbg = ptr_end[0];
    assign ptr_end_1_dbg = ptr_end[1];
    
    logic [1:0] entry_valid; 
    tuple_pair_t front_pair [2];
    tuple_pair_t back_pair [2];

    logic [1:0] read_valid, next_read_valid;

    // there are 4 merge shift scenarios. 
    // Both fronts are min values, One side is the mins (the permutations that form this)
    merge_t merge_code;

    always_comb begin
        next_read_valid = 2'd3;
        read_addr_out   =  '0;
        read_en_out     = 1'b0;
        merge_code      = MERGE_FRONT_0_MIN;
        write_en_out    = 1'b0;
        even_data_out   = '0;
        odd_data_out   = '0;

        if (en_in && !merge_width_done) begin
            if (~&entry_valid) begin

                if (!entry_valid[0] && read_valid != '0) begin
                    read_en_out = 1'b1;
                    read_addr_out   = ptr_head[0];
                    next_read_valid = 2'd0;
                end else if (!entry_valid[1] && read_valid != 2'd1) begin
                    read_en_out = 1'b1;
                    next_read_valid = 2'd1;
                    read_addr_out = ptr_head[1];
                end

            end else begin
                // writes the value 
                write_en_out = 1'b1;
                
                if (front_pair[0] < front_pair[1]) begin
                    even_data_out = front_pair[0];

                    if (back_pair[0] < front_pair[1]) begin
                        odd_data_out = back_pair[0];
                        merge_code = MERGE_0;
                    end else begin
                        odd_data_out = front_pair[1];
                        merge_code = MERGE_FRONT_0_MIN;
                    end
                end else begin
                    even_data_out = front_pair[1];

                    if (back_pair[1] < front_pair[0]) begin
                        odd_data_out = back_pair[1];
                        merge_code = MERGE_1;
                    end else begin
                        odd_data_out = front_pair[0];
                        merge_code = MERGE_FRONT_1_MIN;
                    end
                end

            end
        end
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            pingpong         <= 1'b1;
            merge_width      <= (start_width >> 1);
            merge_width_done <= 1'b1;
            entry_valid      <= 2'b0;
            ptr_head[0]      <= '0;
            ptr_head[1]      <= '0;
            write_addr_out   <= '0;
            read_valid       <=  3;
        end else if (en_in) begin
            read_valid <= next_read_valid;

            // set the next merge-cycle
            if (merge_width_done) begin
                entry_valid      <= '0; 
                pingpong         <= ~pingpong;
                
                ptr_head[0]      <= '0;
                ptr_head[1]      <= (merge_width << 1);
                ptr_end[0]       <= (merge_width << 1);
                ptr_end[1]      <= (merge_width << 2);

                merge_width      <= (merge_width << 1);
                merge_width_done <= 1'b0;
            end  else begin
                // save incoming values
                if (read_valid == 0 && !entry_valid[0]) begin
                    {front_pair[0], back_pair[0]} <= {even_data_in, odd_data_in};
                    entry_valid[0] <= 1'b1;
                end else if (read_valid == 1 && !entry_valid[1]) begin
                    {front_pair[1], back_pair[1]} <= {even_data_in, odd_data_in};
                    entry_valid[1] <= 1'b1;
                end

            end

            // perform the merge
            if (&entry_valid && !merge_width_done) begin
                write_addr_out <= write_addr_out + 2;
                // perform the shift. invalidates an entry and increments counters
                case (merge_code)
                    MERGE_0: begin
                        entry_valid[0] <= 1'b0;
                        front_pair[0] <= -1;
                        ptr_head[0] <= ptr_head[0] + 2;
                    end
                    MERGE_1: begin
                        entry_valid[1] <= 1'b0;
                        front_pair[1] <= -1;
                        ptr_head[1] <= ptr_head[1] + 2;
                    end
                    MERGE_FRONT_0_MIN, MERGE_FRONT_1_MIN: begin
                        front_pair[0] <= back_pair[0];
                        back_pair[0]  <= -1;
                        front_pair[1] <= back_pair[1];
                        back_pair[1]  <= -1;

                        if (ptr_head[0] & 1'b1) entry_valid[0] <= 1'b0;
                        if (ptr_head[1] & 1'b1) entry_valid[1] <= 1'b0;

                        ptr_head[0] <= ptr_head[0] + 1;
                        ptr_head[1] <= ptr_head[1] + 1;
                    end

                endcase

            end
        end
    end

endmodule