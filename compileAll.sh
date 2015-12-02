#!/bin/bash
theHost=`hostname`

if [ -z $1 ]
then
    ## default if nothing passed
    confOpt=2
    ## YELLOWSTONE
    if [[ $theHost == *"yslogin"* ]]; then confOpt=8; fi
else 
    ## if the passed argument is not an integer
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
    echo -e "\e[46mconfigure $confOpt\e[0m"
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
whmPath=`grep "wrf_hydro_model" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
cd $whmPath/trunk/NDHMS/

theBranch=`git branch | grep '*' | tr -d "*" | tr -d ' ' | stripColors`
echo "On Branch: $theBranch"

export WRF_HYDRO=1
export HYDRO_REALTIME=0
echo 
echo -e "Relevant environment variables:"
henv
echo 

nudgingBranchSet='master tmpNudging'
if isInSet $theBranch "$nudgingBranchSet"
then

    branchTag=''
    if [[ ! $theBranch == 'nudging' ]]; then branchTag="${theBranch}."; fi

    echo
    echo -e "\e[7;47;39mnoNudging\e[0m"
    export PRECIP_DOUBLE=0
    export WRF_HYDRO_NUDGING=0
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.noNudging.${branchTag}exe
    ls -lah --color=auto Run/wrf_hydro.noNudging.${branchTag}exe

    echo
    echo -e "\e[7;47;39mnoNudging_doublePrecip\e[0m"
    export PRECIP_DOUBLE=1
    export WRF_HYDRO_NUDGING=0
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.noNudging_doublePrecip.${branchTag}exe
    ls -lah --color=auto Run/wrf_hydro.noNudging_doublePrecip.${branchTag}exe

    echo
    echo -e "\e[7;47;39mnudging\e[0m"
    export PRECIP_DOUBLE=0
    export WRF_HYDRO_NUDGING=1
    cleanCompile
    cp Run/wrf_hydro.exe Run/wrf_hydro.nudging.${branchTag}exe    
    ls -lah --color=auto Run/wrf_hydro.nudging.${branchTag}exe
    exit 0
fi

#if [[ $theBranch == "master" ]]
#then
#    echo "Compiling master"
#    echo
#    export PRECIP_DOUBLE=0
#    export WRF_HYDRO_NUDGING=0
#    cleanCompile
#    cp Run/wrf_hydro.exe Run/wrf_hydro.master.exe
#    ls -lah --color=auto Run/wrf_hydro.master.exe
#    exit 0
#fi

exit 1
