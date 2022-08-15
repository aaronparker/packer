<#
    .SYNOPSIS
        Install evergreen core applications.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification = "Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $FilePath = "$Env:ProgramData\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"
)

if (Test-Path -Path $FilePath) {
    Write-Host "Citrix VDA found. Starting resume..."
    $params = @{
        FilePath    = "$Env:ProgramData\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"
        NoNewWindow = $True
        Wait        = $True
        PassThru    = $True
    }
    $result = Start-Process @params
    $Output = [PSCustomObject]@{
        Path     = "$Env:ProgramData\Citrix\XenDesktopSetup\XenDesktopVdaSetup.exe"
        ExitCode = $result.ExitCode
    }
    Write-Host -InputObject $Output
}
else {
    Write-Host "Citrix VDA not found. Skipping resume."
}
