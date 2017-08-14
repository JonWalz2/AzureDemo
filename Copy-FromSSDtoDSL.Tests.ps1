$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

. "$here\PMG_Functions.ps1"

function Get-PMGVariable{}

Describe 'Test of Copy-FromSSDtoDSL'{

    Function Get-CMApplication {}

    Mock Connect-SCCM -Verifiable
    Mock Get-CMApplication -Verifiable
    Mock Invoke-RestMethod
    Mock New-Item
    Mock Copy-Item

    it "Should check to see if the Application exists in SCCM"{
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
        Assert-MockCalled Connect-SCCM -Times 1
        Assert-MockCalled Get-CMApplication -Times 1
    }
    it "Should throw an error if the Application already exists in SCCM"{
        Mock Get-CMApplication {$true}
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
        $errormessage | should belike "*already exists in SCCM"
    }
    it "Should remove the folder if it already exists on the DSL"{
        Mock Get-CMApplication {$false} -Verifiable
        Mock New-Item -Verifiable
        Mock Remove-Item -Verifiable
        Mock Test-Path {$true} -Verifiable
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
       # Assert-MockCalled New-Item -Times 1
        Assert-MockCalled Remove-Item -Times 1
    }
    It "Should create the folder on the DSL"{
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
        Assert-MockCalled New-Item -Times 1
    }
    It "Should copy the folder to the DSL"{
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
        Assert-MockCalled Copy-Item -Times 1
    }

    It "After the file copy, the source folder should be removed"{
        mock Test-Path {$false}
        . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
        Assert-MockCalled remove-item -Exactly 1 -Scope it
    }
    Context "Test of Outputs"{
        . "$here\PMG_Functions.ps1" #dot Source of functions
        Mock Connect-SCCM
        Mock Get-CMApplication {$false} -Verifiable
        Mock New-Item -Verifiable
        Mock Remove-Item -Verifiable
        Mock Test-Path {$true} -Verifiable
        Mock Import-Module
        Mock New-PSDrive
        Mock Set-Location
        It "An error should cause the `$errormessage variable to be populated with the contents of the error"{
            Mock Copy-Item {write-error "special error"}
            . "$here\$sut" -ApplicationName 'Application Name' -SiteCode 'qa1' -DSL_path '\\a\b' -SSDIntake '\\c\\d' -ReadDatabaseURI 'http://api'
            $errormessage | should belike "*special error*"
        }
    }

}

