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
thresholds$include = thresholds$include == "true"

# Subset data
thresholds = thresholds[(thresholds$condition != "1000 Hz roved level") & (thresholds$include == TRUE), ]

# Fit lme model
mod = lmer(threshold ~ n_comp*freq*hl + (1|subj), data=thresholds)

# Evaluate with ANOVA
Anova(mod, test="F", type=3)

# Evaluate frequency simple main effect
t1 = testInteractions(
    mod, 
    pairwise="freq",
    adjustment="none",
    test="F",
)

# Evaluate interaction between frequency and hearing loss
t2 = testInteractions(
    mod, 
    slope="hl",
    fixed="freq",
    adjustment="none",
    test="F",
)
t3 = testInteractions(
    mod, 
    slope="hl",
    pairwise="freq",
    adjustment="none",
    test="F"
)[c(2, 4, 6), ]

# Evaluate interaction between hearing loss and n_comp
t4 = testInteractions(
    mod, 
    fixed=c("n_comp"), 
    slope="hl",
    adjustment="none",
    test="F"
)
t5_uncorrected = testInteractions(
    mod, 
    fixed=c("n_comp", "freq"), 
    slope="hl",
    adjustment="none",
    test="F"
)
t5 = t5[seq(from=1, to=25, by=5), ]

# Place all tests in list, extract pvals for correction
tests = list(t1, t2, t3, t4)
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
    tests[[idx_test]][(idx_low-n_tests_so_far):(idx_high-n_tests_so_far), "Pr(>F)"] = pvals[idx_low:idx_high]
    n_tests_so_far = n_tests_so_far + n_tests[idx_test]
}



