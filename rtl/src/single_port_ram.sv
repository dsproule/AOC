module single_port_sync_ram #(
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  logic clock,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic bank_en, write_en,

    output logic [DATA_WIDTH-1:0] read_data
);
    logic [DATA_WIDTH-1:0] mem [DEPTH];
    
    always_ff @(posedge clock) begin
        if (bank_en && write_en)
            mem[addr] <= write_data;
        
        if (bank_en && !write_en)
            read_data <= mem[addr];
    end

endmodule