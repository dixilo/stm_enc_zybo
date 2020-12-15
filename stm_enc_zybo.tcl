## Stimulator encoder reader
# Start the project
source ./util.tcl

# Modify this later
# This project is for ZyboZ7-20
set p_device "xc7z020clg400-1"
set p_board "digilentinc.com:zybo-z7-20:part0:1.0"

set sys_zynq 1
set project_name stm_enc_zybo
set lib_dirs ./ip

set project_system_dir "./$project_name.srcs/sources_1/bd/system"
create_project $project_name . -part $p_device -force
set_property board_part $p_board [current_project]

set_property ip_repo_paths $lib_dirs [current_fileset]
update_ip_catalog

add_files -norecurse -fileset sources_1 [glob ./src/*.v]
add_files -norecurse -fileset constrs_1 [glob ./src/*.xdc]


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

# DMA port
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells sys_ps7]

# AXI timestamp
create_bd_cell -type ip -vlnv [latest_ip axi_timestamp] axi_timestamp

# Interconnect
create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect
set_property -dict [list CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect]

# Reset generator
create_bd_cell -type ip -vlnv [latest_ip proc_sys_reset] sys_rstgen

# Encoder reader
create_bd_cell -type module -reference enc_reader enc_reader

# Concat for interrupt
create_bd_cell -type ip -vlnv [latest_ip xlconcat] xlconcat
set_property -dict [list CONFIG.NUM_PORTS {1}] [get_bd_cells xlconcat]

# DMA
create_bd_cell -type ip -vlnv [latest_ip axi_dma] axi_dma
set_property -dict [list \
    CONFIG.c_sg_include_stscntrl_strm {0} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {64} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_include_s2mm {1}] [get_bd_cells axi_dma]

create_bd_cell -type ip -vlnv [latest_ip smartconnect] axi_smc
set_property -dict [list \
    CONFIG.NUM_MI {1}\
    CONFIG.NUM_SI {2}] [get_bd_cells axi_smc]

# Connection
## sys_clk: 50 MHz
create_bd_net sys_clk
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_ps7/FCLK_CLK0]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_ps7/M_AXI_GP0_ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_ps7/S_AXI_HP0_ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_rstgen/slowest_sync_clk]

connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_interconnect/ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_interconnect/S00_ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_smc/aclk]

connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins enc_reader/clk]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_dma/m_axi_sg_aclk]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_dma/m_axi_s2mm_aclk]

## reset
create_bd_net sys_resetn
connect_bd_net [get_bd_pins sys_ps7/FCLK_RESET0_N] [get_bd_pins sys_rstgen/ext_reset_in]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins sys_rstgen/peripheral_aresetn]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins axi_interconnect/S00_ARESETN]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins enc_reader/aresetn]

## interconnect reset
create_bd_net sys_ic_resetn
connect_bd_net -net [get_bd_nets sys_ic_resetn] [get_bd_pins sys_rstgen/interconnect_aresetn]
connect_bd_net -net [get_bd_nets sys_ic_resetn] [get_bd_pins axi_interconnect/ARESETN]
connect_bd_net -net [get_bd_nets sys_ic_resetn] [get_bd_pins axi_smc/aresetn]

## counter
create_bd_net counter
connect_bd_net -net [get_bd_nets counter] [get_bd_pins axi_timestamp/counter_out]
connect_bd_net -net [get_bd_nets counter] [get_bd_pins enc_reader/counter_in]

connect_bd_intf_net [get_bd_intf_pins enc_reader/m_axis] [get_bd_intf_pins axi_dma/S_AXIS_S2MM]


## AXI bus
connect_bd_intf_net [get_bd_intf_pins sys_ps7/M_AXI_GP0] [get_bd_intf_pins axi_interconnect/S00_AXI]
axi_connect 0x43c00000 axi_timestamp
axi_connect 0x40400000 axi_dma

## smart connect
connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_SG] [get_bd_intf_pins axi_smc/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_dma/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins sys_ps7/S_AXI_HP0]
assign_bd_address [get_bd_addr_segs {sys_ps7/S_AXI_HP0/HP0_DDR_LOWOCM }]

## Interrupt
connect_bd_net [get_bd_pins axi_dma/s2mm_introut] [get_bd_pins xlconcat/In0]
connect_bd_net [get_bd_pins xlconcat/dout] [get_bd_pins sys_ps7/IRQ_F2P]

# Interface pin
make_bd_pins_external  -name enc_in [get_bd_pins enc_reader/enc_in]

save_bd_design
validate_bd_design

set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
make_wrapper -files [get_files $project_system_dir/system.bd] -top

import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
set_property top system_top [current_fileset]


# Synthesize
launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_timing_summary -file timing_synth.log

# Implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1
report_timing_summary -file timing_impl.log

# Make .sdk folder
# file copy -force $project_name.runs/impl_1/system_top.sysdef noos/system_top.hdf
