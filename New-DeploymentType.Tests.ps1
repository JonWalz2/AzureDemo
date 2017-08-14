$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}
function Add-CMDeploymentType{}
function Set-CMDeploymentType{}
function Connect-SCCM{}
function Get-SCCMGlobalCondition{}
function Add-CMDeploymentTypeGlobalCondition{}
function Create-SCCMGlobalConditionsRule{}
function New-EDMSettingForDeploymentType{}
function Load-ConfigMgrAssemblies{}
function Add-DetectionMethod{}

Describe 'Test of New-DeploymentType'{
    mock get-childitem
    mock set-location
$DTFake = @'
{
    "value":  [
                  {
                      "DTName":  "QA Workstation US -x86",
                      "ContentPath":  "x86\\ENUS",
                      "InstallString":  "Msiexec /I \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R THD_DEVICE=Workstation THD_LIFECYCLE=QA /l
*v \"%temp%\\FakeAppPatternC.log\"",
                      "UnInstallString":  "msiexec /X \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R /l*v %temp%\\FakeAppPatternC-uninstall.l
og\"",
                      "OSVersions":  "Windows/All_x86_Windows_7_Client;Windows/All_x86_Windows_8_Client;Windows/All_x86_Windows_8.1_Client;Windows
/All_x86_Windows_10_and_higher_Clients",
                      "Reboot":  "None",
                      "Runtime":  "25",
                      "GlobalConditions":  [
                                               {
                                                   "GCName":  "Computer Domain",
                                                   "GCOperator":  "Contains",
                                                   "GCExpectedValue":  "qahomedepot"
                                               },
                                               {
                                                   "GCName":  "THD Locale",
                                                   "GCOperator":  "IsEquals",
                                                   "GCExpectedValue":  "en-US"
                                               }
                                           ],
                      "DetectionMethods":  [
                                               {
                                                   "DMPath":  "Software\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "FileVersion",
                                                   "DMExpectedValue":  "1.2.3",
                                                   "DMOperator":  "GreaterThan"
                                               },
                                               {
                                                   "DMPath":  "Software\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "Good String QA Workstation",
                                                   "DMExpectedValue":  "3.2.1",
                                                   "DMOperator":  "IsEquals"
                                               }
                                           ]
                  },
                  {
                      "DTName":  "PROD Workstation US Chrome -x86",
                      "ContentPath":  "x86\\ENUS",
                      "InstallString":  "Msiexec /I \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R THD_DEVICE=Workstation THD_LIFECYCLE=PROD 
/l*v \"%temp%\\FakeAppPatternC.log\"",
                      "UnInstallString":  "msiexec /X \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R /l*v %temp%\\FakeAppPatternC-uninstall.l
og\"",
                      "OSVersions":  "Windows/All_x86_Windows_7_Client;Windows/All_x86_Windows_8_Client;Windows/All_x86_Windows_8.1_Client;Windows
/All_x86_Windows_10_and_higher_Clients",
                      "Reboot":  "Force",
                      "Runtime":  "35",
                      "GlobalConditions":  [
                                               {
                                                   "GCName":  "Browser Evaluation",
                                                   "GCOperator":  "IsEquals",
                                                   "GCExpectedValue":  "True"
                                               },
                                               {
                                                   "GCName":  "THD Locale",
                                                   "GCOperator":  "IsEquals",
                                                   "GCExpectedValue":  "en-US"
                                               },
                                               {
                                                   "GCName":  "Installed Application - Google Chrome",
                                                   "GCOperator":  "GreaterThan",
                                                   "GCExpectedValue":  "50"
                                               }
                                           ],
                      "DetectionMethods":  [
                                               {
                                                   "DMPath":  "Software\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "MyString",
                                                   "DMExpectedValue":  "PROD",
                                                   "DMOperator":  "Contains"
                                               },
                                               {
                                                   "DMPath":  "c:\\Program Files\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "notepad.exe",
                                                   "DMExpectedValue":  "6.3",
                                                   "DMOperator":  "GreaterThan"
                                               }
                                           ]
                  },
                  {
                      "DTName":  "All Other XXCA -x86/x64",
                      "ContentPath":  "x86\\XXCA",
                      "InstallString":  "Msiexec /I \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R THD_DEVICE=Other /l*v \"%temp%\\FakeAppPat
ternC.log\"",
                      "UnInstallString":  "msiexec /X \"Fake App Pattern C 3.0.16167.4.msi\" /qn REBOOT=R /l*v %temp%\\FakeAppPatternC-uninstall.l
og\"",
                      "OSVersions":  "Windows/All_x64_Windows_7_Client;Windows/All_x86_Windows_7_Client;Windows/All_x64_Windows_8_Client;Windows/A
ll_x86_Windows_8_Client;Windows/All_x64_Windows_8.1_Client;Windows/All_x86_Windows_8.1_Client;Windows/All_x64_Windows_10_and_higher_Clients;Window
s/All_x86_Windows_10_and_higher_Clients;Windows/All_x64_Windows_Server_2016",
                      "Reboot":  "Allow",
                      "Runtime":  "45",
                      "GlobalConditions":  [
                                               {
                                                   "GCName":  "THD Locale",
                                                   "GCOperator":  "Contains",
                                                   "GCExpectedValue":  "CA"
                                               }
                                           ],
                      "DetectionMethods":  [
                                               {
                                                   "DMPath":  "Windows Installer",
                                                   "DMItem":  "ProductCode",
                                                   "DMExpectedValue":  "{35371C9F-A363-4550-B1B8-00187F4A77A3}",
                                                   "DMOperator":  "IsEquals"
                                               },
                                               {
                                                   "DMPath":  "Software\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "MyString",
                                                   "DMExpectedValue":  "Good String QA Workstation",
                                                   "DMOperator":  "IsEquals"
                                               },
                                               {
                                                   "DMPath":  "c:\\Program Files\\The Home Depot\\Fake App Pattern C",
                                                   "DMItem":  "notepad.exe",
                                                   "DMExpectedValue":  "6.3.9600.17930",
                                                   "DMOperator":  "IsEquals"
                                               }
                                           ]
                  }
              ],
    "Count":  3
}
'@

$DeploymentTypes = $DTFake  | ConvertFrom-Json
    mock Get-PMGVariable{}
    mock Add-CMDeploymentType{}
    mock Set-CMDeploymentType{}
    mock Connect-SCCM{}
    mock Get-SCCMGlobalCondition{}
    mock Add-CMDeploymentTypeGlobalCondition{}
    mock Create-SCCMGlobalConditionsRule{}
    mock New-EDMSettingForDeploymentType{}
    mock Load-ConfigMgrAssemblies{}
    mock Get-WmiObject{}
    mock Add-DetectionMethod{}
    mock Remove-Variable

    it "If `$InstallationType is MSI it should create a deploymenttype" {
        $InstallationType = 'MSI'
        mock Get-WmiObject
        . "$here\$sut"
        Assert-MockCalled Add-CMDeploymentType -Exactly 3 -Scope it
    }
    it "If runtime is specified `$runtime should be set to it's value" {
        . "$here\$sut"
        $runtime | should -Match 45
    }
    it "If runtime is not specified `$runtime should be set to 15" {
        $DeploymentTypes.value[2].Runtime = $null
        . "$here\$sut"
        $runtime | should -Match 15
    } 
    it "If reboot is set to 'Allow' `$reboot should be set to 'ProgramReboot'" {
        . "$here\$sut"
        $reboot | should -Match 'ProgramReboot'
    }
    it "If reboot is set to 'None' `$reboot should be set to 'NoAction'" {
        $DeploymentTypes.value[2].Reboot = 'None'
        . "$here\$sut"
        $reboot | should -Match 'NoAction'
    }
    it "If reboot is set to 'Force' `$reboot should be set to 'ForceReboot'" {
        $DeploymentTypes.value[2].Reboot = 'Force'
        . "$here\$sut"
        $reboot | should -Match 'ForceReboot'
    }
    it "If reboot is set to 'something else' `$reboot should be set to 'NoAction'" {
        $DeploymentTypes.value[2].Reboot = 'something else'
        . "$here\$sut"
        $reboot | should -Match 'NoAction'
    }
    it "If reboot is not set `$reboot should be set to 'NoAction'" {
        $DeploymentTypes.value[2].Reboot = $null
        . "$here\$sut"
        $reboot | should -Match 'NoAction'
    }
    it "If Global Conditions are specified for a DT Create-SCCMGlobalConditionsRule should be called for each of them" {
        $DeploymentTypes.value[2] = $null
        . "$here\$sut"
        Assert-MockCalled Create-SCCMGlobalConditionsRule -Exactly 5 -Scope It
    }
    $DeploymentTypes = $DTFake  | ConvertFrom-Json
    it "If OSVersions are specified for a DT Add-CMDeploymentTypeGlobalCondition should be called" {
        . "$here\$sut"
        Assert-MockCalled Add-CMDeploymentTypeGlobalCondition -Exactly 3 -Scope It
    }
    it "If Detection Methods are specified for a DT Add-DetectionMethod should be called" {
        . "$here\$sut"
        Assert-MockCalled Add-CMDeploymentTypeGlobalCondition -Exactly 3 -Scope It
    }

}

