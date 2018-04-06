Function Get-DiskAccess {
    <#
    .SYNOPSIS
        Returns a Win32DiskAccess object if validations pass

    .DESCRIPTION
        Returns a Win32DiskAccess object if validations pass

    .PARAMETER TargetVolume
        Volume of mounted drive to access

    .EXAMPLE
        $_diskAccess = Get-DiskAccess -TargetVolume "D:"

        # Attempts to lock and open access to D: and return the access object to $_diskAccess
    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$TargetVolume
    )
    $_diskAccess = New-Object -TypeName "Posh.DiskWriter.Win32DiskAccess"
    #Lock logical drive
    $success = $_diskAccess.LockDrive($TargetVolume);
    Write-Verbose "Drive lock is $success"
    if (!$success)
    {
        Write-Error "Failed to lock drive"
        return $null
    }
    return $_diskAccess
}

