`timescale 1ns/1ps
module tb_spi;
    reg clk, rst, start;
    reg [1:0] slave_sel;
    reg [7:0] mosi_data;
    wire sclk, mosi;
    wire cs0, cs1, cs2;
    wire miso;
    wire done;
    wire [7:0] miso_data;

    // individual slave MISO outputs and rx_data for verification
    wire miso0, miso1, miso2;
    wire [7:0] rx0, rx1, rx2;
    wire sending; 
    
    // tx_data for each slave (parallel inputs)
    reg [7:0] tx0, tx1, tx2;

    // Instantiate master
    spi_master master_inst (
        .clk(clk), .rst(rst), .start(start),
        .slave_sel(slave_sel), .mosi_data(mosi_data),
        .miso(miso), .sclk(sclk), .mosi(mosi),
        .cs0(cs0), .cs1(cs1), .cs2(cs2),
        .done(done), .miso_data(miso_data), .sending(sending)
    );

    // Instantiate slaves with tx_data inputs
    spi_slave slave0 (.rst(rst), .sclk(sclk), .cs(cs0), .mosi(mosi), .tx_data(tx0), .sending(sending), .miso(miso0), .rx_data(rx0));
    spi_slave slave1 (.rst(rst), .sclk(sclk), .cs(cs1), .mosi(mosi), .tx_data(tx1), .sending(sending), .miso(miso1), .rx_data(rx1));
    spi_slave slave2 (.rst(rst), .sclk(sclk), .cs(cs2), .mosi(mosi), .tx_data(tx2), .sending(sending), .miso(miso2), .rx_data(rx2));

    // MISO bus multiplexer (tri-state like)
    assign miso = (!cs0) ? miso0 :
                  (!cs1) ? miso1 :
                  (!cs2) ? miso2 : 1'bz;

    // Clock generation (system clock)
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz system clock (sclk toggles from master)

    // Test sequence
    initial begin
        $display("=== SPI TEST: slaves send provided tx_data on MISO ===");
        // initialize
        rst = 1; start = 0; slave_sel = 2'd0; mosi_data = 8'h00;
        tx0 = 8'hA5; tx1 = 8'h3C; tx2 = 8'hF0; // parallel tx data for slaves
        #20 rst = 0;

        // Test slave0
        $display("\n-> Test Slave 0: tx0 = 0x%0h", tx0);
        slave_sel = 2'd0; mosi_data = 8'h5A;
        $display("Master sending: 0x%0h", mosi_data);
        start = 1; #10 start = 0;
        wait(done);
        #10; // small gap
        $display("Master received (miso_data) = 0x%0h", miso_data);
        $display("Slave0 rx_data = 0x%0h", rx0);

        // Test slave1
        $display("\n-> Test Slave 1: tx1 = 0x%0h", tx1);
        slave_sel = 2'd1; mosi_data = 8'hC3;
        $display("Master sending: 0x%0h", mosi_data);
        start = 1; #10 start = 0;
        wait(done);
        #10;
        $display("Master received (miso_data) = 0x%0h", miso_data);
        $display("Slave1 rx_data = 0x%0h", rx1);

        // Test slave2
        $display("\n-> Test Slave 2: tx2 = 0x%0h", tx2);
        slave_sel = 2'd2; mosi_data = 8'h0F;
        $display("Master sending: 0x%0h", mosi_data);
        start = 1; #10 start = 0;
        wait(done);
        #10;
        $display("Master received (miso_data) = 0x%0h", miso_data);
        $display("Slave2 rx_data = 0x%0h", rx2);

        $display("\n=== TEST COMPLETE ===");
        #50 $finish;
    end
endmodule
