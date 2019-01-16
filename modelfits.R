library(tidyverse)
library(elasticnet)

###------- Logistic regression per subject -------
# Load the data
setwd('./event_tsvs')
files <- dir(pattern = "*events.tsv")
Data <- data_frame(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  mutate(gain = unlist(gain), # glmnet and enet want this to be a double
         loss = unlist(loss),
         response = gsub(".*_", "", participant_response),
         Choice = ifelse(response %in% "accept", 1, 0)) %>%
  filter(RT != 0,
         SubjID != "sub-048") %>%
  plyr::dlply("SubjID", identity)

# Get just the subject list and number of subjects
subjList <- unique(unlist(sapply(Data, "[[", "SubjID")))
nSubjs <- length(subjList)

# Perform a model fit
modelfits <- lapply(Data, function(data) glm(Choice ~ gain + loss, data = data, family = "binomial"))

# Get the coefficients
choiceCoeffs <- as.data.frame(t(sapply(modelfits, "[[", "coefficients")))
choiceCoeffs$ConvergenceIterations <- sapply(modelfits, function(x) {summary(x)$iter})
choiceCoeffs$R2 <- sapply(modelfits, function(x) {1 - (summary(x)$deviance / summary(x)$null.deviance)})
choiceCoeffs$aic <- sapply(modelfits, function(x) {summary(x)$aic})
choiceCoeffs$propAccept <- sapply(Data, function(data) {mean(data$Choice)})
choiceCoeffs$SubjID <- subjList # add subject list column to join the demographics by it below

# Let's attach participant demographics to the coefficient list
demographics <- read_tsv('participants.tsv', col_names = c("SubjID", "group", "gender", "age"), col_types = cols())
choiceCoeffs <- left_join(choiceCoeffs, demographics, by = "SubjID")

# Reorder columns so that Subject ID comes first
choiceCoeffs <- choiceCoeffs[, c(8,9,10,11,7,1,2,3,4,5,6)]

# simple plot
ggplot(data = choiceCoeffs, aes(gain, loss, fill = group)) +
  geom_point(aes(size = 1/ ConvergenceIterations), pch = 21, color = "black") + 
  geom_abline(intercept = 0, slope = -1, lty = 2) +
  geom_hline(yintercept = 0, lty = 2) +
  geom_vline(xintercept = 0, lty = 2) +
  labs(title = "Logistic regression betas for gain and losses per participant") +
  theme_classic()


###------- Proportion of actual responses -------
# reload the data so non-choices are included
Data2 <- data_frame(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
    unnest() %>%
    mutate(didRespond = ifelse(RT == 0, 0, 1)) %>%
    filter(SubjID != "sub-048") %>%
    plyr::dlply("SubjID", identity)

# Store the subject-id and proportion of responses
choiceCoeffs$propResponses <- sapply(Data2, function(data) {mean(data$didRespond)})

# check the distribution
par(mfrow = c(1,2))
hist(choiceCoeffs$propResponses)
hist(choiceCoeffs$propAccept)

# elastic net
glmnetFits <- lapply(Data, function(data) cv.glmnet(x = as.matrix(data[c("gain", "loss")]), y = as.factor(data$Choice), family = "binomial", alpha = 0))

# attach the resulting lambda.min coefficients to the overall coefficients list
temp <- lapply(glmnetFits, coef, s = "lambda.min")
temp <- as.matrix(t(do.call(cbind, temp)))
colnames(temp) <- c("intercept_L2", "gain_L2", "loss_L2")
choiceCoeffs <- cbind(choiceCoeffs, temp)
rm(temp)

# plot the regularized coefficients
ggplot(data = choiceCoeffs, aes(gain_L2, loss_L2, fill = group)) +
  geom_point(size = 4, pch = 21, color = "black") + 
  geom_abline(intercept = 0, slope = -1, lty = 2) +
  geom_hline(yintercept = 0, lty = 2) +
  geom_vline(xintercept = 0, lty = 2) +
  labs(title = "L2-regularized logistic regression betas for gain and losses per participant") +
  theme_classic()




