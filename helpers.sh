#!/bin/bash

## Remember in bash: TRUE=0, FALSE=1, unless you're using (( ))

function checkExist {
    # arg 1: the thing to test for existence
    # arg 2: OPTIONAL, additional text to echo
    if [ ! -e $1 ]; then 
        echo -e "\e[31m${1} does not exist.\e[0m" 
        if [ ! -z $2 ]; then echo -e "$2"; fi
        return 1
    else 
        return 0
    fi
}


function commented {
    # options w args
    # -c commentChar
    # -e commentException exception string, starts with commentChar or commentChar is added to its start
    local OPTIND
    local commentChar commentException
    commentChar=!
    commentException='!'  ## equal to commentChar does nothing
    while getopts ":c:e:" opt; do
        case $opt in
            c)  commentChar="${OPTARG}"
                commentException=$commentChar;;
            e)  commentException="${OPTARG}";;
            \?) echo "Invalid option: -$OPTARG";;
        esac
    done
    shift "$((OPTIND-1))" # Shift off the options and optional
    
    if [ ${#commentChar} -gt 1 ]
    then
        commentChar=`echo $commentChar | cut -c1`
        echo "Supplied comment character longer than length 1, using the first character: $commentChar"
    fi

    local firstCE=`echo $commentException | cut -c1`
    if [ ! $firstCE == $commentChar ]
    then
        commentException="${commentChar}${commentException}"
        echo "comment exception string does not begin with the comment character, prepending it: $commentException"
    fi

    local noBlank=`echo $1 | tr -d ' '`
    if [[ ! $commentChar == $commentException ]]
    then
        if [[ $noBlank == "$commentException"* ]]; then return 1; else return 0; fi
    fi
    if [[ $noBlank == "$commentChar"* ]]; then return 0; else return 1; fi
}

function notCommented {
    commented "$@"
    local retVal=$?
    if [ $retVal -eq 0 ]; then return 1; fi
    if [ ! $retVal -eq 0 ]; then return 0; fi
}

function getAbsPath {
    ## usage: file=`getAbsPath $file`
    if [[ ! "$1" = /* ]]; then echo `pwd`/$1; else echo $1; fi; return 0;
}


function checkBinary {
    local theBinary=$1
    local message="$2"
    if [[ -z $theBinary ]]; then echo -e "\e[31mNo binary supplied, returning.\e[0m"; return 1; fi
    if [[ ! -e $theBinary ]] 
    then
        echo -e "\e[31mBinary does not exist:\e[0m $theBinary"
        if [[ ! -z "$message" ]]; then echo -e "$message"; fi
        return 1
    fi
    local checkBinary=`ldd $theBinary`
    if [ ! $? -eq 0 ] 
    then
        echo -e "\e[31mProblems with executable:\e[0m $theBinary"
        if [[ ! -z "$message" ]]; then echo -e "$message"; fi
        return 1
    fi
    return 0
}


function getMenu {
    if [ -z $1 ]; then echo -e "\e[31mgetMenu requires its first arg to be a config file.\e[0m"; fi
    if [ -z "$2" ]; then echo -e "\e[31mgetMenu requires its second arg to be a menu name.\e[0m"; fi
    if [ -z $1 ] | [ -z "$2" ]; then return 1; fi
    local configFile=$1
    local menuName=$2
    checkExist $configFile || return 1
    local whMenu=(`grep -n "$menuName" $configFile | cut -d ':' -f1`)
    local nMenu="${#whMenu[@]}"
    if [[ $nMenu -ne 2 ]]; then 
        if [[ $nMenu -eq 0 ]]; then 
            echo -e "\e[31mmenu name was not found in config file: $configFile\e[0m"
        else
            echo -e "\e[31mMalformed menu (\"$menuName\") in config file: $configFile\e[0m"
        fi
        return 1
    fi
    local nItems=$((${whMenu[1]}-${whMenu[0]}-1))
    head -$((${whMenu[1]}-1)) $configFile | tail -${nItems}
    return 0
}


function isInSet {
    # usage: 
    # fruit='orange bannana apple'
    # isInSet [grep options] apple "$fruit"
    # Same exact options as grep, mostly focused on -i for case matching.
    local nArgs=$#
    local set="${@:$nArgs}"
    local opts="${@:1:$(($nArgs-2))}"
    local member="${@:$(($nArgs-1)):1}"
    #echo set: "$set"
    #echo opts: "$opts"
    #echo member?: "$member"
    local set=`echo "$set" | tr ' ' '\n'`
    local setSize=`echo "$set" | wc -l`
    if [[ $setSize -le 1 ]] 
    then
        echo "Warning: The set only has one member."
        echo "You may have forgoten double quotes on the set variable."
        if [ $member == $set ]; then return 0; fi
        return 1
    fi
    for ss in $set
    do
        if [ -z $opts ] 
        then
            local result=`echo $ss | grep "^$member$"`
        else 
            local result=`echo $ss | grep "$opts" "^$member$"`
        fi
        if [ ! -z "$result" ]; then return 0; fi
    done
    return 1
}


round() {
    # $1 is expression to round (should be a valid bc expression)
    # $2 is number of decimal figures (optional). Defaults to three if none given
    [ ! -z $1 ] || return 1
    local scale=${#1}
    local in=`echo "scale=$scale;$1" | bc`
    local df=${2:-$scale}
    printf '%.*f\n' "$df" "$(bc -l <<< "a=$in; if(a>0) a+=5/10^($df+1) else if (a<0) a-=5/10^($df+1); scale=$df; a/1")"
    return 0
}


ceiling() {
    # $1 is expression to ceiling (should be a valid bc expression)
    [ !  -z $1 ] || return 1
    local scale=${#1}
    local in=`echo "scale=$scale;$1" | bc`
    #echo in $in
    local inRound=`round $in 0`
    local isInteger=`echo "$in == $inRound" | bc`
    if [[ $isInteger -eq 1 ]]; then echo $inRound; return 0; fi
    local diff=`echo $inRound - $in | bc`
    local roundUp=`echo "$diff >= 0" | bc`
    if [[ $roundUp -eq 1 ]] 
    then 
        echo $inRound
    else 
        echo $((${inRound}+1)) 
    fi
    return 0
}


function monitorQsubJob {
# $1 is the job id
# return value is the model return value
    local qJobId=$1
    ## That's so easy! (NOT)
    local qJobStatus=`qstat $qJobId | tail -1 | sed 's/ \+/ /g' | cut -d ' ' -f5`
    echo "Waiting for qsub job: $qJobId"
    while [[ ! $qJobStatus == C ]]  
    do
        printf '.'
        qJobStatus=`qstat $qJobId | tail -1 | sed 's/ \+/ /g' | cut -d ' ' -f5`
        sleep 6
    done
    echo ''
    local qTrace=`tracejob $qJobId 2> /dev/null`
    ## certainly not easy to pars stuff coming out of torque... 
    local modelSuccess=`echo "$qTrace" | grep 'Exit_status' | head -1 | sed 's/ \+/\n/g' | grep 'Exit_status' | cut -d '=' -f2`
    return $modelSuccess
}


function monitorBsubJob {
# $1 is the job id
# return value is the model return value
    local bJobId=$1
    local bHist=`bhist -la $bJobId`
    local whRunlimit=`echo "$bHist" | grep -n RUNLIMIT | cut -d':' -f1`
    local bJobStatus=`echo "$bHist" | tail -n+$((whRunlimit)) | grep -i exit | wc -l`
    echo "Waiting for bsub job: $bJobId"
    while [[ $bJobStatus -eq 0 ]]  
    do
        printf '.'
        bHist=`bhist -la $bJobId`
        whRunlimit=`echo "$bHist" | grep -n RUNLIMIT | cut -d':' -f1`
        bJobStatus=`echo "$bHist" | tail -n+$((whRunlimit)) | grep -i exit | wc -l`
        sleep 6
    done
    ## certainly not easy to parse stuff coming out 
    local modelExited=`echo $bHist | grep Exited`
    local exitCode=`echo $modelExited | tr ' ' '\n' | grep -n code | cut -d':' -f1`

    if [ ! -z $exitCode ] 
    then
        exitCode=`echo $modelExited | tr ' ' '\n' | tail -n+$(($exitCode+1)) | head -1 | cut -d'.' -f1`
    else
        echo $bHist | grep exit | tr ' ' '\n' | grep TERM | cut -d ':' -f1
        modelSuccess=1
    fi

    return $exitCode
}

function stripColors { 
    sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g"
}

function errGrep { 
    grep -i 'error' $1 &> /dev/null; return $((!$?)) 
}

return 0