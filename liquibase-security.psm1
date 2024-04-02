Import-Module $PSScriptRoot\Modules\PoShKeePass;

function SetupKeePass{
    param (
        $PathToKeePassDatabase
    )
    <#
        .SYNOPSIS
        Setup KeePass for Liquibase use

        .DESCRIPTION
        Sets up the KeePass database for use in getting passwords

        .PARAMETER PathToKeePassDatabase
        Specifies the path to your KeePass database

        .INPUTS
        None. 

        .OUTPUTS
        None.

        .EXAMPLE
        PS> SetupKeePass

    #>

    $p = Convert-Path -Path $PathToKeePassDatabase
    New-KeePassDatabaseConfiguration -DatabaseProfileName 'Liquibase' -DatabasePath $p -UseNetworkAccount
}
function ClearKeePassConfig{
            <#
        .SYNOPSIS
        Removes liquibase keepass database 

        .DESCRIPTION
        Removes liquibase keepass database 

        .INPUTS
        None. 

        .OUTPUTS
        None.

        .EXAMPLE
        PS> ClearKeePassConfig

    #>
    Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Liquibase"
}

function LBSwitchEnvironments {
    param (
        $Environment
    )
        <#
        .SYNOPSIS
        Pull connection info from KeePass for Environment

        .DESCRIPTION
        Sets up environment variables for liquibase using the environment specified

        .PARAMETER Environment
        Specifies the environment name

        .INPUTS
        None. 

        .OUTPUTS
        None.

        .EXAMPLE
        PS> LBSwitchEnvironments local

    #>
    $config = Get-KeePassDatabaseConfiguration 
    if($null -eq $config){
        Write-Output "KeePass Database isn't set up, please run SetupKeePass"
    }
    else{
        $keepasPath = "Liquibase/Environments"
        $propertiesExists = $false
        $propertiesContent = ""
        if(Test-Path -Path $pwd\liquibase.properties){
            $propertiesExists = $true
            $propertiesContent = Get-Content -Path $pwd\liquibase.properties 
            if($propertiesContent -match 'liquibase.secret.subpath=.+'){
                $subpath = $propertiesContent -match 'liquibase.secret.subpath=.+' -replace 'liquibase.secret.subpath=', ''
                $subpath = $subpath -replace '\/+$', ''
                $keepasPath += '/' + $subpath
            }
        }

        #this gets the keePass entry, find the item with the title and selects the first
        $dbEntry = Get-KeePassEntry -AsPlainText -DatabaseProfileName "Liquibase" -KeePassEntryGroupPath $keepasPath | Where-Object { $_.Title -eq $Environment } | Select-Object -First 1
        if($null -ne $dbEntry){
            #check that there are no template urls, if there is, we need to pull from the liquibase.properties file
            if($dbEntry.Url -match '{{liquibase-database}}'){
                Write-Output "Template URL Found, pulling database from properties file"
                if($propertiesExists){
                    if($propertiesContent -match 'liquibase.database=.+'){
                        $dbName = $propertiesContent -match 'liquibase.database=.+' -replace 'liquibase.database=', ''
                        $Env:LIQUIBASE_COMMAND_URL = $dbEntry.Url -replace "{{liquibase-database}}", $dbName
                    }
                }
            }
            else{
                $Env:LIQUIBASE_COMMAND_URL = $dbEntry.Url 
            }
            
            $Env:LIQUIBASE_COMMAND_USERNAME = $dbEntry.UserName 
            $Env:LIQUIBASE_COMMAND_PASSWORD = $dbEntry.Password 
            $Env:CURRENT_ENV = $Environment 
            Write-Output "Liquibase Variables set for $Env:CURRENT_ENV"
        }
        else{
            Write-Output "Database Entry for $Environment not found!"
        }
    }
}

function LBGetEnvironment {
    <#
        .SYNOPSIS
        View the currently set up environment

        .DESCRIPTION
        View the currently set up environment

        .INPUTS
        None. 

        .OUTPUTS
        A string

        .EXAMPLE
        PS> LBGetEnvironment
        Environment set to local

    #>
    if($null -ne $Env:CURRENT_ENV){
        Write-Output "Environment set to $Env:CURRENT_ENV"
    }
    else{
        Write-Output "Environment not set"
    }
}

function LBClearEnvironment {
    <#
        .SYNOPSIS
        Clears environment variables for liquibase

        .DESCRIPTION
        Clears environment variables for liquibase

        .INPUTS
        None. 

        .OUTPUTS
        A string

        .EXAMPLE
        PS> LBClearEnvironment
        Clearing Environment. Previous Environment was local

    #>
    Write-Output "Clearing Environment. Previous Environment was $Env:CURRENT_ENV"
    $Env:LIQUIBASE_COMMAND_URL = ""
    $Env:LIQUIBASE_COMMAND_USERNAME = ""
    $Env:LIQUIBASE_COMMAND_PASSWORD = ""
    $Env:CURRENT_ENV = ""
}