#!/bin/bash

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '`
source $whsPath/helpers.sh
source $whsPath/sourceMe.sh

clean=1
while getopts ":c" opt; do
    case $opt in
        c)
            clean=0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done
shift "$((OPTIND-1))" # Shift off the options and optional

## what is the integer argument to ./configure ?
## hydro vs yellowstone
theHost=`hostname`
## HYDRO
if [[ $theHost == *"hydro-c1"* ]]; then confOpt=2; fi ## pgfortran
## YELLOWSTONE
if [[ $theHost == *"yslogin"* ]]; then confOpt=8; fi ## intel

echo -e "Relevant environment variables:"
henv | grep '=1' | grep -v "WRF_HYDRO=1"

## configure
echo -e "\e[46mconfigure $confOpt\e[0m"
./configure $confOpt &> /dev/null

## make clean or just make?
if [ $clean -eq 0 ] 
then
    echo -e "\e[46mmake clean\e[0m"
    make clean &> /dev/null
    echo -e "\e[46mcompiling\e[0m"
    ./compile_offline_NoahMP.csh &> make.log
else 
    makeCheck &> make.log
fi

## was the compilation successful?
errGrep make.log
if [ ! $? -eq 0 ] 
then
    echo -e "\e[31mThere were compilation issues, see make.log.\e[0m"
    exit 1
fi

## git-based tagging
## Master is not tagged with branch name
##   if on master with no changes since commit
##     wrf_hydro.sha.ENVVAR1-ENVVAR2.exe
##   if on master with changes since commit
##     wrf_hydro.sha+.ENVVAR1-ENVVAR2.exe
## Other branches include the branch name
##   if on branch with no changes since commit
##     wrf_hydro.sha.ENVVAR1-ENVVAR2.exe
##   if on branch with changes since commit
##     wrf_hydro.sha+.ENVVAR1-ENVVAR2.exe

theSha=`git rev-parse --short HEAD`
unCommittedChanges=`git diff-index --quiet HEAD --`
if [ $? -ne 0 ]; then theSha=${theSha}+ ; fi
theSha=${theSha}.

whmPath=`grep "wrf_hydro_model" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
cd $whmPath/trunk/NDHMS/
theBranch=`git branch | grep '*' | tr -d "*" | tr -d ' ' | stripColors`

if [ $theBranch == 'master' ]; then theBranch=''; else theBranch=${theBranch}.;fi
    # the env vars
envVars=`henv | grep '=1' | grep -v 'WRF_HYDRO=1' | cut -d '=' -f1 | tr '\n' '-'`
lEnvVars=${#envVars}
envVars=`echo $envVars | cut -c-$((${lEnvVars}-1))`
    #echo $envVars

tag=${theSha}${theBranch}${envVars}
    #echo $tag

cp Run/wrf_hydro.exe Run/wrf_hydro.${tag}.exe
ls -lah --color=auto Run/wrf_hydro.${tag}.exe

exit 0

