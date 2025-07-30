`timescale 1ns/1ps

module uart_top_tt (
    input        clk,
    input        rst_n,

    input  [7:0] io_in,
    output [7:0] io_out,
    input  [7:0] io_in_en,
    output [7:0] io_out_en
);

    parameter WIDTH = 8;

    // Input signals
    wire clk_sel           = io_in[0];
    wire mode_osl          = io_in[1];
    wire tr_data_load      = io_in[2];
    wire rx_data_read_en   = io_in[3];
    wire [3:0] tr_fifo_data_w = io_in[7:4];

    // Outputs from internal UART
    wire tx_data_out;
    wire transmit_busy;
    wire tx_o_interpt;
    wire rx_o_interpt;
    wire tx_i_interpt;
    wire rx_i_interpt;
    // Optional: using only two bits of RX data
    wire [1:0] rx_data_read_out_lt = rx_data_read_out[1:0];

    // Internal connections
    wire modified_clk;
    wire clk_out;
    wire tr_d_ready;
    wire rx_fifo_en;
    wire [WIDTH-1:0] tr_fifo_data_in;
    wire [WIDTH-1:0] rx_fifo_data_in;

    assign transmit_busy = tr_bz; // from internal module

    // Clock multiplexer
    mux_2_1 ck_mux (
        .in_0(clk),
        .in_1(clk_out),
        .sel(clk_sel),
        .out(modified_clk)
    );

    // Baud generator
    baud_gen clk_generator (
        .clk(clk),
        .rstn(rst_n),
        .dlh_dll({12'b0, tr_fifo_data_w, rx_data_read_en}), // packed example
        .mode_osl(mode_osl),
        .bclk(clk_out)
    );

    // Transmit FIFO
    tfifo #(.WIDTH(WIDTH)) tr_fifo (
        .clk_i(modified_clk),
        .rst_n_i(rst_n),
        .we_i(tx_data_w_en /* external or kept tied via io_en input */),
        .re_i(tr_data_load),
        .wdata_i({4'b0, tr_fifo_data_w}),
        .o_interpt(tx_o_interpt),
        .i_interpt(tx_i_interpt),
        .d_ready(tr_d_ready),
        .rdata_o(tr_fifo_data_in),
        .tr_bz(tr_bz)
    );

    // Transmitter
    transmitter #(.WIDTH(WIDTH)) tr_module (
        .en(tr_en /* external tie or io mapping */),
        .d_ready(tr_d_ready),
        .clk(modified_clk),
        .rstn(rst_n),
        .d_in(tr_fifo_data_in),
        .tx_data(tx_data_out),
        .tr_bz(tr_bz)
    );

    // Receive FIFO
    rfifo #(.WIDTH(WIDTH)) rr_fifo (
        .clk_i(modified_clk),
        .rst_n_i(rst_n),
        .we_i(rx_fifo_en),
        .re_i(rx_data_read_en),
        .wdata_i(rx_fifo_data_in),
        .o_interpt(rx_o_interpt),
        .i_interpt(rx_i_interpt),
        .rdata_o(rx_data_read_out)
    );

    // Receiver
    receiver #(.WIDTH(WIDTH)) rx_module (
        .clk(modified_clk),
        .rstn(rst_n),
        .rx_data(rx_data_in /* external pin or tie via io? */),
        .d_out(rx_fifo_data_in),
        .fifo_we_en(rx_fifo_en)
    );

    // Map outputs to io_out
    assign io_out[0] = tx_data_out;
    assign io_out[1] = transmit_busy;
    assign io_out[2] = tx_o_interpt;
    assign io_out[3] = rx_o_interpt;
    assign io_out[4] = tx_i_interpt;
    assign io_out[5] = rx_i_interpt;
    assign io_out[7:6] = rx_data_read_out_lt;

    // Enable output pins
    assign io_out_en = 8'b11111111;
endmodule
