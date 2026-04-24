####################################################################################################
## Title: Telco Customer Churn
## Description: Building/Comparing the Telco Churn Models with various tree-based algorithms
## provided by open source R packages and RevoScaleR  libraries
## Author: Microsoft
####################################################################################################

####################################################################################################
## Connect to the training and testing data
####################################################################################################
## SQL data source
train_table <- RxSqlServerData(connectionString = sqlConnString,
                                   table = "edw_cdr_train",
                                   colInfo = cdrColInfo)
test_table <- RxSqlServerData(connectionString = sqlConnString,
                                   table = "edw_cdr_test",
                                   colInfo = cdrColInfo)

## Transform training and testing data to be data frame
train_df <- rxDataStep(inData = train_table)
test_df <- rxDataStep(inData = test_table)

####################################################################################################
## Random forest modeling with randomForest on the data frame
####################################################################################################
library(randomForest)

## Train model
system.time({
forest_model <- randomForest(churn ~ .,
                             data = train_df,
                             ntree = 8,
                             mtry = 2,
                             maxdepth = 16,
                             replace = TRUE)
})
print(forest_model)
#visualize error evolution
plot(forest_model)
#view importance of each predictor
importance(forest_model)
#visualize importance of each predictor
plot(importance(forest_model), lty = 2, pch = 16)
lines(importance(forest_model))

## Score model
predictions_class <- predict(forest_model,
                             newdata = test_df,
                             type = "response")
predictions_prob <- predict(forest_model,
                            newdata = test_df,
                            type = "prob")
pred_df <- cbind(test_df, predictions_class, predictions_prob[, 2])
names(pred_df)[names(pred_df) == "predictions_class"] <- "randomForest_Prediction"
names(pred_df)[names(pred_df) == "predictions_prob[, 2]"] <- "randomForest_Probability"
head(pred_df)

## Evaluate model
forest_metrics <- evaluateModel(data = pred_df,
                                observed = "churn",
                                predicted = "randomForest_Prediction")
forest_metrics

rxrocCurve(data = pred_df,
           observed = "churn",
           predicted = "randomForest_Probability")

####################################################################################################
## Extreme gradient boost modeling with xgboost on the data frame
####################################################################################################
library(Matrix)
library(xgboost)

## Train Model
ntrain <- apply(train_df[, -27], 2, as.numeric)
dtrain <- list()
dtrain$data <- Matrix(ntrain, sparse = TRUE)
dtrain$label <- as.numeric(train_df$churn) - 1
str(dtrain)
system.time({
xgboost_model <- xgboost(data = dtrain$data,
                         label = dtrain$label,
                         max.depth = 32,
                         eta = 1,
                         nthread = 2,
                         nround = 2,
                         objective = "binary:logistic")
})
importance <- xgb.importance(feature_names = dtrain$data@Dimnames[[2]],
                             model = xgboost_model)
print(importance)
library(Ckmeans.1d.dp)
xgb.plot.importance(importance)

## Score model
ntest <- apply(test_df[, -27], 2, as.numeric)
dtest <- list()
dtest$data <- Matrix(ntest, sparse = TRUE)
dtest$label <- as.numeric(test_df$churn) - 1
str(dtest)
predictions <- predict(xgboost_model,
                       newdata = dtest$data)
threshold <- 0.5
xgboost_Probability <- predictions
xgboost_Prediction <- ifelse(xgboost_Probability > threshold, 1, 0)
pred_df <- cbind(test_df[, -27], dtest$label, xgboost_Prediction, xgboost_Probability)
names(pred_df)[names(pred_df) == "dtest$label"] <- "churn"
head(pred_df)

## Evaluate Model
xgboost_metrics <- evaluateModel(data = pred_df,
                                 observed = "churn",
                                 predicted = "xgboost_Prediction")
xgboost_metrics

rxrocCurve(data = pred_df,
           observed = "churn",
           predicted = "xgboost_Probability")

####################################################################################################
## Decision forest modeling with rxDForest on SQL data source
####################################################################################################

## Train model
rxSetComputeContext(sqlCompute)
train_vars <- rxGetVarNames(train_table)
train_vars <- train_vars[!train_vars %in% c("churn")]
temp <- paste(c("churn", paste(train_vars, collapse = "+")), collapse = "~")
formula <- as.formula(temp)

system.time({
rx_forest_model <- rxDForest(formula = formula,
                             data = train_table,
                             nTree = 8,
                             maxDepth = 16,
                             mTry = 2,
                             minBucket = 1,
                             replace = TRUE,
                             importance = TRUE,
                             seed = 8,
                             parms = list(loss = c(0, 4, 1, 0)))
})
rx_forest_model
plot(rx_forest_model)
rxVarImpPlot(rx_forest_model)

## Score model
rxSetComputeContext('local')
predictions <- rxPredict(modelObject = rx_forest_model,
                         data = test_df,
                         type = "prob",
                         overwrite = TRUE)
threshold <- 0.5
predictions$X0_prob <- NULL
predictions$churn_Pred <- NULL
names(predictions) <- c("Forest_Probability")
predictions$Forest_Prediction <- ifelse(predictions$Forest_Probability > threshold, 1, 0)
predictions$Forest_Prediction <- factor(predictions$Forest_Prediction, levels = c(1, 0))
pred_df <- cbind(test_df[, c("customerid", "churn")], predictions)
head(pred_df)

## Evaluate Model
rx_forest_metrics <- evaluateModel(data = pred_df,
                                   observed = "churn",
                                   predicted = "Forest_Prediction")
rx_forest_metrics

rxrocCurve(data = pred_df,
         observed = "churn",
         predicted = "Forest_Probability")

####################################################################################################
## Boosted tree modeling with rxBTrees on SQL data source
####################################################################################################

## Train model
rxSetComputeContext(sqlCompute)

system.time({
rx_boosted_model <- rxBTrees(formula = formula,
                             data = train_table,
                             minSplit = 10,
                             minBucket = 10,
                             learningRate = 0.2,
                             nTree = 100,
                             mTry = 2,
                             maxDepth = 10,
                             useSurrogate = 0,
                             replace = TRUE,
                             importance = TRUE,
                             lossFunction = "bernoulli")
})
rx_boosted_model
plot(rx_boosted_model, by.class = TRUE)
rxVarImpPlot(rx_boosted_model)

## Score model
rxSetComputeContext('local')
predictions <- rxPredict(modelObject = rx_boosted_model,
                         data = test_df,
                         type = "prob",
                         overwrite = TRUE)
threshold <- 0.5
#predictions <- 1-predictions
names(predictions) <- c("Boosted_Probability")
predictions$Boosted_Prediction <- ifelse(predictions$Boosted_Probability > threshold, 1, 0)
predictions$Boosted_Prediction <- factor(predictions$Boosted_Prediction, levels = c(1, 0))
pred_df <- cbind(test_df[, c("customerid", "churn")], predictions)
head(pred_df)

## Evaluate model
rx_boosted_metrics <- evaluateModel(data = pred_df,
                                    observed = "churn",
                                    predicted = "Boosted_Prediction")
rx_boosted_metrics

rxrocCurve(data = pred_df,
         observed = "churn",
         predicted = "Boosted_Probability")

