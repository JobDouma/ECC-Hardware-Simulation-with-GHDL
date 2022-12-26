#!/bin/bash

ghdl -a ecc_mont_opt.vhd
ghdl -a tb_ecc_mont_opt.vhd
ghdl -e tb_ecc_mont_opt
#ghdl -r tb_ecc_mont_opt --wave=ecc_mont_opt.ghw --stop-time=200000ns
#ghdl -r tb_ecc_mont --fst=ecc_mont.ghw --stop-time=30000000ns
ghdl -r tb_ecc_mont_opt --fst=ecc_mont_opt.fst --stop-time=14000000ns --read-wave-opt=export2.txt
#ghdl -r tb_ecc_mont_opt --fst=ecc_mont_opt.fst --stop-time=30000ns --read-wave-opt=export2.txt


