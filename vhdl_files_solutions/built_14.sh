#!/bin/bash

ghdl -a ecc_mont.vhd
ghdl -a tb_ecc_mont.vhd
ghdl -e tb_ecc_mont
ghdl -r tb_ecc_mont --fst=ecc_mont.fst --stop-time=21000000ns --read-wave-opt=export.txt
