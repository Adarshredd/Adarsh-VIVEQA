##=============================================================================
## XDC Constraints - Edge Artix 7 FPGA Development Board
## Board: xc7a35tftg256-1
## Note: This board has a 50MHz clock. The original design expects 24MHz. 
##       You must change CLK_FREQ to 50_000_000 in top.v for correct UART baud!
##=============================================================================

##-----------------------------------------------------------------------------
## Clock (50MHz)
##-----------------------------------------------------------------------------
set_property PACKAGE_PIN N11 [get_ports clk_24mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_24mhz]
create_clock -period 20.000 -name sys_clk [get_ports clk_24mhz]

##-----------------------------------------------------------------------------
## LEDs (Using the first 8 of the 16 onboard LEDs)
##-----------------------------------------------------------------------------
set_property PACKAGE_PIN J3 [get_ports {led[0]}]
set_property PACKAGE_PIN H3 [get_ports {led[1]}]
set_property PACKAGE_PIN J1 [get_ports {led[2]}]
set_property PACKAGE_PIN K1 [get_ports {led[3]}]
set_property PACKAGE_PIN L3 [get_ports {led[4]}]
set_property PACKAGE_PIN L2 [get_ports {led[5]}]
set_property PACKAGE_PIN K3 [get_ports {led[6]}]
set_property PACKAGE_PIN K2 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

##-----------------------------------------------------------------------------
## Slide Switches (Using the first 8 of the 16 onboard switches)
##-----------------------------------------------------------------------------
set_property PACKAGE_PIN L5 [get_ports {sw[0]}]
set_property PACKAGE_PIN L4 [get_ports {sw[1]}]
set_property PACKAGE_PIN M4 [get_ports {sw[2]}]
set_property PACKAGE_PIN M2 [get_ports {sw[3]}]
set_property PACKAGE_PIN M1 [get_ports {sw[4]}]
set_property PACKAGE_PIN N3 [get_ports {sw[5]}]
set_property PACKAGE_PIN N2 [get_ports {sw[6]}]
set_property PACKAGE_PIN N1 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]

##-----------------------------------------------------------------------------
## UART (USB UART interface)
##-----------------------------------------------------------------------------
set_property PACKAGE_PIN C4 [get_ports uart_tx]
set_property PACKAGE_PIN D4 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

##-----------------------------------------------------------------------------
## Push Buttons 
## Edge Artix 7 has 4 directional buttons + 1 reset button.
## We map 5 of the 6 required buttons to the onboard buttons.
## For the 6th button (btn_reserved), you will need to map it to a GPIO header.
##-----------------------------------------------------------------------------
set_property PACKAGE_PIN L13 [get_ports btn_enroll]
set_property PACKAGE_PIN L14 [get_ports btn_auth]
set_property PACKAGE_PIN M12 [get_ports btn_measure]
set_property PACKAGE_PIN K13 [get_ports btn_clear]
set_property PACKAGE_PIN M14 [get_ports btn_uart_dump]

# btn_reserved is left unassigned (map to a GPIO header pin if needed)
# set_property PACKAGE_PIN <GPIO_PIN> [get_ports btn_reserved]

set_property IOSTANDARD LVCMOS33 [get_ports btn_enroll]
set_property IOSTANDARD LVCMOS33 [get_ports btn_auth]
set_property IOSTANDARD LVCMOS33 [get_ports btn_measure]
set_property IOSTANDARD LVCMOS33 [get_ports btn_clear]
set_property IOSTANDARD LVCMOS33 [get_ports btn_uart_dump]
# set_property IOSTANDARD LVCMOS33 [get_ports btn_reserved]

set_property PULLUP true [get_ports btn_enroll]
set_property PULLUP true [get_ports btn_auth]
set_property PULLUP true [get_ports btn_measure]
set_property PULLUP true [get_ports btn_clear]
set_property PULLUP true [get_ports btn_uart_dump]
# set_property PULLUP true [get_ports btn_reserved]

##-----------------------------------------------------------------------------
## External Modules (LCD, MAX7219, Buzzer)
## The Edge Artix-7 board does not have these onboard. 
## You must map these to the 2x20 or 2x17 Expansion Headers based on your wiring.
## The pins below are left commented out as placeholders.
##-----------------------------------------------------------------------------

# LCD 16x2
# set_property PACKAGE_PIN <PIN> [get_ports lcd_rs]
# set_property PACKAGE_PIN <PIN> [get_ports lcd_rw]
# set_property PACKAGE_PIN <PIN> [get_ports lcd_en]
# set_property PACKAGE_PIN <PIN> [get_ports {lcd_d[0]}]
# ...

# MAX7219 7-Segment Display
# set_property PACKAGE_PIN <PIN> [get_ports seg_din]
# set_property PACKAGE_PIN <PIN> [get_ports seg_load]
# set_property PACKAGE_PIN <PIN> [get_ports seg_clk]

# Buzzer
# set_property PACKAGE_PIN <PIN> [get_ports buzzer]

##-----------------------------------------------------------------------------
## Ring Oscillator Placement Constraints
## Each RO is placed in SLICE_X0Y{index} to ensure consistent routing
## and maximize frequency uniqueness due to process variation.
##-----------------------------------------------------------------------------

## RO 0
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_and]
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_inv0]
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_inv1]
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_inv2]
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_inv3]
set_property LOC SLICE_X0Y0 [get_cells gen_ro[0].u_ro/lut_inv4]

## RO 1
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_and]
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_inv0]
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_inv1]
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_inv2]
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_inv3]
set_property LOC SLICE_X0Y1 [get_cells gen_ro[1].u_ro/lut_inv4]

## RO 2
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_and]
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_inv0]
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_inv1]
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_inv2]
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_inv3]
set_property LOC SLICE_X0Y2 [get_cells gen_ro[2].u_ro/lut_inv4]

## RO 3
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_and]
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_inv0]
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_inv1]
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_inv2]
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_inv3]
set_property LOC SLICE_X0Y3 [get_cells gen_ro[3].u_ro/lut_inv4]

## RO 4
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_and]
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_inv0]
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_inv1]
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_inv2]
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_inv3]
set_property LOC SLICE_X0Y4 [get_cells gen_ro[4].u_ro/lut_inv4]

## RO 5
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_and]
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_inv0]
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_inv1]
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_inv2]
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_inv3]
set_property LOC SLICE_X0Y5 [get_cells gen_ro[5].u_ro/lut_inv4]

## RO 6
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_and]
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_inv0]
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_inv1]
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_inv2]
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_inv3]
set_property LOC SLICE_X0Y6 [get_cells gen_ro[6].u_ro/lut_inv4]

## RO 7
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_and]
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_inv0]
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_inv1]
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_inv2]
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_inv3]
set_property LOC SLICE_X0Y7 [get_cells gen_ro[7].u_ro/lut_inv4]

## RO 8
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_and]
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_inv0]
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_inv1]
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_inv2]
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_inv3]
set_property LOC SLICE_X0Y8 [get_cells gen_ro[8].u_ro/lut_inv4]

## RO 9
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_and]
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_inv0]
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_inv1]
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_inv2]
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_inv3]
set_property LOC SLICE_X0Y9 [get_cells gen_ro[9].u_ro/lut_inv4]

## RO 10
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_and]
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_inv0]
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_inv1]
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_inv2]
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_inv3]
set_property LOC SLICE_X0Y10 [get_cells gen_ro[10].u_ro/lut_inv4]

## RO 11
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_and]
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_inv0]
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_inv1]
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_inv2]
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_inv3]
set_property LOC SLICE_X0Y11 [get_cells gen_ro[11].u_ro/lut_inv4]

## RO 12
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_and]
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_inv0]
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_inv1]
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_inv2]
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_inv3]
set_property LOC SLICE_X0Y12 [get_cells gen_ro[12].u_ro/lut_inv4]

## RO 13
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_and]
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_inv0]
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_inv1]
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_inv2]
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_inv3]
set_property LOC SLICE_X0Y13 [get_cells gen_ro[13].u_ro/lut_inv4]

## RO 14
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_and]
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_inv0]
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_inv1]
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_inv2]
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_inv3]
set_property LOC SLICE_X0Y14 [get_cells gen_ro[14].u_ro/lut_inv4]

## RO 15
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_and]
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_inv0]
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_inv1]
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_inv2]
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_inv3]
set_property LOC SLICE_X0Y15 [get_cells gen_ro[15].u_ro/lut_inv4]

##-----------------------------------------------------------------------------
## Ring Oscillator: Allow combinatorial loops (suppress DRC errors)
##-----------------------------------------------------------------------------
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical *inv4_out*]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical *and_out*]

##-----------------------------------------------------------------------------
## False path: Ring oscillator outputs are asynchronous to sys_clk
##-----------------------------------------------------------------------------
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *osc_sync_reg[0]/D}]

##-----------------------------------------------------------------------------
## Bitstream settings
##-----------------------------------------------------------------------------
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
