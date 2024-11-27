# Profile Analysis in Listeners with Normal and Elevated Audiometric Thresholds: Behavioral and Modeling Results

# Introduction
This repository contains the code necessary to reproduce the figures and analyses described in:

```
Guest, D. R., Cameron, D. A., Schwarz, D. M., Leong, U.-C., Richards, V. M., and Carney, L. H. (2024). "Profile Analysis in Listeners with Normal and Elevated Audiometric Thresholds: Behavioral and Modeling Results." The Journal of the Acoustical Society of America, XX(XX), XX—XX, doi:XXX.
```

Corresponding author: Daniel Guest (daniel_guest@urmc.rochester.edu, https://github.com/guestdaniel).

This repository can be found at https://osf.io/krfmq/. 

# Files and paths
## Behavioral data
Behavioral data are stored in the `data` folder.
Processed internal data is stored in `data/int_pro`.
The behavioral data are available in tidy format in a `.csv` file at `data/int_pro/data_postproc.csv`.
Each row in this file is a single "data point" consisting of the proportion of correct trials in a single block, as described in the text of the paper, and all relevant data about the configuration of the block (e.g., frequency, level roving) and the particpant (e.g., ID, audiogram thresholds).
This file has the following columns:
- `freq`: Frequency condition (Hz)
- `level`: Sound level (dB SPL)
- `subj`: Participant ID
- `increment`: Size of the profile-analysis level increment (dB SRS)
- `n_comp`: Number of stimulus frequency components, including target
- `pcorr`: Proportion of correct trials
- `rove`: Presence of level roving, either "fixed level" or "roved level"
- `age`: Participant age (years)
- `sex`: Participant sex (M or F)
- `F250`–`F8000`: Participant audiometric thresholds at the corresponding frequency (dB HL)
- `hl`: Participant audiometric threshold at target frequency as indicated in `freq` column (dB HL)
- `pta_all`: Pure-tone average composed of all audiometric thresholds (dB HL)
- `pta_4`: Pure-tone average composed of 0.5, 1.0, 2.0, and 3.0 kHz thresholds, reported in the manuscript as PTA[0.5–3] (dB HL)
- `pta_upper`: Pure-tone average composed of 4.0, 6.0, and 8.0 kHz thresholds, reported in the manuscript as PTA[4–8] (dB HL)
- `level_per_component`: The per-component level of the reference (i.e., unincremented) stimulus components (dB SPL)
- `audio_threshold_spl`: Participant audiometric threshold converted into dB SPL assuming standard HL to SPL conversion factors (dB SPL)
- `sl`: Estimated per-component sensation levels of the reference stimulus components (dB SL)
- `include`: Boolean indicating whether this datum satisfies the inclusion criteria for plotting and statistical analysis as described in the paper

Some processed *external* data are also available (from other studies of profile analyis, mostly Green lab work from the 80s/90s).
These are available in tidy format in a `.csv` file at `data/ext_pro/paper_fig.csv`, where paper is in `[Green1985, Bernstein1987, Lentz1999]` and figure is in `[Fig2, Fig3, Fig4]`. 
These data did not end up in the paper, but may be of use to others. 

## Path structure
```
.  
├── data                     # Behavioral data (internal and external) lives here
├── plots                    # Intermediate figure files and .svg figure files
├── src                      # Primary source directory
│   ├── experiments          # Code for simulated experiments
│   ├── figures              # Code for compiling simulated results into figures
│   └── ProfileAnalysis.jl   # Primary source file
├── workflows                # Folder containing sequences of scripts
│   ├── behavioral_data      # Scripts for wrangling/plotting/analyzing behavioral data
│   ├── simulations          # Scripts for running simulated experiments
│   └── genfigs.jl           # Script for generating paper figures
├── docs.md                  # Documentation file for the entire repository
├── cfg.R                    # Script to provide config shared across all R files
├── LICENSE                  # License file for the code contained in this repository
└── Project.toml             # Julia environment management file
```

# Code
This project used a mixture of MATLAB, R, and Julia code.
The usage of each language, and how to set up an appropriate environment for using the associated code, is described below.

## MATLAB
MATLAB was used to create the stimuli, present them to listeners, collect behavioral responses, and compile the raw data into a usable form.
Most of these steps and the associated code are not included in this repository. 
Only a few MATLAB scripts are included in this repository, handling conversion of raw `.mat` data files into more user-friendly `.csv` files.
However, these scripts rely on specific local paths and access to University of Rochester internal networks and are not intended for outside use. 

## R 
R was used to perform statistical analyses on the preprocessed behavior data (see `Files and paths` section above for more detail).
This code relies on several common packages, such as `lme4`, `ggplot2`, `phia`, `effects`, and `dplyr`.
Any suitably recent version of R should suffice (the author used 4.3.1); packages can be installed as needed based on which `.R` scripts are used.
Please contact the corresponding author with questions or concerns.

## Julia
Julia was used to generate figures and perform the computational modeling.
This repository is itself a Julia package that we recommend working from by using it as your environment (i.e., open a REPL in this folder, press `]`, and then type `activate .`).
The code can be used once the correct custom dependencies are installed and the environment precompiles successfully. 
There are three such requirements: `AuditorySignalUtils.jl`, `AuditoryNerveFiber.jl`, and `UtilitiesPA`, described below.

### AuditorySignalUtils.jl
AuditorySignalUtils.jl is a small collection of auditory synthesis utilities in Julia. 
It is registered in the Julia package registry.
Install by switching to the package manager (`]` in the REPL) and typing:
```
add AuditorySignalUtils
```

### AuditoryNerveFiber.jl
AuditoryNerveFiber.jl is a wrapper for the Zilany-Bruce-Carney auditory-nerve model in Julia.
A copy is included in this repository in a folder of the same name.
To install, follow the install instructions from Step 2 in the AuditoryNerveFiber.jl folder's `README.md`.
Then, install the package in your Julia environment by switching to the package manager (`]` in the REPL) and typing:
```
add AuditoryNerveFiber.jl
```
This assumes that your REPL's current active directory is the top-level folder of this repository.
Adjust the path accordingly if this is not the case.

Note that AuditoryNerveFiber.jl is an frozen copy of an older version of the actively maintained [ZilanyBruceCarney2014.jl](https://github.com/ZilanyBruceCarney2014.jl). 
This older version is relied on to avoid the need to replace all of the instances of the old name with the new one, but is otherwise nearly identicaly code (as of late 2024).

### UtilitiesPA
This is a package of utility code used in the profile-analysis auditory-model simulations.
A copy is included in this repository in a folder of the same name.
Install in your Julia environment by switching to the package manager (`]` in the REPL) and typing:
```
add UtilitiesPA
```
This assumes that your REPL's current active directory is the top-level folder of this repository.
Adjust the path accordingly if this is not the case.

# Workflows

## Behavioral data workflow (internal)
This section describes the behavioral data workflow steps that are *internal* to the Carney lab (i.e., they are irrelevant for anyone without access to the raw data).
Behavioral data for the profile-analysis experiments are stored on `\\nsc-lcarney-h1\C$`.
There are two manual steps that involve interacting with the `\\nsc-lcarney-h1` machine.

1. First, remove any files/folders in `C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results` to ensure we have a clean slate for a local copy of the data.
2. Next, copy all files/folder from `\\nsc-lcarney-h1\C$\results\profile_analysis_iso_results` to `C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results`

Next we have automated steps that preprocess, clean, and compile the data.
1. Run `workflows\behavioral_data\01_extract_data_mat_to_excel.m` to extract all data from the source `.mat` files to more accessible `.xlsx` files. Both `AuditoryStimulus` and `behavior_code` folders must be on the path (these folders contain various `.m` files needed to properly parse the contents of the `.mat` files containing the data).
2. Run `workflows\behavioral_data\02_convert_audiograms_to_csv.m` to convert the `.mat` file containing subject info and audiograms into a `.csv` file. This CSV file is then manually copied as `audiometry.csv` and placed into the `data\int_pro` folder for later use. Note that audiogram data for one subject (S198) has been manually added as the last row of this CSV.
3. Run `workflows\behavioral_data\03_compile_data.R` to compile raw block-wise data from `.xlsx` files into a single tidy format.

## Behavioral data workflow (external)
This section describes behavioral data workflow steps that are relevant to anyone with the partially preprocessed behavioral data files available in `data\int_pro` in the file `data.csv`. 
We extract thresholds from the raw data in Julia and then analyze those thresholds in R.
1. Run `workflows\behavioral_data\04_postprocess_compiled_data.jl` to add additional useful columns to the behavioral data (e.g., levels in terms of sensation level)
2. Run `workflows\behavioral_data\05_extract_thresholds.jl` to fit logistic curves to behavioral data on the individual-listener level in each condition and save to resulting thresholds and slopes to disk.
3. Run `workflows\behavioral_data\06_evaluate_threshold_fits.jl` to generate plots showing the correspondence between the raw proportion correct data and the fitted curves.

Finally, we analyze the fitted threshold data as well as subject data (e.g., audiograms) to generate data/analyses needed for the paper
1. Run `workflows\behavioral_data\07_model_thresholds_1kHz.R` to run the statistical model for the 1-kHz profile-analysis data
2. Run `workflows\behavioral_data\08_model_thresholds_freq.R` to run the model for the remaining portion of the profile-analysis data
3. Run `workflows\behavioral_data\09_calculate_subject_stats.jl` and `scripts\internal_data\10_calculate_block_stats.jl` interactively to gather data about subjects and data collection to report in methods section

## Modeling workflow
The simulations reported in Figs 6–9 are quite extensive and require substantial computing resources to complete in a reasonable time frame (*see note at bottom of section about how to avoid!!*).
Theoretically, the bare-minimum steps for a full reproduction are as follows:
1. Run the script `experiments/PFs/PFs_run.jl`. You will first need to modify the file on line 1 to point to your `ProfileAnalysis` directory.
2. Run the Julia script `workflows/simulations/compile.jl`.
3. Use the script `workflows/genfigs.jl` to generate the figures of interest (see below for more detail).

However, in practice, this code may take several days or more to run on a single core. 
You can run the first script, `PFs_run.jl` in parallel by starting Julia with multiple workers:
```
julia -p 8 PFs_run.jl
```
Even then, however, it may take several days to complete.
We run this script using a SLURM setup on Rochester's compute cluster.
Refer to `experiments/PFs/PFs_run.sh` to see how we set up the SLURM environment and run the `.jl` script.
The Julia code will automatically cache all of the simulation results to disk as it runs; these results can then be moved back to your local machine by `rsync` or similar tools, and then you can proceed to step 2 entirely on the local machine.

Note that there are some BlueHive-specific paths in the code; if you want to deploy this code on a different Linux machine, search this repository for `Linux` to see where paths may need to be modified for your use case.
In general, these steps have not been tested on other platforms/setups, and so this code is not intended as a turn-key reproduction of the results of the paper — please contact the authors if you are serious about reproducing our results with this code and assistance can be provided!

*Note that this workflow can be avoided by relying on the preprocessed and compiled model-threshold estimates stored in `sim_pro/model_thresholds*.jld2`.*
*The figure generation code (see below) already does this, so you should be able to reproduce the figures even without recomputing all the model responses.*

## Figure workflow
Once simulations are run, figures can be generated by running `workflows/genfigs.jl`.
Some figure code generates multiple subfigures that are combined post hoc into single images in Inkscape.
The `.svg` files involved in this process are not included in this repository but are available upon request.