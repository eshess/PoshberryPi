function Send-PiResponse {
    <#
        .SYNOPSIS
            Internally used by Start-PiServer to send data back to caller.

        .DESCRIPTION
            Internally used by Start-PiServer to send data back to caller. Will initially
            attempt to serialize utilizing PSSerializer and then revert to
            ConvertTo-CliXml if an error occurs.

        .PARAMETER Response
            Response data to send.

        .NOTES
            Name: Send-PiResponse
            Author: Boe Prox
            DateCreated: 22 Feb 2014
            Version History:
                Version 1.2 -- 4 Apr 2018
                    -Modified by Eli Hess to accomodate needs for dot net core

        .EXAMPLE
            Send-PiResponse -Response

            Description
            -----------
            Internally used by Start-PiServer to send data back to caller.
    #>
[cmdletbinding()]
Param (
    $Response
)
    Try {
        Write-Verbose "Serializing data before sending using PSSerializer"
        $ErrorActionPreference = 'stop'
        $serialized = [System.Management.Automation.PSSerializer]::Serialize($Response)
    } Catch {
    Write-Verbose "Serializing data before sending using ConvertTo-CliXml"
        $serialized = $Response | ConvertTo-CliXml
    }
    $ErrorActionPreference = 'Continue'
    #Resend the Data back to the client
    $bytes  = [text.Encoding]::Ascii.GetBytes($serialized)
    #Send the data back to the client
    Write-Verbose "Echoing $($bytes.count) bytes to $remoteClient"
    $Stream.Write($bytes,0,$bytes.length)
    $Stream.Flush()
}
