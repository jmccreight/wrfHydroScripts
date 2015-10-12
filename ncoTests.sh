#!/bin/bash

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh

ncosPath=`grep "ncoScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $ncosPath/ncFilters.sh

function testFailed {
    testStr=''
    if [ ! -z $1 ]; then testStr=": $1"; fi
    echo -e "\e[31mTest failed${testStr}.\e[0m"
}


## UNARY TESTS
function testNaOutput {
    ## Arguments: 
    ## 1: the file to check
    if [ -z $1 ]
    then 
        echo -e "\e[31mtestNaOutput requires one argument: the file to test\e[0m"
        return 1
    fi
    f1=`getAbsPath $1`
    checkExist $f1 || return 1
    echo -e "\e[34mncVarNa $f1\e[0m"
    result=`ncVarNa $f1`
    resultRet=$?
    echo "$result"
    return $resultRet
}


## BINARY TESTS

function testDiffOutput {
    ## Arguments  1-2?
    ## 1: path/file.nc
    ## 1: path/file.nc
    if [[ -z $1 ]] | [[ -z $2 ]]
    then 
        echo -e "\e[31mTwo files required by testDiffOutput in nocTests.sh\e[0m"
        return 1
    fi
    f1=`getAbsPath $1`
    f2=`getAbsPath $2`
    checkExist $f1 || return 1
    checkExist $f2 || return 1
    echo -e "\e[34mncVarDiff $f1 $f2\e[0m"
    diffOut=`ncVarDiff $f1 $f2 2>&1`
    diffRet=$?
    echo "$diffOut"
    return $diffRet
 }


