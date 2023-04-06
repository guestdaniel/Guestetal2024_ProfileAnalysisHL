library(dplyr)
library(tidyr)
library(optimr)

source("~/cl_code/pahi/cfg.R")
data = read.csv(file.path(dir_data_clean, "pahi1.csv"))

# Functions for psychometric function fitting
logistic <- function(x, threshold, slope, min, max) {
  return(min + (max - min) / (1 + exp(-slope * (x - threshold))))
}

loss <- function(theta, x, y) {
  mean((y - logistic(x, theta[1], exp(theta[2]), 0.5, 1.0)) ^ 2)
}

fit <- function(x, y) {
  pars = optimr(c(0.0, 1.0), function(theta) loss(theta, x, y), method="L-BFGS-B", lower=c(-25.0, log(0.01)), upper=c(25.0, log(1.0)))$par
  return(pars)
}

# Do threshold fitting at group-average level
temp = data %>%
  # We want at least three pcorr estimates to average over
  filter(n() > 3) %>%
  group_by(freq, n_comp, delta_l, rove) %>%
  summarize(stderr = sd(pcorr) / sqrt(n()), pcorr = mean(pcorr)) %>%
  # Fit psychometric functions (threshold and slope)
  group_by(freq, n_comp, rove) %>%
  summarize(threshold = fit(delta_l, pcorr)[1], slope = fit(delta_l, pcorr)[2])
write.csv(temp, file.path(dir_data_clean, "pahi_group_avg_thresholds.csv"))

# Do threshold fitting at individual level
temp = data %>%
  group_by(freq, n_comp, delta_l, rove, subj) %>%
  summarize(stderr = sd(pcorr) / sqrt(n()), pcorr = mean(pcorr)) %>%
  # Fit psychometric functions (threshold and slope)
  group_by(freq, n_comp, rove, subj) %>%
  summarize(threshold = fit(delta_l, pcorr)[1], slope = fit(delta_l, pcorr)[2])
write.csv(temp, file.path(dir_data_clean, "pahi_ind_thresholds.csv"))

# Do threshold fitting at individual level run level
temp = data %>%
  group_by(freq, n_comp, delta_l, rove, subj, file_index) %>%
  summarize(stderr = sd(pcorr) / sqrt(n()), pcorr = mean(pcorr)) %>%
  # Fit psychometric functions (threshold and slope)
  group_by(freq, n_comp, rove, subj, file_index) %>%
  summarize(threshold = fit(delta_l, pcorr)[1], slope = fit(delta_l, pcorr)[2])
write.csv(temp, file.path(dir_data_clean, "pahi_ind_rep_thresholds.csv"))
