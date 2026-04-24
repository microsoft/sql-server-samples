# Evaluate specific Policies against a Server List
# Uses the Invoke-PolicyEvaluation Cmdlet

param([string]$ConfigurationGroup=$(Throw `
"Paramater missing: -ConfigurationGroup ConfigGroup"),`
[string]$PolicyCategoryFilter=$(Throw "Parameter missing: `
-PolicyCategoryFilter Category"), `
[string]$EvalMode=$(Throw "Parameter missing: -EvalMode EvalMode"))

# Parameter -ConfigurationGroup specifies the
# Central Management Server group to evaluate
# Parameter -PolicyCategoryFilter specifies the
# category of policies to evaluate
# Parameter -EvalMode accepts "Check" to report policy
# results, "Configure" to reconfigure any violations

# Declare variables to define the central warehouse
# in which to write the output, store the policies
$CentralManagementServer = "WIN2008"
$HistoryDatabase = "MDW"
# Define the location to write the results of the
# policy evaluation.  Delete any files in the directory.
$ResultDir = "e:\Results\"
$ResultDirDel = $ResultDir + "*.xml"
Remove-Item -Path $ResultDirDel
# End of variables

#Function to insert policy evaluation results
#into SQL Server - table policy.PolicyHistory
function PolicyHistoryInsert($sqlServerVariable, $sqlDatabaseVariable, $EvaluatedServer, $EvaluatedPolicy, $EvaluationResults)
{
   &{
	$sqlQueryText = "INSERT INTO policy.PolicyHistory (EvaluatedServer, EvaluatedPolicy, EvaluationResults) VALUES(N'$EvaluatedServer', N'$EvaluatedPolicy', N'$EvaluationResults')"
	Invoke-Sqlcmd -ServerInstance $sqlServerVariable -Database $sqlDatabaseVariable -Query $sqlQueryText -ErrorAction Stop
	}
	trap
	{
	  $ExceptionText = $_.Exception.Message -replace "'", ""
	}
}

#Function to insert policy evaluation errors
#into SQL Server - table policy.EvaluationErrorHistory
function PolicyErrorInsert($sqlServerVariable, $sqlDatabaseVariable, $EvaluatedServer, $EvaluatedPolicy, $EvaluationResultsEscape)
{
	&{
	$sqlQueryText = "INSERT INTO policy.EvaluationErrorHistory (EvaluatedServer, EvaluatedPolicy, EvaluationResults) VALUES(N'$EvaluatedServer', N'$EvaluatedPolicy', N'$EvaluationResultsEscape')"
	Invoke-Sqlcmd -ServerInstance $sqlServerVariable -Database $sqlDatabaseVariable -Query $sqlQueryText -ErrorAction Stop
	}
	trap
	{
	  $ExceptionText = $_.Exception.Message -replace "'", ""
	}
}

# Connection to the policy store
$conn = new-object Microsoft.SQlServer.Management.Sdk.Sfc.SqlStoreConnection("server=$CentralManagementServer;Trusted_Connection=true");
$PolicyStore = new-object Microsoft.SqlServer.Management.DMF.PolicyStore($conn);

# Create recordset of servers to evaluate
$sconn = new-object System.Data.SqlClient.SqlConnection("server=$CentralManagementServer;Trusted_Connection=true");
$q = "SELECT DISTINCT server_name FROM $HistoryDatabase.[policy].[pfn_ServerGroupInstances]('$ConfigurationGroup');"

$sconn.Open()
$cmd = new-object System.Data.SqlClient.SqlCommand ($q, $sconn);
$cmd.CommandTimeout = 0;
$dr = $cmd.ExecuteReader();

# Loop through the servers and then loop through
# the policies.  For each server and policy,
# call cmdlet to evaluate policy on server

while ($dr.Read()) {
	$ServerName = $dr.GetValue(0);
	foreach ($Policy in $PolicyStore.Policies)
   {
		if (($Policy.PolicyCategory -eq $PolicyCategoryFilter)-or ($PolicyCategoryFilter -eq ""))
	{
		&{
			$OutputFile = $ResultDir + ("{0}_{1}.xml" -f (Encode-SqlName $ServerName ), (Encode-SqlName $Policy.Name));
			Invoke-PolicyEvaluation -Policy $Policy -TargetServerName $ServerName -AdHocPolicyEvaluationMode $EvalMode -OutputXML > $OutputFile;
			$PolicyResult = Get-Content $OutputFile -encoding UTF8;
			$PolicyResult = $PolicyResult -replace "'", ""
			PolicyHistoryInsert $CentralManagementServer $HistoryDatabase $ServerName $Policy.Name $PolicyResult;
	 	}
			trap [Exception]
			{
				  $ExceptionText = $_.Exception.Message -replace "'", ""
				  $ExceptionMessage = $_.Exception.GetType().FullName + ", " + $ExceptionText
				  PolicyErrorInsert $CentralManagementServer $HistoryDatabase $ServerName $Policy.Name $ExceptionMessage;
				  continue;
			}		
	}
   }
 }

$dr.Close()
$sconn.Close()

#Shred the XML results to PolicyHistoryDetails
Invoke-Sqlcmd -ServerInstance $CentralManagementServer -Database $HistoryDatabase -Query "exec policy.epm_LoadPolicyHistoryDetail"  -ErrorAction Stop
