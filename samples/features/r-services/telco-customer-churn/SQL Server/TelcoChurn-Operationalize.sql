------------------------------------------------------------------------------------------
--Choose database to use
------------------------------------------------------------------------------------------
use telcoedw2
go

------------------------------------------------------------------------------------------
--View tables
------------------------------------------------------------------------------------------
select top 10 * from dbo.edw_cdr
go

select top 10 * from dbo.edw_cdr_train
go

select top 10 * from dbo.edw_cdr_test
go

--------------------------------------------------------------------------------------------
--Create stored procedures to train models
--------------------------------------------------------------------------------------------
--Create a table to store modeling results
drop table if exists cdr_rx_models;
go
create table cdr_rx_models(
	model_name varchar(30) not null default('default model') primary key,
	model varbinary(max) not null
);
go

--Create a stored procedure to train Xgboost model
drop procedure if exists generate_cdr_xgboost;
go
create procedure generate_cdr_xgboost
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		library(Matrix)
        library(xgboost)
		trainData<-edw_cdr_train
        ntrainData <- apply(trainData[, -27], 2, as.numeric)
        dtrainData <- list()
        dtrainData$data <- Matrix(ntrainData, sparse = TRUE)
        dtrainData$label <- as.numeric(trainData$churn) - 1
        str(dtrainData)
         xgboost_model <- xgboost(data = dtrainData$data,
		                 label = dtrainData$label,
						 max.depth = 32,
						 eta = 1,
						 nthread = 2,
						 nround = 2,
						 objective = "binary:logistic")
		xgboost_model <- data.frame(payload = as.raw(serialize(xgboost_model, connection=NULL)));
'
	, @input_data_1 = N'select * from edw_cdr_train'
	, @input_data_1_name = N'edw_cdr_train'
	, @output_data_1_name = N'xgboost_model'
	with result sets ((model varbinary(max)));
end;
go

--Update rxDForest modeling results
insert into cdr_rx_models (model)
exec generate_cdr_xgboost;
update cdr_rx_models set model_name = 'xgboost' where model_name = 'default model';
select * from cdr_rx_models;
go

--Create a stored procedure to train Decision Forest Model with RevoScaleR
drop procedure if exists generate_cdr_rx_DForest;
go
create procedure generate_cdr_rx_DForest
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		require("RevoScaleR");
        train_vars <- rxGetVarNames(edw_cdr_train)
        train_vars <- train_vars[!train_vars  %in% c("churn")]
        temp<-paste(c("churn",paste(train_vars, collapse="+") ),collapse="~")
        formula<-as.formula(temp)
        rx_forest_model <- rxDForest(formula = formula,
                            data = edw_cdr_train,
                            nTree = 8,
                            maxDepth = 32,
                            mTry = 2,
                            minBucket=1,
                            replace = TRUE,
                            importance = TRUE,
                            seed=8,
                            parms=list(loss=c(0,4,1,0)))
		rxDForest_model <- data.frame(payload = as.raw(serialize(rx_forest_model, connection=NULL)));
'
	, @input_data_1 = N'select * from edw_cdr_train'
	, @input_data_1_name = N'edw_cdr_train'
	, @output_data_1_name = N'rxDForest_model'
	with result sets ((model varbinary(max)));
end;
go

--Update rxDForest modeling results
insert into cdr_rx_models (model)
exec generate_cdr_rx_DForest;
update cdr_rx_models set model_name = 'rxDForest' where model_name = 'default model';
select * from cdr_rx_models;
go

--Create a stored procedure to train Boosted Tree Model with RevoScaleR
drop procedure if exists generate_cdr_rx_BTrees;
go
create procedure generate_cdr_rx_BTrees
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		require("RevoScaleR");
		train_vars <- rxGetVarNames(edw_cdr_train)
        train_vars <- train_vars[!train_vars  %in% c("churn")]
        temp<-paste(c("churn",paste(train_vars, collapse="+") ),collapse="~")
        formula<-as.formula(temp)
		rx_boosted_model <- rxBTrees(formula = formula,
                            data = edw_cdr_train,
                            minSplit=10,
                            minBucket = 10,
                            learningRate = 0.2,
                            nTree = 100,
                            mTry = 2,
                            maxDepth = 10,
                            useSurrogate = 0,
                            replace = TRUE,
                            importance=TRUE,
                            lossFunction = "bernoulli")
		rxBTrees_model <- data.frame(payload = as.raw(serialize(rx_boosted_model, connection=NULL)));
'
	, @input_data_1 = N'select * from edw_cdr_train'
	, @input_data_1_name = N'edw_cdr_train'
	, @output_data_1_name = N'rxBTrees_model'
	with result sets ((model varbinary(max)));
end;
go

--Update rxBTrees modeling results
insert into cdr_rx_models (model)
exec generate_cdr_rx_BTrees;
update cdr_rx_models set model_name = 'rxBTrees' where model_name = 'default model';
select * from cdr_rx_models;
go

--Create a stored procedure to visualize the importance of each feature
drop procedure if exists importance;
go
create procedure importance (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from cdr_rx_models where model_name = @model);
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
require("RevoScaleR");
cdr_model<-unserialize(rx_model);
image_file = tempfile();
jpeg(filename=image_file, width=800, height = 550);
print(
rxVarImpPlot(cdr_model)
);
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model	
	with result sets ((plot varbinary(max)));
end;
go

exec importance 'rxDForest';
go

--------------------------------------------------------------------------------------------
--Create stored procedures to score models
--------------------------------------------------------------------------------------------
--Create a stored procedure to score Xgboost model
drop procedure if exists predict_cdr_churn_xgboost;
go
create procedure predict_cdr_churn_xgboost (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from cdr_rx_models where model_name = @model);
	-- Predict based on the specified model:
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
library(Matrix)
library(xgboost)
cdr_model<-unserialize(rx_model);
testData<-edw_cdr_test
ntestData <- apply(testData[, -27], 2, as.numeric)
dtestData <- list()
dtestData$data <- Matrix(ntestData, sparse = TRUE)
dtestData$label <- as.numeric(testData$churn) - 1
str(dtestData)
predictions <- predict(cdr_model, dtestData$data)
threshold <- 0.5
probability <- predictions
prediction <- ifelse(probability > threshold, 1, 0)
edw_cdr_test_pred <- cbind(edw_cdr_test[,c("customerid","churn")],probability,prediction)
print(head(edw_cdr_test_pred))
edw_cdr_test_pred<-as.data.frame(edw_cdr_test_pred);
'
	, @input_data_1 = N'
	select * from edw_cdr_test'
	, @input_data_1_name = N'edw_cdr_test'
	, @output_data_1_name=N'edw_cdr_test_pred'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model
	with result sets ( ("customerid" int, "churn" varchar(255), "probability " float, "prediction" float)
			  );
end;
go

--Execute scoring procedure
drop table if exists edw_cdr_test_pred;
go
create table edw_cdr_test_pred(
customerid int,
churn varchar(255),
probability float,
prediction float
)
insert into edw_cdr_test_pred
exec predict_cdr_churn_xgboost 'xgboost';
go
select * from edw_cdr_test_pred


--Create a stored procedure to score Decision Forest Model with RevoScaleR
drop procedure if exists predict_cdr_churn_rx_forest;
go
create procedure predict_cdr_churn_rx_forest (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from cdr_rx_models where model_name = @model);
	-- Predict based on the specified model:
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
require("RevoScaleR");
cdr_model<-unserialize(rx_model);
predictions <- rxPredict(modelObject = cdr_model,
                         data = edw_cdr_test,
						 type="prob",
                         overwrite = TRUE)
print(head(predictions))
threshold <- 0.5
predictions$X0_prob <- NULL
predictions$churn_Pred <- NULL
names(predictions) <- c("probability")
predictions$prediction <- ifelse(predictions$probability > threshold, 1, 0)
predictions$prediction<- factor(predictions$prediction, levels = c(1, 0))
edw_cdr_test_pred <- cbind(edw_cdr_test[,c("customerid","churn")],predictions)
print(head(edw_cdr_test_pred))
edw_cdr_test_pred<-as.data.frame(edw_cdr_test_pred);
'
	, @input_data_1 = N'
	select * from edw_cdr_test'
	, @input_data_1_name = N'edw_cdr_test'
	, @output_data_1_name=N'edw_cdr_test_pred'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model
	with result sets ( ("customerid" int, "churn" varchar(255), "probability " float, "prediction" float)
			  );
end;
go

--Execute scoring procedure
drop table if exists edw_cdr_test_pred;
go
create table edw_cdr_test_pred(
customerid int,
churn varchar(255),
probability float,
prediction float
)
insert into edw_cdr_test_pred
exec predict_cdr_churn_rx_forest 'rxDForest';
go
select * from edw_cdr_test_pred

--Create a stored procedure to score Boosted Tree Model with RevoScaleR
drop procedure if exists predict_cdr_churn_rx_boost;
go
create procedure predict_cdr_churn_rx_boost (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from cdr_rx_models where model_name = @model);
	-- Predict based on the specified model:
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
require("RevoScaleR");
cdr_model<-unserialize(rx_model);
predictions <- rxPredict(modelObject = cdr_model,
                         data = edw_cdr_test,
                         type = "prob",
                         overwrite = TRUE)
print(head(predictions))
threshold <- 0.5
names(predictions) <- c("probability")
predictions$prediction <- ifelse(predictions$probability > threshold, 1, 0)
predictions$prediction <- factor(predictions$prediction, levels = c(1, 0))
edw_cdr_test_pred <- cbind(edw_cdr_test[,c("customerid","churn")],predictions)
print(head(edw_cdr_test_pred))
edw_cdr_test_pred<-as.data.frame(edw_cdr_test_pred);
'
	, @input_data_1 = N'
	select * from edw_cdr_test'
	, @input_data_1_name = N'edw_cdr_test'
	, @output_data_1_name=N'edw_cdr_test_pred'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model	
	with result sets ( ("customerid" int, "churn" varchar(255), "probability" float, "prediction" float)
			  );
end;
go

--Execute scoring procedure
drop table if exists edw_cdr_test_pred;
go
create table edw_cdr_test_pred(
customerid int,
churn varchar(255),
probability float,
prediction float
)
insert into edw_cdr_test_pred
exec predict_cdr_churn_rx_boost 'rxBTrees';
go
select * from edw_cdr_test_pred

--------------------------------------------------------------------------------------------
--Create stored procedures to evaluate models
--------------------------------------------------------------------------------------------
--Create a stored procedure to evaluate model performance
drop procedure if exists model_evaluate;
go
create procedure model_evaluate
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
  evaluate_model <- function(data, observed, predicted) {
    confusion <- table(data[[observed]], data[[predicted]])
    print(confusion)
    tp <- confusion[rownames(confusion) == 1, colnames(confusion) == 1]
    fn <- confusion[rownames(confusion) == 1, colnames(confusion) == 0]
    fp <- confusion[rownames(confusion) == 0, colnames(confusion) == 1]
    tn <- confusion[rownames(confusion) == 0, colnames(confusion) == 0]
    accuracy <- (tp + tn) / (tp + fn + fp + tn)
    precision <- tp / (tp + fp)
    recall <- tp / (tp + fn)
    fscore <- 2 * (precision * recall) / (precision + recall)
    metrics <- c("Accuracy" = accuracy,
               "Precision" = precision,
               "Recall" = recall,
               "F-Score" = fscore)
    return(metrics)
}

metrics <- evaluate_model(data = edw_cdr_test_pred,
                                  observed = "churn",
                                  predicted = "prediction")
print(metrics)
metrics<-matrix(metrics,ncol=4)
metrics<-as.data.frame(metrics);
'
	, @input_data_1 = N'
	select * from edw_cdr_test_pred'
	, @input_data_1_name = N'edw_cdr_test_pred'
	, @output_data_1_name = N'metrics'
	with result sets ( ("Accuracy" float, "Precision" float, "Recall" float, "F-Score" float)
			  );
end;
go

--Execute evaluating procedure
exec model_evaluate
go

--Create a stored procedure to generate roc curve
drop procedure if exists model_roccurve;
go
create procedure model_roccurve
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
  require("RevoScaleR");

  roc_curve <- function(data, observed, predicted) {
  data <- data[, c(observed, predicted)]
  data[[observed]] <- as.numeric(as.character(data[[observed]]))
  rxRocCurve(actualVarName = observed,
             predVarNames = predicted,
             data = data)
}

# Open a jpeg file and output plot in that file.
image_file = tempfile();
jpeg(filename=image_file, width=800, height = 550);
print(
roc_curve(data = edw_cdr_test_pred,
          observed = "churn",
          predicted = "probability")
);
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
'
	, @input_data_1 = N'
	select * from edw_cdr_test_pred'
	, @input_data_1_name = N'edw_cdr_test_pred'
	with result sets ((plot varbinary(max)));
end;
go

exec model_roccurve
go


--------------------------------------------------------------------------------------------
--Create stored procedures to generate plots for visualization
--------------------------------------------------------------------------------------------
--Create a stroed procedure to plot pareto chart for churn
drop procedure if exists pareto;
go
create procedure pareto
as
begin
exec sp_execute_external_script
      @language = N'R',
	  @script = N'

# Set output directory for files
# Prior to plotting ensure there are no files with same file names as the out files below in the above directory.
# Calculate counts(percentages) of customers churned or non-churned
require("RevoScaleR");
tmp<- rxCube(~ F(churn),edw_cdr,means=FALSE)
Results_df<- rxResultsDF(tmp)
library(qcc)
CountOfChurn<-
  setNames(as.numeric(Results_df[,2]), Results_df[,1])

# Open a jpeg file and output plot in that file.
image_file = tempfile();
jpeg(filename=image_file, width=800, height = 550);
print(
pareto<-pareto.chart(CountOfChurn,
                     xlab="Churn", ylab="Counts",
                     ylab2="Cumulative Percentage",cex.names=0.5,las=1,
                     col=heat.colors(length(CountOfChurn)),plot=TRUE)
);
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
'
   , @input_data_1 = N'select * from edw_cdr'
   , @input_data_1_name = N'edw_cdr'
	with result sets ((plot varbinary(max)));
end;
go

--Execute pareto procedure
exec pareto
go

--Create a stored procedure to draw histogram over age by churn
drop procedure if exists histogram;
go
create procedure histogram
as
begin
exec sp_execute_external_script
      @language = N'R',
	  @script = N'
require("RevoScaleR");
# Set output directory for files
# Prior to plotting ensure there are no files with same file names as the out files below in the above directory.
# Open a jpeg file and output plot in that file.
image_file = tempfile();
jpeg(filename=image_file, width=800, height = 550);
##Counts of Customers over Age by Churn
print(
rxHistogram(~age|F(churn),edw_cdr,reportProgress=0)
);
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
'
   , @input_data_1 = N'select * from edw_cdr'
   , @input_data_1_name = N'edw_cdr'
	with result sets ((plot varbinary(max)));
end;
go

--Execute histogram procedure
exec histogram
go

--Create a stored procedure to plot heatmap for age and state
drop procedure if exists heatmap;
go
create procedure heatmap
as
begin
exec sp_execute_external_script
      @language = N'R',
	  @script = N'

# Set output directory for files
# Prior to plotting ensure there are no files with same file names as the out files below in the above directory.
# Calculate counts of churned customers by age and state with RevoScaleR
require("RevoScaleR");
tmp<- rxCrossTabs(N(churn)~ F(age):F(state),edw_cdr,means=FALSE)
Results_df <- rxResultsDF(tmp,output="sums")
colnames(Results_df)<-substring(colnames(Results_df),7)
library(gplots)
# Open a jpeg file and output plot in that file.
image_file = tempfile();
jpeg(filename=image_file, width=800, height = 550);
print(
heatmap.2(data.matrix(Results_df[,-1]),
          labRow=Results_df[,1], col=cm.colors(255),
          trace="none",dendrogram ="none",
          na.color=par("bg"))
);
dev.off();
OutputDataSet <- data.frame(data=readBin(file(image_file, "rb"), what=raw(), n=1e6));
'
   , @input_data_1 = N'select * from edw_cdr'
   , @input_data_1_name = N'edw_cdr'
	with result sets ((plot varbinary(max)));
end;
go

--Execute heatmap procedure
exec heatmap
go

