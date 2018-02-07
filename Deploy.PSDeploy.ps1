if ($env:BuildSystem -eq 'AppVeyor') {

    Deploy AppveyorDeployment {

        By AppVeyorModule {
            FromSource .\BuildOutput\$Env:ProjectName\$Env:ProjectName.psd1
            To AppVeyor
            WithOptions @{
                Version = $Env:APPVEYOR_BUILD_VERSION
                PackageName = $Env:ProjectName
                Description = 'A simple module for setting up and interacting with your Raspberry Pi'
                Author = "Eli Hess"
                Owners = "Eli Hess"
                destinationPath = ".\BuildOutput\$Env:ProjectName"
            }
            Tagged Appveyor
        }
    }
}
else {
    Write-Host "Not In AppVeyor. Skipped"
}

