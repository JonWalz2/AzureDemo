Param(
    $SiteCode = $(Get-PMGVariable -name SiteCode),
    $DPType = $(Get-PMGVariable -name DPType)
)

$ActivityName = "Content distribution for $ApplicationName to $DPType"
$ActivityStatus = 'Success'

[int]$ErrorState = 0
$ErrorMessage = ""

Update-Log "Activity Started: $ActivityName"
$ErrorActionPreference = 'Stop'
try{

    Update-Log "Script now executing in PowerShell version [$($PSVersionTable.PSVersion.ToString())] session in a [$([IntPtr]::Size * 8)] bit process"
    Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"
    Update-Log "Parameter values received: ApplicationName=$($ApplicationName);DPType=$($DPType);PackageId=$($PackageId);CMServerName=$($CMServerName); SiteCode=$($SiteCode)"

    Connect-SCCM -SiteCode $SiteCode
    $Location = $SiteCode + ":"
    Set-Location $Location

    If (!(($packageid.Length -eq 8) -and ($packageid.StartsWith($SiteCode))))
    {
        $PackageID = Get-CMApplication -name $ApplicationName | Select-Object -ExpandProperty PackageID
    }

    if ($PackageID.Trim().Length -gt 1)
    {
        Update-Log "PackageID = $PackageID"
        $DPGroups = Get-CMDistributionPointGroup

        if ($DPType -like 'store*' )
        {
            $PrimaryDPGroups = $DPGroups | Select-Object -ExpandProperty name | Where-Object {$_ -like 'store*' }
        }
        else
        {
            $PrimaryDPGroups = $DPGroups | Select-Object -ExpandProperty name | Where-Object {$_ -notlike 'store*' }
        }

        Update-Log "DPGroups $($PrimaryDPGroups | out-string)"

        #destribute content to datacenters and logistics
        foreach ($dpgroup in $PrimaryDPGroups){
            Update-Log "Distributing to $dpGroup"
            try
            {
                Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $dpgroup -ErrorAction Stop
            }
            catch
            {
                Update-Log "Failed to distribute content to DP Group $dpGroup. $($_.Exception.Message)"
                $ErrorMessage =  $ErrorMessage + "Failed to distribute content to DP Group $dpGroup. $($_.Exception.Message) `n"
            }
        }
    } # else PackageId not found
    else
    {
        Update-Log "Failed to find Package Id"
        $ErrorMessage =  $ErrorMessage + "Failed to find Package Id"
    }

}
catch
{
    $ErrorMessage = $error[0] | Out-String
    Update-Log "Exception caught during action [$script:CurrentAction]: $($Error[0])"
    $ActivityStatus = 'failed'
}
finally{
    $varlist = 'PrimaryDPGroups', 'DPGroups'
    remove-variable $varlist -Force -ErrorAction SilentlyContinue
    remove-variable varlist
    Update-Log "Finished Activity: $ActivityName"
}
