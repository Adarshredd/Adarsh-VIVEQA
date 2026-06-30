# Seven Segment Display — MAX7219 Driver Notes

## 1. MAX7219 Overview

The **MAX7219** is a compact, serial input/output common-cathode display driver that can interface with up to **8 digits** of seven-segment displays. It uses a simple **SPI-like** 3-wire serial interface.

### Key Features
- Drives up to 8 seven-segment digits (or 64 individual LEDs in matrix mode)
- Built-in BCD decoder
- Adjustable brightness (16 levels via PWM)
- SPI-compatible serial interface (DIN, CLK, LOAD/CS)
- Cascadable for multi-chip configurations
- Built-in display test mode

## 2. SPI-Like Interface

| Pin | Name | Direction | Description |
|-----|------|-----------|-------------|
| DIN | Data In | FPGA → MAX7219 | Serial data input (MSB first) |
| CLK | Clock | FPGA → MAX7219 | Serial clock (max 10 MHz) |
| LOAD/CS | Chip Select | FPGA → MAX7219 | Active-low during transfer; rising edge latches data |

### Timing Diagram

```
CLK:  _____|‾|_|‾|_|‾|_|‾|_|‾|_| ... |‾|_|‾|___
DIN:  -----<D15><D14><D13> ... <D1><D0>---------
CS:   ‾‾‾‾‾|___________________________|‾‾‾‾‾‾‾
                                         ^ LOAD (latch on rising edge)
```

### 16-bit Data Format

```
Bit:  | 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
      |--- don't care ----|------- Register Address -------|---------- Data ---------------|
```

- **Bits [15:12]**: Don't care (for single device)
- **Bits [11:8]**: 4-bit register address
- **Bits [7:0]**: 8-bit data

## 3. Register Map

| Address | Register | Description |
|---------|----------|-------------|
| 0x00 | No-Op | No operation (for cascading) |
| 0x01–0x08 | Digit 0–7 | Digit data registers |
| 0x09 | Decode Mode | BCD decode enable per digit |
| 0x0A | Intensity | Brightness (0x00–0x0F) |
| 0x0B | Scan Limit | Digits displayed (0x00–0x07) |
| 0x0C | Shutdown | 0x00=off, 0x01=normal |
| 0x0F | Display Test | 0x00=normal, 0x01=all on |

### BCD Decode Values

| Data | Display | Data | Display |
|------|---------|------|---------|
| 0x00 | 0 | 0x05 | 5 |
| 0x01 | 1 | 0x06 | 6 |
| 0x02 | 2 | 0x07 | 7 |
| 0x03 | 3 | 0x08 | 8 |
| 0x04 | 4 | 0x09 | 9 |
| 0x0A | - | 0x0F | blank |

Bit 7 controls the **decimal point** (DP).

## 4. Segment Mapping (No-Decode Mode)

```
     ___
    | a |
   f|   |b
    |___|
    | g |
   e|   |c
    |___|  .dp
      d
```

| Bit | 7  | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|-----|----|----|----|----|----|----|----|----|
| Seg | DP | A  | B  | C  | D  | E  | F  | G  |

## 5. Initialization Sequence

```
1. Write {0x0C, 0x01} — Exit shutdown (normal operation)
2. Write {0x0F, 0x00} — Disable display test
3. Write {0x0B, 0x07} — Scan limit = 7 (all 8 digits)
4. Write {0x09, 0xFF} — BCD decode for all digits
5. Write {0x0A, 0x07} — Intensity = mid-level (7/15)
6. Write digit data to registers 0x01–0x08
```

## 6. SPI Clock Calculation

For 24 MHz FPGA → 500 kHz SPI:
```
SPI_CLK_DIV = 24,000,000 / (2 × 500,000) = 24
Half-period = 24 FPGA clock cycles
```

## 7. Driver Architecture

```
seg_display (top)
├── Init FSM (configure registers)
├── Display Update (write digit data)
└── max7219_spi (shift out 16 bits)
```

## 8. Vivado Steps

1. Create Project → Add `seg_display.v` + `constraints.xdc`
2. Run Synthesis → Run Implementation → Generate Bitstream
3. Program FPGA → Display shows incrementing counter
