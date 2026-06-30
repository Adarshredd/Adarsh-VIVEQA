// ============================================================================
// Module:      i2c_master
// Description: I2C Master Controller — Standard Mode (100 kHz)
//              Supports single-byte register write and single-byte register read
//              with repeated START. Designed for 24 MHz system clock.
//
// Target:      Vivado / Verilog-2001
// Clock:       24 MHz system clock → 100 kHz SCL
// Author:      FPGA Internship — Class Work
// ============================================================================

module i2c_master #(
    parameter CLK_FREQ    = 24_000_000,  // System clock frequency (Hz)
    parameter I2C_FREQ    = 100_000,     // I2C SCL frequency (Hz)
    // Derived: full SCL period in clock cycles
    parameter CLK_DIV     = CLK_FREQ / I2C_FREQ,        // 240
    parameter HALF_PERIOD = CLK_DIV / 2,                 // 120
    parameter QUARTER     = CLK_DIV / 4                  // 60
)(
    input  wire        clk,          // 24 MHz system clock
    input  wire        rst,          // Active-high synchronous reset

    // Control interface
    input  wire [6:0]  slave_addr,   // 7-bit slave address
    input  wire [7:0]  reg_addr,     // Register address to read/write
    input  wire [7:0]  write_data,   // Data byte to write
    input  wire        rw,           // 0 = write, 1 = read
    input  wire        start,        // Pulse high to begin transaction

    // Status interface
    output reg  [7:0]  read_data,    // Data byte read from slave
    output reg         busy,         // 1 = transaction in progress
    output reg         done,         // Pulses high for 1 clock when complete
    output reg         ack_error,    // 1 = NACK received when ACK expected

    // I2C bus
    inout  wire        sda,          // Bidirectional serial data
    output wire        scl           // Serial clock output
);

    // ========================================================================
    // FSM State Encoding
    // ========================================================================
    localparam [4:0]
        S_IDLE       = 5'd0,   // Idle — waiting for start trigger
        S_START      = 5'd1,   // Generate START condition
        S_SEND_ADDR_W= 5'd2,   // Send slave address + Write bit
        S_WAIT_ACK1  = 5'd3,   // Wait for ACK after address (write phase)
        S_SEND_REG   = 5'd4,   // Send register address
        S_WAIT_ACK2  = 5'd5,   // Wait for ACK after register address
        S_SEND_DATA  = 5'd6,   // Send data byte (write mode)
        S_WAIT_ACK3  = 5'd7,   // Wait for ACK after data (write mode)
        S_RESTART    = 5'd8,   // Generate repeated START (read mode)
        S_SEND_ADDR_R= 5'd9,   // Send slave address + Read bit
        S_WAIT_ACK4  = 5'd10,  // Wait for ACK after address (read phase)
        S_RECV_DATA  = 5'd11,  // Receive data byte from slave
        S_SEND_NACK  = 5'd12,  // Send NACK to slave (last read byte)
        S_STOP       = 5'd13,  // Generate STOP condition
        S_DONE       = 5'd14;  // Transaction complete

    // ========================================================================
    // Internal Registers
    // ========================================================================
    reg [4:0]  state;
    reg [8:0]  clk_cnt;          // Clock divider counter (0 to CLK_DIV-1)
    reg [3:0]  bit_cnt;          // Bit counter (0 to 7)
    reg [7:0]  shift_reg;        // Shift register for TX/RX
    reg        sda_out;          // SDA output value (directly drives tristate)
    reg        sda_oe;           // SDA output enable (1 = drive, 0 = release)
    reg        scl_reg;          // SCL output register
    reg        clk_en;           // Clock phase enable
    reg        rw_latch;         // Latched R/W bit
    reg [6:0]  addr_latch;       // Latched slave address
    reg [7:0]  reg_latch;        // Latched register address
    reg [7:0]  data_latch;       // Latched write data
    reg [8:0]  phase_cnt;        // Phase counter within each state

    // ========================================================================
    // SDA Tristate Control
    // ========================================================================
    // Open-drain: drive LOW when sda_oe=1 and sda_out=0, else high-Z
    assign sda = (sda_oe) ? sda_out : 1'bz;

    // SCL output — open-drain style but for simplicity we drive both levels
    // In hardware, the pull-up handles the high level
    assign scl = scl_reg;

    // ========================================================================
    // Main FSM — Sequential Logic
    // ========================================================================
    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            clk_cnt    <= 9'd0;
            bit_cnt    <= 4'd0;
            shift_reg  <= 8'd0;
            sda_out    <= 1'b1;
            sda_oe     <= 1'b0;   // Release SDA (high-Z)
            scl_reg    <= 1'b1;   // SCL idle high
            busy       <= 1'b0;
            done       <= 1'b0;
            ack_error  <= 1'b0;
            read_data  <= 8'd0;
            rw_latch   <= 1'b0;
            addr_latch <= 7'd0;
            reg_latch  <= 8'd0;
            data_latch <= 8'd0;
            phase_cnt  <= 9'd0;
        end else begin
            // Default: clear done pulse
            done <= 1'b0;

            case (state)
                // ============================================================
                // IDLE — Wait for start trigger
                // ============================================================
                S_IDLE: begin
                    sda_oe    <= 1'b0;   // Release SDA
                    sda_out   <= 1'b1;
                    scl_reg   <= 1'b1;   // SCL high
                    busy      <= 1'b0;
                    ack_error <= 1'b0;
                    phase_cnt <= 9'd0;

                    if (start) begin
                        // Latch all inputs
                        addr_latch <= slave_addr;
                        reg_latch  <= reg_addr;
                        data_latch <= write_data;
                        rw_latch   <= rw;
                        busy       <= 1'b1;
                        state      <= S_START;
                    end
                end

                // ============================================================
                // START — Generate START condition (SDA high→low while SCL high)
                // ============================================================
                S_START: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt < HALF_PERIOD) begin
                        // Ensure SDA and SCL are high first
                        sda_oe  <= 1'b0;   // SDA released (pulled high)
                        scl_reg <= 1'b1;
                    end else if (phase_cnt < CLK_DIV) begin
                        // Pull SDA low while SCL is still high → START
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;
                        scl_reg <= 1'b1;
                    end else begin
                        // Pull SCL low to begin first bit
                        scl_reg   <= 1'b0;
                        phase_cnt <= 9'd0;
                        bit_cnt   <= 4'd7;
                        // Load address + W for first phase
                        shift_reg <= {addr_latch, 1'b0}; // Write
                        state     <= S_SEND_ADDR_W;
                    end
                end

                // ============================================================
                // SEND_ADDR_W — Shift out address byte + W bit (MSB first)
                // ============================================================
                S_SEND_ADDR_W: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        // Set SDA to current bit while SCL is low
                        sda_oe  <= 1'b1;
                        sda_out <= shift_reg[7];
                    end else if (phase_cnt == QUARTER) begin
                        // Raise SCL — data must be stable
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        // Lower SCL
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};

                        if (bit_cnt == 4'd0) begin
                            state <= S_WAIT_ACK1;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // ============================================================
                // WAIT_ACK1 — Check ACK after address+W
                // ============================================================
                S_WAIT_ACK1: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        // Release SDA for slave to drive ACK
                        sda_oe <= 1'b0;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == HALF_PERIOD) begin
                        // Sample SDA — should be LOW for ACK
                        if (sda == 1'b1) begin
                            ack_error <= 1'b1;
                        end
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        bit_cnt   <= 4'd7;
                        shift_reg <= reg_latch;

                        if (ack_error) begin
                            state <= S_STOP;
                        end else begin
                            state <= S_SEND_REG;
                        end
                    end
                end

                // ============================================================
                // SEND_REG — Shift out register address byte
                // ============================================================
                S_SEND_REG: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe  <= 1'b1;
                        sda_out <= shift_reg[7];
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};

                        if (bit_cnt == 4'd0) begin
                            state <= S_WAIT_ACK2;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // ============================================================
                // WAIT_ACK2 — Check ACK after register address
                // ============================================================
                S_WAIT_ACK2: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe <= 1'b0;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == HALF_PERIOD) begin
                        if (sda == 1'b1) begin
                            ack_error <= 1'b1;
                        end
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;

                        if (ack_error) begin
                            state <= S_STOP;
                        end else if (rw_latch) begin
                            // Read mode → need RESTART
                            state <= S_RESTART;
                        end else begin
                            // Write mode → send data
                            bit_cnt   <= 4'd7;
                            shift_reg <= data_latch;
                            state     <= S_SEND_DATA;
                        end
                    end
                end

                // ============================================================
                // SEND_DATA — Shift out data byte (write mode)
                // ============================================================
                S_SEND_DATA: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe  <= 1'b1;
                        sda_out <= shift_reg[7];
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};

                        if (bit_cnt == 4'd0) begin
                            state <= S_WAIT_ACK3;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // ============================================================
                // WAIT_ACK3 — Check ACK after write data
                // ============================================================
                S_WAIT_ACK3: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe <= 1'b0;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == HALF_PERIOD) begin
                        if (sda == 1'b1) begin
                            ack_error <= 1'b1;
                        end
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        state     <= S_STOP;
                    end
                end

                // ============================================================
                // RESTART — Generate repeated START for read phase
                // ============================================================
                S_RESTART: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt < QUARTER) begin
                        // Release SDA (let it go high) while SCL is low
                        sda_oe  <= 1'b0;
                        scl_reg <= 1'b0;
                    end else if (phase_cnt < HALF_PERIOD) begin
                        // Raise SCL with SDA high
                        sda_oe  <= 1'b0;
                        scl_reg <= 1'b1;
                    end else if (phase_cnt < HALF_PERIOD + QUARTER) begin
                        // Pull SDA low while SCL is high → RESTART
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;
                        scl_reg <= 1'b1;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        // Pull SCL low, prepare to send address + R
                        scl_reg   <= 1'b0;
                        phase_cnt <= 9'd0;
                        bit_cnt   <= 4'd7;
                        shift_reg <= {addr_latch, 1'b1}; // Read bit
                        state     <= S_SEND_ADDR_R;
                    end
                end

                // ============================================================
                // SEND_ADDR_R — Shift out address byte + R bit
                // ============================================================
                S_SEND_ADDR_R: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe  <= 1'b1;
                        sda_out <= shift_reg[7];
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        shift_reg <= {shift_reg[6:0], 1'b0};

                        if (bit_cnt == 4'd0) begin
                            state <= S_WAIT_ACK4;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // ============================================================
                // WAIT_ACK4 — Check ACK after address+R
                // ============================================================
                S_WAIT_ACK4: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        sda_oe <= 1'b0;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == HALF_PERIOD) begin
                        if (sda == 1'b1) begin
                            ack_error <= 1'b1;
                        end
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;

                        if (ack_error) begin
                            state <= S_STOP;
                        end else begin
                            bit_cnt   <= 4'd7;
                            shift_reg <= 8'd0;
                            state     <= S_RECV_DATA;
                        end
                    end
                end

                // ============================================================
                // RECV_DATA — Receive data byte from slave (MSB first)
                // ============================================================
                S_RECV_DATA: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        // Release SDA — slave drives data
                        sda_oe <= 1'b0;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == HALF_PERIOD) begin
                        // Sample SDA at mid-point of SCL high
                        shift_reg <= {shift_reg[6:0], sda};
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;

                        if (bit_cnt == 4'd0) begin
                            read_data <= {shift_reg[6:0], sda};
                            state     <= S_SEND_NACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                // ============================================================
                // SEND_NACK — Master sends NACK (SDA=1) to end read
                // ============================================================
                S_SEND_NACK: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt == 9'd0) begin
                        // Drive SDA high (NACK)
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b1;
                    end else if (phase_cnt == QUARTER) begin
                        scl_reg <= 1'b1;
                    end else if (phase_cnt == QUARTER + HALF_PERIOD) begin
                        scl_reg <= 1'b0;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        state     <= S_STOP;
                    end
                end

                // ============================================================
                // STOP — Generate STOP condition (SDA low→high while SCL high)
                // ============================================================
                S_STOP: begin
                    phase_cnt <= phase_cnt + 1'b1;

                    if (phase_cnt < QUARTER) begin
                        // Ensure SDA is low, SCL is low
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;
                        scl_reg <= 1'b0;
                    end else if (phase_cnt < HALF_PERIOD) begin
                        // Raise SCL while SDA is low
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;
                        scl_reg <= 1'b1;
                    end else if (phase_cnt < HALF_PERIOD + QUARTER) begin
                        // Release SDA while SCL is high → STOP
                        sda_oe  <= 1'b0;
                        scl_reg <= 1'b1;
                    end else if (phase_cnt >= CLK_DIV - 1) begin
                        phase_cnt <= 9'd0;
                        state     <= S_DONE;
                    end
                end

                // ============================================================
                // DONE — Signal completion, return to IDLE
                // ============================================================
                S_DONE: begin
                    done    <= 1'b1;
                    busy    <= 1'b0;
                    sda_oe  <= 1'b0;
                    scl_reg <= 1'b1;
                    state   <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
