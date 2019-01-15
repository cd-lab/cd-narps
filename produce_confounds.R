# This script will extract BOLD confounds of interest and produce text files for each per subject
# Meant to work with FSL FEAT

library(tidyverse)

# confounds of interest (COI)
COI <- c("X", "Y", "Z", "RotX", "RotY", "RotZ")
  
# load data
files <- dir(pattern = "*bold_confounds.tsv")
confounds <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  filter(SubjID != "sub-048") %>%
  plyr::dlply("SubjID", identity)

# write tsvs for each confound
lapply(confounds, function(data) {
  lapply(COI, function(coi) {
    sub <- unique(data$SubjID);
    write_tsv(data[coi], paste(sub, "_", coi, ".tsv", sep = ""), col_names = F)
})})






