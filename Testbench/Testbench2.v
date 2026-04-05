`timescale 1ns/1ps

module SPI_slave_tb();
    reg  clk, rst, SS_n, MOSI;
    wire MISO;
    reg [7:0] captured;
    reg [7:0] golden_mem  [0:255];
    reg [7:0] sb_addr     [0:255];
    reg [7:0] sb_data     [0:255];
    reg       addr_written[0:255];
    reg       addr_read   [0:255];
    integer   pass_count, fail_count, k;
    integer   sb_head, sb_tail;
    integer   covered_written, covered_read;

    parameter TIMEOUT = 300;

    SPI_slave_RAM uut (.clk(clk), .rst(rst), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO));

    initial clk = 0;
    always #5 clk = ~clk;

    task sb_push;
        input [7:0] addr, data;
        begin
            sb_addr[sb_tail] = addr;
            sb_data[sb_tail] = data;
            sb_tail = sb_tail + 1;
        end
    endtask

    task sb_check;
        input [7:0] dut_out;
        reg [7:0] exp_addr, exp_data;
        begin
            exp_addr = sb_addr[sb_head];
            exp_data = sb_data[sb_head];
            sb_head  = sb_head + 1;
            if (dut_out === exp_data) begin
                $display("Pass addr=0x%0h  expected=0x%0h  got=0x%0h", exp_addr, exp_data, dut_out);
                pass_count = pass_count + 1;
            end else begin
                $display("Fail addr=0x%0h  expected=0x%0h  got=0x%0h", exp_addr, exp_data, dut_out);
                fail_count = fail_count + 1;
                //$stop;
            end
        end
    endtask

    task wait_miso_valid;
        output timed_out;
        integer w;
        begin
            timed_out = 0; w = 0;
            while (MISO === 1'bx && w < TIMEOUT) begin
                @(negedge clk); w = w + 1;
            end
            if (w >= TIMEOUT) begin
                $display("Fail MISO timeout");
                fail_count = fail_count + 1;
                timed_out  = 1;
            end
        end
    endtask

    task write_operation;
        input [9:0] write_add, write_data;
        integer i;
        begin
            SS_n = 1'b0; MOSI = 1'b0;
            @(negedge clk); @(negedge clk);
            for (i = 0; i < 10; i = i + 1) begin
                MOSI = write_add[9-i]; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk);
            SS_n = 1'b0; MOSI = 1'b0;
            @(negedge clk); @(negedge clk);
            for (i = 0; i < 10; i = i + 1) begin
                MOSI = write_data[9-i]; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk);
            golden_mem[write_add[7:0]]    = write_data[7:0];
            addr_written[write_add[7:0]]  = 1;
            sb_push(write_add[7:0], write_data[7:0]);
        end
    endtask

    task read_operation;
        input  [9:0] read_add;
        output [7:0] captured;
        reg [9:0] read_cmd;
        integer i;
        begin
            SS_n = 1'b0; MOSI = 1'b1;
            @(negedge clk); @(negedge clk);
            for (i = 0; i < 10; i = i + 1) begin
                MOSI = read_add[9-i]; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk);
            SS_n = 1'b0; MOSI = 1'b1;
            @(negedge clk); @(negedge clk);
            read_cmd = 10'b11_xxxx_xxxx;
            for (i = 0; i < 10; i = i + 1) begin
                MOSI = read_cmd[9-i]; @(negedge clk);
            end
            @(negedge clk); @(negedge clk); @(negedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                captured[7-i] = MISO; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk);
            addr_read[read_add[7:0]] = 1;
        end
    endtask

    task aborted_write;
        input [9:0] write_add;
        input integer abort_after;
        integer i;
        begin
            SS_n = 1'b0; MOSI = 1'b0;
            @(negedge clk); @(negedge clk);
            for (i = 0; i < abort_after; i = i + 1) begin
                MOSI = write_add[9-i]; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk); @(negedge clk);
        end
    endtask

    task aborted_read;
        input [9:0] read_add;
        input integer abort_after;
        integer i;
        begin
            SS_n = 1'b0; MOSI = 1'b1;
            @(negedge clk); @(negedge clk);
            for (i = 0; i < abort_after; i = i + 1) begin
                MOSI = read_add[9-i]; @(negedge clk);
            end
            SS_n = 1'b1; @(negedge clk); @(negedge clk);
        end
    endtask

    task do_reset;
        integer j;
        begin
            rst = 0; SS_n = 1; MOSI = 0;
            @(negedge clk); rst = 1; @(negedge clk);
            for (j = 0; j < 256; j = j + 1) begin
                golden_mem[j]    = 8'h00;
                addr_written[j]  = 0;
                addr_read[j]     = 0;
            end
            sb_head = 0; sb_tail = 0;
        end
    endtask

    task rand_addr_pick;
        output [7:0] addr;
        reg [7:0] boundaries [0:3];
        begin
            boundaries[0] = 8'h00; boundaries[1] = 8'h7F;
            boundaries[2] = 8'h80; boundaries[3] = 8'hFF;
            if ($random % 2 == 0)
                addr = boundaries[$random % 4];
            else
                addr = $random % 256;
        end
    endtask

    task constrained_random_write_read;
        reg [7:0] r_addr, r_data;
        begin
            rand_addr_pick(r_addr);
            r_data = $random % 256;
            write_operation({2'b00, r_addr}, {2'b01, r_data});
            read_operation ({2'b10, r_addr}, captured);
            sb_check(captured);
        end
    endtask

    task print_coverage;
        integer j;
        begin
            covered_written = 0; covered_read = 0;
            for (j = 0; j < 256; j = j + 1) begin
                if (addr_written[j]) covered_written = covered_written + 1;
                if (addr_read[j])    covered_read    = covered_read    + 1;
            end
            $display("Coverage – written: %0d/256 (%0d%%)  read: %0d/256 (%0d%%)",
                covered_written, (covered_written*100)/256,
                covered_read,    (covered_read*100)/256);
        end
    endtask

    initial begin
        pass_count = 0; fail_count = 0;
        do_reset;

        if (MISO !== 1'b0) begin
            $display("Fail MISO not 0 during reset"); fail_count = fail_count + 1;
        end

        $display("Directed boundaries tests");
        write_operation(10'b00_0000_0000, 10'b01_1010_1010);
        read_operation (10'b10_0000_0000, captured); sb_check(captured);
        write_operation(10'b00_1111_1111, 10'b01_1111_1111);
        read_operation (10'b10_1111_1111, captured); sb_check(captured);
        write_operation(10'b00_1000_0000, 10'b01_0000_0001);
        read_operation (10'b10_1000_0000, captured); sb_check(captured);
        write_operation(10'b00_0111_1111, 10'b01_1111_1110);
        read_operation (10'b10_0111_1111, captured); sb_check(captured);

        $display("Data edge cases" );
        write_operation(10'b00_0010_0000, 10'b01_0000_0000);
        read_operation (10'b10_0010_0000, captured); sb_check(captured);
        write_operation(10'b00_0011_0000, 10'b01_1111_1111);
        read_operation (10'b10_0011_0000, captured); sb_check(captured);
        write_operation(10'b00_0100_0000, 10'b01_0101_0101);
        read_operation (10'b10_0100_0000, captured); sb_check(captured);
        write_operation(10'b00_0101_0000, 10'b01_1010_1010);
        read_operation (10'b10_0101_0000, captured); sb_check(captured);

        $display("Consecutive overwrites");
        write_operation(10'b00_0001_0000, 10'b01_1111_0000); 
        write_operation(10'b00_0001_0000, 10'b01_0000_1111); sb_head = sb_head + 1;
        write_operation(10'b00_0001_0000, 10'b01_1010_1010); sb_head = sb_head + 1;
        read_operation (10'b10_0001_0000, captured); sb_check(captured);

        $display("Uninitialised read");
        read_operation(10'b10_0101_0101, captured);
        if (captured === 8'h00) begin
            $display("Pass uninit addr=0x55 got=0x00"); pass_count = pass_count + 1;
        end else begin
            $display("Fail uninit addr=0x55 expected=0x00 got=0x%0h", captured); fail_count = fail_count + 1;
        end

        $display("Aborted");
        aborted_write(10'b00_1010_1010, 4);
        aborted_read (10'b10_0000_0001, 6);
        write_operation(10'b00_0110_0000, 10'b01_1100_0011);
        read_operation (10'b10_0110_0000, captured); sb_check(captured);

        $display("Rapid SS_n Toggling");
        repeat(5) begin SS_n = 1'b0; @(negedge clk); SS_n = 1'b1; @(negedge clk); end
        write_operation(10'b00_0111_0000, 10'b01_1011_1101);
        read_operation (10'b10_0111_0000, captured); sb_check(captured);

        $display("MOSI stuck high");
        SS_n = 1'b0; MOSI = 1'b1;
        repeat(12) @(negedge clk);
        SS_n = 1'b1; @(negedge clk);
        write_operation(10'b00_1000_0001, 10'b01_0101_0101);
        read_operation (10'b10_1000_0001, captured); sb_check(captured);

        $display("MOSI stuck low");
        SS_n = 1'b0; MOSI = 1'b0;
        repeat(12) @(negedge clk);
        SS_n = 1'b1; @(negedge clk);
        write_operation(10'b00_1001_0000, 10'b01_1010_0101);
        read_operation (10'b10_1001_0000, captured); sb_check(captured);

        $display("reset");
        aborted_write(10'b00_1010_0000, 5); do_reset;
        read_operation(10'b10_1010_0000, captured);
        if (captured === 8'h00) begin
            $display("Pass post reset mid write addr"); pass_count = pass_count + 1;
        end else begin
            $display("Fail post reset mid write addr got=0x%0h", captured); fail_count = fail_count + 1;
        end

        write_operation(10'b00_1011_0000, 10'b01_1111_1111);
        aborted_write(10'b00_1011_0000, 5); do_reset;
        read_operation(10'b10_1011_0000, captured);
        if (captured === 8'h00) begin
            $display("Pass post reset mid write data"); pass_count = pass_count + 1;
        end else begin
            $display("Fail post reset mid write data got=0x%0h", captured); fail_count = fail_count + 1;
        end

        aborted_read(10'b10_1100_0000, 5); do_reset;
        read_operation(10'b10_1100_0000, captured);
        if (captured === 8'h00) begin
            $display("Pass post reset mid read addr"); pass_count = pass_count + 1;
        end else begin
            $display("Fail post reset mid read addr got=0x%0h", captured); fail_count = fail_count + 1;
        end

        write_operation(10'b00_1101_0000, 10'b01_1010_1010);
        aborted_read(10'b10_1101_0000, 5); do_reset;
        read_operation(10'b10_1101_0000, captured);
        if (captured === 8'h00) begin
            $display("Pass post reset mid read data"); pass_count = pass_count + 1;
        end else begin
            $display("Fail post reset mid read data got=0x%0h", captured); fail_count = fail_count + 1;
        end

        write_operation(10'b00_0000_0001, 10'b01_0001_0010);
        write_operation(10'b00_0000_0010, 10'b01_0010_0100);
        read_operation (10'b10_0000_0001, captured); sb_check(captured);
        write_operation(10'b00_0000_0011, 10'b01_0011_0110);
        read_operation (10'b10_0000_0010, captured); sb_check(captured);
        read_operation (10'b10_0000_0011, captured); sb_check(captured);

        $display("Full sweep");
        for (k = 0; k < 256; k = k + 1)
            write_operation({2'b00, k[7:0]}, {2'b01, k[7:0]});
        for (k = 0; k < 256; k = k + 1) begin
            read_operation({2'b10, k[7:0]}, captured); sb_check(captured);
        end

        $display("Random tests");
        for (k = 0; k < 100; k = k + 1)
            constrained_random_write_read;

        $display("Coverage report");
        print_coverage;

        $display("Results: %0d passed, %0d failed", pass_count, fail_count);
        $stop;
    end

    initial begin
        $monitor("t=%0t SS_n=%b MOSI=%b MISO=%b captured=%b",
                  $time, SS_n, MOSI, MISO, captured);
    end

endmodule
