Function Wait-PiResponse {
    <#
        .SYNOPSIS
            Internal looping function which receives data after invoking Invoke-PiCommand.

        .DESCRIPTION
            Internal looping function which receives data after invoking Invoke-PiCommand.

        .PARAMETER TcpClient
            TCP Socket endpoint object used receive data

        .PARAMETER ServerStream
            Bytestream for sending and receiving data

        .NOTES
            Name: Wait-PiResponse
            Author: Boe Prox
            DateCreated: 22 Feb 2014
            Version History:
                Version 1.2 -- 4 Apr 2018
                    -Modified by Eli Hess to accomodate needs for dot net core

        .EXAMPLE
            Wait-PiResponse -TcpClient $TcpClient -ServerStream $ServerStream

            Description
            -----------
            Call typically made internally on Invoke-PiCommand utilizing TcpClient and Server stream
            already created for sending data.
    #>
[cmdletbinding()]
param (
    $TcpClient,
    $ServerStream
)
    $stringBuilder = New-Object Text.StringBuilder
    $Waiting = $True
    While ($Waiting) {
        While ($TcpClient.available -gt 0) {
            Write-Verbose "Processing return bytes: $($TcpClient.Available)"
            [byte[]]$inStream = New-Object byte[] $TcpClient.Available
            $buffSize = $TcpClient.Available
            $return = $ServerStream.Read($inStream, 0, $buffSize)
            [void]$stringBuilder.Append([System.Text.Encoding]::ASCII.GetString($inStream[0..($return-1)]))
            Start-Sleep -Seconds 1
        }
        If ($stringBuilder.length -gt 0) {
            $returnedData = [System.Management.Automation.PSSerializer]::DeSerialize($stringBuilder.ToString())
            Remove-Variable String -ErrorAction SilentlyContinue
            $Waiting = $False
        }
    }
    Write-Output $returnedData
}
