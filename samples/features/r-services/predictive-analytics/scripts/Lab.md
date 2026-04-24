# Implement Predictive Analytics - Lab



In this lab, you will implement predictive analytics to predict the likelihood a taxi driver will be receive a tip given detail about the trip including the number of passengers, the trip distance (as measured by the odometer), the linear trip distance (e.g., as the crow flies), and the trip duration. Using SQL Server 2016 R Services, you will train the model, store the model in a table, and make the prediction available via a stored procedure which you will invoke from a simple node.js application.

Requirements
-----------------
* [SQL Server 2016 Developer Edition](https://www.microsoft.com/en-us/sql-server/sql-server-editions-developers) or higher
* [Visual Studio Code](http://code.visualstudio.com)
* Node.js

A tool to run SQL scripts against your SQL Server database, such as [SQL Server Management Studio (SSMS)](https://msdn.microsoft.com/library/mt238290.aspx)
This lab assumes you have setup SQL Server 2016 Developer Edition locally on your workstation or a remote instance.

Required SQL Server Configuration
*	Make sure that your installation of SQL Server includes R Services.
*	Using SQL Server Configuration Manager, make sure that TCP/IP connections are enabled to your instance of SQL Server.
*	Be sure that the SQL Server, SQL Server Launchpad and SQL Server Browser services are all running.



Download the Project
----------------------
Clone this repo to have the sample application and setup scripts.

### Setup the sample database

The following steps will get your taxidata database setup and loaded with data.

1. Using the SQL tool of your choice (SQL Server Management Studio, Visual Studio Code with the MSSQL extension), connect to your database and execute the following scripts (provided with the project files) to create the database, a table to hold the taxi data, and load the 1.7M records into the taxi trip data table.
    - *CreateDatabase.sql*
    - *Create nyctaxi_features Table.sql*
    - *Load nyctaxi_features using BCP.sql* **Important**, make sure that you edit the script to point to the folder where you've cloned the .bcp file
2. Next, create a table valued function that will package inputs received by the stored procedure into a tabular format by executing the following script. You will use this function later within the stored procedure that makes predictions.
    - *Create Function fnEngineerFeatures.sql*
3. Execute the following script to create a table that will persist the predictive model you will generate. Observe that this table has a schema that consists of one column of type varbinary(max). This column will hold the serialized representation of your model.
    - *Create nyc_taxi_models Table.sql*

### Train the Model
To train your model, you will create a stored procedure that you can run at any time to train your model and store its serialized form in the nyctaxi_features table.

1. Execute the following script to define the stored procedure:
    - *Create Procedure TrainTipPredictionModel.sql*
2. Execute the following script to train the model and store it.
    - *Exec TrainTipPredictionModel.sql*. You may need to [configure external scripts](https://msdn.microsoft.com/en-us/library/mt590884.aspx) and restart SQL.

Let’s take a closer look at the contents of the stored procedure.

```
CREATE PROCEDURE [dbo].[TrainTipPredictionModel]
AS
BEGIN
  DECLARE @inquery nvarchar(max) = N'
    select tipped,  passenger_count, trip_time_in_secs, trip_distance, direct_distance
    from nyctaxi_features
'
  -- Before insterting a new model, we delete the previous one
    truncate table dbo.nyc_taxi_models

  -- Insert the trained model into a database table
  INSERT INTO nyc_taxi_models
  EXEC sp_execute_external_script
    @language = N'R',
    @script = N'

	##Create model
	logitObj <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs +
                           direct_distance, data = InputDataSet)

	##Serialize model and put it in data frame
	trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
									',
   @input_data_1 = @inquery,
    @output_data_1_name = N'trained_model'
  ;

END
GO
```
The procedure begins by defining a query that retrieves the sample data contained in the nyctaxi_features table.
```
  DECLARE @inquery nvarchar(max) = N'
    select tipped,  passenger_count, trip_time_in_secs, trip_distance, direct_distance
    from nyctaxi_features
'
```
This query is passed as one of the parameters to sp_execute_external_script, via the @input_data_1 parameter.

Next, a call to sp_execute_external_script is constructed. The return value of this stored procedure call is the serialized model, which is saved into the nyc_taxi_models table.  The inputs to sp_execute_external_script are:
*	__@language__: needs to indicate that the script is written in the R language.
*	__@script__: this is the actual R script that uses the rxLogit function to train a model.
*	__@input_data_1__: by convention represent the query that is accessible via InputDataSet within the R script.
*	__@output_data_1_name__: provides the column name used in the result set containing the serialized model.

Looking at the R script specifically, we have:

```
##Create model
logitObj <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs +
                    direct_distance, data = InputDataSet)
##Serialize model and put it in data frame
trained_model <- data.frame(model=as.raw(serialize(logitObj, NULL)));
```

The second line trains the model using the **rxLogit** method, which performs a **logistic regression**. Observe that the inputs are expressed in a formula syntax that describes what feature to predict and what features to use in its prediction:

```
tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance
```

The formula reads as such:  predict **tipped** given the *passenger_count*, *trip_distance*, *trip_time_in_secs* and *direct_distance*. The source of these features comes from the data set made available via the InputDataSet variable.

After that, we serialize the model into a **data.frame** and store it in the *trained_model* variable, which is returned as an output result set consisting of one cell with the column name *trained_model* and value of the serialized model.

### Operationalize the Model
With trained model in hand, you are ready operationalize the model and make it available to your application.

1. Execute the following script to operationalize the model in a stored procedure.
    - *Create Procedure PredictTip.sql*

Let’s take a closer look at this stored procedure.
```
CREATE PROCEDURE [dbo].[PredictTip]
	@passenger_count int = 0,
	@trip_distance float = 0,
	@trip_time_in_secs int = 0,
	@direct_distance float = 0
AS
BEGIN

  -- Package the inputs as a table	
  DECLARE @inquery nvarchar(max) = N'
	SELECT * FROM [dbo].[fnEngineerFeatures](
		@passenger_count,
		@trip_distance,
		@trip_time_in_secs,
		@direct_distance)
	'

  -- Load the serialized model from the nyc_taxi_models table		
  DECLARE @lmodel2 varbinary(max) = (SELECT TOP 1 model FROM nyc_taxi_models);

  -- Invoke the prediction
  EXEC sp_execute_external_script
		@language = N'R',
       @script = N'
		        	mod <- unserialize(as.raw(model));
                   OutputDataSet<-rxPredict(modelObject = mod, data = InputDataSet,
						    outData = NULL,
						    predVarNames = "Score", type = "response",
                                            writeModelVars = FALSE, overwrite = TRUE);
			',
		@input_data_1 = @inquery,
		@params = N'@model varbinary(max),
					@passenger_count int,
					@trip_distance float,
					@trip_time_in_secs int ,
					@direct_distance float',
              @model = @lmodel2,
		@passenger_count = @passenger_count ,
		@trip_distance = @trip_distance,
		@trip_time_in_secs = @trip_time_in_secs,
		@direct_distance = @direct_distance
		WITH RESULT SETS ((Score float));

END
```
The PredictTip procedure takes as input the passenger count, trip distance (odometer reading), trip time and direct distance (calculated linear distance).

The first query uses the fnEngineerFeatures table valued function to package the values of the input parameters as a table:
```
  DECLARE @inquery nvarchar(max) = N'
	SELECT * FROM [dbo].[fnEngineerFeatures](
		@passenger_count,
		@trip_distance,
		@trip_time_in_secs,
		@direct_distance)
	'
```
After that we retrieve the serialized model from the nyc_taxi_models table:

```
-- Load the serialized model from the nyc_taxi_models table		
  DECLARE @lmodel2 varbinary(max) = (SELECT TOP 1 model FROM nyc_taxi_models);
```

Following that we invoke the prediction using a call to sp_execute_external_script:

```
  --Invoke the prediction
  EXEC sp_execute_external_script
		@language = N'R',
       @script = N'
			mod <- unserialize(as.raw(model));

			OutputDataSet<-rxPredict(modelObject = mod, data = InputDataSet,
						    outData = NULL,
						    predVarNames = "Score", type = "response",
                                             writeModelVars = FALSE, overwrite = TRUE);
			',
		@input_data_1 = @inquery,
		@params = N'@model varbinary(max),
		            @passenger_count int,
			     @trip_distance float,
			     @trip_time_in_secs int ,
			     @direct_distance float',
             @model = @lmodel2,
		@passenger_count = @passenger_count ,
		@trip_distance = @trip_distance,
		@trip_time_in_secs = @trip_time_in_secs,
		@direct_distance = @direct_distance
		WITH RESULT SETS ((Score float));
```

Observe that we pass as input the following parameters:
* @language: needs to indicate that the script is written in the R language.
* @script: this is the actual R script that uses the rxPredict function to make the prediction.
* @input_data_1: the query which contains the one row of data against which we make a prediction.
* @params: defines the parameters and SQL types of all the parameters used.
* @model: the serialized model.
* @passenger_count, @trip_distance, @trip_time_in_secs, @direct_distance: the values that will be packaged into a table after executing the query defined by @inquery.

The R script used for prediction has only the following two lines:
```
mod <- unserialize(as.raw(model));

OutputDataSet<-rxPredict(modelObject = mod, data = InputDataSet,
 			    outData = NULL, predVarNames = "Score", type = "response",
                         writeModelVars = FALSE, overwrite = TRUE);

```

The first line deserializes the model so it is in a form useable by the **rxPredict** method. The second line invokes rxPredict which uses the model against the supplied row of data (within InputDataSet, which is sourced from the query in @inquery).

Finally, the script ends using the following line:

```
WITH RESULT SETS ((Score float));
```

This schematizes the result set returned in OutputDataSet within the R script. This data set has one column, labeled Score with a type of float. The label of “Score” was configured in the call to rxPredict via the predVarNames parameter.

### Execute a prediction in T-SQL
Now you are ready to give your predictive stored procedure a test run.

1. Run the following script to predict the probability of a tip using the PredictTip stored procedure.
    - *Exec PredictTip.sql*
2. You should get a result set consisting of one row and one column (labeled Score), for example:



### Execute the sample in Node.js
Now let’s integrate a call to this stored procedure from our node.js sample application.

1. Within the root of the project directory, at the command line execute:

```
npm install tedious
```

2. This will install the tedious package which we use to connect to SQL Server.

3. Open TipPredictor.js in Visual Studio Code.

4. Near the top, modify the values of the config element so that they contain the appropriate values to connect to your instance of the taxidata database.

Provide the connection details appropriate to your environment (Change the user/pass and instanceName to match your environment)

```
var config = {
userName: 'youruser',
password: 'yourpass',
server: 'localhost',
options: {
database: 'taxidata',
instanceName: 'SQL2016DEVED',
encrypt: true
}
};
```

5. Save the file.
6. Scroll down to the connect.on() callback implementation.

```
connection.on('connect', function(err) {

    if (err)
    {
        console.log("Unable to Connect: " + err);
        return;
    }

    // If no error, then good to go...
    console.log("Connected.");

    executeStatement();

});
```

7.	Observe that this method connects to SQL Server using tedious. If it connects successfully, it executes the method executeStatement().
8.	Look at the implementation for executeStatement().

```
function executeStatement() {
    // Specify the name of the predictive stored procedure
    storedProcedureName = "[dbo].[PredictTip]";

    request = new Request(storedProcedureName, function(err, rowCount) {
        if (err) {
            console.log(err);
        } else {
            console.log(rowCount + ' rows');
        }
    });

    // The input values to the prediction are provided here:
    request.addParameter('passenger_count', TYPES.Int, '1');
    request.addParameter('trip_distance', TYPES.Float, '2.5');
    request.addParameter('trip_time_in_secs', TYPES.Int, '631');
    request.addParameter('direct_distance', TYPES.Float, '2');

    // Iterate over any received rows in the result
    request.on('row', function(columns) {
        columns.forEach(function(column) {
        console.log(column.metadata.colName + " = " + column.value);
        });
    });

    connection.callProcedure(request);
}
```

9. Observe that this method builds up a Request object that takes the stored procedure name and contains the input parameters upon which the prediction will execute. The return value of the stored procedure is handled via the *request.on(‘row’)* callback. The stored procedure is actually invoked at the last statement, via *connection.callProcedure(request)*.

10. Open an instance of the command line and navigate to the directory containing TipPredictor.js.

11. Run the sample application by typing:

```
node TipPredictor.js
```

12.	You should see output like the following (which in this case means there is a 53% chance of a tip):

```
node TipPredictor.js
Connected.
Score = 0.5333974344542649
3 rows
```

### Congratulations!!!
You’ve just trained and operationalized a model using SQL Server 2016 and enabled a node.js application with predictive analytics capabilities.

### Additional resources
