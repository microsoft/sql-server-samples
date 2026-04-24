USE [master]
GO

/****** Object:  Database [LendingClub]    Script Date: 12/29/2016 9:29:37 PM ******/
CREATE DATABASE [LendingClub]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'LendingClubData', FILENAME = N'C:\Tiger\DATA\LendingClub.mdf' , SIZE = 19210240KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536MB ),
 FILEGROUP [InMemOLTP] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
( NAME = N'InMem', FILENAME = N'C:\Tiger\DATA\InMem' , MAXSIZE = UNLIMITED)
 LOG ON
( NAME = N'LendingClubLog', FILENAME = N'C:\Tiger\DATA\LendingClub_log.ldf' , SIZE = 512MB , MAXSIZE = 2048GB , FILEGROWTH = 64MB )
GO

ALTER DATABASE [LendingClub] SET COMPATIBILITY_LEVEL = 130
GO

ALTER DATABASE [LendingClub] SET ANSI_NULL_DEFAULT OFF
GO

ALTER DATABASE [LendingClub] SET ANSI_NULLS OFF
GO

ALTER DATABASE [LendingClub] SET ANSI_PADDING OFF
GO

ALTER DATABASE [LendingClub] SET ANSI_WARNINGS OFF
GO

ALTER DATABASE [LendingClub] SET ARITHABORT OFF
GO

ALTER DATABASE [LendingClub] SET AUTO_CLOSE OFF
GO

ALTER DATABASE [LendingClub] SET AUTO_SHRINK OFF
GO

ALTER DATABASE [LendingClub] SET AUTO_UPDATE_STATISTICS ON
GO

ALTER DATABASE [LendingClub] SET CURSOR_CLOSE_ON_COMMIT OFF
GO

ALTER DATABASE [LendingClub] SET CURSOR_DEFAULT  GLOBAL
GO

ALTER DATABASE [LendingClub] SET CONCAT_NULL_YIELDS_NULL OFF
GO

ALTER DATABASE [LendingClub] SET NUMERIC_ROUNDABORT OFF
GO

ALTER DATABASE [LendingClub] SET QUOTED_IDENTIFIER OFF
GO

ALTER DATABASE [LendingClub] SET RECURSIVE_TRIGGERS OFF
GO

ALTER DATABASE [LendingClub] SET  ENABLE_BROKER
GO

ALTER DATABASE [LendingClub] SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO

ALTER DATABASE [LendingClub] SET DATE_CORRELATION_OPTIMIZATION OFF
GO

ALTER DATABASE [LendingClub] SET TRUSTWORTHY OFF
GO

ALTER DATABASE [LendingClub] SET ALLOW_SNAPSHOT_ISOLATION OFF
GO

ALTER DATABASE [LendingClub] SET PARAMETERIZATION SIMPLE
GO

ALTER DATABASE [LendingClub] SET READ_COMMITTED_SNAPSHOT OFF
GO

ALTER DATABASE [LendingClub] SET HONOR_BROKER_PRIORITY OFF
GO

ALTER DATABASE [LendingClub] SET RECOVERY SIMPLE
GO

ALTER DATABASE [LendingClub] SET  MULTI_USER
GO

ALTER DATABASE [LendingClub] SET PAGE_VERIFY CHECKSUM
GO

ALTER DATABASE [LendingClub] SET DB_CHAINING OFF
GO

ALTER DATABASE [LendingClub] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF )
GO

ALTER DATABASE [LendingClub] SET TARGET_RECOVERY_TIME = 60 SECONDS
GO

ALTER DATABASE [LendingClub] SET DELAYED_DURABILITY = DISABLED
GO

ALTER DATABASE [LendingClub] SET QUERY_STORE = OFF
GO

USE [LendingClub]
GO

ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO

ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO

ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO

ALTER DATABASE [LendingClub] SET  READ_WRITE
GO

USE [LendingClub]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoanStatsStaging]
(
	[id] [int] NULL,
	[member_id] [int] NULL,
	[loan_amnt] [int] NULL,
	[funded_amnt] [int] NULL,
	[funded_amnt_inv] [int] NULL,
	[term] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[int_rate] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[installment] [float] NULL,
	[grade] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[sub_grade] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[emp_title] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[emp_length] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[home_ownership] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[annual_inc] [float] NULL,
	[verification_status] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[issue_d] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[loan_status] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[pymnt_plan] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[url] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[desc] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[purpose] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[title] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[zip_code] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[addr_state] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[dti] [float] NULL,
	[delinq_2yrs] [int] NULL,
	[earliest_cr_line] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[inq_last_6mths] [int] NULL,
	[mths_since_last_delinq] [int] NULL,
	[mths_since_last_record] [int] NULL,
	[open_acc] [int] NULL,
	[pub_rec] [int] NULL,
	[revol_bal] [int] NULL,
	[revol_util] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[total_acc] [int] NULL,
	[initial_list_status] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[out_prncp] [float] NULL,
	[out_prncp_inv] [float] NULL,
	[total_pymnt] [float] NULL,
	[total_pymnt_inv] [float] NULL,
	[total_rec_prncp] [float] NULL,
	[total_rec_int] [float] NULL,
	[total_rec_late_fee] [float] NULL,
	[recoveries] [float] NULL,
	[collection_recovery_fee] [float] NULL,
	[last_pymnt_d] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[last_pymnt_amnt] [float] NULL,
	[next_pymnt_d] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[last_credit_pull_d] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[collections_12_mths_ex_med] [int] NULL,
	[mths_since_last_major_derog] [int] NULL,
	[policy_code] [int] NULL,
	[application_type] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[annual_inc_joint] [float] NULL,
	[dti_joint] [float] NULL,
	[verification_status_joint] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[acc_now_delinq] [int] NULL,
	[tot_coll_amt] [int] NULL,
	[tot_cur_bal] [int] NULL,
	[open_acc_6m] [int] NULL,
	[open_il_6m] [int] NULL,
	[open_il_12m] [int] NULL,
	[open_il_24m] [int] NULL,
	[mths_since_rcnt_il] [int] NULL,
	[total_bal_il] [int] NULL,
	[il_util] [float] NULL,
	[open_rv_12m] [int] NULL,
	[open_rv_24m] [int] NULL,
	[max_bal_bc] [int] NULL,
	[all_util] [float] NULL,
	[total_rev_hi_lim] [int] NULL,
	[inq_fi] [int] NULL,
	[total_cu_tl] [int] NULL,
	[inq_last_12m] [int] NULL,
	[acc_open_past_24mths] [int] NULL,
	[avg_cur_bal] [int] NULL,
	[bc_open_to_buy] [int] NULL,
	[bc_util] [float] NULL,
	[chargeoff_within_12_mths] [int] NULL,
	[delinq_amnt] [int] NULL,
	[mo_sin_old_il_acct] [int] NULL,
	[mo_sin_old_rev_tl_op] [int] NULL,
	[mo_sin_rcnt_rev_tl_op] [int] NULL,
	[mo_sin_rcnt_tl] [int] NULL,
	[mort_acc] [int] NULL,
	[mths_since_recent_bc] [int] NULL,
	[mths_since_recent_bc_dlq] [int] NULL,
	[mths_since_recent_inq] [int] NULL,
	[mths_since_recent_revol_delinq] [int] NULL,
	[num_accts_ever_120_pd] [int] NULL,
	[num_actv_bc_tl] [int] NULL,
	[num_actv_rev_tl] [int] NULL,
	[num_bc_sats] [int] NULL,
	[num_bc_tl] [int] NULL,
	[num_il_tl] [int] NULL,
	[num_op_rev_tl] [int] NULL,
	[num_rev_accts] [int] NULL,
	[num_rev_tl_bal_gt_0] [int] NULL,
	[num_sats] [int] NULL,
	[num_tl_120dpd_2m] [int] NULL,
	[num_tl_30dpd] [int] NULL,
	[num_tl_90g_dpd_24m] [int] NULL,
	[num_tl_op_past_12m] [int] NULL,
	[pct_tl_nvr_dlq] [float] NULL,
	[percent_bc_gt_75] [float] NULL,
	[pub_rec_bankruptcies] [int] NULL,
	[tax_liens] [int] NULL,
	[tot_hi_cred_lim] [int] NULL,
	[total_bal_ex_mort] [int] NULL,
	[total_bc_limit] [int] NULL,
	[total_il_high_credit_limit] [int] NULL,

INDEX [LoanStats_index] NONCLUSTERED HASH
(
	[id]
)WITH ( BUCKET_COUNT = 2000000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY );

GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoanStats](
	[id] [int] NOT NULL IDENTITY(1,1),
	[member_id] [int] NULL,
	[loan_amnt] [int] NULL,
	[funded_amnt] [int] NULL,
	[funded_amnt_inv] [int] NULL,
	[term] [nvarchar](max) NULL,
	[int_rate] [float] NULL,
	[installment] [float] NULL,
	[grade] [nvarchar](max) NULL,
	[sub_grade] [nvarchar](max) NULL,
	[emp_title] [nvarchar](max) NULL,
	[emp_length] [nvarchar](max) NULL,
	[home_ownership] [nvarchar](max) NULL,
	[annual_inc] [float] NULL,
	[verification_status] [nvarchar](max) NULL,
	[issue_d] [nvarchar](max) NULL,
	[loan_status] [nvarchar](max) NULL,
	[pymnt_plan] [nvarchar](max) NULL,
	[purpose] [nvarchar](max) NULL,
	[title] [nvarchar](max) NULL,
	[zip_code] [nvarchar](max) NULL,
	[addr_state] [nvarchar](max) NULL,
	[dti] [float] NULL,
	[delinq_2yrs] [int] NULL,
	[earliest_cr_line] [nvarchar](max) NULL,
	[inq_last_6mths] [int] NULL,
	[mths_since_last_delinq] [int] NULL,
	[mths_since_last_record] [int] NULL,
	[open_acc] [int] NULL,
	[pub_rec] [int] NULL,
	[revol_bal] [int] NULL,
	[revol_util] [float] NULL,
	[total_acc] [int] NULL,
	[initial_list_status] [nvarchar](max) NULL,
	[out_prncp] [float] NULL,
	[out_prncp_inv] [float] NULL,
	[total_pymnt] [float] NULL,
	[total_pymnt_inv] [float] NULL,
	[total_rec_prncp] [float] NULL,
	[total_rec_int] [float] NULL,
	[total_rec_late_fee] [float] NULL,
	[recoveries] [float] NULL,
	[collection_recovery_fee] [float] NULL,
	[last_pymnt_d] [nvarchar](max) NULL,
	[last_pymnt_amnt] [float] NULL,
	[next_pymnt_d] [nvarchar](max) NULL,
	[last_credit_pull_d] [nvarchar](max) NULL,
	[collections_12_mths_ex_med] [int] NULL,
	[mths_since_last_major_derog] [int] NULL,
	[policy_code] [int] NULL,
	[application_type] [nvarchar](max) NULL,
	[annual_inc_joint] [float] NULL,
	[dti_joint] [float] NULL,
	[verification_status_joint] [nvarchar](max) NULL,
	[acc_now_delinq] [int] NULL,
	[tot_coll_amt] [int] NULL,
	[tot_cur_bal] [int] NULL,
	[open_acc_6m] [int] NULL,
	[open_il_6m] [int] NULL,
	[open_il_12m] [int] NULL,
	[open_il_24m] [int] NULL,
	[mths_since_rcnt_il] [int] NULL,
	[total_bal_il] [int] NULL,
	[il_util] [float] NULL,
	[open_rv_12m] [int] NULL,
	[open_rv_24m] [int] NULL,
	[max_bal_bc] [int] NULL,
	[all_util] [float] NULL,
	[total_rev_hi_lim] [int] NULL,
	[inq_fi] [int] NULL,
	[total_cu_tl] [int] NULL,
	[inq_last_12m] [int] NULL,
	[acc_open_past_24mths] [int] NULL,
	[avg_cur_bal] [int] NULL,
	[bc_open_to_buy] [int] NULL,
	[bc_util] [float] NULL,
	[chargeoff_within_12_mths] [int] NULL,
	[delinq_amnt] [int] NULL,
	[mo_sin_old_il_acct] [int] NULL,
	[mo_sin_old_rev_tl_op] [int] NULL,
	[mo_sin_rcnt_rev_tl_op] [int] NULL,
	[mo_sin_rcnt_tl] [int] NULL,
	[mort_acc] [int] NULL,
	[mths_since_recent_bc] [int] NULL,
	[mths_since_recent_bc_dlq] [int] NULL,
	[mths_since_recent_inq] [int] NULL,
	[mths_since_recent_revol_delinq] [int] NULL,
	[num_accts_ever_120_pd] [int] NULL,
	[num_actv_bc_tl] [int] NULL,
	[num_actv_rev_tl] [int] NULL,
	[num_bc_sats] [int] NULL,
	[num_bc_tl] [int] NULL,
	[num_il_tl] [int] NULL,
	[num_op_rev_tl] [int] NULL,
	[num_rev_accts] [int] NULL,
	[num_rev_tl_bal_gt_0] [int] NULL,
	[num_sats] [int] NULL,
	[num_tl_120dpd_2m] [int] NULL,
	[num_tl_30dpd] [int] NULL,
	[num_tl_90g_dpd_24m] [int] NULL,
	[num_tl_op_past_12m] [int] NULL,
	[pct_tl_nvr_dlq] [float] NULL,
	[percent_bc_gt_75] [float] NULL,
	[pub_rec_bankruptcies] [int] NULL,
	[tax_liens] [int] NULL,
	[tot_hi_cred_lim] [int] NULL,
	[total_bal_ex_mort] [int] NULL,
	[total_bc_limit] [int] NULL,
	[total_il_high_credit_limit] [int] NULL,
	[is_bad] int NULL,
 CONSTRAINT [PK__LoanStat] PRIMARY KEY CLUSTERED
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO



SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


USE [LendingClub]
GO
/****** Object:  StoredProcedure [dbo].[PerformETL]    Script Date: 12/31/2016 3:00:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PerformETL]
AS
BEGIN
	INSERT INTO [dbo].[LoanStats]
			   (
			    [member_id]
			   ,[loan_amnt]
			   ,[funded_amnt]
			   ,[funded_amnt_inv]
			   ,[term]
			   ,[int_rate]
			   ,[installment]
			   ,[grade]
			   ,[sub_grade]
			   ,[emp_title]
			   ,[emp_length]
			   ,[home_ownership]
			   ,[annual_inc]
			   ,[verification_status]
			   ,[issue_d]
			   ,[loan_status]
			   ,[pymnt_plan]
			   ,[purpose]
			   ,[title]
			   ,[zip_code]
			   ,[addr_state]
			   ,[dti]
			   ,[delinq_2yrs]
			   ,[earliest_cr_line]
			   ,[inq_last_6mths]
			   ,[mths_since_last_delinq]
			   ,[mths_since_last_record]
			   ,[open_acc]
			   ,[pub_rec]
			   ,[revol_bal]
			   ,[revol_util]
			   ,[total_acc]
			   ,[initial_list_status]
			   ,[out_prncp]
			   ,[out_prncp_inv]
			   ,[total_pymnt]
			   ,[total_pymnt_inv]
			   ,[total_rec_prncp]
			   ,[total_rec_int]
			   ,[total_rec_late_fee]
			   ,[recoveries]
			   ,[collection_recovery_fee]
			   ,[last_pymnt_d]
			   ,[last_pymnt_amnt]
			   ,[next_pymnt_d]
			   ,[last_credit_pull_d]
			   ,[collections_12_mths_ex_med]
			   ,[mths_since_last_major_derog]
			   ,[policy_code]
			   ,[application_type]
			   ,[annual_inc_joint]
			   ,[dti_joint]
			   ,[verification_status_joint]
			   ,[acc_now_delinq]
			   ,[tot_coll_amt]
			   ,[tot_cur_bal]
			   ,[open_acc_6m]
			   ,[open_il_6m]
			   ,[open_il_12m]
			   ,[open_il_24m]
			   ,[mths_since_rcnt_il]
			   ,[total_bal_il]
			   ,[il_util]
			   ,[open_rv_12m]
			   ,[open_rv_24m]
			   ,[max_bal_bc]
			   ,[all_util]
			   ,[total_rev_hi_lim]
			   ,[inq_fi]
			   ,[total_cu_tl]
			   ,[inq_last_12m]
			   ,[acc_open_past_24mths]
			   ,[avg_cur_bal]
			   ,[bc_open_to_buy]
			   ,[bc_util]
			   ,[chargeoff_within_12_mths]
			   ,[delinq_amnt]
			   ,[mo_sin_old_il_acct]
			   ,[mo_sin_old_rev_tl_op]
			   ,[mo_sin_rcnt_rev_tl_op]
			   ,[mo_sin_rcnt_tl]
			   ,[mort_acc]
			   ,[mths_since_recent_bc]
			   ,[mths_since_recent_bc_dlq]
			   ,[mths_since_recent_inq]
			   ,[mths_since_recent_revol_delinq]
			   ,[num_accts_ever_120_pd]
			   ,[num_actv_bc_tl]
			   ,[num_actv_rev_tl]
			   ,[num_bc_sats]
			   ,[num_bc_tl]
			   ,[num_il_tl]
			   ,[num_op_rev_tl]
			   ,[num_rev_accts]
			   ,[num_rev_tl_bal_gt_0]
			   ,[num_sats]
			   ,[num_tl_120dpd_2m]
			   ,[num_tl_30dpd]
			   ,[num_tl_90g_dpd_24m]
			   ,[num_tl_op_past_12m]
			   ,[pct_tl_nvr_dlq]
			   ,[percent_bc_gt_75]
			   ,[pub_rec_bankruptcies]
			   ,[tax_liens]
			   ,[tot_hi_cred_lim]
			   ,[total_bal_ex_mort]
			   ,[total_bc_limit]
			   ,[total_il_high_credit_limit])
	SELECT DISTINCT
			    [member_id]
			   ,[loan_amnt]
			   ,[funded_amnt]
			   ,[funded_amnt_inv]
			   ,[term]
			   ,REPLACE([int_rate], '%', '')
			   ,[installment]
			   ,[grade]
			   ,[sub_grade]
			   ,[emp_title]
			   ,[emp_length]
			   ,[home_ownership]
			   ,[annual_inc]
			   ,[verification_status]
			   ,[issue_d]
			   ,[loan_status]
			   ,[pymnt_plan]
			   ,[purpose]
			   ,[title]
			   ,[zip_code]
			   ,[addr_state]
			   ,[dti]
			   ,[delinq_2yrs]
			   ,[earliest_cr_line]
			   ,[inq_last_6mths]
			   ,[mths_since_last_delinq]
			   ,[mths_since_last_record]
			   ,[open_acc]
			   ,[pub_rec]
			   ,[revol_bal]
			   ,REPLACE([revol_util], '%', '')
			   ,[total_acc]
			   ,[initial_list_status]
			   ,[out_prncp]
			   ,[out_prncp_inv]
			   ,[total_pymnt]
			   ,[total_pymnt_inv]
			   ,[total_rec_prncp]
			   ,[total_rec_int]
			   ,[total_rec_late_fee]
			   ,[recoveries]
			   ,[collection_recovery_fee]
			   ,[last_pymnt_d]
			   ,[last_pymnt_amnt]
			   ,[next_pymnt_d]
			   ,[last_credit_pull_d]
			   ,[collections_12_mths_ex_med]
			   ,[mths_since_last_major_derog]
			   ,[policy_code]
			   ,[application_type]
			   ,[annual_inc_joint]
			   ,[dti_joint]
			   ,[verification_status_joint]
			   ,[acc_now_delinq]
			   ,[tot_coll_amt]
			   ,[tot_cur_bal]
			   ,[open_acc_6m]
			   ,[open_il_6m]
			   ,[open_il_12m]
			   ,[open_il_24m]
			   ,[mths_since_rcnt_il]
			   ,[total_bal_il]
			   ,[il_util]
			   ,[open_rv_12m]
			   ,[open_rv_24m]
			   ,[max_bal_bc]
			   ,[all_util]
			   ,[total_rev_hi_lim]
			   ,[inq_fi]
			   ,[total_cu_tl]
			   ,[inq_last_12m]
			   ,[acc_open_past_24mths]
			   ,[avg_cur_bal]
			   ,[bc_open_to_buy]
			   ,[bc_util]
			   ,[chargeoff_within_12_mths]
			   ,[delinq_amnt]
			   ,[mo_sin_old_il_acct]
			   ,[mo_sin_old_rev_tl_op]
			   ,[mo_sin_rcnt_rev_tl_op]
			   ,[mo_sin_rcnt_tl]
			   ,[mort_acc]
			   ,[mths_since_recent_bc]
			   ,[mths_since_recent_bc_dlq]
			   ,[mths_since_recent_inq]
			   ,[mths_since_recent_revol_delinq]
			   ,[num_accts_ever_120_pd]
			   ,[num_actv_bc_tl]
			   ,[num_actv_rev_tl]
			   ,[num_bc_sats]
			   ,[num_bc_tl]
			   ,[num_il_tl]
			   ,[num_op_rev_tl]
			   ,[num_rev_accts]
			   ,[num_rev_tl_bal_gt_0]
			   ,[num_sats]
			   ,[num_tl_120dpd_2m]
			   ,[num_tl_30dpd]
			   ,[num_tl_90g_dpd_24m]
			   ,[num_tl_op_past_12m]
			   ,[pct_tl_nvr_dlq]
			   ,[percent_bc_gt_75]
			   ,[pub_rec_bankruptcies]
			   ,[tax_liens]
			   ,[tot_hi_cred_lim]
			   ,[total_bal_ex_mort]
			   ,[total_bc_limit]
			   ,[total_il_high_credit_limit]
	  FROM [dbo].[LoanStatsStaging]
	  WHERE [loan_status] IS NOT NULL

	DELETE FROM [dbo].[LoanStatsStaging]
END  ;
GO

USE [LendingClub]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoanStatsPredictions]
(
	[is_bad_Pred] [float] NULL,
	[id] [int] NULL

INDEX [LoanStats_index] NONCLUSTERED HASH
(
	[id]
)WITH ( BUCKET_COUNT = 2000000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY );

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPredictionsWhatIf]
(
	[is_bad_Pred] [float] NULL,
	[id] [int] NULL

INDEX [LoanStats_index] NONCLUSTERED HASH
(
	[id]
)WITH ( BUCKET_COUNT = 2000000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY );
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RunTimeStats]
(
	[SessionID] [int] NOT NULL,
	[RunTime] [datetime] NOT NULL,
	[Operation] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,

INDEX [RunTimeStats_index] NONCLUSTERED HASH
(
	[SessionID]
)WITH ( BUCKET_COUNT = 32)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )

GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- Create a table to store the WhatIf value used for the WhatIf scenario
CREATE TABLE [dbo].[WhatIf](
	[Rate] [float] NULL
) ON [PRIMARY]

GO

INSERT INTO [dbo].[WhatIf] VALUES (0.0)


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Stored procedure for scoring loans for the base predictions
CREATE PROCEDURE [dbo].[ScoreLoans]
@start bigint,
@end bigint
AS
BEGIN

  -- Declare the variables to get the input data and the scoring model
  DECLARE @inquery nvarchar(max) = N'SELECT id,revol_util, int_rate, mths_since_last_record, annual_inc_joint, dti_joint, total_rec_prncp, all_util, is_bad FROM [dbo].[LoanStats]  where [id] >= ' + CAST(@start as varchar(255)) + 'and [id] <= ' + CAST(@end as varchar(255));
  DECLARE @model varbinary(max) = (SELECT TOP 1 [model] FROM [dbo].[models])

  -- Log beginning of processing time
  INSERT INTO [dbo].[RunTimeStats] VALUES (@@SPID, GETDATE(),'Start')

  -- Score the loans and store them in a table
  INSERT INTO [dbo].[LoanStatsPredictions]
  EXEC sp_execute_external_script
  @language = N'R',
  @script = N'
  rfModel <- unserialize(as.raw(model));
  OutputDataSet<-rxPredict(rfModel, data = InputDataSet, extraVarsToWrite = c("id"))
  ',
  @input_data_1 = @inquery,
  @params = N'@model varbinary(max)',
  @model = @model

  -- Log end of processing time
  INSERT INTO [dbo].[RunTimeStats] VALUES (@@SPID, GETDATE(),'End')

END
GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Stored procedure to in
CREATE PROCEDURE [dbo].[ScoreLoansWhatIf]
@start bigint,
@end bigint,
@incr float
AS
BEGIN

  -- Declare the variables to get the input data and the scoring model
  DECLARE @inquery nvarchar(max) = N'SELECT id,revol_util, (int_rate+ ' + CAST (@Incr as varchar(5)) + ') as int_rate, mths_since_last_record, annual_inc_joint, dti_joint, total_rec_prncp, all_util,is_bad FROM [dbo].[LoanStats]  where [id] >= ' + CAST(@start as varchar(255)) + 'and [id] <= ' + CAST(@end as varchar(255));
  DECLARE @model varbinary(max) = (SELECT TOP 1 [model] FROM [dbo].[models])

  -- Log beginning of processing time
  INSERT INTO [dbo].[RunTimeStats] VALUES (@@SPID, GETDATE(),'Start')

  INSERT INTO [dbo].[LoanPredictionsWhatIf]
  EXEC sp_execute_external_script
  @language = N'R',
  @script = N'
  rfModel <- unserialize(as.raw(model));
  OutputDataSet<-rxPredict(rfModel, data = InputDataSet, extraVarsToWrite = c("id"))
  ',
  @input_data_1 = @inquery,
  @params = N'@model varbinary(max)',
  @model = @model

  -- Log end of processing time
  INSERT INTO [dbo].[RunTimeStats] VALUES (@@SPID, GETDATE(),'End')


END

GO

