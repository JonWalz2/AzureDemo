$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}
function Get-CMApplication{}
function Set-PMGVariable{}


Describe 'Validate-Content'{
    mock Connect-SCCM
    mock set-location
    mock update-log
    mock Get-CMApplication
    mock Set-PMGVariable
    mock Get-WmiObject
    mock Remove-Variable
    it "If the JSONObject does not contain a PackageID it should be pulled from SCCM"{
        $packageID = $null
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        Assert-MockCalled Get-CMApplication -Exactly 1 -Scope It
    }
    it "If the JSONObject has a packageID Get-CMApplication should NOT be called"{
        $packageID = 'QA101BA4'
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        Assert-MockCalled Get-CMApplication -Exactly 0 -Scope It
    }
    it "If `$StatusInfo = `$null `$ResultStatus should be set to 'Success'"{
        $packageID = 'QA101BA4'
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        $ResultStatus | Should be 'Success'
    }
    it "If `$StatusInfo returns a state of 3 `$ResultStatus should be set to 'failed'"{
        $packageID = 'QA101BA4'
        mock Get-WmiObject {
            [PSCustomObject]@{state = 3}
        }
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        $ResultStatus | Should be 'failed'
    }
    It "If an error is generated, `$ActivityStatus should be 'Failed'"{
        $packageID = 'QA101BA4'
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        $ActivityStatus | should -Match 'Failed'
    }
    It "If an error is generated, `$ErrorMessage should contain the error"{
        $packageID = 'QA101BA4'
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -CMsitecode 'QA1' -CMServerName 'server'
        $Errormessage | should -Match 'an error'
    }
}