# This script will extract BOLD confounds of interest and produce text files for each per subject
# Meant to work with FSL FEAT

library(tidyverse)

# setups
fwdThresh <- 0.5
FSL <- FALSE
AFNI <- T

# confounds of interest (COI)
COI <- c("X", 
         "Y",
         "Z", 
         "RotX", 
         "RotY", 
         "RotZ", 
         #"GlobalSignal", 
         "FramewiseDisplacement", 
         "aCompCor00", 
         "aCompCor01", 
         "aCompCor02", 
         "aCompCor03", 
         "aCompCor04", 
         "aCompCor05")
  
# load data and identify noisy participants
setwd('./event_tsvs/confounds/')
files <- dir(pattern = "*bold_confounds.tsv")
toRemove <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  group_by(SubjID) %>% 
  summarize(prcntFWD = mean(FramewiseDisplacement > fwdThresh)) %>%
  filter(prcntFWD > 0.05) %>%
  rbind(c("sub-048", NA)) %>% # append sub 48, since it has missing data
  rbind(c("sub-056", NA)) # and 56 for having weird gain-loss coefficients

# write to csv for further reference
# write_csv(toRemove, "removedsubs.csv")

# load data and filter out noisy participants
confounds <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  filter(!(SubjID %in% toRemove$SubjID)) %>% 
  plyr::dlply("SubjID", identity)

# write tsvs for each confound for each surviving participant

# for FSL
if (FSL) {
  lapply(confounds, function(data) {
    lapply(COI, function(coi) {
      sub <- unique(data$SubjID);
      if (coi == "FramewiseDisplacement") { # individual vectors produced for larger FWDs, so variance is captured individually
        nDisplacements <- which(data[coi] > fwdThresh);
        for (i in nDisplacements) {
          if (i > 1) { # fwd adds n/a to the first volume, which gets caught in nDispl. So always skip it
            vec <- rep(0, nrow(data));
            vec[c(i-1, i, i+1)] <- 1;
            vec[1] <- 0; # otherwise it's na
            write.table(vec, 
                        file = paste(sub, "_", coi, "_", i, ".tsv", sep = ""), 
                        quote=FALSE, 
                        sep='\t', 
                        col.names = F,
                        row.names = F)
          }
        }
      } else {
        write_tsv(data[coi], paste(sub, "_", coi, ".tsv", sep = ""), col_names = F)
      }
  })})
}

# for AFNI with run-specific columns (as of 1/31/19)
if (AFNI) {
  # function to generate the spread per variable
  sepRuns <- function(data, run) {
    data_frame(run, data) %>% 
      mutate(i = row_number()) %>%
      spread(run, data) %>%
      select(-i) %>%
      replace(., is.na(.), 0)
  }
  
  # iterate through subjects and collect most confounds
  for (data in confounds) {
    sub <- unique(data$SubjID)
    run <- data$Run
    tdata <- data %>% select(COI, -FramewiseDisplacement)
    final <- do.call(cbind, apply(tdata, 2, sepRuns, run = run))
    #final <- do.call(cbind, apply(tdata, 2, sepRuns, run = run))
    write_tsv(final, paste(sub, "_AFNI_confounds_spread.tsv", sep = ""), col_names = F)
  }
  
  # and then write a separate vector of FWD values to be censored (censor = 0)
  if ("FramewiseDisplacement" %in% COI) {
    do.call(rbind, confounds) %>%
      group_by(SubjID, Run) %>%
      mutate(FWD = ifelse(FramewiseDisplacement > fwdThresh, 0, 1),
             FWD = FWD * c(rep(0,3), rep(1, length(FWD) - 3))) %>% # create the FWD thresholded vector, then multiply the first 3 volumes by 0
      group_by(SubjID) %>% 
      do(write_tsv(as.data.frame(.$FWD), paste(unique(.$SubjID), "AFNI_FWD.tsv", sep = ""), col_names = F))
  }
}


















