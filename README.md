<header>
wrfHydroScripts
============
</header>
<main>

Towards automating repetitive, time consuming, and error-prone tasks related to setting up and running WRF-Hydro.  

These are bash scripts. To make these available at command line, you have to use bash as your shell because the 
individual scripts are sourced as functions of the same name (without ".sh" at the end) in to the shell 
environment. (You can't even define a function in csh, so you probably want to give up on it. Though you could
call the full path to the scripts in csh, or put them in your $PATH. I.E. internally these scripts (should) use 
the full paths to the script files to call them)

Note this is a work in progress.  

Commands are listed first. Setting up the scripts for your system is next.  

# Commands
## Running WRF-Hydro
* __cleanup [-r] [directoryToCleanupTo]__  
  Clean up a run directory. Option -r removes restart files. Specifying an existing directory cleansup to that directory.
  
* __cleanRun [-cnpu] nCores [runDirectory] [binary]__  
  Run the model after cleaning up the run directory.  
  Options, all passed to __linkToTestCase.sh__, used when specifying a runDirectory:  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_-c_  copy files  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_-n_  get nudging files  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_-p_  write-protect  
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;_-u_  un-write-protect
  
* __qCleanRun [-cnpu] nCores [runDirectory] [binary]__  
  Submit cleanRun to qsub/torque job scheduler.  
  Arguments identical to cleanRun. The header applied by this script can be tailored within. 
  
* __qHead__
  
## Setting up test cases
* __linkToTestCase__

## Regression testing
* __regTest [-q] binary__

* __compareOutputs__

## Compiling WRF-Hydro
* __compileAll__

* __makeCheck__

## Setup wrfHydroScripts
* __helpers__

## Plotting 
* __plotFrxst__


## Misc
* __colorFormats__
Color coding sections/warnings/errors/etc in long, verbose outputs from complicated scripts is SUPER helpful. This is 
the color-coding cheat sheet.

* __hgrep__


# Setup
These are listed in order from most critical to least critical. 

# ~/.wrfHydroScripts            
This file specifies the path to this repository on your computer (potentially other items to be added) and is 
assumed to be in this location with this name . E.g. 

> jamesmcc@hydro-c1:~> cat ~/.wrfHydroScripts  
> wrfHydroScripts=/home/jamesmcc/wrfHydroScripts  

# sourceMe.sh 
This file is meant to be sourced into a bash shell to give auto-complete (e.g. seemingly in your path) commandline 
functionality for calling the scripts

> jamesmcc@hydro-c1:~> source ~jamesmcc/wrfHydroScripts/sourceMe.sh 

but better yet, put it in your ~/.bashrc (or ~/.bash_profile, depending on your system).

> jamesmcc@hydro-c1:~> grep sourceMe ~/.bashrc  
> source ~/wrfHydroScripts/sourceMe.sh  

Note you'll still have to source sourceMe.sh in qsub scripts when you want to pick these up (unless you perform other 
shenanigans). 

# ~/.wrfHydroRegressionTests.txt
For regression testing only. This file specifies where regression test _attempts_ are to be carried out and enumerates "canned" regression tests for
interactive selection during the script.

> jamesmcc@hydro-c1:~> cat ~/.wrfHydroRegressionTests.txt  
> attemptDir = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/ATTEMPTS    
>   
> 1: Boulder Creek 1D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/Boulder_Creek_NHD  
> 2: Boulder Creek NLDAS forcing 1D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/Boulder_Creek_NHD_NLDAS  
> 3: Front Range   4D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/FRNG_NHD  
> 4: Front Range   6H NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/FRNG_NHD_6HR  







</main>
