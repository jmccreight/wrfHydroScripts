#!/bin/bash

## Purpose: 
## 1) extract a test case using linkToTestCase
## 2) Standardize the result
## 

## Arguments: exactly those of link to test case
whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh


## Let linkToTestCase handle the errors
$whsPath/linkToTestCase.sh "$@"

## Now parse the result into the standard format
###################################
## OPTIONS: dont use them, just shift them off.
while getopts ":fpuncdo" opt; do
  case $opt in
  esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

runDir=$1
myTestDir=`getAbsPath $3`
echo $runDir
echo $myTestDir

cd $myTestDir
mkdir PARAMS

mv $runDir/*TBL PARAMS/.

mv $runDir/*namelist* .

rmdir $runDir

echo -e "\e[31mDoing much more gets really tricky.... do it by hand.\e[0m"
echo -e "\e[31mDont forget to edit the namelists by hand.\e[0m"

exit 0




