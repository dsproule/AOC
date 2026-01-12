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
    
    logic [1:0] ptr_done;
    logic [`BANK_ADDR_WIDTH-1:0] ptr_head [2], ptr_end [2];
    
    logic [`BANK_ADDR_WIDTH-1:0] ptr_head_0_dbg, ptr_head_1_dbg;
    logic [`BANK_ADDR_WIDTH-1:0] ptr_end_0_dbg, ptr_end_1_dbg;
    
    assign ptr_head_0_dbg = ptr_head[0];
    assign ptr_head_1_dbg = ptr_head[1];
    // assign ptr_end_0_dbg = ptr_end[0];
    // assign ptr_end_1_dbg = ptr_end[1];

    assign ptr_done[0] = (ptr_head[0] >= ptr_end[0]);
    assign ptr_done[1] = (ptr_head[1] >= ptr_end[1]);
    
    logic [1:0] entry_valid; 
    tuple_pair_t front_pair [2], back_pair [2];
    logic [1:0] read_valid, next_read_valid;

    tuple_pair_t stage_pair [2];
    logic stage_insert;

    assign even_data_out = stage_pair[0];
    assign odd_data_out = stage_pair[1];

    always_comb begin
        next_read_valid = 2'd3;
        read_addr_out   =  '0;
        read_en_out     = 1'b0;

        if (en_in && !merge_width_done) begin
            if (!entry_valid[0] && read_valid != '0 && !ptr_done[0]) begin
                read_en_out     = 1'b1;
                next_read_valid = 2'd0;
                read_addr_out   = ptr_head[0];
            end else if (!entry_valid[1] && read_valid != 2'd1 && !ptr_done[1]) begin
                read_en_out     = 1'b1;
                next_read_valid = 2'd1;
                read_addr_out   = ptr_head[1];
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
            stage_insert     <= 1'b0;
        end else if (en_in) begin
            read_valid <= next_read_valid;

            // set the next merge-cycle
            if (merge_width_done) begin
                entry_valid      <= '0; 
                pingpong         <= ~pingpong;
                
                ptr_head[0]      <= '0;
                ptr_head[1]      <= (merge_width << 1);
                ptr_end[0]       <= (merge_width << 1);
                ptr_end[1]       <= (merge_width << 2);

                merge_width      <= (merge_width << 1);
                merge_width_done <= 1'b0;
            end else begin
                // save incoming values
                if (read_valid == 0 && !entry_valid[0]) begin
                    {front_pair[0], back_pair[0]} <= {even_data_in, odd_data_in};
                    entry_valid[0] <= 1'b1;
                end else if (read_valid == 1 && !entry_valid[1]) begin
                    {front_pair[1], back_pair[1]} <= {even_data_in, odd_data_in};
                    entry_valid[1] <= 1'b1;
                end

            end

            write_en_out <= 1'b0;
            if (write_en_out) write_addr_out <= write_addr_out + 2;

            // perform the merge
            if ((&entry_valid || (|entry_valid && |ptr_done)) && !merge_width_done) begin
                if (front_pair[0] < front_pair[1]) begin
                    front_pair[0] <= back_pair[0];
                    back_pair[0]  <= -1;
                    
                    if (ptr_head[0] & 1'b1) entry_valid[0] <= 1'b0;
                    ptr_head[0] <= ptr_head[0] + 1;

                    stage_pair[stage_insert] <= front_pair[0];
                end else begin
                    front_pair[1] <= back_pair[1];
                    back_pair[1]  <= -1;

                    if (ptr_head[1] & 1'b1) entry_valid[1] <= 1'b0;

                    ptr_head[1] <= ptr_head[1] + 1;
                    stage_pair[stage_insert] <= front_pair[1];
                end
                
                write_en_out <= stage_insert;
                stage_insert <= ~stage_insert;
            end
        end
    end

endmodule