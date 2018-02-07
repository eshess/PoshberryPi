using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

namespace Posh.DiskWriter
{
    public enum EMoveMethod : int
    {
        Begin = 0,
        Current = 1,
        End = 2
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DiskGeometry
    {
        public long Cylinders;
        public int MediaType;
        public int TracksPerCylinder;
        public int SectorsPerTrack;
        public int BytesPerSector;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DiskGeometryEx
    {
        public DiskGeometry Geometry;
        public long DiskSize;
        public byte Data;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DISK_EXTENT
    {
        public  int DiskNumber;
        public ulong StartingOffset;
        public ulong ExtentLength;
    } 

    [StructLayout(LayoutKind.Sequential)]
    internal struct VolumeDiskExtents
    {
        public uint NumberOfDiskExtents;
        public DISK_EXTENT DiskExtent1;
    }

    public static class NativeMethods 
    {
        internal const uint OPEN_EXISTING = 3;
        internal const uint GENERIC_WRITE = (0x40000000);
        internal const uint GENERIC_READ = 0x80000000;
        internal const uint FSCTL_LOCK_VOLUME = 0x00090018;
        internal const uint FSCTL_UNLOCK_VOLUME = 0x0009001c;
        internal const uint FSCTL_DISMOUNT_VOLUME = 0x00090020;
        internal const uint FILE_SHARE_READ = 0x1;
        internal const uint FILE_SHARE_WRITE = 0x2;
        internal const uint IOCTL_DISK_GET_DRIVE_GEOMETRY = 0x70000;
        internal const uint IOCTL_DISK_GET_DRIVE_GEOMETRY_EX = 0x700a0;
        internal const uint IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS = 0x00560000;
        internal const uint IOCTL_STORAGE_GET_DEVICE_NUMBER = 0x2D1080;
        internal const uint BCM_SETSHIELD = 0x160C;
        internal const int INVALID_SET_FILE_POINTER = -1;

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern internal IntPtr LoadIcon(IntPtr hInstance, string lpIconName);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
        static extern internal IntPtr LoadLibrary(string lpFileName);

        [DllImport("Kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern internal int SetFilePointer([In] SafeFileHandle hFile, [In] int lDistanceToMove,  ref int lpDistanceToMoveHigh, [In] EMoveMethod dwMoveMethod);

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern internal  SafeFileHandle CreateFile(string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);

        [DllImport("kernel32", SetLastError = true)]
        static extern internal int ReadFile(SafeFileHandle handle, byte[] bytes, int numBytesToRead, out int numBytesRead, IntPtr overlapped_MustBeZero);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern internal int WriteFile(SafeFileHandle handle, byte[] bytes, int numBytesToWrite, out int numBytesWritten, IntPtr overlapped_MustBeZero);

        [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
        static extern internal bool DeviceIoControl(SafeFileHandle hDevice, uint dwIoControlCode, byte[] lpInBuffer, int nInBufferSize, byte[] lpOutBuffer, int nOutBufferSize, out int lpBytesReturned, IntPtr lpOverlapped);

        [DllImport("Kernel32.dll", SetLastError = false, CharSet = CharSet.Auto)]
        public static extern bool DeviceIoControl(SafeFileHandle device, uint dwIoControlCode, IntPtr inBuffer, uint inBufferSize, IntPtr outBuffer, uint outBufferSize, ref uint bytesReturned, IntPtr overlapped);

        [DllImport("kernel32.dll", ExactSpelling = true, SetLastError = true)]
        static extern internal bool CloseHandle(SafeFileHandle handle);

        [DllImport("user32", CharSet = CharSet.Auto, SetLastError = true)]
        static extern int SendMessage(IntPtr hWnd, UInt32 Msg, int wParam, IntPtr lParam);

    }
    public class Win32DiskAccess
    {
        #region Fields

        SafeFileHandle _partitionHandle = null;
        SafeFileHandle _diskHandle = null;

        #endregion

        #region IDiskAccess Members

        //public event EventHandler OnDiskChanged;

        public int Open(string drivePath)
        {
            int intOut;

            //
            // Now that we've dismounted the logical volume mounted on the removable drive we can open up the physical disk to write
            //
            var diskHandle = NativeMethods.CreateFile(drivePath, NativeMethods.GENERIC_READ | NativeMethods.GENERIC_WRITE, NativeMethods.FILE_SHARE_READ | NativeMethods.FILE_SHARE_WRITE, IntPtr.Zero, NativeMethods.OPEN_EXISTING, 0, IntPtr.Zero);
            if (diskHandle.IsInvalid)
            {
                //LogMsg(@"Failed to open device: " + Marshal.GetHRForLastWin32Error());
                return -1;
            }

            var success = NativeMethods.DeviceIoControl(diskHandle, NativeMethods.FSCTL_LOCK_VOLUME, null, 0, null, 0, out intOut, IntPtr.Zero);
            if (!success)
            {
                //LogMsg(@"Failed to lock device");
                diskHandle.Dispose();
                return -1;
            }

            _diskHandle = diskHandle;

            return 0;
        }

        public bool LockDrive(string drivePath)
        {
            bool success;
            int intOut;
            SafeFileHandle partitionHandle;

            //
            // Unmount partition (Todo: Note that we currently only handle unmounting of one partition, which is the usual case for SD Cards)
            //

            //
            // Open the volume
            ///
            partitionHandle = NativeMethods.CreateFile(@"\\.\" + drivePath, NativeMethods.GENERIC_READ, NativeMethods.FILE_SHARE_READ, IntPtr.Zero, NativeMethods.OPEN_EXISTING, 0, IntPtr.Zero);
            if (partitionHandle.IsInvalid)
            {
                //LogMsg(@"Failed to open device");
                partitionHandle.Dispose();
                return false;
            }

            //
            // Lock it
            //
            success = NativeMethods.DeviceIoControl(partitionHandle, NativeMethods.FSCTL_LOCK_VOLUME, null, 0, null, 0, out intOut, IntPtr.Zero);
            if (!success)
            {
                //LogMsg(@"Failed to lock device");
                partitionHandle.Dispose();
                return false;
            }

            //
            // Dismount it
            //
            success = NativeMethods.DeviceIoControl(partitionHandle, NativeMethods.FSCTL_DISMOUNT_VOLUME, null, 0, null, 0, out intOut, IntPtr.Zero);
            if (!success)
            {
                //LogMsg(@"Error dismounting volume: " + Marshal.GetHRForLastWin32Error());
                NativeMethods.DeviceIoControl(partitionHandle, NativeMethods.FSCTL_UNLOCK_VOLUME, null, 0, null, 0, out intOut, IntPtr.Zero);
                partitionHandle.Dispose();
                return false;
            }

            _partitionHandle = partitionHandle;

            return true;
        }


        public void UnlockDrive()
        {
            if(_partitionHandle != null)
            {
                _partitionHandle.Dispose();
                _partitionHandle = null;
            }
        }

        public int Read(byte[] buffer, int readMaxLength, out int readBytes)
        {
            readBytes = 0;

            if(_diskHandle == null)
                return -1;

            return NativeMethods.ReadFile(_diskHandle, buffer, readMaxLength, out readBytes, IntPtr.Zero);
        }

        public int Write(byte[] buffer, int bytesToWrite, out int wroteBytes)
        {
            wroteBytes = 0;
            if(_diskHandle == null)
                return -1;

            return NativeMethods.WriteFile(_diskHandle, buffer, bytesToWrite, out wroteBytes, IntPtr.Zero);
        }

        public void Close()
        {
            if (_diskHandle != null)
            {
                _diskHandle.Dispose();
                _diskHandle = null;
            }
        }

        public string GetPhysicalPathForLogicalPath(string logicalPath)
        {
            var diskIndex = -1;

            //
            // Now that we've dismounted the logical volume mounted on the removable drive we can open up the physical disk to write
            //
            var diskHandle = NativeMethods.CreateFile(@"\\.\" + logicalPath, NativeMethods.GENERIC_READ, NativeMethods.FILE_SHARE_READ, IntPtr.Zero, NativeMethods.OPEN_EXISTING, 0, IntPtr.Zero);
            if (diskHandle.IsInvalid)
            {
                //LogMsg(@"Failed to open device: " + Marshal.GetHRForLastWin32Error());
                return null;
            }

            var vdeSize = Marshal.SizeOf(typeof(VolumeDiskExtents));
            var vdeBlob = Marshal.AllocHGlobal(vdeSize);
            uint numBytesRead = 0;

           var success = NativeMethods.DeviceIoControl(diskHandle, NativeMethods.IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS, IntPtr.Zero,
                                                    0, vdeBlob, (uint)vdeSize, ref numBytesRead, IntPtr.Zero);

            var vde = (VolumeDiskExtents)Marshal.PtrToStructure(vdeBlob, typeof(VolumeDiskExtents));
            if (success)
            {
                if (vde.NumberOfDiskExtents == 1)
                    diskIndex = vde.DiskExtent1.DiskNumber;
            }
            else
            {
                //LogMsg(@"Failed get physical disk: " + Marshal.GetHRForLastWin32Error());
            }
            Marshal.FreeHGlobal(vdeBlob);

            diskHandle.Dispose();
            
            var path = "";
            if(diskIndex >= 0)
                path = @"\\.\PhysicalDrive" + diskIndex;

            return path;

        }

        public long GetDriveSize(string drivePath)
        {
            //
            // Now that we've dismounted the logical volume mounted on the removable drive we can open up the physical disk to write
            //
            var diskHandle = NativeMethods.CreateFile(drivePath, NativeMethods.GENERIC_WRITE, 0, IntPtr.Zero, NativeMethods.OPEN_EXISTING, 0, IntPtr.Zero);
            if (diskHandle.IsInvalid)
            {
                //LogMsg( @"Failed to open device: " + Marshal.GetHRForLastWin32Error());
                return -2;
            }

            //
            // Get drive size (NOTE: that WMI and IOCTL_DISK_GET_DRIVE_GEOMETRY don't give us the right value so we do it this way)
            //
            long size = -1;

            var geometrySize = Marshal.SizeOf(typeof(DiskGeometryEx));
            var geometryBlob = Marshal.AllocHGlobal(geometrySize);
            uint numBytesRead = 0;

            var success = NativeMethods.DeviceIoControl(diskHandle, NativeMethods.IOCTL_DISK_GET_DRIVE_GEOMETRY_EX, IntPtr.Zero,
                                                    0, geometryBlob, (uint)geometrySize, ref numBytesRead, IntPtr.Zero);

            var geometry = (DiskGeometryEx)Marshal.PtrToStructure(geometryBlob, typeof(DiskGeometryEx));
            if (success)
                size = geometry.DiskSize;

            Marshal.FreeHGlobal(geometryBlob);

            diskHandle.Dispose();

            return size;
        }

        #endregion

        private void Progress(int progressValue)
        {
            //if (OnProgress != null)
                //OnProgress(this, progressValue);
        }

        private void LogMsg(string msg)
        {
            //if (OnLogMsg != null)
                //OnLogMsg(this, msg);
        }

    }
}
