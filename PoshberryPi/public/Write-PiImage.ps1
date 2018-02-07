Function Write-PiImage {
    <#
    .SYNOPSIS
        Writes an image file to an SD card

    .DESCRIPTION
        Writes an image file to an SD card

    .PARAMETER DriveLetter
        Drive letter of mounted SD card

    .PARAMETER FileName
        Path to image file

    .EXAMPLE
        Write-PiImage -DriveLetter "D:" -FileName "C:\Images\stretch.img"

        # Writes the image file located at C:\Images\stretch.img to the SD card mounted to D:

    .LINK
        https://github.com/eshess/PoshberryPi

    #>
    [cmdletbinding()]
    param (
        [string]$DriveLetter,
        [string]$FileName
    )
    $Completed = $false
    $dtStart = (Get-Date)
    $_diskAccess = New-Object -TypeName "Posh.DiskWriter.Win32DiskAccess"
    if((Test-Path $FileName) -eq $false)
    {
        Write-Error "$FileName doesn't exist"
        return $Completed
    }

    #Get physical drive partition for logical partition
    $physicalDrive = $_diskAccess.GetPhysicalPathForLogicalPath($DriveLetter)
    Write-Verbose "Drive path is $physicalDrive"
    if ([string]::IsNullOrEmpty($physicalDrive))
    {
        Write-Error "Failed to map partition to physical drive"
        return $Completed
    }

    #Lock logical drive
    $success = $_diskAccess.LockDrive($DriveLetter)
    Write-Verbose "Lock is $success"
    if (!$success)
    {
        Write-Error "Failed to lock drive"
        return $Completed
    }
    Start-Sleep -Seconds 5
    #Get drive size
    $driveSize = $_diskAccess.GetDriveSize($physicalDrive)
    if ($driveSize -le 0)
    {
        Write-Error "Failed to get device size"
        $_diskAccess.UnlockDrive();
        return $Completed
    }

    #Open the physical drive
    $physicalHandle = $_diskAccess.Open($physicalDrive)
    if ($physicalHandle -eq -1)
    {
        Write-Error "Failed to open physical drive"
        $_diskAccess.UnlockDrive()
        return $Completed
    }
    $maxBufferSize = 1048576
    $buffer = [System.Array]::CreateInstance([Byte],$maxBufferSize)
    [long]$offset = 0;
    $fileLength = ([System.Io.FileInfo]::new($fileName)).Length

    $basefs = [System.Io.FileStream]::new($fileName, [System.Io.FileMode]::Open,[System.Io.FileAccess]::Read)
    $bufferOffset = 0;
    $br = [System.IO.BinaryReader]::new($basefs)
    try {
        [console]::TreatControlCAsInput = $true
        while ($offset -lt $fileLength -and !$IsCancelling)
        {
            #Check for Ctrl-C and break if found
            if ([console]::KeyAvailable) {
                $key = [system.console]::readkey($true)
                if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C")) {
                    $IsCancelling = $true
                    break
                }
            }
            [int]$readBytes = 0
            do
            {
                $readBytes = $br.Read($buffer, $bufferOffset, $buffer.Length - $bufferOffset)
                $bufferOffset += $readBytes
            } while ($bufferOffset -lt $maxBufferSize -and $readBytes -ne 0)

            [int]$wroteBytes = 0
            $bytesToWrite = $bufferOffset;
            $trailingBytes = 0;

            #Assume that the underlying physical drive will at least accept powers of two!
            if(Get-IsPowerOfTwo $bufferOffset)
            {
                #Find highest bit (32-bit max)
                $highBit = 31;
                for (; (($bufferOffset -band (1 -shl $highBit)) -eq 0) -and $highBit -ge 0; $highBit--){}

                #Work out trailing bytes after last power of two
                $lastPowerOf2 = 1 -shl $highBit;

                $bytesToWrite = $lastPowerOf2;
                $trailingBytes = $bufferOffset - $lastPowerOf2;
            }

            if ($_diskAccess.Write($buffer, $bytesToWrite, [ref]$wroteBytes) -lt 0)
            {
                Write-Error "Null disk handle"
                return $Completed
            }

            if ($wroteBytes -ne $bytesToWrite)
            {
                Write-Error "Error writing data to drive - past EOF?"
                return $Completed
            }

            #Move trailing bytes up - Todo: Suboptimal
            if ($trailingBytes -gt 0)
            {
                $Buffer.BlockCopy($buffer, $bufferOffset - $trailingBytes, $buffer, 0, $trailingBytes);
                $bufferOffset = $trailingBytes;
            }
            else
            {
                $bufferOffset = 0;
            }
            $offset += $wroteBytes;

            $percentDone = [int](100 * $offset / $fileLength);
            $tsElapsed = (Get-Date) - $dtStart
            $bytesPerSec = $offset / $tsElapsed.TotalSeconds;
            Write-Progress -Activity "Writing to Disk" -Status "Writing at $bytesPerSec" -PercentComplete $percentDone
        }
        $_diskAccess.Close()
        $_diskAccess.UnlockDrive()
        if(-not $IsCancelling) {
            $Completed = $true
            $tstotalTime = (Get-Date) - $dtStart
            Write-Verbose "All Done - Wrote $offset bytes. Elapsed time $($tstotalTime.ToString("dd\.hh\:mm\:ss"))"
        } else {
            Write-Verbose "Operation was cancelled"
        }
    } catch {
        $_diskAccess.Close()
        $_diskAccess.UnlockDrive()
    }finally {
        [console]::TreatControlCAsInput = $false
    }
    return $Completed
}
