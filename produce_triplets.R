# This script will create triplet tsvs to input as predictors in FSL glms

library(tidyverse)

# Load the data
setwd('./event_tsvs')
files <- dir(pattern = "sub*")
Data <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  mutate(response = gsub(".*_", "", participant_response),
         Choice = ifelse(response %in% "accept", 1, 0)) %>%
  filter(RT != 0,
         SubjID != "sub-048") %>%
  plyr::dlply("SubjID", identity)

# for gains
lapply(Data, function(data) {sub <- unique(data$SubjID); 
                              data %>% 
                                select(onset, duration, gain) %>%
                                write_tsv(., paste(sub, "_gain", ".tsv", sep = ""), col_names = F)})

# for losses
lapply(Data, function(data) {sub <- unique(data$SubjID); 
                              data %>% 
                                select(onset, duration, loss) %>%
                                write_tsv(., paste(sub, "_loss", ".tsv", sep = ""), col_names = F)})