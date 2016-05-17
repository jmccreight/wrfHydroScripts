#!/bin/bash

## source this file in your .bashrc for universal access to the scripts via function calls:
## source pathTo/wrfHydroScripts/sourceMe.sh

## where do you keep your scripts? This config file is required to know.
configFile=~/.wrfHydroScripts
if [[ ! -e $configFile ]]
then
    echo -e \
        "\e[31mPlease create a ~/.wrfHydroScripts file based on the example in the repository.\e[0m"
    return 1
fi

whsPath=`grep "wrfHydroScripts" $configFile | cut -d '=' -f2 | tr -d ' '` 

function lrl { ## "list readlink"
    for i in "$@"
    do
        echo "$i ->"
        ls -lahd `readlink -e $i`
    done
}

function plotFrxst {
    $whsPath/plotFrxst.sh $@
}

function cleanup {
    $whsPath/cleanup.sh $@
}

function cleanRun {
    $whsPath/cleanRun.sh $@
}

function linkToTestCase {
    $whsPath/linkToTestCase.sh $@
}

function standardizeTestCase {
    $whsPath/standardizeTestCase.sh $@
}

function getTestFiles {
    $whsPath/getTestFiles.sh $@
}

function testNLast {
    $whsPath/testNLast.sh $@
}

function makeCheck {
    $whsPath/makeCheck.sh $@
}

function qCleanRun {
    $whsPath/qCleanRun.sh $@
}

function bCleanRun {
    $whsPath/bCleanRun.sh $@
}

function compileAll {
    "$whsPath"/compileAll.sh $@
}

function regTest {
    $whsPath/regTest.sh $@
}

function hgrep {
    $whsPath/hgrep.sh $@
}

function compileTag {
    $whsPath/compileTag.sh $@
}

function geyser {
    $whsPath/geyser.sh $@
}

function henv {
    printenv | egrep -i "(HYDRO|NUDG|PRECIP|CHAN_CONN|^NETCDF|REALTIME|SOIL|WRFIO)" | egrep -v PWD
}

function setHenv {
    local R N D P O S
    R=0; N=0; D=0; P=0; O=0; S=0
    local OPTIND
    while getopts ":RNDPOSL" opt; do
        case $opt in
            R)  R=1;;
            N)  N=1;;
            D)  D=1;;
            P)  P=1;;
            O)  O=1;;
            S)  S=1;;
            L)  L=1;;
            \?) echo "Invalid option: -$OPTARG";;
        esac
    done
    shift "$((OPTIND-1))" # Shift off the options and optional

    export HYDRO_REALTIME=0
    export WRF_HYDRO_NUDGING=0
    export HYDRO_D=0
    export PRECIP_DOUBLE=0
    export OUTPUT_CHAN_CONN=0
    export WRF_HYDRO=1
    export SPATIAL_SOIL=0
    export WRFIO_NCD_LARGE_FILE_SUPPORT=0

    if [ $R -eq 1 ]; then export HYDRO_REALTIME=1; fi
    if [ $N -eq 1 ]; then export WRF_HYDRO_NUDGING=1; fi
    if [ $D -eq 1 ]; then export HYDRO_D=1; fi
    if [ $P -eq 1 ]; then export PRECIP_DOUBLE=1; fi
    if [ $O -eq 1 ]; then export OUTPUT_CHAN_CONN=1; fi
    if [ $S -eq 1 ]; then export SPATIAL_SOIL=1; fi
    if [ $L -eq 1 ]; then export WRFIO_NCD_LARGE_FILE_SUPPORT=1; fi
    henv
}

function checkAllocations {
    $whsPath/checkAllocations.sh $@
}

function getScratchDates {
    $whsPath/getScratchDates.sh $@
}

function r2Geyser {
    $whsPath/r2Geyser.sh $@
}


return 0
