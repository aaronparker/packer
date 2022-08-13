#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Customise a Windows image for use as an WVD/XenApp VM in Azure.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\image-customise",

    [Parameter(Mandatory = $False)]
    [System.String] $InvokeScript = "Install-Defaults.ps1"
)

#region Script logic
Write-Host " Start: Customise."
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
try {
    $Installer = Get-EvergreenApp -Name "stealthpuppyWindowsCustomisedDefaults" | Where-Object { $_.Type -eq "zip" } | `
        Select-Object -First 1 | `
        Save-EvergreenApp -CustomPath $Path
    Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
    Push-Location -Path $Path
    .\$InvokeScript
    Pop-Location
}
catch {
    Write-Warning -Message " ERR: $($Script.FullName) error with: $($_.Exception.Message)."
}

Write-Host " Complete: Customise."
#endregion
