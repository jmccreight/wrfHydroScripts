#!/bin/bash

searchStr=("$@")

echo "${searchStr[@]}"

#cd ~/WRF_Hydro/ndhms.beta2me/trunk/NDHMS/
cd ~/WRF_Hydro/wrf_hydro_model/trunk/NDHMS/

egrep -s "${searchStr[@]}" */*.inc

egrep -s "${searchStr[@]}" */*.F
egrep -s "${searchStr[@]}" */*/*.F
egrep -s "${searchStr[@]}" */*/*/*.F
egrep -s "${searchStr[@]}" */*/*/*/*.F

egrep -s "${searchStr[@]}" */Makefile
egrep -s "${searchStr[@]}" */*/Makefile
egrep -s "${searchStr[@]}" */*/*/Makefile
egrep -s "${searchStr[@]}" */*/*/*/Makefile


exit 0
