`timescale 1ns / 1ps
`default_nettype none

// Project F: Display Controller DVI Demo
// (C)2020 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io

module display_demo_dvi(
    input  wire clk_100mhz_p,
    output wire [3:0] dio_p
    );

    localparam SYSTEM_CLK_MHZ = 100;
    localparam DDR_HDMI_TRANSFER = 0;
    localparam PIXEL_F = 25_000_000;

    wire clk_locked;
    wire [3:0] clocks;

    ecp5pll
        #(
            .in_hz(SYSTEM_CLK_MHZ*1e6),
            .out0_hz(PIXEL_F * (DDR_HDMI_TRANSFER ? 5 : 10)),
            .out1_hz(PIXEL_F)
        )
        ecp5pll_inst
        (
            .clk_i(clk_100mhz_p),
            .clk_o(clocks),
            .locked(clk_locked)
        );

    wire tmds_clk = clocks[0];
    wire pclk = clocks[1];

    // Display Timings
    wire signed [15:0] sx;          // horizontal screen position (signed)
    wire signed [15:0] sy;          // vertical screen position (signed)
    wire h_sync;                    // horizontal sync
    wire v_sync;                    // vertical sync
    wire de;                        // display enable
    wire frame;                     // frame start

    display_timings #(              // 640x480  800x600 1280x720 1920x1080
        .H_RES(640),               //     640      800     1280      1920
        .V_RES(480),                //     480      600      720      1080
        .H_FP(16),                 //      16       40      110        88
        .H_SYNC(96),                //      96      128       40        44
        .H_BP(48),                 //      48       88      220       148
        .V_FP(10),                   //      10        1        5         4
        .V_SYNC(2),                 //       2        4        5         5
        .V_BP(33),                  //      33       23       20        36
        .H_POL(0),                  //       0        1        1         1
        .V_POL(0)                   //       0        1        1         1
    )
    display_timings_inst (
        .i_pix_clk(pclk),
        .i_rst(!clk_locked),
        .o_hs(h_sync),
        .o_vs(v_sync),
        .o_de(de),
        .o_frame(frame),
        .o_sx(sx),
        .o_sy(sy)
    );

    // test card colour output
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    // Test Card: Simple - ENABLE ONE TEST CARD INSTANCE ONLY
    test_card_simple #(
        .H_RES(640)    // horizontal resolution
    ) test_card_inst (
        .i_x(sx),
        .o_red(red),
        .o_green(green),
        .o_blue(blue)
    );

    // // Test Card: Squares - ENABLE ONE TEST CARD INSTANCE ONLY
    // test_card_squares #(
    //     .H_RES(1280),   // horizontal resolution
    //     .V_RES(720)     // vertical resolution
    // )
    // test_card_inst (
    //     .i_x(sx),
    //     .i_y(sy),
    //     .o_red(red),
    //     .o_green(green),
    //     .o_blue(blue)
    // );

    // // Test Card: Gradient - ENABLE ONE TEST CARD INSTANCE ONLY
    // localparam GRAD_STEP = 2;  // step right shift: 480=2, 720=2, 1080=3
    // test_card_gradient test_card_inst (
    //     .i_y(sy[GRAD_STEP+7:GRAD_STEP]),
    //     .i_x(sx[5:0]),
    //     .o_red(red),
    //     .o_green(green),
    //     .o_blue(blue)
    // );

    localparam OUT_TMDS_MSB = DDR_HDMI_TRANSFER ? 1 : 0;
    wire [OUT_TMDS_MSB:0] out_tmds_red;
    wire [OUT_TMDS_MSB:0] out_tmds_green;
    wire [OUT_TMDS_MSB:0] out_tmds_blue;
    wire [OUT_TMDS_MSB:0] out_tmds_clk;

    hdmi_device #(.DDR_ENABLED(DDR_HDMI_TRANSFER)) hdmi_device_i(
                    pclk,
                    tmds_clk,

                    red,
                    green,
                    blue,

                    ~de,
                    v_sync,
                    h_sync,

                    out_tmds_red,
                    out_tmds_green,
                    out_tmds_blue,
                    out_tmds_clk
                );


    generate
        if (DDR_HDMI_TRANSFER) begin
            ODDRX1F ddr0_clock (.D0(out_tmds_clk   [0] ), .D1(out_tmds_clk   [1] ), .Q(dio_p[3]), .SCLK(tmds_clk), .RST(0));
            ODDRX1F ddr0_red   (.D0(out_tmds_red   [0] ), .D1(out_tmds_red   [1] ), .Q(dio_p[2]), .SCLK(tmds_clk), .RST(0));
            ODDRX1F ddr0_green (.D0(out_tmds_green [0] ), .D1(out_tmds_green [1] ), .Q(dio_p[1]), .SCLK(tmds_clk), .RST(0));
            ODDRX1F ddr0_blue  (.D0(out_tmds_blue  [0] ), .D1(out_tmds_blue  [1] ), .Q(dio_p[0]), .SCLK(tmds_clk), .RST(0));
        end else begin
            assign dio_p[3] = out_tmds_clk;
            assign dio_p[2] = out_tmds_red;
            assign dio_p[1] = out_tmds_green;
            assign dio_p[0] = out_tmds_blue;
        end
    endgenerate

endmodule