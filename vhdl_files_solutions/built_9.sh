#!/bin/bash

ghdl -a modarithn.vhd
ghdl -a tb_modarithn.vhd
ghdl -e tb_modarithn
ghdl -r tb_modarithn --wave=modarithn.ghw --stop-time=100000ns
