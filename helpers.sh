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


function notCommented {
    ## assumes that ! is the comment... could make that an argument.
    noBlank=`echo $1 | tr -d ' '`
    if [[ $noBlank == !* ]]; then return 1; else return 0; fi
}


function getAbsPath {
    ## usage: file=`getAbsPath $file`
    if [[ ! "$1" = /* ]]; then echo `pwd`/$1; else echo $1; fi; return 0;
}


function checkBinary {
    theBinary=$1
    message="$2"
    if [[ -z $theBinary ]]; then echo -e "\e[31mNo binary supplied, returning.\e[0m"; return 1; fi
    if [[ ! -e $theBinary ]] 
    then
        echo -e "\e[31mBinary does not exist:\e[0m $theBinary"
        if [[ ! -z "$message" ]]; then echo -e "$message"; fi
        return 1
    fi
    checkBinary=`ldd $theBinary`
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
    configFile=$1
    menuName=$2
    checkExist $configFile || return 1
    whMenu=(`grep -n "$menuName" $configFile | cut -d ':' -f1`)
    nMenu="${#whMenu[@]}"
    if [[ $nMenu -ne 2 ]]; then 
        if [[ $nMenu -eq 0 ]]; then 
            echo -e "\e[31mmenu name was not found in config file: $configFile\e[0m"
        else
            echo -e "\e[31mMalformed menu (\"$menuName\") in config file: $configFile\e[0m"
        fi
        return 1
    fi
    nItems=$((${whMenu[1]}-${whMenu[0]}-1))
    head -$((${whMenu[1]}-1)) $configFile | tail -${nItems}
    return 0
}


function isInSet {
    # usage: 
    # fruit='orange bannana apple'
    # isMember [grep options] apple "$fruit"
    # Same exact options as grep, mostly focused on -i for case matching.
    nArgs=$#
    set="${@:$nArgs}"
    opts="${@:1:$(($nArgs-2))}"
    member="${@:$(($nArgs-1)):1}"
    #echo set: "$set"
    #echo opts: "$opts"
    #echo member?: "$member"
    set=`echo "$set" | tr ' ' '\n'`
    setSize=`echo "$set" | wc -l`
    if [[ $setSize -le 1 ]] 
    then
        echo "The passed set only has one member, you likely forgot the double quotes on the set variable"
        return 1
    fi
    for ss in $set
    do
        if [ -z $opts ] 
        then
            result=`echo $ss | grep "^$member$"`
        else 
            result=`echo $ss | grep "$opts" "^$member$"`
        fi
        if [ ! -z "$result" ]; then return 0; fi
    done
    return 1
}


round() {
    # $1 is expression to round (should be a valid bc expression)
    # $2 is number of decimal figures (optional). Defaults to three if none given
    [ ! -z $1 ] || return 1
    scale=${#1}
    in=`echo "scale=$scale;$1" | bc`
    local df=${2:-$scale}
    printf '%.*f\n' "$df" "$(bc -l <<< "a=$in; if(a>0) a+=5/10^($df+1) else if (a<0) a-=5/10^($df+1); scale=$df; a/1")"
    return 0
}


ceiling() {
    # $1 is expression to ceiling (should be a valid bc expression)
    [ !  -z $1 ] || return 1
    scale=${#1}
    in=`echo "scale=$scale;$1" | bc`
    #echo in $in
    inRound=`round $in 0`
    isInteger=`echo "$in == $inRound" | bc`
    if [[ $isInteger -eq 1 ]]; then echo $inRound; return 0; fi
    diff=`echo $inRound - $in | bc`
    roundUp=`echo "$diff >= 0" | bc`
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


function setHenv {
    R=0; N=0; D=0; P=0; O=0
    while getopts ":R:N:D:P:O" opt; do
        case $opt in
            R) R=1;;
            N) N=1;;
            D) D=1;;
            P) P=1;;
            O) O=1;;
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

    if [ $R -eq 1 ]; then export HYDRO_REALTIME=1; fi
    if [ $N -eq 1 ]; then export WRF_HYDRO_NUDGING=1; fi
    if [ $D -eq 1 ]; then export HYDRO_D=1; fi
    if [ $P -eq 1 ]; then export PRECIP_DOUBLE=1; fi
    if [ $O -eq 1 ]; then export OUTPUT_CHAN_CONN=1; fi
    henv
}
