Function Get-DiskHandle {
    <#
    .SYNOPSIS
        Opens the physical disk and returns the handle

    .DESCRIPTION
        Opens the physical disk and returns the handle

    .PARAMETER DiskAccess
        DiskAccess object to target

    .EXAMPLE
        $PhysicalHandle = Get-DiskHandle -DiskAccess $DiskAccess

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [Posh.DiskWriter.Win32DiskAccess]$DiskAccess,
        [parameter(Mandatory=$true)]
        [string]$PhysicalDrive
    )
    $physicalHandle = $DiskAccess.Open($PhysicalDrive)
    Write-Verbose "Physical handle is $physicalHandle"
    if ($physicalHandle -eq -1)
    {
        Write-Error "Failed to open physical drive"
        return $false
    }else {
        return $true
    }
}
