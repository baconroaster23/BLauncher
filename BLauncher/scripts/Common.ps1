# Common.ps1 - shared helper functions

function Get-OSName {
    if ($IsWindows -or $env:OS -eq 'Windows_NT') { return 'windows' }
    elseif ($IsMacOS) { return 'osx' }
    else { return 'linux' }
}


function Test-Rule {
    param($Rules)

    if (-not $Rules) { return $true }

    $allowed = $false
    foreach ($rule in $Rules) {
        $applies = $true

        if ($rule.os -and $rule.os.name -and $rule.os.name -ne (Get-OSName)) {
            $applies = $false
        }

        if ($rule.features) {
            
            $applies = $false
        }

        if ($applies) {
            $allowed = ($rule.action -eq 'allow')
        }
    }

    return $allowed
}
