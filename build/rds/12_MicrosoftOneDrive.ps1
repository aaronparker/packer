#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\OneDrive"
)

#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
Write-Host "Microsoft OneDrive"
$App = Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Ring -eq "Production" -and $_.Type -eq "Exe" -and $_.Architecture -eq "AMD64" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Install
Write-Host "Installing Microsoft OneDrive: $($App.Version)."
$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/silent /ALLUSERS"
    Wait         = $False
    PassThru     = $True
    Verbose      = $True
}
$result = Start-Process @params
do {
    Start-Sleep -Seconds 10
} while (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | Stop-Process -Force -ErrorAction "SilentlyContinue"
[PSCustomObject]@{
    "Path"     = $OutFile.FullName
    "ExitCode" = $result.ExitCode
}

# if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft OneDrive."
#endregion
