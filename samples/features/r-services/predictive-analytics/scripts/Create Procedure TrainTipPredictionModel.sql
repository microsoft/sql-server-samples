use taxidata
go

CREATE PROCEDURE [dbo].[TrainTipPredictionModel]
AS
BEGIN
  DECLARE @inquery nvarchar(max) = N'
    select tipped,  passenger_count, trip_time_in_secs, trip_distance, direct_distance
    from nyctaxi_features
'

  --delete previous stored models
    truncate table dbo.nyc_taxi_models

  -- Insert the trained model into a database table
  INSERT INTO nyc_taxi_models
  EXEC sp_execute_external_script
	@language = N'R',
    @script = N'

	## Create model
	logitObj <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance, data = InputDataSet)


	## Serialize model and put it in data frame
	trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
									',
    @input_data_1 = @inquery,
    @output_data_1_name = N'trained_model'
  ;

END
GO  