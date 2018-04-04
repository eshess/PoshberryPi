Function Invoke-PiCommand {
    <#
        .SYNOPSIS
            Used to send PowerShell commands to a remote listener. Use this command with -Command Exit
            to shut down TCP Server.

        .DESCRIPTION
            Used to send PowerShell commands to a remote listener. Waits for a return response
            and presents data returned from remote system. Use this command with -Command Exit
            to shut down TCP Server.

        .PARAMETER Computername
            Computer to send command to

        .PARAMETER Port
            Remote port to target command on system running TCP Server

        .PARAMETER SourcePort
            Use a different source port for endpoint

        .PARAMETER Command
            Command to send to the TCP Server. Recommonded to be contained using single quotes if not
            using a variable containing the commands.

        .NOTES
            Name: Send-Command
            Author: Boe Prox
            DateCreated: 22 Feb 2014
            Version History:
                Version 1.2 -- 4 Apr 2018
                    -Modified by Eli Hess to accomodate needs for dot net core
                Version 1.1 -- 24 Feb 2014
                    -Added -ImpersonationLevel which will allow for a specific level of impersonation or no
                    impersonation at all.
                    -Broke out commonly used commands into Private functions (ConvertFrom-CliXml,Wait-Response)
                    -Changed SourePort default value to a randomized port in case command needs to run again to avoid
                    duplicate endpoint issues when source port is in a TIME_WAIT state
                Version 1.0 -- 22 Feb 2014
                    -Initial Version

        .EXAMPLE
            Invoke-PiCommand -Computername '192.168.1.40' -Port 2656 -Command 'Get-Process | Select -First 1'

            Description
            -----------
            Sends a Get-Process command to Server on port 2656 and returns the first process.
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Computername = $env:COMPUTERNAME,
        [parameter()]
        [int]$Port = 1655,
        [parameter()]
        [int]$SourcePort=(Get-Random -Minimum 1500 -Maximum 16000),
        [parameter(Mandatory=$True)]
        [string]$Command = 'Exit'
    )
    Begin {
        Write-Verbose ("PSCommandPath $PSCommandPath")
        $PSBoundParameters.GetEnumerator() | ForEach-Object {
            Write-Verbose $_
        }
        Try {
            Write-Verbose "Creating Endpoint <$SourcePort> on $env:COMPUTERNAME"
            $Endpoint = new-object System.Net.IPEndpoint ([ipaddress]::any,$SourcePort)
            $TcpClient = [Net.Sockets.TCPClient]$endpoint
        } Catch {
            Write-Warning $_.Exception.Message
            Break
        }
    }
    Process {
        Try {
            Write-Verbose "Initiating connection to $Computername <$Port>"
            $TcpClient.Connect($Computername,$Port)
            $ServerStream = $TcpClient.GetStream()
            #Make the recieve buffer a little larger
            $TcpClient.ReceiveBufferSize = 1MB
            ##Client
            Try {
                Write-Verbose "Sending command"
                $data = [text.Encoding]::Ascii.GetBytes($Command)
                Write-Verbose "Sending $($data.count) bytes to $Computername <$port>"
                $ServerStream.Write($data,0,$data.length)
                $ServerStream.Flush()
                Wait-PiResponse -ServerStream $ServerStream -TcpClient $TcpClient
            } Catch {
                Write-Warning $_.Exception.Message
            }
        } Catch {
            Write-Warning $_.Exception.Message
        }
    }
    End {
        Write-Verbose 'Closing connection'
        If ($ServerStream) {$ServerStream.Dispose()}
        If ($TcpClient) {$TcpClient.Dispose()}
    }
}
