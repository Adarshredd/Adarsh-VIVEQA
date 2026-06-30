#==============================================================================
# Vivado Non-Project Mode Build Script
# Ring Oscillator PUF Authentication System
# Board: AT-STLN-ARTIX7-001 (XC7A35T-FTG256-1, 24MHz clock)
#
# Usage:
#   vivado -mode batch -source build.tcl
#
# Or from Vivado Tcl Console:
#   cd <path_to_project_root>
#   source build.tcl
#==============================================================================

# Exit on error
set_msg_config -severity ERROR -new_severity ERROR

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
set PART        xc7a35tftg256-1
set TOP         top
set PRJ_DIR     [file dirname [info script]]
set SRC_DIR     ${PRJ_DIR}/src
set XDC_DIR     ${PRJ_DIR}/constraints
set OUT_DIR     ${PRJ_DIR}/output
set RPT_DIR     ${OUT_DIR}/reports

# Create output directories
file mkdir ${OUT_DIR}
file mkdir ${RPT_DIR}

#------------------------------------------------------------------------------
# Read source files
#------------------------------------------------------------------------------
puts "==== Reading design sources ===="

read_verilog [glob ${SRC_DIR}/*.v]
read_xdc     ${XDC_DIR}/top.xdc

#------------------------------------------------------------------------------
# Synthesis
#------------------------------------------------------------------------------
puts "==== Running Synthesis ===="

synth_design \
    -top ${TOP} \
    -part ${PART} \
    -flatten_hierarchy rebuilt \
    -keep_equivalent_registers

# Check that ring oscillators survived synthesis
set ro_cells [get_cells -hierarchical -filter {REF_NAME == LUT1 || REF_NAME == LUT2} -quiet]
set ro_count [llength $ro_cells]
puts "INFO: Found ${ro_count} LUT primitives in RO array (expected 96 = 16 ROs x 6 LUTs)"
if {$ro_count < 96} {
    puts "WARNING: Some RO LUTs may have been optimized away!"
    puts "WARNING: Check that DONT_TOUCH attributes are being respected."
}

# Synthesis reports
report_timing_summary -file ${RPT_DIR}/synth_timing.rpt
report_utilization     -file ${RPT_DIR}/synth_utilization.rpt
report_drc             -file ${RPT_DIR}/synth_drc.rpt

# Write checkpoint
write_checkpoint -force ${OUT_DIR}/post_synth.dcp

#------------------------------------------------------------------------------
# Opt Design
#------------------------------------------------------------------------------
puts "==== Running Optimization ===="
opt_design

#------------------------------------------------------------------------------
# Place Design
#------------------------------------------------------------------------------
puts "==== Running Placement ===="
place_design

# Post-placement reports
report_clock_utilization -file ${RPT_DIR}/place_clock_util.rpt
report_utilization       -file ${RPT_DIR}/place_utilization.rpt

# Write checkpoint
write_checkpoint -force ${OUT_DIR}/post_place.dcp

#------------------------------------------------------------------------------
# Route Design
#------------------------------------------------------------------------------
puts "==== Running Routing ===="
route_design

#------------------------------------------------------------------------------
# Post-implementation reports
#------------------------------------------------------------------------------
puts "==== Generating Reports ===="

report_timing_summary -file ${RPT_DIR}/impl_timing.rpt -max_paths 10
report_utilization     -file ${RPT_DIR}/impl_utilization.rpt
report_drc             -file ${RPT_DIR}/impl_drc.rpt
report_power           -file ${RPT_DIR}/impl_power.rpt
report_io              -file ${RPT_DIR}/impl_io.rpt

# Verify RO placement
set ro_placement_ok 1
for {set i 0} {$i < 16} {incr i} {
    set cells [get_cells -quiet gen_ro[$i].u_ro/lut_*]
    if {[llength $cells] == 0} {
        puts "WARNING: RO $i cells not found!"
        set ro_placement_ok 0
    } else {
        foreach c $cells {
            set loc [get_property LOC $c]
            set expected "SLICE_X0Y${i}"
            if {$loc ne $expected} {
                puts "WARNING: Cell $c placed at $loc, expected $expected"
                set ro_placement_ok 0
            }
        }
    }
}
if {$ro_placement_ok} {
    puts "INFO: All 16 ROs correctly placed in SLICE_X0Y0 through SLICE_X0Y15"
}

# Write checkpoint
write_checkpoint -force ${OUT_DIR}/post_route.dcp

#------------------------------------------------------------------------------
# Bitstream Generation
#------------------------------------------------------------------------------
puts "==== Generating Bitstream ===="
write_bitstream -force ${OUT_DIR}/${TOP}.bit

puts ""
puts "================================================================"
puts "  BUILD COMPLETE"
puts "  Bitstream: ${OUT_DIR}/${TOP}.bit"
puts "  Reports:   ${RPT_DIR}/"
puts "================================================================"
puts ""

# Print timing summary to console
set WNS [get_property SLACK [get_timing_paths -max_paths 1 -quiet]]
if {$WNS ne ""} {
    if {$WNS < 0} {
        puts "CRITICAL WARNING: Timing NOT met! WNS = ${WNS} ns"
    } else {
        puts "INFO: Timing met. WNS = ${WNS} ns"
    }
}
