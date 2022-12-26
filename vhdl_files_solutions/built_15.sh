#!/bin/bash

ghdl -a ecc_mont_opt.vhd
ghdl -a tb_ecc_mont_opt.vhd
ghdl -e tb_ecc_mont_opt
ghdl -r tb_ecc_mont_opt --fst=ecc_mont_opt.fst --stop-time=14000000ns --read-wave-opt=export2.txt


