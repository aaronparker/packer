<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param ()

#region Script logic
# Trust the PSGallery for modules
$Repository = "PSGallery"
if (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
    try {
        Write-Host "Trusting the repository: $Repository."
        Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.208 -Force
        Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
    }
    catch {
        $_.Exception.Message
    }
}

# Install the Evergreen module; https://github.com/aaronparker/Evergreen
# Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
foreach ($module in "Evergreen", "VcRedist") {
    Write-Host "Checking module: $module"
    $installedModule = Get-Module -Name $module -ListAvailable -ErrorAction "SilentlyContinue" | `
        Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
        Select-Object -First 1
    $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
    if (($Null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
        Write-Host "Installing module: $module"
        $params = @{
            Name               = $module
            SkipPublisherCheck = $true
            Force              = $true
            ErrorAction        = "Stop"
        }
        Install-Module @params
    }
}

Write-Host "Complete: SupportFunctions."
#endregion
