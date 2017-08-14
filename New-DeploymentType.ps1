Param(
    $SiteCode = $(Get-PMGVariable -name SiteCode),
    $ApplicationName = $(Get-PMGVariable -name ApplicationName),
    $DSL = $(Get-PMGVariable -name DSL_QA),
    $Primary = $(Get-PMGVariable -name SCCMPrimaryQA)
)
#$DeploymentTypes = $DeploymentTypes | ConvertFrom-Json -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'
Set-Location C:

Function Get-SCCMGlobalCondition($name,$siteServerName){
    $connectionManager = new-object Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlConnectionManager  
    $isConnected = $connectionManager.Connect($siteServerName)
	$SCCMserver = $connectionManager.NamedValueDictionary.ServerName
    $SCCMsitecode = $connectionManager.NamedValueDictionary.ConnectedSiteCode
	$SCCMNamespace = "root\sms\site_$SCCMsitecode" 
    #$nameformated = $name.Replace(" ","")
    $objResult = Get-WmiObject -Class SMS_GlobalCondition -Namespace $SCCMNamespace -filter "ModelName like '%$name%' " -ComputerName $SCCMserver
    if($objResult -eq $null){       
        $objResult = Get-WmiObject -Class SMS_GlobalCondition -Namespace $SCCMNamespace -filter "ModelName = '$name'" -ComputerName $SCCMserver
    }
    if($objResult -eq $null){       
        $objResult = Get-WmiObject -Class SMS_GlobalCondition -Namespace $SCCMNamespace -filter "LocalizedDisplayName = '$name'" -ComputerName $SCCMserver
    }
    $objResult
 }

Function Add-CMDeploymentTypeGlobalCondition{
    <#
    .SYNOPSIS
	    Add a Requirement to an existing SCCM 2012 Application / Deployment Type
    .DESCRIPTION
	    Add a Requirement to an existing SCCM 2012 Application / Deployment Type
    .PARAMETER sdkserver
	    Configuration Manager SMS Provider Server. This can be Netbios Name, IP Address or FQDN Name
    .PARAMETER sitecode
	    Configuration Manager Site Code
    .PARAMETER GlobalCondition
	    Requirement to be added.
	    Possible values are:
		    OperatingSystem
		    TotalPhysicalMemory
		    NumberOfProcessors
		    OSLanguage
		    CPUSpeed
		    MachineOU
		    PrimaryDevice
		    FreeDiskSpace
		    Device_OwnershipDesktop
    .PARAMETER Operator
	    Operator for the validation. 
	    Possible values are:
		    IsEquals
		    NotEquals
		    GreaterThan
		    LessThan
		    GreaterEquals
		    LessEquals
		    OneOf
		    NoneOf
    .PARAMETER Value
	    Value to be added to the requirement
	    For values for Operating System, use the SQL Query SELECT ModelName FROM v_CICategories_All where CategoryTypeName = 'Platform'
	    For values for Languase, use the SQL Query select distinct cast(Replace(CategoryInstance_UniqueID, 'Locale:', '') as int), CategoryInstanceName  from v_CICategoryInfo where CategoryTypeName='Locale' order by 1
	    Values for Device_OwnershipDesktop can only be Company or Personal
    .PARAMETER ApplicationName
	    Configuration Manager application name, as apper in the console
    .PARAMETER DeploymentTypeName
	    Configuration Manager deployment type, as apper in the console
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "OperatingSystem"
	    PS C:\PSScript > $Operator = "NoneOf"
	    PS C:\PSScript > $Value = "Windows/x64_Windows_7_Client;Windows/All_x64_Windows_8.1_Client"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add an Operating System Requirement for an Application where the OS cannot be Windows 7 x64 or Windows 8.1 x64
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "TotalPhysicalMemory"
	    PS C:\PSScript > $Operator = "GreaterThan"
	    PS C:\PSScript > $Value = (1024 * 1024 * 1024).ToString()
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Total Physical Memory Requirement for an Application where the computer has to have more than 1024MB of RAM
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "NumberOfProcessors"
	    PS C:\PSScript > $Operator = "IsEquals"
	    PS C:\PSScript > $Value = "3"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Number Of Processors Requirement for an Application where the computer has to have 3 processors
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "PrimaryDevice"
	    PS C:\PSScript > $Operator = "IsEquals"
	    PS C:\PSScript > $Value = "True"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Primary Device Requirement for an Application where the application will only be installed if the user is a primary user of the computer
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "FreeDiskSpace"
	    PS C:\PSScript > $Operator = "GreaterThan"
	    PS C:\PSScript > $Value = (5 * 1024 * 1024).ToString()
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Free Disk Space Requirement for an Application where the computer has to have more than 5GB of disk space on any drive
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "OSLanguage"
	    PS C:\PSScript > $Operator = "OneOf"
	    PS C:\PSScript > $Value = "9;1046"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add an OS Language Requirement for an Application where the application will be installed only on English and Brazilian Portuguese languages
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "MachineOU"
	    PS C:\PSScript > $Operator = "OneOf"
	    PS C:\PSScript > $Value = "CN=Computers,DC=CORP,DC=LOCAL;CN=Computers-Old,DC=CORP,DC=LOCAL"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Machine OU Requirement for an Application where the computer must be part of the Computer or Computers-OS in the active directory
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "CPUSpeed"
	    PS C:\PSScript > $Operator = "IsEquals"
	    PS C:\PSScript > $Value = "3000"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a CPU Speed Requirement for an Application where the computer needs to have CPU equals to 3000MHz
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "Device_OwnershipDesktop"
	    PS C:\PSScript > $Operator = "IsEquals"
	    PS C:\PSScript > $Value = "Company"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a Device Ownership Requirement for an Application where the computer needs to be a company owned computer
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "ADSite"
	    PS C:\PSScript > $Operator = "OneOf"
	    PS C:\PSScript > $Value = "LONDON"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add an Active Directory Site Requirement for an Application where the computer needs to be member of an Active Directory Site
    .EXAMPLE
	    PS C:\PSScript > $ApplicationName = "Google Chrome 39.0.2171.99"
	    PS C:\PSScript > $DeploymentTypeName = "MSI - x86"
	    PS C:\PSScript > $dkserver = "srv0007"
	    PS C:\PSScript > $sitecode = "CLC"
	    PS C:\PSScript > $GlobalCondition = "SCCMSite"
	    PS C:\PSScript > $Operator = "OneOf"
	    PS C:\PSScript > $Value = "CLC"
	    PS C:\PSScript > .\Add-CMDeploymentTypeGlobalCondition.ps1 -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName" -sdkserver "$dkserver" -sitecode "$sitecode" -GlobalCondition "$GlobalCondition" -Operator "$Operator" -Value "$Value"
	    Will add a SCCM Site Requirement for an Application where the computer/user needs to be member of an SCCM Site
    .INPUTS
	    None.  You cannot pipe objects to this script.
    .OUTPUTS
	    No objects are output from this script.  
    .LINK
	    http://www.rflsystems.co.uk
	    http://www.thedesktopteam.com
    .NOTES
	    NAME: Add-CMDeploymentTypeGlobalCondition.ps1
	    VERSION: 0.01
	    AUTHOR: Raphael Perez
	    PUBLISHED: May 19, 2015
    #>
    [CmdletBinding()] 
    Param (
	    [parameter(Mandatory = $True)][string]$sdkserver,
	    [parameter(Mandatory = $True)][string]$sitecode,
	    [parameter(Mandatory = $True)][ValidateSet('OperatingSystem', 'TotalPhysicalMemory', 'NumberOfProcessors', 'OSLanguage', 'CPUSpeed', 'MachineOU', 'PrimaryDevice', 'FreeDiskSpace', 'SCCMSite', 'ADSite', 'Device_OwnershipDesktop', IgnoreCase = $true)] [string]$GlobalCondition,
	    [parameter(Mandatory = $True)][ValidateSet('IsEquals', 'NotEquals', 'GreaterThan', 'LessThan', 'GreaterEquals', 'LessEquals', 'OneOf', 'NoneOf', IgnoreCase = $true)] [string]$Operator,
	    [parameter(Mandatory = $True)][string]$Value,
	    [parameter(Mandatory = $True)][string]$ApplicationName,
	    [parameter(Mandatory = $True)][string]$DeploymentTypeName
    )
    $ErrorActionPreference = 'Stop'
    ##Validation

    switch ($GlobalCondition.Tolower())
    {
        { ($_ -eq 'operatingsystem') -or ($_ -eq 'oslanguage') -or ($_ -eq 'machineou') -or ($_ -eq 'adsite') -or ($_ -eq 'sccmsite') } {
            if ($operator -notin @('oneof', 'noneof')) { Update-Log "Invalid operation ($Operator) for $GlobalCondition. No further action taken..." -ForegroundColor 'Red'; return }
            if ($_ -eq 'operatingsystem')
            {
                foreach ($val in $Value.Split(';'))
                {
                    if ($val -notin @('Android/All_Android','Android/Android_4_0','Android/Android_4_1','Android/Android_4_2','iOS/iPad','iOS/iPad_5','iOS/iPad_6','iOS/iPad_7','iOS/iPad_8','iOS/iPhone','iOS/iPhone_5','iOS/iPhone_6','iOS/iPhone_7','iOS/iPhone_8','Mac/All_Mac','Mac/All_Mac_10_10','Mac/All_Mac_10_6','Mac/All_Mac_10_7','Mac/All_Mac_10_8','Mac/All_Mac_10_9','Mobile/All_Mobile','Symbian/All_Symbian','Windows/All_ARM_Windows_8.1','Windows/All_ARM_Windows_8.1_Client','Windows/All_ARM_Windows_8_Client','Windows/All_Embedded_Windows_XP','Windows/All_IA64_Windows_Server_2003_Non_R2','Windows/All_IA64_Windows_Server_2008','Windows/All_Windows_Client_Server','Windows/All_Windows_RT','Windows/All_x64_Windows_7_Client','Windows/All_x64_Windows_8.1','Windows/All_x64_Windows_8.1_and_higher_Clients','Windows/All_x64_Windows_8.1_Client','Windows/All_x64_Windows_8_and_higher_Client','Windows/All_x64_Windows_8_Client','Windows/All_x64_Windows_Embedded_8.1_Industry','Windows/All_x64_Windows_Embedded_8_Industry','Windows/All_x64_Windows_Embedded_8_Standard','Windows/All_x64_Windows_Server_2003_Non_R2','Windows/All_x64_Windows_Server_2003_R2','Windows/All_x64_Windows_Server_2008','Windows/All_x64_Windows_Server_2008_R2','Windows/All_x64_Windows_Server_2012_R2','Windows/All_x64_Windows_Server_2012_R2_and_higher','Windows/All_x64_Windows_Server_8','Windows/All_x64_Windows_Server_8_and_higher','Windows/All_x64_Windows_Vista','Windows/All_x64_Windows_XP_Professional','Windows/All_x86_Windows_7_Client','Windows/All_x86_Windows_8.1','Windows/All_x86_Windows_8.1_and_higher_Clients','Windows/All_x86_Windows_8.1_Client','Windows/All_x86_Windows_8_and_higher_Client','Windows/All_x86_Windows_8_Client','Windows/All_x86_Windows_Embedded_8.1_Industry','Windows/All_x86_Windows_Embedded_8_Industry','Windows/All_x86_Windows_Embedded_8_Standard','Windows/All_x86_Windows_Server_2003_Non_R2','Windows/All_x86_Windows_Server_2003_R2','Windows/All_x86_Windows_Server_2008','Windows/All_x86_Windows_Vista','Windows/All_x86_Windows_XP','Windows/IA64_Windows_Server_2003_SP1','Windows/IA64_Windows_Server_2003_SP2','Windows/IA64_Windows_Server_2008_original_release','Windows/IA64_Windows_Server_2008_SP2','Windows/x64_Embedded_Windows_7','Windows/x64_Windows_7_Client','Windows/x64_Windows_7_SP1','Windows/x64_Windows_Server_2003_R2_original_release_SP1','Windows/x64_Windows_Server_2003_R2_SP2','Windows/x64_Windows_Server_2003_SP1','Windows/x64_Windows_Server_2003_SP2','Windows/x64_Windows_Server_2008_Core','Windows/x64_Windows_Server_2008_original_release','Windows/x64_Windows_Server_2008_R2','Windows/x64_Windows_Server_2008_R2_Core','Windows/x64_Windows_Server_2008_R2_SP1','Windows/x64_Windows_Server_2008_R2_SP1_Core','Windows/x64_Windows_Server_2008_SP2','Windows/x64_Windows_Server_2008_SP2_Core','Windows/x64_Windows_Vista_Original_Release','Windows/x64_Windows_Vista_SP1','Windows/x64_Windows_Vista_SP2','Windows/x64_Windows_XP_Professional_SP1','Windows/x64_Windows_XP_Professional_SP2','Windows/x86_Embedded_Windows_7','Windows/x86_Windows_7_Client','Windows/x86_Windows_7_SP1','Windows/x86_Windows_Server_2003_R2_original_release_SP1','Windows/x86_Windows_Server_2003_R2_SP2','Windows/x86_Windows_Server_2003_SP1','Windows/x86_Windows_Server_2003_SP2','Windows/x86_Windows_Server_2008_Core','Windows/x86_Windows_Server_2008_original_release','Windows/x86_Windows_Server_2008_SP2','Windows/x86_Windows_Vista_Original_Release','Windows/x86_Windows_Vista_SP1','Windows/x86_Windows_Vista_SP2','Windows/x86_Windows_XP_Professional_Service_Pack_2','Windows/x86_Windows_XP_Professional_Service_Pack_3','WindowsMobile/All_Windows_Mobile','WindowsMobile/Windows_Mobile_6.1','WindowsMobile/Windows_Mobile_6.5','WindowsPhone/All_Windows_Phone','WindowsPhone/Windows_Phone_8','Windows/All_x64_Windows_10_and_higher_Clients','Windows/All_x64_Windows_Server_2012','Windows/All_x64_Windows_Server_2016','Windows/All_x86_Windows_10_and_higher_Clients'))
                    { Throw "Invalid value ($val) for $GlobalCondition. No further action taken..." }
                }
            }
            break
        }
        { ($_ -eq 'totalphysicalmemory') -or ($_ -eq 'numberofprocessors') -or ($_ -eq 'cpuspeed') -or ($_ -eq 'freediskspace') } {
            if ($operator -notin @('isequals', 'notequals', 'greaterthan', 'lessthan', 'greaterequals', 'lessequals')) { Update-Log "Invalid operation ($Operator) for $GlobalCondition. No further action taken..." -ForegroundColor 'Red'; return }
            break
        }
        'primarydevice' {
            if ($operator -notin @('isequals')) { Update-Log "Invalid operation ($Operator) for $GlobalCondition. No further action taken..." -ForegroundColor 'Red'; return }
            break
        }
        'device_ownershipdesktop' {
            if ($operator -notin @('isequals', 'notequals')) { Update-Log "Invalid operation ($Operator) for $GlobalCondition. No further action taken..." -ForegroundColor 'Red'; return }
            if ($Value -notin @('company', 'personal')) { Update-Log "Invalid value ($value) for $GlobalCondition. No further action taken..." -ForegroundColor 'Red'; return }
            break
        }
    }
    if ((Get-CMApplication -Name "$ApplicationName") -eq $null) { Update-Log "Application ($ApplicationName) does not exist. No further action taken..." -ForegroundColor 'Red'; return }
    if ((Get-CMDeploymentType -ApplicationName "$ApplicationName" -DeploymentTypeName "$DeploymentTypeName") -eq $null) { Update-Log "DeploymentType ($DeploymentTypeName) for Application ($ApplicationName) does not exist. No further action taken..." -ForegroundColor 'Red'; return }

    ##End Validation

	    switch ($GlobalCondition.Tolower())
	    {
		    'operatingsystem' {
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Other
			    break
		    }

		    'totalphysicalmemory' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    break
		    }

		    'numberofprocessors' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    break
		    }

		    'oslanguage' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64Array
			    break
		    }
		    'cpuspeed' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    break
		    }

		    'machineou' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::StringArray
			    break
		    }

		    'adsite' {
			    $GlobalConditionName = "$($GlobalCondition)_RegSetting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::Registry
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::StringArray
			    break
		    }

		    'sccmsite' {
			    $GlobalConditionName = "$($GlobalCondition)_RegSetting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::Registry
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::StringArray
			    break
		    }

		    'primarydevice' {
			    $GlobalConditionName = "$($GlobalCondition)_Setting_LogicalName"
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Boolean
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Boolean
			    break
		    }

		    'freediskspace' {
			    $GlobalConditionName = 'FreeSpace'
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
			    break
		    }
		    'device_ownershipdesktop' {
			    $GlobalConditionName = 'OwnershipDesktop_Setting_LogicalName'
			    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
			    $ConfigurationItemSettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
			    $pdSettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String
			    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String
			    break
		    }
	    }
	    $ExpressionOperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator
	    $Annotation = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation

	    $Annotation.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList @('DisplayName', "$GlobalCondition $operator $Value", $null)
	    switch ($GlobalCondition.Tolower())
	    {
		    { ($_ -eq 'operatingsystem') } {
			    $Value.Split(';') | foreach { $ExpressionBase.Add($_) }
			    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList @($ExpressionOperator, $ExpressionBase)
			    break
		    }
		    { ($_ -eq 'machineou') -or ($_ -eq 'oslanguage') -or ($_ -eq 'adsite') -or ($_ -eq 'sccmsite') } {
			    $ExpressionBase.Add((new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference -ArgumentList ('GLOBAL', "$GlobalCondition", $pdSettingDataType, "$GlobalConditionName", $ConfigurationItemSettingSourceType)))
			    $ConstantValueList = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValueList -ArgumentList ($pdDataType)
			    $Value.Split(';') | foreach { $ConstantValueList.AddConstantValue($_) }
			    $ExpressionBase.Add($ConstantValueList)
			    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList @($ExpressionOperator, $ExpressionBase)
			    break
		    }
		    { ($_ -eq 'cpuspeed') } {
			    $ExpressionBase.Add((new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference -ArgumentList ('GLOBAL', $GlobalCondition, $pdSettingDataType, "$GlobalConditionName", $ConfigurationItemSettingSourceType)))
			    $value.Split(';') | foreach { $ExpressionBase.Add((New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue -ArgumentList @([int64]$_, $pdDataType))) }
			    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList @($ExpressionOperator, $ExpressionBase)
			    break
		    }
		    default
		    {
			    $ExpressionBase.Add((new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference -ArgumentList ('GLOBAL', "$GlobalCondition", $pdSettingDataType, "$GlobalConditionName", $ConfigurationItemSettingSourceType)))
			    $value.Split(';') | foreach { $ExpressionBase.Add((New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue -ArgumentList @($_, $pdDataType))) }
			    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList @($ExpressionOperator, $ExpressionBase)
			    break
		    }
	    }
	    $newRule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule -ArgumentList @("$($GlobalCondition)Rule_$([Guid]::NewGuid().ToString())", [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $Annotation, $expression)
	    $App = Get-CMApplication -Name "$ApplicationName"
	    $AppXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($app.SDMPackageXML)
	    $i = 0
	    foreach ($dt in $AppXML.deploymenttypes)
	    {
		    if ($dt.Title.ToLower() -ne $DeploymentTypeName.tolower()) { $i++ }
		    else { break }
	    }
	    $AppXML.DeploymentTypes[$i].Requirements.Add($newrule)
	    $app.SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($AppXML)
	    $app.Put() | Out-Null
} #end function Add-CMDeploymentTypeGlobalCondition

Function Create-SCCMGlobalConditionsRule {
    Param(
        $siteServerName,
        $GlobalCondition,
        $Operator = "IsEquals",
        $Value,
        $SettingSourceType
    )

<#
    .SYNOPSIS
        Creates a Global Condition rule of type [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule]. 
        This rule can be added as a requirement for an deployment type
    .DESCRIPTION
        This function will Create a rule for an global condition
    .PARAMETER SiteServerName
        Name of the SCCM Site server to check Global Conditions
    .PARAMETER GlobalCondition
        Name of the global condition you wanted to use
    .PARAMETER Operator
        Operator used to validate the rule. Accepted values are Equals,NotEquals,GreaterThan,LessThan,Between,GreaterEquals,LessEquals,BeginsWith,NotBeginsWith,EndsWith,NotEndsWith,Contains,NotContains,AllOf,OneOf,NoneOf,SetEquals,Existential (Custom),NotExistential (Custom)
    .PARAMETER Value
        Value on which the rule should check. Use MB when data value is needed
    .PARAMETER SettingSourceType
        Default value is CIM if type is of other value please type this value. Possible values:
		Registry, IisMetabase, SqlQuery, WqlQuery, Script, XPathQuery, ADQuery, Complex, SoftwareUpdate, File, 
		Folder, RegistryKey, Assembly, Uri, Expression, CIM, ParameterizedSetting, PlistKey, MSI, MacDetection
    .EXAMPLE
        Create-SCCMGlobalConditionsRule . "TotalPhysicalMemory" "GreaterEquals" 524288000 "CIM"
        Creates a rule where Total Phyiscal memory is greater than or equals to 500 MB
    .EXAMPLE
        Create-SCCMGlobalConditionsRule . "CPU" "GreaterThan" 10000 "CIM"
        Creates a rule where the cpu speed is greater than 1 GHZ
#>

if ($Operator -eq "" -or $Operator -eq $null){
    $Operator = "IsEquals"
}

if($GlobalCondition.ModelName -eq $null){
    $GlobalCondition = Get-SCCMGlobalCondition $GlobalCondition $siteServerName
}

if($GlobalCondition -eq $null){
    Write-Error "Global condition not found"
	return
}

$gcTmp =  $GlobalCondition.ModelName.Split("/")
$gcScope = $gcTmp[0]
$gcLogicalName = $gcTmp[1]
$gcDataType = $GlobalCondition.DataType
$gcExpressionDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::GetDataTypeFromTypeName($gcDataType)

if($operator.ToLower() -eq  "notexistential" -OR $operator.ToLower() -eq  "existential" ){
	$gcExpressionDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
}

#Retrieving logical name of setting 
$settingsxml = [xml] ([wmi] $GlobalCondition.__PATH).SDMPackageXML

if(  $settingsxml.DesiredConfigurationDigest.GlobalSettings.AuthoringScopeId -eq "GLOBAL"){
    $global = $true
    $SettingLogicalName =  "$($gcLogicalName)_Setting_LogicalName"
}
else{
	$SettingLogicalName = $settingsxml.DesiredConfigurationDigest.GlobalSettings.Settings.FirstChild.FirstChild.LogicalName
}

if (!($SettingLogicalName)){
    $SettingLogicalName = $settingsxml.DesiredConfigurationDigest.GlobalExpression.LogicalName
}

if (!($SettingLogicalName)){
    $SettingLogicalName = $settingsxml.DesiredConfigurationDigest.GlobalSettings.LogicalName
    if ($CISettingSourceType -eq 'file'){
        $SettingLogicalName = $SettingLogicalName.replace('GlobalSettings', 'File')
    }
}

#Checking for ConfigurationItemSetting 

if ($SettingSourceType -ne $null -AND $SettingSourceType -ne "")	{
	$CISettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::$SettingSourceType
}
else{
	$CISettingSourceType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingSourceType]::CIM
}

$arg = @(
    $gcScope, 
    $gcLogicalName 
    $gcExpressionDataType, 
    $SettingLogicalName,
    $CISettingSourceType
)

$reqSetting =  new-object  Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.GlobalSettingReference -ArgumentList  $arg

#custom properties Existential

if($operator.ToLower() -eq  "notexistential"){
	$operator = "Equals"
	$Value = 0
	$reqSetting.MethodType = "Count"
}

if($operator.ToLower() -eq  "existential"){
	$operator = "NotEquals"
	$Value = 0
	$reqSetting.MethodType = "Count"
}

$arg = @(
    $value,
    $gcExpressionDataType
)
$reqValue = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue -ArgumentList $arg
$operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]"
$operands.Add($reqSetting) | Out-Null
$operands.Add($reqValue) | Out-Null

#Changing Equals to IsEquals 

if($operator.ToLower() -eq "equals"){$operator = "IsEquals"}

$Expoperator =  Invoke-Expression [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator

if( $GlobalCondition.DataType -eq "OperatingSystem"){
    $operands = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
    foreach( $os in $value){
        $operands.Add($os)
    }
    $arg = @(
        $Expoperator , 
        $operands
    )
    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList $arg
}
else{
    $arg = @( $Expoperator , 
        $operands
    )
    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression -ArgumentList $arg
}
$anno =  new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation 
$annodisplay = "$($GlobalCondition.LocalizedDisplayName) $operator $value"

$arg = @(
    "DisplayName", 
    $annodisplay, 
    $null
)
$anno.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList $arg
$arg = @(
    ("Rule_" + [Guid]::NewGuid().ToString()), 
    [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, 
    $anno, 
    $expression
)
$rule = new-object "Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule" -ArgumentList $arg
return $rule
}

Function New-EDMSettingForDeploymentType {
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("RegistryKey","File","MSI")]
        $DetectionType,
        [Parameter(Mandatory=$False,ParameterSetName="FileDetection")][ValidateNotNullOrEmpty()][String]$FileName,
        [Parameter(Mandatory=$False,ParameterSetName="FileDetection")][ValidateNotNullOrEmpty()][String]$FolderPath,
        [Parameter(Mandatory=$False,ParameterSetName="FileDetection")]$Is64bit,
        [ValidateSet("And,","Or","IsEquals","NotEquals","GreaterThan","Between","GreaterEquals","LessEquals","BeginsWith","NotBeginsWith","EndsWith","NotEndsWith","Contains","NotContains","AllOf","OneOf","NoneOf","SetEquals","SupportedOperators")]
        #[Parameter(Mandatory=$False,ParameterSetName="FileDetection")]
        #[Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        $Operator,
        [Parameter(Mandatory=$false)]
        [ValidateSet("None","Informational","Warning","Critical","CriticalWithEvent")]
        $NoncomplianceSeverity = "None",
        $ApplicationName,
        $DeploymentTypeName,
        $siteCode,
        $version,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        [ValidateSet("HKEY_LOCAL_MACHINE","HKEY_USERS","HKEY_CLASSES_ROOT","HKEY_CURRENT_CONFIG","HKEY_CURRENT_USER")]
        [ValidateNotNullOrEmpty()][String]$RegistryHyve,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")][ValidateNotNullOrEmpty()][String]$RegistryKey,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")][String]$RegistryKeyValue,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")][string]$RegistryKeyValueDataType = "String",
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        [Parameter(Mandatory=$false)][switch]$CheckForConstant,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        $ConstantValue= $true,
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        $ConstantDataType = 'String',
        [Parameter(Mandatory=$False,ParameterSetName="RegistryDetection")]
        $DcmObjectModelPath = "$($env:SMS_ADMIN_UI_PATH | split-path -parent)\DcmObjectModel.dll",
        [Parameter(Mandatory=$true, HelpMessage="SCCM Server")][Alias("Server","SmsServer")][System.Object] $SccmServer
    )
    $application1 = [wmi](Get-WmiObject -Query "select * from sms_application where LocalizedDisplayName='$ApplicationName' AND ISLatest='true'" -ComputerName $sccmserver -Namespace "root\sms\site_$SiteCode").__PATH
    #Deserialize the SDMPackageXML
    $App1Deserializedstuff = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($application1.SDMPackageXML)
    $Is64bit = $true  
    #$oEnhancedDetection = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod

    switch ($DetectionType){
        "MSI"{
            #$oEnhancedDetection = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
            $ProductCode = $version
            $msiSetting = New-Object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.MSISettingInstance($ProductCode, $null)

            #$oEnhancedDetection.Settings.Add($msiSetting)

            $setting = $msiSetting
            $msiDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Int64
            $msiConstValue = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue('0', $msiDataType)
            $msiSettingRef = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.SettingReference(
                $App1Deserializedstuff.Scope,
                $App1Deserializedstuff.Name,
                $App1Deserializedstuff.Version,
                $msiSetting.LogicalName,
                $msiDataType,
            	$msiSetting.SourceType,
           	    [bool]0
            )
            $msiSettingRef.MethodType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingMethodType]::Count
            $msiOperands = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]
            $msiOperands.Add($msiSettingRef);
            $msiOperands.Add($msiConstValue);
            $msiExpression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression(
                [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::NotEquals, $msiOperands
            )
            $expression =  $msiExpression
        }
        "File" {
            #$oEnhancedDetection = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod

            $oDetectionType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemPartType]::File
            $oFileSetting = New-Object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.FileOrFolder( $oDetectionType , $null)
            $oFileSetting.FileOrFolderName = $FileName
            $oFileSetting.Path =  $FolderPath
            if ($Is64bit){$Is64bits= 1}else{$Is64bits = 0}
            $oFileSetting.Is64Bit = $Is64bits#$Is64bits
            $oFileSetting.SettingDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Version

            #$oFileSetting.ChangeLogicalName()

            #$oEnhancedDetection.Settings.Add($oFileSetting)

            $setting = $oFileSetting

            #$oFileSetting

            $oSettingRef = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.SettingReference(
                $App1Deserializedstuff.Scope,
                $App1Deserializedstuff.Name,
                $App1Deserializedstuff.Version,
                $oFileSetting.LogicalName,
                $oFileSetting.SettingDataType,
                $oFileSetting.SourceType,
                [bool]0
            )

            # setting bool 0 as false
            $oSettingRef.MethodType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingMethodType]::Value
            $oSettingRef.PropertyPath = "Version"
            $oConstValue = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue( $version, 
            [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Version)
            $oFileCheckOperands = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]
            $oFileCheckOperands.Add($oSettingRef)
            $oFileCheckOperands.Add($oConstValue)

            $FileCheckExpression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression(
            [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$Operator, $oFileCheckOperands)
            $expression =  $FileCheckExpression
        }
        "RegistryKey"{
$sourceFix = @"
using Microsoft.ConfigurationManagement.DesiredConfigurationManagement;

using System;

namespace RegistrySettingNamespace
{
	public class RegistrySettingFix
	{
		private RegistrySetting _registrysetting;
		public RegistrySettingFix(string str)
		{
			this._registrysetting = new RegistrySetting(null);
		}
		public RegistrySetting GetRegistrySetting()
		{
			return this._registrysetting;
		}
	}
}
"@
            #Hack to bypass bug in Microsoft.ConfigurationManagement.DesiredConfigurationManagement.registrySetting which doesn't allow us to create a enhanced detection method.
            Add-Type -ReferencedAssemblies $DcmObjectModelPath -TypeDefinition $sourceFix -Language CSharp
            $temp = New-Object RegistrySettingNamespace.RegistrySettingFix ""
            $oRegistrySetting = $temp.GetRegistrySetting()
            #$oEnhancedDetection = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod

            $oDetectionType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemPartType]::RegistryKey

            if ($oRegistrySetting -ne $null) {} else {Throw " oRegistrySetting object Creation failed"}
                switch ($RegistryHyve){
                    "HKEY_CLASSES_ROOT"{
                        $oRegistrySetting.RootKey = "ClassesRoot"
                        Break
                    }
                    "HKEY_CURRENT_CONFIG"{
                        $oRegistrySetting.RootKey = "CurrentConfig"
                        Break
                    }
                    "HKEY_CURRENT_USER"{
                        $oRegistrySetting.RootKey = "CurrentUser"
                        Break
                    }
                    "HKEY_LOCAL_MACHINE"{
                        $oRegistrySetting.RootKey = "LocalMachine"
                        Break
                    }
                    "HKEY_USERS"{
                        $oRegistrySetting.RootKey = "Users"
                        Break
                    }
                }
                $oregistrysetting.Key = $RegistryKey
                $oRegistrySetting.ValueName = $RegistryKeyValue
                if ($Is64bit){$Is64bits= 1}else{$Is64bits = 0}
                $oRegistrySetting.Is64Bit          = $Is64bits#$Is64bits
                $oRegistrySetting.SettingDataType  = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::String#$RegistryKeyValueDataType
                #$oRegistrySetting.ChangeLogicalName()
                #$oEnhancedDetection.Settings.Add($oRegistrySetting)
                $setting = $oRegistrySetting
                #$oFileSetting
                $oSettingRef = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.SettingReference(
                    $App1Deserializedstuff.Scope,
                    $App1Deserializedstuff.Name,
                    $oApplicApp1Deserializedstuffation.Version,
                    $oRegistrySetting.LogicalName,
                    $oRegistrySetting.SettingDataType,
                    $oRegistrySetting.SourceType,
                [bool]0 )
                # setting bool 0 as false

            #Registry Setting must satisfy the following rule
            $oSettingRef.MethodType = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ConfigurationItemSettingMethodType]::Value
            #this is needed if you are only checking to see if the registry value exists
            #$oSettingRef.PropertyPath = "RegistryValueExists"
            #$oSettingRef
            <#
                if (!($CheckForConstant)){
                    $ConstantValue = $true
                    $ConstantDataType = "boolean"
                }
            #>
            $oConstValue = New-Object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ConstantValue($ConstantValue, 
            [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::$ConstantDataType)
            $oRegistrySettingOperands = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]
            $oRegistrySettingOperands.Add($oSettingRef)
            $oRegistrySettingOperands.Add($oConstValue)
            #$Operator = "IsEquals"
            $RegistryCheckExpression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression(
            [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$Operator, $oRegistrySettingOperands)
            $expression =  $RegistryCheckExpression
        }
        #Expression, Annotation,  Severity and an empty
        Default {Throw "DetectionType $($DetectionType) not recognized as a valid detection type"}
    } #End Switch 
    $returnobject = @()
    $returnobject += $expression
    $returnobject += $setting
    return $returnobject
}

Function Load-ConfigMgrAssemblies {
 Param(
    $AdminConsoleDirectory = ($env:SMS_ADMIN_UI_PATH | Split-Path -Parent)
 )

     $filesToLoad = "Microsoft.ConfigurationManagement.ApplicationManagement.dll","AdminUI.WqlQueryEngine.dll", "AdminUI.DcmObjectWrapper.dll","DcmObjectModel.dll","AdminUI.AppManFoundation.dll","AdminUI.WqlQueryEngine.dll","Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll","Microsoft.ConfigurationManagement.ManagementProvider.dll","Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll"
     Set-Location $AdminConsoleDirectory
     [System.IO.Directory]::SetCurrentDirectory($AdminConsoleDirectory)

      foreach($fileName in $filesToLoad){
         $fullAssemblyName = [System.IO.Path]::Combine($AdminConsoleDirectory, $fileName)

         if([System.IO.File]::Exists($fullAssemblyName )){
             $FileLoaded = [Reflection.Assembly]::LoadFrom($fullAssemblyName )
         }
         else{
              Write-Host ([System.String]::Format("File not found {0}",$fileName )) -backgroundcolor "red"
         }
      }
 }

Function Add-DetectionMethod{
    param(
        [string]$ApplicationName,
        $DT,
        $sccmserver,
        $sitecode

    )
        $application1 = [wmi](Get-WmiObject -Query "select * from sms_application where LocalizedDisplayName='$ApplicationName' AND ISLatest='true'" -ComputerName $sccmserver -Namespace "root\sms\site_$SiteCode").__PATH

    #Deserialize the SDMPackageXML
    $App1Deserializedstuff = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($application1.SDMPackageXML)
    $oEnhancedDetection = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.EnhancedDetectionMethod
    $expressionlist = @()

    foreach ($DM in $DT.DetectionMethods){

        if (!($dm.type)){
            if ($dm.dmpath -eq 'Windows Installer'){
                $detectiontype = 'MSI'
            }
            elseif ($DM.DMPath.split(':')[0].length -gt 1){
                $DetectionType = 'RegistryKey'
            }
            else{
                $DetectionType = 'file'
            }
        }
        else{
            if ($dm.type -eq 'registry'){
                $detectiontype = 'RegistryKey'
            }
            else{
                $DetectionType = $dm.type
            }
        }

        If ($DetectionType -eq 'RegistryKey'){
                $Hive = $DM.DMPath.Split(':')[0]
                switch ($hive)

                {
                    'HKLM' {$hive = "HKEY_LOCAL_MACHINE"}
                    'HKU'  {$hive = "HKEY_USERS"}
                    'HKCR' {$hive = "HKEY_CLASSES_ROOT"}
                    'HKCC' {$hive = "HKEY_CURRENT_CONFIG"}
                    'HKCU' {$hive = "HKEY_CURRENT_USER"}
                    Default {throw "Unable to identify registry hive"}
                }
                $DM.DMPath = (($DM.DMPath.Split(':')[1]).TrimStart('\')).TrimEnd('\')
        }

	    If ($DetectionType -eq 'file'){
			    $params = @{
				    Sitecode = $SiteCode
				    ApplicationName = $ApplicationName
                    DeploymentTypeName = $DeploymentTypeName
				    DetectionType = $detectiontype
				    Filename = $DM.DMItem
				    FolderPath = $DM.DMPath
				    version = $DM.DMExpectedValue
				    Operator = $DM.DMOperator
				    SCCMServer = $primary
			    }

                $resultlist = New-EDMSettingForDeploymentType @params
                $expressionlist += $resultlist[0]
                $oEnhancedDetection.Settings.Add($resultlist[1])
	    }

	    If ($DetectionType -eq 'MSI'){

			    $params = @{
				    Sitecode = $SiteCode
				    ApplicationName = $ApplicationName
                    DeploymentTypeName = $DeploymentTypeName
				    DetectionType = $detectiontype
				    Filename = "ProductCode"
				    FolderPath = "Windows Installer"
				    version = $DM.DMExpectedValue
				    Operator = $DM.DMOperator
				    SCCMServer = $primary
			    }
                $resultlist = New-EDMSettingForDeploymentType @params
                $expressionlist += $resultlist[0]
                $oEnhancedDetection.Settings.Add($resultlist[1])
	    }

	    If ($DetectionType -eq 'RegistryKey'){

			    $params = @{
				    Sitecode = $SiteCode
				    ApplicationName = $ApplicationName
                    DeploymentTypeName = $DeploymentTypeName
				    DetectionType = $DetectionType
				    Operator = $DM.DMOperator
				    SCCMServer = $primary
				    RegistryHyve = $hive
				    RegistryKey = $dm.dmpath
				    RegistryKeyValue = $DM.DMItem
                    ConstantValue = $DM.DMExpectedValue
			    }
			    $resultlist = New-EDMSettingForDeploymentType @params
                $expressionlist += $resultlist[0]
                $oEnhancedDetection.Settings.Add($resultlist[1])
	    }
    }
    If ($expressionlist.count -eq 1){
        $Rule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule("IsInstalledRule", 
            [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $null, $expressionlist[0])
        if ($Rule  -ne $null) {} else {throw "rule object Creation failed for a single detection method"}
    }
    else{
        $rootOperands = new-object Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.ExpressionBase]]
        foreach ($expression in $expressionlist){
            $rootOperands.add($expression)
        }
        $rootExp = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.Expression(
        [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::Or, $rootOperands)
        $Rule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule("IsInstalledRule", 
        [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $null, $rootExp)
            if ($Rule  -ne $null) {} else {throw "rule object Creation failed for multiple detection methods"}
    }
    $oEnhancedDetection.Rule = $Rule
    $i = 0
    foreach ($DT in $App1Deserializedstuff.DeploymentTypes){
        if ($DT.Title -eq $DeploymentTypeName){
            Update-Log "Adding Enhanced detection type to application $($ApplicationName) and deploymentType $($DeploymentTypeName)"
            $App1Deserializedstuff.DeploymentTypes[$i].Installer.DetectionMethod = [Microsoft.ConfigurationManagement.ApplicationManagement.DetectionMethod]::Enhanced
            $App1Deserializedstuff.DeploymentTypes[$i].Installer.EnhancedDetectionMethod = $oEnhancedDetection
            continue
        }else{

            $i++
        }
    }
    $connection = New-Object Microsoft.ConfigurationManagement.ManagementProvider.WqlQueryEngine.WqlConnectionManager
    [void]$connection.Connect($sccmserver)
    # initialise management scope.
    $factory = New-Object Microsoft.ConfigurationManagement.AdminConsole.AppManFoundation.ApplicationFactory
    $wrapper = [Microsoft.ConfigurationManagement.AdminConsole.AppManFoundation.AppManWrapper]::Create($connection, $factory)
	$wrapper.InnerAppManObject = $App1Deserializedstuff
	$factory.PrepareResultObject($wrapper)
	$wrapper.InnerResultObject.Put() | Out-Null
    Remove-Variable oEnhancedDetection
}

function countme{}

$ErrorActionPreference = 'Stop'
$ActivityStatus = "Success"
$ActivityName = "Create Deployment Types with Advanced or Customized Scenarios"

# Add startup details to trace log

Update-Log "Running as user [$([Environment]::UserDomainName)\$([Environment]::UserName)] on host [$($env:COMPUTERNAME)]"
Update-Log "Activity Started: $ActivityName"
Update-Log "ApplicationName = $ApplicationName"
$sccmserver = $Primary

Load-ConfigMgrAssemblies

#Create the deployment types
$DTs = $DeploymentTypes[0].value
foreach ($DT in $DTs){
    $contentpath = "$DSL\$ApplicationName\$($Dt.ContentPath)"
    $DeploymentTypeName = "$ApplicationName - $($DT.DTName)"
    $reboot = $dt.reboot

    if ($reboot){
        switch ($reboot)
        {
            'None'  {$reboot = 'NoAction'}
            'Force' {$reboot = 'ForceReboot'}
            'Allow' {$reboot = 'ProgramReboot'}
            default {$reboot = 'NoAction'}
        }
    }
    else{
        $reboot = 'NoAction'
    }
    if ($dt.runtime){
        $runtime = $dt.runtime
    }
    else{
        $runtime = 15
    }

    #create the deployment type

    Connect-SCCM -SiteCode $SiteCode

    If ($InstallationType -eq 'MSI'){
        Set-Location c:
        $InstallationLocation = get-childitem $contentpath -Include "*.msi" -Recurse | select -First 1 | select -ExpandProperty fullname
        Set-Location "$($sitecode):"
        Add-CMDeploymentType -applicationname $ApplicationName -DeploymentTypeName $DeploymentTypeName -InstallationFileLocation $InstallationLocation -ForceForUnknownPublisher $true -InstallationBehaviorType InstallForSystem -MsiInstaller | out-null
        Set-CMDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $DeploymentTypeName -MsiOrScriptInstaller -InstallationProgram $dt.InstallString -UninstallProgram $dt.UnInstallString -AllowClientsToShareContentOnSameSubnet $false -OnSlowNetworkMode Download -RebootBehavior $reboot -EstimatedInstallationTimeMinutes $runtime -MaximumAllowedRunTimeMinutes $runtime -InstallationBehaviorType InstallForSystem -InstallationProgramVisibility Hidden | Out-Null  
    }

    Else{
        $DPTypeProps = @{
            ScriptInstaller = $true
            ApplicationName = $ApplicationName
            DeploymentTypeName = $DeploymentTypeName
            InstallationProgram = $DT.InstallString
            UninstallProgram = $DT.UninstallString
            ScriptType = 'PowerShell'
            ScriptContent = 'Return $true'
            AllowClientsToShareContentOnSameSubnet = $false
            OnSlowNetworkMode = 'Download'
            EstimatedInstallationTimeMinutes = $runtime
            MaximumAllowedRunTimeMinutes = $runtime
            InstallationBehaviorType = 'InstallForSystem'
            InstallationProgramVisibility = 'Hidden'
            ContentLocation = $contentpath
            LogonRequirementType = 'WhetherOrNotUserLoggedOn'
        }

        Set-Location "$($sitecode):"
        Add-CMDeploymentType @DPTypeProps | Out-Null
        Set-CMDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $DeploymentTypeName -RebootBehavior $reboot -MsiOrScriptInstaller | out-null
    }

    #add Global Conditions

    if ($DT.GlobalConditions){
        #The Deployment Type must exist
        foreach ($GC in $DT.Globalconditions){
            try{
                Set-Location "$($SiteCode):"
                $rule = Create-SCCMGlobalConditionsRule -GlobalCondition $GC.GCName -Operator $GC.GCOperator -Value $GC.GCExpectedValue -siteServerName $Primary -SettingSourceType 'wqlquery'
                Set-CMDeploymentType -ApplicationName $applicationname -DeploymentTypeName $DeploymentTypeName -AddRequirement $rule | Out-Null
            }
            catch{
                $ErrorMessage = $Error[0] | out-string
                Throw $error[0] | Out-String
            }
        }
    }

    if ($Dt.OSVersions){

        $DPGlobal = @{
            ApplicationName = $ApplicationName
            DeploymentTypeName = $DeploymentTypeName
            sdkserver = $Primary
            sitecode = $SiteCode
        }
        Update-Log "Adding global conditions to $DeploymentTypeName"
        Add-CMDeploymentTypeGlobalCondition @DPGlobal -GlobalCondition OperatingSystem -Operator OneOf -Value $DT.OSVersions | Out-Null
    }
    if ($DT.DetectionMethods){       
        $oEnhancedDetection = Add-DetectionMethod -ApplicationName $applicationname -DT $dt -sccmserver $sccmserver -sitecode $sitecode
    } #end if DetectionMethods
}
    Update-log "Finished Activity: $ActivityName"
$varlist = 'contentpath','DeploymentTypeName','DetectionType','InstallationLocation','params','reboot','rule','runtime','sccmserver','DTs','DPGlobal','DT','GC'
remove-variable $varlist -Force -ErrorAction SilentlyContinue
remove-variable varlist
if ($ErrorMessage){
    update-log $ErrorMessage
}