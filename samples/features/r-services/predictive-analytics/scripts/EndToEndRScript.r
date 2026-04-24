## Just in case you want to go through the steps on an R tool like (RGui, RStudio or R Tools for VS)
##this script uses rpart instead of rxlogit
## these are the step by step to reproduce the lab

install.packages("RODBC")
library(RODBC)

##Connect to SQL Server 2016, assumes a Windows Authentication method
dbhandle <- odbcDriverConnect('driver={SQL Server};server=<yourservername>;database=taxidata;trusted_connection=true')

##Run the query to brin the data we'll use to create the model
res <- sqlQuery(dbhandle, 'select tipped,  passenger_count, trip_time_in_secs, trip_distance, direct_distance   from nyctaxi_features')

##Create the model...
model <- rxLogit(tipped ~ passenger_count + trip_distance + trip_time_in_secs + direct_distance, res)
summary(model)

##Now, let's create the frame with the parameters for the prediction
prediction_parameters <- data.frame(passenger_count = 1, trip_time_in_secs = 631, trip_distance = 2.5, direct_distance = 2)

##predict
OutputDataFrame <- rxPredict(model, prediction_parameters, outData = NULL, predVarNames = "Score", type = "response", writeModelVars = FALSE, overwrite = TRUE)
OutputDataFrame