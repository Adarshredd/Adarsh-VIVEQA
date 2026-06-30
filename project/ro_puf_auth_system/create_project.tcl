#==============================================================================
# Vivado Project Mode Setup Script
# Ring Oscillator PUF Authentication System
# Board: AT-STLN-ARTIX7-001 (XC7A35T-FTG256-1)
#
# Usage (creates a Vivado project for GUI use):
#   vivado -mode batch -source create_project.tcl
#   Then open: vivado_project/ro_puf_auth.xpr
#
# Or from Vivado Tcl Console:
#   cd <path_to_project_root>
#   source create_project.tcl
#==============================================================================

set PRJ_DIR     [file dirname [info script]]
set PRJ_NAME    ro_puf_auth
set PRJ_PATH    ${PRJ_DIR}/vivado_project
set SRC_DIR     ${PRJ_DIR}/src
set XDC_DIR     ${PRJ_DIR}/constraints
set SIM_DIR     ${PRJ_DIR}/sim
set PART        xc7a35tftg256-1

#------------------------------------------------------------------------------
# Create project
#------------------------------------------------------------------------------
create_project ${PRJ_NAME} ${PRJ_PATH} -part ${PART} -force

#------------------------------------------------------------------------------
# Add design sources
#------------------------------------------------------------------------------
add_files -norecurse [glob ${SRC_DIR}/*.v]
set_property top top [current_fileset]

#------------------------------------------------------------------------------
# Add constraints
#------------------------------------------------------------------------------
add_files -fileset constrs_1 -norecurse ${XDC_DIR}/top.xdc

#------------------------------------------------------------------------------
# Add simulation sources
#------------------------------------------------------------------------------
add_files -fileset sim_1 -norecurse ${SIM_DIR}/tb_top.v
set_property top tb_top [get_filesets sim_1]

#------------------------------------------------------------------------------
# Set synthesis strategy
#------------------------------------------------------------------------------
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]

# Ensure ring oscillators are not optimized
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} \
    -value {-keep_equivalent_registers} \
    -objects [get_runs synth_1]

#------------------------------------------------------------------------------
# Set implementation strategy
#------------------------------------------------------------------------------
set_property strategy Performance_Explore [get_runs impl_1]

puts ""
puts "================================================================"
puts "  Project created: ${PRJ_PATH}/${PRJ_NAME}.xpr"
puts "  Open in Vivado GUI or run:"
puts "    launch_runs synth_1 -jobs 4"
puts "    wait_on_run synth_1"
puts "    launch_runs impl_1 -to_step write_bitstream -jobs 4"
puts "    wait_on_run impl_1"
puts "================================================================"
puts ""
