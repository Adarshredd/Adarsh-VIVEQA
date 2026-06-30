# RO PUF Authentication System
## Hardware Security Architecture, Verification, and FPGA Implementation

---

## 1. System Architecture & Overview

### 1.1 Design Objective

This project implements a hardware-based authentication system leveraging a **Ring Oscillator (RO) Physical Unclonable Function (PUF)**. The system exploits manufacturing variations in FPGA logic gates and routing to generate unique, unclonable responses to challenge inputs, effectively acting as a digital "fingerprint" for the device. 

The system integrates challenge decoding, frequency measurement, response generation, and multiple peripheral interfaces (LCD, LED, Buzzer, MAX7219, UART) to provide real-time authentication feedback. It demonstrates hardware security principles in a complete System-on-Chip (SoC) style architecture.

### 1.2 Top-Level System Block Diagram

The top-level module (`top.v`) serves as the integration wrapper, instantiating the PUF core, measurement modules, authentication logic, and all peripheral drivers. It manages the global clock, reset, and physical I/O routing to the external components.

### 1.3 Core PUF Components

The core of the PUF relies on measuring the minute differences in propagation delay between identical logic circuits.

| Component | Module | Function |
|---|---|---|
| **Ring Oscillator** | `ring_oscillator.v` | Generates a high-frequency clock signal by chaining an odd number of inverters in a loop, exploiting innate gate delays. |
| **RO Selector Mux** | `ro_selector_mux.v` | Selects specific pairs of ROs from the array based on the provided challenge input. |
| **Frequency Counter** | `frequency_counter.v` | Accurately counts the number of oscillations of the selected ROs over a fixed, precise time window. |
| **Response Generator** | `response_generator.v` | Compares the frequency counts of the selected RO pairs to produce a digital signature (response bit: 1 if RO_A > RO_B, else 0). |

### 1.4 Authentication and Control

These modules orchestrate the high-level logic, timing, and security verification processes.

| Component | Module | Function |
|---|---|---|
| **Challenge Decoder** | `challenge_decoder.v` | Maps user inputs (via physical switches or UART) to valid RO selection challenges. |
| **Measurement Controller** | `measurement_controller.v` | Orchestrates the timing sequence of enabling ROs, starting the counters, and latching the results. |
| **Comparator** | `comparator.v` | Compares the generated PUF response against the expected reference response to determine authenticity. |
| **Authentication Controller** | `authentication_controller.v` | The central state machine governing the end-to-end authentication flow and peripheral triggering based on success or failure. |

### 1.5 Peripheral Interfaces

The system features robust user feedback mechanisms to clearly communicate the authentication state.

| Interface | Module | Description |
|---|---|---|
| **UART Controller** | `uart_controller.v`, `uart_rx.v`, `uart_tx.v` | Provides serial communication for external challenge input, enrollment, and detailed status logging to a host PC. |
| **LCD Driver** | `lcd_driver.v` | Drives a standard 16x2 character LCD to display messages like "Auth Success" or "Auth Failed". |
| **LED Controller** | `led_controller.v` | Provides immediate visual indicators for system state (Idle, Processing, Success, Error). |
| **MAX7219 Driver** | `max7219_driver.v` | Drives an external 7-segment or dot matrix display for real-time visualization of frequency counts or challenge IDs. |
| **Buzzer Controller** | `buzzer_controller.v` | Triggers an audible alarm upon multiple failed authentication attempts to deter brute-force attacks. |
| **Debounce & Clocks** | `debounce.v`, `clock_divider.v` | Ensures clean mechanical button inputs and generates appropriately scaled clock frequencies for different peripherals. |

### 1.6 Data Flow: End-to-End Execution

1. **Challenge Reception**: The system receives a challenge via debounced buttons (`debounce.v`) or serial command (`uart_rx.v`), which is then interpreted by the `challenge_decoder.v`.
2. **Measurement Phase**: The `measurement_controller.v` activates the targeted ROs via the `ro_selector_mux.v`. The `frequency_counter.v` tallies the oscillations over a highly stable time window derived from `clock_divider.v`.
3. **Response Generation**: The `response_generator.v` compares the counted frequencies of the RO pair to produce a unique, stable response bit.
4. **Verification**: The `comparator.v` matches the newly generated PUF response against an enrolled or transmitted expected response.
5. **Feedback & Action**: The `authentication_controller.v` interprets the comparison result and commands the peripherals. It updates the `lcd_driver.v` and `led_controller.v` to indicate success or failure. If verification fails repeatedly, the `buzzer_controller.v` activates an alarm. All system events are logged via `uart_tx.v`.
