#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $LogPath = "$env:SystemRoot\Logs\M365Apps",

    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Office",

    [Parameter(Mandatory = $False)]
    [ValidateSet("BetaChannel", "CurrentPreview", "Current", "MonthlyEnterprise", "PerpetualVL2021", "SemiAnnualPreview", "SemiAnnual", "PerpetualVL2019")]
    [System.String] $Channel = "Current"
)

#region Script logic

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
New-Item -Path $LogPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
$OfficeXml = @"
<Configuration ID="a39b1c70-558d-463b-b3d4-9156ddbcbb05">
    <Add OfficeClientEdition="64" Channel="$Channel" MigrateArch="TRUE">
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
        <User Key="software\microsoft\office\16.0\outlook\options\rss" Name="disable" Value="1" Type="REG_DWORD" App="outlk16" Id="L_TurnoffRSSfeature" />
        <User Key="software\microsoft\office\16.0\outlook\setup" Name="disableroamingsettings" Value="0" Type="REG_DWORD" App="outlk16" Id="L_DisableRoamingSettings" />
        <User Key="software\microsoft\office\16.0\powerpoint\options" Name="defaultformat" Value="27" Type="REG_DWORD" App="ppt16" Id="L_SavePowerPointfilesas" />
        <User Key="software\microsoft\office\16.0\word\options" Name="defaultformat" Value="" Type="REG_SZ" App="word16" Id="L_SaveWordfilesas" />
    </AppSettings>
    <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

# Get Office version
Write-Host "Microsoft 365 Apps: $Channel"
$App = Get-EvergreenApp -Name "Microsoft365Apps" | Where-Object { $_.Channel -eq $Channel } | Select-Object -First 1
$OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

# Download Office package, Setup fails to exit, so wait 9-10 mins for Office install to complete
Write-Host "Installing Microsoft 365 Apps: $($App.Version)."
$XmlFile = Join-Path -Path $Path -ChildPath "Office.xml"
Out-File -FilePath $XmlFile -InputObject $OfficeXml -Encoding "utf8"

$params = @{
    FilePath     = $OutFile.FullName
    ArgumentList = "/configure $XmlFile"
    NoNewWindow  = $True
    Wait         = $True
    PassThru     = $True
    Verbose      = $True
}
Push-Location -Path $Path
$result = Start-Process @params
[PSCustomObject]@{
    "Path"     = $OutFile.FullName
    "ExitCode" = $result.ExitCode
}
Pop-Location

# # if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft 365 Apps."
#endregion
