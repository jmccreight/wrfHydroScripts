#!/bin/bash
## Purpose: Compare the output from two WRF-Hydro runs for differences. 

help="
Arguments
1) first argument is how many of each file to compare going backwards from the last one.
2) OPTIONAL second argument is the path to the verification data. 
3) OPTIONAL but need 2 if you use 3: third argument is the path to your output, if missing 
            assuming you're in the run or ouput directory.
"

## Dependency on this file, in case you change computers.
source ~jamesmcc/ncScripts/ncFilters.sh
source ~jamesmcc/wrfHydroScripts/helpers.sh

nLast=$1
if [[ ! $nLast =~ ^-?[0-9]+$ ]]
then
    echo -e "\e[31mPlease supply a valid integer for the firt argument 'nLast'\e[0m $help".
    exit 1
fi

if [ -z "$2" ]
then
    origRunNamelist=`readlink namelist.hrldas`
    origRunDir=`dirname $origRunNamelist`    
    nlstOutDir=`grep OUTDIR $origRunDir/namelist.hrldas | tr -d ' ' | egrep -v '^!'` || exit 1
    nlstOutDir=`echo $nlstOutDir | cut -d'=' -f2 | tr -d "'" | tr -d '"'`
    origRunOutDir=$origRunDir/$nlstOutDir
else
    origRunOutDir=`getAbsPath $2`
fi

if [ -z "$3" ]
then
    myRunOutDir=`pwd`
else
    myRunOutDir=`getAbsPath $3`
    cd $myRunOutDir
fi

echo ""
echo -e "\e[43mThe setup:\e[0m"
echo -e "\e[43m1)\e[0m nLast:          $nLast"
echo -e "\e[43m2)\e[0m origRunOutDir:  $origRunOutDir"
echo -e "\e[43m3)\e[0m myRunOutDir:    $myRunOutDir"


## DONT do the expansion here.
fileWilds=(.CHANOBS_DOMAIN  .CHRTOUT_DOMAIN    .CHRTOUT_GRID  \
           .LDASOUT_DOMAIN  HYDRO_RST.          RESTART.)

echo ""
echo "The WRF-Hydro file kinds to be compared (you may want to add others):"
echo ${fileWilds[*]}
echo ""

accRetDiffs=0

for ll in `seq $nLast -1 1`
do
    echo -e "\e[46mThe $((ll-1)) before last file of this kind:\e[0m"
    for ff in ${fileWilds[*]}
    do
        matches=`ls *$ff*`
        matches=($matches)
#        echo ${matches[*]}
#        echo ${#matches[*]}
#        echo --
        if [[ ${#matches[*]} -lt $((ll)) ]]; then continue; fi
        ifsOrig=$IFS
        IFS=$'\n'
        theFile=`echo "${matches[*]}" | tail -n $ll | head -n 1`
        IFS=$ifsOrig
        echo -e "\e[7m $theFile \e[0m"
        echo -e "\e[34mncVarDiff $myRunOutDir/$theFile $origRunOutDir/$theFile\e[0m"
        diffOut=`ncVarDiff $myRunOutDir/$theFile $origRunOutDir/$theFile 2>&1`
        retDiff=$?
        accRetDiff=$(($accRetDiff+$retDiff))
        echo -e "\e[31m$diffOut\e[0m"
    done
done

exit $accRetDiff
