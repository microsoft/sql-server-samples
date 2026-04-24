<#

Author: Amit Banerjee
Contact: @mssqltiger | @banerjeeamit | http://aka.ms/sqlserverteam
Description:
    1. First step is to use Lending Club CSV files and import them into an in-memory staging table
    2. Second step is to transform the staging data and move them into the table which will be used for the predictions

#>
# Get a list of all the CSV files in the folder
$files = ls C:\Tiger\Extract\*.csv # TODO: Change the path to the appropriate location of the CSV files


# Create a function to import the CSV data by skipping the first line
# You will see a number of Invoke-SqlCmd failures for rows that are not being imported into the database
function ImportData ($csvFile)
{


    $SqlServer = "." # TODO: Change the name of SQL Server instance name
    $dbName = "LendingClub" # TODO: Change the name of the database
    $csvData = Get-Content -Path $csvFile | Select-Object -Skip 1 | Where-Object {$_.id -notcontains "*Total amount funded in policy code*"} | ConvertFrom-Csv

    foreach ($line in $csvData)
    {
        $Query = "INSERT INTO dbo.LoanStatsStaging (id,member_id,loan_amnt,funded_amnt,funded_amnt_inv,term,int_rate,installment,grade,sub_grade,emp_title,emp_length,home_ownership,annual_inc,verification_status,issue_d,loan_status,pymnt_plan,[url],[desc],purpose,title,zip_code,addr_state,dti,delinq_2yrs,earliest_cr_line,inq_last_6mths,mths_since_last_delinq,mths_since_last_record,open_acc,pub_rec,revol_bal,revol_util,total_acc,initial_list_status,out_prncp,out_prncp_inv,total_pymnt,total_pymnt_inv,total_rec_prncp,total_rec_int,total_rec_late_fee,recoveries,collection_recovery_fee,last_pymnt_d,last_pymnt_amnt,next_pymnt_d,last_credit_pull_d,collections_12_mths_ex_med,mths_since_last_major_derog,policy_code,application_type,annual_inc_joint,dti_joint,verification_status_joint,acc_now_delinq,tot_coll_amt,tot_cur_bal,open_acc_6m,open_il_6m,open_il_12m,open_il_24m,mths_since_rcnt_il,total_bal_il,il_util,open_rv_12m,open_rv_24m,max_bal_bc,all_util,total_rev_hi_lim,inq_fi,total_cu_tl,inq_last_12m,acc_open_past_24mths,avg_cur_bal,bc_open_to_buy,bc_util,chargeoff_within_12_mths,delinq_amnt,mo_sin_old_il_acct,mo_sin_old_rev_tl_op,mo_sin_rcnt_rev_tl_op,mo_sin_rcnt_tl,mort_acc,mths_since_recent_bc,mths_since_recent_bc_dlq,mths_since_recent_inq,mths_since_recent_revol_delinq,num_accts_ever_120_pd,num_actv_bc_tl,num_actv_rev_tl,num_bc_sats,num_bc_tl,num_il_tl,num_op_rev_tl,num_rev_accts,num_rev_tl_bal_gt_0,num_sats,num_tl_120dpd_2m,num_tl_30dpd,num_tl_90g_dpd_24m,num_tl_op_past_12m,pct_tl_nvr_dlq,percent_bc_gt_75,pub_rec_bankruptcies,tax_liens,tot_hi_cred_lim,total_bal_ex_mort,total_bc_limit,total_il_high_credit_limit) VALUES ("
        $Query = $Query + $line.id + "," + $line.member_id + "," + $line.loan_amnt + "," + $line.funded_amnt + "," + $line.funded_amnt_inv + "," + "N'" + $line.term + "',"+ "N'" + $line.int_rate + "',"+ $line.installment + "," + "N'" + $line.grade + "',"+ "N'" + $line.sub_grade + "',"+ "N'" + $line.emp_title + "',"+ "N'" + $line.emp_length + "',"+ "N'" + $line.home_ownership + "',"+ $line.annual_inc + "," + "N'" + $line.verification_status + "',"+ "N'" + $line.issue_d + "',"+ "N'" + $line.loan_status + "',"+ "N'" + $line.pymnt_plan + "',"+ "N'" + $line.url + "',"+ "N'" + $line.desc + "',"+ "N'" + $line.purpose + "',"+ "N'" + $line.title + "',"+ "N'" + $line.zip_code + "',"+ "N'" + $line.addr_state + "',"+ $line.dti + "," + $line.delinq_2yrs + "," + "N'" + $line.earliest_cr_line + "',"+ $line.inq_last_6mths + "," + $line.mths_since_last_delinq + "," + $line.mths_since_last_record + "," + $line.open_acc + "," + $line.pub_rec + "," + $line.revol_bal + "," + "N'" + $line.revol_util + "',"+ $line.total_acc + "," + "N'" + $line.initial_list_status + "',"+ $line.out_prncp + "," + $line.out_prncp_inv + "," + $line.total_pymnt + "," + $line.total_pymnt_inv + "," + $line.total_rec_prncp + "," + $line.total_rec_int + "," + $line.total_rec_late_fee + "," + $line.recoveries + "," + $line.collection_recovery_fee + "," + "N'" + $line.last_pymnt_d + "',"+ $line.last_pymnt_amnt + "," + "N'" + $line.next_pymnt_d + "',"+ "N'" + $line.last_credit_pull_d + "',"+ $line.collections_12_mths_ex_med + "," + $line.mths_since_last_major_derog + "," + $line.policy_code + "," + "N'" + $line.application_type + "',"+ $line.annual_inc_joint + "," + $line.dti_joint + "," + "N'" + $line.verification_status_joint + "',"+ $line.acc_now_delinq + "," + $line.tot_coll_amt + "," + $line.tot_cur_bal + "," + $line.open_acc_6m + "," + $line.open_il_6m + "," + $line.open_il_12m + "," + $line.open_il_24m + "," + $line.mths_since_rcnt_il + "," + $line.total_bal_il + "," + $line.il_util + "," + $line.open_rv_12m + "," + $line.open_rv_24m + "," + $line.max_bal_bc + "," + $line.all_util + "," + $line.total_rev_hi_lim + "," + $line.inq_fi + "," + $line.total_cu_tl + "," + $line.inq_last_12m + "," + $line.acc_open_past_24mths + "," + $line.avg_cur_bal + "," + $line.bc_open_to_buy + "," + $line.bc_util + "," + $line.chargeoff_within_12_mths + "," + $line.delinq_amnt + "," + $line.mo_sin_old_il_acct + "," + $line.mo_sin_old_rev_tl_op + "," + $line.mo_sin_rcnt_rev_tl_op + "," + $line.mo_sin_rcnt_tl + "," + $line.mort_acc + "," + $line.mths_since_recent_bc + "," + $line.mths_since_recent_bc_dlq + "," + $line.mths_since_recent_inq + "," + $line.mths_since_recent_revol_delinq + "," + $line.num_accts_ever_120_pd + "," + $line.num_actv_bc_tl + "," + $line.num_actv_rev_tl + "," + $line.num_bc_sats + "," + $line.num_bc_tl + "," + $line.num_il_tl + "," + $line.num_op_rev_tl + "," + $line.num_rev_accts + "," + $line.num_rev_tl_bal_gt_0 + "," + $line.num_sats + "," + $line.num_tl_120dpd_2m + "," + $line.num_tl_30dpd + "," + $line.num_tl_90g_dpd_24m + "," + $line.num_tl_op_past_12m + "," + $line.pct_tl_nvr_dlq + "," + $line.percent_bc_gt_75 + "," + $line.pub_rec_bankruptcies + "," + $line.tax_liens + "," + $line.tot_hi_cred_lim + "," + $line.total_bal_ex_mort + "," + $line.total_bc_limit + "," + $line.total_il_high_credit_limit + ")"
        $Query = $Query.Replace(",)",",NULL)")
        while ($Query.Contains(",,") -eq 1)
        {
            #Write-Host "Removing NULLs"
            $Query = $Query.Replace(",,",",NULL,")
        }

        #Write-Host $query
        Invoke-Sqlcmd -ServerInstance $SqlServer -Database $dbName -Query $Query -Verbose

    }
}

# Create a while loop to import the data from the CSV files to an in-memory table
foreach ($file in $files)
{
   ImportData $file.FullName
   Invoke-Sqlcmd -ServerInstance $SqlServer -Database $dbName -Query "EXEC dbo.PerformETL"
}
