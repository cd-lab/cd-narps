# This script will extract BOLD confounds of interest and produce text files for each per subject
# Meant to work with FSL FEAT

library(tidyverse)

# setups
fwdThresh <- 0.5
FSL <- FALSE
AFNI <- T
spread <- T

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

# for AFNI
if (AFNI) {
  for (data in confounds) {
    sub <- unique(data$SubjID)
    tdata <- data %>% select(COI, -FramewiseDisplacement)
    if ("FramewiseDisplacement" %in% COI) {
      nDisp <- which(data["FramewiseDisplacement"] > fwdThresh)
      for (i in nDisp[-1]) {
        vec <- rep(0, nrow(data))
        vec[c(i-1, i, i+1)] <- 1
        tdata <- cbind(tdata, vec)
        colnames(tdata)[ncol(tdata)] <- paste("FWD", i, sep = "")
      }
    }
    write_tsv(tdata, paste(sub, "_AFNI_confounds.tsv", sep = ""), col_names = F)
  }
}

# for AFNI with run-specific columns (as of 1/31/19)
if (AFNI & spread) {
  # function to generate the spread per variable
  sepRuns <- function(data, run) {
    data_frame(run, data) %>% 
      mutate(i = row_number()) %>%
      spread(run, data) %>%
      select(-i) %>%
      replace(., is.na(.), 0)
  }
  
  # iterate through subjects
  for (data in confounds) {
    sub <- unique(data$SubjID)
    run <- data$Run
    tdata <- data %>% select(COI, -FramewiseDisplacement)
    if ("FramewiseDisplacement" %in% COI) {
      nDisp <- which(data["FramewiseDisplacement"] > fwdThresh)
      for (i in nDisp[-1]) {
        vec <- rep(0, nrow(data))
        vec[c(i-1, i, i+1)] <- 1
        tdata <- cbind(tdata, vec)
        colnames(tdata)[ncol(tdata)] <- paste("FWD", i, sep = "")
      }
    }
    final <- do.call(cbind, apply(tdata, 2, sepRuns, run = run))
    write_tsv(final, paste(sub, "_AFNI_confounds_spread.tsv", sep = ""), col_names = F)
  }
}


















