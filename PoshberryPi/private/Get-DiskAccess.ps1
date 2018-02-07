Function Get-DiskAccess {
    <#
    .SYNOPSIS
        Returns a Win32DiskAccess object if validations pass

    .DESCRIPTION
        Returns a Win32DiskAccess object if validations pass

    .PARAMETER DriveLetter
        Volume of mounted drive to access

    .EXAMPLE
        $_diskAccess = Get-DiskAccess -DriveLetter "D:"

        # Attempts to lock and open access to D: and return the access object to $_diskAccess
    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$DriveLetter
    )
    $_diskAccess = New-Object -TypeName "Posh.DiskWriter.Win32DiskAccess"
    #Map to physical drive
    $physicalDrive = $_diskAccess.GetPhysicalPathForLogicalPath($DriveLetter)
    if([string]::IsNullOrEmpty($physicalDrive)) {
        Write-Error "Drive map unsuccessful"
        return $null
    }
    Write-Verbose "Physical drive path is $physicalDrive"
    #Lock logical drive
    $success = $_diskAccess.LockDrive($DriveLetter);
    Write-Verbose "Drive lock is $success"
    if (!$success)
    {
        Write-Error "Failed to lock drive"
        return $null
    }
    #Open the physical drive
    $physicalHandle = $_diskAccess.Open($physicalDrive)
    Write-Verbose "Physical handle is $physicalHandle"
    if ($physicalHandle -eq -1)
    {
        Write-Error "Failed to open physical drive"
        $_diskAccess.UnlockDrive();
        return $null
    }
    return $_diskAccess
}

