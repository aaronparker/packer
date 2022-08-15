#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Downloads / installs the Windows Virtual Desktop agents and services
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\App\Microsoft\Wvd"
)


#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
#region RTC service
Write-Host "Microsoft WvdAgents."
$App = Get-EvergreenApp -Name "MicrosoftWvdRtcService" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $CustomPath -WarningAction "SilentlyContinue"

# Install RTC
Write-Host "Installing Microsoft Remote Desktop WebRTC Redirector Service: $($App.Version)."
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
    Verbose      = $True
}
$result = Start-Process @params
[PSCustomObject]@{
    "Path"     = $OutFile.FullName
    "ExitCode" = $result.ExitCode
}
#endregion

#region Boot Loader
Write-Host "Microsoft Windows Virtual Desktop Agent Bootloader"
$App = Get-EvergreenApp -Name "MicrosoftWvdBootLoader" | Where-Object { $_.Architecture -eq "x64" } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -Path $CustomPath -WarningAction "SilentlyContinue"

# Install
Write-Host "Installing Microsoft Windows Virtual Desktop Agent Bootloader: $($App.Version)."
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet /Log $LogPath"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
    Verbose      = $True
}
$result = Start-Process @params
[PSCustomObject]@{
    "Path"     = $OutFile.FullName
    "ExitCode" = $result.ExitCode
}
#endregion

#region Infra agent
<#
Write-Host "Microsoft WVD Infrastructure Agent"
$App = Get-EvergreenApp -Name "MicrosoftWvdInfraAgent" | Where-Object { $_.Architecture -eq "x64" }
$OutFile = Save-EvergreenApp -InputObject $App -Path $CustomPath -WarningAction "SilentlyContinue"
Write-Host "Installing Microsoft WVD Infrastructure Agent"
$params = @{
    FilePath     = "$env:SystemRoot\System32\msiexec.exe"
    ArgumentList = "/package $($OutFile.FullName) ALLUSERS=1 /quiet"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
    Verbose      = $True
}
Start-Process @params
#>
#endregion

# if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft WvdAgents."
#endregion
