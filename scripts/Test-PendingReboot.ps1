function Test-PendingReboot {
    <#
        .SYNOPSIS
            Tests for pending reboot on Windows

        .NOTES
            Author: Darwin Sanoy
            URL: https://github.com/DarwinJS/DevOpsAutomationCode/blob/main/CompactDevOpsRebootWindowsIfNeeded.ps1
    #>
    [OutputType([Boolean])]
    [CmdletBinding()]
    param ()

    return ([bool]((Get-ItemProperty "hklm:SYSTEM\CurrentControlSet\Control\Session Manager").RebootPending) -or
        [bool]((Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update").RebootRequired) -or
        [bool]((Get-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Control\Session Manager").PendingFileRenameOperations) -or

        # Computer Rename pending
        ((Get-ItemProperty 'HKLM:SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\' | `
                Select-Object -Expand 'ComputerName') -ine (Get-ItemProperty 'HKLM:SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\' | `
                Select-Object -Expand 'ComputerName')) -or

        # Domain Join Pending
        ((Test-Path "HKLM:SYSTEM\CurrentControlSet\Services\Netlogon\JoinDomain") -or (Test-Path "HKLM:SYSTEM\CurrentControlSet\Services\Netlogon\AvoidSpnSet"))) -or

    # WindowsFeature install or uninstall has a pending reboot
    ((Test-Path c:\windows\winsxs\pending.xml) -and ([bool](Get-Content c:\windows\winsxs\pending.xml | Select-String 'postAction="reboot"')))
}
