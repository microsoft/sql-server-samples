USE [LendingClub]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[models](
	[model] [varbinary](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

GO

INSERT INTO [dbo].[models]
EXEC sp_execute_external_script
  @language = N'R',
  @script = N'
  randomForestObj <- rxDForest(is_bad ~ revol_util + int_rate + mths_since_last_record + annual_inc_joint + dti_joint + total_rec_prncp + all_util, InputDataSet)
  model <- data.frame(payload = as.raw(serialize(randomForestObj, connection=NULL)))
  ',
  @input_data_1 = N'SELECT revol_util, int_rate, mths_since_last_record, annual_inc_joint, dti_joint, total_rec_prncp, all_util,is_bad FROM [dbo].[LoanStats] WHERE (ABS(CAST((BINARY_CHECKSUM(id, NEWID())) as int)) % 100) < 75',
  @output_data_1_name = N'model';
