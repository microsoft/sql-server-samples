################################################################
# Title: CRM Demo in-SQL
# Author: Microsoft
# Date: Dec, 2015
#################################################################

# Specify connection string and compute context

connectionString <- "Driver=SQL Server;
                     Server=tcp:192.168.176.130,1433;
                     Database=sqlr;
                     Uid=******;
                     Pwd=******"

RFMData <- RxSqlServerData(connectionString=connectionString,
                           table="RFM_Result")

cc <- RxInSqlServer(connectionString=connectionString,
                    autoCleanup=FALSE,
                    consoleOutput=TRUE)

rxSetComputeContext(cc)

rxGetInfo(RFMData, getVarInfo=T, numRows=3)

# Step 1: RFM analysis

# Visualize the RFM values

rxHistogram(~R, data=RFMData, xNumTicks=20)
rxHistogram(~F, data=RFMData, rowSelection=F < 30, xNumTicks=20)
rxHistogram(~M, data=RFMData, rowSelection=M < 200, xNumTicks=20)

# Count frequency of each RFMscore Level

tmp <- rxCube(~F(Toltal_Score), data=RFMData)
results <- rxResultsDF(tmp)
results <- results[results$Counts != 0, ]
results[order(results$Counts, decreasing=TRUE), ]

# Step 2: K-means Clustering

KmeansData <- RxSqlServerData(connectionString=connectionString,
                              table = "Kmeans_Result")

md.km <- rxKmeans(formula=~R+F+M+R_Score+F_Score+M_Score,
		  data=RFMData,
 	          outFile=KmeansData,
		  numClusters=8,
		  algorithm="lloyd",
		  writeModelVars=TRUE,
		  overwrite=TRUE)

rxGetInfo(KmeansData, getVarInfo=TRUE, numRows=10)

centers <- round(md.km$centers, digits=2)
size <- md.km$size
centers.txt <- file.path(output.path, "centers.txt")
write.table(centers, file=centers.txt, sep=" ")
size.txt <- file.path(output.path, "size.txt")
write.table(size, file=size.txt, sep=" ")

# Connect to SQL database via odbcConnect

library(RODBC)

channel<-odbcDriverConnect(connection=connectionString)

# Read Kmeans_Result from SQL via OSR

Kmeans.df <- sqlQuery(channel, paste("select * from dbo.Kmeans_Result"))

head(Kmeans.df)
plot(Kmeans.df[, 2:4], col=Kmeans.df$X_rxCluster)
title(main="RFM-based K-means on CDNOW Data", line=3)	

# Step 3: Prediction-logistic and decision tree

# Create IsVIP variable

RFMVIPData <- RxSqlServerData(connectionString=connectionString,
                              table="RFMVIP")

rxDataStep(inData=RFMData,
           outFile=RFMVIPData,
           transforms=list(IsVIP=ifelse(Toltal_Score >= 441, 1, 0)),
           overwrite=TRUE,
           reportProgress=1)

rxGetInfo(RFMVIPData, getVarInfo=T, numRows=3)
rxGetInfo(RFMVIPRDData, getVarInfo=T, numRows=3)

RFMVIPRDData <- RxSqlServerData(connectionString=connectionString,
                                table="RFMVIPRD")

RFMVIPTrainTestData <- RxSqlServerData(connectionString = connectionString,
                                       table="RFMVIPTrainTest")	

rxDataStep(inData=RFMVIPRDData,
           outFile=RFMVIPTrainTestData,
	   transforms=list(urv=factor(ifelse(RD <= 8,'TRAIN','TEST'))),
           overwrite=T)

rxGetInfo(RFMVIPTrainTestData, T, numRows=3)

## Split data into training/testing data set

TrainData <- RxSqlServerData(connectionString=connectionString,
                             table = "RFMVIPTrainTest.urv.TRAIN")	

TestData <- RxSqlServerData(connectionString=connectionString,
                            table="RFMVIPTrainTest.urv.TEST")	

rxSplit(RFMVIPTrainTestData, outFilesBase=RFMVIPTrainTestData,
        splitByFactor='urv', overwrite=T, reportProgress=1)

## Built our Logistic Regression Model with IsVIP as response

r1<- rxLogit(IsVIP~R+F+M,
             data =RFMVIPData,
             variableSelection = rxStepControl(method="stepwise",
             scope = ~ R+F+M))
             summary(r1)

## r1:stepwise selection shows that Monetary, Recency are significant.
## Build our Logistic Regression Model

r2 <- rxLogit(IsVIP~R+F,
              data=RFMVIPData, covCoef=TRUE)
summary(r2)

## Predict our Logistic Model on our test Dataset

LogisticPred.xdf <- file.path(output.path,"LogisticPred.xdf")
p2 <- rxPredict(r2, data=test.xdf, outData=LogisticPred.xdf,
                writeModelVars=TRUE, extraVarsToWrite="ID",
                computeResiduals=TRUE, computeStdErr=TRUE,
                interval="confidence", predVarNames='LogitPredict',
                overwrite=TRUE)

rxGetInfo(LogisticPred.xdf, getVarInfo=T, numRows=10)
LogisticPredInfoTop10 <- rxGetInfo(LogisticPred.xdf, getVarInfo=T, numRows=10)
LogisticPredInfoTop10.txt <- file.path(output.path, "LogisticPredInfoTop10.txt")
write.table(LogisticPredInfoTop10$data, file=LogisticPredInfoTop10.txt, sep=" ")

## Draw a ROC curve

rxRocCurve(actualVarName='IsVIP',predVarNames='LogitPredict',data=LogisticPred.xdf)

## Build a Decision Tree with Cluster as response

d1 <- rxDTree(Cluster~R+F+M, data=TrainData, blocksPerRead=5)
d1 <- rxDTree(Cluster~R_Score+F_Score+M_Score, data=TrainData, blocksPerRead=5)
d1
d1Cp<- rxDTreeBestCp(d1)
d1 <- prune.rxDTree(d1, cp=d1Cp)
d2 <- rxDTree(Cluster~R+F+M, data=TrainData, pruneCp="auto")
d2 <- rxDTree(Cluster~R_Score+F_Score+M_Score, data=TrainData, pruneCp="auto")
d2

# View Decision Tree

# View 1

library(RevoTreeView)

plot(createTreeView(d1))
plot(createTreeView(d2))

# View 2

library(rpart)

plot(rxAddInheritance(d1))
text(rxAddInheritance(d1))
title(main="RFM-based Decision Tree on CDNOW Data",line=3)

plot(rxAddInheritance(d2))
text(rxAddInheritance(d2))
title(main="RFM-based Decision Tree on CDNOW Data",line=3)	

# Prediction

DTreePred.xdf<-file.path(output.path,"DTreePred.xdf")
rxPredict(d1, data=test.xdf, outData=DTreePred.xdf,
          writeModelVars=TRUE, extraVarsToWrite="ID",
          computeResiduals=T, overwrite=TRUE)

rxGetInfo(DTreePred.xdf, getVarInfo=T, numRows=3)

DTreePredInfoTop10 <- rxGetInfo(DTreePred.xdf, getVarInfo=T, numRows=10)
DTreePredInfoTop10.txt <- file.path(output.path, "DTreePredInfoTop10.txt")
write.table(DTreePredInfoTop10$data, file=DTreePredInfoTop10.txt, sep=" ")

DTreePred <- rxXdfToDataFrame(file=DTreePred.xdf)

sqlSave(channel, DTreePred, rownames=FALSE, append=FALSE,
        varTypes=list(numeric="float",
                      integer="int",
                      Date="date"))
odbcClose(channel)







