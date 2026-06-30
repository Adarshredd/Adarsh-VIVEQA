# I2C Protocol — Comprehensive Notes

## Table of Contents
1. [I2C Protocol Overview](#1-i2c-protocol-overview)
2. [Electrical Characteristics](#2-electrical-characteristics)
3. [Protocol Fundamentals](#3-protocol-fundamentals)
4. [Addressing](#4-addressing)
5. [Data Transfer — Write Operation](#5-data-transfer--write-operation)
6. [Data Transfer — Read Operation](#6-data-transfer--read-operation)
7. [Clock Stretching](#7-clock-stretching)
8. [MPU6050 IMU Sensor](#8-mpu6050-imu-sensor)
9. [Timing Diagrams](#9-timing-diagrams)
10. [Vivado Simulation & Synthesis](#10-vivado-simulation--synthesis)

---

## 1. I2C Protocol Overview

**I2C** (Inter-Integrated Circuit), developed by Philips (now NXP), is a synchronous,
multi-master, multi-slave, half-duplex serial communication protocol using only **two wires**:

| Signal | Name         | Function                              |
|--------|--------------|---------------------------------------|
| SDA    | Serial Data  | Bidirectional data line               |
| SCL    | Serial Clock | Clock line, driven by master          |

### Key Features
- **Half-duplex**: Data flows in one direction at a time on SDA
- **Open-drain/open-collector**: Both lines require **pull-up resistors** (typically 4.7 kΩ)
- **Addressable**: Each slave has a unique 7-bit (or 10-bit) address
- **Multi-master capable**: Bus arbitration via SDA monitoring
- **Speed modes**:

| Mode            | Max Clock | Notes                    |
|-----------------|-----------|--------------------------|
| Standard Mode   | 100 kHz   | Most common, universal   |
| Fast Mode       | 400 kHz   | Widely supported         |
| Fast Mode Plus  | 1 MHz     | Stronger pull-ups needed |
| High Speed Mode | 3.4 MHz   | Requires master code     |

Our design targets **Standard Mode (100 kHz)** with a **24 MHz** system clock.

---

## 2. Electrical Characteristics

### Open-Drain Bus Architecture

```
        VDD (3.3V)
         │    │
        [Rp]  [Rp]     Rp = Pull-up resistor (4.7 kΩ typical)
         │    │
    SDA──┤    ├──SCL
         │    │
  ┌──────┴────┴──────┐
  │     MASTER       │
  │   (FPGA Board)   │
  └──────┬────┬──────┘
         │    │
  ┌──────┴────┴──────┐
  │     SLAVE        │
  │   (MPU6050)      │
  └──────────────────┘
```

- **Logic HIGH**: No device pulls the line low → pull-up resistor pulls to VDD
- **Logic LOW**: A device activates its open-drain FET → line pulled to GND
- This allows **wired-AND** behavior — any device can pull the bus low

### FPGA Implementation (Tristate)

```verilog
// SDA is bidirectional — implemented with tristate buffer
assign sda = (sda_oe) ? 1'b0 : 1'bz;  // Drive low or release (high-Z)
wire sda_in = sda;                       // Read SDA state
```

> **Important**: The FPGA never drives SDA high. It either drives LOW or releases
> (high-impedance), letting the external pull-up resistor pull the line high.

---

## 3. Protocol Fundamentals

### 3.1 START Condition

A **START** condition is generated when SDA transitions from HIGH to LOW
**while SCL is HIGH**.

```
    SCL:  ─────────┐          
                    └──────   
    SDA:  ──────┐              
                └──────────   
                 ↑
              START
```

- This signals all slaves that a transaction is beginning
- Only a master can generate START

### 3.2 STOP Condition

A **STOP** condition is generated when SDA transitions from LOW to HIGH
**while SCL is HIGH**.

```
    SCL:       ┌───────────
          ─────┘
    SDA:          ┌────────
          ────────┘
                   ↑
                 STOP
```

- Releases the bus for other masters
- Slaves reset their internal I2C logic

### 3.3 Repeated START (RESTART)

A **Repeated START** is a START condition issued without a preceding STOP.
Used to change direction (write→read) without releasing the bus.

```
    SCL:  ───┐    ┌────┐         
             └────┘    └─────   
    SDA:  ──────────┐            
                    └────────   
                     ↑
                  RESTART
```

### 3.4 Data Bit Transfer

Data is transferred one bit at a time. **SDA must be stable while SCL is HIGH**.
SDA may only change when SCL is LOW.

```
    SCL:     ┌─────┐     ┌─────┐
         ────┘     └─────┘     └────
    SDA:  ═══╤═══════════╤══════════
             │  Bit N    │  Bit N-1
         ────┘           └──────────
         ← Setup →← Hold →
```

- **MSB first**: Bit 7 is sent first, Bit 0 last
- 8 data bits per byte, followed by 1 ACK/NACK bit

### 3.5 ACK / NACK

After every 8 data bits, the **receiver** must send an acknowledge:

| Response | SDA State | Meaning                                |
|----------|-----------|----------------------------------------|
| **ACK**  | LOW       | Byte received successfully, send more  |
| **NACK** | HIGH      | Error, or last byte in read sequence   |

```
         Bit 0    ACK/NACK
    SCL:  ┌───┐   ┌───┐
     ─────┘   └───┘   └───
    SDA:      ═════╤═══════
                   │ Receiver
                   │ drives SDA
```

- During **write**: Slave sends ACK (pulls SDA low)
- During **read**: Master sends ACK for all bytes except the last (sends NACK on last byte to signal end)

---

## 4. Addressing

### 7-Bit Addressing

The first byte after START contains the **slave address (7 bits)** and the **R/W bit (1 bit)**:

```
    Byte 1 (Address Byte):
    ┌────┬────┬────┬────┬────┬────┬────┬────┐
    │ A6 │ A5 │ A4 │ A3 │ A2 │ A1 │ A0 │ R/W│
    └────┴────┴────┴────┴────┴────┴────┴────┘
     MSB                              LSB
    
    R/W = 0 → Write (Master sends data to slave)
    R/W = 1 → Read  (Master receives data from slave)
```

### Address Byte Construction

```verilog
// For MPU6050 (address = 7'h68):
// Write: {7'h68, 1'b0} = 8'hD0
// Read:  {7'h68, 1'b1} = 8'hD1
wire [7:0] addr_byte = {slave_addr, rw_bit};
```

### Reserved Addresses

| Address    | Purpose                      |
|------------|------------------------------|
| 0000 000   | General call                 |
| 0000 001   | CBUS address                 |
| 0000 010   | Reserved for different format|
| 0000 011   | Reserved for future purposes |
| 0000 1XX   | High-speed master code       |
| 1111 1XX   | Reserved for future purposes |
| 1111 0XX   | 10-bit slave addressing      |

---

## 5. Data Transfer — Write Operation

### Single-Byte Register Write

Used to configure slave registers (e.g., wake up MPU6050).

```
Master: [S] [ADDR+W] [   ] [REG_ADDR] [   ] [DATA] [   ] [P]
Slave:                [ACK]            [ACK]        [ACK]

S = START, P = STOP, ADDR+W = slave address + write bit
```

### Sequence Diagram

```
    SDA: ─┐ ┌─A6─A5─A4─A3─A2─A1─A0─W─┐ ┌─R7─R6─R5─R4─R3─R2─R1─R0─┐ ┌─D7─D6─...─D0─┐    ┌─
          └─┘                          └─┘                            └─┘               └────┘
    SCL: ───┐  ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐  ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐ ┌┐  ┌┐ ┌┐  ... ┌┐ ┌┐  ┌┐ ┌──
            └──┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└──┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└──┘└─┘└─     ┘└─┘└──┘└─┘
          START    Address + W     ACK     Register Addr     ACK    Data Byte    ACK   STOP
```

### Verilog Flow

```
STATE_IDLE → (start trigger)
STATE_START → generate START condition
STATE_SEND_ADDR → shift out {slave_addr, 1'b0} (write)
STATE_WAIT_ACK1 → release SDA, check for ACK
STATE_SEND_REG → shift out reg_addr[7:0]
STATE_WAIT_ACK2 → check ACK
STATE_SEND_DATA → shift out write_data[7:0]
STATE_WAIT_ACK3 → check ACK
STATE_STOP → generate STOP condition
STATE_IDLE → done = 1
```

---

## 6. Data Transfer — Read Operation

### Single-Byte Register Read

Reading requires a **write phase** (to set register pointer) followed by a
**repeated START** and **read phase**.

```
Master: [S] [ADDR+W] [   ] [REG] [   ] [Sr] [ADDR+R] [   ] [     ] [NACK] [P]
Slave:                [ACK]      [ACK]                [ACK] [DATA]

S = START, Sr = Repeated START, P = STOP
```

### Detailed Flow

```
Phase 1 (Write register address):
  START → Slave Addr + W → ACK → Register Addr → ACK

Phase 2 (Read data):
  RESTART → Slave Addr + R → ACK → (Slave sends data) → Master NACK → STOP
```

### Why Repeated START?

- The write phase sets the slave's internal register pointer
- The repeated START switches direction without releasing the bus
- Without RESTART, another master could seize the bus between write and read

---

## 7. Clock Stretching

**Clock stretching** allows a slow slave to pause the master by holding SCL LOW.

```
    SCL (Master drives): ───┐     ┌───────────
                             └─────┘
    SCL (Slave holds):            └────┐
                                       └──────
    SCL (Actual on bus):  ───┐         ┌──────
                             └─────────┘
                              ← Slave  →
                               holds SCL
                               low
```

### FPGA Implementation

```verilog
// Before assuming SCL is high, read the actual bus value
// If slave holds SCL low, wait until it releases
if (scl_target == 1'b1 && scl_pin == 1'b0) begin
    // Slave is stretching — wait
end else begin
    // Proceed with transaction
end
```

---

## 8. MPU6050 IMU Sensor

### Overview

The **MPU6050** is a 6-axis Motion Processing Unit containing:
- 3-axis accelerometer (±2g, ±4g, ±8g, ±16g)
- 3-axis gyroscope (±250, ±500, ±1000, ±2000 °/s)
- Temperature sensor
- Digital Motion Processor (DMP)

### I2C Configuration

| Parameter        | Value                           |
|------------------|---------------------------------|
| I2C Address      | `0x68` (AD0=GND) or `0x69` (AD0=VDD) |
| Bus Speed        | Standard (100 kHz) or Fast (400 kHz)  |
| Logic Level      | 3.3V                            |

### Key Register Map

| Address | Name            | Description                     | Reset Value |
|---------|-----------------|---------------------------------|-------------|
| `0x3B`  | ACCEL_XOUT_H    | Accelerometer X-axis high byte  | —           |
| `0x3C`  | ACCEL_XOUT_L    | Accelerometer X-axis low byte   | —           |
| `0x3D`  | ACCEL_YOUT_H    | Accelerometer Y-axis high byte  | —           |
| `0x3E`  | ACCEL_YOUT_L    | Accelerometer Y-axis low byte   | —           |
| `0x3F`  | ACCEL_ZOUT_H    | Accelerometer Z-axis high byte  | —           |
| `0x40`  | ACCEL_ZOUT_L    | Accelerometer Z-axis low byte   | —           |
| `0x41`  | TEMP_OUT_H      | Temperature high byte           | —           |
| `0x42`  | TEMP_OUT_L      | Temperature low byte            | —           |
| `0x43`  | GYRO_XOUT_H     | Gyroscope X-axis high byte      | —           |
| `0x44`  | GYRO_XOUT_L     | Gyroscope X-axis low byte       | —           |
| `0x45`  | GYRO_YOUT_H     | Gyroscope Y-axis high byte      | —           |
| `0x46`  | GYRO_YOUT_L     | Gyroscope Y-axis low byte       | —           |
| `0x47`  | GYRO_ZOUT_H     | Gyroscope Z-axis high byte      | —           |
| `0x48`  | GYRO_ZOUT_L     | Gyroscope Z-axis low byte       | —           |
| `0x6B`  | PWR_MGMT_1      | Power management 1              | `0x40`      |
| `0x6C`  | PWR_MGMT_2      | Power management 2              | `0x00`      |
| `0x75`  | WHO_AM_I        | Device identity (returns `0x68`)| `0x68`      |
| `0x1A`  | CONFIG          | FSYNC and DLPF configuration    | `0x00`      |
| `0x1B`  | GYRO_CONFIG     | Gyroscope configuration         | `0x00`      |
| `0x1C`  | ACCEL_CONFIG    | Accelerometer configuration     | `0x00`      |
| `0x19`  | SMPLRT_DIV      | Sample rate divider             | `0x00`      |

### PWR_MGMT_1 Register (0x6B)

```
Bit 7: DEVICE_RESET — Write 1 to reset all registers
Bit 6: SLEEP        — 1 = sleep mode (DEFAULT ON AT POWER-UP!)
Bit 5: CYCLE        — 1 = cycle between sleep and wake
Bit 4: —            — Reserved
Bit 3: TEMP_DIS     — 1 = disable temperature sensor
Bit 2:0 CLKSEL      — Clock source selection
        000 = Internal 8 MHz oscillator
        001 = PLL with X axis gyroscope reference
```

> **Critical**: On power-up, the MPU6050 is in **SLEEP mode** (bit 6 = 1).
> You MUST write `0x00` to `PWR_MGMT_1` (0x6B) to wake it up!

### WHO_AM_I Register (0x75)

- Read-only register, returns `0x68` (the upper 6 bits of the I2C address)
- Used to verify communication: if you read `0x68`, the bus is working correctly

### Accelerometer Data Registers

Each axis has a 16-bit signed value split across two registers:

```
ACCEL_X = {ACCEL_XOUT_H[7:0], ACCEL_XOUT_L[7:0]}  // 16-bit signed
```

At default ±2g range: **1g = 16384 LSB**

---

## 9. Timing Diagrams

### Complete Write Transaction: Wake Up MPU6050

Write `0x00` to register `0x6B` at slave address `0x68`:

```
         ┌── START
         │
SDA: ────┘ 1 1 0 1 0 0 0 0  A  0 1 1 0 1 0 1 1  A  0 0 0 0 0 0 0 0  A  ┌── STOP
              │               │    │               │    │               │  │
              └─ 0x68 + W ───┘    └─── 0x6B ──────┘    └──── 0x00 ────┘  │
                (0xD0)              (PWR_MGMT_1)        (Wake up)         │
                                                                          │
SCL: ────┐ ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐ ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐ ┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐ ┌┐────
         └─┘└┘└┘└┘└┘└┘└┘└┘└┘└─┘└┘└┘└┘└┘└┘└┘└┘└┘└─┘└┘└┘└┘└┘└┘└┘└┘└┘└─┘└┘
          S  1  2  3  4  5  6  7  8  9  1  2  3  4  5  6  7  8  9  ...

         A = ACK (slave pulls SDA low), S = START
```

### Complete Read Transaction: Read WHO_AM_I

Read register `0x75` from slave `0x68`:

```
Phase 1 — Set register pointer:
SDA: ────┘ 1 1 0 1 0 0 0 0  A  0 1 1 1 0 1 0 1  A  ┐
              └─ 0xD0 ──────┘    └──── 0x75 ────────┘│
                                                      │
Phase 2 — Read data:                                  │
     ┘ 1 1 0 1 0 0 0 1  A  0 1 1 0 1 0 0 0  N  ┌────┘
        └─ 0xD1 ──────┘    └── 0x68 (data) ──┘  │
        (ADDR + R)          (WHO_AM_I value)   NACK
                                                STOP
     ↑
  RESTART
```

### SCL Generation from 24 MHz Clock

```
System Clock:  24 MHz → Period = 41.667 ns
SCL Target:    100 kHz → Period = 10 μs → Half-period = 5 μs
Divider:       5 μs / 41.667 ns = 120 counts per half-period
Full Divider:  240 counts per full SCL period

clk:    ┌┐┌┐┌┐┌┐┌┐┌┐ ... ┌┐┌┐┌┐┌┐┌┐ ... ┌┐┌┐┌┐┌┐┌┐
        └┘└┘└┘└┘└┘└┘     └┘└┘└┘└┘└┘     └┘└┘└┘└┘└┘

counter: 0  1  2  3 ...   119  120 121 ... 239  0  1 ...

SCL:    ─────────────────────┐                   ┌─────
                             └───────────────────┘
        ←── 120 clocks ────→←── 120 clocks ─────→
              (HIGH)               (LOW)
```

---

## 10. Vivado Simulation & Synthesis

### Creating a Vivado Project

1. Open **Vivado 2024.x** (or your version)
2. **File → New Project** → Next
3. Project name: `I2C_MPU6050`, Location: choose your directory
4. **RTL Project**, check "Do not specify sources at this time" → Next
5. Select your target FPGA part → Next → Finish

### Adding Source Files

1. **Sources → Add Sources → Add or Create Design Sources**
2. Add `i2c_master.v` and `mpu6050_top.v`
3. **Add or Create Constraints** → Add `constraints.xdc`

### Running Synthesis

1. Click **Run Synthesis** in the Flow Navigator
2. Wait for completion — fix any errors/warnings
3. Review **Schematic** (Synthesis → Open Synthesized Design → Schematic)
4. Verify the I2C tristate buffer is inferred correctly

### Running Behavioral Simulation

1. **Add Simulation Sources** → Add your testbench file
2. **Flow Navigator → Run Simulation → Run Behavioral Simulation**
3. In the waveform viewer, add SDA, SCL, and FSM state signals
4. Run for sufficient time (at least 1 ms for one I2C transaction at 100 kHz)
5. Verify:
   - START condition: SDA falls while SCL is high
   - Correct address byte on SDA
   - ACK bits present
   - STOP condition: SDA rises while SCL is high

### Running Implementation

1. After synthesis succeeds, click **Run Implementation**
2. Review timing report — ensure all timing constraints are met
3. **Generate Bitstream** → program FPGA

### Hardware Verification

1. Connect MPU6050 module to FPGA:
   - SDA → FPGA pin C14 (with 4.7 kΩ pull-up to 3.3V)
   - SCL → FPGA pin C15 (with 4.7 kΩ pull-up to 3.3V)
   - VCC → 3.3V, GND → GND
2. Program FPGA with generated bitstream
3. Verify WHO_AM_I read (LEDs should show specific pattern)
4. Observe LEDs changing with accelerometer tilt

### Debugging with ILA (Integrated Logic Analyzer)

```tcl
# In Vivado TCL console, add ILA core:
create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets clk]
# Add SDA, SCL, state signals to probe
```

---

## Quick Reference Card

| Item                  | Value                              |
|-----------------------|------------------------------------|
| Protocol              | I2C, Standard Mode                 |
| SCL Frequency         | 100 kHz                            |
| System Clock          | 24 MHz                             |
| Clock Divider         | 240 (half = 120)                   |
| MPU6050 Address       | 7'h68 (0x68)                       |
| Write Byte            | 8'hD0 (0x68 << 1 | 0)             |
| Read Byte             | 8'hD1 (0x68 << 1 | 1)             |
| Wake-up Register      | 0x6B ← 0x00                       |
| Identity Register     | 0x75 → 0x68                       |
| Accel X High          | 0x3B                               |
| Accel X Low           | 0x3C                               |
| SDA Pin (FPGA)        | C14                                |
| SCL Pin (FPGA)        | C15                                |
| Pull-up Resistors     | 4.7 kΩ to 3.3V (external)         |
