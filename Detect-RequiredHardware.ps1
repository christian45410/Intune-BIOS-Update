## Detect mfg, model, and bios version before deploying update.

[string]$currentModel = (Get-WmiObject -Class:Win32_ComputerSystem).Model
[string]$currentMfg = (Get-WmiObject -Class:Win32_ComputerSystem).Manufacturer
[string]$currentBIOSVersion = (Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion


# Required manufacture name
[string]$reqMfg = "LENOVO"

## Requried bios version
[string]$reqBIOSversion = "N32ET76W (1.52 )"


if (("$currentMfg" -like "$reqMfg") -and ("$currentBIOSversion" -lt "$reqBIOSversion")) 
{
    Write-Output "applyUpdate"
}

else
{
    Write-Output "noUpdate"
    Exit 0
}