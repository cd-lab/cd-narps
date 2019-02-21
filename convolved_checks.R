# this script will evaluate the convolved design matrices that AFNI (3ddeconvolve) produces per individual GLM
library(tidyverse)
library(corrplot)

# Load the data
files <- dir(pattern = "*.xmat.1D")
Data <- tibble(SubjID = files) %>% 
    mutate(contents = map(SubjID, ~ read.table(.)),
           SubjID = substring(SubjID, 15, 17)) %>%
  unnest() %>%
  plyr::dlply("SubjID", identity) %>%
  lapply("[", seq(22, 25))

# regressor names
regressor_names <- c("RT0", "RT1", "gain", "loss")

# individual correlation matirces
cormats <- map(Data, ~ cor(.x))

# mean of the correlation matrices
cormats_mean <- Reduce("+", cormats) / length(cormats)
dimnames(cormats_mean) <- list(regressNames, regressNames)

# everyone's ranks
ranks <- sapply(Data, Matrix::rankMatrix)

# plot
corrplot(cormats_mean, method = "color", outline = T)