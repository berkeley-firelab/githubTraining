#!/bin/bash
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -t 3600
#SBATCH --mem-per-cpu=50000
#SBATCH --time=1-02:00:00

# Begin specifying inputs

CELLSIZE=10.0 # Grid size in meters

# End inputs specification

ELMFIRE_VER=${ELMFIRE_VER:-2023.0427}

SCRATCH=./scratch
INPUTS=./inputs
OUTPUTS=./outputs
MISC=./misc

#rm slurm*.out
rm -f -r $SCRATCH $INPUTS $OUTPUTS $MISC
mkdir $INPUTS $SCRATCH $OUTPUTS $MISC

echo $CELLSIZE | python input_generator.py
cp elmfire.data.in $INPUTS/elmfire.data
cp $ELMFIRE_BASE_DIR/build/source/fuel_models.csv $MISC
A_SRS="EPSG: 32610" # Spatial reference system - UTM Zone 10

# Execute ELMFIRE
mpirun --mca opal_warn_on_mission_libcuda 0 -np 1 elmfire_$ELMFIRE_VER ./inputs/elmfire.data

# Postprocess
for f in ./outputs/*.bil; do
   gdal_translate -a_srs "$A_SRS" -co "COMPRESS=DEFLATE" -co "ZLEVEL=9" $f ./outputs/`basename $f | cut -d. -f1`.tif
done
gdal_contour -i 3600 `ls ./outputs/time_of_arrival*.tif` ./outputs/hourly_isochrones.shp

# Clean up and exit:
rm -f -r ./outputs/*.bil ./outputs/*.hdr $SCRATCH $MISC

exit 0
