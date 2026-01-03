module freemachine #(
    parameter start_row = 0,
    parameter end_row   = `BANK_DEPTH
)(
    input logic clock, reset,
    input logic [`TX_DATA_WIDTH] partial_vec_in,
    input logic sweep_start, ack_in,

    output logic changed_out, done_out, write_en_out, read_en_out,
    output logic [`BANK_ADDR_WIDTH-1:0] row_addr_out,
    output logic [`COL_ADDR_WIDTH-1:0]  col_addr_out,
    output logic [`TX_DATA_WIDTH]       partial_vec_out
);

    logic regs_valid;
    logic [`GRID_VEC_ALIGN_N-1:0] regs [3];
    logic [1:0] insert_reg;

    // reg loading handler. (timing of counters)
    always_ff @(posedge clock) begin
        if (reset) begin
            regs[0] <= '0;
            regs[1] <= '0;
            regs[2] <= '0;
            read_en_out  <= 1'b0;
            write_en_out <= 1'b0;
            regs_valid <= 1'b0;
        end else if (sweep_start) begin
            // place initial values and set the machine to go
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
            // cycle until end
            if (col_addr_out + `TX_DATA_WIDTH < `GRID_VEC_ALIGN_N) 
                col_addr_out <= col_addr_out + `TX_DATA_WIDTH;
            else if (insert_reg != 2) begin
                row_addr_out <= row_addr_out + 1;
                insert_reg   <= insert_reg + 1;
                col_addr_out <= '0;
            end else regs_valid <= 1'b1;

            regs[insert_reg][`VEC_OFFSET(col_addr_out) +: `TX_DATA_WIDTH] <= partial_vec_in;
        end
    end
    
endmodule