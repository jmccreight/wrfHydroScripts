#!/bin/bash

if [ -z $1 ]
then
    ## default if nothing passed
    confOpt=2
else 
    ## if the passed argument is not an integers
    if [[ ! $1 == [1-8] ]]
    then
        confOpt=2
    else 
        confOpt=$1
    fi
fi

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh
source $whsPath/sourceMe.sh

function errGrep { 
    grep -i 'error' $1 &> /dev/null; return $((!$?)) 
}

function cleanCompile {
    henv | egrep -i '(precip|nudging)'
    echo -e "\e[46mconfigure\e[0m"
    ./configure $confOpt &> /dev/null
    echo -e "\e[46mmake clean\e[0m"
    make clean &> /dev/null
    echo -e "\e[46mcompiling\e[0m"
    ./compile_offline_NoahMP.csh &> make.log
    errGrep make.log
    if [ ! $? -eq 0 ] 
    then
        echo -e "\e[31mThere were compilation issues, see make.log.\e[0m"
        exit 1
    fi
}

## check branch
cd ~/WRF_Hydro/wrf_hydro_model/trunk/NDHMS/
theBranch=`git branch | grep '*' | tr -d "*" | tr -d ' '`
echo $theBranch
export WRF_HYDRO=1
export HYDRO_REALTIME=0

if [ $theBranch == "daBranch" ] | [ $theBranch == "newDa" ] 
then
    echo "Compiling daBranch"

    echo
    echo -e "\e[7;47;39mnoNudging\e[0m"
    export PRECIP_DOUBLE=0
    export WRF_HYDRO_NUDGING=0
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.noNudging.exe
    ls -lah --color=auto Run/wrf_hydro.noNudging.exe

    echo
    echo -e "\e[7;47;39mnoNudging_doublePrecip\e[0m"
    export PRECIP_DOUBLE=1
    export WRF_HYDRO_NUDGING=0
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.noNudging_doublePrecip.exe
    ls -lah --color=auto Run/wrf_hydro.noNudging_doublePrecip.exe

    echo
    echo -e "\e[7;47;39mnudging\e[0m"
    export PRECIP_DOUBLE=0
    export WRF_HYDRO_NUDGING=1
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.nudging.exe    
    ls -lah --color=auto Run/wrf_hydro.nudging.exe

fi

if [ $theBranch == "master" ]
then
    echo "Compiling master"

    echo
    export PRECIP_DOUBLE=0
    export WRF_HYDRO_NUDGING=0
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.master.exe
    ls -lah --color=auto Run/wrf_hydro.master.exe
fi

exit 0
