# script
set ip_name "axi_irig_reader"

## Device setting (KCU105)
set p_device "xc7z020clg400-1"
set p_board "digilentinc.com:zybo-z7-20:part0:1.0"

create_project $ip_name . -force -part $p_device
set_property board_part $p_board [current_project]

#source ./util.tcl

# file
set proj_fileset [get_filesets sources_1]
add_files -norecurse -scan_for_includes -fileset $proj_fileset [list \
    axi_irig_reader.v\
    b002_decoder.v
]
set_property "top" "axi_irig_reader" $proj_fileset

# ip package

ipx::package_project -root_dir . -vendor kuhep -library user -taxonomy /kuhep
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {kuhep} [ipx::current_core]
ipx::save_core [ipx::current_core]

update_compile_order -fileset sources_1
ipx::save_core [ipx::current_core]
