USE sqlr;
GO

/* Create procedure for scoring using the decision tree model */
create or alter procedure predict_iris_species (@model varchar(100))
as
begin
		declare @rx_model varbinary(max) = (select model from iris_models where model_name = @model);
		-- Predict based on the specified model:
		exec sp_execute_external_script
						@language = N'R'
					, @script = N'
# Unserialize model from SQL Server
irismodel<-unserialize(rx_model);

# Predict species for new data using rxDTree model
OutputDataSet <-rxPredict(irismodel, iris_rx_data, extraVarsToWrite = c("Species", "id"));
	'
		, @input_data_1 = N'
select id, "Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width", "Species"
from iris_data'
		, @input_data_1_name = N'iris_rx_data'
		, @params = N'@rx_model varbinary(max)'
		, @rx_model = @rx_model
		with result sets ( ("setosa_Pred" float, "versicolor_Pred" float, "virginica_Pred" float, "Species.Actual" varchar(100), "id" int));
end;
go

/* Test scoring of model */
exec predict_iris_species 'iris.dtree';
go
