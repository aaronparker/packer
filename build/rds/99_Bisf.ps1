#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Optimise and seal a Windows image.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Tools"
)

#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"


#region BIS-F
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
Write-Host "BISF"

$App = Get-EvergreenApp -Name "BISF"
$OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"

# Install BIS-F
Write-Host "Found MSI file: $($OutFile.FullName)."
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/i $($OutFile.FullName) ALLUSERS=1 /quiet"
    NoNewWindow  = $True
    Wait         = $True
    Verbose      = $True
}
Start-Process @params

# If BIS-F installed OK, continue
$BisfInstall = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Base Image Script Framework (BIS-F)"
Write-Host "BIS-F install path: $BisfInstall."
if (Test-Path -Path $BisfInstall -ErrorAction "SilentlyContinue") {

    # Remove Start menu shortcut if it exists
    Write-Host "Remove BIS-F Start menu shortcut."
    $params = @{
        Path        = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Base Image Script Framework (BIS-F).lnk"
        Force       = $True
        Verbose     = $True
        ErrorAction = "SilentlyContinue"
    }
    Remove-Item @params

    # Copy BIS-F config files
    try {
        Write-Host "Copy BIS-F configuration files from: $Path to $BisfInstall."
        Switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
            "Microsoft Windows Server*" {
                $Config = "BISFconfig_MicrosoftWindowsServer2019Standard_64-bit.json"
            }
            "Microsoft Windows 1*" {
                $Config = "BISFconfig_MicrosoftWindows10Enterprise_64-bit.json"
            }
            Default {
            }
        }
        $ConfigFile = Get-ChildItem -Path $Path -Recurse -Filter $Config
        $params = @{
            Path        = $ConfigFile.FullName
            Destination = $BisfInstall
            Force       = $True
            Verbose     = $True
            ErrorAction = "SilentlyContinue"
        }
        Write-Host "Copy BIS-F configuration file: $($ConfigFile.FullName)."
        Copy-Item @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to copy BIS-F config file: $($ConfigFile.FullName) with: $($_.Exception.Message)."
    }

    # Set BISFSharedConfig.json
    try {
        $json = [PSCustomObject] @{
            ConfigFile = [System.IO.Path]::Combine(${env:ProgramFiles(x86)}, "Base Image Script Framework (BIS-F)", $ConfigFile)
        }
        $params = @{
            FilePath    = [System.IO.Path]::Combine(${env:ProgramFiles(x86)}, "Base Image Script Framework (BIS-F)", "BISFSharedConfig.json")
            Encoding    = "utf8"
            Force       = $True
            Verbose     = $True
            ErrorAction = "SilentlyContinue"
        }
        Write-Host "Set BIS-F shared configuration file: BISFSharedConfig.json."
        $json | ConvertTo-Json | Out-File @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to set BIS-F shared config file: $ConfigFile with: $($_.Exception.Message)."
    }

    # Run BIS-F
    Write-Host "Run BIS-F."
    try {
        Push-Location -Path (Join-Path -Path $BisfInstall -ChildPath "Framework")
        & "${env:ProgramFiles(x86)}\Base Image Script Framework (BIS-F)\Framework\PrepBISF_Start.ps1" -Verbose:$False
        Pop-Location
    }
    catch {
        Write-Warning -Message "`tERR: BIS-F exited with: $($_.Exception.Message)."
    }
}
else {
    Write-Warning -Message "`tERR: Failed to find BIS-F in: ${env:ProgramFiles(x86)}\Base Image Script Framework (BIS-F)."
}
#endregion


Write-Host "Complete: Bisf."
#endregion
