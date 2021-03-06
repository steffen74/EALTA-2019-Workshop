####################################################
#Setting Working Directory
setwd("C:/Users/Steffen/Arbeit/190528_ELATA Workshop/EALTA-2019-Workshop")

####################################################
# Import
####################################################
# Functions
library(psych)
library(ggplot2)
library(TAM)

# Data
load("PISA_2015_GERMANY.Rda")

####################################################
# Prepare Data
####################################################
# Function to retrieve all variable names in the data table
names(PISA_2015_GERMANY)

# Rename gender variable
PISA_2015_GERMANY <- PISA_2015_GERMANY %>%
  rename(gender=ST004D01T)

# Contruct data table with only the items from the reading assessment
resp <- PISA_2015_GERMANY[c("CR055Q01S","DR055Q02C","DR055Q03C","DR055Q05C","CR104Q01S","CR104Q02S", 
                            "CR104Q05S","CR111Q01S","DR111Q02BC","DR111Q06C","CR227Q01S","CR227Q02S",
                            "DR227Q03C","DR227Q06C")]

# Recoding missing values to 0 score
resp[is.na(resp)] <- 0

# Construction of a dichotomous dataset
resp_d <- resp
resp_d[resp_d==2] <- 1

####################################################
# Explore Data
####################################################
describe(resp)
describe(resp_d)

table(PISA_2015_GERMANY$HISCED, useNA = "always")

ggplot(PISA_2015_GERMANY) +
  geom_histogram(aes(x=EAPREAD))

####################################################
# Unidimensional Model
####################################################
mod <- tam.mml(resp=resp)
summary(mod)


####################################################
# Revision of Item Characteristics
####################################################

# Point-biserial correlatio
wle <- tam.wle(mod)
tam.ctt(resp, wlescore=wle$theta)

#ICCS
plot(mod)

# Gender DIF
mod_dif_d <- tam.mml.mfr(resp=resp_d, facets=PISA_2015_GERMANY, formulaA=~item+gender+item*gender)
summary(mod_dif_d)

# Gender DIF for partial credit tests

# data table including your DIF variable 
facets <- as.data.frame(PISA_2015_GERMANY)
# data table including your response data set
resp <- resp
# DIF formula including name of your DIF variable
formulaA=~item*step + item*gender

#######
#DO NOT CHANGE HERE
# create design matrices
des2 <- designMatrices.mfr2( resp=resp, facets=facets, formulaA=formulaA)
# restructured data set: pseudoitem=item x DIF group
resp2 <- des2$gresp$gresp.noStep
# A design matrix
A <- des2$A$A.3d
# redundant xsi parameters must be eliminated from design matrix
xsi.elim <- des2$xsi.elim
A <- A[,, - xsi.elim[,2] ]
# extract loading matrix B
B <- des2$B$B.3d
#######

# estimate model
mod_dif_pc <- tam.mml(resp=resp2, A=A, B=B, control=list(maxiter=100) )
summary(mod_dif_pc)


# Calculate Cronbachs Alpha
cronbach <- psych::alpha(resp)
cronbach$total$raw_alpha


####################################################
# Revision of Person Characteristics
####################################################

ggplot(PISA_2015_GERMANY) +
  geom_point(aes(x=mod$person$EAP, y=wle$theta ))+
  theme_bw() +
  xlab("EAP") +
  ylab("WLE")

ggplot(PISA_2015_GERMANY) +
  geom_point(aes(x=mod$person$score, y=wle$theta ))+
  theme_bw() +
  xlab("Sum Score") +
  ylab("WLE")

####################################################
# Estimation of a Model with Regression Data
####################################################

# Preparation of the regression data
Y <- as_tibble(dummy.code(PISA_2015_GERMANY$gender))  %>%
  select(-1)
mod_reg <- tam(resp, Y=Y)
summary(mod_reg)

# EAP vs. EAP With regression
ggplot(PISA_2015_GERMANY) +
  geom_point(aes(x=mod_reg$person$EAP, y=mod$person$EAP)) +
  theme_bw() +
  xlim(c(-5,5)) + ylim(c(-5,5)) +
  xlab("EAP With Regression") + ylab("EAP")
ggsave("EAP_vs_EAP-regression.png")

# WLE vs. WLE with regression 
ggplot(PISA_2015_GERMANY) +
  geom_point(aes(x=tam.wle(mod_reg)$theta, y=wle$theta)) +
  theme_bw() +
  xlim(c(-5,5)) + ylim(c(-5,5)) +
  xlab("WLE With Regression") + ylab("WLE")
ggsave("WLE_vs_WLE-regression.png")


##########################################
# Comparison of PV results with and without regression
##########################################

gender_mean <- pv %>%
  group_by(PISA_2015_GERMANY$gender) %>%
  summarize(mean(PV1.Dim1), mean(PV2.Dim1), mean(PV3.Dim1), mean(PV4.Dim1), mean(PV5.Dim1))
diff(rowMeans(select(gender_mean, -1)))

pv_reg <- tam.pv(mod_reg)$pv
gender_mean_reg <- pv_reg %>%
  group_by(PISA_2015_GERMANY$gender) %>%
  summarize(mean(PV1.Dim1), mean(PV2.Dim1), mean(PV3.Dim1), mean(PV4.Dim1), mean(PV5.Dim1))
rowMeans(select(gender_mean_reg, -1))
diff(rowMeans(select(gender_mean_reg, -1)))


##########################################
# Model Estimation (Multidimensional)
##########################################

# Definition of loading (Q) matrix
Q <- array( 0 , dim = c( ncol(resp) , 4 ))
Q[1:4,1] <- 1
Q[5:7,2] <- 1
Q[8:10,3] <- 1
Q[11:14,4] <- 1
m_mod <- tam(resp, Q=Q, control=list(snodes=2000, maxiter=50))


