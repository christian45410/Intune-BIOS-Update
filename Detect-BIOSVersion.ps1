## Detection if BIOS was updated.

## Auto detect current BIOS version
[string]$currBIOSVersion = (Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion

## New BIOS version
[string]$newBIOSVersion = "N32ET76W"

if ("$currBIOSVersion" -like "*$newBIOSVersion*") 
{
    Write-Output "BIOS Updated to $currBIOSVersion"
    Exit 0
}

else
{
    Write-Output "BIOS was not updated to $newBIOSVersion. Current version is $currBIOSVersion"
    Exit 1
}