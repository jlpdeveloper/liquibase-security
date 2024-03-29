Import-Module $PSScriptRoot\Modules\PoShKeePass;

function SetupKeePass{
    param (
        $PathToKeePassDatabase
    )
    $p = Convert-Path -Path $PathToKeePassDatabase
    New-KeePassDatabaseConfiguration -DatabaseProfileName 'Liquibase' -DatabasePath $p -UseNetworkAccount
}
function ClearKeePassConfig{
    Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Liquibase"
}

function LBSwitchEnvironments {
    param (
        $Environment
    )
    $checkKeePass = CheckKeePassConfig
    if($checkKeePass -eq $true){
        $dbEntry = Get-KeePassEntry -AsPlainText -DatabaseProfileName TestLB -KeePassEntryGroupPath "Liquibase/Environments" | Where-Object { $_.Title -eq $Environment } | Select-Object -First 1
        if($null -ne $dbEntry){
            Set-Variable -Name LIQUIBASE_URL -Value $dbEntry.Url
            Set-Variable -Name LIQUIBASE_USERNAME -Value $dbEntry.UserName
            Set-Variable -Name LIQUIBASE_PASSWORD -Value $dbEntry.Password
            Set-Variable -Name CURRENT_ENV -Value $Environment
            Write-Output "Liquibase Variables set for $CURRENT_ENV"
        }
        else{
            Write-Output "Database Entry for $Environment not found!"
        }
    }
}

function LBGetEnvironment {
    Write-Output "Environment set to $CURRENT_ENV"
}

function LBClearEnvironment {
    Remove-Variable -Name LIQUIBASE_URL
    Remove-Variable -Name LIQUIBASE_USERNAME
    Remove-Variable -Name LIQUIBASE_PASSWORD
    Remove-Variable -Name CURRENT_ENV
}

function CheckKeePassConfig {
    $config = Get-KeePassDatabaseConfiguration
    if($null -eq $config){
        Write-Output "KeePass Database isn't set up, please run SetupKeePass"
        return $false
    }
    return $true
}