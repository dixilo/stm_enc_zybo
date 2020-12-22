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

# AXI timestamp
create_bd_cell -type ip -vlnv [latest_ip axi_timestamp] axi_timestamp

# Interconnect
create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect
set_property -dict [list CONFIG.NUM_MI {2}] [get_bd_cells axi_interconnect]

# Reset generator
create_bd_cell -type ip -vlnv [latest_ip proc_sys_reset] sys_rstgen

# Encoder reader
create_bd_cell -type module -reference enc_reader enc_reader

# Stream data fifo
create_bd_cell -type ip -vlnv [latest_ip axis_data_fifo] axis_data_fifo

# Formatter
create_bd_cell -type module -reference enc_packet enc_packet


# Concat for interrupt
create_bd_cell -type ip -vlnv [latest_ip xlconcat] xlconcat
set_property -dict [list CONFIG.NUM_PORTS {1}] [get_bd_cells xlconcat]

# AXI GPIO for test
create_bd_cell -type ip -vlnv [latest_ip axi_gpio] axi_gpio
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {1} \
    CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells axi_gpio]

create_bd_cell -type ip -vlnv [latest_ip util_reduced_logic] util_reduced_logic
set_property -dict [list \
    CONFIG.C_SIZE {2} \
    CONFIG.C_OPERATION {or}] [get_bd_cells util_reduced_logic]

create_bd_cell -type ip -vlnv [latest_ip xlconcat] xlconcat_test

# AXI-Stream FIFO
create_bd_cell -type ip -vlnv [latest_ip axi_fifo_mm_s] axi_fifo_mm_s
set_property -dict [list \
    CONFIG.C_USE_TX_DATA {0} \
    CONFIG.C_USE_TX_CTRL {0} \
    CONFIG.C_HAS_AXIS_TUSER {true} \
    CONFIG.C_RX_FIFO_DEPTH {4096} \
    CONFIG.C_RX_FIFO_PF_THRESHOLD {4091} \
    CONFIG.C_RX_FIFO_PE_THRESHOLD {5} \
    CONFIG.C_AXIS_TUSER_WIDTH {4}] [get_bd_cells axi_fifo_mm_s]

# Connection
## sys_clk: 50 MHz
create_bd_net sys_clk
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_ps7/FCLK_CLK0]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_ps7/M_AXI_GP0_ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins sys_rstgen/slowest_sync_clk]

connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_interconnect/ACLK]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axi_interconnect/S00_ACLK]

connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins enc_reader/clk]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins axis_data_fifo/s_axis_aclk]
connect_bd_net -net [get_bd_nets sys_clk] [get_bd_pins enc_packet/clk]


## reset
create_bd_net sys_resetn
connect_bd_net [get_bd_pins sys_ps7/FCLK_RESET0_N] [get_bd_pins sys_rstgen/ext_reset_in]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins sys_rstgen/peripheral_aresetn]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins axi_interconnect/S00_ARESETN]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins enc_reader/aresetn]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins axis_data_fifo/s_axis_aresetn]
connect_bd_net -net [get_bd_nets sys_resetn] [get_bd_pins enc_packet/aresetn]


## interconnect reset
create_bd_net sys_ic_resetn
connect_bd_net -net [get_bd_nets sys_ic_resetn] [get_bd_pins sys_rstgen/interconnect_aresetn]
connect_bd_net -net [get_bd_nets sys_ic_resetn] [get_bd_pins axi_interconnect/ARESETN]


## counter
create_bd_net counter
connect_bd_net -net [get_bd_nets counter] [get_bd_pins axi_timestamp/counter_out]
connect_bd_net -net [get_bd_nets counter] [get_bd_pins enc_reader/counter_in]


## AXI bus
connect_bd_intf_net [get_bd_intf_pins sys_ps7/M_AXI_GP0] [get_bd_intf_pins axi_interconnect/S00_AXI]
axi_connect 0x43c00000 axi_timestamp
axi_connect 0x43c10000 axi_fifo_mm_s
axi_connect 0x41200000 axi_gpio

## AXIS connection
connect_bd_intf_net [get_bd_intf_pins enc_reader/m_axis] [get_bd_intf_pins axis_data_fifo/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo/M_AXIS] [get_bd_intf_pins enc_packet/s_axis]
connect_bd_intf_net [get_bd_intf_pins enc_packet/m_axis] [get_bd_intf_pins axi_fifo_mm_s/AXI_STR_RXD]

## Interrupt
connect_bd_net [get_bd_pins xlconcat/dout] [get_bd_pins sys_ps7/IRQ_F2P]
connect_bd_net [get_bd_pins axi_fifo_mm_s/interrupt] [get_bd_pins xlconcat/In0]

connect_bd_net [get_bd_pins axi_gpio/gpio_io_o] [get_bd_pins xlconcat_test/In1]
connect_bd_net [get_bd_pins util_reduced_logic/Res] [get_bd_pins enc_reader/enc_in]
connect_bd_net [get_bd_pins xlconcat_test/dout] [get_bd_pins util_reduced_logic/Op1]

# Interface pin
make_bd_pins_external  -name enc_in [get_bd_pins xlconcat_test/In0]


save_bd_design
validate_bd_design

set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
make_wrapper -files [get_files $project_system_dir/system.bd] -top

import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
set_property top system_top [current_fileset]


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

# Make .sdk folder
# file copy -force $project_name.runs/impl_1/system_top.sysdef noos/system_top.hdf
