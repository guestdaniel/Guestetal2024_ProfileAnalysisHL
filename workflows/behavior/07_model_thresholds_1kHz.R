# 07_model_thresholds_1kHz.R
#
# Fits a linear mixed-effects model to threshold data from the profile-analyis experiment
# only in the 1-kHz condition.

# Load packages and configuration files
source("cfg.R")
library(lme4)
library(ggplot2)
library(dplyr)
library(effects)
library(phia)

# Load fitted thresholds from CSV
thresholds = as.data.frame(read.csv(file.path(dir_data_clean, "thresholds.csv")))

# Convert relevant columns to factors
thresholds$n_comp = factor(thresholds$n_comp)
thresholds$condition = factor(thresholds$condition)
thresholds$freq = factor(thresholds$freq)

# Subset data
thresholds = thresholds[thresholds$freq == "1000", ]

# Fit lme model
mod = lmer(threshold ~ n_comp*rove*hl + (1|subj), data=thresholds)

# Evaluate with ANOVA
Anova(mod, test="F")

# Evaluate marginal means with phia
plot(interactionMeans(mod, covariates=c(hl=-10.0)))
plot(interactionMeans(mod, covariates=c(hl=0.0)))
plot(interactionMeans(mod, covariates=c(hl=10.0)))
plot(interactionMeans(mod, covariates=c(hl=20.0)))

# Evaluate slopes with phia
plot(interactionMeans(mod, slope="hl"))

# Evaluate significance of rove simple main effect @ mean HL
t1 = testInteractions(
    mod, 
    pairwise="rove", 
    adjustment="none",
    test="F"
)

# Evaluate significance of component spacing simple main effect @ mean HL
t2 = testInteractions(
    mod, 
    pairwise="n_comp", 
    fixed="rove", 
    adjustment="none",
    test="F"
)

# Significant n_comp:rove, so we want to test effect of rove as function of n_comp @ mean HL
t3 = testInteractions(
    mod, 
    pairwise="rove", 
    fixed="n_comp",
    adjustment="none",
    test="F"
)
t4 = testInteractions(
    mod, 
    pairwise=c("rove", "n_comp"), 
    adjustment="none",
    test="F"
)

# Significant n_comp:hl interaction, so evaluate significance of HL slope in each n_comp
t5 = testInteractions(
    mod, 
    fixed="n_comp", 
    slope="hl",
    adjustment="none",
    test="F"
)
t6 = testInteractions(
    mod, 
    pairwise="n_comp", 
    slope="hl",
    adjustment="none",
    test="F"
)[5:7, ]

# Place all tests in list, extract pvals for correction
tests = list(t1, t2, t3, t4, t5, t6)
pvals = c()
n_tests = c()
for (idx_test in seq_along(tests)) {
    # Determine the number of subtests in this test
    n_test = nrow(tests[[idx_test]]) - 1
    n_tests = c(n_tests, n_test)

    # Extract pvals and store
    pvals = c(pvals, tests[[idx_test]][1:n_test, "Pr(>F)"])
}

# Jointly correct pvalues
pvals = p.adjust(pvals, method="holm")

# Replace uncorrected pvalues
n_tests_so_far = 0
for (idx_test in seq_along(tests)) {
    # Determine indices
    idx_low = n_tests_so_far + 1
    idx_high = n_tests_so_far + n_tests[idx_test]
    tests[[idx_test]][idx_low:idx_high, "Pr(>F)"] = pvals[idx_low:idx_high]
    n_tests_so_far = n_tests_so_far + n_tests[idx_test]
}
