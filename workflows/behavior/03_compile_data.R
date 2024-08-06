source("cfg.R")
library(openxlsx)
library(stringr)

# Build paths
dir_in = file.path(dir_data_raw, "profile_analysis_iso_results")
dir_out = file.path(dir_data_clean)

# Gather subject IDs from data folder
subj_ids = list.files(dir_in)
subj_ids = subj_ids[grepl("S\\d{3}", subj_ids)]

# Filter subject IDs
subj_ids = subj_ids[subj_ids != "S000"]  # test subject, not real
subj_ids = subj_ids[subj_ids != "S192"]  # does not have 3 full runs for each condition

# Pull subject audiogram data
audiograms = read.csv(file.path(dir_data_clean, "audiometry.csv"))
audiograms[audiograms$Subject == "S98", "Subject"] = "S098"

# Loop through each subject and extract data
data_clean = data.frame()
for (subj in subj_ids) {
  for (rove in c("unroved", "roved")) {
    # Get list of all xlsx files
    if (rove == "unroved") {
      data_files = list.files(file.path(dir_in, subj), ".xlsx")
    } else {
      data_files = list.files(file.path(dir_in, subj, "rove"), ".xlsx")
    }
    # Filter out datafiles that don't terminate in a _#
    data_files = data_files[str_detect(data_files, "([\\s\\S]+)_\\d\\.xlsx")]
    # Loop through each xlsx file and extract data
    for (idx_file in seq_along(data_files)) {
      # Get file
      file = data_files[idx_file]
      # Extract sound level and other parameters from xlsx title
      freq_string = strsplit(file, "_")[[1]][2]
      freq = as.numeric(substr(freq_string, 2, nchar(freq_string)))
      level_string = strsplit(file, "_")[[1]][3]
      level = as.numeric(substr(level_string, 1, 2))
      index_string = strsplit(file, "_")[[1]][4]
      file_index = as.numeric(substr(index_string, 1, 1))
      if (rove == "unroved") {
        data = read.xlsx(file.path(dir_in, subj, file))
      } else {
        data = read.xlsx(file.path(dir_in, subj, "rove", file))
      }
      # Extract data from file
      delta_ls = data[, 1]
      n_comps = as.numeric(colnames(data)[2:ncol(data)])
      # Pull audiogram data
      audio_data = audiograms[audiograms$Subject == subj, 2:12]
      for (idx_delta_l in seq_along(delta_ls)) {
        # Join existing data with newly extracted data
        data_clean = rbind(
          data_clean,
          data.frame(
          freq = freq,
          level = level,
          subj = subj,
          delta_l = delta_ls[idx_delta_l],
          n_comp = n_comps,
          pcorr = as.numeric(data[idx_delta_l, 2:ncol(data)]),
          rove = rove,
          file_index = file_index,
          audio_data
          )
        )
      }
    }
  }
}

# Filter out roved data from non 1 kHz runs
data_clean = data_clean[!(data_clean$rove == "roved" & data_clean$freq == 500.0), ]
data_clean = data_clean[!(data_clean$rove == "roved" & data_clean$freq == 2000.0), ]
data_clean = data_clean[!(data_clean$rove == "roved" & data_clean$freq == 4000.0), ]

# Remove nans
data_clean = data_clean[!is.na(data_clean$pcorr), ]

# Factorize file index
data_clean$file_index = as.factor(data_clean$file_index)

# Add HL at each frequency
for (i in seq_len(nrow(data_clean))) {
  data_clean[i, "hl"] = data_clean[i, paste0("F", as.character(data_clean[i, "freq"]))]
  data_clean[i, "pta_all"] = mean(as.numeric(data_clean[i, 11:19]))
  data_clean[i, "pta_3"] = mean(as.numeric(data_clean[i, 12:14]))
  data_clean[i, "pta_4"] = mean(as.numeric(data_clean[i, 12:15]))
}

# Save output
write.csv(data_clean, file=file.path(dir_out, "data.csv"))
