$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}
function Get-CMApplication{}
function Get-CMDistributionPointGroup{}
function Start-CMContentDistribution{}
$DPGroups = @()
$dpgroups += [PSCustomObject]@{name = "Logistic & Divisional - Distribution Points"}
$dpgroups += [PSCustomObject]@{name = "AUS - Distribution Points"}
$dpgroups += [PSCustomObject]@{name = "ATL - Distribution Points"}
$dpgroups += [PSCustomObject]@{name = "Store - Distribution Points"}

Describe 'Test of New_Content_Distribution'{
    mock Connect-SCCM
    mock set-location
    mock update-log
    mock Get-CMDistributionPointGroup {$dpgroups}
    mock Get-CMApplication
    mock Start-CMContentDistribution
    mock remove-variable
    it "If the JSONObject does not contain a PackageID it should be pulled from SCCM"{
        $packageID = $null
        . "$here\$sut" -sitecode 'QA1'
        Assert-MockCalled Get-CMApplication -Exactly 1 -Scope It
    }
    it "If the JSONObject has a packageID Get-CMApplication should NOT be called"{
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1'
        Assert-MockCalled Get-CMApplication -Exactly 0 -Scope It
    }
    it "Distribution Point Groups should be pulled from SCCM"{
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1'
        Assert-MockCalled Get-CMDistributionPointGroup -Exactly 1 -Scope it
    }
    it "If `$DPType is Non-Store `$PrimaryDPGroups should contain non-store DPs"{
        $dpType = "non-store"
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        "Logistic & Divisional - Distribution Points" | should BeIn $primarydpgroups
        "AUS - Distribution Points" | should BeIn $primarydpgroups
        "ATL - Distribution Points" | should BeIn $primarydpgroups
        "Store - Distribution Points" | should not BeIn $primarydpgroups
    }
    it "If `$DPType is Store `$PrimaryDPGroups should only contain store DPs"{
        $dpType = "store"
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        "Logistic & Divisional - Distribution Points" | should not BeIn $primarydpgroups
        "AUS - Distribution Points" | should not BeIn $primarydpgroups
        "ATL - Distribution Points" | should not BeIn $primarydpgroups
        "Store - Distribution Points" | should BeIn $primarydpgroups
    }
    it "If `$DPType is Store Start-CMContentDistribution should run once"{
        $dpType = "store"
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        Assert-MockCalled Start-CMContentDistribution -Exactly 1 -Scope It
    }
    it "If `$DPType is Non-Store Start-CMContentDistribution should run three times"{
        $dpType = "non-store"
        $packageID = 'QA101BA4'
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        Assert-MockCalled Start-CMContentDistribution -Exactly 3 -Scope It
    }
    It "If an error is generated, `$ActivityStatus should be 'Failed'"{
        $dpType = "non-store"
        $packageID = 'QA101BA4'
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        $ActivityStatus | should -Match 'Failed'
    }
    It "If an error is generated, `$ErrorMessage should contain the error"{
        $dpType = "non-store"
        $packageID = 'QA101BA4'
        mock Connect-SCCM {throw 'an error'}
        . "$here\$sut" -sitecode 'QA1' -DPType $dptype
        $Errormessage | should -Match 'an error'
    }
}