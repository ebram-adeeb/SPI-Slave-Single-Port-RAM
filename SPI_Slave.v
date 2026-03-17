module SPI_slave(

    input        clk,      //clk(posedge) 
    input        rst,      //rst(negedge) 

    //Master Slave Interface
    input        SS_n,     //Slave Sel.(negedge)
    input        MOSI,     //Master-out, Slave-in
    output       MISO,     //Master-in, Slave-out

    //Slave RAM Interface
    output [9:0] rx_data,  //Recieve Data
    output       rx_valid, //Recieve Validate

    input  [7:0] tx_data,  //Transmit Data
    input        tx_valid, //Transmit Validate
);  
    parameter IDLE      = 3'b000; //Standby
    parameter CHK_CMD   = 3'b001; //Check Command
    parameter WRITE     = 3'b010; 
    parameter READ_ADD  = 3'b011;
    parameter READ_DATA = 3'b100;

    (* fsm_encoding = "one_hot" *)
    reg [2:0] cs, ns; //Current State, Next State
    wire add_read;
    //Next State Logic 
    always @(*) begin
        case (cs)
            IDLE: begin
                if (~SS_n)
                    ns = CHK_CMD;
                else 
                    ns = IDLE;
            end 
            CHK_CMD: begin
                if (SS_n)
                    ns = IDLE;
                else begin
                    if (~MOSI)
                        ns = WRITE;
                    else begin
                        
                    end
                end
            end
        endcase
    end
    always @(posedge clk) begin
        if (~rst) begin
            
        end
    end
endmodule