<#
    Windows image preparation and application install
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param()

Set-ExecutionPolicy Bypass -Scope "Process" -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Disable Defender during install for speed
Set-MpPreference -DisableRealtimeMonitoring $true

# Run the script to install applications
$Scripts = @(
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/03_RegionLanguage.ps1",
    "https://stealthpuppy.com/image-customise/Install.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/06_SupportFunctions.ps1",
    "https://vcredist.com/install.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/08_MicrosoftFSLogixApps.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/09_MicrosoftEdge.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/10_Microsoft365Apps.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/11_MicrosoftTeams.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/12_MicrosoftOneDrive.ps1",
    "https://raw.githubusercontent.com/aaronparker/packer/main/build/rds/39_AdobeAcrobatReaderDC.ps1"
)
foreach ($Script in $Scripts) {
    try {
        Invoke-Expression -Command ((New-Object -TypeName "System.Net.WebClient").DownloadString($Script))
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
}

# Re-enable Defender
Set-MpPreference -DisableRealtimeMonitoring $false
