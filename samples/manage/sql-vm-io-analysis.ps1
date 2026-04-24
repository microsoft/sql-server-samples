# Enter parameters
$subscriptionId = Read-Host "<Subscription ID>"
$resourceGroup = Read-Host "<Resource Group>"
$vmName = Read-Host "<Virtual machine name>"

# Set resource details
$resourceType = "Microsoft.Compute/virtualMachines"
$resourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/$resourceType/$vmName"

# Get Azure access token
$accessToken = az account get-access-token --query accessToken -o tsv

# Invoke Azure Monitor Metrics API
function Get-Metrics {
	[CmdletBinding()]
    param (
        [string]$accessToken,
        [string]$resourceId,
        [string]$metricNames,
        [string]$apiVersion = "2023-10-01"
    )
    try {
        $startTime = (Get-Date).AddHours(-24).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $endTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $timespan = "$startTime/$endTime"
		Write-Verbose "Evaluating timespan: $timespan"
        $uri = "https://management.azure.com$resourceId/providers/Microsoft.Insights/metrics?api-version=$apiVersion&metricnames=$metricNames&aggregation=maximum&interval=PT1M&timespan=$timespan"
        $headers = @{ "Authorization" = "Bearer $accessToken"; "Content-Type" = "application/json" }
        
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        if ($response) {
            Write-Verbose "API response successfully retrieved."
            return $response
        } else {
            Write-Error "No response from API."
        }
    } catch {
        Write-Error "Error retrieving metrics: $_"
    }
}

# Check if data disk latency violates thresholds
function Check-Latency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Object]$metrics,

        [Parameter()]
        [int]$latencyThreshold = 500,

        [Parameter()]
        [int]$consecutiveCount = 5
    )
    $violationTimes = @()
    foreach ($metric in $metrics.value) {
        if ($metric.name.value -eq "Data Disk Latency") {
            $count = 0
            foreach ($dataPoint in $metric.timeseries[0].data) {
                if ($dataPoint.maximum -gt $latencyThreshold) {
                    $count++
                    if ($count -ge $consecutiveCount) {
                        $violationTimes += $dataPoint.timeStamp
                        $count = 0  # Reset count after recording a violation
                    }
                } else {
                    $count = 0  # Reset count if the sequence is broken
                }
            }
        }
    }
    if ($violationTimes.Count -gt 0) {
        Write-Verbose "Latency violations detected."
        return @{ "Flag" = $true; "Times" = $violationTimes }
    } else {
        Write-Verbose "No latency violations detected."
        return @{ "Flag" = $false }
    }
}

# Check metrics other than latency to evaluate for throttling
function Check-OtherMetricsThrottled {
	[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Object]$metrics,

        [Parameter()]
        [int]$PercentageThreshold = 90,

        [Parameter()]
        [int]$consecutiveCount = 5
    )
    $violatedMetrics = @()
    foreach ($metric in $metrics.value) {
        $count = 0
        foreach ($dataPoint in $metric.timeseries[0].data) {
            if ($dataPoint.maximum -gt $PercentageThreshold) {
                $count++
                if ($count -ge $consecutiveCount) {
                    $violatedMetrics += @{ "Metric" = $metric.name.localizedValue; "Time" = $dataPoint.timeStamp; "Value" = $dataPoint.maximum }
                    break
                }
            } else {
                $count = 0
            }
        }
    }
    if ($violatedMetrics.Count -gt 0) {
        Write-Verbose "Other metrics violations detected."
    } else {
        Write-Verbose "No other metrics violations detected."
    }
    return $violatedMetrics
}

# Compare times for latency & other throttled metrics. Logs the volations with values & timestamps
function CompareTimes {
	[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$latencyResult,
        
        [Parameter(Mandatory = $true)]
        [Array]$otherMetrics
    )
    foreach ($metric in $otherMetrics) {
        $otherDateTime = [DateTime]$metric["Time"]
        $isWithinFiveMinutes = $false
        $closestLatencyTime = $null
        $closestTimeDifference = [int]::MaxValue

        foreach ($latencyTime in $latencyResult.Times) {
            $latencyDateTime = [DateTime]$latencyTime
            $timeDifference = [Math]::Abs(($otherDateTime - $latencyDateTime).TotalMinutes)
            
            if ($timeDifference -le 5) {
                $isWithinFiveMinutes = $true
                if ($timeDifference -lt $closestTimeDifference) {
                    $closestTimeDifference = $timeDifference
                    $closestLatencyTime = $latencyTime
                }
            }
        }

        if ($isWithinFiveMinutes) {
            if ($otherDateTime -lt $closestLatencyTime) {
                Write-Host "`n $($metric["Metric"]) limit was hit before latency spiked at $closestLatencyTime with value $($metric["Value"]). `n"
            } else {
                Write-Host "`n $($metric["Metric"]) hit its limit with value $($metric["Value"]) at $($metric["Time"])."
                Write-Host "Latency spiked at $closestLatencyTime before $($metric["Metric"]) hit its limit `n"
            }
        } else {
            Write-Host "`n Metric: $($metric["Metric"]) exceeded its threshold with a value of $($metric["Value"]) at $($metric["Time"]), but this was not within 5 minutes of any latency spikes."
        }
    }
}

# Prompt user for latency threshold
$latencyThreshold = Read-Host "Enter Latency Threshold (default is 500)"
if (-not [int]::TryParse($latencyThreshold, [ref]0)) {
    $latencyThreshold = 500 # Use default if invalid input
	Write-Host "No valid input provided. Using Default 500ms for disk latency threshold"
}

# Execute main logic
$latencyMetrics = Get-Metrics -accessToken $accessToken -resourceId $resourceId -metricNames "Data Disk Latency"
$latencyResult = Check-Latency -metrics $latencyMetrics -latencyThreshold $latencyThreshold

if ($latencyResult.Flag) {
	
	# If latency is flagged, check for other metrics. If there is no disk latency, machine is likely not throttled but only at high consumption
	Write-Verbose "Checking the following metrics: Data Disk Bandwidth Consumed Percentage,Data Disk IOPS Consumed Percentage,VM Cached Bandwidth Consumed Percentage,VM Cached IOPS Consumed Percentage,VM Uncached Bandwidth Consumed Percentage,VM Uncached IOPS Consumed Percentage"
	
    $DiskVMMetrics = Get-Metrics -accessToken $accessToken -resourceId $resourceId -metricNames "Data Disk Bandwidth Consumed Percentage,Data Disk IOPS Consumed Percentage,VM Cached Bandwidth Consumed Percentage,VM Cached IOPS Consumed Percentage,VM Uncached Bandwidth Consumed Percentage,VM Uncached IOPS Consumed Percentage"
	
    $additionalMetrics = Check-OtherMetricsThrottled -metrics $DiskVMMetrics
	
	if ($additionalMetrics.Count -gt 0) {
        CompareTimes $latencyResult $additionalMetrics
    } else {
        Write-Host "No metrics violations detected besides latency."
    }
} else {
    Write-Host "No latency issues detected."
}
