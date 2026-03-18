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
    input        tx_valid  //Transmit Validate
);  
    parameter IDLE      = 3'b000; //Standby
    parameter CHK_CMD   = 3'b001; //Check Command
    parameter WRITE     = 3'b010; 
    parameter READ_ADD  = 3'b011;
    parameter READ_DATA = 3'b100;
    
    (* fsm_encoding = "gray" *)
    reg [2:0] cs, ns; //Current State, Next State
    reg [9:0] shift_reg;
    wire [3:0] bit_cnt;
    reg cnt_on;
    reg reg_full;
    reg add_read;
    counter cntr (.clk(clk), .rst(rst), .cnt_on(cnt_on), .cnt(bit_cnt));
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
                if (~SS_n & ~reg_full)
                    ns = WRITE;
                else
                    ns = IDLE;
            end
            READ_ADD: begin
                if (~SS_n & ~reg_full)
                    ns = READ_ADD;
                else
                    ns = IDLE;
            end
            READ_DATA: begin
                if (~SS_n & ~reg_full)
                    ns = READ_DATA;
                else
                    ns = IDLE;
            end
        endcase
    end
    always @(posedge clk) begin
        if (~rst) 
            cs <= IDLE;
        else 
            cs <= ns;
    end
    always @(posedge clk) begin
        if (~rst) begin
            cnt_on    <= 1'b0;
            reg_full  <= 1'b0;
            add_read  <= 1'b0;
            shift_reg <= 10'b0;
        end
        else begin
            case (cs)
                IDLE: begin
                    cnt_on    <= 1'b0;
                    reg_full  <= 1'b0;
                    add_read  <= 1'b0;
                    shift_reg <= 10'b0;
                end
                CHK_CMD: begin
                    cnt_on    <= 1'b0;
                    reg_full  <= 1'b0;
                    add_read  <= 1'b0;
                    shift_reg <= 10'b0;
                end
                WRITE: begin
                    
                end 
            endcase
        end
    end
endmodule
