#!/bin/bash

ghdl -a add4.vhd
ghdl -a tb_add4.vhd
ghdl -e tb_add4
ghdl -r tb_add4 --wave=add4.ghw --stop-time=100000ns
