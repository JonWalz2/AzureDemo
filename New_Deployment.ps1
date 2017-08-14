Param(
    $ApplicationName = $(Get-PMGVariable -name ApplicationName),
    $SiteCode = $(Get-PMGVariable -name SiteCode),
    $Primary = $(Get-PMGVariable -name SCCMPrimaryQA)
)

$ActivityName = "Create Deployment for $ApplicationName"
$ActivityStatus = 'Success'
Update-log "Started activity: $ActivityName"

try{
    Update-Log "Script now executing in PowerShell version [$($PSVersionTable.PSVersion.ToString())] session in a [$([IntPtr]::Size * 8)] bit process"
    Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"

    Connect-Sccm -SiteCode $SiteCode
    Set-Location "$($sitecode):"
    if (!($CollectionName)){
        $CollectionName = 'Application Testing - Workstations'
    }
    $props = @{
        Name = $ApplicationName
        CollectionName = $CollectionName
        DeployPurpose = 'Available'
        AvailableDateTime = ((get-date).AddMinutes(10))
        TimeBaseOn = 'LocalTime'
    }
    Start-CMApplicationDeployment @props
    $deploymentinfo = Get-CMDeployment -CollectionName $CollectionName | Where-Object softwarename -eq $ApplicationName
    $AssignmentID = $deploymentinfo.AssignmentID
    Update-log "The new deployment has an AssignmentID of: $AssignmentID"
}
catch{
    # Catch any errors thrown above here, setting the result status and recording the error message to return to the activity for data bus publishing
    $ActivityStatus = "Failed"
    $ErrorMessage = $error[0] | Out-String
    Update-Log "An error occured attempting to create a deployment for $ApplicationName"
}
finally{
    Set-Location c:
    $varlist = 'deploymentinfo'
    remove-variable $varlist -Force -ErrorAction SilentlyContinue
    remove-variable varlist
}

# Record end of activity script process
Update-Log "Deployment to $CollectionName completed for $ApplicationName."
