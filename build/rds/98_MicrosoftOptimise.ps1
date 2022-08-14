<#
    .SYNOPSIS
        Optimise and seal a Windows image.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Microsoft\Optimise"
)

#region Individual optimisation functions
function Invoke-WindowsDefender {
    # Run Windows Defender quick scan
    Write-Host "Running Windows Defender"
    Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-SignatureUpdate -MMPC" -Wait
    Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -ScanType 1" -Wait
    # Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RemovalTools\MRT" -Name "GUID" -Value ""
}

function Disable-ScheduledTask {
    <#
        - NOTE:           Original script details here:
        - TITLE:          Microsoft Windows 1909  VDI/WVD Optimization Script
        - AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft Premier Services)
        - AUTHORED DATE:  11/19/2019
        - LAST UPDATED:   04/10/2020
        - PURPOSE:        To automatically apply setting referenced in white paper:
                        "Optimizing Windows 10, Build 1909, for a Virtual Desktop Infrastructure (VDI) role"
                        URL: TBD

        - REFERENCES:
        https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
        https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
        https://msdn.microsoft.com/en-us/library/cc422938.aspx
    #>

    #region Disable Scheduled Tasks
    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # comment or delete from the "SchTaskList.txt" file.
    Write-Host "Disabling scheduled tasks."

    # Original list
    $SchTasksList = @("BgTaskRegistrationMaintenanceTask", "Consolidator", "Diagnostics", "FamilySafetyMonitor",
        "FamilySafetyRefreshTask", "MapsToastTask", "*Compatibility*", "Microsoft-Windows-DiskDiagnosticDataCollector",
        "*MNO*", "NotificationTask", "PerformRemediation", "ProactiveScan", "ProcessMemoryDiagnosticEvents", "Proxy",
        "QueueReporting", "RecommendedTroubleshootingScanner", "ReconcileLanguageResources", "RegIdleBackup",
        "RunFullMemoryDiagnostic", "Scheduled", "ScheduledDefrag", "SilentCleanup", "SpeechModelDownloadTask",
        "Sqm-Tasks", "SR", "StartupAppTask", "SyspartRepair", "UpdateLibrary", "WindowsActionDialog", "WinSAT",
        "XblGameSaveTask")

    # Safe list - WVD VMs aren't really non-persistent
    $SchTasksList = @("BgTaskRegistrationMaintenanceTask", "Consolidator", "Diagnostics", "FamilySafetyMonitor",
        "FamilySafetyRefreshTask", "MapsToastTask", "MNO Metadata Parser", "NotificationTask",
        "ProcessMemoryDiagnosticEvents", "Proxy", "QueueReporting", "RecommendedTroubleshootingScanner",
        "RegIdleBackup", "RunFullMemoryDiagnostic", "ScheduledDefrag", "Scheduled", "ScheduledDefrag",
        "SR", "StartupAppTask", "SyspartRepair", "WindowsActionDialog", "WinSAT", "XblGameSaveTask")
    if ($SchTasksList.count -gt 0) {
        $EnabledScheduledTasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }
        Foreach ($Item in $SchTasksList) {
            $Task = (($Item -split ":")[0]).Trim()
            $EnabledScheduledTasks | Where-Object { $_.TaskName -like "*$Task*" } | Disable-ScheduledTask -ErrorAction "SilentlyContinue"
        }
    }
    #endregion
}

function Disable-WindowsTrace {
    #region Disable Windows Traces
    Write-Host "Disabling Windows traces."
    $DisableAutologgers = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AppModel\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\CloudExperienceHostOOBE\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WDIContextLog\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WiFiDriverIHVSession\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WiFiSession\",
        "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\WinPhoneCritical\")
    if ($DisableAutologgers.count -gt 0) {
        Foreach ($Item in $DisableAutologgers) {
            New-ItemProperty -Path "$Item" -Name "Start" -PropertyType "DWORD" -Value "0" -Force -ErrorAction "SilentlyContinue"
        }
    }
    #endregion
}

function Disable-Service {
    #region Disable Services
    #################### BEGIN: DISABLE SERVICES section ###########################
    Write-Host "Disabling services."
    $ServicesToDisable = @("autotimesvc", "BcastDVRUserService", "CDPSvc", "CDPUserSvc", "CscService",
        "defragsvc", "DiagTrack", "DsmSvc", "DusmSvc", "icssvc", "lfsvc", "MapsBroker",
        "MessagingService", "OneSyncSvc", "PimIndexMaintenanceSvc", "Power", "SEMgrSvc", "SmsRouter",
        "SysMain", "TabletInputService", "UsoSvc", "WerSvc", "XblAuthManager",
        "XblGameSave", "XboxGipSvc", "XboxNetApiSvc", "AdobeARMservice")
    if ($ServicesToDisable.count -gt 0) {
        Foreach ($Item in $ServicesToDisable) {
            $service = Get-Service -Name $Item -ErrorAction "SilentlyContinue"
            Write-Host "Disabling service: $($service.DisplayName)."
            $service | Set-Service -StartupType "Disabled" -ErrorAction "SilentlyContinue"
        }
    }
    #endregion
}

function Disable-SystemRestore {
    Disable-ComputerRestore -Drive "$($env:SystemDrive)\" -ErrorAction "SilentlyContinue"
}

function Optimize-Network {
    #region Network Optimization
    # LanManWorkstation optimizations
    Write-Host "Network optimisations."
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DisableBandwidthThrottling" -PropertyType "DWORD" -Value "1" -Force
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "FileInfoCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DirectoryCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "FileNotFoundCacheEntriesMax" -PropertyType "DWORD" -Value "1024" -Force
    New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\" -Name "DormantFileLimit" -PropertyType "DWORD" -Value "256" -Force

    # NIC Advanced Properties performance settings for network biased environments
    # Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB
    <#
        Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
        by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
        Set-NetAdapterAdvancedProperty command.
    #>
    #endregion
}

function Invoke-Cleanmgr {
    #region Disk Cleanup
    # Disk Cleanup Wizard automation (Cleanmgr.exe /SAGESET:11)
    # If you prefer to skip a particular disk cleanup category, edit the "Win10_1909_DiskCleanRegSettings.txt"
    Write-Host "Cleanmgr."
    $DiskCleanupSettings = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders\",
        #"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Diagnostic Data Viewer database files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files\",
        #"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\RetailDemo Offline Content\",
        #"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache\",
        #"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files\",
        #"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files\",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files\")
    if ($DiskCleanupSettings.count -gt 0) {
        Foreach ($Item in $DiskCleanupSettings) {
            New-ItemProperty -Path "$Item" -Name "StateFlags0011" -PropertyType "DWORD" -Value "2" -Force -ErrorAction "SilentlyContinue"
        }
    }
    Write-Host "Running Disk Cleanup"
    Start-Process "$env:SystemRoot\System32\Cleanmgr.exe" -ArgumentList "SAGERUN:11" -Wait
    #endregion
}

function Remove-TempFile {
    #region
    # ADDITIONAL DISK CLEANUP
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx (not in use==not needed)

    Write-Host "Remove temp files."
    $FilesToRemove = Get-ChildItem -Path "$env:SystemDrive\" -Include *.tmp, *.etl, *.evtx -Recurse -Force -ErrorAction SilentlyContinue
    $FilesToRemove | Remove-Item -ErrorAction "SilentlyContinue"

    # Delete not in-use anything in the C:\Windows\Temp folder
    Write-Host "Clean $env:SystemRoot\Temp."
    Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction "SilentlyContinue"

    # Delete not in-use anything in your %temp% folder
    Write-Host "Clean $env:Temp."
    Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction "SilentlyContinue"
    #endregion
}

function Global:Clear-WinEvent {
    [CmdletBinding(SupportsShouldProcess = $True)]
    param ([System.String] $LogName)
    Process {
        if ($PSCmdlet.ShouldProcess("$LogName", "Clear event log")) {
            try {
                [System.Diagnostics.Eventing.Reader.EventLogSession]::GlobalSession.ClearLog("$LogName")
            }
            catch {
                Write-Error -Message "Failed to clear log: $LogName."
            }
        }
    }
}
#endregion

#region
function MicrosoftOptimizer {
    # https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
    $Url = "https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip"
    $Path = Join-Path -Path $Path -ChildPath "VirtualDesktopOptimizationTool"
    New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
    $OutFile = Join-Path -Path $Path -ChildPath (Split-Path -Path $Url -Leaf)
    try {
        $params = @{
            Uri             = $Url
            UseBasicParsing = $true
            OutFile         = $OutFile
        }
        Invoke-WebRequest @params
    }
    catch {
        Write-Warning -Message " ERR: Failed to download with: $($_.Exception.Message)."
    }
    try {
        $params = @{
            Path        = $OutFile
            Destination = $Path
            Force       = $true
        }
        Expand-Archive @params
    }
    catch {
        Write-Warning -Message " ERR: Failed to expand archive with: $($_.Exception.Message)."
    }
    try {
        Push-Location -Path $Path
        . .\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -AppxPackages:$False -Restart:$False -Verbose
        Pop-Location
    }
    catch {
        Write-Warning -Message " ERR: Failed to run with: $($_.Exception.Message)."
    }
}
#endregion


#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

# Set TLS to 1.2; Create target folder
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

#region Manual seal image tasks
Invoke-WindowsDefender
Disable-ScheduledTask
Disable-WindowsTrace
Disable-SystemRestore
Disable-Service
Optimize-Network
# Invoke-Cleanmgr
Remove-TempFile
Get-WinEvent -ListLog * | ForEach-Object { Clear-WinEvent $_.LogName -Confirm:$False }
#endregion

#region Virtual-Desktop-Optimization-Tool
# MicrosoftOptimizer
#endregion

Write-Host "Complete: OptimiseImage."
#endregion
