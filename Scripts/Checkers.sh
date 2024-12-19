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


###############################
### CLUSTER-RELATED ENTRIES ###
###############################
# Load the required modules
# This is how it works on our computing cluster, you will need to adapt these lines to your cluster or your standalone computing rig.
# On your standalone computing rig you might just want to comment the 5 following lines using #
module load anaconda/2020.07-Python3.8-gcc8
module load cuda/10.1
module load cudnn/7.6.5-cuda10.1
module load imod/4.11.15
module load matlab


##############################
#### INPUT AND PARAMETERS ####
##############################
# Define the directory where computation is performed
#computingdir=/path/to/my/working/directory
computingdir=/home/strepout/st67/Projects/TestWorkflow

# Define directory containing the data to process (indicate the basename)
#datadir=/path/to/my/data/directory/Tomo
datadir=/scratch2/sa61/ZhiYing2/tilt_series/Tomo

# Define the path where Tomo3D is installed
tomo3dpath=/home/strepout/st67/Soft/tomo3d-2.2_january2023/bin/

# Define the thickness (in pixels) of your recontructed tomograms
thickness=2000

# Give the tilt-series X/Y dimension
dimension=2048
tomoHalf=$((dimension/2))


#########################
#### PROGRAM STARTED ####
#########################
# Got to the working directory
cd $computingdir

# Create a subfolder if it does not exist
DIR=TS_001
if [[ ! -d "$DIR" ]];
then
	mkdir "$DIR"
fi

# Loop through tilt-series. 
# Range can be large as the script checks if files exist and nonexistent tomos will be skipped.
for i in $(seq 14 33)
do

	# Change the 2-digit number into a 3-digit one
	# Replace "%03d" with "%04d" if you have more than 1000 tomos (4-digit numbers)
	j=$(printf "%03d" $i)	

	echo $i
	echo $j

	# Define directory containing the current data
	newdatadir="$datadir${j}"

	echo $newdatadir

	#exit

	# Checks if data directory exists
	if [ -d "$newdatadir" ];
	then

		# For each tilt-series, define the ROI coordinates
		# The coordinates can be measured on pre-computed 3D reconstructions
		if [[ $i -eq 14 ]];
		then

			xStart=300
			xStop=1900
			yStart=300
			yStop=1800
			zStart=400
			zStop=1500

		fi

		if [[ $i -eq 15 ]];
		then

			xStart=30
			xStop=2000
			yStart=300
			yStop=2000
			zStart=400
			zStop=1400

		fi

		if [[ $i -eq 17 ]];
		then

			xStart=100
			xStop=1800
			yStart=1
			yStop=2000
			zStart=550
			zStop=1300

		fi

		if [[ $i -eq 21 ]];
		then

			xStart=30
			xStop=1500
			yStart=1
			yStop=2000
			zStart=700
			zStop=1500

		fi		

		if [[ $i -eq 33 ]];
		then

			xStart=200
			xStop=1600
			yStart=1
			yStop=2000
			zStart=500
			zStop=1300

		fi

		xMiddle=$((xStart+xStop))
		xMiddle=$((xMiddle/2))

		yMiddle=$((yStart+yStop))
		yMiddle=$((yMiddle/2))

		xSize=$((xStop-xStart))
		ySize=$((yStop-yStart))

		xOffset=$((xMiddle-tomoHalf))
		yOffset=$((yMiddle-tomoHalf))
			
		echo $xMiddle
		echo $yMiddle

		echo $xSize
		echo $ySize

		echo $xOffset
		echo $yOffset

		echo $DIR

		# Tilt-series name (change the base name if you use another convention)
		TS="Tomo${j}.ali"

		# Tilt-file name (change the base name if you use another convention)
		TF="Tomo${j}.rawtlt"

		# Copy the aligned tilt-series to the computing directory
		cp "$newdatadir/$TS" "$computingdir/TS_001/TS_001.ali"

		# Copy the angle file to the processing folder
		cp "$newdatadir/$TF" "$computingdir/TS_001/TS_001.rawtlt"

		# -- STEP 01 -- 
		# Split the pixels into halves
		# This step requires a MRC reader inside Matlab
		matlab -nodesktop -r "cd $computingdir,run('splitPixels.m'),exit" -logfile "$computingdir/TS_001/matlab_output_splitPixels.txt"		

		# -- STEP 02a -- 
		# Reconstruct the half tilt-series
		$tomo3dpath/tomo3d -a TS_001/TS_001.rawtlt -i TS_001/TS_001a_DCT.mrc -o TS_001/TS_001a.rec -z $thickness -T 1,1,0.02

		# -- STEP 02b -- 
		# Reconstruct the half tilt-series
		$tomo3dpath/tomo3d -a TS_001/TS_001.rawtlt -i TS_001/TS_001b_DCT.mrc -o TS_001/TS_001b.rec -z $thickness -T 1,1,0.02

		# -- STEP 03a -- 
		# Flip the volume around X
		# The output name cannot be changed as the ipynb script will look for this file
		trimvol -rx TS_001/TS_001a.rec TS_001/TS_001a_DCT_wbp.rec

		# -- STEP 03b -- 
		# Flip the volume around X
		# The output name cannot be changed as the ipynb script will look for this file
		trimvol -rx TS_001/TS_001b.rec TS_001/TS_001b_DCT_wbp.rec
	
		# -- STEP 04a -- 
		# Trim the volume to remove any white areas
		# If trimming is necessary, use the following command, changing the -secs -size and --offset parameters accordingly
		# Use carefully as it overwrites the previous file
		newstack -input TS_001/TS_001a_DCT_wbp.rec -output TS_001/TS_001a_DCT_wbp.rec -secs $zStart-$zStop -size $xSize,$ySize -offset $xOffset,$yOffset

		# -- STEP 04b -- 
		# Trim the volume to remove any white areas
		# If trimming is necessary, use the following command, changing the -secs -size and --offset parameters accordingly
		# Use carefully as it overwrites the previous file
		newstack -input TS_001/TS_001b_DCT_wbp.rec -output TS_001/TS_001b_DCT_wbp.rec -secs $zStart-$zStop -size $xSize,$ySize -offset $xOffset,$yOffset

		# -- STEP 05 -- 
		# Remove temp files
		rm TS_001/TS_001a.rec
		rm TS_001/TS_001b.rec

		# -- STEP 06 -- 
		# Activate miniconda and load the cryocare environment
		# Change path if you need activation of your cryocare conda environment
		source /my/path/to/conda/miniconda/bin/activate
		conda activate cryocare

		# -- STEP 07 -- 
		# Generate data for training
		#ipython -c "%run step1_train_data_generation.ipynb"

		# -- STEP 08-- 
		# Train the network and generate a model
		#ipython -c "%run step2_train_neural_network.ipynb"

		# -- STEP 09 -- 
		# Denoise the tomogram using the computed model
		#ipython -c "%run step3_denoise_tomogram.ipynb"

		# -- STEP 10 -- 
		# Copy the denoised tomogram and the config and model files to the data directory
		#mv TS_001/TS_001_DTC_wbp_denoised.mrc "$newdatadir/$TS"_denoised2.mrc
		#mv TS_001/model_001/config.json "$newdatadir/config.json"
		#mv TS_001/model_001/weights* "$newdatadir/"
		mv TS_001/matlab_output_splitPixels.txt "$newdatadir/"
		rm TS_001/TS_001*

		#exit

	fi

done
	

