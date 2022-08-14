#Requires -Modules Evergreen
<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Teams"
)

#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks/install apps
Write-Host "Microsoft Teams"
$App = Get-EvergreenApp -Name "MicrosoftTeams" | Where-Object { $_.Architecture -eq "x64" -and $_.Ring -eq "General" -and $_.Type -eq "msi" } | Select-Object -First 1
if ($App) {

    # Download
    $OutFile = Save-EvergreenApp -InputObject $App -CustomPath $Path -WarningAction "SilentlyContinue"

    # Install
    try {
        Write-Host "Installing Microsoft Teams: $($App.Version)."
        REG add "HKLM\SOFTWARE\Microsoft\Teams" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f 2> $Null
        REG add "HKLM\SOFTWARE\Citrix\PortICA" /v "IsWVDEnvironment" /t REG_DWORD /d 1 /f 2> $Null

        $params = @{
            FilePath     = "$env:SystemRoot\System32\msiexec.exe"
            ArgumentList = "/package $($OutFile.FullName) OPTIONS=`"noAutoStart=true`" ALLUSER=1 ALLUSERS=1 /quiet"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        $Result = Start-Process @params
    }
    catch {
        Write-Warning -Message "`tERR: Failed to install Microsoft Teams with: $($Result.ExitCode)."
    }
}
else {
    Write-Host "Failed to retrieve Microsoft Teams."
}

# Teams JSON files
$ConfigFiles = @((Join-Path -Path "${env:ProgramFiles(x86)}\Teams Installer" -ChildPath "setup.json"),
    (Join-Path -Path "${env:ProgramFiles(x86)}\Microsoft\Teams" -ChildPath "setup.json"))

# Read the file and convert from JSON
foreach ($Path in $ConfigFiles) {
    if (Test-Path -Path $Path) {
        try {
            $Json = Get-Content -Path $Path | ConvertFrom-Json
            $Json.noAutoStart = $true
            $Json | ConvertTo-Json | Set-Content -Path $Path -Force
        }
        catch {
            Write-Warning -Message "`tERR: Failed to set Teams autostart file: $Path."
        }
    }
}

# Delete the registry auto-start
REG delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run" /v "Teams" /f 2> $Null

# if (Test-Path -Path $Path) { Remove-Item -Path $Path -Recurse -Confirm:$False -ErrorAction "SilentlyContinue" }
Write-Host "Complete: Microsoft Teams."
#endregion
