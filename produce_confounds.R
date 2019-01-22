# This script will extract BOLD confounds of interest and produce text files for each per subject
# Meant to work with FSL FEAT

library(tidyverse)

# setupds
fwdThresh <- 0.5

# confounds of interest (COI)
COI <- c("X", "Y", "Z", "RotX", "RotY", "RotZ", "GlobalSignal", "FramewiseDisplacement")
  
# load data
setwd('./event_tsvs')
files <- dir(pattern = "*bold_confounds.tsv")
confounds <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  filter(SubjID != "sub-048") %>%
  plyr::dlply("SubjID", identity)

toremove <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  group_by(SubjID) %>% 
  summarize(prcntFWD = mean(FramewiseDisplacement > fwdThresh)) %>%
  filter(prcntFWD > 0.05)

# write tsvs for each confound
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






