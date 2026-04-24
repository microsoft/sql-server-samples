
##################### STEP1 - Connect to DB and read data ####################

#Connection string to connect to SQL Server named instance
connStr <- paste("Driver=SQL Server; Server=", "MYSQLSERVER",
                ";Database=", "Tutorialdb", ";Trusted_Connection=true;", sep = "");

#Get the data from SQL Server Table
SQL_rentaldata <- RxSqlServerData(table = "dbo.rental_data",
                              connectionString = connStr, returnDataFrame = TRUE);

#Import the data into a data frame
rentaldata <- rxImport(SQL_rentaldata);

#Let's see the structure of the data and the top rows
# Ski rental data, giving the number of ski rentals on a given date
head(rentaldata);


##################### STEP2 - Clean and prepare the data ####################

#Changing the three factor columns to factor types
#This helps when building the model because we are explicitly saying that these values are categorical
rentaldata$Holiday <- factor(rentaldata$Holiday);
rentaldata$Snow <- factor(rentaldata$Snow);
rentaldata$WeekDay <- factor(rentaldata$WeekDay);

#Visualize the dataset after the change
str(rentaldata);

##################### STEP3 - train model ####################

#Now let's split the dataset into 2 different sets
#One set for training the model and the other for validating it
train_data = rentaldata[rentaldata$Year < 2015,];
test_data = rentaldata[rentaldata$Year == 2015,];

#Use this column to check the quality of the prediction against actual values
actual_counts <- test_data$RentalCount;

#Model 1: Use rxLinMod to create a linear regression model. We are training the data using the training data set
model_linmod <- rxLinMod(RentalCount ~  Month + Day + WeekDay + Snow + Holiday, data = train_data);

#Model 2: Use rxDTree to create a decision tree model. We are training the data using the training data set
model_dtree <- rxDTree(RentalCount ~ Month + Day + WeekDay + Snow + Holiday, data = train_data);


#################### STEP4 - Predict using the models ########################

#Use the models we just created to predict using the test data set.
#That enables us to compare actual values of RentalCount from the two models and compare to the actual values in the test data set
predict_linmod <- rxPredict(model_linmod, test_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"));

predict_dtree <- rxPredict(model_dtree, test_data, writeModelVars = TRUE, extraVarsToWrite = c("Year"));

#Look at the top rows of the two prediction data sets.
head(predict_linmod);
head(predict_dtree);

#################### STEP5 - Compare models ########################
#Now we will use the plotting functionality in R to viusalize the results from the predictions
#We are plotting the difference between actual and predicted values for both models to compare accuracy
par(mfrow = c(2, 1));
plot(predict_linmod$RentalCount_Pred - predict_linmod$RentalCount, main = "Difference between actual and predicted. rxLinmod");
plot(predict_dtree$RentalCount_Pred - predict_dtree$RentalCount, main = "Difference between actual and predicted. rxDTree");

