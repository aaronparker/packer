<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $FilePath = "$Env:ProgramData\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"
)

if (Test-Path -Path $FilePath) {
    Write-Host "Citrix VDA found. Starting resume..."
    try {
        $params = @{
            FilePath     = "$Env:ProgramData\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"
            WindowStyle  = "Hidden"
            Wait         = $True
            PassThru     = $True
            Verbose      = $True
        }
        $process = Start-Process @params
    }
    catch {
        if ($process.ExitCode -ne 0) {
            Write-Host "Err: Citrix VDA Setup exited with: $($process.ExitCode)."
        }
        else {
            Write-Host "Citrix VDA Setup exited with: $($process.ExitCode)."
        }
    }
    Write-Host "Citrix VDA resume complete with: $($process.ExitCode)."
}
else {
    Write-Host "Citrix VDA not found. Skipping resume."
}
