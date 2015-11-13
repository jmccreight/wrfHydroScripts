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

function henv {
    printenv | egrep -i "(HYDRO|NUDG|PRECIP|CHAN_CONN|^NETCDF|^LDFLAGS|^ifort|REALTIME)" | egrep -v PWD
}

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


return 0
