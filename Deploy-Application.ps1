[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================

	##  Current BIOS version - Do not modify
	$oldBIOSVersion = (Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion
	
	## Computer manufacture name - Do not modify
	$computerMfg = (Get-WmiObject Win32_ComputerSystem).Manufacturer

	##===============================================
	## Modify below variables for your environment
	##===============================================
	
	## Computer model
	## [string]$computerModelFriendlyName = "ThinkPad X1 Carbon"

	## New BIOS version
	[string]$newBIOSVersion = "N32ET76W (1.52 )"
	
	## Computer mfg name
	[string]$mfgName = "LENOVO"

	## Executable name
	#[string]$execName = "WINUPTP64.exe"

	## Executable arguments ex. -s
	#[string]$execArgs = "-s"

	## Deadline until force install
	[string]$deadline = "07/15/2022 20:00:00"

	## Restart timer (in seconds) once deadline exceeded
	[int]$restartTime = "600"
	
	## Script full title
	[string]$appName = "BIOS Update"

	## Welcome message
	[string]$welcomeMsg = "There is a mandatory BIOS update for your $computerMfg computer. `nYour computer will need to be restarted for the update to apply. `nPlease save your work before restarting!"

	## No power message
	[string]$noPowerMsg = "Please plug your laptop into a power source to continue with the BIOS update process." 

	
	##*===============================================
	##* Do not anything change below this line
	##*===============================================

	[string]$appVendor = "$computerMfg"
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '04/06/2022'
	[string]$appScriptAuthor = 'Christian Lancaster'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Script Friendly Name
	[string]$deployAppScriptFriendlyName = "$appName"

	## Variables: Script
	#[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.3'
	[string]$deployAppScriptDate = '30/09/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show-InstallationWelcome
        Show-InstallationWelcome -AllowDefer -DeferTimes 999 -DeferDeadline "$deadline" -PersistPrompt -CustomText

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		$biosUpdateExec = 'FALSE'

		if (($biosUpdateExec -eq 'FALSE') -and ("$computerMfg" -like "*$mfgName*") -and ("$oldBIOSVersion" -lt "$newBIOSVersion"))
		{
			## Welcome message
			Show-InstallationPrompt -Message "$welcomeMsg" -ButtonRightText 'Continue' -Timeout 300

			## Checks if computer is using the battery or plugged into a power source. Update will NOT allow the user to continue until computer is plugged in.
			If(-not (Test-Battery))
			{ 
				do
				{ 
					Show-InstallationPrompt -Message "$noPowerMsg" -ButtonRightText 'Continue' -Icon Exclamation
				} 
				until (Test-Battery) 
			}

			## Initiate the BIOS update sequence
			Try 
			{ 
				## Install bios update
				Execute-Process -Path "$dirFiles\WINUPTP64.exe" -Parameters "-s" -Wait -IgnoreExitCodes "1,1073807364"
				$biosUpdateExec = 'TRUE'
			} 
			Catch 
			{

			}
		}
		
		else 
		{
			Exit-Script -ExitCode 0
		}

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## Restarts computer if BIOS update ran
		if ($biosUpdateExec -eq 'TRUE')
		{
			## Suspend Bitlocker for 1 reboot
			Suspend-BitLocker -MountPoint C: -RebootCount 1 ##-Confirm:$false

			## Restart computer with countdown
			Show-InstallationRestartPrompt -Countdownseconds $restartTime -CountdownNoHideSeconds 30 -Wait
			Exit-Script -ExitCode 0
		}

	}

	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

    }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
