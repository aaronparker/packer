<#
    .SYNOPSIS
        Use Pester and Evergreen to validate installed apps.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
param()

BeforeDiscovery {
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
}

# Per script tests
Describe -Name "Validate script <Script>" -ForEach $Scripts {
    BeforeAll {

        # Get details for the current application
        $Script = $_
    }

    Context "Validate <Script> exists" {
        It "Should be a valid URL" {
            { try { $r = (New-Object -TypeName "System.Net.WebClient").DownloadString($Script) } catch { throw $_.Exception.Message } } | Should -Not -Throw
        }
    }
}
