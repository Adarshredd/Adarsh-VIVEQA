# =============================================================================
# Seven Segment Display (MAX7219) - Constraints File
# Target: 24 MHz FPGA
# =============================================================================

# Clock
set_property PACKAGE_PIN D13 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 41.667 [get_ports clk]

# Reset
set_property PACKAGE_PIN A12 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# MAX7219 SPI Interface
set_property PACKAGE_PIN B7 [get_ports spi_din]
set_property PACKAGE_PIN A7 [get_ports spi_cs]
set_property PACKAGE_PIN D8 [get_ports spi_clk]
set_property IOSTANDARD LVCMOS33 [get_ports spi_din]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs]
set_property IOSTANDARD LVCMOS33 [get_ports spi_clk]
