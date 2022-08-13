<#
    .SYNOPSIS
        Installs modules required for updating the markdown and committing changes
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter()]
    [System.String[]] $Modules = @("MarkdownPS", "powershell-yaml", "posh-git")
)

#region Trust the PSGallery and install modules
$Repository = "PSGallery"
if (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
    try {
        Write-Host " Trusting the repository: $Repository."
        Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force
        Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
    }
    catch {
        Throw $_
        break
    }
}

foreach ($module in $Modules) {
    try {
        Write-Host " Checking module: $module."
        $installedModule = Get-Module -Name $module -ListAvailable | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
            Select-Object -First 1
        $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
        if (($Null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
            Write-Host " Installing module: $module"
            $params = @{
                Name               = $module
                SkipPublisherCheck = $true
                Force              = $true
                ErrorAction        = "Stop"
            }
            Install-Module @params
        }
    }
    catch {
        Throw $_
        break
    }
}
#endregion
