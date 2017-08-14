Param(
    $ApplicationName = $(Get-PMGVariable -name ApplicationName),
    $SiteCode = $(Get-PMGVariable -name SiteCode),
    $DSL_path = $(Get-PMGVariable -name DSL_QA),
    $SSDIntake = $(Get-PMGVariable -name SSDIntake),
    $ReadDatabaseURI = $(Get-PMGVariable -name APIReadJSON),
    $WriteDatabaseURI = $(Get-PMGVariable -name APIWriteDatabase)
)
$ErrorActionPreference = 'Stop'

$ActivityName = 'Copy to DSL'
$ActivityStatus = 'Success'
Update-log "Started Activity: $ActivityName"
Update-Log "ApplicationName is: $ApplicationName"

try{
    Update-Log "Script now executing in PowerShell version [$($PSVersionTable.PSVersion.ToString())] session in a [$([IntPtr]::Size * 8)] bit process"
    Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"

    Update-Log "Checking to see if $ApplicationName exists in SCCM"
    Connect-SCCM -SiteCode $SiteCode
    $app = Get-CMApplication -Name $ApplicationName
    if ($app){
        Update-Log "$ApplicationName already exits in SCCM"
        $ActivityStatus = 'FAILED'
        $ErrorMessage = "$ApplicationName already exists in SCCM"
        throw "$ApplicationName already exists in SCCM"
    }
    else{
        Update-Log "$ApplicationName does not exist in SCCM"
    }
   Set-Location C:
   if (Test-Path "$DSL_path\$ApplicationName"){
        if ($ApplicationName.Length -gt 2){
            Update-log "The Application folder already exists on the DSL. Removing it."
            Remove-Item "$DSL_path\$ApplicationName" -Recurse -Force
            new-item -ItemType directory "$DSL_path\$ApplicationName"
        }
   }

   else {
       new-item -ItemType directory "$DSL_path\$ApplicationName"
   }

   $SSDIntake = $SSDIntake.trim()
   $ApplicationName = $ApplicationName.trim()
   $source = "$SSDIntake\$applicationName"
   Update-Log "The source path is: $source"
   Copy-Item -Path "$source\*" -Destination "$DSL_path\$ApplicationName\" -Recurse -Force -Verbose -ErrorAction Stop
   Update-Log "Attempting to copy $JSONPath to $DSL_path"
   remove-item $source -Recurse -Force
   $Source = "$DSL_path\$ApplicationName"
}
catch{
    # Catch any errors thrown above here, setting the result status and recording the error message to return to the activity for data bus publishing
    $ActivityStatus = "FAILED"
    if (!($ErrorMessage)){
        $ErrorMessage = $error[0] | Out-String
        $ActivityStatus = 'FAILED'
        Update-Log "An error occured attempting to copy the Application files to the DSL`n`n $ErrorMessage"
    }

}
finally{
    Set-Location c:
    $ActivityName = 'Copy to DSL'
    if (Get-Variable -Name App -ErrorAction SilentlyContinue){
        Remove-Variable -Name App
    }
}

# Record end of activity script process
Update-Log "Finished Activity: $ActivityName."
If ($ActivityStatus -ne 'FAILED'){
    $ActivityStatus = 'success'
}

