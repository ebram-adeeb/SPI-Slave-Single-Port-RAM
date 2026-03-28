// Wrapper for the SPI Slave wit Single Port RAM module
module SPI_slave_RAM(
    input    clk,   //posedge 
    input    rst,   //negedge  
    //Master Slave Interface
    input    SS_n,   //Slave Sel. ctrl signal (Active Low)
    input    MOSI,   //Master-out, Slave-in
    output   MISO   //Master-in, Slave-out
);
    wire [9:0] rx_data;
    wire       rx_valid;
    wire [7:0] tx_data;
    wire       tx_valid;
    SPI_slave slave (
        .clk(clk),
        .rst(rst),
        .SS_n(SS_n),
        .MOSI(MOSI),
        .MISO(MISO),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .tx_data(tx_data),
        .tx_valid(tx_valid)
    );
    SPI_RAM RAM (
        .clk(clk),
        .rst(rst),
        .din(rx_data),
        .rx_valid(rx_valid),
        .dout(tx_data),
        .tx_valid(tx_valid)
    );
endmodule