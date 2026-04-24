################################################################
## Title: Data Science For Database Professionals
## Description: Data Preparation
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
##Method 1: Prepare the raw, training and testing data sets all in SQL database
####################################################################################################
col_info <- list(age = list(type = "integer"),
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


myDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr",
  colInfo = col_info)
rxDataStep(inData = myDataTb, outFile = myDataTb, overwrite = TRUE)

trainDataTb <- RxSqlServerData(
    connectionString = connection_string,
    table = "edw_cdr_train",
    colInfo = col_info)
rxDataStep(inData = trainDataTb, outFile = trainDataTb, overwrite = TRUE)

testDataTb <- RxSqlServerData(
    connectionString = connection_string,
    table = "edw_cdr_test",
    colInfo = col_info)
rxDataStep(inData = testDataTb, outFile = testDataTb, overwrite = TRUE)


####################################################################################################
##Method 2: Prepare the training and testing data sets by feature engineering and spliting on raw data
####################################################################################################
rxSetComputeContext(local)

##SQL data source
myDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr",
  colInfo = col_info)
rxGetInfo(myDataTb, getVarInfo = T, numRows = =3)

####################################################################################################
## Project Columns-exclude columns: year and month
## Metadata Editor-change column headers (no difference with original headers)
## Metadata Editor-change column types
####################################################################################################
rxSetComputeContext(local)
myVars <- rxGetVarNames(myDataTb)
myVars <- myVars[!myVars %in% c("year", "month")]
myVars <- paste(myVars, collapse = ", ")
sql_query <- paste("select", myVars, "from edw_cdr")
col_info <- list(age = list(type = "integer"),
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
                numberofcomplaints = list(type = "integer"),
                numberofmonthunpaid = list(type = "integer"),
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
                churn = list(type = "factor", levels = c("1", "0")))

projectedMetaedData <- RxSqlServerData(sqlQuery = sql_query,
                               connectionString = connection_string,
                               colInfo = col_info)
rxGetInfo(projectedMetaedData, getVarInfo = T, numRows = 3)

####################################################################################################
## Clean Missing Data (no missing)
## Remove Duplicate Rows
####################################################################################################
cleanedData <- rxDataStep(inData = projectedMetaedData,
                              removeMissings = TRUE,
                              overwrite = TRUE)

rxGetInfo(cleanedData, getVarInfo = T)

cleanedUnduplicatedData <- cleanedData[!duplicated(cleanedData),]

rxGetInfo(cleanedUnduplicatedData, getVarInfo = T)

####################################################################################################
## Split Data
####################################################################################################
set.seed(1234)
splitFiles <- rxSplit(inData = cleanedUnduplicatedData,
                       outFilesBase = "trainTestData",
                       splitByFactor = "ind",
                       transforms = list(ind = factor(
                         sample(0:1, size = .rxNumRows, replace = TRUE, prob = c(0.3, 0.7)),
                         levels = 0:1, labels = c("Test", "Train"))),
                        overwrite = TRUE)
names(splitFiles)
trainFile <- splitFiles[[2]]
testFile <- splitFiles[[1]]
rxGetInfo(trainFile)$numRows
rxGetInfo(testFile)$numRows
rxGetVarInfo(trainFile)

####################################################################################################
## SMOTE on training data (using OSR)
####################################################################################################
trainData <- rxXdfToDataFrame(file = trainFile, varsToDrop = c("ind"))
testData <- rxXdfToDataFrame(file = testFile, varsToDrop = c("ind"))
table(trainData$churn)
table(testData$churn)

library(unbalanced)
myvars <- names(trainData) %in% c("churn")
SMOTEData <- ubSMOTE(X = trainData[!myvars], Y = trainData$churn, perc.over = 200, k = 3, perc.under = 500, verbose = TRUE)
newSMOTEData <- cbind(SMOTEData$X, SMOTEData$Y)
colnames(newSMOTEData)
names(newSMOTEData)[names(newSMOTEData) == "SMOTEData$Y"] <- "churn"
colnames(newSMOTEData)
trainData <- newSMOTEData
table(trainData$churn)

####################################################################################################
## Load final training data frame and test data frame into SQL
####################################################################################################
rxSetComputeContext(local)

trainDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr_train",
  colInfo = col_info)
testDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr_test",
  colInfo = col_info)
rxDataStep(inData = trainData, outFile = trainDataTb, overwrite = TRUE)
rxDataStep(inData = testData, outFile = testDataTb, overwrite = TRUE)
rxGetInfo(trainDataTb, getVarInfo = T, numRows = 3)
rxGetInfo(testDataTb, getVarInfo = T, numRows = 3)
rxSummary( ~ churn, data = trainDataTb)
rxSummary( ~ churn, data = testDataTb)



