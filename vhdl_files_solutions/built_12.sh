#!/bin/bash

ghdl -a ecc_base.vhd
ghdl -a tb_ecc_base.vhd
ghdl -e tb_ecc_base
ghdl -r tb_ecc_base --wave=ecc_base.ghw --stop-time=100000ns
