///////////////////////////////////////////////////////////////////////////////
//   Single Port RAM module design for use in the SPI Slave Module project
//   RAM consists of:
//   - parameterized 256 line deep, 8-bit wide storage unit 
//   - Output Register + 2 address storage registers for the RD/WR operations
//   Two MSBs in din express control signals for RD/WR ADD/DATA 
///////////////////////////////////////////////////////////////////////////////
module SPI_RAM #(parameter MEM_DEPTH = 256, parameter ADDR_SIZE = 8)
(
    input      clk,      //posedge 
    input      rst,      //negedge

    input wire [9:0] din,      //Recieved from SPI Slave to RAM
    input wire       rx_valid, //RAM recieve data command
    output reg [7:0] dout,     //Sent from RAM to SPI Slave
    output reg       tx_valid  //SPI Register recieve data command
);
    localparam MEM_WIDTH  = 8;
    localparam RAM_WR_ADD  = 2'b00; 
    localparam RAM_WR_DATA = 2'b01; 
    localparam RAM_RD_ADD  = 2'b10; 
    localparam RAM_RD_DATA = 2'b11; 
    reg [MEM_WIDTH-1:0] mem [MEM_DEPTH-1:0];
    reg [MEM_WIDTH-1:0] wr_add;
    reg [MEM_WIDTH-1:0] rd_add;
    always @(posedge clk) begin
        if(~rst) begin
            dout     <= 8'b0;
            tx_valid <= 1'b0;
        end
        else begin
            tx_valid <= (din[9:8] == RAM_RD_DATA);
            if (rx_valid) begin
                case (din[9:8])
                    RAM_WR_ADD  : wr_add      <= din[7:0];
                    RAM_WR_DATA : mem[wr_add] <= din[7:0];
                    RAM_RD_ADD  : rd_add      <= din[7:0];
                    RAM_RD_DATA : dout        <= mem[rd_add];
                endcase
            end
        end
    end
endmodule