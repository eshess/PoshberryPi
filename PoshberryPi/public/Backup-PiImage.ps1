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

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param(
        [string]$DriveLetter,
        [string]$FileName
    )
    $IsCancelling = $false;
    $dtstart = Get-Date
    $maxBufferSize = 1048576
    $_diskAccess = New-Object -TypeName "Posh.DiskWriter.Win32DiskAccess"
    #Map to physical drive
    $physicalDrive = $_diskAccess.GetPhysicalPathForLogicalPath($DriveLetter)
    Write-Verbose "Physical drive path is $physicalDrive"
    #Lock logical drive
    $success = $_diskAccess.LockDrive($DriveLetter);
    Write-Verbose "Drive lock is $success"
    if (!$success)
    {
        Write-Verbose "Failed to lock drive"
        break
    }
    Start-Sleep -Seconds 5
    #Get drive size
    $driveSize = $_diskAccess.GetDriveSize($physicalDrive);
    Write-Verbose "Drive size is $driveSize"
    if($driveSize -le 0)
    {
        Write-Verbose "Failed to get device size"
        $_diskAccess.UnlockDrive()
        break
    }

    $readSize = $driveSize;
    #Open the physical drive
    $physicalHandle = $_diskAccess.Open($physicalDrive)
    Write-Verbose "Physical handle is $physicalHandle"
    if ($physicalHandle -eq -1)
    {
        Write-Verbose "Failed to open physical drive"
        $_diskAccess.UnlockDrive();
        break;
    }

    #Start doing the read
    $buffer =  [System.Array]::CreateInstance([Byte],$maxBufferSize)
    $offset = 0

    $fs = [System.Io.FileStream]::new($FileName, [System.Io.FileMode]::Create,[System.Io.FileAccess]::Write)
    while ($offset -lt $readSize -and !$IsCancelling)
    {
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
            Write-Verbose "Error reading data from drive: " + $Marshal.GetHRForLastWin32Error();
            break;
        }
        if ($readBytes -eq 0)
        {
            Write-Verbose "Error reading data from drive - past EOF?"
            break
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
    if ($IsCancelling)
    {
        Write-Verbose "Cancelled";
    }
    else
    {
        Write-Verbose "All Done - Read $offset bytes. Elapsed time $($tstotalTime.ToString("dd\.hh\:mm\:ss"))"
    }
}
