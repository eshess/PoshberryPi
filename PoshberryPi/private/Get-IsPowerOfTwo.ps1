Function Get-IsPowerOfTwo {
    <#
    .SYNOPSIS
        Verifies input is a power of two and returns true or false

    .DESCRIPTION
        Verifies input is a power of two and returns true or false

    .PARAMETER Num
        Number to check against

    .EXAMPLE
        Get-IsPowerOfTwo -Num 23

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param (
        $Num
    )
    return ($Num -ne 0) -and (($Num -band ($Num - 1)) -eq 0);
}
