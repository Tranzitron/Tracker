$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
	Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
	exit
}

function Test-CommandExists ($cmdname) {
	return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

$commandName = "act"
if (-Not (Test-CommandExists -cmdname $commandName)) {
	Write-Host "$commandName isn't installed."
	Write-Host "installing act"
	
	if (Test-CommandExists -cmdname 'winget') {
		#winget install nektos.act 
		winget install -e --id nektos.act --disable-interactivity --silent --accept-package-agreements --accept-source-agreements
	}
 else {
		choco upgrade act-cli -y
	}
}

if (-Not (Test-CommandExists -cmdname $commandName)) {
	Write-Host Couldnt install "act"
	pause
	exit
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
}



pause