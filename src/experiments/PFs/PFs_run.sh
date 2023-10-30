#!/bin/bash
#SBATCH --partition=standard
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=3G
#SBATCH --time=96:00:00 
#SBATCH --output=/home/dguest2/ProfileAnalysis.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=daniel_guest@urmc.rochester.edu
# Load required software
module load hdf5
module load git
module load matlab
# module load julia

# Print current time
now=$(date +"%T")
echo "Start time : $now"

# Run script
cd ~/cl_code/ProfileAnalysis/src/experiments/PFs
julia -p 30 PFs_run.jl

# Print current time
now=$(date +"%T")
echo "Stop time : $now"


