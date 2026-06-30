##=============================================================================
## XDC Constraints - Ring Oscillator PUF Authentication System
## Board: AT-STLN-ARTIX7-001 (XC7A35T-FTG256-1, 24MHz clock)
## Manual: ANM-PRD-2025-005 Rev 1.0
##=============================================================================

##-----------------------------------------------------------------------------
## Clock — D13 is IO_L12P_T1_MRCC_15 (Bank 15, MRCC-capable)
## D13 is in the TOP half of the chip (Bank 15, Y > mid).
## BUFGCTRL_X0Y31 is also in the top half → clock rule passes cleanly.
## Use -dict syntax so PACKAGE_PIN and IOSTANDARD are set atomically,
## matching the board manual's XDC template exactly.
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports clk_24mhz]
create_clock -period 41.667 -name sys_clk [get_ports clk_24mhz]

##-----------------------------------------------------------------------------
## User LEDs — Bank 35 (Section 3.1)
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]

##-----------------------------------------------------------------------------
## Slide Switches — Bank 35 (Section 3.4)
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN B7 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS33} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN B9 IOSTANDARD LVCMOS33} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN C9 IOSTANDARD LVCMOS33} [get_ports {sw[7]}]

##-----------------------------------------------------------------------------
## LCD (16x2, 8-bit mode) — Bank 35 (Section 4.3)
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports lcd_rs]
set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS33} [get_ports lcd_rw]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports lcd_en]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {lcd_d[0]}]
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {lcd_d[1]}]
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {lcd_d[2]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {lcd_d[3]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {lcd_d[4]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {lcd_d[5]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {lcd_d[6]}]
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {lcd_d[7]}]

##-----------------------------------------------------------------------------
## MAX7219 7-Segment Display — Bank 15 (Section 3.2)
## NOTE: J16 here is the PCB PMOD connector label, NOT FPGA ball J16.
##       FPGA ball J16 is seg_load below — no conflict.
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports seg_din]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports seg_load]
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVCMOS33} [get_ports seg_clk]

##-----------------------------------------------------------------------------
## Buzzer — Bank 35 (Section 4.11)
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN K5 IOSTANDARD LVCMOS33} [get_ports buzzer]

##-----------------------------------------------------------------------------
## UART — PMOD connector J16, Bank 34 (Section 3.7)
## No dedicated FPGA-to-USB UART on this board (FT232H = JTAG only).
## Connect an external USB-UART adapter to PMOD header:
##   PMOD Pin 1  (IO_0 = T2) → UART TX  (FPGA transmits)
##   PMOD Pin 2  (IO_1 = R3) → UART RX  (FPGA receives)
##   PMOD Pin 19              → GND
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN R3 IOSTANDARD LVCMOS33} [get_ports uart_rx]

##-----------------------------------------------------------------------------
## Push Buttons — mapped to 4×4 keypad pins, Bank 35 (Section 3.5)
## Section 3.6 (Push Buttons) is undocumented in the manual Rev 1.0.
## Keypad pins are used since the keypad is not used in this design.
## These pins have 10K pull-ups and 100nF debounce caps on the PCB.
##
##   btn_enroll    → keypad key 0  → A13
##   btn_auth      → keypad key 1  → F5
##   btn_measure   → keypad key 2  → E3
##   btn_clear     → keypad key 3  → F2
##   btn_uart_dump → keypad key 4  → A12
##   btn_reserved  → keypad key 5  → D6
##-----------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports btn_enroll]
set_property -dict {PACKAGE_PIN F5 IOSTANDARD LVCMOS33} [get_ports btn_auth]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports btn_measure]
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports btn_clear]
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports btn_uart_dump]
set_property -dict {PACKAGE_PIN D6  IOSTANDARD LVCMOS33} [get_ports btn_reserved]

## No explicit PULLUP needed — PCB already has 10K pull-ups on keypad pins

##-----------------------------------------------------------------------------
## Ring Oscillator Placement Constraints
## Each RO is placed in a dedicated SLICE to ensure consistent routing
## and maximise frequency uniqueness due to process variation.
##-----------------------------------------------------------------------------

## RO 0
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_and}]
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y0 [get_cells {gen_ro[0].u_ro/lut_inv4}]

## RO 1
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_and}]
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y1 [get_cells {gen_ro[1].u_ro/lut_inv4}]

## RO 2
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_and}]
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y2 [get_cells {gen_ro[2].u_ro/lut_inv4}]

## RO 3
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_and}]
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y3 [get_cells {gen_ro[3].u_ro/lut_inv4}]

## RO 4
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_and}]
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y4 [get_cells {gen_ro[4].u_ro/lut_inv4}]

## RO 5
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_and}]
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y5 [get_cells {gen_ro[5].u_ro/lut_inv4}]

## RO 6
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_and}]
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y6 [get_cells {gen_ro[6].u_ro/lut_inv4}]

## RO 7
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_and}]
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y7 [get_cells {gen_ro[7].u_ro/lut_inv4}]

## RO 8
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_and}]
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y8 [get_cells {gen_ro[8].u_ro/lut_inv4}]

## RO 9
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_and}]
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y9 [get_cells {gen_ro[9].u_ro/lut_inv4}]

## RO 10
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_and}]
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y10 [get_cells {gen_ro[10].u_ro/lut_inv4}]

## RO 11
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_and}]
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y11 [get_cells {gen_ro[11].u_ro/lut_inv4}]

## RO 12
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_and}]
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y12 [get_cells {gen_ro[12].u_ro/lut_inv4}]

## RO 13
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_and}]
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y13 [get_cells {gen_ro[13].u_ro/lut_inv4}]

## RO 14
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_and}]
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y14 [get_cells {gen_ro[14].u_ro/lut_inv4}]

## RO 15
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_and}]
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_inv0}]
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_inv1}]
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_inv2}]
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_inv3}]
set_property LOC SLICE_X0Y15 [get_cells {gen_ro[15].u_ro/lut_inv4}]

##-----------------------------------------------------------------------------
## Ring Oscillator: Allow combinatorial loops (suppress DRC errors)
##-----------------------------------------------------------------------------
set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets -hierarchical *inv4_out*]
set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets -hierarchical *and_out*]

##-----------------------------------------------------------------------------
## False path: RO outputs are asynchronous to sys_clk.
## They are synchronised by 3-FF synchronisers inside frequency_counter.
## Target only the first FF in the synchroniser chain — LUT outputs in
## combinatorial loops are not valid timing startpoints.
##-----------------------------------------------------------------------------
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *osc_sync_reg[0]/D}]

##-----------------------------------------------------------------------------
## Bitstream settings
##-----------------------------------------------------------------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

