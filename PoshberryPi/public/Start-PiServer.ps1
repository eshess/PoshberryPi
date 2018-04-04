function Start-PiServer {
    <#
        .SYNOPSIS
            Used to start a basic TCP server on your Raspberry Pi.

        .DESCRIPTION
            Used to start a basic TCP server on your Raspberry Pi.

        .PARAMETER Port
            Remote port to target command on system running TCP Server

        .NOTES
            Name: Start-PiServer
            Author: Boe Prox
            DateCreated: 22 Feb 2014
            Version History:
                Version 1.2 -- 4 Apr 2018
                    -Modified by Eli Hess to accomodate needs for dot net core

        .EXAMPLE
            Start-PiServer -Port 2656

            Description
            -----------
            Creates a TCP listener on port 2656 which echos output back to the source
    #>
[CmdletBinding()]
param(
    $Port=1655
)
    #Create the Listener port
    $Listener = New-Object System.Net.Sockets.TcpListener -ArgumentList $Port

    #Start the listener; opens up port for incoming connections
    $Listener.Start()
    Write-Verbose "Server started on port $Port"
    $Active = $True
    While ($Active) {
        $incomingClient = $Listener.AcceptTcpClient()
        $remoteClient = $incomingClient.client.RemoteEndPoint.Address.IPAddressToString
        Write-Verbose ("New connection from $remoteClient")
        #Let it buffer for a second
        Start-Sleep -Milliseconds 1000

        #Get the data stream from connected client
        $stream = $incomingClient.GetStream()
        #Validate default credentials
        Try {
            $activeConnection = $True
            $stringBuilder = New-Object Text.StringBuilder
            While ($incomingClient.Connected) {
                #Is there data available to process
                If ($Stream.DataAvailable) {
                    Do {
                        [byte[]]$byte = New-Object byte[] 1024
                        Write-Verbose "$($incomingClient.Available) Bytes available from $($remoteClient)"
                        $bytesReceived = $Stream.Read($byte, 0, $byte.Length)
                        If ($bytesReceived -gt 0) {
                            Write-Verbose "$bytesReceived Bytes received from $remoteClient"
                            [void]$stringBuilder.Append([text.Encoding]::Ascii.GetString($byte[0..($bytesReceived - 1)]))
                        } Else {
                            $activeConnection = $False
                            Break
                        }
                    } While ($Stream.DataAvailable)
                    $string = $stringBuilder.ToString()
                    If ($stringBuilder.Length -gt 0) {
                        If ($string -match '^(Quit|Exit)') {
                            Write-Verbose "Message received from $($remoteClient):`n$($stringBuilder.ToString())"
                            Write-Verbose 'Shutting down...'
                            $data = "Shutting down TCP Server on $Computername <$Port>"
                            Send-PiResponse -Response $data
                            $Active = $False
                            $Stream.Close()
                            $Listener.Stop()
                        } Else {
                            Write-Verbose "Message received from $($remoteClient):`n$string"
                            Try {
                                $ErrorActionPreference = 'Stop'
                                Write-Verbose "Running command"
                                $Data = [scriptblock]::Create($string).Invoke()
                            } Catch {
                                $Data = $_.Exception.Message
                            }
                            If (-Not $Data) {
                                $Data = 'No data to return!'
                            }
                            Send-PiResponse -Response $Data
                        }
                    } Else {
                        Send-PiResponse -Response 'No data'
                    }
                    Write-Verbose "Closing session to $remoteClient"
                    $incomingClient.Close()
                }
                Start-Sleep -Milliseconds 1000
            }
        } Catch {
            Write-Warning $_.Exception.Message
            Try {
                Send-PiResponse -Response $_ -ErrorAction Stop
            } Catch {
                Write-Warning $_.Exception.Message
            }
            $Stream.Dispose()
            $incomingClient.Close()
            $incomingClient.Dispose()
            Continue
        }
        [void]$stringBuilder.Clear()
    }
}
