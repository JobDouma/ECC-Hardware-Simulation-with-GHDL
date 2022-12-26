#!/bin/bash

ghdl -a ram_double.vhd
ghdl -a tb_ram_double.vhd
ghdl -e tb_ram_double
ghdl -r tb_ram_double --wave=ram_double.ghw --stop-time=100000ns
