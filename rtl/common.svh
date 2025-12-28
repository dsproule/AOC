`ifndef COMMON_SVH__
`define COMMON_SVH__

`define DATA_WIDTH 64
`define LONG_DATA_WIDTH 64

function automatic logic [`DATA_WIDTH-1:0] pow10(input logic [3:0] n);
    case (n)
        0: pow10 = 64'd1;
        1: pow10 = 64'd10;
        2: pow10 = 64'd100;
        3: pow10 = 64'd1_000;
        4: pow10 = 64'd10_000;
        5: pow10 = 64'd100_000;
        6: pow10 = 64'd1_000_000;
        7: pow10 = 64'd10_000_000;
        8: pow10 = 64'd100_000_000;
        9: pow10 = 64'd1_000_000_000;
        10: pow10 = 64'd10_000_000_000;
        default: pow10 = 64'hDEADBEEF;
    endcase
endfunction

`endif