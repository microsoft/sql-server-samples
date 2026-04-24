/*
To install the pretrained model in SQL Server, open an elevated CMD promtp:
1. Navigate to the SQL Server installation path:
C:\<SQL SERVER Installation path>\Microsoft SQL Server\140\Setup Bootstrap\SQL2017\x64
2. Run the following command:
RSetup.exe /install /component MLM /<version>/language 1033 /destdir <SQL_DB_instance_folder>\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs
Example:
RSetup.exe /install /component MLM /version 9.2.0.24 /language 1033 /destdir "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs"
The models will be downloaded and extracted.
The database used for this sample can be downloaded here: https://sqlchoice.blob.core.windows.net/sqlchoice/static/tpcxbb_1gb.bak
*/


USE [tpcxbb_1gb]
GO

--******************************************************************************************************************
-- STEP 1 Stored procedure that uses a pretrained model to determine sentiment of a text, such as a product review
--******************************************************************************************************************
CREATE OR ALTER PROCEDURE [dbo].[get_review_sentiment]
AS
BEGIN
	DECLARE	@script nvarchar(max);
	
	--The Python script we want to execute
	SET @script = N'
from microsoftml import rx_featurize, get_sentiment

# Get the sentiment scores
sentiment_scores = rx_featurize(data=reviews, ml_transforms=[get_sentiment(cols=dict(scores="review"))])

# Lets translate the score to something more meaningful
sentiment_scores["Sentiment"] = sentiment_scores.scores.apply(lambda score: "Positive" if score > 0.6 else "Negative")
';
	
	EXECUTE sp_execute_external_script
				@language = N'Python'
				, @script = @script
				, @input_data_1 = N'SELECT CAST(pr_review_content AS NVARCHAR(4000)) AS review FROM product_reviews'
				, @input_data_1_name = N'reviews'
				, @output_data_1_name = N'sentiment_scores'
				WITH RESULT SETS (("Review" NVARCHAR(MAX),"Score" FLOAT, "Sentiment" NVARCHAR(30)));			

END
				
GO

--******************************************************************************************************************
-- STEP 2 Execute the stored procedure
--******************************************************************************************************************
EXECUTE [dbo].[get_review_sentiment];
GO
