#!/bin/bash

searchStr=("$@")

whmPath=`grep "wrf_hydro_model" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
cd $whmPath/trunk/NDHMS/
echo $whmPath :: "${searchStr[@]}"


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
