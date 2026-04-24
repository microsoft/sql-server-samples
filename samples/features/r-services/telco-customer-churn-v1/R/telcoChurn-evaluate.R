################################################################
## Title: Telco Customer Churn
## Description: Defining pre-functions
## Author: Microsoft
################################################################

####################################################################################################
## Define functions for model evaluation
####################################################################################################
## Define evaluation metrics
evaluateModel <- function(data, observed, predicted)
{
  confusion <- table(data[[observed]], data[[predicted]])
  print(confusion)
  tp <- confusion[rownames(confusion) == 1, colnames(confusion) == 1]
  fn <- confusion[rownames(confusion) == 1, colnames(confusion) == 0]
  fp <- confusion[rownames(confusion) == 0, colnames(confusion) == 1]
  tn <- confusion[rownames(confusion) == 0, colnames(confusion) == 0]
  accuracy <- (tp + tn) / (tp + fn + fp + tn)
  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  fscore <- 2 * (precision * recall) / (precision + recall)
  metrics <- c("Accuracy" = accuracy,
               "Precision" = precision,
               "Recall" = recall,
               "F-Score" = fscore)
  return(metrics)
}

## Define ROC curve
rxrocCurve <- function(data, observed, predicted)
{
  data <- data[, c(observed, predicted)]
  data[[observed]] <- as.numeric(as.character(data[[observed]]))
  rxRocCurve(actualVarName = observed,
             predVarNames = predicted,
             data = data)
}

