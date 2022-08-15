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
        Verbose     = $True
    }
    $result = Start-Process @params
    [PSCustomObject]@{
        "Path"     = $OutFile.FullName
        "ExitCode" = $result.ExitCode
    }
}
else {
    Write-Host "Citrix VDA not found. Skipping resume."
}
