// SPI slave: loads parallel tx_data when selected (CS goes low)
// shifts tx_data out MSB-first on MISO, captured on negedge sclk
// simultaneously captures incoming MOSI into rx_data (on posedge sclk).
module spi_slave (
    input  wire sclk,          // SPI clock from master
    input  wire cs,            // Active-low chip select
    input  wire mosi,          // Data from master
    input  wire [7:0] tx_data, // Parallel data to send to master when selected
    output reg  miso,          // Data to master (serial)
    output reg  [7:0] rx_data  // Parallel data received from master
);

    reg [7:0] tx_shift;        // shift register for transmit (MISO)
    reg [7:0] rx_shift;        // shift register for receive (MOSI)
    reg [2:0] bit_cnt;

 
    always @(cs) begin
        if (cs) begin
            // Deselected: clear counters and samples
            tx_shift <= 8'b0;
            rx_shift <= 8'b0;
            bit_cnt <= 3'd0;
            miso <= 1'b0;
            rx_data <= 8'b0;
        end else begin
            // Selected: load tx_shift with provided parallel data
            tx_shift <= tx_data;
            rx_shift <= 8'b0;
            bit_cnt <= 3'd0;
            miso <= tx_data[7]; // output MSB immediately (will be stable before first rising edge)
        end
    end

    // Capture MOSI into rx_shift on rising edge of SCLK (sampling)
    always @(posedge sclk) begin
        if (!cs) begin
            rx_shift <= {rx_shift[6:0], mosi}; // shift in MOSI bit
            bit_cnt <= bit_cnt + 1;
            if (bit_cnt == 3'd7) begin
                rx_data <= {rx_shift[6:0], mosi}; // complete byte received
            end
        end
    end

    // Shift out next MISO bit on falling edge of SCLK (drive output for next sample)
    always @(negedge sclk) begin
        if (!cs) begin
            // after presenting current MSB, rotate left so next MSB appears
            tx_shift <= {tx_shift[6:0], 1'b0};
            miso <= tx_shift[6]; // next bit to output (was bit6)
            // Note: miso is set here so it's stable before next rising edge
        end
    end

endmodule
