function RunAsAdmin {
	$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
	$isAdmin = (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

	if (-not $isAdmin) {
		Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
		exit
	}
}

RunAsAdmin

function Test-CommandExists ($cmdname) {
	return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

if (-not (Test-NetConnection -ComputerName www.google.com -InformationLevel Quiet)) {
	Write-Host "An Internet connection is required." -ForegroundColor Red
	Pause
	exit
}

$commandName = "act"
if (-not (Test-CommandExists -cmdname $commandName)) {
	$actInstalled = $false
	Write-Host "$commandName isn't installed."
	Write-Host "Trying to install act.."
	
	if (Test-CommandExists -cmdname 'winget') {
		winget install -e --id nektos.act --disable-interactivity --silent --accept-package-agreements --accept-source-agreements
		if (Test-CommandExists -cmdname $commandName) {
			$actInstalled = $true
		}
	}

	if (-not $actInstalled) {
		if (Test-CommandExists -cmdname 'choco') {
			choco upgrade act-cli -y
			if (Test-CommandExists -cmdname $commandName) {
				$actInstalled = $true
			}
		}
		else {
			Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
			if (Test-CommandExists -cmdname 'choco') {
				choco upgrade act-cli -y
				if (Test-CommandExists -cmdname $commandName) {
					$actInstalled = $true
				}
			}
		}
	}

	if (-not (Test-CommandExists -cmdname $commandName)) {
		Write-Host Couldnt install "act"
		Pause
		exit
	}
}

$serviceName = "com.docker.service"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service -and ($service.Status -eq "Running")) {
	Write-Host "Docker Daemon is already running."
}
elseif ($service) {
	Write-Host "Starting the Docker Daemon..."
	try {
		Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
		Start-Sleep -Seconds 10
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)"
	}
}
else {
	Write-Host "DOCKER ISNT INSTALLED"
	try {
		# Required for both WSL and Docker
		Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
	}
	catch {
		Write-Host "Couln't Enable Windows Feature: 'VirtualMachinePlatform'" -ForegroundColor Red
		Write-Host $_
		Pause
		exit
	}
	wsl --install --no-distribution
	choco upgrade -y docker-desktop
}

Pause