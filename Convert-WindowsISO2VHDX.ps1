Function Convert-WindowsISO2VHDX {
    param(
        [Parameter(Mandatory = $true)] [string]$SystemVHDXName,
        [Parameter(Mandatory = $true)] [int]$VHDXSize,
        [Parameter(Mandatory = $true)] [string]$OSImagenName
    )
    # Porcess needed veriable
    [string]$SystemVHDXNamePath
    [int]$VHDXDiskNumber,
    [string]$EFIDriveLetter,
    [string]$OSDriveLetter,
    [string]$OSImageDriveLetter,
    [int]$OSImageIndex,
    [string]$OSDrivePath
    [string]$OSWimImagePath
    [string]$OSImagePath=Resolve-Path -Path $OSImagenName

    New-VHD -Path $SystemVHDXName  -Dynamic -SizeBytes ($VHDXSize * 1073741824)
    $SystemVHDXNamePath = Resolve-Path $SystemVHDXName
    Mount-VHD -Path $SystemVHDXNamePath
    $VHDXDiskNumner = (Get-Disk | Where-Object { $_.Location -eq $SystemVHDXNamePath }).Number
    
    #Clear-Disk -Number $VHDXDiskNumner -RemoveData -Confirm:$false
    Initialize-Disk  -Number $VHDXDiskNumner  -PartitionStyle GPT
    
    # Create EFI,rimary partition and save the drive letter
    $EFIDriveLetter = (New-Partition -DiskNumber $VHDXDiskNumner -Size 200MB  -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}'   -AssignDriveLetter | Format-Volume -FileSystem FAT32 -NewFileSystemLabel "EFI" -Confirm:$false).DriveLetter
    $OSDriveLetter = (New-Partition -DiskNumber $VHDXDiskNumner -UseMaximumSize -AssignDriveLetter  | Format-Volume -FileSystem NTFS -NewFileSystemLabel "OS" -Confirm:$false).DriveLetter
    
    # Mount OS .iso image
    $OSImageDriveLetter = (Mount-DiskImage -ImagePath  $OSImagePath | Get-Volume).DriveLetter
    $OSWimImagePath = $OSImageDriveLetter + ":\sources\install.wim"
    Get-WindowsImage -ImagePath $OSWimImagePath
    $OSImageIndex = Read-Host -Prompt "Please Choose your Windows OS image"
    $OSDrivePath = $OSDriveLetter + ":\"
    Expand-WindowsImage -ImagePath  $OSWimImagePath -Index $OSImageIndex -ApplyPath $OSDrivePath
    
    # Write the EFI Boot file
    $BCDBootCopyWindows = $OSDriveLetter + ":\Windows"
    $BCDBootCopyESP = $EFIDriveLetter + ":"
    bcdboot $BCDBootCopyWindows /s $BCDBootCopyESP /f UEFI
    
    # Dismount VHD and OS Image
    Dismount-VHD -Path  $SystemVHDXNamePath
    Dismount-DiskImage -ImagePath  $OSImagePath
}





