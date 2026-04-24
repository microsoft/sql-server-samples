################################################################
## Title: Data Science For Database Professionals
## Description:: Data Exploration
## Author: Microsoft
################################################################

####################################################################################################
##Compute context
####################################################################################################
connection_string <- "Driver=SQL Server;Server=.;Database=telcoedw2;Trusted_Connection=yes;"
sql <- RxInSqlServer(connectionString = connection_string, autoCleanup = FALSE, consoleOutput = TRUE)
local <- RxLocalParallel()
rxOptions(reportProgress = 0)

####################################################################################################
##Connect to the data
####################################################################################################
rxSetComputeContext(local)

##SQL data source
myDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr",
  colInfo = col_info)
rxGetInfo(myDataTb, getVarInfo = T, numRows = 3)

##Data frame
myData <- rxDataStep(myDataTb, overwrite = TRUE)
str(myData)

####################################################################################################
##Data exploration and visualization on the data frame myData
####################################################################################################

#pie chart of customer churn
library(ggplot2)
ggplot(data = myData,
       aes(x = factor(1), fill = churn)) +
       geom_bar(width = 1) +
       coord_polar(theta = "y")

#density plot of age
ggplot(data = myData,
       aes(x = age)) +
  geom_density(fill = "salmon",
               bw = "SJ",
               colour = NA) +
  geom_rug(colour = "salmon") +
  theme_minimal()

#boxplot of age by churn
ggplot(data = myData,
       aes(x = reorder(churn, - age),
           y = age,
           colour = churn)) +
  geom_boxplot() +
  labs(x = "churn",
       y = "age") +
  theme_minimal() +
  theme(legend.position = "none")

#density plot of annualincome
  ggplot(data = myData,
         aes(x = annualincome)) +
    geom_density(fill = "salmon",
                 bw = "SJ",
                 colour = NA) +
    geom_rug(colour = "salmon") +
    theme_minimal()

#boxplot of annualincome by churn
ggplot(data = myData,
       aes(x = reorder(churn, - annualincome),
           y = annualincome,
           colour = churn)) +
  geom_boxplot() +
  labs(x = "churn",
       y = "annualincome") +
  theme_minimal() +
  theme(legend.position = "none")

#impact of education level on churn
library(dplyr)
myData %>%
    group_by(month, education) %>%
    summarize(countofchurn = sum(as.numeric(churn))) %>%
    ggplot(aes(x = month,
               y = countofchurn,
               group = education,
               fill = education)) +
    geom_bar(stat = "identity", position = position_dodge()) +
    labs(x = "month",
         y = "Counts of churn") +
    theme_minimal()

#impact of callfailure rate (%) on churn
myData %>%
   group_by(month, callfailurerate) %>%
   summarize(countofchurn = sum(as.numeric(churn)) ) %>%
   ggplot(aes(x = month,
              y = countofchurn,
              group = factor(callfailurerate),
              fill = factor(callfailurerate))) +
  geom_bar(stat = "identity", position = position_dodge()) +
  labs(x = "month",
       y = "Counts of churn") +
  theme_minimal()

#count of customers by % callsoutsidenetwork
myData %>%
  group_by(percentagecalloutsidenetwork) %>%
  summarize(countofcustomer = length(unique(customerid))) %>%
  ggplot(aes(x = percentagecalloutsidenetwork,
             y = countofcustomer)) +
  geom_bar(stat = "identity", fill = "orange") +
  labs(x = "% callsoutsidenetwork",
       y = "Counts of Customerid") +
  theme_minimal()

#count of customers by calldroprate
myData %>%
  group_by(calldroprate) %>%
  summarize(countofcustomer = length(unique(customerid))) %>%
  ggplot(aes(x = calldroprate,
             y = countofcustomer)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  labs(x = "% calldroprate",
       y = "Counts of Customerid") +
  theme_minimal()

# Comparing the proportions of customer churn at individual state for several education levels
library(GGally)
  proportions <- myData %>%
    group_by(state, education) %>%
    summarise(countofchurn = sum(as.numeric(churn))) %>%
    ungroup() %>%
    group_by(state) %>%
    summarise(Prop_BA = sum(countofchurn[education == "Bachelor or equivalent"]) / sum(countofchurn),
              Prop_HS = sum(countofchurn[education == "High School or below"]) / sum(countofchurn),
              Prop_MA = sum(countofchurn[education == "Master or equivalent"]) / sum(countofchurn))

ggpairs(proportions, columns = 2:ncol(proportions)) + theme_bw()

####################################################################################################
##Data exploration and visualization on the SQL data source myDataTb
####################################################################################################
rxSetComputeContext(sql)

#Counts(Percentages) of customers churned or non-churned (Pareto Chart)
tmp <- rxCube( ~ churn, myDataTb, means = FALSE)
Results_df <- rxResultsDF(tmp)
library(qcc)
CountOfChurn <-
  setNames(as.numeric(Results_df[, 2]), Results_df[, 1])
par(oma = c(2, 2, 2, 2))
pareto <- pareto.chart(CountOfChurn,
                     xlab = "Churn", ylab = "Counts",
                     ylab2 = "Cumulative Percentage", cex.names = 0.5, las = 1,
                     col = heat.colors(length(CountOfChurn)), plot = TRUE)

#Counts of customer over age/annualincome by churn
rxHistogram( ~ age | churn, myDataTb)
rxHistogram(~ annualincome | churn, myDataTb)

#Counts of churned customer by age and state (Interactive HeatMap)
tmp <- rxCrossTabs(N(churn) ~ F(age):state, myDataTb, means = FALSE)
Results_df <- rxResultsDF(tmp, output = "sums")
colnames(Results_df) <- substring(colnames(Results_df), 7)
library(Rcpp)
library(d3heatmap)
d3heatmap(data.matrix(Results_df[, -1]), scale = "none", labRow = Results_df[, 1], dendrogram = "none",
          color = cm.colors(255))

