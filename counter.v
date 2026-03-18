module counter(
    input            clk,    //posedge clk
    input            rst,    //negedge rst
    input            cnt_on, //turn on command
    output reg [3:0] cnt
);
    always @(posedge clk) begin
        if (~rst)
            cnt <= 'b0;
        else if (cnt_on) begin
            if (cnt == 9)
                cnt <= 'b0;
            else
                cnt <= cnt + 1;
        end
        else 
            cnt <= 'b0;
    end
endmodule