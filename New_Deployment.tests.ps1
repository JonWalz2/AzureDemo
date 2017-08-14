$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}
function Start-CMApplicationDeployment{}

function Get-CMDeployment{}


Describe 'New_Deployment.ps1'{
    mock Connect-SCCM
    mock Set-Location
    mock Start-CMApplicationDeployment
    mock Get-CMDeployment

    mock Remove-Variable
    it "If a collection is not provided it should default to 'Application Testing - Workstations'"{
        . "$here\$sut" -sitecode 'QA1' -primary 'server' -ApplicationName 'Fake App'
        $CollectionName | should be 'Application Testing - Workstations'
    }
    It "Deploypurpose should be set to 'Available'"{
        . "$here\$sut" -sitecode 'QA1' -primary 'server' -ApplicationName 'Fake App'
        $props.DeployPurpose | should be 'Available'
    }
    It "They deployment should be based on local time"{
        . "$here\$sut" -sitecode 'QA1' -primary 'server' -ApplicationName 'Fake App'
        $props.TimeBaseOn | Should be 'localtime'
    }
    It "The available time for the deployment should be in the future"{
        . "$here\$sut" -sitecode 'QA1' -primary 'server' -ApplicationName 'Fake App'
        $props.availabledatetime | should begreaterthan (get-date)
    }
    It "The Deployment should be created"{
    . "$here\$sut" -sitecode 'QA1' -primary 'server'
    Assert-MockCalled Start-CMApplicationDeployment -Exactly 1 -Scope it
    }
    It "`$AssignmentID should be populated"{
        Mock Get-CMDeployment -MockWith {[psobject]@{'AssignmentID' = '12345'}}
        . "$here\$sut" -sitecode 'QA1' -primary 'server'
        $assignmentID | should be '12345'
    }
    It "If an error is generated, `$ActivityStatus should be 'Failed'"{
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -sitecode 'QA1' -primary 'server'
        $ActivityStatus | should -Match 'Failed'
    }

    It "If an error is generated, `$ErrorMessage should contain the error"{
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -sitecode 'QA1' -primary 'server'
        $Errormessage | should -Match 'an error'
    }
}