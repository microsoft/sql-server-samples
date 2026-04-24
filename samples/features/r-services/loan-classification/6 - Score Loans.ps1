cls
# Create a while loop to start the SQL jobs to execute scoring procedure in parallel

$StartCtr = 1
$Increment = 250000
$EndCtr = $Increment
$FinalCount = 1195907
$vServerName = $env:computername
$vDatabaseName = "LendingClub"
$count = "{0:N0}" -f $FinalCount

Write-Host "Performing clean-up to start new scoring run...." -ForegroundColor Yellow

# Start Cleanup
Invoke-Sqlcmd -ServerInstance $vServerName -Database $vDatabaseName -Query "delete from [LoanStatsPredictions];delete from Runtimestats;checkpoint;"

Write-Host "Starting parallel jobs to score " $count "loans" -ForegroundColor Yellow

while ($EndCtr -le $FinalCount)
{
    $SqlScript = [ScriptBlock]::Create("Invoke-Sqlcmd -ServerInstance `"" + $vServerName + "`" -Query `"EXEC [dbo].[ScoreLoans] " + $StartCtr + "," + $EndCtr + "`" -Database `"$vDatabaseName`"")
    Start-Job -ScriptBlock $SqlScript
    $StartCtr += $Increment
    $EndCtr += $Increment
}

# Wait till jobs complete
while (Get-Job -State Running)
{

    Start-Sleep 1
}


# Find out duration
$duration = Invoke-Sqlcmd -ServerInstance $vServerName -Database $vDatabaseName -Query "select DATEDIFF(s,MIN (Runtime), MAX(Runtime)) as RuntimeSeconds from dbo.RuntimeStats;"

Write-Host "`n"

$rate = "{0:N2}" -f ($FinalCount/$duration.RuntimeSeconds)

Write-Host "Completed scoring" $count "loans in" $duration.RuntimeSeconds "seconds at" $rate "loans/sec." -ForegroundColor Green

# Remove Jobs
Get-Job | Remove-Job



