# Profile Analysis in Listeners with Normal and Elevated Audiometric Thresholds: Behavioral and Modeling Results

# Introduction
This repository contains the code necessary to reproduce the figures and analyses described in:

```
Guest, D. R., Cameron, D. A., Schwarz, D. M., Leong, U.-C., Richards, V. M., and Carney, L. H. (2024). "Profile Analysis in Listeners with Normal and Elevated Audiometric Thresholds: Behavioral and Modeling Results." The Journal of the Acoustical Society of America, XX(XX), XX—XX, doi:XXX.
```

This repository can be found at https://osf.io/krfmq/. 

# Files and paths
## Behavioral data
Behavioral data are stored in the `data` folder.
Processed internal data is stored in `data/int_pro`.
The behavioral data are available in tidy format in a `.csv` file at `data/int_pro/data_postproc.csv`.
This file has the following columns:

Some processed *external* data are also available (from other studies of profile analyis, mostly Green lab work from the 80s/90s).
These are available in tidy format in a `.csv` file at `data/ext_pro/paper_fig.csv`, where paper is in `[Green1985, Bernstein1987, Lentz1999]` and figure is in `[Fig2, Fig3, Fig4]`. 
These files have the following columns:

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
Most of these steps, and the associated code, are not handled in this repository (but you can contact the authors with questions or code requests).  
Only a few MATLAB scripts are included in this repository, handling conversion of raw `.mat` data files into more user-friendly `.csv` files.
However, these scripts rely on specific local paths and access to University of Rochester internal networks and are not intended for outside use. 

## R 
R was used to perform statistical analyses on the preprocessed behavior data (see `Files and paths` section above for more detail).
This code relies on several common packages, such as `lme4`, `ggplot2`, `phia`, `effects`, and `dplyr`.
Any suitably recent version of R should suffice (the author used 4.3.1); packages can be installed as needed based on which `.R` scripts are used.
Please contact the corresponding author with questions or concerns.

## Julia
Julia was used to generate figures and perform the computational modeling.
This repository is itself a Julia package that can be used as normal once the correct custom dependencies are installed.
There are three such requirements: `AuditorySignalUtils.jl`, `AuditoryNerveFiber.jl`, and `UtilitiesPA`.
Please contact the corresponding author with questions or concerns.

### AuditorySignalUtils.jl
AuditorySignalUtils.jl is a small collection of auditory synthesis utilities in Julia. 
Install by switching to the package manager (`]` in the REPL) and typing:
```
add https://github.com/guestdaniel/AuditorySignalUtils.jl
```

### AuditoryNerveFiber.jl
AuditoryNerveFiber.jl is a wrapper for the Zilany-Bruce-Carney auditory-nerve model in Julia.
Install by switching to the package manager (`]` in the REPL) and typing:
```
add https://github.com/guestdaniel/AuditoryNerveFiber.jl
```

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
This section describes behavioral data workflow steps that are relevant to anyone with the partially preprocessed behavioral data files available in `data\int_pro`. 
We extract thresholds from the raw data in Julia and then analyze those thresholds in R.
1. Run `workflows\behavioral_data\04_postprocess_compiled_data.jl` to add additional useful columns to the behavioral data (e.g., levels in terms of sensation level)
2. Run `workflows\behavioral_data\05_extract_thresholds.jl` to fit logistic curves to behavioral data on the individual-listener level in each condition and save to resulting thresholds and slopes to disk.
3. Run `workflows\behavioral_data\06_evaluate_threshold_fits.jl` to generate plots showing the correspondence between the raw proportion correct data and the fitted curves.

Finally, we analyze the fitted threshold data as well as subject data (e.g., audiograms) to generate data/analyses needed for the paper
1. Run `workflows\behavioral_data\07_model_thresholds_1kHz.R` to run the statistical model for the 1-kHz profile-analysis data
2. Run `workflows\behavioral_data\08_model_thresholds_freq.R` to run the model for the remaining portion of the profile-analysis data
3. Run `workflows\behavioral_data\09_calculate_subject_stats.jl` and `scripts\internal_data\10_calculate_block_stats.jl` interactively to gather data about subjects and data collection to report in methods section

## Modeling workflow
### Parameter sets
Parameters were selected by hand to provide balanced responses to modulated noise and profile-analysis stimuli (i.e., a balance between good MTFs and good sustained resposnes to profile-analysis stimuli).
Selected parameters are available in `src\experiments\parameter_sets.jl`.

### Generating and examining simulations
Simulations are organized around concrete subtypes of `ProfileAnalysisExperiment`.
There are several available, each of which handle a subset of the total necessary simulations for the paper:
- `ProfileAnalysis_PFTemplateObserver`: Majority of NH simulations in paper
- `ProfileAnalysis_PFTemplateObserver_HearingImpaired`: Majority of HI simulations in paper
- `ProfileAnalysis_PFTemplateObserver_WidebandControl`: Control for testing off-CF effects
- `ProfileAnalysis_PFTemplateObserver_PureToneControl`: Control for testing suppression

The following commands can be used to work with these types, assuming that the associated `Utilities` package is also loaded.
```
setup(exp)        # fetch all simulation objects, but don't run them 
status(exp)       # check which simulations are cached on file and which are not
run(exp)          # run all simulations
```

If one sets `sims = setup(exp)`, the following operations are useful:
```
id.(sims)         # fetch all simulation IDs
cachepath.(sims)  # fetch all simulation cache paths, assuming standard Config
```

Note that we have only discussed the "template-based" simulations! This is because we only
worry about generating and running the template-based simulations --- the other
"template-free" simulations are simply re-analysis of the data generated by the
template-based simulations, implemented via the disk-memoized caching system provided by
`Utilities`. 

### Running simulations
Simulations can be run as above using `run(exp)`, but practically we rarely do this directly.
Instead, we first set up an environment on CIRC's BlueHive and then run the simulations in a batch mode.
This is achieved by submitting `PFs_run.sh` using `sbatch`. 
This script uses ~30 worker processes for long stretches of time to run `PFs_run.jl`, a script that sets up each worker process' environemnt and simulates each of the above experiments.
The results of this process can be downloaded to local machies using the Julia function `synchronize_cache`.
These steps have not been tested on other platforms/setups, and so this code is not intended for use as a turn-key reproduction of the results of the paper — please contact the authors if you are serious about reproducing our results with this code and assistance can be provided!

## Figure workflow
Once simulations are run, figures can be generated by running `workflows/genfigs.jl`.
Some figure code generates multiple subfigures that are combined post hoc into single images in Inkscape.
The `.svg` files involved in this process are not included in this repository but are available upon request.
Figures 1–5 can be generated relatively quickly and do not rely on the large-scale simulations.
Later figures can only be generated after first running the large-scale simulations as described above.