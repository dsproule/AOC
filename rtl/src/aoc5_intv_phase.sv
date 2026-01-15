module intv_phase (
    input logic clock, reset, 
    input logic en_in, parity_clock_in,
    input int stream_len_in,

    // ping memory
    input  tuple_pair_t even_data_in, odd_data_in,
    output logic [`BANK_ADDR_WIDTH-1:0] read_addr_out,
    output logic read_en_out,

    output logic phase_done_out,
    output longint final_sum_out
);
    tuple_pair_t prev_intv, cur_intv;
    logic intv_sweep_started;
    
    assign phase_done_out = (read_addr_out == stream_len_in);
    // mem is even aligned so every 2 addresses indexes same thing (just mux the output)
    assign cur_intv       = (read_addr_out & 1'b1) ? even_data_in : odd_data_in;
    assign final_sum_out  = final_sum + (prev_intv.second - prev_intv.first + 1);

    longint final_sum;
    // Grabs intvs
    always_ff @(posedge clock) begin
        intv_sweep_started <= read_en_out;
        
        if (reset) begin
            read_addr_out <=  '0;
            read_en_out   <= 1'b0;
            
            prev_intv.first  <=  1;
            prev_intv.second <= '0;
            
            intv_sweep_started <= 1'b0;
            final_sum          <= '0;
        end else if (en_in) begin
            read_en_out <= 1'b1;

            if (read_addr_out < stream_len_in && read_en_out) read_addr_out <= read_addr_out + 1;

            if (intv_sweep_started) begin
                // interval merge or accumulation
                if (cur_intv.first <= prev_intv.second)
                    prev_intv.second <= (cur_intv.second > prev_intv.second) ? cur_intv.second : prev_intv.second;
                else begin
                    final_sum <= final_sum + (prev_intv.second - prev_intv.first + 1);
                    prev_intv <= cur_intv;
                end
            end

        end else read_en_out <= 1'b0;
    end 

endmodule