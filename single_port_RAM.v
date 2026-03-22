
module SPI_RAM #(parameter MEM_DEPTH = 256, parameter ADDR_SIZE = 8)
(
    input      clk,      
    input      rst,      
    input wire [9:0] din,     
    input wire       rx_valid, 
    output reg [7:0] dout,     
    output reg       tx_valid  
);

endmodule
