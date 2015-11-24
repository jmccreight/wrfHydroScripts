#!/bin/bash

whmPath=`grep "wrf_hydro_model" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
cd $whmPath/trunk/NDHMS/
echo $whmPath :: $@


grep -s $@ */*.inc

grep -s $@ */*.F
grep -s $@ */*/*.F
grep -s $@ */*/*/*.F
grep -s $@ */*/*/*/*.F

grep -s $@ */Makefile
grep -s $@ */*/Makefile
grep -s $@ */*/*/Makefile
grep -s $@ */*/*/*/Makefile

grep -s $@ arc/*

exit 0
