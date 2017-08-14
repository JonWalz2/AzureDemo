#These functions are to be pulled into a workflow variable for use

Function Connect-SCCM{
    param(
        [CmdletBinding()]
        [ValidateNotNullOrEmpty()]
        [string]$SiteCode = $(throw "SiteCode is required"),
        [string]$Primary = 'WSQASM020.amer.qahomedepot.com'
    )
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -Force -ErrorAction Stop # Import the ConfigurationManager.psd1 module
    If (!(Get-Module -name ConfigurationManager)){
        import-module ConfigurationManager -force
    }
    if ((get-psdrive $SiteCode -erroraction SilentlyContinue | Measure-Object).Count -ne 1){
        new-psdrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $Primary  -Scope Global | Out-Null
        $Error.Clear()
    }
    Set-Location "$($SiteCode):" -ErrorAction Stop # Set the current location to be the site code.
}

function Get-ComputerInformation {
    try{
        get-ComputerInfo -ErrorAction Stop
    }
    catch{
        Get-CimInstance Win32_OperatingSystem
        Get-CimInstance Win32_ComputerSys
    }
}

function Post-JsonObjAPI {
    [CmdletBinding()]
    param
    (
      [String]
      $ApplicationName,
      $URI,
      $JSONData
    )
    if ($JSONData.GetType().name -ne 'string'){
        $global:JSONData = $JSONData | ConvertTo-Json -Depth 6
    }
    write-verbose "Inside Post-JsonObjAPI"
    write-verbose $jsondata
    Write-Verbose $jsondata.GetType()

    Invoke-RestMethod -Uri "$uri/$applicationname" -Body $jsondata -Method Post -ContentType 'application/json' -Verbose
}

function Get-JsonObjAPI {
    [CmdletBinding()]
    param
    (
      [String]
      $ApplicationName,
      $URI
    )
    $JSONObject = Invoke-RestMethod -Uri "$uri/$applicationname" -ErrorAction Stop
    #make sure that the object received is a valid JSON object
    try{
        $a = $JSONObject | ConvertTo-Json -Depth 6
        $JSONData = $a | ConvertFrom-Json -ErrorAction Stop
    }
    catch{
        throw "Data received from API call was not a valid JSON object."
    }
    $JSONData
}

function Write-Log{
    Param(
        [string]$Message
    )
    #Update the $JSONData trace log
    $Global:CurrentAction = $Message
    if ($Message.Length -gt 3){
        If (!($Message.EndsWith('.'))){
            $Message = $Message + '.'
        }
        $message = $Message.Replace('&','and')
        $message = $Message.Replace("'",'"')
    }
    $Global:Trace += ((Get-Date).ToString() + " " + $Message)
}

Function Send-FailureEmail {
    [CmdletBinding()]
    Param(
        [string]$RunbookName,
        [ValidateNotNullOrEmpty()]
        $trace = $(throw '$Trace is required but was not provided'),
        [string]$ActivityName,
        [ValidateNotNullOrEmpty()]
        [string]$email = $(throw '$email is required but was not provided'),
        [string]$ActivityStatus,
        [ValidateNotNullOrEmpty()]
        [string]$ErrorMessage = $(throw '$ErrorMessage is required but was not provided'),
        [ValidateNotNullOrEmpty()]
        [String]$ApplicationName = $(throw '$ApplicationName is required but was not provided')

    )

    If (!($email)){
       $email = 'Jonathan_Walz@HomeDepot.com'
    }

    $BodyData = @{
        ApplicationName = $ApplicationName
        RunbookName = $RunbookName
        ActivityName = $ActivityName
        ActivityStatus = $ActivityStatus
        ErrorMessage = $ErrorMessage
    }
    $BodyData = New-Object -TypeName psobject -Property $BodyData

    $Email = $Email
    $Subject = "Error during $RunbookName"
    $EmailFrom = "SSDAutomation@HomeDepot.com"
    $BodyData = $BodyData
    $Title = "Failure during activity: $activityname"
    $Footer = "$Trace"

$head=@"
<style>
@charset "UTF-8";

table
{
font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;
border-collapse:collapse;
}
td
{
font-size:1em;
border:1px solid #98bf21;
padding:5px 5px 5px 5px;
}
th
{
font-size:1.1em;
text-align:center;
padding-top:5px;
padding-bottom:5px;
padding-right:7px;
padding-left:7px;
background-color:#ee7125;
color:#ffffff;
}
name tr
{
color:#F00000;
background-color:#EAF2D3;
}
</style>
"@

    If (!($Title)){
        $Title = $Subject
    }
    $body = $bodydata
    $body = $body | select ApplicationName, RunbookName, ActivityName, ActivityStatus, ErrorMessage | ConvertTo-HTML -Head $head -PreContent "<H2>$title</H2>" -PostContent "<br><br><H3>Trace information:</H3>$($footer -Split '(?=\d{1,2}/\d*/\d* \d*:\d*:\d*)' | %{"$_<br>"})" | out-string
    $body += "<br><br>This is an automated message. Please do not reply to this message."
    Send-MailMessage -SmtpServer 'mail2.homedepot.com' -to $Email -Subject $Subject -Body $body -BodyAsHtml -From $EmailFrom
} #End Send-FailureEmail

Function Publish-ToTimeline{
    [CmdletBinding()]
    param(
        $ApplicationName,
        $RunbookName,
        $IsError,
        $data,
        $URI,
        $NewTrace
    )

    $CurrentDateTime = ((get-date).ToUniversalTime()).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    $BodyData =@{
        "ApplicationName" = $ApplicationName
        "RunbookName" = $RunbookName
        "IsError" = $iserror.ToUpper()
        "ReceivedDateTime" = $CurrentDateTime
        "Data" = $data | ConvertFrom-Json
    }

    $NewTrace = $NewTrace | ConvertTo-Json
    $BodyData = $BodyData | ConvertTo-Json
    $Bodydata = $BodyData.Replace('"trace"',$newtrace)
    $BodyData

    try{
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Accept", 'application/json')
        $headers.Add("Content-Type", 'application/json')
        $ApiResponse = Invoke-WebRequest -Method Post -Uri $uri -Body $BodyData -Headers $headers -UseBasicParsing -ErrorAction Stop
        if ($ApiResponse.StatusCode -ne "200")
        {
            Throw "Failed to send data to api. Response Code: $($ApiResponse.StatusCode). Content : $($ApiResponse.Content)"
        }

    }
    catch{
        $global:errormessage = $error[0] | Out-String
        #throw $errormessage
    }
}

function Test-Error{
    [CmdletBinding()]
    Param
    (
        [ValidateNotNullOrEmpty()]
        $ApplicationName = $(Throw "ApplicationName is required"),
        [ValidateNotNullOrEmpty()]
        $APIReadJSON = $(Throw "APIReadJSON is required"),
        [ValidateNotNullOrEmpty()]
        $Timelineuri = $(Get-PMGVariable -name APIUpdateTimeline),
        [ValidateNotNullOrEmpty()]
        $APIWriteDatabase = $(Get-PMGVariable -name APIWriteDatabase)
    )
    #Check for ErrorMessage or ActivityStats = 'FAILED'
    Write-Verbose "Running Test-Error"

    $jsondata = Get-JsonObjAPI -ApplicationName $ApplicationName -URI $APIReadJSON
    if ($jsondata.GetType() -eq 'String'){
        $jsondata = $jsondata | ConvertFrom-Json
    }
    #Set-PMGVariable -name JSONObject -Value ($jsondata)
    $ErrorMessage = $null
    if ($jsondata.errormessage){
        $ErrorMessage = $JSONData.ErrorMessage
    }
    $ActivityStatus = $jsondata.activitystatus
    If (($errormessage) -or ($activitystatus -ne 'SUCCESS')){
        $params = @{
            Runbookname = $jsondata.runbookname
            trace = $jsondata.Trace
            ActivityName = $jsondata.ActivityName
            ActivityStatus = $jsondata.ActivityStatus
            ErrorMessage = $ErrorMessage
            ApplicationName = $jsondata.ApplicationName
            email = $jsondata.email
        }
        Write-Verbose $params
        #send failure email
        Send-FailureEmail @params -Verbose
    }

    #update timeline


    Write-Verbose "`$Timelineuri is $Timelineuri"

    $ErrorActionPreference = 'stop'

    try{
        $trace = $jsondata.trace
        $trace = $trace.Replace('`n',"").replace("`n","")
        #$t = $trace -split '(?=\d{1,2}/\d*/\d* \d*:\d*:\d*)'
        $t = $trace -split '(?=(0?[1-9]|1[012])/\d*/\d* \d*:\d*:\d*)'
        $t = $t | %{if ($_.length -ge 3){$_}}
        $newtrace = @()
        $newtrace += foreach ($log in $t){
            if ($log){
                $log -match '(?<date>\d{1,2}/\d*/\d* \d*:\d*:\d* [AM/PM]{2})(?<data>.*)' | Out-Null
                if ($Matches){
                    New-Object -TypeName psobject -Property @{time = $Matches.date; description = ($Matches.data).Trim()}
                    #"{ time : $($Matches.date), description : $(($Matches.data).trim()) }"
                }
            }
        }

        $newtrace = $newtrace | ConvertTo-Json

        If ($ActivityStatus -eq 'failure'){
            $ActivityStatus = 'FAILED'
        }

        If ($jsondata.ErrorMessage){
            try {
                $jsondata.errormessage = $ErrorMessage.Split("`n")[0]
            }
            catch{
            }
            $data = @{
                Step = "QA - $($jsondata.ActivityName)"
                Status = $jsondata.ActivityStatus.ToUpper()
                ErrorMessage = $jsondata.ErrorMessage
                Trace = 'trace'
            }
        }
        else {
            $data = @{
                Step = "QA - $($jsondata.ActivityName)"
                Status = $jsondata.ActivityStatus.ToUpper()
                Trace = 'trace'
            }
        }

        $data = $data | ConvertTo-Json
        Publish-ToTimeline -ApplicationName $ApplicationName -RunbookName $jsondata.RunbookName -IsError $jsondata.ActivityStatus -data $data -NewTrace $newtrace -URI $Timelineuri

    }
    catch{
        $ErrorMessage = $error[0] | Out-String
    }
    #update database

    Write-Verbose "`$uri is $apiwritedatabase"
    Write-Verbose "`$applicationname is $applicationname"
    $jsondata = $jsondata | ConvertTo-Json -Depth 6
    Post-JsonObjAPI -ApplicationName $ApplicationName -URI $apiwritedatabase -JSONData $JSONData -Verbose
    $ErrorMessage
}

Function Start-Script{
    [CmdletBinding()]
    param()
    try{
        $initialvars = Get-Variable
        $JSONData = Get-PMGVariable -name JSONObject | ConvertFrom-Json

        #create new variables based on the data in JSONData
        $JsonData.psobject.Members | Where-Object Membertype -eq Noteproperty | foreach {New-Variable -Name $_.name -Value $_.value -force -ErrorAction SilentlyContinue}

        #create a list of all the new variables that were created from $JSONData
        $JSONDataVars = Get-Variable | where name -Notin ($initialvars).name
        $JSONDataVars = $JSONDataVars | where {$_.name -NotLike 'initialvars' -and $_.name -notlike 'JSONData'}
        $trace = ""

        #run PowerShell code stored in PMG variables

        invoke-expression (Get-PMGVariable -name PowerShellScript)
    }
    catch{
        $errormessage = $error[0] | Out-String
        Set-PMGVariable -name Script_Error -value $ErrorMessage
    }

    $newvarlist = Get-Variable | where{$_.name -notin ($initialvars).name -and $_.name -notin ($JSONDataVars).name} | where {$_.name -notlike 'jsondatavars' -and $_.name -notlike 'initialvars' -and $_.name -notlike 'JSONData' -and $_.name -notlike 'currentaction'}
    $newvarlist = $newvarlist | where value -ne $null

    #determine which variables from JSONData have changed and update $JSONData with the new values
    foreach ($var in $JSONDataVars){
        if ((get-variable $var.name -ValueOnly) -ne $JSONData.($var.name)){
            #the value has changed, update $JSONData
            $Jsondata.($var.name) = get-variable $var.name -ValueOnly
        }
    }

    #add newly created variables to JSONData
    foreach ($var in $newvarlist){
        $JSONData | Add-Member -MemberType NoteProperty -Name $var.name -Value $var.Value -Force
    }
    Write-Verbose "Trace: $($JsonData.trace)"
    Write-Verbose "Trying to set JSONObject"
    Set-PMGVariable -name JSONObject -value ($JSONData | ConvertTo-Json -Depth 6)
}

function Get-DatabaseData {
	[CmdletBinding()]
	param (
		[string]$connectionString,
		[string]$query
	)
	$connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$command = $connection.CreateCommand()
	$command.CommandText = $query
	$adapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter $command
	$dataset = New-Object -TypeName System.Data.DataSet
	$adapter.Fill($dataset)
	$dataset.Tables[0]
}
function Get-PMGCredential {
    [CmdletBinding()]
	param (
		[string]$ScenarioName
	)
    $query = "SELECT * FROM [dbo].[udf_get_ConnectorConfig] ('Powershell.Config.xml', '$ScenarioName')"
    Add-Type -Path 'H:\Program Files\PMG Service Catalog\SPE\Bin\PMGSPEUtils.DB.dll'
    $PMG_Util = New-Object PMGSPEUtils.DB.DbUtils
    $connection_string = $PMG_Util::GetConnectionString('PMGSPE')
    $connection_string = $connection_string.replace('Driver={SQL Server};','')
    $data = Get-DatabaseData -connectionString $connection_string -query $query
    $Password = $data.password
    Add-Type -Path "H:\Program Files\PMG Service Catalog\SPE\Bin\PMGSPEEncryption.dll"
    $PMG_Decoder = New-Object PMGSPEEncryption.Encryption
    $Password = $PMG_Decoder::DecryptSafeString2($Password)
    return [pscustomobject]@{username = $data.username; password = $Password}
}

New-Alias -Name Update-Log -Value Write-Log -Force