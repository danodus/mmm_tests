module top(
    input  wire logic clk_100mhz_p,
    output      logic led1,
    output      logic led2
);

    logic [26:0] counter = 0;

    always_ff @(posedge clk_100mhz_p) begin
        counter <= counter + 1;
        led1    <= counter[26];
        led2    <= ~counter[26];
    end

endmodule