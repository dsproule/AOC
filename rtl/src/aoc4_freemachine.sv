module freemachine #(
    parameter start_row = 0,
    parameter end_row   = `BANK_DEPTH
)(
    input logic clock, reset,
    input logic [`TX_DATA_WIDTH] partial_vec_in,
    input logic run, ack_in, sync_init_in,

    output int updates_out,
    output logic changed_out, done_out, write_en_out, read_en_out, 
    output logic sync_last_row_req_out, sync_ack_out,
    output logic [`BANK_ADDR_WIDTH-1:0] row_addr_out,
    output logic [`COL_ADDR_WIDTH-1:0]  col_addr_out,
    output logic [`TX_DATA_WIDTH]       partial_vec_out
);

    localparam log2_mod = $clog2(`TX_DATA_WIDTH);

    logic regs_valid, done_out_buf;
    // tail reg is the first value
    logic [`GRID_VEC_ALIGN_N-1:0] regs [3], tail_reg;
    logic [`BANK_ADDR_WIDTH-1:0] row_addr_out_buf;

    assign done_out = done_out_buf && !write_en_out;
    
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_0;
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_1;
    logic [`GRID_VEC_ALIGN_N-1:0] regs_dbg_2;
    assign regs_dbg_0 = regs[0];
    assign regs_dbg_1 = regs[1];
    assign regs_dbg_2 = regs[2];

    logic prune, next_last_row;
    logic [3:0] degree;
    logic [`GRID_VEC_ALIGN_N-1:0] next_regs_1, next_regs_2, next_regs_0;

    assign next_last_row = (row_addr_out_buf == end_row - start_row - 1);

    // accumulation 
    always_comb begin
        degree = regs[0][0] + regs[0][1] + regs[0][2]
                        + regs[1][0] +             regs[1][2]
                        + regs[2][0] + regs[2][1] + regs[2][2];
        
        prune = (regs[1][1] && degree < 4);

        next_regs_0 = {regs[0][0], regs[0][`GRID_VEC_ALIGN_N-1:1]};
        next_regs_1 = {regs[1][0], regs[1][`GRID_VEC_ALIGN_N-1:1]};
        next_regs_2 = {regs[2][0], regs[2][`GRID_VEC_ALIGN_N-1:1]};
        
        if (prune) next_regs_1[0] = 1'b0;

        if (col_i == `GRID_VEC_ALIGN_N - 1) begin
            next_regs_0 = next_regs_1;
            next_regs_1 = next_regs_2;
            next_regs_2 = '0;
        end
    end

    logic store_pending, read_en_buf;
    logic [1:0] insert_reg, store_parity;
    int col_i, row_i;

    assign read_en_out = (write_en_out || done_out) ? 1'b0 : read_en_buf;

    // reg loading handler. (timing of counters)
    logic sync_valid, prev_sync; 
    always_ff @(posedge clock) begin
        if (reset) prev_sync <= 1'b0;
        else       prev_sync <= sync_init_in;
    end

    assign sync_ack_out = sync_init_in && (insert_reg == 1);
    assign sync_valid   = sync_init_in && (prev_sync != sync_init_in);

    logic stall;
    assign stall = write_en_out || sync_ack_out;

    always_ff @(posedge clock) begin
        if (reset) begin
            {regs[0], regs[1], regs[2]} <= '0;
            regs_valid <= 1'b0;
            insert_reg <= '0;
        end else if (sync_valid) begin
            // this is sync top
            regs_valid <= 1'b0;

            insert_reg <= '0;
            if (start_row == 0) begin
                regs[0]      <= '0;
                insert_reg   <= 1;
            end
        end else if (stall) begin
        end else if (ack_in && !regs_valid) begin
            regs[insert_reg][`VEC_OFFSET(col_addr_out) +: `TX_DATA_WIDTH] <= partial_vec_in;

            if (col_addr_out + `TX_DATA_WIDTH >= `GRID_VEC_ALIGN_N) begin
                if (insert_reg != 2) begin
                    insert_reg   <= insert_reg + 1;
                end else begin
                    regs_valid  <= 1'b1;
                    if (row_addr_out == `MAX_ROWS) regs[2] <= '0;
                end
            end 
        end else if (regs_valid && !done_out_buf && !write_en_out) begin
            {regs[0], regs[1], regs[2]} <= {next_regs_0, next_regs_1, next_regs_2};
            if (col_i == `GRID_VEC_ALIGN_N - 1 && end_row + 1 != `MAX_ROWS) regs_valid <= 1'b0;
        end
    end

    // memory interactions machine
    always_ff @(posedge clock) begin
        if (reset) begin
            done_out_buf      <= 1'b0;
            updates_out       <= '0;
            store_parity      <= '0;
            changed_out       <= 1'b1;
            sync_last_row_req_out <= 1'b0;
            
            read_en_buf  <= 1'b0;
        end else if (sync_valid) begin
            // place initial values and set the machine to go. Initializer 
            // of machine in a block.
            col_addr_out <=  '0;
            read_en_buf  <= 1'b1;
            store_parity <=  '0;
            done_out_buf <=  '0;
            changed_out  <= 1'b0;

            row_addr_out_buf <= '0;
            row_i <= start_row;
        end else if (stall) begin
            if (write_en_out && ack_in) begin
                store_parity[1] <= ~store_parity[1];
                col_addr_out <= col_i;
            end
        end else if (ack_in && !regs_valid) begin
            // save chunks until end of line. latency-insensitive design,
            // helps contention of mem if each can be stalled
            if (col_addr_out + `TX_DATA_WIDTH < `GRID_VEC_ALIGN_N) begin
                col_addr_out <= col_addr_out + `TX_DATA_WIDTH;
            end else if (insert_reg != 2) begin
                if (!sync_init_in) row_addr_out_buf <= row_addr_out_buf + 1;
                col_addr_out <= '0;
            end else begin
                sync_last_row_req_out <= 1'b0;
                col_i       <= '0;
                read_en_buf <= 1'b0;
            end

        end else if (regs_valid && !done_out_buf && !write_en_out) begin
            // driver of the cycle
            // if (prune) begin
            //     updates_out <= updates_out + 1;
            //     changed_out <= 1'b1;
            // end
            
            if (col_i == `GRID_VEC_ALIGN_N - 1) begin
                col_addr_out <= '0;
                col_i <= '0;
                row_i <= row_i + 1;

                if (row_i == end_row) done_out_buf <= 1'b1;
                else if (row_i == end_row - 1) begin
                    sync_last_row_req_out <= (end_row + 1 != `MAX_ROWS);
                end else begin
                    read_en_buf <= 1'b1;
                    row_addr_out_buf <= row_addr_out_buf + 1;
                end

            end else col_i <= col_i + 1;
            
            if (col_i[log2_mod-1:0] == log2_mod'(-1)) begin
                store_parity[0] <= ~store_parity[0];
                // at this point it is still within the prev so aligns auto
                col_addr_out <= col_i;  
            end
        end
    end
    
    assign write_en_out = (store_parity[0] != store_parity[1]) && (start_row == 4);
    assign partial_vec_out = (col_i == '0) ? regs[0][`GRID_VEC_ALIGN_N - 1 -: `TX_DATA_WIDTH] : 
                                             regs[1][`GRID_VEC_ALIGN_N - 1 -: `TX_DATA_WIDTH] ;
    assign row_addr_out = (!write_en_out)  ? row_addr_out_buf     : 
                          (col_i == '0)    ? row_addr_out_buf - 2 : row_addr_out_buf - 1;
    // assign row_addr_out = row_addr_out_buf;
    
endmodule