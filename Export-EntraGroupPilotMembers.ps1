function Export-EntraGroupPilotMembers {
    <#
    .Synopsis
    Will return a list of random workstations to form a pilot based on a percentage given.
    .Description
    Will return a list of random workstations to form a pilot based on a percentage given.
    .Example
    Export-g46EntraGroupPilotMembers -SourceEntraGroupName "GroupName" -Percentage "5"
    .Parameter SourceEntraGroupName
    The entra group name to build the pilot off of.
    .Parameter Percentage
    The percentage to build the pilot off of.
    #> 

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [string]$SourceEntraGroupName,
        [Parameter(Mandatory = $True)]
        [ValidateRange(1, 100)][int]$Percentage
    )

    #region Declarations
    $FunctionName = $MyInvocation.MyCommand.Name.ToString()
    $date = Get-Date -Format yyyyMMdd-HHmm
    if ($outputdir.Length -eq 0) { $outputdir = $pwd }
    $OutputFilePath = "$OutputDir\$FunctionName-$date.csv"
    $LogFilePath = "$OutputDir\$FunctionName-$date.log"
    $graphApiVersion = "beta"
    $resultsArray = @()
    #endregion
    
    # Microsoft Graph Connection check
    if ($null -eq (Get-MgContext)) {
        Write-Error "Connect to Graph"
        Break
    }

    #region Obtain Group
    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/groups?`$filter=DisplayName eq '$SourceEntraGroupName'"
        $group = (Invoke-MgGraphRequest -uri $uri -Method GET).value
        Write-Host "Obtaining Group: $sourceEntraGroupName"
    }
    catch {
        Write-Error "An error occurred : $_"
    }
    #end region

    #region Obtain Group Members  
    $resultCheck = @()   
    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/groups/$($group.Id)/members"
        #pagination
        do {
            $groupmembers = (Invoke-MgGraphRequest -Uri $uri -Method GET)
            $resultCheck += $groupmembers
        
            $uri = $groupmembers.'@odata.nextLink'
        } while ($uri)
        $groupmembers = $resultCheck.value

        Write-Host "Obtaining '$($group.DisplayName)' with $($groupmembers.count) members." -ForegroundColor Cyan
    }
    catch {
        Write-Host "An error occurred : $_"
    }
    #endregion


    #region Randomization
    $Decimal = $Percentage / 100
    $NumberofMembers = [int]($($groupMembers).Count * $Decimal)
    $NumberofMembers = [Math]::Ceiling($NumberofMembers)

    Write-Host "Randomizing group and gathering $NumberofMembers workstations." -ForegroundColor Cyan
    $GroupMembers = $GroupMembers | Sort-Object { Get-Random }
    $GroupMembers = $GroupMembers | Select-Object -First $NumberofMembers

    #endRegion

    #region Build Object
    foreach ($member in $groupMembers) {
        $result = New-Object -TypeName PSObject -Property @{
            EntraDeviceID = $member.deviceId
            DeviceName    = $member.displayName
        }
        $ResultsArray += $result
    }
    #endregion

    #region Results
    if ($ResultsArray.Count -ge 1) {
        $ResultsArray | Export-Csv -Path $outputfilepath -NoTypeInformation
    }

    # Test if output file was created
    if (Test-Path $outputfilepath) {
        Write-g46log -Message "Output file = $outputfilepath."
    }
    else {
        Write-g46log -Message "No output file created." -Level Warning
    }
    #endregion
}
