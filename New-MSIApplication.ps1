Param(
    $SiteCode = $(Get-PMGVariable -name SiteCode),
    $ApplicationName = $(Get-PMGVariable -name ApplicationName)
)

$ActivityName = 'Create MSI Application'
$ActivityStatus = 'Success'

Update-Log "Started Activity: $ActivityName"

try{
    $ErrorActionPreference = 'Stop'
    Update-Log "Script now executing in PowerShell version [$($PSVersionTable.PSVersion.ToString())] session in a [$([IntPtr]::Size * 8)] bit process"
    Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"

    Connect-Sccm -SiteCode $Sitecode
    Set-Location "$($sitecode):"

    if ($Categories){
        $Categories = $Categories.Split(',').Trim()
        $Categories = foreach ($category in $Categories){
            #Make sure the categories passed actually exist
            if (Get-CMCategory -Name $category){
                $category
            }
            else{
                Update-log "Category $category does not exist in SCCM and was not added."
                Throw "Category $category does not exist in SCCM and was not added."
            }
        }
    }
    if (Get-CMApplication -Name $ApplicationName){
        Update-Log "Process failed: $ApplicationName already exists."
        $ActivityStatus = 'Failed'
        Throw "Unable to create $ApplicationName. The Application already exists."
    }
    Update-Log "Attempting to create application: $ApplicationName"

    if ($LocalizedName -and $LocalizedDescription){
        $ScriptBlock = [scriptblock]::Create('New-CMApplication -Name $ApplicationName -Publisher $Publisher -SoftwareVersion $Version -Description "SSD: $Comments" -AutoInstall $true -LocalizedApplicationDescription $LocalizedDescription -LocalizedApplicationName $LocalizedName -ReleaseDate (get-date) -keyword $keywords -erroraction stop')
    }
    elseif($LocalizedName){
        $ScriptBlock = [scriptblock]::Create('New-CMApplication -Name $ApplicationName -Publisher $Publisher -SoftwareVersion $Version -Description "SSD: $Comments" -AutoInstall $true -LocalizedApplicationName $LocalizedName -ReleaseDate (get-date) -keyword $keywords -erroraction stop')
    }
    elseif($LocalizedDescription){
        $ScriptBlock = [scriptblock]::Create('New-CMApplication -Name $ApplicationName -Publisher $Publisher -SoftwareVersion $Version -Description "SSD: $Comments" -AutoInstall $true -LocalizedApplicationDescription $LocalizedDescription -ReleaseDate (get-date) -keyword $keywords -erroraction stop')
    }
    else{
        $ScriptBlock = [scriptblock]::Create('New-CMApplication -Name $ApplicationName -Publisher $Publisher -SoftwareVersion $Version -Description "SSD: $Comments" -AutoInstall $true -LocalizedApplicationDescription $LocalizedDescription -LocalizedApplicationName $LocalizedName -ReleaseDate (get-date) -keyword $keywords -erroraction stop')
    }

    Invoke-Command -scriptblock $ScriptBlock

    Remove-Variable -Name ScriptBlock
    
    if ($Iconpath -and $Categories){
        Update-log "Path to icon file is: $Iconpath"
        Set-CMApplication -Name $ApplicationName -DistributionPointSetting DeltaCopy -UserCategory $Categories -IconLocationFile $Iconpath -AppCategory 'Workstations' -erroraction Stop
    }
    elseif ($IconPath){
        Update-log "Path to icon file is: $Iconpath"
        Set-CMApplication -Name $ApplicationName -DistributionPointSetting DeltaCopy -IconLocationFile $Iconpath -AppCategory 'Workstations' -erroraction Stop
    }
    elseif ($Categories){
        Set-CMApplication -Name $ApplicationName -DistributionPointSetting DeltaCopy -UserCategory $Categories -AppCategory 'Workstations' -erroraction Stop
    }
    else{
        Set-CMApplication -Name $ApplicationName -DistributionPointSetting DeltaCopy -AppCategory 'Workstations' -erroraction Stop
    }
  
    
    Update-Log "No errors reported in the creation of $ApplicationName"
    #$ActivityStatus = 'report'
}
catch{
    # Catch any errors thrown above here, setting the result status and recording the error message to return to the activity for data bus publishing
    $ActivityStatus = "Failed"
    if (!($ErrorMessage)){
        $ErrorMessage = $error[0] | Out-String
    }
    Update-Log "An error occured attempting to create $ApplicationName $ErrorMessage"
}
finally{
    Set-Location c:
}

# Record end of activity script process
Update-Log "Finished Activity: $ActivityName."