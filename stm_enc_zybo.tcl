## Stimulator encoder reader
# Start the project
source ./util.tcl

# Modify this later
# This project is for ZyboZ7-20
set p_device "xc7z020clg400-1"
set p_board "digilentinc.com:zybo-z7-20:part0:1.0"

set sys_zynq 1
set project_name stm_enc_zybo
set lib_dirs ../

set project_system_dir "./$project_name.srcs/sources_1/bd/system"
create_project $project_name . -part $p_device -force
set_property board_part $p_board [current_project]

set_property ip_repo_paths $lib_dirs [current_fileset]
update_ip_catalog

create_bd_design "system"

############## Zynq
create_bd_cell -type ip -vlnv [get_ipdefs "*processing_system7*"] sys_ps7

# Board automation
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
-config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  \
[get_bd_cells sys_ps7]

# enable interrupt
set_property -dict [list \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
    CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1}] \
    [get_bd_cells sys_ps7]

set_property -dict [list \
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {0}\
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {0}\
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0}\
    CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0}] \
[get_bd_cells sys_ps7]

# Counter


# Interface pin
#make_bd_pins_external  -name rot_a [get_bd_pins axi_gb_rotary/rot_a]
#make_bd_pins_external  -name rot_b [get_bd_pins axi_gb_rotary/rot_b]
#make_bd_pins_external  -name rot_z [get_bd_pins axi_gb_rotary/rot_z]
#make_bd_pins_external  -name ex_sync [get_bd_pins axi_gb_rotary/ex_sync]

#create_bd_port -dir O -type clk f_clk
#connect_bd_net [get_bd_pins /sys_ps7/FCLK_CLK0] [get_bd_ports f_clk]
#create_bd_port -dir O -type rst f_rstn
#connect_bd_net [get_bd_ports f_rstn] [get_bd_pins rst_sys_ps7_50M/peripheral_aresetn]


save_bd_design
validate_bd_design

#set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
#generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
#make_wrapper -files [get_files $project_system_dir/system.bd] -top


#import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
#add_files -norecurse -fileset sources_1 [list \
#    "el_encoder.xdc" \
#    "system_top.v" \
#    "sync_splitter.v"]
#set_property top system_top [current_fileset]


# Synthesize
# launch_runs synth_1
# wait_on_run synth_1
# open_run synth_1
# report_timing_summary -file timing_synth.log

# # Implementation
# launch_runs impl_1 -to_step write_bitstream
# wait_on_run impl_1
# open_run impl_1
# report_timing_summary -file timing_impl.log

# # Make .sdk folder
# file copy -force $project_name.runs/impl_1/system_top.sysdef noos/system_top.hdf
