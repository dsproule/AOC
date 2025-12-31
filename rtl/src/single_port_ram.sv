module single_port_sync_ram #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input  logic clock,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] write_data,  // Write data
    input  logic bank_sel, write_en,

    output logic [DATA_WIDTH-1:0] read_data   // Read data
);

    logic [DATA_WIDTH-1:0] mem [DEPTH];
    
    always_ff @(posedge clock) begin
        if (bank_sel && write_en)
            mem[addr] <= write_data;
        
        if (bank_sel && !write_en)
            read_data <= mem[addr];
    end

endmodule