Function Get-PhysicalDrive {
    <#
    .SYNOPSIS
        Returns the physical drive path of the DiskAccess object

    .DESCRIPTION
        Returns the physical drive path of the DiskAccess object

    .PARAMETER TargetVolume
        Volume to get physical path to

    .EXAMPLE
        $PhysicalDrive = Get-PhysicalDrive -TargetVolume "D:"

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$TargetVolume
    )
    #Map to physical drive

    $LogicalDisk = Get-WmiObject Win32_LogicalDisk | Where-Object DeviceID -eq $TargetVolume
    $Log2Part = Get-WmiObject Win32_LogicalDiskToPartition | Where-Object Dependent -eq $LogicalDisk.__Path
    $phys = Get-WmiObject Win32_DiskDriveToDiskPartition | Where-Object Dependent -eq $Log2Part.Antecedent
    $DiskDrive = Get-WmiObject Win32_DiskDrive | Where-Object __Path -eq $phys.Antecedent
    Write-Verbose "Physical drive path is $($DiskDrive.DeviceID)"
    if($DiskDrive) {
        return $DiskDrive
    }else {
        Write-Error "Drive map unsuccessful"
        return $null
    }
}
