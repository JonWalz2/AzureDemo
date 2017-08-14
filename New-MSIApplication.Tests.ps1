$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}

Describe 'Test of New-MSIApplication'{

    Function Get-CMApplication {}
    Function Get-CMCategory {}
    Function New-CMApplication {}
    Function Set-CMApplication {}

    Mock Connect-SCCM -Verifiable
    Mock Set-Location -Verifiable
    Mock Get-CMApplication -Verifiable
    Mock Get-CMCategory {$true} -Verifiable
    Mock New-CMApplication -Verifiable
    Mock Set-CMApplication -Verifiable

    It "New-CMApplication should be called exactly once"{
        $Iconpath = 'c:\fake\icon.ico'
        ."$here\$sut" -SiteCode QA1
        Assert-MockCalled New-CMApplication -Exactly 1
    }
    It "If `$Iconpath exists, the Application should be updated."{
        Assert-MockCalled Set-CMApplication -Exactly 1      
    }
    It "If `$Categories exist, with a single value, Get-CMCategory should be called once."{
        $Categories = 'utilities'
        ."$here\$sut" -SiteCode QA1
        Assert-MockCalled -CommandName Get-CMCategory -Exactly 1
    }
    It "If `$Categories exist, with 3 values, Get-CMCategory should be called three times."{
        $Categories = 'utilities,tools,Connectivity'
        ."$here\$sut" -SiteCode QA1
        Assert-MockCalled -CommandName Get-CMCategory -Exactly 3 -Scope It
    }
    It "If a specified category does not exist an error should be generated."{
        Mock Get-CMCategory {$false}
        $Categories = 'utilities'
        ."$here\$sut" -SiteCode QA1
        $errormessage | should -Match "Category utilities does not exist in SCCM and was not added."
    }
    It "If `$Categories exist the Application should be updated."{
        $Categories = 'utilities'
        Mock Get-CMCategory {$true}
        ."$here\$sut" -SiteCode QA1
        Assert-MockCalled -CommandName Set-CMApplication -Exactly 1 -Scope It
    }
    It "If the Application already exists in SCCM an error should be generated."{
        Mock Get-CMCategory {$true}
        Mock Get-CMApplication {$true}
        Mock New-CMApplication -Verifiable
        $ApplicationName = 'Fake App'
        ."$here\$sut" -SiteCode QA1 -ApplicationName $ApplicationName
        $errormessage | should -Match "Unable to create Fake App. The Application already exists."
    }
    It "If an error is generated, `$ActivityStatus should be 'Failed'"{
        Mock Get-CMCategory {$true}
        Mock Get-CMApplication {$true}
        Mock New-CMApplication -Verifiable
        $ApplicationName = 'Fake App'
        ."$here\$sut" -SiteCode QA1
        $ActivityStatus | should -Match 'Failed'
    }

}