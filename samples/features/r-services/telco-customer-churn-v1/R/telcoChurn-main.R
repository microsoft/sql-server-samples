####################################################################################################
## Title: Telco Customer Churn
## Description: Main R file driving the demo execution
## Author: Microsoft
####################################################################################################

####################################################################################################
## Settings
# In order to run this script, you need to set the values of the parameters in this section to your
# own values.
####################################################################################################

## SQL database and login credentials. Please change this part to your own values.
## If you are using Windows Authentication, "user" and "password" are not needed.
## if you are using Windows Authentication, change authenticationFlag to "Windows"
authenticationFlag <- "SQL" #Valid values: "Windows" or "SQL"
servername <- "."
database <- "telcoedw"
user <- "sa"
password <- "" #Please set your own password

## Set working directory. Please change this to the main directory of the demo
wd <- "C:\\Demo\\TelcoChurn4\\TelcoChurn4"

####################################################################################################	
## Source function scripts
####################################################################################################
source(file.path(wd, "R", "telcoChurn-setUp.R"))
source(file.path(wd, "R", "telcoChurn-evaluate.R"))
source(file.path(wd, "R", "telcoChurn-dataExploration.R"))
source(file.path(wd, "R", "telcoChurn-dataPreparation.R"))
source(file.path(wd, "R", "telcoChurn-trainModel.R"))

####################################################################################################	
## Set up SQL server compute context
# This part just configure the sql compute context. We are still in the default local compute context.
# We will swtich to SQL compute context after loading data into SQL tables.
####################################################################################################
if (authenticationFlag == "Windows") {
    sqlConnString <- paste("Driver=SQL Server;Server=", servername, ";Database=", database, ";trusted_connection=true", sep = "")
} else if (authenticationFlag == "SQL") { sqlConnString <- paste("Driver=SQL Server;Server=", servername, ";Database=", database, ";Uid=", user, ";Pwd=", password, sep = "") }

sqlCompute <- RxInSqlServer(connectionString = sqlConnString)

sqlSettings <- vector("list")
sqlSettings$connString <- sqlConnString

####################################################################################################
## Load data into SQL tables
####################################################################################################
rxSetComputeContext('local')
cdrTable <- "edw_cdr"

cdrFile <- RxTextData(file.path(wd, "Data", "edw_cdr.csv"))

cdrColInfo <- list(age = list(type = "integer"),
                 annualincome = list(type = "integer"),
                 calldroprate = list(type = "numeric"),
                 callfailurerate = list(type = "numeric"),
                 callingnum = list(type = "numeric"),
                 customerid = list(type = "integer"),
                 customersuspended = list(type = "factor", levels = c("No", "Yes")),
                 education = list(type = "factor", levels = c("Bachelor or equivalent", "High School or below", "Master or equivalent", "PhD or equivalent")),
                 gender = list(type = "factor", levels = c("Female", "Male")),
                 homeowner = list(type = "factor", levels = c("No", "Yes")),
                 maritalstatus = list(type = "factor", levels = c("Married", "Single")),
                 monthlybilledamount = list(type = "integer"),
                 noadditionallines = list(type = "factor", levels = c("\\N")),
                 numberofcomplaints = list(type = "factor", levels = as.character(0:3)),
                 numberofmonthunpaid = list(type = "factor", levels = as.character(0:7)),
                 numdayscontractequipmentplanexpiring = list(type = "integer"),
                 occupation = list(type = "factor", levels = c("Non-technology Related Job", "Others", "Technology Related Job")),
                 penaltytoswitch = list(type = "integer"),
                 state = list(type = "factor"),
                 totalminsusedinlastmonth = list(type = "integer"),
                 unpaidbalance = list(type = "integer"),
                 usesinternetservice = list(type = "factor", levels = c("No", "Yes")),
                 usesvoiceservice = list(type = "factor", levels = c("No", "Yes")),
                 percentagecalloutsidenetwork = list(type = "numeric"),
                 totalcallduration = list(type = "integer"),
                 avgcallduration = list(type = "integer"),
                 churn = list(type = "factor", levels = as.character(0:1)),
                 year = list(type = "factor", levels = as.character(2015)),
                 month = list(type = "factor", levels = as.character(1:3)))

cdrSQL <- RxSqlServerData(table = cdrTable,
                          connectionString = sqlConnString,
                          colInfo = cdrColInfo)

rxDataStep(inData = cdrFile, outFile = cdrSQL, overwrite = TRUE)

## View raw data information
rxGetInfo(data = cdrSQL, getVarInfo = TRUE)

####################################################################################################
## Data exploration and visualization
####################################################################################################
shinyApp(ui, server)

####################################################################################################
## Data preparation and feature engineering
####################################################################################################

## SQL table names
inputTable <- cdrTable
trainTable <- "edw_cdr_train"
testTable <- "edw_cdr_test"
predTable <- "edw_cdr_pred"

## Data preparation.
# We now delete unnecessary columns, clean missing values, remove duplicate rows,
# but more importantly, split the raw data into training and testing data sets followed by SMOTE.
system.time({
    dataPreparation(sqlSettings, trainTable, testTable)
})

## View the number of churn events in training and testing data sets.
trainDataSQL <- RxSqlServerData(connectionString = sqlConnString,
                                   table = trainTable,
                                   colInfo = cdrColInfo)
testDataSQL <- RxSqlServerData(connectionString = sqlConnString,
                                   table = testTable,
                                   colInfo = cdrColInfo)
rxGetInfo(trainDataSQL, getVarInfo = T)
rxGetInfo(testDataSQL, getVarInfo = T)
rxSummary( ~ churn, data = trainDataSQL)
rxSummary( ~ churn, data = testDataSQL)

####################################################################################################	
## Train model
####################################################################################################
## Switch to sql compute context.
# From now on, all the executions will be done in the SQL server
rxSetComputeContext(sqlCompute)

## Train Decision Forest model with rxDForest
system.time({
    trainModel(sqlSettings, trainTable)
})

## View model results
rx_forest_model
plot(rx_forest_model)
rxVarImpPlot(rx_forest_model)

####################################################################################################
## Score model
####################################################################################################
## Switch to local compute context.
rxSetComputeContext('local')

## Transform the test data set into a data frame
testDF <- rxDataStep(inData = testDataSQL)

## Score model
predictions <- rxPredict(modelObject = rx_forest_model,
                         data = testDF,
                         type = "prob",
                         overwrite = TRUE)
threshold <- 0.5
predictions$X0_prob <- NULL
predictions$churn_Pred <- NULL
names(predictions) <- c("Forest_Probability")
predictions$Forest_Prediction <- ifelse(predictions$Forest_Probability > threshold, 1, 0)
predictions$Forest_Prediction <- factor(predictions$Forest_Prediction, levels = c(1, 0))
predDF <- cbind(testDF[, c("customerid", "churn")], predictions)
head(predDF)

####################################################################################################
## Evaluate model
####################################################################################################
## Visualize confusion matrix
tmp <- rxCube( ~ churn:Forest_Prediction, data = predDF, mean = FALSE)
resultsDF <- rxResultsDF(tmp)
resultsDF %>%
  ggplot(aes(x = churn, y = Counts,
             group = Forest_Prediction, fill = Forest_Prediction)) +
  geom_bar(stat = "identity") +
  labs(x = "churn", y = "Counts of customer") +
theme_minimal()

## Generate model performance metrics
rx_forest_metrics <- evaluateModel(data = predDF,
                                    observed = "churn",
                                    predicted = "Forest_Prediction")
rx_forest_metrics

## Draw roc curve
rxrocCurve(data = predDF,
         observed = "churn",
         predicted = "Forest_Probability")




