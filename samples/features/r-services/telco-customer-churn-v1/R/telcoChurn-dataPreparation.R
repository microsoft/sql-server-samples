####################################################################################################
## Title: Telco Customer Churn
## Description: Data Preparation
## Author: Microsoft
## Note: Prepare the training and testing data sets by pre-processing and spliting on raw data
####################################################################################################

dataPreparation <- function(sqlSettings, trainTable, testTable) {
    sqlConnString <- sqlSettings$connString

    ## Query necessary columns from the call detail record table
    dataVars <- rxGetVarNames(cdrSQL)
    dataVars <- dataVars[!dataVars %in% c("year", "month")]
    dataVars <- paste(dataVars, collapse = ", ")
    dataQuery <- paste("select", dataVars, "from", inputTable)

    ## Create sql server data sources
    inputDataSQL = RxSqlServerData(sqlQuery = dataQuery,
                                   connectionString = sqlConnString,
                                   colInfo = cdrColInfo)
    trainDataSQL <- RxSqlServerData(connectionString = sqlConnString,
                                   table = trainTable,
                                   colInfo = cdrColInfo)
    testDataSQL <- RxSqlServerData(connectionString = sqlConnString,
                                   table = testTable,
                                   colInfo = cdrColInfo)

    ## Data pre-processing: cleaning and splitting followed by SMOTE
    rxExec(preProcess, inData = inputDataSQL, outData1 = trainDataSQL, outData2 = testDataSQL)
}

preProcess <- function(inData, outData1, outData2) {
    ## Clean missing data
    ## Remove duplicate rows
    cdrDF <- rxDataStep(inData = inData,
                        removeMissings = TRUE,
                        overwrite = TRUE)
    cdrDF <- cdrDF[!duplicated(cdrDF),]

    ## Split data
    set.seed(1234)
    splitFile <- rxSplit(inData = cdrDF,
                         outFilesBase = "trainTestData",
                         splitByFactor = "ind",
                         transforms = list(ind = factor(sample(0:1, size = .rxNumRows, replace = TRUE, prob = c(0.3, 0.7)),
                                                       levels = 0:1,
                                                       labels = c("Test", "Train"))),
                         overwrite = TRUE)
    trainFile <- splitFile[[2]]
    testFile <- splitFile[[1]]

    ## SMOTE on training data
    trainDF <- rxDataStep(inData = trainFile, varsToDrop = c("ind"))
    testDF <- rxDataStep(inData = testFile, varsToDrop = c("ind"))

    library(unbalanced)
    trainVars <- names(trainDF)
    trainVarsInd <- trainVars %in% c("churn")
    smotetrain <- ubSMOTE(X = trainDF[!trainVarsInd], Y = trainDF$churn,
                      perc.over = 200, perc.under = 500,
                      k = 3, verbose = TRUE)
    smotetrainDF <- cbind(smotetrain$X, smotetrain$Y)
    names(smotetrainDF)[names(smotetrainDF) == "smotetrain$Y"] <- "churn"
    trainDF <- smotetrainDF

    ## Load final training data and testing data into SQL
    rxDataStep(inData = trainDF, outFile = outData1, overwrite = TRUE)
    rxDataStep(inData = testDF, outFile = outData2, overwrite = TRUE)
}
