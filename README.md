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

Setting up the scripts for your system is next.  General usage tips are then given. Command usage is briefly shown after that.. 

# Setup
These are listed in order from most critical to least critical. 

# ~/.wrfHydroScripts            
This file specifies the path to this repository on your computer (potentially other items to be added) and is 
assumed to be in this location with this name . E.g. 

``` 
jamesmcc@hydro-c1:~> cat ~/.wrfHydroScripts  
wrfHydroScripts=/glade/u/home/jamesmcc/wrfHydroScripts
ncoScripts=/glade/u/home/jamesmcc/ncoScripts
wrf_hydro_model=/glade/u/home/jamesmcc/WRF_Hydro/wrf_hydro_model.

#bsubHeader: This regex is used to get the header from this file '^#BSUB'.
#            Variables available in bCleanRun: $nCores.
#            Double quotes must be escaped.
#BSUB -P P48500028                      # Project 99999999
#BSUB -x                                # exclusive use of node (not_shared)
#BSUB -n $nCores                            # number of total (MPI) tasks
#BSUB -R \"span[ptile=16]\"               # run a max of ptile tasks per node
#BSUB -J  wh_nudging                    # job name
#BSUB -o $theDate.%J.stdout  # output filename
#BSUB -e $theDate.%J.stderr  # error filename
#BSUB -W 01:00                          # wallclock time (hrs:mins)
#BSUB -q premium                        # queue: small, economy, regular, premium
#BSUB -B                                # email when the job starts
#BSUB -N                                # email when the job finishes
```
# sourceMe.sh (sourceMe.csh)
This file is meant to be sourced into a bash (or csh/tcsh) shell to make the scripts seemingly in your path commandline (with auto complete in bash) 

```
jamesmcc@hydro-c1:~> source ~jamesmcc/wrfHydroScripts/sourceMe.sh 
(in csh: jamesmcc@hydro-c1:~> source ~jamesmcc/wrfHydroScripts/sourceMe.csh)
```
but better yet, put it in your ~/.bashrc (~/.cshrc):

```
jamesmcc@hydro-c1:~> grep sourceMe ~/.bashrc  
source ~/wrfHydroScripts/sourceMe.sh  
```

For csh:
```
jamesmcc@hydro-c1:~> grep sourceMe ~/.cshrc  
source ~/wrfHydroScripts/sourceMe.csh  
```

Note you'll still have to source sourceMe.sh in qsub scripts when you want to pick these up (unless you perform other shenanigans). 

# ~/.wrfHydroRegressionTests.txt
For regression testing only. This file specifies where regression test _attempts_ are to be carried out and enumerates "canned" regression tests for
interactive selection during the script.

```
jamesmcc@hydro-c1:~> cat ~/.wrfHydroRegressionTests.txt  
attemptDir = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/ATTEMPTS  
  
*** Regression Tests Menu  
1: Boulder Creek 1D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/Boulder_Creek_NHD  
2: Boulder Creek NLDAS forcing 1D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/Boulder_Creek_NHD_NLDAS  
3: Front Range   4D NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/FRNG_NHD  
4: Front Range   6H NHD Master = /home/jamesmcc/WRF_Hydro/TESTING/REGRESSION/TESTS/FRNG_NHD_6HR  
*** Regression Tests Menu   
  
    
*** testNLast Menu - currently this menu is to be comment selected, opt out = # at start  
1: testNaOutput   : fails if there are nans in any variable in the file  
2: testDiffOutput : test fails if there are non-zero differences with verification output  
*** testNLast Menu  
```
# Usage tips

* One of the more complicated scripts that creates copies and/or links on your computer is __linkToTestCase__.   
  The most important piece of advice for avoiding a rats nest of links and copied files is:  
  _In your namelists, never point to directories or files outside of the run directory._   
  Use symlinks in to make all namelist references local to the run directory. For example, never use "../" or
  any other absolute path in your namelists. 


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

* __testNLast__

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







</main>
