module SPI_slave_RAM_tb();
    reg clk; reg rst; reg SS_n; reg MOSI;
    wire MISO;
    reg [7:0] captured;
    reg [7:0] expected;

    SPI_slave_RAM uut (.clk(clk), .rst(rst), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO)); 

    task write_operation (input [9:0] write_add, input [9:0] write_data);
        SS_n = 1'b0;
        MOSI = 1'b0;
        @(negedge clk);
        @(negedge clk);
        for (int i=0;i<10;i++) begin
            MOSI = write_add[9-i];
            @(negedge clk);
        end
        SS_n = 1'b1;
        @(negedge clk);

        SS_n = 1'b0;
        MOSI = 1'b0;
        @(negedge clk);
        @(negedge clk);
        for (int i=0;i<10;i++) begin
            MOSI = write_data[9-i];
            @(negedge clk);
        end
        SS_n = 1'b1;
        @(negedge clk);
    endtask

    task read_operation (input [9:0] read_add, input [9:0] read_data, output [7:0] captured);
        SS_n = 1'b0;
        MOSI = 1'b1;
        @(negedge clk);
        @(negedge clk);
        for (int i=0;i<10;i++) begin
            MOSI = read_add[9-i];
            @(negedge clk);
        end
        SS_n = 1'b1;
        @(negedge clk);

        SS_n = 1'b0;
        MOSI = 1'b1;
        @(negedge clk);
        @(negedge clk);
        for (int i=0;i<10;i++) begin
            MOSI = read_data[9-i];
            @(negedge clk);
        end
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        for (int i=0;i<8;i++) begin
            captured[7-i] = MISO;
            @(negedge clk);
        end
        SS_n = 1'b1;
        @(negedge clk);
    endtask

    //clock generation
    initial begin
        clk = 0;
        forever
            #5 clk = ~clk;
    end
    
    initial begin
        SS_n = 1; rst = 0; MOSI = 1;
        @(negedge clk)
        if (MISO != 0) begin
            $display("Error!");
            $stop;
        end

        rst = 1;
        write_operation (10'b00_0010_0011, 10'b01_1110_1010);
        read_operation (10'b10_0010_0011, 10'b11_XXXX_XXXX, captured);
        expected = 8'b1110_1010;
        @(negedge clk);
        if ( captured !== expected) begin
            $display("Error!");
            $stop;
        end
        $stop;
    end

    initial begin
        $monitor("t=%t SS_n=%b MOSI=%b MISO=%b Captured=%b Expected=%b",
            $time, SS_n, MOSI, MISO, captured, expected);
    end
endmodule