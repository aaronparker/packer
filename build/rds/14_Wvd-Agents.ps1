#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Downloads / installs the Windows Virtual Desktop agents and services
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $LogPath = "$env:SystemRoot\Logs\Packer",

    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\App\Microsoft\Wvd"
)


#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
New-Item -Path $LogPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
#region RTC service
Write-Host "Microsoft WvdAgents."
$App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64"} | Select-Object -First 1
if ($App) {

    # Download
    Write-Host "Downloading Microsoft Remote Desktop WebRTC Redirector Service"
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install RTC
    try {
        Write-Host "Installing Microsoft Remote Desktop WebRTC Redirector Service: $($App.Version)."
        $params = @{
            FilePath     = "$env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        Start-Process @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft Remote Desktop WebRTC Redirector Service."
    }
}
else {
    Write-Warning -Message "`tERR: Failed to retrieve Microsoft Remote Desktop WebRTC Redirector Service"
}
#endregion

#region Boot Loader
Write-Host "Microsoft Windows Virtual Desktop Agent Bootloader"
$App = Get-EvergreenApp -Name "MicrosoftWvdBootLoader" | Where-Object { $_.Architecture -eq "x64"} | Select-Object -First 1
if ($App) {
    if (!(Test-Path $Path)) { New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null }

    # Download
    Write-Host "Downloading Microsoft Windows Virtual Desktop Agent Bootloader"
    $OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"

    # Install
    Write-Host "Installing Microsoft Windows Virtual Desktop Agent Bootloader: $($App.Version)."
    try {
        $params = @{
            FilePath     = "$env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        Start-Process @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft Windows Virtual Desktop Agent Bootloader"
    }
}
else {
    Write-Warning -Message "`tERR: Failed to Microsoft Windows Virtual Desktop Agent Bootloader"
}
#endregion

#region Infra agent
Write-Host "Microsoft WVD Infrastructure Agent"
$App = Get-EvergreenApp -Name "MicrosoftWvdInfraAgent" | Where-Object { $_.Architecture -eq "x64"}
if ($App) {

    # Download
    Write-Host "Downloading Microsoft WVD Infrastructure Agent: $($App.Version)."
    $OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"

    # Install
    <#
    Write-Host "Installing Microsoft WVD Infrastructure Agent"
    try {
        $params = @{
            FilePath     = "$env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        $process = Start-Process @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft WVD Infrastructure Agent."
    }
    Write-Host "Done"
    #>
}
else {
    Write-Warning -Message "`tERR: Failed to retrieve Microsoft WVD Infrastructure Agent"
}
#endregion

# if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft WvdAgents."
#endregion
