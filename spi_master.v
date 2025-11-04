module spi_master (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [1:0] slave_sel,
    input  wire [7:0] mosi_data,
    input  wire miso,
    output reg  sclk,
    output reg  mosi,
    output reg  cs0, cs1, cs2,
    output reg  done,
    output reg  [7:0] miso_data,
    output reg sending
);

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk <= 0; done <= 0; mosi <= 0;
            cs0 <= 1; cs1 <= 1; cs2 <= 1;
            bit_cnt <= 0; sending <= 0;
            miso_data <= 0;
            shift_reg <= 0;
        end else begin
            if (start && !sending) begin
                // start transfer
                sending <= 1;
                done <= 0;
                bit_cnt <= 0;
                shift_reg <= mosi_data;
                case (slave_sel)
                    2'b00: begin cs0 <= 0; cs1 <= 1; cs2 <= 1; end
                    2'b01: begin cs0 <= 1; cs1 <= 0; cs2 <= 1; end
                    2'b10: begin cs0 <= 1; cs1 <= 1; cs2 <= 0; end
                    default: begin cs0 <= 1; cs1 <= 1; cs2 <= 1; end
                endcase
            end else if (sending) begin
                sclk <= ~sclk; // toggle clock

                if (sclk == 0) begin
                    // SCLK low phase: drive MOSI (setup)
                    mosi <= shift_reg[7];
                end else begin
                    // SCLK high phase: sample MISO
                    miso_data <= {miso_data[6:0], miso};
                    // shift tx (we already shifted out msb, now shift left)
                    shift_reg <= {shift_reg[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 3'd7) begin
                        sending <= 0;
                        done <= 1;
                        sclk <= 0;
                        cs0 <= 1; cs1 <= 1; cs2 <= 1;
                    end
                end
            end else begin
                sclk <= 0;
                done <= 0;
            end
        end
    end
endmodule
