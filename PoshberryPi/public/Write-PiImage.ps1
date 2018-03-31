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
    try { [Posh.DiskWriter.Win32DiskAccess] | Out-Null } catch { Add-Type -Path "$PSScriptRoot\classes\Win32DiskAccess.cs" }
    $Completed = $false
    $dtStart = (Get-Date)
    if((Test-Path $FileName) -eq $false)
    {
        Write-Error "$FileName doesn't exist"
        return $Completed
    }
    $DriveLetter = Format-DriveLetter $DriveLetter

    #Validate we're not targeting the system drive and the drive we're targeting is empty
    if($DriveLetter -eq $ENV:SystemDrive) {
        Write-Error "System Drive cannot be used as source"
        return $Completed
    } elseif ((Get-ChildItem $DriveLetter).Count -gt 0) {
        Write-Error "Target volume is not empty. Use diskpart to clean and reformat the target partition to FAT32."
        return $Completed
    } else {
        $DiskAccess = Get-DiskAccess -DriveLetter $DriveLetter
    }

    #Validate disk access is operational
    if($DiskAccess) {
        #Get drive size and open the physical drive
        $PhysicalDrive = Get-PhysicalDrive -DriveLetter $DriveLetter
        if($PhysicalDrive){
            $physicalHandle = Get-DiskHandle -DiskAccess $DiskAccess -PhysicalDrive $PhysicalDrive.DeviceID
        }
    }else {
        return $Completed
    }

    if($physicalHandle) {
        try {
            [console]::TreatControlCAsInput = $true
            $maxBufferSize = 1048576
            $buffer = [System.Array]::CreateInstance([Byte],$maxBufferSize)
            [long]$offset = 0;
            $fileLength = ([System.Io.FileInfo]::new($fileName)).Length
            $basefs = [System.Io.FileStream]::new($fileName, [System.Io.FileMode]::Open,[System.Io.FileAccess]::Read)
            $bufferOffset = 0;
            $BinanaryReader = [System.IO.BinaryReader]::new($basefs)
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
                    $readBytes = $BinanaryReader.Read($buffer, $bufferOffset, $buffer.Length - $bufferOffset)
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

                if ($DiskAccess.Write($buffer, $bytesToWrite, [ref]$wroteBytes) -lt 0)
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
            $DiskAccess.Close()
            $DiskAccess.UnlockDrive()
            if(-not $IsCancelling) {
                $Completed = $true
                $tstotalTime = (Get-Date) - $dtStart
                Write-Verbose "All Done - Wrote $offset bytes. Elapsed time $($tstotalTime.ToString("dd\.hh\:mm\:ss"))"
            } else {
                Write-Output "Imaging was terminated early. Please clean and reformat the target volume before trying again."
            }
        } catch {
            $DiskAccess.Close()
            $DiskAccess.UnlockDrive()
        }finally {
            [console]::TreatControlCAsInput = $false
        }
    }
    return $Completed
}
