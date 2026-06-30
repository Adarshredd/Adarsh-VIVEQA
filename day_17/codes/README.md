# Seven Segment Display — MAX7219 Driver

## Overview

SPI-based MAX7219 seven-segment display driver for a **24 MHz FPGA**. Displays an 8-digit BCD counter that increments every second. Uses a 500 kHz SPI clock and includes complete initialization sequence.

## File Listing

| File | Description |
|------|-------------|
| `seg_display.v` | All modules: `max7219_spi` (SPI master) + `seg_display` (top with init FSM + counter) |
| `constraints.xdc` | Vivado constraint file (clk, rst, SPI pins) |

## Module Hierarchy

```
seg_display (top)
├── max7219_spi   — 16-bit SPI master (MSB first, 500 kHz)
├── Init FSM      — Configures MAX7219 registers on reset
├── BCD Counter   — 8-digit BCD counter, increments every 1 second
└── Display Loop  — Writes all 8 digits via SPI after each increment
```

## Architecture

### SPI Master (`max7219_spi`)
- Shifts 16 bits MSB first
- CS held LOW during transfer, raised HIGH to latch
- Clock divider: 24 (24 MHz / 2×24 = 500 kHz SPI clock)
- States: IDLE → SHIFT (16 bits) → LATCH → IDLE

### Initialization Sequence
1. `{0x0C, 0x01}` — Exit shutdown mode
2. `{0x0F, 0x00}` — Disable display test
3. `{0x0B, 0x07}` — Scan limit = 7 (all 8 digits)
4. `{0x09, 0xFF}` — BCD decode for all digits
5. `{0x0A, 0x07}` — Intensity = mid-level (7/15)

### Display Update
- After init, enters run mode
- On each 1-second tick, BCD counter increments
- All 8 digit registers (0x01–0x08) written sequentially via SPI
- Display shows: `00000000` → `00000001` → ... → `99999999` → `00000000`

## Pin Assignments

| Port | Pin | Description |
|------|-----|-------------|
| `clk` | D13 | 24 MHz clock |
| `rst` | A12 | Active-high reset |
| `spi_din` | B7 | MAX7219 DIN |
| `spi_cs` | A7 | MAX7219 LOAD/CS |
| `spi_clk` | D8 | MAX7219 CLK |

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SPI_CLK_DIV` | 24 | SPI half-period (500 kHz) |
| `ONE_SEC_COUNT` | 24000000 | 1-second counter limit |

## Vivado Instructions

### Synthesis
1. Create Project → Add `seg_display.v` + `constraints.xdc`
2. Run Synthesis → Run Implementation → Generate Bitstream
3. Program FPGA via Hardware Manager

### Simulation (optional)
Override parameters for fast simulation:
```verilog
seg_display #(
    .SPI_CLK_DIV(2),
    .ONE_SEC_COUNT(100)
) uut (
    .clk(clk), .rst(rst),
    .spi_clk(spi_clk), .spi_din(spi_din), .spi_cs(spi_cs)
);
```

### Expected Behavior
- On power-up: display initializes and shows `00000000`
- Every second: counter increments by 1
- Display wraps from `99999999` to `00000000`
