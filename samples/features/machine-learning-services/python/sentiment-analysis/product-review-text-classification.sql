--The database used for this sample can be downloaded here: https://sqlchoice.blob.core.windows.net/sqlchoice/static/tpcxbb_1gb.bak
USE [tpcxbb_1gb]
GO

--**************************************************************
-- STEP 1 Create a table for storing the machine learning model
--**************************************************************
DROP TABLE IF EXISTS [dbo].[models]
GO
CREATE TABLE [dbo].[models](
	[language] [varchar](30) NOT NULL,
	[model_name] [varchar](30) NOT NULL,
	[model] [varbinary](max) NOT NULL,
	[create_time] [datetime2](7) NULL DEFAULT (sysdatetime()),
	[created_by] [nvarchar](500) NULL DEFAULT (suser_sname()),
	PRIMARY KEY CLUSTERED
	(
	[language],
	[model_name]
	)
)
GO

--*************************************************************************************************************
-- STEP 2 Look at the dataset we will use in this sample
-- Tag is a label indicating the sentiment of a review. These are actual values we will use to train the model
-- For training purposes, we will use 90% percent of the data.
-- For testing / scoring purposes, we will use 10% percent of the data.
--*************************************************************************************************************
CREATE OR ALTER VIEW product_reviews_training_data
AS
SELECT TOP(CAST( ( SELECT COUNT(*) FROM   product_reviews)*.9 AS INT))
		CAST(pr_review_content AS NVARCHAR(4000)) AS pr_review_content,
		CASE
			WHEN pr_review_rating <3 THEN 1
			WHEN pr_review_rating =3 THEN 2
			ELSE 3
		END AS tag
FROM   product_reviews;
GO

CREATE OR ALTER VIEW product_reviews_test_data
AS
SELECT TOP(CAST( ( SELECT COUNT(*) FROM   product_reviews)*.1 AS INT))
		CAST(pr_review_content AS NVARCHAR(4000)) AS pr_review_content,
		CASE
			WHEN pr_review_rating <3 THEN 1
			WHEN pr_review_rating =3 THEN 2
			ELSE 3
		END AS tag
FROM   product_reviews;
GO

-- Look at the dataset we will use in this sample
SELECT TOP(100) * FROM product_reviews_training_data;
GO

--***************************************************************************************************
-- STEP 3 Create a stored procedure for training a
-- text classifier model for product review sentiment classification (Positive, Negative, Neutral)
-- 1 = Negative, 2 = Neutral, 3 = Positive
--***************************************************************************************************
CREATE OR ALTER PROCEDURE [dbo].[create_text_classification_model]
AS
BEGIN
	DECLARE	  @model varbinary(max)
			, @train_script nvarchar(max);
	
--The Python script we want to execute
	SET @train_script = N'
##Import necessary packages
from microsoftml import rx_logistic_regression,featurize_text, n_gram
import pickle

## Defining the tag column as a categorical type
training_data["tag"] = training_data["tag"].astype("category")

## Create a machine learning model for multiclass text classification.
## We are using a text featurizer function to split the text in features of 2-word chunks
model = rx_logistic_regression(formula = "tag ~ features", data = training_data, method = "multiClass", ml_transforms=[
                        featurize_text(language="English",
                                     cols=dict(features="pr_review_content"),
                                      word_feature_extractor=n_gram(2, weighting="TfIdf"))])

## Serialize the model so that we can store it in a table
modelbin = pickle.dumps(model)
';
	
	EXECUTE sp_execute_external_script
						@language = N'Python'
					  , @script = @train_script
					  , @input_data_1 = N'SELECT * FROM product_reviews_training_data'
					  , @input_data_1_name = N'training_data'
					  , @params  = N'@modelbin varbinary(max) OUTPUT'
					  , @modelbin = @model OUTPUT;

	--Save model to DB Table				
	DELETE FROM dbo.models WHERE model_name = 'rx_logistic_regression' and language = 'Python';
	INSERT INTO dbo.models (language, model_name, model) VALUES('Python', 'rx_logistic_regression', @model);
END;
GO

--***************************************************************************************************
-- STEP 4 Execute the stored procedure that creates and saves the machine learning model in a table
--***************************************************************************************************

EXECUTE [dbo].[create_text_classification_model];
--Take a look at the model object saved in the model table
SELECT * FROM dbo.models;
GO

--******************************************************************************************************************
-- STEP 5 --Stored procedure that uses the model we just created to predict/classify the sentiment of product reviews
--******************************************************************************************************************
CREATE OR ALTER PROCEDURE [dbo].[predict_review_sentiment]
AS
BEGIN
	-- text classifier for online review sentiment classification (Positive, Negative, Neutral)
	DECLARE	
			 @model_bin varbinary(max)
			, @prediction_script nvarchar(max);
	
	-- Select the model binary object from the model table
	SET @model_bin = (select model from dbo.models WHERE model_name = 'rx_logistic_regression' and language = 'Python');
	

	--The Python script we want to execute
	SET @prediction_script = N'
from microsoftml import rx_predict
from revoscalepy import rx_data_step
import pickle

## The input data from the query in  @input_data_1 is populated in test_data
## We are selecting 10% of the entire dataset for testing the model

## Unserialize the model
model = pickle.loads(model_bin)

## Use the rx_logistic_regression model
predictions = rx_predict(model = model, data = test_data, extra_vars_to_write = ["tag", "pr_review_content"], overwrite = True)

## Converting to output data set
result = rx_data_step(predictions)
';
	
	EXECUTE sp_execute_external_script
				@language = N'Python'
				, @script = @prediction_script
				, @input_data_1 = N'SELECT * FROM product_reviews_test_data'
				, @input_data_1_name = N'test_data'
				, @output_data_1_name = N'result'
				, @params  = N'@model_bin varbinary(max)'
				, @model_bin = @model_bin
		WITH RESULT SETS (("Review" NVARCHAR(MAX),"Tag" FLOAT, "Predicted_Score_Negative" FLOAT, "Predicted_Score_Neutral" FLOAT, "Predicted_Score_Positive" FLOAT));			
END
GO


--***************************************************************************************************
-- STEP 6 Execute the multi class prediction using the model we trained earlier
--***************************************************************************************************
EXECUTE [dbo].[predict_review_sentiment]
GO




	