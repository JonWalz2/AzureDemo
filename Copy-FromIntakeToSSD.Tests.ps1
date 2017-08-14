$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

#Import-Module "C:\Program Files\PMG Service Catalog\WorkflowRemoteAgent\PMG.PSVariables.dll" -Force

Function Get-PMGVariable {}
Function Set-PMGVariable {}

$Test_Inputs = @{
    Sourcepath = '\\wn035b\PMG\Intake_DEV\VISUAL STUDIO CODE'
    ApplicatonName = 'Microsoft Visual Studio Code 1.4.0'
}

Describe 'Test of Copy-FromIntakeToSSD'{
    Mock test-path {$true}
    mock Copy-Item -Verifiable
    mock Move-Item -Verifiable
    mock Remove-Item -Verifiable
    mock Get-PMGVariable {$sourcepath} -Verifiable
    mock Set-PMGVariable
    mock Post-JsonObjAPI
    mock Remove-Variable
    mock Get-JsonObjAPI {
    $json = @'
{
    "Source":  "SLSPLAN",
    "CollectionName":  "",
    "Version":  "3.1.0.5",
    "LocalizedName":  "Fake App Pattern E",
    "ActivityName" : "Activity",
    "ActivityStatus"  : "Success",
    "RunbookName" : "Name of runbook",
    "Trace" : "some trace data",
    "ErrorMessage" : ""
}
'@
    $json | ConvertFrom-Json
        }
    New-Item -ItemType File -Path TestDrive:\fakefile1.txt
    New-Item -ItemType File -Path TestDrive:\fakefile2.txt
    it "test files should exist"{
        (Get-ChildItem TestDrive:).count | Should be 2
    }

#    Context "Test of Inputs"{
#
#    }
    mock new-item
    Context "Test of Actions"{
        Mock test-path {$true}
        It "Source paths that end in 'Intake' should result in `$destination containing the SSDIntake folder"{
            $sourcepath = "\\at1a3\vol4\DEPTS\ISPROG\Retail Systems Packaging\RSP_Inbox\Automated_Intake\Fake App Pattern E\file.json"
            . "$here\$sut" -Sourcepath $sourcepath
            $destination | should be '\\ssd\SSD\intake'
        }
        It "Source paths that end in 'TEST' should result in `$destination containing the SSD-TEST Intake folder"{
            $sourcepath = "\\at1a3\vol4\DEPTS\ISPROG\Retail Systems Packaging\RSP_Inbox\Automated_Intake_TEST\Fake App Pattern E\file.json"
            . "$here\$sut" -Sourcepath $sourcepath
            $destination | should be '\\ssd-test\SSD-Test\intake'
        }
        It "Source paths that end in 'DEV' should result in `$destination containing the SSD-DEV Intake folder"{
            $sourcepath = "\\wn1341\PMG\SSD-Dev\Intake_dev\VISUAL STUDIO CODE\file.json"
            . "$here\$sut" -Sourcepath $sourcepath
            $destination | should be '\\ssd-dev\ssd-dev\intake'
        }
        It "If the folder already exists in the destination it should be removed"{
            Assert-MockCalled test-path -Times 1
        }
        It "Copy-Item should run twice"{
            Assert-MockCalled Copy-Item -Times 2
        }
        It "If the folder already exists in the processed folder it should be removed"{
            Assert-MockCalled Remove-Item -Times 2
        }
        It "The source foder should be moved to the processed folder"{
            Assert-MockCalled Move-Item -Times 1
        }
    }
    Context "Test of Outputs"{
        Mock Post-JsonObjAPI
        It "An error should cause the `$errormessage variable to be populated with the contents of the error"{
            Mock Copy-Item {write-error "special error"}
            $sourcepath = "\\at1a3\vol4\DEPTS\ISPROG\Retail Systems Packaging\RSP_Inbox\Automated_Intake_DEV"
            . "$here\$sut"
            $errormessage | should belike "*special error*"
        }
    }

}

