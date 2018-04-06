Function Format-DriveLetter {
    <#
    .SYNOPSIS
        Returns uppercase driveletter with colon

    .DESCRIPTION
        Returns uppercase driveletter with colon

    .PARAMETER DriveLetter
        The string input to be validated

    .EXAMPLE
        $DriveLetter = Format-DriveLetter -DriveLetter "e"

        # Stores 'E:' in the variable DriveLetter

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$DriveLetter
    )
    $DriveLetter = $DriveLetter.ToUpper()
    switch($DriveLetter.Length) {
        1 {
            $DriveLetter += ":"
            break
        }
        2 {
            $DriveLetter = "$($DriveLetter.Substring(0,1)):"
            break
        }
        default {
            $DriveLetter = "$($DriveLetter.Substring(0,1)):"
        }
    }
    return $DriveLetter
}
