// ============================================================================
// Module:      mpu6050_top
// Description: Top-level module for MPU6050 IMU interface via I2C.
//              Performs initialization (wake-up), reads WHO_AM_I for
//              verification, then continuously reads accelerometer X-axis
//              data and displays the MSB on LEDs.
//
// Target:      Vivado / Verilog-2001
// Clock:       24 MHz system clock
// Author:      FPGA Internship — Class Work
// ============================================================================

module mpu6050_top (
    input  wire        clk,       // 24 MHz system clock
    input  wire        rst,       // Active-high synchronous reset
    output reg  [3:0]  led,       // 4 LEDs for data display
    inout  wire        sda,       // I2C serial data
    output wire        scl        // I2C serial clock
);

    // ========================================================================
    // MPU6050 Constants
    // ========================================================================
    localparam [6:0] MPU_ADDR        = 7'h68;   // MPU6050 I2C address (AD0=GND)

    // Register addresses
    localparam [7:0] REG_PWR_MGMT_1  = 8'h6B;   // Power management 1
    localparam [7:0] REG_WHO_AM_I    = 8'h75;   // WHO_AM_I (expect 0x68)
    localparam [7:0] REG_ACCEL_XH    = 8'h3B;   // Accelerometer X high byte
    localparam [7:0] REG_ACCEL_XL    = 8'h3C;   // Accelerometer X low byte

    // Expected values
    localparam [7:0] WHO_AM_I_VAL    = 8'h68;   // Expected WHO_AM_I response
    localparam [7:0] WAKEUP_VAL      = 8'h00;   // Write to PWR_MGMT_1 to wake

    // ========================================================================
    // I2C Master Interface Signals
    // ========================================================================
    reg  [6:0]  i2c_slave_addr;
    reg  [7:0]  i2c_reg_addr;
    reg  [7:0]  i2c_write_data;
    reg         i2c_rw;           // 0=write, 1=read
    reg         i2c_start;        // Pulse to trigger transaction
    wire [7:0]  i2c_read_data;
    wire        i2c_busy;
    wire        i2c_done;
    wire        i2c_ack_error;

    // ========================================================================
    // I2C Master Instantiation
    // ========================================================================
    i2c_master #(
        .CLK_FREQ    (24_000_000),
        .I2C_FREQ    (100_000)
    ) u_i2c (
        .clk         (clk),
        .rst         (rst),
        .slave_addr  (i2c_slave_addr),
        .reg_addr    (i2c_reg_addr),
        .write_data  (i2c_write_data),
        .rw          (i2c_rw),
        .start       (i2c_start),
        .read_data   (i2c_read_data),
        .busy        (i2c_busy),
        .done        (i2c_done),
        .ack_error   (i2c_ack_error),
        .sda         (sda),
        .scl         (scl)
    );

    // ========================================================================
    // Top-Level FSM
    // ========================================================================
    localparam [3:0]
        TOP_IDLE         = 4'd0,   // Power-on idle
        TOP_WAKEUP       = 4'd1,   // Write 0x00 to PWR_MGMT_1
        TOP_WAIT_WAKEUP  = 4'd2,   // Wait for wakeup write to complete
        TOP_READ_WHO     = 4'd3,   // Read WHO_AM_I register
        TOP_WAIT_WHO     = 4'd4,   // Wait for WHO_AM_I read to complete
        TOP_CHECK_WHO    = 4'd5,   // Verify WHO_AM_I value
        TOP_READ_XH      = 4'd6,   // Read ACCEL_XOUT_H
        TOP_WAIT_XH      = 4'd7,   // Wait for read to complete
        TOP_READ_XL      = 4'd8,   // Read ACCEL_XOUT_L
        TOP_WAIT_XL      = 4'd9,   // Wait for read to complete
        TOP_UPDATE_LEDS  = 4'd10,  // Update LED outputs
        TOP_DELAY        = 4'd11,  // Short delay before next read cycle
        TOP_ERROR        = 4'd12;  // Error state (WHO_AM_I mismatch or NACK)

    reg [3:0]  top_state;
    reg [7:0]  accel_xh;          // Accelerometer X high byte
    reg [7:0]  accel_xl;          // Accelerometer X low byte
    reg [23:0] delay_cnt;         // Delay counter between read cycles
    reg        who_am_i_ok;       // WHO_AM_I verification flag

    // Delay between read cycles: ~50ms at 24 MHz = 1,200,000 cycles
    localparam DELAY_CYCLES = 24'd1_200_000;

    // ========================================================================
    // Top-Level FSM — Sequential Logic
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            top_state     <= TOP_IDLE;
            i2c_slave_addr<= 7'd0;
            i2c_reg_addr  <= 8'd0;
            i2c_write_data<= 8'd0;
            i2c_rw        <= 1'b0;
            i2c_start     <= 1'b0;
            accel_xh      <= 8'd0;
            accel_xl      <= 8'd0;
            delay_cnt     <= 24'd0;
            who_am_i_ok   <= 1'b0;
            led           <= 4'b0000;
        end else begin
            // Default: deassert start pulse
            i2c_start <= 1'b0;

            case (top_state)
                // ============================================================
                // IDLE — Power-on, wait a bit then begin initialization
                // ============================================================
                TOP_IDLE: begin
                    delay_cnt <= delay_cnt + 1'b1;
                    // Wait ~50ms for MPU6050 power-up
                    if (delay_cnt >= DELAY_CYCLES) begin
                        delay_cnt <= 24'd0;
                        top_state <= TOP_WAKEUP;
                    end
                end

                // ============================================================
                // WAKEUP — Write 0x00 to PWR_MGMT_1 to exit sleep mode
                // ============================================================
                TOP_WAKEUP: begin
                    if (!i2c_busy) begin
                        i2c_slave_addr <= MPU_ADDR;
                        i2c_reg_addr   <= REG_PWR_MGMT_1;
                        i2c_write_data <= WAKEUP_VAL;
                        i2c_rw         <= 1'b0;   // Write
                        i2c_start      <= 1'b1;
                        top_state      <= TOP_WAIT_WAKEUP;
                    end
                end

                // ============================================================
                // WAIT_WAKEUP — Wait for wakeup write to complete
                // ============================================================
                TOP_WAIT_WAKEUP: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            top_state <= TOP_ERROR;
                        end else begin
                            top_state <= TOP_READ_WHO;
                        end
                    end
                end

                // ============================================================
                // READ_WHO — Read WHO_AM_I register (0x75)
                // ============================================================
                TOP_READ_WHO: begin
                    if (!i2c_busy) begin
                        i2c_slave_addr <= MPU_ADDR;
                        i2c_reg_addr   <= REG_WHO_AM_I;
                        i2c_rw         <= 1'b1;   // Read
                        i2c_start      <= 1'b1;
                        top_state      <= TOP_WAIT_WHO;
                    end
                end

                // ============================================================
                // WAIT_WHO — Wait for WHO_AM_I read to complete
                // ============================================================
                TOP_WAIT_WHO: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            top_state <= TOP_ERROR;
                        end else begin
                            top_state <= TOP_CHECK_WHO;
                        end
                    end
                end

                // ============================================================
                // CHECK_WHO — Verify WHO_AM_I value equals 0x68
                // ============================================================
                TOP_CHECK_WHO: begin
                    if (i2c_read_data == WHO_AM_I_VAL) begin
                        who_am_i_ok <= 1'b1;
                        top_state   <= TOP_READ_XH;
                    end else begin
                        // WHO_AM_I mismatch — communication error
                        who_am_i_ok <= 1'b0;
                        top_state   <= TOP_ERROR;
                    end
                end

                // ============================================================
                // READ_XH — Read ACCEL_XOUT_H (0x3B)
                // ============================================================
                TOP_READ_XH: begin
                    if (!i2c_busy) begin
                        i2c_slave_addr <= MPU_ADDR;
                        i2c_reg_addr   <= REG_ACCEL_XH;
                        i2c_rw         <= 1'b1;   // Read
                        i2c_start      <= 1'b1;
                        top_state      <= TOP_WAIT_XH;
                    end
                end

                // ============================================================
                // WAIT_XH — Wait for ACCEL_XOUT_H read
                // ============================================================
                TOP_WAIT_XH: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            top_state <= TOP_ERROR;
                        end else begin
                            accel_xh  <= i2c_read_data;
                            top_state <= TOP_READ_XL;
                        end
                    end
                end

                // ============================================================
                // READ_XL — Read ACCEL_XOUT_L (0x3C)
                // ============================================================
                TOP_READ_XL: begin
                    if (!i2c_busy) begin
                        i2c_slave_addr <= MPU_ADDR;
                        i2c_reg_addr   <= REG_ACCEL_XL;
                        i2c_rw         <= 1'b1;   // Read
                        i2c_start      <= 1'b1;
                        top_state      <= TOP_WAIT_XL;
                    end
                end

                // ============================================================
                // WAIT_XL — Wait for ACCEL_XOUT_L read
                // ============================================================
                TOP_WAIT_XL: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            top_state <= TOP_ERROR;
                        end else begin
                            accel_xl  <= i2c_read_data;
                            top_state <= TOP_UPDATE_LEDS;
                        end
                    end
                end

                // ============================================================
                // UPDATE_LEDS — Display upper 4 bits of ACCEL_XOUT_H on LEDs
                // ============================================================
                TOP_UPDATE_LEDS: begin
                    // Display MSB nibble of accelerometer X high byte
                    // LED[3:0] = accel_xh[7:4]
                    // When sensor is tilted, LEDs change pattern
                    led       <= accel_xh[7:4];
                    delay_cnt <= 24'd0;
                    top_state <= TOP_DELAY;
                end

                // ============================================================
                // DELAY — Wait ~50ms before next read cycle
                // ============================================================
                TOP_DELAY: begin
                    delay_cnt <= delay_cnt + 1'b1;
                    if (delay_cnt >= DELAY_CYCLES) begin
                        delay_cnt <= 24'd0;
                        top_state <= TOP_READ_XH;
                    end
                end

                // ============================================================
                // ERROR — Communication error, blink all LEDs
                // ============================================================
                TOP_ERROR: begin
                    // Blink all LEDs to indicate error
                    delay_cnt <= delay_cnt + 1'b1;
                    if (delay_cnt >= DELAY_CYCLES) begin
                        delay_cnt <= 24'd0;
                        led       <= ~led;   // Toggle LEDs
                    end
                end

                default: begin
                    top_state <= TOP_IDLE;
                end
            endcase
        end
    end

endmodule
