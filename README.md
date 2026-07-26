# Pyload


A Python-based in-memory .NET assembly loader with low-noise defense evasion, designed for authorized red team engagements.

### ETW bypass:
* Technique: Environment variable pre CLR initialization
* Sets COMPLUS_ETWEnabled=0 and COMPlus_EnableDiagnostics=0 before the .NET runtime loads
* CLR reads these at startup and skips ETW initialization entirely


### AMSI bypass:
* Technique: .NET Reflection amsiInitFailed field manipulation
* Accesses System.Management.Automation.AmsiUtils via BindingFlags.NonPublic | Static
* Sets amsiInitFailed = True CLR skips all AMSI scan calls


- Random sleep intervals injected between every critical stage (CLR load, decryption, execution)
- Disrupts sandbox timing analysis and behavioral heuristics that expect fixed execution patterns


## Building automated: 
```powershell
.\build.ps1 -PathToFile C:\Temp\Rubeus.exe -FileArgs "hash /password:Aa123456" -Key "Aa12345677!!"
```


## Building Manual:

1. Enrypt the PE (P.txt file will created):
```python
  python Encryptor.py C:\Temp\Rubeus.exe -a "hash /password:Aa123456" -k "Aa12345677!!"

  [+] Payload encrypted (AES-256-GCM)
      Source    : C:\Temp\Rubeus.exe (510,976 bytes)
      Arguments : 'hash /password:Aa123456'
      Output    : P.txt (681,389 bytes)
      Key       : Aa12345677!!
```

2. Build the stub file:

```python
python PreBuild.py
```

3. Download python_minimal + libraries 
```
powershell.exe -exec bypass
python -m venv venv
.\venv\Scripts\activate
pip install python-embedded-launcher
git clone https://github.com/zsquareplusc/python-embedded-launcher.git
pip install -r .\python-embedded-launcher\requirements.txt
python -m launcher_tool.download_python3_minimal --this-version --64
```
```powershell
$content = @"
python313.zip
.

import site
"@
[System.IO.File]::WriteAllText(
    (Resolve-Path "python3-minimal\python313._pth"),
    $content,
    [System.Text.Encoding]::ASCII
)

```
``` powershell
curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py
.\python3-minimal\python.exe .\get-pip.py
.\python3-minimal\python.exe -m pip install pythonnet cryptography --target python3-minimal --no-warn-script-location
```

4. Download NSIS: https://sourceforge.net/projects/nsis/

5. Comiple the loader:
```
Right click on BuildExe.nsi and push Compile NSIS Script -> output file : AzureSyncConnector.exe
```
