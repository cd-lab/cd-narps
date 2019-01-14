# This script will create triplet tsvs to input as predictors in FSL glms

# for gains
lapply(Data, function(data) {sub <- unique(data$SubjID); 
                              data %>% 
                                select(onset, duration, gain) %>%
                                write_tsv(., paste(sub, "_gain", ".tsv", sep = ""))})

# for losses
lapply(Data, function(data) {sub <- unique(data$SubjID); 
                              data %>% 
                                select(onset, duration, loss) %>%
                                write_tsv(., paste(sub, "_loss", ".tsv", sep = ""))})