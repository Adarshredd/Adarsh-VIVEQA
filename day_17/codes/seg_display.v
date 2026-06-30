//=============================================================================
// seg_display.v — MAX7219 Seven Segment Display Driver
//
// Contains:
//   - max7219_spi  : SPI master for MAX7219 (shifts 16 bits MSB first)
//   - seg_display  : Top module with init FSM + counter display
//
// Target Clock: 24 MHz
// SPI Clock:    500 kHz (DIV = 24)
// Display:      8-digit BCD counter incrementing every second
//
// Author: ADARSH
// Date:   2026-06-27
//=============================================================================


//=============================================================================
// Module: max7219_spi
// SPI-like master for MAX7219.
// Shifts out 16 bits MSB first on spi_din.
// spi_cs held LOW during transfer, pulsed HIGH to latch data.
//=============================================================================
module max7219_spi #(
    parameter CLK_DIV = 24   // SPI half-period in FPGA clocks (500 kHz @ 24 MHz)
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        send,        // Pulse to begin 16-bit transfer
    input  wire [15:0] data_in,     // 16-bit data {addr[11:8], data[7:0]}
    output reg         spi_clk,     // SPI clock to MAX7219
    output reg         spi_din,     // Serial data to MAX7219
    output reg         spi_cs,      // Chip select (active low during transfer)
    output reg         busy,        // HIGH during transfer
    output reg         done         // Single-cycle pulse when transfer complete
);

    // State machine
    localparam [1:0] S_IDLE    = 2'd0,
                     S_SHIFT   = 2'd1,
                     S_LATCH   = 2'd2;

    reg [1:0]  state;
    reg [15:0] shift_reg;     // Shift register
    reg [4:0]  bit_cnt;       // Bit counter (0..15)
    reg [7:0]  clk_cnt;       // Clock divider counter
    reg        spi_clk_phase; // 0 = first half (data setup), 1 = second half (clock edge)

    always @(posedge clk) begin
        if (rst) begin
            state         <= S_IDLE;
            shift_reg     <= 16'd0;
            bit_cnt       <= 5'd0;
            clk_cnt       <= 8'd0;
            spi_clk       <= 1'b0;
            spi_din       <= 1'b0;
            spi_cs        <= 1'b1;   // CS idle HIGH
            busy          <= 1'b0;
            done          <= 1'b0;
            spi_clk_phase <= 1'b0;
        end else begin
            done <= 1'b0;  // Default: clear done pulse

            case (state)
                S_IDLE: begin
                    spi_clk <= 1'b0;
                    spi_cs  <= 1'b1;  // CS idle HIGH
                    busy    <= 1'b0;
                    if (send) begin
                        state     <= S_SHIFT;
                        shift_reg <= data_in;
                        bit_cnt   <= 5'd0;
                        clk_cnt   <= 8'd0;
                        spi_cs    <= 1'b0;   // Assert CS LOW
                        busy      <= 1'b1;
                        spi_din   <= data_in[15]; // MSB first: setup first bit
                        spi_clk_phase <= 1'b0;
                    end
                end

                S_SHIFT: begin
                    if (clk_cnt == CLK_DIV - 1) begin
                        clk_cnt <= 8'd0;

                        if (spi_clk_phase == 1'b0) begin
                            // First half done: raise SPI clock (data sampled on rising edge)
                            spi_clk       <= 1'b1;
                            spi_clk_phase <= 1'b1;
                        end else begin
                            // Second half done: lower SPI clock, advance to next bit
                            spi_clk       <= 1'b0;
                            spi_clk_phase <= 1'b0;

                            if (bit_cnt == 5'd15) begin
                                // All 16 bits shifted out
                                state <= S_LATCH;
                                clk_cnt <= 8'd0;
                            end else begin
                                // Shift to next bit
                                bit_cnt   <= bit_cnt + 5'd1;
                                shift_reg <= {shift_reg[14:0], 1'b0};
                                spi_din   <= shift_reg[14]; // Next MSB
                            end
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end

                S_LATCH: begin
                    // Brief delay then raise CS to latch data
                    if (clk_cnt == CLK_DIV - 1) begin
                        spi_cs <= 1'b1;  // Rising edge of CS latches data
                        done   <= 1'b1;
                        state  <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule


//=============================================================================
// Module: seg_display (Top Module)
// MAX7219 Seven Segment Display Driver
//
// Initialization: configures MAX7219 registers (shutdown, test, scan limit,
//                 decode mode, intensity).
// Running:        displays an 8-digit BCD counter that increments every second.
//
// Ports match constraints.xdc: clk, rst, spi_clk, spi_din, spi_cs
//=============================================================================
module seg_display #(
    parameter SPI_CLK_DIV   = 24,        // SPI clock divider
    parameter ONE_SEC_COUNT = 24000000   // 1 second at 24 MHz
)(
    input  wire clk,
    input  wire rst,
    output wire spi_clk,    // To MAX7219 CLK
    output wire spi_din,    // To MAX7219 DIN
    output wire spi_cs      // To MAX7219 LOAD/CS
);

    // =========================================================================
    // Internal Signals
    // =========================================================================
    reg         spi_send;
    reg  [15:0] spi_data;
    wire        spi_busy;
    wire        spi_done;

    // =========================================================================
    // SPI Master Instance
    // =========================================================================
    max7219_spi #(
        .CLK_DIV(SPI_CLK_DIV)
    ) u_spi (
        .clk      (clk),
        .rst      (rst),
        .send     (spi_send),
        .data_in  (spi_data),
        .spi_clk  (spi_clk),
        .spi_din  (spi_din),
        .spi_cs   (spi_cs),
        .busy     (spi_busy),
        .done     (spi_done)
    );

    // =========================================================================
    // Main FSM States
    // =========================================================================
    localparam [3:0] S_INIT_SHUTDOWN   = 4'd0,
                     S_INIT_WAIT1      = 4'd1,
                     S_INIT_DISPTEST   = 4'd2,
                     S_INIT_WAIT2      = 4'd3,
                     S_INIT_SCANLIMIT  = 4'd4,
                     S_INIT_WAIT3      = 4'd5,
                     S_INIT_DECODE     = 4'd6,
                     S_INIT_WAIT4      = 4'd7,
                     S_INIT_INTENSITY  = 4'd8,
                     S_INIT_WAIT5      = 4'd9,
                     S_RUN_LOAD        = 4'd10,
                     S_RUN_WAIT        = 4'd11,
                     S_RUN_IDLE        = 4'd12;

    reg [3:0]  state;
    reg [3:0]  digit_idx;    // Current digit being updated (1..8)

    // =========================================================================
    // 1-Second Counter and 8-Digit BCD Value
    // =========================================================================
    reg [24:0] sec_counter;    // Counts up to ONE_SEC_COUNT-1
    reg [31:0] display_val;    // 8-digit BCD counter (4 bits per digit)
    reg        update_flag;    // Set when display_val changes

    // BCD increment with carry
    reg [31:0] bcd_next;
    reg [3:0]  bcd_digit;
    reg        bcd_carry;
    integer    d;

    always @(posedge clk) begin
        if (rst) begin
            sec_counter <= 25'd0;
            display_val <= 32'd0;
            update_flag <= 1'b1;  // Force initial display update
        end else begin
            update_flag <= 1'b0;

            if (sec_counter == ONE_SEC_COUNT - 1) begin
                sec_counter <= 25'd0;
                update_flag <= 1'b1;

                // BCD increment
                bcd_carry = 1'b1;
                bcd_next  = display_val;
                for (d = 0; d < 8; d = d + 1) begin
                    bcd_digit = bcd_next[d*4 +: 4];
                    if (bcd_carry) begin
                        if (bcd_digit == 4'd9) begin
                            bcd_next[d*4 +: 4] = 4'd0;
                            bcd_carry = 1'b1;
                        end else begin
                            bcd_next[d*4 +: 4] = bcd_digit + 4'd1;
                            bcd_carry = 1'b0;
                        end
                    end
                end
                display_val <= bcd_next;
            end else begin
                sec_counter <= sec_counter + 25'd1;
            end
        end
    end

    // =========================================================================
    // Extract individual digit values
    // =========================================================================
    wire [7:0] digit_data [0:7];
    
    // Digit registers: addr 0x01=digit0 ... 0x08=digit7
    // BCD decode mode: just send the 4-bit BCD value
    assign digit_data[0] = {4'h0, display_val[3:0]};    // Ones
    assign digit_data[1] = {4'h0, display_val[7:4]};    // Tens
    assign digit_data[2] = {4'h0, display_val[11:8]};   // Hundreds
    assign digit_data[3] = {4'h0, display_val[15:12]};  // Thousands
    assign digit_data[4] = {4'h0, display_val[19:16]};  // Ten-thousands
    assign digit_data[5] = {4'h0, display_val[23:20]};  // Hundred-thousands
    assign digit_data[6] = {4'h0, display_val[27:24]};  // Millions
    assign digit_data[7] = {4'h0, display_val[31:28]};  // Ten-millions

    // =========================================================================
    // Main FSM — Initialization + Display Update
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            state     <= S_INIT_SHUTDOWN;
            spi_send  <= 1'b0;
            spi_data  <= 16'd0;
            digit_idx <= 4'd1;
        end else begin
            spi_send <= 1'b0;  // Default: no send pulse

            case (state)
                // ----- INITIALIZATION SEQUENCE -----

                // Step 1: Exit shutdown mode
                S_INIT_SHUTDOWN: begin
                    spi_data <= {4'h0, 4'hC, 8'h01};  // Addr=0x0C, Data=0x01
                    spi_send <= 1'b1;
                    state    <= S_INIT_WAIT1;
                end

                S_INIT_WAIT1: begin
                    if (spi_done) state <= S_INIT_DISPTEST;
                end

                // Step 2: Disable display test
                S_INIT_DISPTEST: begin
                    spi_data <= {4'h0, 4'hF, 8'h00};  // Addr=0x0F, Data=0x00
                    spi_send <= 1'b1;
                    state    <= S_INIT_WAIT2;
                end

                S_INIT_WAIT2: begin
                    if (spi_done) state <= S_INIT_SCANLIMIT;
                end

                // Step 3: Set scan limit to 7 (all 8 digits)
                S_INIT_SCANLIMIT: begin
                    spi_data <= {4'h0, 4'hB, 8'h07};  // Addr=0x0B, Data=0x07
                    spi_send <= 1'b1;
                    state    <= S_INIT_WAIT3;
                end

                S_INIT_WAIT3: begin
                    if (spi_done) state <= S_INIT_DECODE;
                end

                // Step 4: Enable BCD decode for all digits
                S_INIT_DECODE: begin
                    spi_data <= {4'h0, 4'h9, 8'hFF};  // Addr=0x09, Data=0xFF
                    spi_send <= 1'b1;
                    state    <= S_INIT_WAIT4;
                end

                S_INIT_WAIT4: begin
                    if (spi_done) state <= S_INIT_INTENSITY;
                end

                // Step 5: Set intensity to mid-level
                S_INIT_INTENSITY: begin
                    spi_data <= {4'h0, 4'hA, 8'h07};  // Addr=0x0A, Data=0x07
                    spi_send <= 1'b1;
                    state    <= S_INIT_WAIT5;
                end

                S_INIT_WAIT5: begin
                    if (spi_done) begin
                        state     <= S_RUN_LOAD;
                        digit_idx <= 4'd1;
                    end
                end

                // ----- DISPLAY UPDATE LOOP -----

                // Load digit data and send via SPI
                S_RUN_LOAD: begin
                    // Address = digit_idx (1..8), Data = digit value
                    spi_data <= {4'h0, digit_idx, digit_data[digit_idx - 1]};
                    spi_send <= 1'b1;
                    state    <= S_RUN_WAIT;
                end

                S_RUN_WAIT: begin
                    if (spi_done) begin
                        if (digit_idx == 4'd8) begin
                            // All 8 digits updated
                            digit_idx <= 4'd1;
                            state     <= S_RUN_IDLE;
                        end else begin
                            digit_idx <= digit_idx + 4'd1;
                            state     <= S_RUN_LOAD;
                        end
                    end
                end

                // Wait for next update trigger
                S_RUN_IDLE: begin
                    if (update_flag) begin
                        digit_idx <= 4'd1;
                        state     <= S_RUN_LOAD;
                    end
                end

                default: state <= S_INIT_SHUTDOWN;
            endcase
        end
    end

endmodule
