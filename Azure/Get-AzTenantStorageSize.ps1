<#  
.SYNOPSIS  
    This script finds all storage accounts in a tenant and writes out the storage account names and sizes to an excel file.
 .DESCRIPTION  
    This script finds all storage accounts in a tenant and writes out the storage account names and sizes to an excel file.
.NOTES  
    File Name  : Get-AzTenantStorageSize.ps1
    Author     : StormFuel  
    Requires   : PowerShell 7
.LINK  
    https://github.com/StormFuel/PowerShell
.EXAMPLE
    ./Get-AzTenantStorageSize.ps1
#>


$logfilepath = ".\Get-AzTenantStorageSize.log"
Start-Transcript -Path $logfilepath

$totalsize = 0

$StorageAccountDetails = New-Object System.Data.DataTable

[void]$StorageAccountDetails.Columns.Add("SubscriptionName")
[void]$StorageAccountDetails.Columns.Add("ResourceGroupName")
[void]$StorageAccountDetails.Columns.Add("StorageAccountName")
[void]$StorageAccountDetails.Columns.Add("SubscriptionId")
[void]$StorageAccountDetails.Columns.Add("ResourceGroupId")
[void]$StorageAccountDetails.Columns.Add("StorageAccountId")
[void]$StorageAccountDetails.Columns.Add("SizeInBytes")
[void]$StorageAccountDetails.Columns.Add("SizeInTB")

function Write-ProgressBar {
    Param (
        [string[]]$label,
        [int[]]$CurrentNumber,
        [int[]]$TotalNumber
    )

    $progressPercentage = $CurrentNumber/$TotalNumber
    Write-Progress -Activity "$label Progress" -Status "Percent Complete:" -PercentComplete $progressPercentage
}


function Initialize-Module ($moduleName) {

    # If module is imported say that and do nothing
    if (Get-Module | Where-Object {$_.Name -eq $moduleName}) {
        write-host "Module $moduleName is already imported."
    }
    else {

        # If module is not imported, but available on disk then import
        if (Get-Module -ListAvailable | Where-Object {$_.Name -eq $moduleName}) {
            Import-Module $moduleName -Verbose
        }
        else {

            # If module is not imported, not available on disk, but is in online gallery then install and import
            if (Find-Module -Name $moduleName | Where-Object {$_.Name -eq $moduleName}) {
                Install-Module -Name $moduleName -Force -Verbose -Scope CurrentUser
                Import-Module $moduleName -Verbose
            }
            else {

                # If the module is not imported, not available and not in the online gallery then abort
                write-host "Module $moduleName not imported, not available and not in an online gallery, exiting."
                EXIT 1
            }
        }
    }
}

Initialize-Module "ImportExcel"

$subscriptioncounter = 0
$storageAccountCounter = 0

$subscriptions = Get-AzSubscription
$totalSubscriptions = $subscriptions.count
Write-Host "-- $($totalSubscriptions) Subscriptions Found"

foreach ($subscription in $subscriptions) {
    
    ++$subscriptioncounter

    Write-Host "-- Subscription # $subscriptioncounter $($subscription.Name)"
    Select-AzSubscription $subscription.Id    

    # Progress Bar
    # would like to get this working but I'm having trouble with the total subscriptions within the foreach loop.
    #Write-ProgressBar -label "Subscription" -CurrentNumber $subscriptionCounter -TotalNumber $($totalSubscriptions)


    Start-Sleep -Seconds 5 # may be helpful in avoiding getting throttled

        $storageAccounts = Get-AzStorageAccount
        Write-Host "--------------------------------- $($storageAccounts.count) Storage Accounts Found"
        $storageAccountCounter = 0
        
        foreach ($storageAccount in $storageAccounts) {
            ++$storageAccountCounter
            Write-Host "--------------------------------- Storage Account # $storageAccountCounter $($storageAccount.StorageAccountName)"
            
            $sizeInBytes = $(Get-AzMetric -ResourceID $storageaccount.Id -MetricName "UsedCapacity" -WarningAction:SilentlyContinue).Data.Average 
            $totalsize += $sizeInBytes
            [void]$StorageAccountDetails.Rows.Add($subscription.Name, $resourceGroup.ResourceGroupName, $storageAccount.StorageAccountName, $Subscription.Id, $ResourceGroup.Id, $StorageAccount.Id, $sizeInBytes, $sizeInBytes/1TB)
        
            Start-Sleep -seconds 1 # This seems necessary to avoid API timeouts
        }
    }
}


$StorageAccountDetails | Select-Object SubscriptionName, StorageAccountName, SizeInTB |  Export-Excel ./AzureTenantStorageSize.csv -AutoSize 

Stop-Transcript
