#!/bin/bash

## Purpose: do the NLDAS regridding in one go with a minimum amount of 
## information suppled, do it in the output directory and, optionally,
## clean up the mess.

## I hacked the scripts to pass everything at command line and just configure this file. 
## These could also be commandline args to this script when so motivated. 

## Requires a hacked version of NLDAS2WRFHYDRO_forcing_regridder_ESMFregrid.ncl
## where dirm and outdir are commented out.
## I also noted system() in ncl... so these hacks could be applied internally if desired.

#### CONFIGURE ############
## your geogrid file
geo=~/WRF_Hydro/domains/Boulder_Creek_NHD/geo_em.d01.boulder_creek_1km.nc
## Path with pattern to match
src='/glade/scratch/karsten/NLDAS/2013/NLDAS_FORA0125_H.201307010[0-6]*'
## directory where regridded forcing data will be placed. set to dirm for overwriting the original file
outdir="FORC_Boulder_Creek_NHD_tmp/"      
############################

## Derivatives of the config
function getAbsPath {
    if [[ ! "$1" = /* ]]; then echo `pwd`/$1; else echo $1; fi
}

geo=`getAbsPath $geo`
srcW=`ls $src | head -1`
srcW=`getAbsPath $srcW`
dirm=`dirname "$src"`/
dirm=`getAbsPath $dirm`
src=`basename "$src"`
outdir=`getAbsPath $outdir`

## Check before spewing
echo -e "\e[0;49;96mThe geogrid file                   :\e[0m $geo"
echo -e "\e[0;49;96mSource file for regridding weights :\e[0m $srcW"
echo -e "\e[0;49;96mPath/pattern for NLDAS files       :\e[0m $src"
echo -e "\e[0;49;96mThe output directory               :\e[0m $outdir"
echo
echo -e "\e[31mIs this setup OK? y/n?:\e[0m"
read OK
[ "$OK" == y ] || exit 4

if [ ! -d $outdir ]; then mkdir -p $outdir; fi
## Just do everything in the output directory
origDir=`pwd`
cd $outdir
## link to the ncl scripts
ln -sf ${origDir}/ESMF_genWgts_NLDAS2WRFHYDRO_forcing.ncl .
ln -sf ${origDir}/NLDAS2WRFHYDRO_forcing_regridder_ESMFregrid.ncl .

#### GENERATE THE WEIGHTS
ncl "interp_opt=\"conserve\"" "srcGridName=\"$srcW\"" "dstGridName=\"$geo\"" ESMF_genWgts_NLDAS2WRFHYDRO_forcing.ncl

#### REGRID
## directory where source forcing data resides

origOutDir=$outdir
outdir="./"
ncl "srcfilename=\"$src\"" "dstGridName=\"$geo\"" \
     "dirm=\"$dirm\"" "outdir=\"$outdir\"" NLDAS2WRFHYDRO_forcing_regridder_ESMFregrid.ncl

echo
echo -e "\[7;107;91m Finished \e[0m"

echo
echo -e "Created the following files in $origOutDir:"
ls -l --color=auto ESMF_genWgts_NLDAS2WRFHYDRO_forcing.ncl 
ls -l --color=auto NLDAS2WRFHYDRO_forcing_regridder_ESMFregrid.ncl 
ls -l --color=auto NLDAS_to_WRFHYDRO_weight_conserve.nc
ls -l --color=auto PET0.RegridWeightGen.Log
ls -l --color=auto dst_NLDAS2WRFHYDRO_conserve.nc
ls -l --color=auto src_NLDAS2WRFHYDRO_conserve.nc
echo -e "Do you want to remove these? y/n?:"
read OK
if [ "$OK" == y ] 
then
    rm ESMF_genWgts_NLDAS2WRFHYDRO_forcing.ncl \
       NLDAS2WRFHYDRO_forcing_regridder_ESMFregrid.ncl \
       NLDAS_to_WRFHYDRO_weight_conserve.nc \
       PET0.RegridWeightGen.Log \
       dst_NLDAS2WRFHYDRO_conserve.nc \
       src_NLDAS2WRFHYDRO_conserve.nc
fi

exit 0
