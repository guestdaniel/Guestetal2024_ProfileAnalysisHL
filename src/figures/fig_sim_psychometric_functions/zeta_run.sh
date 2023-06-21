#!/bin/bash
#SBATCH --partition=standard
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=2G
#SBATCH --time=08:00:00 
#SBATCH --output=/home/dguest2/ProfileAnalysis.log
#SBATCH --mail-type=ALL
#SBATCH --mail-user=daniel_guest@urmc.rochester.edu
# Load required software
module load hdf5
module load git
module load matlab
module load julia

# Print current time
now=$(date +"%T")
echo "Start time : $now"

# Run script
cd ~/cl_code/ProfileAnalysis/papers/Guestetal2023/figures/fig_zeta
julia -p 30 zeta_run.jl

# Print current time
now=$(date +"%T")
echo "Stop time : $now"


