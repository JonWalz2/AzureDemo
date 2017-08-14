#should all the inputs be parameters with default values?
param(
    $SourcePath = (Get-PMGVariable -name SourcePath),
    $ApplicationName = (Get-PMGVariable -name ApplicationName),
    $APIReadJSON = (Get-PMGVariable -Name APIReadJSON),
    $APIWriteDatabase = (Get-PMGVariable -Name APIWriteDatabase)
)
$ErrorActionPreference = 'stop' #added to pass any uncaught error to the PMG workflow 
#$SourcePath = Get-PMGVariable -name SourcePath

$ActivityName = "Copy from Intake to SSD share"
$RunbookName = "Copy-FromIntakeToSSD"

Update-Log "Started Activity: $ActivityName"
Update-Log "ApplicationName is: $ApplicationName"

$SourcePath = $SourcePath.ToUpper()
$SourcePath = $SourcePath | Split-Path -Parent

try{
    If (!(test-path $SourcePath)){
        throw "invalid SourcePath passed"
    }
    
    If (($SourcePath | Split-Path -Parent).endswith('TEST')){
        $destination = '\\ssd-test\SSD-Test\intake'
        $Processed = '\\at1a3\vol4\DEPTS\ISPROG\Retail Systems Packaging\RSP_Inbox\Automated_Processed_Test'
    }
    
    If (($SourcePath | Split-Path -Parent).endswith('DEV')){
        $destination = '\\ssd-dev\ssd-dev\intake'
        $Processed = '\\wn1341.amer.qahomedepot.com\SSD_Share\PMG\Processed'
    }
    
    If (($SourcePath | Split-Path -Parent).endswith('INTAKE')){
        $Global:destination = '\\ssd\SSD\intake'
        $Processed = '\\at1a3\vol4\DEPTS\ISPROG\Retail Systems Packaging\RSP_Inbox\Automated_Processed'
    }
    
    
    #Copy application folder to $destination .JSON file last
    Start-Sleep -Seconds 2
    $folderToCopy = $SourcePath
    if (test-path "$destination\$ApplicationName"){
        Remove-Item "$destination\$ApplicationName" -Recurse -Force
    }

    Update-log "Copying $folderToCopy to $destination\$ApplicationName"

    Copy-Item $folderToCopy -Destination "$destination\$ApplicationName" -Recurse -Force -Container
    
    #Move folder to $Processed
    $check = "$Processed\$($folderToCopy | Split-Path -Leaf)"
    if (Test-Path $check){
        Remove-Item $check -Recurse -Force
    }
    Move-Item $folderToCopy -Destination $Processed -Force -Verbose
    Remove-Variable folderToCopy
    Remove-Variable destination
    Remove-Variable Processed
}
catch{
    $errormessage = $error[0] | Out-String
    update-log $errormessage
}
