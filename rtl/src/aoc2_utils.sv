`include "common.svh"

module get_digs(
    input logic [`DATA_WIDTH-1:0] n_in,

    output logic [3:0] digs_out
);
    // priority encoder 
    always_comb begin
        if      (n_in >= pow10(10)) digs_out = 11;
        else if (n_in >= pow10(9))  digs_out = 10;
        else if (n_in >= pow10(8))  digs_out = 9;
        else if (n_in >= pow10(7))  digs_out = 8;
        else if (n_in >= pow10(6))  digs_out = 7;
        else if (n_in >= pow10(5))  digs_out = 6;
        else if (n_in >= pow10(4))  digs_out = 5;
        else if (n_in >= pow10(3))  digs_out = 4;
        else if (n_in >= pow10(2))  digs_out = 3;
        else if (n_in >= pow10(1))  digs_out = 2;
        else                        digs_out = 1;
    end

endmodule

module pref_lookup(
    input logic [3:0] idx,

    output logic [`LONG_DATA_WIDTH-1:0] value
);
    // precomputed lookup table for 10 digits
    always_comb begin
        case (idx)
            4'd0:  value = 64'd0;
            4'd1:  value = 64'd0;
            4'd2:  value = 64'd495;
            4'd3:  value = 64'd5490;
            4'd4:  value = 64'd500895;
            4'd5:  value = 64'd1000890;
            4'd6:  value = 64'd540590850;
            4'd7:  value = 64'd590590845;
            4'd8:  value = 64'd495095086350;
            4'd9:  value = 64'd990140130900;
            4'd10: value = 64'd496436044631310;
            default: value = 64'd0;
        endcase
    end

endmodule