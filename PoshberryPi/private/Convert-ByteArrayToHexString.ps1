Function Convert-ByteArrayToHexString {
    <#
    .SYNOPSIS
        Returns a hex representation of a System.Byte[] array as one or more strings. Hex format can be changed.

    .DESCRIPTION
        Returns a hex representation of a System.Byte[] array as one or more strings. Hex format can be changed.

    .PARAMETER ByteArray
        System.Byte[] array of bytes to put into the file. If you pipe this array in, you must pipe the [Ref] to the array.
        Also accepts a single Byte object instead of Byte[].

    .PARAMETER Width
        Number of hex characters per line of output.

    .PARAMETER Delimiter
        How each pair of hex characters (each byte of input) will be delimited from the next pair in the output. The default
        looks like "0x41,0xFF,0xB9" but you could specify "\x" if you want the output like "\x41\xFF\xB9" instead. You do
        not have to worry about an extra comma, semicolon, colon or tab appearing before each line of output. The default
        value is ",0x".

    .Parameter Prepend
        An optional string you can prepend to each line of hex output, perhaps like '$x += ' to paste into another
        script, hence the single quotes.

    .PARAMETER AddQuotes
        A switch which will enclose each line in double-quotes.

    .EXAMPLE
        [Byte[]] $x = 0x41,0x42,0x43,0x44
        Convert-ByteArrayToHexString $x

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [System.Byte[]] $ByteArray,
    [Parameter()]
    [Int] $Width = 10,
    [Parameter()]
    [String] $Delimiter = ",0x",
    [Parameter()]
    [String] $Prepend = "",
    [Parameter()]
    [Switch] $AddQuotes
)
    if ($Width -lt 1)
    {
        $Width = 1
    }
    if ($ByteArray.Length -eq 0)
    {
        Write-Error "ByteArray length cannot be zero."
        Return
    }
    $FirstDelimiter = $Delimiter -Replace "^[\,\:\t]",""
    $From = 0
    $To = $Width - 1
    $Output = ""
    Do
    {
        $String = [System.BitConverter]::ToString($ByteArray[$From..$To])
        $String = $FirstDelimiter + ($String -replace "\-",$Delimiter)
        if ($AddQuotes)
        {
            $String = '"' + $String + '"'
        }
        if ($Prepend -ne "")
        {
            $String = $Prepend + $String
        }
        $Output += $String
        $From += $Width
        $To += $Width
    } While ($From -lt $ByteArray.Length)
    Write-Output $Output
}
