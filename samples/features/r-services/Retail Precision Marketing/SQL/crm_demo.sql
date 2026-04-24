--use the database RREDemoSql

use sqlr;
go

drop procedure if exists get_CDNOW_RFM
go

--create stored procedure to get RFM

create proc get_CDNOW_RFM (@start datetime = '1900-1-1', @end datetime = '3000-1-1', @now datetime = null)
as
begin
if @now is null
	set @now = getdate()

select
	ID, DATEDIFF(d,R,@now) as R ,F,M
from
(select
 	ID, MAX([Date]) as R, COUNT(Volume) as F, round(avg(Amount),2) as M
from
	[dbo].[CDNOW]
 where
	[Date] BETWEEN @start AND @end
 group by ID ) as rfm_tmp
order by cast (ID as int)
end
go

--execute the stored procedure to obtain CDNOWRFM table

exec dbo.get_CDNOW_RFM @start='1997-1-1',@end='1998-7-1',@now='1998-7-1'
go

drop procedure if exists BreakScoreRFM
go

--create stored procedure to break RFM score

create proc BreakScoreRFM (@start datetime = '1900-1-1', @end datetime = '3000-1-1', @now datetime = null,
      @r_cut varchar(254) = null, @f_cut varchar(254) = null, @m_cut varchar(254) = null)
as
begin
      if @now is null
            set @now = getdate()

      declare @r_cut1 float = 100, @r_cut2 float = 200, @r_cut3 float = 300, @r_cut4 float = 400
      declare @f_cut1 float = 100, @f_cut2 float = 200, @f_cut3 float = 300, @f_cut4 float = 400
      declare @m_cut1 float = 100, @m_cut2 float = 200, @m_cut3 float = 300, @m_cut4 float = 400
      declare @idx int = 0, @len int = 0
      --get cut parameter, should add more code to check cut parameter.
      if(@r_cut is not null) -- and @r_cut follow the syntax
      begin
            set @idx = CHARINDEX('-',@r_cut)
            set @len = len(@r_cut)
            set @r_cut1 = substring(@r_cut,1,@idx-1)
            set @r_cut=substring(@r_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@r_cut)
            set @len = len(@r_cut)
            set @r_cut2 = substring(@r_cut,1,@idx-1)
            set @r_cut=substring(@r_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@r_cut)
            set @len = len(@r_cut)
            set @r_cut3 = substring(@r_cut,1,@idx-1)
            set @r_cut4=substring(@r_cut,@idx+1,@len-@idx)
      end

      if(@f_cut is not null) -- and @f_cut follow the syntax
      begin
            set @idx = CHARINDEX('-',@f_cut)
            set @len = len(@f_cut)
            set @f_cut1 = substring(@f_cut,1,@idx-1)
            set @f_cut=substring(@f_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@f_cut)
            set @len = len(@f_cut)
            set @f_cut2 = substring(@f_cut,1,@idx-1)
            set @f_cut=substring(@f_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@f_cut)
            set @len = len(@f_cut)
            set @f_cut3 = substring(@f_cut,1,@idx-1)
            set @f_cut4=substring(@f_cut,@idx+1,@len-@idx)
      end

      if(@m_cut is not null) -- and @m_cut follow the syntax
      begin
            set @idx = CHARINDEX('-',@m_cut)
            set @len = len(@m_cut)
            set @m_cut1 = substring(@m_cut,1,@idx-1)
            set @m_cut=substring(@m_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@m_cut)
            set @len = len(@m_cut)
            set @m_cut2 = substring(@m_cut,1,@idx-1)
            set @m_cut=substring(@m_cut,@idx+1,@len-@idx)

            set @idx = CHARINDEX('-',@m_cut)
            set @len = len(@m_cut)
            set @m_cut3 = substring(@m_cut,1,@idx-1)
            set @m_cut4=substring(@m_cut,@idx+1,@len-@idx)
      end

      --drop exists tmp tables.
      if exists (select 1 from sys.tables where [object_id] =object_id('RFM_Score') and type= 'U')
      begin
            truncate table RFM_Score
            drop table RFM_Score
      end

      if exists (select 1 from sys.tables where [object_id] =object_id('RFM') and type= 'U')
      begin
            truncate table RFM
            drop table RFM
      end
      -- get RFM table from initial data.
      select
            ID, DATEDIFF(d,R,@now) as R, F, M into RFM
      from
      (select
            ID, max([Date]) as R, count(Volume) as F, round(avg(Amount),2) as M
      from
            CDNOW
       where
            [Date] between @start and @end
       group by ID ) as rfm_tmp
      order by cast (ID as int)

      -- record R_Score at temp table '#R'
      select
            ID,
            case when R <= @r_cut1 then 5
                  when R > @r_cut1 and R <= @r_cut2 then 4
                  when R > @r_cut2 and R <= @r_cut3 then 3
                  when R > @r_cut3 and R <= @r_cut4 then 2
                  when R > @r_cut4 then 1
            else 0
            end as R_Score
      into #R
      from RFM

      -- score F
      select
            ID,
            case when F >= @f_cut4 then 5
                  when F > @f_cut3 and F <= @f_cut4 then 4
                  when F > @f_cut2 and F <= @f_cut3 then 3
                  when F > @f_cut3 and F <= @f_cut4 then 2
                  when F < @f_cut4 then 1
            else 0
            end as F_Score
      into #F
      from RFM

      -- score M
      select
            ID,
            case when M >= @m_cut4 then 5
                  when M > @m_cut3 and M <= @m_cut4 then 4
                  when M > @m_cut2 and M <= @m_cut3 then 3
                  when M > @m_cut3 and M <= @m_cut4 then 2
                  when M < @m_cut4 then 1
            else 0
            end as M_Score
      into #M
      from RFM

      --union all
      select #R.ID, R_Score, F_Score, M_Score, R_Score*100 + F_Score*10 + M_Score as Toltal_Score
                  into RFM_Score
      from #R, #F, #M
      where #R.ID = #F.ID and #R.ID = #M.ID

      select * from RFM_Score order by Toltal_Score desc,ID
end

go

--execute the stored procedure to obtain RFM_Score table

exec dbo.BreakScoreRFM @start ='1997-1-1', @end = '1998-7-1' ,@now = '1998-7-1', @r_cut ='142-433-486-513', @f_cut = '1-1-2-4', @m_cut ='14.37-20.25-29.37-44.29'
go

--combine RFM and RFM_Score

drop table RFM_Result;
select a.*, b.R_Score, b.F_Score, b.M_Score, b.Toltal_Score
into RFM_Result
from
  [dbo].[RFM] a  left outer join
  [dbo].[RFM_Score] b on
      a.[ID] = b.[ID];
select top 10 * from RFM_Result;

--create stored procedure to visualize RFM

drop procedure if exists visualizeRFM;
go
create procedure visualizeRFM
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		drawHistograms <- function(df,r=5,f=5,m=5){
        #set the layout plot window
        par(mfrow = c(f,r))
        names <-rep("",times=m)
        for(i in 1:m) names[i]<-paste("M",i)
        for (i in 1:f){
	        for (j in 1:r){
		      c <- rep(0,times=m)
		        for(k in 1:m){
			      tmpdf <-df[df$R_Score==j & df$F_Score==i & df$M_Score==k,]
			      c[k]<- dim(tmpdf)[1]
                }
		    if (i==1 & j==1)
			    barplot(c,col="lightblue",names.arg=names)
		    else
			barplot(c,col="lightblue")
		    if (j==1) title(ylab=paste("F",i))	
		    if (i==1) title(main=paste("R",j))	
            }
       }
	   par(mfrow = c(1,1))
    }
	RFMhist<-drawHistograms(RFM_Result[,1:4])
	ff= tempfile()
	png(filename=ff, width=620, height=240)
	print(RFMhist)
	dev.off()
    OutputDataSet <- data.frame(data=readBin(file(ff, "rb"), what=raw(), n=1e6));
	   '
	, @input_data_1 = N'select "R", "F", "M" from RFM_Result'
	, @input_data_1_name = N'RFM_Result'
	with result sets ((plot varbinary(max)));
end;
go
grant execute on visualizeRFM to rdemo;
go

--clustering based on RFM

drop table if exists Kmeans_Result;
drop table if exists CDNOW_rx_models;
go
create table CDNOW_rx_models(
	model_name varchar(30) not null default('default model') primary key,
	model varbinary(max) not null
);
go

create table Kmeans_Result (
		"X_rxCluster" int  null
		, "R" int null, "F" int null, "M" float null
		, "R_Score" int null, "F_Score" int null, "M_Score" int null
);
go

--create stored procedure to do clustering

drop procedure if exists generate_CDNOW_rx_Kmeans;
go
create procedure generate_CDNOW_rx_Kmeans
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		require("RevoScaleR");
		CDNOWKmeans <- rxKmeans(formula=~R+F+M+R_Score+F_Score+M_Score,
						                data=RFM_Result,
 						                #outFile=Kmeans_Result,
						                numClusters=8,
					                	algorithm="lloyd",
						                writeModelVars=TRUE,
					                	overwrite=TRUE)
		rxKmeans_model <- data.frame(payload=as.raw(serialize(CDNOWKmeans, connection=NULL)));
'
	, @input_data_1 = N'select * from RFM_Result'
	, @input_data_1_name = N'RFM_Result'
	, @output_data_1_name = N'rxKmeans_model'
	with result sets ((model varbinary(max)));
end;
go

--how to write Kmeans_Result back to database?[To Be Modified]

insert into CDNOW_rx_models (model)
exec generate_CDNOW_rx_Kmeans;
update CDNOW_rx_models set model_name = 'rxKmeans' where model_name = 'default model';
select * from CDNOW_rx_models;
go

--create stored procedure to build logistic regression model

drop procedure if exists generate_CDNOW_rx_Logit;
go
create procedure generate_CDNOW_rx_Logit
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		require("RevoScaleR");
		CDNOWLogit <- rxLogit(IsVIP~R+F+M,
                          data=RFMVIPCluster,
                          variableSelection=rxStepControl(method="stepwise",
                          scope=~R+F+M))
    summary(CDNOWLogit)
		rxLogit_model <- data.frame(payload = as.raw(serialize(CDNOWLogit, connection=NULL)));
'
	, @input_data_1 = N'select * from RFMVIPCluster'
	, @input_data_1_name = N'RFMVIPCluster'
	, @output_data_1_name = N'rxLogit_model'
	with result sets ((model varbinary(max)));
end;
go

insert into CDNOW_rx_models (model)
exec generate_CDNOW_rx_Logit;
update CDNOW_rx_models set model_name = 'rxLogit' where model_name = 'default model';
select * from CDNOW_rx_models;
go

--create stored procedure to build decision tree model

drop procedure if exists generate_CDNOW_rx_Dtree;
go
create procedure generate_CDNOW_rx_Dtree
as
begin
	execute sp_execute_external_script
	  @language = N'R'
	, @script = N'
		require("RevoScaleR");
		CDNOWDtree <- rxDTree(Cluster~R+F+M, data=RFMVIPCluster, pruneCp="auto")
		rxDtree_model <- data.frame(payload=as.raw(serialize(CDNOWDtree, connection=NULL)));
'
	, @input_data_1 = N'select * from RFMVIPCluster'
	, @input_data_1_name = N'RFMVIPCluster'
	, @output_data_1_name = N'rxDtree_model'
	with result sets ((model varbinary(max)));
end;
go

insert into CDNOW_rx_models (model)
exec generate_CDNOW_rx_Dtree;
update CDNOW_rx_models set model_name = 'rxDtree' where model_name = 'default model';
select * from CDNOW_rx_models;
go

--create stored procedure to predict whether the customer is VIP or not

drop procedure if exists predict_CDNOW_IsVIP;
go
create procedure predict_CDNOW_IsVIP (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from CDNOW_rx_models where model_name = @model);
	-- Predict based on the specified model:
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
          require("RevoScaleR");
          CDNOWmodel <- unserialize(rx_model);
          CDNOWpred <- rxPredict(CDNOWmodel, data=RFMVIPCluster, writeModelVars = TRUE);
          OutputDataSet <- cbind(RFMVIPCluster[,1], CDNOWpred$IsVIP, round(CDNOWpred$IsVIP_Pred,2));
          colnames(OutputDataSet) <- c("ID", "IsVIP.Actual", "IsVIP.Expected");
          OutputDataSet <- as.data.frame(OutputDataSet);
'
	, @input_data_1 = N'
	select * from RFMVIPCluster'
	, @input_data_1_name = N'RFMVIPCluster'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model
	with result sets ( ("ID" int, "IsVIP.Actual" int, "IsVIP.Expected" float)
			  );
end;
go

--execute the stored procedure to obtain the prediction on IsVIP

exec predict_CDNOW_IsVIP 'rxLogit';
go

--create stored procedure to predict which cluster the customer belongs to

drop procedure if exists predict_CDNOW_Cluster;
go
create procedure predict_CDNOW_Cluster (@model varchar(100))
as
begin
	declare @rx_model varbinary(max) = (select model from CDNOW_rx_models where model_name = @model);
	-- Predict based on the specified model:
	exec sp_execute_external_script
					@language = N'R'
				  , @script = N'
          require("RevoScaleR");
          CDNOWmodel <- unserialize(rx_model);
          CDNOWpred <- rxPredict(CDNOWmodel,
                                 data=RFMVIPCluster,
                                 predVarNames=c("prob1", "prob2", "prob3", "prob4", "prob5", "prob6", "prob7", "prob8"),
                                 writeModelVars=TRUE, extraVarsToWrite="ID",
                                 computeResiduals=T, overwrite=TRUE);
          OutputDataSet <- round(cbind(RFMVIPCluster[,1], RFMVIPCluster[,10],
                                CDNOWpred$prob1,CDNOWpred$prob2,CDNOWpred$prob3,CDNOWpred$prob4,
					                      CDNOWpred$prob5,CDNOWpred$prob6,CDNOWpred$prob7,CDNOWpred$prob8),2);
					
          colnames(OutputDataSet) <- c("ID", "Cluster.Actual", "Cluster1.Prob","Cluster2.Prob","Cluster3.Prob","Cluster4.Prob","Cluster5.Prob","Cluster6.Prob","Cluster7.Prob","Cluster8.Prob");
          OutputDataSet<-as.data.frame(OutputDataSet);
  '
	, @input_data_1 = N'
	select * from RFMVIPCluster'
	, @input_data_1_name = N'RFMVIPCluster'
	, @params = N'@rx_model varbinary(max)'
	, @rx_model = @rx_model
	with result sets ( ("ID" int, "Cluster.Actual" int, "Cluster1.Prob" float,"Cluster2.Prob" float,"Cluster3.Prob" float,"Cluster4.Prob" float,"Cluster5.Prob" float,"Cluster6.Prob" float,"Cluster7.Prob" float,"Cluster8.Prob" float)
			  );
end;
go

--execute the stored procedure to obtain the prediction on Cluster

exec predict_CDNOW_Cluster 'rxDtree';
go