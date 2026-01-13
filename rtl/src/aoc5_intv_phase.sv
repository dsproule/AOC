module intv_phase (
    input logic clock, reset, 
    input logic en_in, parity_clock_in,
    input int stream_len_in,

    // ping memory
    input  tuple_pair_t even_data_in, odd_data_in,
    output logic [`BANK_ADDR_WIDTH-1:0] read_addr_out,
    output logic read_en_out

);

    always_ff @(posedge clock) begin
        if (reset) begin

        end else begin

        end
    end 

endmodule