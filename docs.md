# Profile analysis at high frequencies and in listeners with sensorineural hearing loss (Guest et al., 2023)

# Introduction

# Behavioral procedure
Behavior was conducted in the human testing space of the Carney lab (University of Rochester Medical Center, Rochester NY).
The primary experimenters were Evie Feld and David Cameron.

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
├── plots                    # Intermediate figure files, primary figure .svg files, etc.
├── src                      # Primary source directory
│   ├── experiments          # Private code for implementing and running various simulated experiments
│   ├── figures              # Private code for compiling simulated results into figures
│   └── ProfileAnalysis.jl   # Primary source file
├── workflows                # Folder containing various "workflows" (sequences of scripts)
│   ├── behavioral_data      # Public scripts for wrangling, plotting, and analyzing behavioral data
│   ├── simulations          # Public scripts for running simulated experiments
│   └── genfigs.jl           # Script for generating paper figures
├── docs.md                  # Documentation file for the entire repository
├── cfg.R                    # Short script to provide constants/configs shared across all R files
├── LICENSE                  # License file for the code contained in this repository
├── LICENSE_data             # [[TODO]] License file for the behavioral data contained in this repository
└── Project.toml             # Julia environment management file
```

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
1. Run `workflows\behavioral_data\04_postprocess_compiled_data.jl` to add additional useful columns to the behavioral data (e.g., levels in terms of sensational level)
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
- `ProfileAnalysis_PFTemplateObserver_WidebandControl`: Small control simulations for testing off-CF effects
- `ProfileAnalysis_PFTemplateObserver_PureToneControl`: Small control simulations for testing contributions of suppression

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