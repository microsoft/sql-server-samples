/*
To install the pretrained model in SQL Server, open an elevated CMD promtp:
1. Navigate to the SQL Server installation path:
C:\<SQL SERVER Installation path>\Microsoft SQL Server\140\Setup Bootstrap\SQL2017\x64
2. Run the following command:
RSetup.exe /install /component MLM /<version>/language 1033 /destdir <SQL_DB_instance_folder>\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs
Example:
RSetup.exe /install /component MLM /version 9.2.0.24 /language 1033 /destdir "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs"
The models will be downloaded and extracted.
*/


USE [tpcxbb_1gb]
GO

--******************************************************************************************************************
-- STEP 1 Stored procedure that uses a pretrained model to determine sentiment of a text, such as a product review
--******************************************************************************************************************
CREATE OR ALTER PROCEDURE [dbo].[get_sentiment]
(@text NVARCHAR(MAX))
AS
BEGIN
	DECLARE	@script nvarchar(max);

	--Check that text is not empty
	IF NULLIF(@text, '') is null
	BEGIN
		THROW 50001, 'Please specify a text value to be analyzed.', 1;
		RETURN
	END

	--The Python script we want to execute
	SET @script = N'
import pandas as p
from microsoftml import rx_featurize, get_sentiment

analyze_this = text

# Create the data
text_to_analyze = p.DataFrame(data=dict(Text=[analyze_this]))

# Get the sentiment scores
sentiment_scores = rx_featurize(data=text_to_analyze,ml_transforms=[get_sentiment(cols=dict(scores="Text"))])

# Lets translate the score to something more meaningful
sentiment_scores["Sentiment"] = sentiment_scores.scores.apply(lambda score: "Positive" if score > 0.6 else "Negative")
';
	
	EXECUTE sp_execute_external_script
				@language = N'Python'
				, @script = @script
				, @output_data_1_name = N'sentiment_scores'
				, @params = N'@text nvarchar(max)'
				, @text = @text
				WITH RESULT SETS (("Text" NVARCHAR(MAX),"Score" FLOAT, "Sentiment" NVARCHAR(30)));			

END
				
GO

--******************************************************************************************************************
-- STEP 2 Execute the stored procedure to get sentiment of your own text
--The below examples test a negative and a positive review text
--******************************************************************************************************************
-- Negative review
EXECUTE [dbo].[get_sentiment] N'These are not a normal stress reliever. First of all, they got sticky, hairy and dirty on the first day I received them. Second, they arrived with tiny wrinkles in their bodies and they were cold. Third, their paint started coming off. Fourth when they finally warmed up they started to stick together. Last, I thought they would be foam but, they are a sticky rubber. If these were not rubber, this review would not be so bad.';
GO

--Positive review
EXECUTE [dbo].[get_sentiment] N'These are the cutest things ever!! Super fun to play with and the best part is that it lasts for a really long time. So far these have been thrown all over the place with so many of my friends asking to borrow them because they are so fun to play with. Super soft and squishy just the perfect toy for all ages.'
GO
