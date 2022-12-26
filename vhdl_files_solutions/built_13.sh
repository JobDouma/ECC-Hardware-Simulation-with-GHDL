#!/bin/bash

ghdl -a ecc_add_double.vhd
ghdl -a tb_ecc_add_double_nist.vhd
ghdl -e tb_ecc_add_double_nist
ghdl -r tb_ecc_add_double_nist --wave=ecc_add_double_nist.ghw --stop-time=100000ns
