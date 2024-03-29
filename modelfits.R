library(tidyverse)
library(glmnet)
library(corrplot)

###------- Logistic regression per subject -------

setwd('./event_tsvs')

# Load demographics
demographics <- read_tsv('participants.tsv', col_names = c("SubjID", "group", "gender", "age"), col_types = cols())

# ps to remove
toRemove <- read_csv('../removedsubs.csv')

# Load the data
files <- dir(pattern = "*events.tsv")
Data <- tibble(SubjID = files) %>% 
  mutate(contents = map(SubjID, ~ read_tsv(., col_types = cols())),
         Run = substring(SubjID, 22, 23),
         SubjID = substring(SubjID, 1, 7)) %>%
  unnest() %>%
  mutate(gain = unlist(gain), # glmnet and enet want this to be a double
         loss = unlist(loss),
         response = gsub(".*_", "", participant_response),
         Choice = ifelse(response %in% "accept", 1, 0)) %>%
  filter(RT != 0,
         !(SubjID %in% toRemove$SubjID)) %>%
  left_join(demographics) %>%
  plyr::dlply("SubjID", identity)

# get a subject list
subjList <- unique(do.call(rbind, Data)$SubjID)

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
# and then get the final counts for each group
choiceCoeffs <- left_join(choiceCoeffs, demographics, by = "SubjID")
nSubjs_EI <- count(choiceCoeffs, group) %>% filter(group == "equalIndifference") %>% .$n
nSubjs_ER <- count(choiceCoeffs, group) %>% filter(group == "equalRange") %>% .$n

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
    filter(!(SubjID %in% toRemove$SubjID)) %>%
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
  scale_fill_discrete(labels = c("Equal Indifference", "Equal Range")) +
  labs(x = "Coefficient for Gains", y = "Coefficient for Losses", fill= "Group") +
  theme(legend.position = c(0.8, 0.8),
        legend.key = element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank(),
        axis.line = element_line(colour = "black"),
        text = element_text(size = 16))


###-------- Replicating the RT and proportion heatmaps ------
par(mfrow=c(2,2))
# first for RT
# equal indifference
RT_EI_mat <- matrix(0, ncol = 20, nrow = 40)

for (sub in Data) {
  if ("equalIndifference" %in% sub$group) {
    for (trial in seq(nrow(sub))) {
      RT_EI_mat[sub[trial, 5], sub[trial, 6]] <- RT_EI_mat[sub[trial, 5], sub[trial, 6]] + sub$RT[trial]
    }
  }
}

RT_EI_mat <- RT_EI_mat[seq(10,40, by = 2), 5:20] / nSubjs_EI
dimnames(RT_EI_mat) <- list(seq(10,40, by = 2), seq(5,20))

corrplot(RT_EI_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")


# equal range
RT_ER_mat <- matrix(0, ncol = 20, nrow = 20)

for (sub in Data) {
  if ("equalRange" %in% sub$group) {
    for (trial in seq(nrow(sub))) {
      RT_ER_mat[sub[trial, 5], sub[trial, 6]] <- RT_ER_mat[sub[trial, 5], sub[trial, 6]] + sub$RT[trial]
    }
  }
}

RT_ER_mat <- RT_ER_mat[seq(5,20), seq(5,20)] / nSubjs_ER
dimnames(RT_ER_mat) <- list(seq(5,20), seq(5,20))

corrplot(RT_ER_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")


# and now for proportions
# equal indifference
prop_EI_mat <- matrix(0, ncol = 20, nrow = 40)

for (sub in Data) {
  if ("equalIndifference" %in% sub$group) {
    for (trial in seq(nrow(sub))) {
      prop_EI_mat[sub[trial, 5], sub[trial, 6]] <- prop_EI_mat[sub[trial, 5], sub[trial, 6]] + sub$Choice[trial]
    }
  }
}

prop_EI_mat <- prop_EI_mat[seq(10,40, by = 2), 5:20] / nSubjs_EI
dimnames(prop_EI_mat) <- list(seq(10,40, by = 2), seq(5,20))

corrplot(prop_EI_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")


# equal range
prop_ER_mat <- matrix(0, ncol = 20, nrow = 20)

for (sub in Data) {
  if ("equalRange" %in% sub$group) {
    for (trial in seq(nrow(sub))) {
      prop_ER_mat[sub[trial, 5], sub[trial, 6]] <- prop_ER_mat[sub[trial, 5], sub[trial, 6]] + sub$Choice[trial]
    }
  }
}

prop_ER_mat <- prop_ER_mat[seq(5,20), seq(5,20)] / nSubjs_ER
dimnames(prop_ER_mat) <- list(seq(5,20), seq(5,20))

corrplot(prop_ER_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")



###-------- Indifference heatmaps ------
par(mfrow=c(1,2))
t1 <- do.call(rbind, Data) %>%
  filter(RT != 0) %>%
  left_join(choiceCoeffs[c('SubjID', 'intercept_L2', 'gain_L2', 'loss_L2')]) %>%
  mutate(probFit = exp(intercept_L2 + gain_L2*gain + loss_L2*loss) / (1 + exp(intercept_L2 + gain_L2*gain + loss_L2*loss))) %>%
  group_by(SubjID) %>%
  filter(probFit > 0.49 & probFit < 0.51)

prop_EI_mat <- matrix(0, ncol = 20, nrow = 40)

for (row in seq(nrow(t1))) {
  if (t1$group[row] == "equalIndifference") {
    gain <- as.numeric(t1[row, 5])
    loss <- as.numeric(t1[row, 6])
    prop_EI_mat[gain, loss] <- prop_EI_mat[gain, loss] + 1
  }
}

prop_EI_mat <- prop_EI_mat[seq(10,40, by = 2), 5:20] 
dimnames(prop_EI_mat) <- list(seq(10,40, by = 2), seq(5,20))

corrplot(prop_EI_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")


prop_ER_mat <- matrix(0, ncol = 20, nrow = 20)

for (row in seq(nrow(t1))) {
  if (t1$group[row] == "equalRange") {
    gain <- as.numeric(t1[row, 5])
    loss <- as.numeric(t1[row, 6])
    prop_ER_mat[gain, loss] <- prop_ER_mat[gain, loss] + 1
  }
}

prop_ER_mat <- prop_ER_mat[seq(5,20), seq(5,20)] 
dimnames(prop_ER_mat) <- list(seq(5,20), seq(5,20))

corrplot(prop_ER_mat,
         is.corr = F,
         method = "color",
         outline = T,
         tl.col = "black")









