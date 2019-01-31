# This script will create triplet tsvs to input as predictors in FSL glms

library(tidyverse)

# to do
# not only remove RT == 0 from gain, loss, etc., but create a new file with the removed trials (see 3dconvolve for afni)

# which file types to produce?
FSL <- FALSE
AFNI <- TRUE

# read the file with the noisy participants, so they are exluded
# note that the error produced by the lack of this file is on purpose. Run confounds script before this one.
toRemove <- read_csv('./event_tsvs/confounds/removedsubs.csv')

# Load the data
setwd('./event_tsvs')
files <- dir(pattern = "*events.tsv")
Data <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  mutate(response = gsub(".*_", "", participant_response),
         Choice = ifelse(response %in% "accept", 1, 0)) %>%
  filter(!(SubjID %in% toRemove$SubjID), !(RT < 0.2)) %>% # as of 1/31/19, remove all non-response trials
  plyr::dlply("SubjID", identity)

# FSL style
if (FSL) {
  # for gains
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  select(onset, duration, gain) %>%
                                  mutate(gain = round(scale(gain, center = T), digits = 3)) %>%
                                  write_tsv(., paste(sub, "_gain", ".tsv", sep = ""), col_names = F)})
  
  # for losses
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  select(onset, duration, loss) %>%
                                  mutate(loss = round(scale(loss, center = T), digits = 3)) %>%
                                  write_tsv(., paste(sub, "_loss", ".tsv", sep = ""), col_names = F)})
  
  # create a vector of 1's to modulate baseline activation
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  select(onset, duration) %>%
                                  mutate(baseline = rep(1, length(onset))) %>%
                                  write_tsv(., paste(sub, "_base", ".tsv", sep = ""), col_names = F)})
  
  # vector including all missed responses
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  mutate(noResp = ifelse(response == "NoResp", 1, 0)) %>%
                                  select(onset, duration, noResp) %>%
                                  write_tsv(., paste(sub, "_noResponse", ".tsv", sep = ""), col_names = F)})
  
  # for RTs
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  select(onset, duration, RT) %>%
                                  mutate(RT = round(scale(RT, center = T), digits = 3)) %>%
                                  write_tsv(., paste(sub, "_RT", ".tsv", sep = ""), col_names = F)})
}

# for AFNI
# afni automatically adds an intercept vector, so there is no need to create one
if (AFNI) {
  # for gains
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  mutate(gain = round(scale(gain, center = T, scale = F), digits = 3),
                                         towrite = paste(onset,"*", gain, sep = "")) %>%
                                  select(Run, towrite) %>%
                                  unstack(towrite~Run) %>% 
                                  lapply(., function(x) write.table(t(noquote(x)), 
                                                                    paste(sub, "_gain", "_AFNI.tsv", sep = ""), 
                                                                    append = T, 
                                                                    sep = '\t',
                                                                    col.names = F,
                                                                    row.names = F,
                                                                    quote = F))})
  
  # for losses
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  mutate(loss = round(scale(loss, center = T, scale = F), digits = 3),
                                         towrite = paste(onset,"*", loss, sep = "")) %>%
                                  select(Run, towrite) %>%
                                  unstack(towrite~Run) %>% 
                                  t() %>% 
                                  as.data.frame() %>%
                                  lapply(., function(x) write.table(t(noquote(x)), 
                                                                    paste(sub, "_loss", "_AFNI.tsv", sep = ""), 
                                                                    append = T, 
                                                                    sep = '\t',
                                                                    col.names = F,
                                                                    row.names = F,
                                                                    quote = F))})
  
  # vector including all missed responses
  # these can just be limited to the trials that showed no response + their onsets. Not a full vector. 
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  mutate(noResp = ifelse(response == "NoResp", 1, 0),
                                         towrite = paste(onset,"*", noResp, sep = "")) %>%
                                  select(Run, towrite) %>%
                                  unstack(towrite~Run) %>% 
                                  t() %>% 
                                  as.data.frame() %>%
                                  write_tsv(., paste(sub, "_noResponse", "_AFNI.tsv", sep = ""), col_names = F)})
  
  # for RTs
  lapply(Data, function(data) {sub <- unique(data$SubjID); 
                                data %>% 
                                  mutate(RT = round(scale(RT, center = T, scale = F), digits = 3),
                                         towrite = paste(onset,"*", RT, sep = "")) %>%
                                  select(Run, towrite) %>%
                                  unstack(towrite~Run) %>% 
                                  t() %>% 
                                  as.data.frame() %>%
                                  lapply(., function(x) write.table(t(noquote(x)), 
                                                                    paste(sub, "_RT", "_AFNI.tsv", sep = ""), 
                                                                    append = T, 
                                                                    sep = '\t',
                                                                    col.names = F,
                                                                    row.names = F,
                                                                    quote = F))})
}







