# Standard Pmod JE
set_property PACKAGE_PIN V12 [get_ports enc_in]
#set_property PACKAGE_PIN W16 [get_ports irig_in]
set_property PACKAGE_PIN J15 [get_ports irig_in]
#set_property PACKAGE_PIN V13 [get_ports ex_sync]
#set_property PACKAGE_PIN U17 [get_ports fanout_0]
#set_property PACKAGE_PIN T17 [get_ports fanout_1]

set_property IOSTANDARD LVCMOS33 [get_ports enc_in]
#set_property IOSTANDARD LVCMOS33 [get_ports irig_in]
set_property IOSTANDARD LVCMOS33 [get_ports irig_in]
#set_property IOSTANDARD LVCMOS33 [get_ports ex_sync]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_0]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_1]

# High-speed port JB
#set_property PACKAGE_PIN V8 [get_ports fanout_jb[0]]
#set_property PACKAGE_PIN W8 [get_ports fanout_jb[1]]
#set_property PACKAGE_PIN U7 [get_ports fanout_jb[2]]
#set_property PACKAGE_PIN V7 [get_ports fanout_jb[3]]
#set_property PACKAGE_PIN Y7 [get_ports fanout_jb[4]]
#set_property PACKAGE_PIN Y6 [get_ports fanout_jb[5]]
#set_property PACKAGE_PIN V6 [get_ports fanout_jb[6]]
#set_property PACKAGE_PIN W6 [get_ports fanout_jb[7]]

#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[0]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[1]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[2]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[3]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[4]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[5]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[6]]
#set_property IOSTANDARD LVCMOS33 [get_ports fanout_jb[7]]



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_system_wrapper/system_i/sys_ps7/inst/FCLK_CLK0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/state[0]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/state[1]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 2 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_type[0]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_type[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 20 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[0]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[1]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[2]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[3]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[4]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[5]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[6]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[7]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[8]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[9]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[10]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[11]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[12]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[13]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[14]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[15]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[16]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[17]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[18]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pulse_width[19]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 8 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[0]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[1]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[2]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[3]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[4]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[5]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[6]} {i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/bit_position[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/falling]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/irig_buf]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pw_proc]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pw_proc_buf]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/pw_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list i_system_wrapper/system_i/axi_irig_reader/inst/decoder_inst/rising]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets u_ila_0_FCLK_CLK0]
