module freemachine #(
    parameter start_row = 0,
    parameter end_row   = `BANK_DEPTH
)(
    input logic clock, reset,
    input logic [`TX_DATA_WIDTH] partial_vec_in,
    input logic run, ack_in,

    output logic changed_out, done_out, write_en_out, read_en_out,
    output logic [`BANK_ADDR_WIDTH-1:0] row_addr_out,
    output logic [`COL_ADDR_WIDTH-1:0]  col_addr_out,
    output logic [`TX_DATA_WIDTH]       partial_vec_out
);

    logic regs_valid;
    logic [`GRID_VEC_ALIGN_N-1:0] regs [3];
    
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_0;
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_1;
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_2;
    assign regs_dbg_0 = regs[0];
    assign regs_dbg_1 = regs[1];
    assign regs_dbg_2 = regs[2];

    logic prune;
    logic [3:0] degree;
    logic [`GRID_VEC_ALIGN_N-1:0] next_regs_1, next_regs_2, next_regs_0;

    always_comb begin
        degree = regs[0][0] + regs[0][1] + regs[0][2]
                        + regs[1][0] +             regs[1][2]
                        + regs[2][0] + regs[2][1] + regs[2][2];
        
        prune = (regs[1][1] && degree < 4);

        next_regs_0 = {regs_dbg_0[0], regs_dbg_0[`GRID_VEC_ALIGN_N-1:1]};
        next_regs_1 = {regs[1][0], regs[1][`GRID_VEC_ALIGN_N-1:1]};
        next_regs_2 = {regs[2][0], regs[2][`GRID_VEC_ALIGN_N-1:1]};
        
        if (prune) next_regs_1[0] = 1'b0;

        if (col_i == `GRID_VEC_ALIGN_N - 1) begin
            next_regs_0 = next_regs_1;
            next_regs_1 = next_regs_2;
            next_regs_2 = -1;
        end
    end

    logic [1:0] insert_reg;
    int col_i, row_i, updates;
    // reg loading handler. (timing of counters)
    always_ff @(posedge clock) begin
        if (reset) begin
            regs[0] <= '0;
            regs[1] <= '0;
            regs[2] <= '0;

            done_out   <= 1'b0;
            regs_valid <= 1'b0;
            updates    <= '0;
            
            read_en_out  <= 1'b0;
            write_en_out <= 1'b0;
        end else if (run) begin
            // place initial values and set the machine to go. Initializer 
            // of machine in a block.
            col_addr_out <= '0;
            read_en_out  <= 1'b1;
            write_en_out <= 1'b0;
            regs_valid   <= 1'b0;

            if (start_row == 0) begin
                regs[0]      <= '0;
                insert_reg   <= 1;
                row_addr_out <= start_row ;
            end else row_addr_out <= start_row - 1;

        end else if (ack_in && !regs_valid) begin
            // save chunks until end of line. latency-insensitive design,
            // helps contention of mem if each can be stalled
            
            regs[insert_reg][`VEC_OFFSET(col_addr_out) +: `TX_DATA_WIDTH] <= partial_vec_in;

            if (row_addr_out == `MAX_ROWS) begin
                regs[2] <= '0;
                regs_valid <= 1'b1;
                col_i      <= '0;
            end else 
            if (col_addr_out + `TX_DATA_WIDTH < `GRID_VEC_ALIGN_N) begin
                col_addr_out <= col_addr_out + `TX_DATA_WIDTH;
            end else if (insert_reg != 2) begin
                row_addr_out <= row_addr_out + 1;
                insert_reg   <= insert_reg + 1;
                col_addr_out <= '0;
            end else begin
                regs_valid <= 1'b1;
                col_i      <= '0;
                read_en_out <= 1'b0;
            end

        end else if (regs_valid && !done_out) begin
            // driver of the cycle
            regs[0] <= next_regs_0;
            regs[1] <= next_regs_1;
            regs[2] <= next_regs_2;
            if (prune) updates <= updates + 1;
            
            if (col_i == `GRID_VEC_ALIGN_N - 1) begin
                if (row_addr_out == `MAX_ROWS)
                    done_out <= 1'b1;
                read_en_out <= 1'b1;
                col_i <= '0;
                col_addr_out <= '0;

                row_addr_out <= row_addr_out + 1;

                // load in new line
                regs_valid <= 1'b0;
            end else col_i <= col_i + 1;
        end
    end
    
endmodule