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
    int ptr_head [2], ptr_end [2];
    logic [1:0] entry_valid; 

    // always_comb begin
    //     read_addr_out =  '0;
    //     read_en       = 1'b0;
    //     if (~&entry_valid) begin
    //         if (!entry_valid[0]) begin
    //             // read_addr_out = 
    //         end else begin

    //         end
    //     end
    // end

    always_ff @(posedge clock) begin
        if (reset) begin
            pingpong         <= 1'b1;
            merge_width      <= (start_width >> 1);
            merge_width_done <= 1'b1;
        end else if (en_in) begin
            if (merge_width_done) begin
                entry_valid      <= '0; 
                pingpong         <= ~pingpong;
                
                // ptr_head[0]      <= '0;
                // ptr_head[1]      <= (merge_width << 1);

                // merge_width      <= (merge_width << 1);
                merge_width_done <= 1'b0;
            end else begin

            end
        end
    end

endmodule