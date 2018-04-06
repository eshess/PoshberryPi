Function Enable-PiSSH {
    <#
    .SYNOPSIS
        Enables SSH remoting on next boot of your Pi

    .DESCRIPTION
        Creates an empty file named 'ssh' in the specified path. Placing this file in the boot volume of your Rasperry Pi
        will enable SSH remoting on next boot

    .PARAMETER TargetVolume
        Drive letter of target boot volume

    .EXAMPLE
        Enable-PiSSH -TargetVolume "D:"

        # Creates an empty file named 'ssh' on the boot volume mounted to D:
    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [Parameter()]
        [String]$TargetVolume
    )
    $TargetVolume = Format-DriveLetter $TargetVolume
    New-Item -Path "$TargetVolume\" -Name ssh -ItemType File
}
