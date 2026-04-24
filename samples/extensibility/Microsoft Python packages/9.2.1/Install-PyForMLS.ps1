#
# Install-PyForMLS.ps1
# Copyright (C) Microsoft.  All rights reserved.
#

# See: https://learn.microsoft.com/sql/machine-learning/python/setup-python-client-tools-sql

# Command-line parameters
param
(
    [string]$InstallFolder = "$Env:ProgramFiles\Microsoft\PyForMLS",
    [string]$CacheFolder = $Env:Temp,
    [string]$JupyterShortcut = "$Env:ProgramData\Microsoft\Windows\Start Menu\Jupyter Notebook for Microsoft Machine Learning Server.lnk"
)

# Verify script is being run with elevated privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script must be run as Administrator"
    Exit 1
}

# Product version to install
$productVersion = '9.2.1.0'

# Default language to install (en-us)
$productLcid = '1033'

# Component names and their corresponding fwlink IDs
$components = @{ 'SPO' = '852723'; 'SPS' = '852726'; }

# Helper function which outputs the specified message to the console and prepends the current date and time
function WriteMessage($message)
{
    Write-Host ("[{0}] {1}" -f (Get-Date -format u), $message)
}

# Helper function which generates a fwlink for the specified component
function GenerateFwlink($componentName)
{
    return 'https://go.microsoft.com/fwlink/?LinkId={0}&clcid={1}' -f $components[$componentName], $productLcid
}

# Helper function which generates the absolute CAB path of the specified component 
function GenerateCabPath($componentName)
{
    return "{0}\{1}_{2}_1033.cab" -f $cacheFolder, $componentName, $productVersion
}

# Helper function which returns true if the specified CAB file is found in the cache
function IsCachedCabValid($cabFile, $cabUrl)
{
    $isValid = $false

    # Does CAB file exist?
    if (Test-Path $cabFile)
    {
        # Retrieve headers from CAB URL
        $response = Invoke-WebRequest -Method Head -Uri $cabUrl

        # Compare last modified date of cached file against the remote file
        if ([datetime](Get-ItemProperty -Path $cabFile).LastWriteTime -ge $response.Headers['Last-Modified'])
        {
            WriteMessage "Cached $cabFile is up-to-date"
            $isValid = $true
        }
        else
        {
            WriteMessage "Cached $cabFile is expired"
            $isValid = $false
        }
    }
    else
    {
        WriteMessage "$cabFile not found in cache"
        $isValid = $false
    }

    return $isValid
}

WriteMessage "Starting installation"

# Create install folder, if necessary
if (-not (Test-Path $installFolder))
{   
    WriteMessage "Creating install folder $installFolder"
    New-Item -ItemType directory -Path $installFolder > $null
}

# Download the CAB file for each component
foreach ($componentName in $components.Keys)
{
    $cabUrl = GenerateFwlink($componentName)
    $cabFile = GenerateCabPath($componentName)
        
    # Download CAB file, if necessary
    if (-not (IsCachedCabValid $cabFile $cabUrl))
    {
        WriteMessage "Downloading $cabUrl to $cabFile"
        Invoke-WebRequest -Uri $cabUrl -OutFile $cabFile
    }
}
    
# Extract the contents of each CAB file
foreach ($componentName in $components.Keys)
{
    $cabFile = GenerateCabPath($componentName)

    # Extract all files using the built-in expand.exe tool
    WriteMessage "Extracting $cabFile to $installFolder (this may take several minutes)"
    &"$Env:WinDir\System32\expand.exe" $cabFile -F:* $installFolder > $null
}

# Create shortcut
WriteMessage "Creating shortcut $jupyterShortcut"
$shell = New-Object -comObject WScript.Shell
$shortcut = $shell.CreateShortcut($jupyterShortcut)
$shortcut.TargetPath = "$installFolder\Scripts\jupyter-notebook.exe"
$shortcut.Arguments = "--notebook-dir `"$installFolder\samples`""
$shortcut.Save()

# Force shortcut to launch as admin
$bytes = [System.IO.File]::ReadAllBytes($jupyterShortcut)
$bytes[0x15] = $bytes[0x15] -bor 0x20
[System.IO.File]::WriteAllBytes($JupyterShortcut, $bytes)

WriteMessage "Installation complete"
