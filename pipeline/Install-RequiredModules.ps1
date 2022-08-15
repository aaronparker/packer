<#
    .SYNOPSIS
        Installs modules required for updating the markdown and committing changes
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param ()

#region Trust the PSGallery and install modules
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force
Install-PackageProvider -Name "PowerShellGet" -MinimumVersion "2.2.5" -Force
foreach ($Repository in "PSGallery") {
    if (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
        try {
            Write-Host "Trusting the repository: $Repository."
            Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
        }
        catch {
            $_.Exception.Message
        }
    }
}

foreach ($module in @("MarkdownPS", "powershell-yaml", "posh-git")) {
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
#endregion
