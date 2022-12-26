#!/bin/bash

ghdl -a modaddn_mult.vhd
ghdl -a tb_modaddn_mult.vhd
ghdl -e tb_modaddn_mult
ghdl -r tb_modaddn_mult --wave=modaddn_mult.ghw --stop-time=100000ns
