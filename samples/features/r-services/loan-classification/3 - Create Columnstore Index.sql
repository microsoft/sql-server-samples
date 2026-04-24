USE [LendingClub]
GO

UPDATE [dbo].[LoanStats]
SET [is_bad] = (CASE WHEN loan_status IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') THEN 1 ELSE 0 END);

CREATE NONCLUSTERED COLUMNSTORE INDEX [ncci_LoanStats] ON [dbo].[LoanStats]
(
	[revol_util],
	[int_rate],
	[mths_since_last_record],
	[annual_inc_joint],
	[dti_joint],
	[total_rec_prncp],
	[all_util],
	[is_bad]
)WITH (COMPRESSION_DELAY = 0, MAXDOP = 1) ON [PRIMARY];
GO

