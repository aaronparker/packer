#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\OneDrive"
)

#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
Write-Host "Microsoft OneDrive"
$App = Get-EvergreenApp -Name "MicrosoftOneDrive" | Where-Object { $_.Ring -eq "Production" -and $_.Type -eq "Exe" -and $_.Architecture -eq "AMD64" } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1
If ($App) {

    # Download
    $OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"

    # Install
    try {
        Write-Host "`tInstalling Microsoft OneDrive: $($App.Version)."
        $params = @{
            FilePath     = $OutFile.FullName
            ArgumentList = "/silent /ALLUSERS"
            Wait         = $False
            PassThru     = $True
            Verbose      = $True
        }
        $Result = Start-Process @params
        Do {
            Start-Sleep -Seconds 10
        } While (Get-Process -Name "OneDriveSetup" -ErrorAction "SilentlyContinue")
        Get-Process -Name "OneDrive" | Stop-Process -Force -ErrorAction "SilentlyContinue"
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft OneDrive with: $($Result.ExitCode)."
    }
}
Else {
    Write-Warning -Message "`tERR: Failed to retrieve Microsoft OneDrive"
}

# If (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft OneDrive."
#endregion
