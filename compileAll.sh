#!/bin/bash

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh
source $whsPath/sourceMe.sh

## always offline WRF HYDRO
export WRF_HYDRO=1

## check branch
whmPath=`grep "wrf_hydro_model" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
cd $whmPath/trunk/NDHMS/
theBranch=`git branch | grep '*' | tr -d "*" | tr -d ' ' | stripColors`
echo "On Branch: $theBranch"

## 111=RND

#011 = 0ND
export HYDRO_REALTIME=0
export WRF_HYDRO_NUDGING=1
export HYDRO_D=1
compileTag -c

#110 = RN0
export HYDRO_REALTIME=1
export WRF_HYDRO_NUDGING=1
export HYDRO_D=0
compileTag -c

#111 = RND
export HYDRO_REALTIME=1
export WRF_HYDRO_NUDGING=1
export HYDRO_D=1
compileTag -c

#100 R00
export HYDRO_REALTIME=1
export WRF_HYDRO_NUDGING=0
export HYDRO_D=0
compileTag -c

#101
export HYDRO_REALTIME=1
export WRF_HYDRO_NUDGING=0
export HYDRO_D=1
compileTag -c

#001
export HYDRO_REALTIME=0
export WRF_HYDRO_NUDGING=0
export HYDRO_D=1
compileTag -c


exit 1
