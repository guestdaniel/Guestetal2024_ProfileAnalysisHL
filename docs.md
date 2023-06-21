# Profile analysis in listeners with hearing impairment (Guest and Carney 20xx)

# Introduction

# Files and paths
## Behavioral data
Behavioral data are stored in the `data` folder.
Processed internal data is stored in `data\int_pro`.
The behavioral data are available in tidy format in a `.csv` file at `data\int_pro\data_postproc.csv`.
This file has the following columns:

Some processed *external* data are also available (from other studies of profile analyis, mostly Green lab work from the 80s/90s).
These are available in tidy format in a `.csv` file at `data\ext_pro\paper_fig.csv`, where paper is in `[Green1985, Bernstein1987, Lentz1999]` and figure is in `[Fig2, Fig3, Fig4]`. 
These files have the following columns:

## Computational/modeling data
```
.  
├── src                      # All "source" (i.e., non-script) code
│   ├── experiments          # source files for particular analyses/simulations
│   └── ...                  # primary source files  
```

## 2023 paper stuff
For the 2023 paper, the structure is something like this:
```
.  
├── figures                  # Code to generate figures
├── simulations              # Code to generate simulations 
└── README.md                # This README file
```

# Workflows

## Behavioral data workflow
Behavioral data for the profile-analysis experiments are stored on `\\nsc-lcarney-h1\C$`.
The workflow for updating behavioral data and preparing cleaned and pre-processed copies is described below.
There are two manual steps that involve interacting with the `\\nsc-lcarney-h1` machine.

1. First, remove any files/folders in `C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results` to ensure we have a clean slate for a local copy of the data.
2. Next, copy all files/folder from `\\nsc-lcarney-h1\C$\results\profile_analysis_iso_results` to `C:\Users\dguest2\cl_data\pahi\raw\profile_analysis_iso_results`

Next we have automated steps that preprocess, clean, and compile the data.
1. Run `workflows\behavioral_data\01_extract_data_mat_to_excel.m` to extract all data from the source `.mat` files to more accessible `.xlsx` files. Both `AuditoryStimulus` and `behavior_code` folders must be on the path (these folders contain various `.m` files needed to properly parse the contents of the `.mat` files containing the data).
2. Run `workflows\behavioral_data\02_convert_audiograms_to_csv.m` to convert the `.mat` file containing subject info and audiograms into a `.csv` file
3. Run `workflows\behavioral_data\03_compile_data.R` to compile raw block-wise data from `.xlsx` files into a single tidy format.

Next, we extract thresholds from the raw data in Julia and then analyze those thresholds in R.
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