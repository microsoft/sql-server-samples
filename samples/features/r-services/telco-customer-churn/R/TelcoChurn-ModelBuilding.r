################################################################
## Title: Data Science For Database Professionals
## Description: Building the Telco Churn Model
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
trainDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr_train",
  colInfo = col_info)

testDataTb <- RxSqlServerData(
  connectionString = connection_string,
  table = "edw_cdr_test",
  colInfo = col_info)

rxGetInfo(trainDataTb, getVarInfo = T, numRows = 3)
rxGetInfo(testDataTb, getVarInfo = T, numRows = 3)
rxSummary( ~ churn, data = trainDataTb)
rxSummary( ~ churn, data = testDataTb)

##Data frame
trainData <- rxDataStep(trainDataTb, overwrite = TRUE)
testData <- rxDataStep(testDataTb, overwrite = TRUE)
str(trainData)
str(testData)

####################################################################################################
## Random forest modeling with randomForest on the data frame
####################################################################################################
library(randomForest)

##Train Model
system.time(
forest_model <- randomForest(churn ~ .,
                                   data = trainData,
                                   ntree = 8,
                                   mtry = 2,
                                   maxdepth = 32,
                                   replace = TRUE))
print(forest_model)
#visualize error evolution
plot(forest_model)
#view importance of each predictor
importance(forest_model)
#visualize importance of each predictor
plot(importance(forest_model), lty = 2, pch = 16)
lines(importance(forest_model))

##Score Model
system.time(predictions.class <- predict(forest_model, newdata = testData, type = "response"))
system.time(predictions.prob <- predict(forest_model, newdata = testData, type = "prob"))
testPredData <- cbind(testData, predictions.class, predictions.prob[, 2])
names(testPredData)[names(testPredData) == "predictions.class"] <- "randomForest_Prediction"
names(testPredData)[names(testPredData) == "predictions.prob[, 2]"] <- "randomForest_Probability"
head(testPredData)

##Evaluate Model
forest_metrics <- evaluate_model(data = testPredData,
                                  observed = "churn",
                                  predicted = "randomForest_Prediction")
forest_metrics

threshold = 0.5
S = testPredData$randomForest_Probability
Y = testPredData$churn
roc.curve(s = threshold)
ROC.curve = Vectorize(roc.curve)
M.ROC.randomForest = ROC.curve(s = seq(0, 1, by = .01))
library(AUC)
library(pROC)
randomForest.auc <- auc(randomForest_Prediction, churn)
plot(M.ROC.randomForest[1,], M.ROC.randomForest[2,], main = "ROC Curves for Random Forest", col = "blue", lwd = 4, type = "l", xlab = "False Positive Rate", ylab = "True Positive Rate")
text(0.2, 0, paste("AUC=", round(randomForest.auc, 2)))

####################################################################################################
## Extreme gradient boost modeling with xgboost on the data frame
####################################################################################################
library(Matrix)
library(xgboost)

##Train Model
ntrainData <- apply(trainData[, -27], 2, as.numeric)
ntestData <- apply(testData[, -27], 2, as.numeric)
dtrainData <- list()
dtestData <- list()
dtrainData$data <- Matrix(ntrainData, sparse = TRUE)
dtrainData$label <- as.numeric(trainData$churn) - 1
dtestData$data <- Matrix(ntestData, sparse = TRUE)
dtestData$label <- as.numeric(testData$churn) - 1
str(dtrainData)
str(dtestData)
system.time(
xgboost_model <- xgboost(data = dtrainData$data, label = dtrainData$label, max.depth = 32, eta = 1, nthread = 2, nround = 2, objective = "binary:logistic")
)
importance <- xgb.importance(feature_names = dtrainData$data@Dimnames[[2]], model = xgboost_model)
print(importance)
library(Ckmeans.1d.dp)
xgb.plot.importance(importance)

##Score Model
predictions <- predict(xgboost_model, dtestData$data)
threshold <- 0.5
xgboost_Probability <- predictions
xgboost_Prediction <- ifelse(xgboost_Probability > threshold, 1, 0)
testPredData <- cbind(testData[, -27], dtestData$label, xgboost_Prediction, xgboost_Probability)
names(testPredData)[names(testPredData) == "dtestData$label"] <- "churn"
head(testPredData)

##Evaluate Model
xgboost_metrics <- evaluate_model(data = testPredData,
                                  observed = "churn",
                                  predicted = "xgboost_Prediction")
xgboost_metrics

threshold = 0.5
S = testPredData$xgboost_Probability
Y = testPredData$churn
roc.curve(s = threshold)
ROC.curve = Vectorize(roc.curve)
M.ROC.xgboost = ROC.curve(s = seq(0, 1, by = .01))
library(AUC)
library(pROC)
xgboost.auc <- auc(testPredData$xgboost_Prediction,testPredData$churn)
plot(M.ROC.xgboost[1,], M.ROC.xgboost[2,], main = "ROC Curves for Xgboost", col = "blue", lwd = 4, type = "l", xlab = "False Positive Rate", ylab = "True Positive Rate")
text(0.5, 0, paste("AUC=", round(xgboost.auc, 2)))

####################################################################################################
## Decision forest modeling with rxDForest on SQL data source
####################################################################################################

##Train Model
rxSetComputeContext(sql)
train_vars <- rxGetVarNames(trainDataTb)
train_vars <- train_vars[!train_vars %in% c("churn")]
temp <- paste(c("churn", paste(train_vars, collapse = "+")), collapse = "~")
formula <- as.formula(temp)

system.time(
  rx_forest_model <- rxDForest(formula = formula,
                            data = trainDataTb,
                            nTree = 8,
                            maxDepth = 32,
                            mTry = 2,
                            minBucket = 1,
                            replace = TRUE,
                            importance = TRUE,
                            seed = 8,
                            parms = list(loss = c(0, 4, 1, 0))))
rx_forest_model
plot(rx_forest_model)
rxVarImpPlot(rx_forest_model)

##Score Model
rxSetComputeContext(local)
system.time(
  predictions <- rxPredict(modelObject = rx_forest_model,
                           data = testData,
                           type = "prob",
                           overwrite = TRUE))
threshold <- 0.5
predictions$X0_prob <- NULL
predictions$churn_Pred <- NULL
names(predictions) <- c("Forest_Probability")
predictions$Forest_Prediction <- ifelse(predictions$Forest_Probability > threshold, 1, 0)
predictions$Forest_Prediction <- factor(predictions$Forest_Prediction, levels = c(1, 0))
testPredData <- cbind(testData, predictions)
head(testPredData)

##Evaluate Model
rx_forest_metrics <- evaluate_model(data = testPredData,
                                 observed = "churn",
                                 predicted = "Forest_Prediction")
rx_forest_metrics

roc_curve(data = testPredData,
          observed = "churn",
          predicted = "Forest_Probability")

####################################################################################################
## Boosted tree modeling with rxBTrees on SQL data source
####################################################################################################

##Train Model
rxSetComputeContext(sql)
system.time(
  rx_boosted_model <- rxBTrees(formula = formula,
                            data = trainDataTb,
                            minSplit = 10,
                            minBucket = 10,
                            learningRate = 0.2,
                            nTree = 100,
                            mTry = 2,
                            maxDepth = 10,
                            useSurrogate = 0,
                            replace = TRUE,
                            importance = TRUE,
                            lossFunction = "bernoulli"))
rx_boosted_model
plot(rx_boosted_model, by.class = TRUE)
rxVarImpPlot(rx_boosted_model)

##Score Model
rxSetComputeContext(local)
system.time(
  predictions <- rxPredict(modelObject = rx_boosted_model,
                           data = testData,
                           type = "prob",
                           overwrite = TRUE))
threshold <- 0.5
names(predictions) <- c("Boosted_Probability")
predictions$Boosted_Prediction <- ifelse(predictions$Boosted_Probability > threshold, 1, 0)
predictions$Boosted_Prediction <- factor(predictions$Boosted_Prediction, levels = c(1, 0))
testPredData <- cbind(testData, predictions)
head(testPredData)

##Evaluate Model
rx_boosted_metrics <- evaluate_model(data = testPredData,
                                  observed = "churn",
                                  predicted = "Boosted_Prediction")
rx_boosted_metrics

roc_curve(data = testPredData,
          observed = "churn",
          predicted = "Boosted_Probability")


