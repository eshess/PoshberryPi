Function Backup-PiImage {
    <#
    .SYNOPSIS
        Reads mounted SD card and saves contents to an img file

    .DESCRIPTION
        Reads mounted SD card and saves contents to an img file

    .PARAMETER DriveLetter
        Drive letter of source SD card

    .PARAMETER FileName
        Full file path of img file to create

    .EXAMPLE
        Backup-PiImage -DriveLetter "D:" -FileName "C:\Images\backup2018.img"

        # Creates a backup image of the SD card mounted to drive D: at C:\Images\backup2018.img
    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$DriveLetter,
        [parameter(Mandatory=$true)]
        [string]$FileName
    )
    $Completed = $false;
    $IsCancelling = $false
    $dtstart = Get-Date
    $maxBufferSize = 1048576
    $DriveLetter = Format-DriveLettter $DriveLetter

    #Validate we're not targeting the system drive
    if($DriveLetter -eq $ENV:SystemDrive) {
        Write-Error "System Drive cannot be targeted"
        return $Completed
    } else {
        $_diskAccess = Get-DiskAccess
    }

    #Get drive size
    if($_diskAccess) {
        $readSize = $_diskAccess.GetDriveSize($physicalDrive);
        Write-Verbose "Drive size is $readSize"
        if($readSize -le 0)
        {
            Write-Error "Failed to get device size"
            $_diskAccess.Close()
            $_diskAccess.UnlockDrive()
            return $Completed
        }
    }else {
        return $Completed
    }

    #Start doing the read
    $buffer =  [System.Array]::CreateInstance([Byte],$maxBufferSize)
    $offset = 0
    $fs = [System.Io.FileStream]::new($FileName, [System.Io.FileMode]::Create,[System.Io.FileAccess]::Write)
    try {
        #Capture CTRL-C as input so we can free up disk locks
        [console]::TreatControlCAsInput = $true
        while ($offset -lt $readSize -and !$IsCancelling)
        {
            #Check for CTRL-C and break if found
            if ([console]::KeyAvailable) {
                $key = [system.console]::readkey($true)
                if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C")) {
                    $IsCancelling = $true
                    break
                }
            }
            #NOTE: If we provide a buffer that extends past the end of the physical device ReadFile() doesn't
            #seem to do a partial read. Deal with this by reading the remaining bytes at the end of the
            #drive if necessary
            if(($readSize - $offset) -lt $buffer.Length) {
                $readMaxLength = $readSize - $offset
            } else {
                $readMaxLength = $buffer.Length
            }
            [int]$readBytes = 0;
            if ($_diskAccess.Read($buffer, $readMaxLength, [ref]$readBytes) -lt 0)
            {
                Write-Error "Error reading data from drive: " + $Marshal.GetHRForLastWin32Error();
                return $Completed;
            }
            if ($readBytes -eq 0)
            {
                Write-Error "Error reading data from drive - past EOF?"
                return $Completed
            }

            $fs.Write($buffer, 0, $readBytes)
            $offset += $readBytes

            $percentDone = (100*$offset/$readSize)
            $tsElapsed = (Get-Date) - $dtStart
            $bytesPerSec = $offset/$tsElapsed.TotalSeconds
            Write-Progress -Activity "Writing to disk" -Status "In Progress $bytesPerSec" -PercentComplete $percentDone
        }
        $_diskAccess.Close();
        $_diskAccess.UnlockDrive();
        $tstotalTime = (Get-Date) -$dtStart
        if (-not $IsCancelling)
        {
            $Completed = $true
            Write-Verbose "All Done - Read $offset bytes. Elapsed time $($tstotalTime.ToString("dd\.hh\:mm\:ss"))"
        }
        else
        {
            Write-Verbose "Cancelled";
            Remove-Item $FileName -Force
        }
    } catch {
        $_diskAccess.Close();
        $_diskAccess.UnlockDrive();
    } finally {
        [console]::TreatControlCAsInput = $false
    }
    return $Completed
}
