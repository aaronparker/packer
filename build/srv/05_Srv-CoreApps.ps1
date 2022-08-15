<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps"
)

#region Functions
function Install-RequiredModule {
    Write-Host "Installing required modules"
    # Install the Evergreen module; https://github.com/aaronparker/Evergreen
    Install-Module -Name Evergreen -AllowClobber

    # Install the VcRedist module; https://docs.stealthpuppy.com/vcredist/
    Install-Module -Name VcRedist -AllowClobber
}

function Install-VcRedistributable ($Path) {
    Write-Host "Microsoft Visual C++ Redistributables"
    if (!(Test-Path $Path)) { New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null }
    $VcList = Get-VcList -Release 2010, 2012, 2013, 2019

    Save-VcRedist -Path $Path -VcList $VcList
    Install-VcRedist -VcList $VcList -Path $Path
    Write-Host "Done"
}

function Install-MicrosoftEdge ($Path) {
    Write-Host "Microsoft Edge"
    $App = Get-EvergreenApp -Name "MicrosoftEdge" | Where-Object { $_.Architecture -eq "x64" -and $_.Channel -eq "Stable" -and $_.Release -eq "Enterprise" } `
    | Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | Select-Object -First 1

    if ($App) {
        Write-Host "Downloading Microsoft Edge"
        if (!(Test-Path $Path)) { New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null }

        # Download
        Write-Host "Downloading Microsoft Edge"
        $OutFile = Save-EvergreenApp -InputObject $App -Path $Path -WarningAction "SilentlyContinue"

        # Install
        Write-Host "Installing Microsoft Edge"
        try {
            $params = @{
                FilePath     = "$env:SystemRoot\System32\msiexec.exe"
                ArgumentList = "/package $($OutFile.FullName) /quiet /norestart DONOTCREATEDESKTOPSHORTCUT=true"
                NoNewWindow  = $True
                Wait         = $True
                Verbose      = $True
            }
            Start-Process @params
        }
        catch {
            Write-Warning -Message " ERR: Failed to install Microsoft Edge."
        }

        Write-Host "Post-install config"
        $prefs = @{
            "homepage"               = "edge://newtab"
            "homepage_is_newtabpage" = $false
            "browser"                = @{
                "show_home_button" = true
            }
            "distribution"           = @{
                "skip_first_run_ui"              = $True
                "show_welcome_page"              = $False
                "import_search_engine"           = $False
                "import_history"                 = $False
                "do_not_create_any_shortcuts"    = $False
                "do_not_create_taskbar_shortcut" = $False
                "do_not_create_desktop_shortcut" = $True
                "do_not_launch_chrome"           = $True
                "make_chrome_default"            = $True
                "make_chrome_default_for_user"   = $True
                "system_level"                   = $True
            }
        }
        $prefs | ConvertTo-Json | Set-Content -Path "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\master_preferences" -Force
        $services = "edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService"
        foreach ($service in $services) { Get-Service -Name $service | Set-Service -StartupType "Disabled" }
        foreach ($task in (Get-ScheduledTask -TaskName *Edge*)) { Unregister-ScheduledTask -TaskName $Task -Confirm:$False -ErrorAction SilentlyContinue }
        Remove-Variable -Name url
        Write-Host "Done"
    }
    else {
        Write-Host "Failed to retrieve Microsoft Edge"
    }
}
#endregion Functions


#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

if (!(Test-Path $Path)) { New-Item -Path $Path -Type Directory -Force -ErrorAction SilentlyContinue }

# Set TLS to 1.2; Create target folder
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
# Trust the PSGallery for modules
if (Get-PSRepository | Where-Object { $_.Name -eq "PSGallery" -and $_.InstallationPolicy -ne "Trusted" }) {
    Write-Verbose "Trusting the repository: PSGallery"
    Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.208 -Force
    Set-PSRepository -Name "PSGallery" -InstallationPolicy "Trusted"
}

Install-RequiredModule
Install-VcRedistributable -Path "$Path\VcRedist"
Install-MicrosoftEdge -Path "$Path\Edge"
Write-Host "Complete: $($MyInvocation.MyCommand)."
#endregion
