#!/bin/bash

ghdl -a modmultn.vhd
ghdl -a tb_modmultn.vhd
ghdl -e tb_modmultn
ghdl -r tb_modmultn --wave=modmultn.ghw --stop-time=100000ns
