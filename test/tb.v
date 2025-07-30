`timescale 1ns/1ps

module uart_top_tt_tb;

    reg clk;
    reg rst_n;

    reg  [7:0] io_in;
    wire [7:0] io_out;

    reg  [7:0] io_in_en;
    wire [7:0] io_out_en;

    // Instantiate the top module
    uart_top_tt dut (
        .clk(clk),
        .rst_n(rst_n),
        .io_in(io_in),
        .io_out(io_out),
        .io_in_en(io_in_en),
        .io_out_en(io_out_en)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz

    initial begin
        // Initialization
        rst_n = 0;
        io_in = 8'b00000000;
        io_in_en = 8'b11111111;

        #20;
        rst_n = 1;

        // ----------- Simulate TX Operation ----------------

        // Step 1: Set clk_sel = 0, mode_osl = 0 (default), write TX data 4'b1010
        io_in = 8'b10100000;  // io_in[7:4] = 4'b1010
        #10;

        // Step 2: Pulse tr_data_load = 1
        io_in[2] = 1;
        #10;
        io_in[2] = 0;
        #10;

        // ----------- Simulate RX Read (assume RX data present) -----------

        // Step 3: Pulse rx_data_read_en = 1 to read received data
        io_in[3] = 1;
        #10;
        io_in[3] = 0;
        #10;

        // Observe output flags (tx_data_out, tx_o_interpt, rx_o_interpt, etc.)
        $display("TX Output       : %b", io_out[0]);
        $display("TX Busy         : %b", io_out[1]);
        $display("TX Out Interrupt: %b", io_out[2]);
        $display("RX Out Interrupt: %b", io_out[3]);
        $display("RX Data Output  : %b", io_out[7:6]);

        #100;

        $finish;
    end

endmodule
