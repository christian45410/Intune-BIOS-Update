[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive'
)

$loggedInUsers = @((Get-CIMInstance -Class win32_computersystem -ErrorAction SilentlyContinue).UserName)
if ($loggedInUsers.Count -eq 0) {
    Try {
        Write-Output "No user logged in, running without ServiceUI"
        Start-Process Deploy-Application.exe -Wait -ArgumentList "-DeploymentType `"$DeploymentType`" -DeployMode `"NonInteractive`""
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
else {
    Foreach ($loggedInUser in $loggedInUsers) {
        Write-output "$loggedInUser logged in, running with ServiceUI"
    }
    Try {
        .\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -DeploymentType "$DeploymentType" -DeployMode "$DeployMode"
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
Write-Output "Install Exit Code = $LASTEXITCODE"
Exit $LASTEXITCODE