#!/bin/bash


# References
#
#   created by ST 01/11/23
#
#   Buckley G., Ramm G. and Trépout S., 'GoldDigger and Checkers, computational developments in
#   cryo-scanning transmission electron tomography to improve the quality of reconstructed volumes'
#   Journal, volume (year), page-page.
#
#   Ramaciotti Centre for CryoEM
#   Monash University
#   15, Innovation Walk
#   Clayton 3168
#   Victoria (The Place To Be)
#   Australia
#   https://www.monash.edu/researchinfrastructure/cryo-em/our-team



# Load the required modules
module load anaconda/2020.07-Python3.8-gcc8
module load cuda/10.1
module load cudnn/7.6.5-cuda10.1
module load imod/4.11.15

# Define the directory where computation is performed
workingdir=/path/to/my/working/directory

# Define directory containing the data
DIR=/path/to/my/data/directory

# Define the thickness of your recontructed tomograms
thickness=800

# Got to the working directory
cd $workingdir


# Copy the aligned tilt-series to the computing directory
cp "$DIR/Tomo110.ali" "$workingdir/TS_001/TS_001.ali"

# Copy the angle file to the processing folder
cp "$DIR/Tomo110.rawtlt" "$workingdir/TS_001/TS_001.rawtlt"


# Split the pixels into halves
# This step requires at MRC reader inside Matlab, this is why we want to port everything to Python
matlab -nodesktop -r "cd $workingdir,run('splitPixels.m'),exit" -logfile "$workingdir/TS_001/matlab_output_splitPixels.txt"		

# Reconstruct the half tilt-series
/home/strepout/st67/Soft/tomo3d-2.2_january2023/bin/tomo3d -a TS_001/TS_001.rawtlt -i TS_001/TS_001a_DCT.mrc -o TS_001/TS_001a_DCT_wbp.rec -z $thickness

# Flip the volume around X
trimvol -rx TS_001/TS_001a_DCT_wbp.rec TS_001/TS_001a_DCT_wbp.rec2

# Trim the volume to remove any white areas
# If trimming is necessary, use the following command, changing the -secs -size and --offset parameters accordingly
newstack -input TS_001/TS_001a_DCT_wbp.rec2 -output TS_001/TS_001a_DCT_crop.rec -secs 0-499 -size 1600,1700 -offset -700,-650

# Remove temp files
rm TS_001/TS_001a_DCT_wbp.rec*

# Reconstruct the half tilt-series
/home/strepout/st67/Soft/tomo3d-2.2_january2023/bin/tomo3d -a TS_001/TS_001.rawtlt -i TS_001/TS_001b_DCT.mrc -o TS_001/TS_001b_DCT_wbp.rec -z $thickness

# Flip the volume around X
trimvol -rx TS_001/TS_001b_DCT_wbp.rec TS_001/TS_001b_DCT_wbp.rec2

# Trim the volume to remove any white areas
# If trimming is necessary, use the following command, changing the -secs -size and --offset parameters accordingly
newstack -input TS_001/TS_001b_DCT_wbp.rec2 -output TS_001/TS_001b_DCT_crop.rec -secs 0-499 -size 1600,1700 -offset -700,-650

# Remove temp files
rm TS_001/TS_001b_DCT_wbp.rec*

# Activate miniconda and load the cryocare environment
source /home/strepout/st67/conda/miniconda/bin/activate
conda activate cryocare

# Generate data for training
ipython -c "%run step1_train_data_generation.ipynb"

# Train the network and generate a model
ipython -c "%run step2_train_neural_network.ipynb"

# Denoise the tomogram using the computed model
ipython -c "%run step3_denoise_tomogram.ipynb"

# Copy the denoised tomogram and the config and model files to the data directory
mv TS_001/TS_001_DTC_crop_denoised.mrc "$DIR/Tomo110_DTC_crop_denoised.mrc"
mv TS_001/model_001/config.json "$DIR/config.json"
mv TS_001/model_001/weights* "$DIR/"

	

