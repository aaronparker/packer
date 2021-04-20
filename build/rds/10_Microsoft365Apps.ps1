<# 
    .SYNOPSIS
        Install evergreen core applications.
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $False)]
    [System.String] $LogPath = "$env:SystemRoot\Logs\Packer",

    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Office"
)

#region Script logic
# Set $VerbosePreference so full details are sent to the log; Make Invoke-WebRequest faster
$VerbosePreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
$OfficeXml = @"
<Configuration ID="a39b1c70-558d-463b-b3d4-9156ddbcbb05">
<Add OfficeClientEdition="64" Channel="MonthlyEnterprise" MigrateArch="TRUE">
  <Product ID="O365ProPlusRetail">
    <Language ID="MatchOS" />
    <Language ID="MatchPreviousMSI" />
    <ExcludeApp ID="Access" />
    <ExcludeApp ID="Groove" />
    <ExcludeApp ID="Lync" />
    <ExcludeApp ID="Publisher" />
    <ExcludeApp ID="Bing" />
    <ExcludeApp ID="Teams" />
  </Product>
</Add>
<Property Name="SharedComputerLicensing" Value="0" />
<Property Name="PinIconsToTaskbar" Value="FALSE" />
<Property Name="SCLCacheOverride" Value="0" />
<Property Name="AUTOACTIVATE" Value="0" />
<Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
<Property Name="DeviceBasedLicensing" Value="0" />
<Updates Enabled="FALSE" />
<RemoveMSI />
<AppSettings>
<User Key="software\microsoft\office\16.0\common\toolbars" Name="customuiroaming" Value="1" Type="REG_DWORD" App="office16" Id="L_AllowRoamingQuickAccessToolBarRibbonCustomizations" />
<User Key="software\microsoft\office\16.0\common\general" Name="shownfirstrunoptin" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableOptinWizard" />
<User Key="software\microsoft\office\16.0\common\languageresources" Name="installlanguage" Value="3081" Type="REG_DWORD" App="office16" Id="L_PrimaryEditingLanguage" />
<User Key="software\microsoft\office\16.0\common\fileio" Name="disablelongtermcaching" Value="1" Type="REG_DWORD" App="office16" Id="L_DeleteFilesFromOfficeDocumentCache" />
<User Key="software\microsoft\office\16.0\common\graphics" Name="disablehardwareacceleration" Value="1" Type="REG_DWORD" App="office16" Id="L_DoNotUseHardwareAcceleration" />
<User Key="software\microsoft\office\16.0\common\general" Name="disablebackgrounds" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableBackgrounds" />
<User Key="software\microsoft\office\16.0\firstrun" Name="disablemovie" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableMovie" />
<User Key="software\microsoft\office\16.0\firstrun" Name="bootedrtm" Value="1" Type="REG_DWORD" App="office16" Id="L_DisableOfficeFirstrun" />
<User Key="software\microsoft\office\16.0\common" Name="default ui theme" Value="0" Type="REG_DWORD" App="office16" Id="L_DefaultUIThemeUser" />
<User Key="software\microsoft\office\16.0\excel\options" Name="defaultformat" Value="51" Type="REG_DWORD" App="excel16" Id="L_SaveExcelfilesas" />
<User Key="software\microsoft\office\16.0\onenote\options\other" Name="runsystemtrayapp" Value="0" Type="REG_DWORD" App="onent16" Id="L_AddOneNoteicontonotificationarea" />
<User Key="software\microsoft\office\16.0\outlook\preferences" Name="disablemanualarchive" Value="1" Type="REG_DWORD" App="outlk16" Id="L_DisableFileArchive" />
<User Key="software\microsoft\office\16.0\outlook\options\rss" Name="disable" Value="1" Type="REG_DWORD" App="outlk16" Id="L_TurnoffRSSfeature" />
<User Key="software\microsoft\office\16.0\outlook\setup" Name="disableroamingsettings" Value="0" Type="REG_DWORD" App="outlk16" Id="L_DisableRoamingSettings" />
<User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
<User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
</AppSettings>
<Display Level="None" AcceptEULA="TRUE" />
<Logging Level="Standard" Path="C:\Apps" />
</Configuration>
"@

# Get Office version
Write-Host " Microsoft 365 Apps"
$App = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq "Monthly" }
If ($App) {

    # Download setup.exe
    $OutFile = Save-EvergreenApp -InputObject $App -Path $Path

    try {
        # Download Office package, Setup fails to exit, so wait 9-10 mins for Office install to complete
        Write-Host " Installing Microsoft 365 Apps"
        Push-Location -Path $Path
        $XmlFile = Join-Path -Path $Path -ChildPath "Office.xml"
        Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"

        $params = @{
            FilePath     = $OutFile.Path
            ArgumentList = "/configure $XmlFile"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        $process = Start-Process @params
        
        Pop-Location
    }
    catch {
        Write-Warning -Message " ERR: Failed to install Microsoft 365 Apps."
    }
}
Else {
    Write-Host " Failed to retrieve Microsoft 365 Apps setup."
}

# # If (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host " Complete: Microsoft 365 Apps."
#endregion
