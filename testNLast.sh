#!/bin/bash
## Purpose: Compare the output from two WRF-Hydro runs for differences. 

## fix: would be nice to know the order of the difference and have it match the order
## of the arguments, attempt-verification

## fix: if only one argument, just run unary tests?? it's easy enough to specify "." as the test dir.

help="
Arguments
1) how many of each file to compare going backwards from the last one (as N in "tail -N").
2) OPTIONAL second argument is the (relative or abs) path to the verification data. 
3) OPTIONAL but need 2 if you use 3: third argument is the (relative or abs) path to your 
            output, if missing assuming you're in the run or ouput directory.

"

whsPath=`grep "wrfHydroScripts" ~/.wrfHydroScripts | cut -d '=' -f2 | tr -d ' '` 
source $whsPath/helpers.sh
source $whsPath/ncoTests.sh

nLast=$1
if [[ ! $nLast =~ ^-?[0-9]+$ ]]
then
    echo -e "\e[31mPlease supply a valid integer for the first argument 'nLast'\e[0m $help".
    exit 1
fi

if [ -z "$2" ]
then
    origRunNamelist=`readlink namelist.hrldas`
    if [ -z $origRunNamelist ]; then origRunNamelist=namelist.hrldas; fi
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

configFile=~/.wrfHydroRegressionTests.txt
checkExist $configFile || exit 1
nLastTestMenu=`getMenu $configFile testNLast`
menuSelections=`echo "$nLastTestMenu" | tr -d ' ' | grep -v '^#' | cut -d ':' -f2`

accumReturns=0
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
        
        #########
        ## unary checks on new output
        if isInSet testNaOutput "$menuSelections"
        then
            testNaOutput $myRunOutDir/$theFile
            accumReturns=$(($accumReturns+$?))
        fi

        #########
        ## binary checks with new and old output
        if isInSet testDiffOutput "$menuSelections"
        then
            testDiffOutput $myRunOutDir/$theFile $origRunOutDir/$theFile
            accumReturns=$(($accumReturns+$?))
        fi


        echo -e "\e[31m$diffOut\e[0m"
    done
done

exit $accumReturns
