# Build template customised for PROJ

set common_files [list ../../src/tec1.vhd \
    ../../A-Z80/cpu/bus/inc_dec_2bit.v \
    ../../A-Z80/cpu/bus/inc_dec.v \
    ../../A-Z80/cpu/bus/address_mux.v \
    ../../A-Z80/cpu/bus/address_pins.v \
    ../../A-Z80/cpu/bus/bus_switch.v \
    ../../A-Z80/cpu/bus/bus_control.v \
    ../../A-Z80/cpu/bus/address_latch.v \
    ../../A-Z80/cpu/bus/data_pins.v \
    ../../A-Z80/cpu/bus/data_switch_mask.v \
    ../../A-Z80/cpu/bus/data_switch.v \
    ../../A-Z80/cpu/bus/control_pins_n.v \
    ../../A-Z80/cpu/control/sequencer.v \
    ../../A-Z80/cpu/control/pin_control.v \
    ../../A-Z80/cpu/control/execute.v \
    ../../A-Z80/cpu/control/resets.v \
    ../../A-Z80/cpu/control/ir.v \
    ../../A-Z80/cpu/control/memory_ifc.v \
    ../../A-Z80/cpu/control/interrupts.v \
    ../../A-Z80/cpu/control/decode_state.v \
    ../../A-Z80/cpu/control/clk_delay.v \
    ../../A-Z80/cpu/control/pla_decode.v \
    ../../A-Z80/cpu/alu/alu_bit_select.v \
    ../../A-Z80/cpu/alu/alu_prep_daa.v \
    ../../A-Z80/cpu/alu/alu_mux_2z.v \
    ../../A-Z80/cpu/alu/alu_mux_8.v \
    ../../A-Z80/cpu/alu/alu_mux_3z.v \
    ../../A-Z80/cpu/alu/alu_mux_2.v \
    ../../A-Z80/cpu/alu/alu_control.v \
    ../../A-Z80/cpu/alu/alu.v \
    ../../A-Z80/cpu/alu/alu_select.v \
    ../../A-Z80/cpu/alu/alu_flags.v \
    ../../A-Z80/cpu/alu/alu_slice.v \
    ../../A-Z80/cpu/alu/alu_mux_4.v \
    ../../A-Z80/cpu/alu/alu_shifter_core.v \
    ../../A-Z80/cpu/alu/alu_core.v \
    ../../A-Z80/cpu/toplevel/z80_top_direct_n.v \
    ../../A-Z80/cpu/registers/reg_latch.v \
    ../../A-Z80/cpu/registers/reg_file.v \
    ../../A-Z80/cpu/registers/reg_control.v]

create_project -force -part PROJPART PROJNAME

# Common files
add_files $common_files

# Project specific files
add_files [list PROJFILES]
set_property top top [current_fileset]
set monitor_filename ../../common/mon2.hex
set util_filename ../../common/util.hex
set monitor_fullpath [pwd]/$monitor_filename
set util_fullpath [pwd]/$util_filename
set_property generic [list g_monitor_filename=$monitor_fullpath g_util_filename=$util_fullpath] [current_fileset]
add_files PROJNAME.xdc

# Synth
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

launch_runs impl_1 -jobs 4 -to_step route_design
wait_on_run impl_1
set directory [get_property DIRECTORY [get_runs impl_1]]
open_checkpoint $directory/top_routed.dcp
write_bitstream -force -bin_file PROJNAME.bit
exit

