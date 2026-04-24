**Instructions**


- After executing those R scripts, an edw_cdr SQL table will be created.
- Run the code in telcoChurn-operationalize.sql
- Run the code in telcoChurn-main.sql



----------
**Description**

- telcoChurn-main.sql - Use this T-SQL script to try out the telco customer churn example.
- telcoChurn-operationalize.sql - T-SQL scripts to create the stored procedures used in this example.

The database consists of the following tables

- **cdr\_models** - Contains the serialized R models that are used for predicting customer churn
- **edw\_cdr**- Base Call Detail Records (CDR)
- **edw\_cdr\_train**- Training data
- **edw\_cdr\_test** - Testing data
- **edw\_cdr\_pred** - Predicted results

and the following stored procedures

- **generate_cdr_rx_forest** - Train decision forest model with the rxDForest algorithm in RevoScaleR library
- **predict_cdr_rx_forest** - Predict customer churn using the trained model
- **model_evaluate** - Generate model performance metrics: Accuracy, Precision, Recall, F-score
- **model_roccurve** - Generate ROC curve
- **pie** - Create a pie chart to visualize the proportion of predicted customer churn
- **stackedbar** - Create a stacked bar chart to visualize the model confusion matrix

----------
