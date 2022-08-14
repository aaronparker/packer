#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "Outputs progress to the pipeline log")]
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
if ($App) {

    # Download
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install
    try {
        Write-Host "Installing Microsoft OneDrive: $($App.Version)."
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
        Get-Process -Name "OneDrive" -ErrorAction "SilentlyContinue" | Stop-Process -Force -ErrorAction "SilentlyContinue"
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft OneDrive with: $($Result.ExitCode)."
    }
}
else {
    Write-Warning -Message "`tERR: Failed to retrieve Microsoft OneDrive"
}

# if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft OneDrive."
#endregion
