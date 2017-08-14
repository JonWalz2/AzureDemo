Param(
    $CMSiteCode = $(Get-PMGVariable -name SiteCode),
    $CMServerName = $(Get-PMGVariable -name SCCMPrimaryQA),
    $ApplicationName = $(Get-PMGVariable -name ApplicationName)
)
$ActivityName = "Verify content distribution"
$ActivityStatus = "Success"
Update-Log "Started Activity: $ActivityName"
"ApplicationName: $ApplicationName"
try{

    Update-Log "Script now executing in PowerShell version [$($PSVersionTable.PSVersion.ToString())] session in a [$([IntPtr]::Size * 8)] bit process"
    Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"
    Update-Log "Parameter values received: ApplicationName=$($ApplicationName);DPType=$($DPType); CMServerName=$($CMServerName); CMSiteCode=$($CMSiteCode)"

    Connect-SCCM -SiteCode $CMSiteCode -Primary $CMServerName
    $Location = $CMSiteCode + ":"
    Set-Location $Location

    If (!(($packageid.Length -eq 8) -and ($packageid.StartsWith($SiteCode)))){
        $PackageID = Get-CMApplication -name $ApplicationName | Select-Object -ExpandProperty PackageID
    }
    $ResultStatus = 'Failed'
    "PackageID is $PackageID"
    $StatusInfo = Get-WmiObject -NameSpace Root\SMS\Site_$CMSiteCode -Class SMS_PackageStatusDistPointsSummarizer -Filter "PackageID='$PackageID' AND NOT State=0" -ComputerName $CMServerName
    If ($StatusInfo -eq $null){
        Update-Log 'Installed number matches targeted number. This indicates success'
        $ResultStatus = 'Success'
    }

    If ($statusinfo | Where-Object state -eq 3){
        Update-Log 'Failed state'
        $ResultStatus = 'Failed'
    }
}
catch{
    $ErrorMessage = $error[0] | Out-String
    Update-Log "Exception caught during action [$script:CurrentAction]: $($Error[0])"
    $ActivityStatus = 'failed'
    $ErrorMessage
    $ResultStatus = "Failed due to error"
}
finally{
    "ResultStatus is $resultstatus"
    Update-Log "Finished Activity: $ActivityName"
    Set-PMGVariable -name DistributionStatus -value $ResultStatus
    $varlist = 'ResultStatus', 'StatusInfo'
    remove-variable $varlist -Force -ErrorAction SilentlyContinue
    remove-variable varlist
}
