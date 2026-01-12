// arbitrates by using lock-semantics
module arb(
    input  logic clock, reset,
    input  logic ack_in,
    input  logic [`MACH_N-1:0] reqs_in,

    output logic [`MACH_N-1:0] gnt_out, 
    output int i_out
);

    always_ff @(posedge clock) begin
        if (reset) begin
            gnt_out <= 0;
        end else if (~|gnt_out && |reqs_in) begin
            // if gnt_out is un-reserved and a request is incoming
            for (int req_i = 0; req_i < `MACH_N; req_i++) begin
                if (reqs_in[req_i]) begin
                    gnt_out <= (1 << req_i);
                    i_out   <= req_i;
                end
            end
        // request line releases the request -> free it
        end else if (|gnt_out && !(reqs_in & gnt_out)) gnt_out <= '0;
    end

endmodule