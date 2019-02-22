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
dimnames(cormats_mean) <- list(regressor_names, regressor_names)

# everyone's ranks
ranks <- sapply(Data, Matrix::rankMatrix)

# get the distributions of correlations among relevant predictors
gain_RT <- sapply(cormats, "[", 3, 2)
loss_RT <- sapply(cormats, "[", 4, 2)
gain_loss <- sapply(cormats, "[", 3, 4)

dists <- tibble(combo = rep(c("gain vs RT", "loss vs RT", "gain vs loss"), each = length(cormats)),
             correlation = c(gain_RT, loss_RT, gain_loss))

# plot
# distribution of correlations per predictor combo
ggplot(aes(correlation, color = combo, fill = combo), data = dists) + 
  geom_density(alpha = 0.3) +
  xlim(-1,1) +
  theme_classic()

# mean across participants
corrplot(cormats_mean, method = "color", outline = T)
