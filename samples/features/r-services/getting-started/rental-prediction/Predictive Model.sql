
USE TutorialDB;

-- Table containing ski rental data
SELECT * FROM [dbo].[rental_data];



-------------------------- STEP 1 - Setup model table ----------------------------------------
DROP TABLE IF EXISTS rental_rx_models;
GO
CREATE TABLE rental_rx_models (
                model_name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
                model VARBINARY(MAX) NOT NULL
);
GO




-------------------------- STEP 2 - Train model ----------------------------------------
-- Stored procedure that trains and generates an R model using the rental_data and a decision tree algorithm
DROP PROCEDURE IF EXISTS generate_rental_rx_model;
go
CREATE PROCEDURE generate_rental_rx_model (@trained_model varbinary(max) OUTPUT)
AS
BEGIN
    EXECUTE sp_execute_external_script
      @language = N'R'
    , @script = N'
        require("RevoScaleR");

			rental_train_data$Holiday = factor(rental_train_data$Holiday);
            rental_train_data$Snow = factor(rental_train_data$Snow);
            rental_train_data$WeekDay = factor(rental_train_data$WeekDay);

        #Create a dtree model and train it using the training data set
        model_dtree <- rxDTree(RentalCount ~ Month + Day + WeekDay + Snow + Holiday, data = rental_train_data);
        #Before saving the model to the DB table, we need to serialize it
        trained_model <- as.raw(serialize(model_dtree, connection=NULL));'

    , @input_data_1 = N'select "RentalCount", "Year", "Month", "Day", "WeekDay", "Snow", "Holiday" from dbo.rental_data where Year < 2015'
    , @input_data_1_name = N'rental_train_data'
    , @params = N'@trained_model varbinary(max) OUTPUT'
    , @trained_model = @trained_model OUTPUT;
END;
GO

------------------- STEP 3 - Save model to table -------------------------------------
TRUNCATE TABLE rental_rx_models;

DECLARE @model VARBINARY(MAX);
EXEC generate_rental_rx_model @model OUTPUT;

INSERT INTO rental_rx_models (model_name, model) VALUES('rxDTree', @model);

SELECT * FROM rental_rx_models;



------------------ STEP 4  - Use the model to predict number of rentals --------------------------
DROP PROCEDURE IF EXISTS predict_rentalcount;
GO
CREATE PROCEDURE predict_rentalcount (@model varchar(100))
AS
BEGIN
	DECLARE @rx_model varbinary(max) = (select model from rental_rx_models where model_name = @model);

	EXEC sp_execute_external_script
					@language = N'R'
				  , @script = N'
require("RevoScaleR");

#Before using the model to predict, we need to unserialize it
rental_model<-unserialize(rx_model);

rental_predictions <-rxPredict(rental_model, rental_score_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"));

OutputDataSet <- cbind(rental_predictions[1],rental_predictions[2], rental_predictions[3], rental_predictions[4], rental_predictions[5], rental_predictions[6], rental_predictions[7], rental_predictions[8])
'
	, @input_data_1 = N'Select "RentalCount", "Year" ,"Month", "Day", "WeekDay", "Snow", "Holiday"  from rental_data where Year = 2015'
	, @input_data_1_name = N'rental_score_data'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model
	with result sets (("RentalCount_Predicted" float, "RentalCount_Actual" float,"Month" float,"Day" float,"WeekDay" float,"Snow" float,"Holiday" float, "Year" float));
			
END;
GO

---------------- STEP 5 - Create DB table to store predictions -----------------------
DROP TABLE IF EXISTS [dbo].[rental_predictions];
GO
--Create a table to store the predictions in
CREATE TABLE [dbo].[rental_predictions](
	[RentalCount_Predicted] [int] NULL,
	[RentalCount_Actual] [int] NULL,
	[Month] [int] NULL,
	[Day] [int] NULL,
	[WeekDay] [int] NULL,
	[Snow] [int] NULL,
	[Holiday] [int] NULL,
	[Year] [int] NULL
) ON [PRIMARY]
GO


---------------- STEP 6 - Save the predictions in a DB table -----------------------
TRUNCATE TABLE rental_predictions;
--Insert the results of the predictions for test set into a table
INSERT INTO rental_predictions
      EXEC predict_rentalcount 'rxDTree';

-- Select contents of the table
SELECT * FROM rental_predictions;

------------- STEP 7 - Alternative to the previous stored procedure - Uses new data to predict future rental counts
--Stored procedure that takes model name and new data as input parameters and predicts the rental count for the new data
DROP PROCEDURE IF EXISTS predict_rentalcount_new;
GO
CREATE PROCEDURE predict_rentalcount_new (@model VARCHAR(100),@q NVARCHAR(MAX))
AS
BEGIN
    DECLARE @rx_model VARBINARY(MAX) = (SELECT model FROM rental_rx_models WHERE model_name = @model);
    EXECUTE sp_execute_external_script
        @language = N'R'
        , @script = N'
            require("RevoScaleR");

            #The InputDataSet contains the new data passed to this stored proc. We will use this data to predict.
            rentals = InputDataSet;

        #Convert types to factors
            rentals$Holiday = factor(rentals$Holiday);
            rentals$Snow = factor(rentals$Snow);
            rentals$WeekDay = factor(rentals$WeekDay);

            #Before using the model to predict, we need to unserialize it
            rental_model = unserialize(rx_model);

            #Call prediction function
            rental_predictions = rxPredict(rental_model, rentals);'
                , @input_data_1 = @q
        , @output_data_1_name = N'rental_predictions'
                , @params = N'@rx_model varbinary(max)'
                , @rx_model = @rx_model
                WITH RESULT SETS (("RentalCount_Predicted" FLOAT));

END;
GO

--Execute the predict_rentals stored proc and pass the modelname and a query string with a set of features we want to use to predict the rental count
EXEC dbo.predict_rentalcount_new @model = 'rxDTree',
       @q ='SELECT CONVERT(INT, 3) AS Month, CONVERT(INT, 24) AS Day, CONVERT(INT, 4) AS WeekDay, CONVERT(INT, 1) AS Snow, CONVERT(INT, 1) AS Holiday';
GO


-------------- STEP 8 - Getting predictions from an Application ----------------------------------
-- Create stored procedure that returns predictions as JSON
-- This stored procedure is going to be called from our application
DROP PROCEDURE IF EXISTS get_rental_predictions;
GO
CREATE PROCEDURE get_rental_predictions (@year int)
AS
SELECT
 "Year",
 RentalCount_Predicted ,
 RentalCount_Actual ,
 "Month" ,
 "Day" ,
 "WeekDay" ,
 "Snow",
 "Holiday"
 FROM rental_predictions
 WHERE Year = @year
 FOR JSON PATH, root('data')

RETURN
GO

-- Executing stored procedure with year = 2015
EXEC get_rental_predictions 2015;