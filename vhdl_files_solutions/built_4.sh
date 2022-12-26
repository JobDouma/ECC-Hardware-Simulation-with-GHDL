#!/bin/bash

ghdl -a modaddn.vhd
ghdl -a tb_modaddn.vhd
ghdl -e tb_modaddn
ghdl -r tb_modaddn --wave=modaddn.ghw --stop-time=100000ns
