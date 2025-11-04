// SPI slave: loads parallel tx_data when selected (CS goes low)
// shifts tx_data out MSB-first on MISO, captured on negedge sclk
// simultaneously captures incoming MOSI into rx_data (on posedge sclk).
module spi_slave (
    input wire rst,
    input  wire sclk,          // SPI clock from master
    input  wire cs,            // Active-low chip select
    input  wire mosi,          // Data from master
    input  wire [7:0] tx_data, // Parallel data to send to master when selected
    input wire sending,
    output reg  miso,          // Data to master (serial)
    output reg  [7:0] rx_data  // Parallel data received from master
);

    reg [7:0] tx_shift;        // shift register for transmit (MISO)
    reg [2:0] bit_cnt;
    reg done;
 
   
    always @(cs or rst) begin
        if (rst) begin
            // Deselected: clear counters and samples
            tx_shift <= 8'b0;
            bit_cnt <= 3'd0;
            miso <= 1'b0;
            rx_data<=0;
        end else begin
        if(!cs && sending) begin
            // Selected: load tx_shift with provided parallel data
            tx_shift <= tx_data;
            bit_cnt <= 3'd0;
            miso <= tx_data[7]; // output MSB immediately (will be stable before first rising edge)
        end
        end
    end

    // Capture MOSI into rx_shift on rising edge of SCLK (sampling)
    always @(posedge sclk) begin
        if (!cs && sending) begin
            rx_data <= {rx_data[6:0], mosi}; // shift in MOSI bit
        end
    end

    // Shift out next MISO bit on falling edge of SCLK (drive output for next sample)
    always @(negedge sclk) begin
        if (!cs && sending) begin
            // after presenting current MSB, rotate left so next MSB appears
            tx_shift <= {tx_shift[6:0], 1'b0};
            miso <= tx_shift[6]; // next bit to output (was bit6)
            // Note: miso is set here so it's stable before next rising edge
        end
    end

endmodule

