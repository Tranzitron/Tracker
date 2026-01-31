$os = "undefined"
function DefineOS {
	$osDescription = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
	if ($osDescription.Contains("Windows")) {
		return "windows"
	}
	elseif ($osDescription.Contains("MacOS")) {
		return = "macos"
	}
 else {
		return = "linux"
	}
}

function Request-AdminPrivileges {
	if (($os -eq "macos") -or ($os -eq "linux")) {
		$isRoot = (id -u) -eq 0
        
		if (-not $isRoot) {
			$scriptPath = $PSCommandPath
			$allArguments = $MyInvocation.Line.Replace($MyInvocation.InvocationName, '').Trim()
            
			if ($scriptPath) {
				# Restart with sudo
				$command = "sudo pwsh -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $allArguments"
				Invoke-Expression $command
				exit
			}
			else {
				Write-Error "Cannot elevate: Script must be saved to a file."
				exit 1
			}
		}
		else {
			Write-Host "Already running with root privileges" -ForegroundColor Green
		}
	}
}
function RunAsAdmin {
	if ($os -eq "windows") {
		$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
		$isAdmin = (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
	
		if (-not $isAdmin) {
			Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
			exit
		}
	}
	elseif (($os -eq "macos") -or ($os -eq "linux")) {
		$isRoot = (id -u) -eq 0
        
		if (-not $isRoot) {
			Write-Warning "Root privileges required. Asking for sudo."
			Request-AdminPrivileges
			exit
		}
	}
}

$os = DefineOS
RunAsAdmin

function Test-CommandExists ($cmdname) {
	return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

function Test-Network {
	param([string]$HostName = "www.google.com")
    
	Write-Host $os
	if ($os -eq "windows") {
		try {
			return Test-NetConnection -ComputerName $HostName -InformationLevel Quiet
		}
		catch {
			return $false
		}
	}
	else {
		try {
			# Try DNS resolution first
			[System.Net.Dns]::GetHostEntry($HostName) | Out-Null
            
			if ($os -eq "macos") {
				ping -c 1 -t 3 $HostName 2>&1 | Out-Null
			}
			else {
				ping -c 1 -W 3 $HostName 2>&1 | Out-Null
			}
            
			return ($LASTEXITCODE -eq 0)
		}
		catch {
			return $false
		}
	}
}

if (-not (Test-Network)) {
	Write-Host "An Internet connection is required." -ForegroundColor Red
	Pause
	exit
}

function Install-Act-Windows {
	$actInstalled = $false
	if (Test-CommandExists -cmdname 'winget') {
		winget install -e --id nektos.act --disable-interactivity --silent --accept-package-agreements --accept-source-agreements
		if (Test-CommandExists -cmdname $actCommand) {
			$actInstalled = $true
		}
	}

	if (-not $actInstalled) {
		if (Test-CommandExists -cmdname 'choco') {
			choco upgrade act-cli -y
			if (Test-CommandExists -cmdname $actCommand) {
				$actInstalled = $true
			}
		}
		else {
			Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
			if (Test-CommandExists -cmdname 'choco') {
				choco upgrade act-cli -y
				if (Test-CommandExists -cmdname $actCommand) {
					$actInstalled = $true
				}
			}
		}
	}
}

function Install-Act-MacOS {
	$actInstalled = $false
	if (Test-CommandExists -cmdname 'brew') {
		$originalUser = $env:SUDO_USER
		if (-not $originalUser) {
			$originalUser = (Get-ChildItem /Users | Where-Object { $_.Name -ne 'root' -and $_.Name -ne 'Shared' } | Select-Object -First 1).Name
		}
		
		sudo -u $originalUser brew install act
		
		if (Test-CommandExists -cmdname 'act') {
			$actInstalled = $true
		}
	}

	if (-not $actInstalled) {
		#Not tested
		if (Test-CommandExists -cmdname 'port') {
			#sudo port install act
			port install act
			if (Test-CommandExists -cmdname $actCommand) {
				$actInstalled = $true
			}
		}
		else {
			#Not tested
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
			if (Test-CommandExists -cmdname 'brew') {
				brew install act
				if (Test-CommandExists -cmdname $actCommand) {
					$actInstalled = $true
				}
			}
		}
	}
}

$actCommand = "act"
if (-not (Test-CommandExists -cmdname $actCommand)) {
	Write-Host "'$actCommand' isn't installed."

	if ($os -eq "windows") {
		Install-Act-Windows
	}
	elseif ($os -eq "macos") {
		Write-Host "MacOS"
		Install-Act-MacOS
	}

	if (-not (Test-CommandExists -cmdname $actCommand)) {
		Write-Host "Couldn't install '$actCommand'" -ForegroundColor Red
		Pause
		exit
	}
}

function Install-Docker-Windows {
	try {
		# Required for both WSL and Docker
		Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
	}
	catch {
		Write-Host "Couln't Enable Windows Feature: 'VirtualMachinePlatform'" -ForegroundColor Red
		Write-Host $_ -ForegroundColor Red
		Pause
		exit
	}
	wsl --install --no-distribution
	choco upgrade -y docker-desktop
}

$dockerCommand = "docker"
if (-not (Test-CommandExists -cmdname $dockerCommand)) {
	Write-Host "$dockerCommand isn't installed."

	if ($os -eq "windows") {
		Install-Docker-Windows
	}
	elseif ($os -eq "macos") {
		Install-Docker-MacOS
	}

	if (-not (Test-CommandExists -cmdname $dockerCommand)) {
		Write-Host "Couldnt install '$dockerCommand'" -ForegroundColor Red
		Pause
		exit
	}
}

$serviceName = "com.docker.service"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service -and ($service.Status -eq "Running")) {
	Write-Host "Docker Daemon is already running." -ForegroundColor Green
}
elseif ($service) {
	Write-Host "Starting the Docker Daemon..."
	try {
		Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"
		Start-Sleep -Seconds 10
	}
	catch {
		Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
	}
}
else {
	Write-Host "'DOCKER' isn't installed."
	try {
		# Required for both WSL and Docker
		Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All
	}
	catch {
		Write-Host "Couln't Enable Windows Feature: 'VirtualMachinePlatform'" -ForegroundColor Red
		Write-Host $_ -ForegroundColor Red
		Pause
		exit
	}
	wsl --install --no-distribution
	choco upgrade -y docker-desktop
}

Pause