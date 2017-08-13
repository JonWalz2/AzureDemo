$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
"$here\$sut"

Describe 'Demo Tests'{
    It '1 should be 1'{
        1 | should be 1
    }
    It '2 should be 2'{
        2 | should be 2
    }
}