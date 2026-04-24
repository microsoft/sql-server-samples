#This script repeatedly probes all regions for connectivity to the Azure Arc data services/Arc-enabled SQL Server endpoints for telemetry and the data processing service.
#The script will output the status of the connectivity to the console.
#The script will run indefinitely until stopped by the user.
#The script will iterate through all regions in the $regions array.
#The list of regions are updated as of June 7,2024 to reflect all publicly available, supported Azure regions for Arc-enabled SQL Server.

$regions = @(
    "East US",
    "East US 2",
    "West US 2",
    "West US 3",
    "Central US",
    "North Central US",
    "South Central US",
    "West Central US",
    "Canada Central",
    "Canada East",
    "UK South",
    "UK West",
    "France Central",
    "West Europe",
    "North Europe",
    "Switzerland North",
    "Central India",
    "Brazil South",
    "South Africa North",
    "UAE North",
    "Japan East",
    "Korea Central",
    "Southeast Asia",
    "Australia East",
    "Sweden Central",
    "Norway East"
)

$regions = $regions | ForEach-Object { $_.Replace(" ", "") }

do{
    $regions | ForEach-Object {
        $dps_url =  "dataprocessingservice.$_.arcdataservices.com"
        $ti_url =  "telemetry.$_.arcdataservices.com"
        try{
            $dps_response_time = Measure-Command { $response = Invoke-WebRequest -Uri $dps_url -Method Get }
            $dps_result = ($response).StatusCode
        }catch{
            $dps_result = $_.Exception.Message
        }
        try{
            $ti_response_time = Measure-Command { $response = Invoke-WebRequest -Uri $ti_url -Method Get -SkipHttpErrorCheck }
        }catch{
            if($_.Exception.Message -like "*401*"){
                $ti_result = "Expected"
            }
            else {
                $ti_result = $_.Exception.Message
            }
        }
        if ($ti_response_time.TotalSeconds -gt 3 -or $dps_response_time.TotalSeconds -gt 3 -or $dps_result -ne 200 -or $ti_result -ne "Expected") {
            Write-Host $dps_result "($dps_response_time) " $ti_result " ($ti_response_time) :: $_" -ForegroundColor Red
        }
        elseif ($ti_response_time.TotalSeconds -gt 1 -or $dps_response_time.TotalSeconds -gt 1) {
            Write-Host $dps_result "($dps_response_time) " $ti_result " ($ti_response_time) :: $_" -ForegroundColor Yellow
        }
        else
        {
            Write-Host $dps_result "($dps_response_time) " $ti_result " ($ti_response_time) :: $_"
        }
    }
    Write-Host "====================================================================="
} while($true)