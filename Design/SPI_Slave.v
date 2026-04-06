/////////////////////////////////////////////////////////////////////////////////
// - SPI Slave Submodule for control of single port RAM.
// - Consists of: 
//       - FSM with sequential output logic that checks then excutes three commands: 
//         Send SPI Write Address/Data to RAM, Send SPI Read Address to RAM,    
//         Recieve SPI Read Data from RAM. 
//       - An internal 10-bit Shift Register,two MSBs store mode select for RAM.
//         The rest stores Data/Addresses to be sent to the RAM module.                                 
//       - Counter Paired with the shift register, flags when register is filled.
/////////////////////////////////////////////////////////////////////////////////
module SPI_slave(
    input        clk,      //posedge
    input        rst,      //negedge 

    //Master Slave Interface
    input        SS_n,     //Slave Sel. ctrl signal (Active Low)
    input        MOSI,     //Master-out, Slave-in
    output reg   MISO,     //Master-in, Slave-out

    //Slave RAM Interface
    output [9:0]  rx_data,  //Sent from SPI Slave to RAM
    output  reg   rx_valid, //RAM recieve data command

    input  [7:0]  tx_data,  //Recieved from RAM to SPI Slave
    input         tx_valid  //SPI Register recieve data command
);  
    parameter IDLE      = 3'b000; //Standby
    parameter CHK_CMD   = 3'b001; //Check Command
    parameter WRITE     = 3'b010; //write address/data
    parameter READ_ADD  = 3'b011; //read address recieved from SPI Master
    parameter READ_DATA = 3'b100; //retrieve data from RAM
    
    (* fsm_encoding = "gray" *)
    reg [2:0] cs, ns; //Current State, Next State
    reg [9:0] shift_reg;
    wire [3:0] bit_cnt;
    reg cnt_on;
    reg add_read;
    reg data_read;
    //counter instantiation
    counter cntr (.clk(clk), .rst(rst), .cnt_on(cnt_on), .cnt(bit_cnt));
    //connect output data to internal shift register
    assign rx_data = (rx_valid)? shift_reg:10'b0;

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
                        if (~add_read)
                            ns = READ_ADD;
                        else   
                            ns = READ_DATA;
                    end
                end
            end
            WRITE: begin
                if (~SS_n)
                    ns = WRITE;
                else
                    ns = IDLE;
            end
            READ_ADD: begin
                if (~SS_n)
                    ns = READ_ADD;
                else
                    ns = IDLE;
            end
            READ_DATA: begin
                if (~SS_n)
                    ns = READ_DATA;
                else
                    ns = IDLE;
            end
            default: ns = IDLE;
        endcase
    end

    //Store State
    always @(posedge clk) begin
        if (~rst) 
            cs <= IDLE;
        else 
            cs <= ns;
    end

    //Output Logic
    always @(posedge clk) begin
        if (~rst) begin
            cnt_on    <= 1'b0;
            add_read  <= 1'b0;
            data_read <= 1'b0;
            shift_reg <= 10'b0;
            MISO      <= 1'b0;
            rx_valid  <= 1'b0;
        end
        else begin
            case (cs)
                IDLE: begin
                    data_read <= 1'b0;
                    cnt_on    <= 1'b0;
                    shift_reg <= 10'b0;
                    MISO      <= 1'b0;   
                    rx_valid  <= 1'b0;
                end
                CHK_CMD: begin
                    cnt_on    <= 1'b1;
                end
                WRITE: begin
                    if (cnt_on) begin
                        shift_reg <= (shift_reg << 1) | {9'b0, MOSI};
                    end 
                    if (bit_cnt == 4'd9) begin
                        cnt_on   <= 1'b0;
                        rx_valid <= 1'b1;
                    end 
                    else
                        rx_valid <= 1'b0;
                end 
                READ_ADD: begin
                    if (cnt_on) begin
                        shift_reg <= (shift_reg << 1) | {9'b0, MOSI};
                    end 
                    if (bit_cnt == 4'd9) begin
                        cnt_on   <= 1'b0;
                        rx_valid <= 1'b1;
                        add_read <= 1'b1;
                    end
                    else
                        rx_valid <= 1'b0;
                end 
                READ_DATA: begin
                    add_read <= 1'b0;
                    if (~tx_valid) begin
                        shift_reg <= (shift_reg << 1) | {9'b0, MOSI};
                    end  
                    else  begin
                        shift_reg [7:0] <= tx_data;
                        data_read <= 1'b1;
                    end
                    if (bit_cnt == 4'd9) begin
                        cnt_on   <= 1'b0;
                        rx_valid <= 1'b1;
                    end
                    else
                        rx_valid <= 1'b0;
                    if (data_read) begin
                        MISO <= shift_reg[7];
                    end  
                end
                default: begin
                    data_read <= 1'b0;
                    cnt_on    <= 1'b0;
                    shift_reg <= 10'b0;
                    MISO      <= 1'b0; 
                    rx_valid  <= 1'b0; 
                end          
            endcase
        end
    end
endmodule
