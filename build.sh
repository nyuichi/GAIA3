#!/bin/bash
cd ~/.ise_projects/gaia
source /opt/Xilinx/14.7/ISE_DS/settings64.sh
xst -intstyle ise -ifn "/home/yuichi/.ise_projects/gaia/top.xst" -ofn "/home/yuichi/.ise_projects/gaia/top.syr" 
ngdbuild -intstyle ise -dd _ngo -aul -aut -nt timestamp -uc /home/yuichi/workspace/GAIA3/top.ucf -p xc5vlx50t-ff1136-1 top.ngc top.ngd  
map -intstyle ise -p xc5vlx50t-ff1136-1 -w -logic_opt off -ol high -t 1 -register_duplication off -global_opt off -mt off -cm area -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf 
par -w -intstyle ise -ol high -mt off top_map.ncd top.ncd top.pcf 
bitgen -intstyle ise -f top.ut top.ncd 
