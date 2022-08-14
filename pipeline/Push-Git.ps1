<#
    .SYNOPSIS
        Pushes commits back to GitHub
        Uses environment variables created inside the Azure DevOps environment
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [System.String] $GitHubKey
)

Write-Host "GitHubKey:"
Write-Host "##vso[task.setvariable variable=GitHubKey]$GitHubKey"


#region Functions
function Invoke-Process {
    <#PSScriptInfo
        .VERSION 1.4
        .GUID b787dc5d-8d11-45e9-aeef-5cf3a1f690de
        .AUTHOR Adam Bertram
        .COMPANYNAME Adam the Automator, LLC
        .TAGS Processes
    #>
    <#
    .DESCRIPTION
        Invoke-Process is a simple wrapper function that aims to "PowerShellyify" launching typical external processes. There
        are lots of ways to invoke processes in PowerShell with Start-Process, Invoke-Expression, & and others but none account
        well for the various streams and exit codes that an external process returns. Also, it's hard to write good tests
        when launching external process.

        This function ensures any errors are sent to the error stream, standard output is sent via the Output stream and any
        time the process returns an exit code other than 0, treat it as an error.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String] $FilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String] $ArgumentList
    )

    $ErrorActionPreference = 'Stop'

    try {
        $stdOutTempFile = "$env:TEMP\$((New-Guid).Guid)"
        $stdErrTempFile = "$env:TEMP\$((New-Guid).Guid)"

        $startProcessParams = @{
            FilePath               = $FilePath
            ArgumentList           = $ArgumentList
            RedirectStandardError  = $stdErrTempFile
            RedirectStandardOutput = $stdOutTempFile
            Wait                   = $true;
            PassThru               = $true;
            NoNewWindow            = $true;
        }
        if ($PSCmdlet.ShouldProcess("Process [$($FilePath)]", "Run with args: [$($ArgumentList)]")) {
            $cmd = Start-Process @startProcessParams
            $cmdOutput = Get-Content -Path $stdOutTempFile -Raw
            $cmdError = Get-Content -Path $stdErrTempFile -Raw
            if ($cmd.ExitCode -ne 0) {
                if ($cmdError) {
                    throw $cmdError.Trim()
                }
                if ($cmdOutput) {
                    throw $cmdOutput.Trim()
                }
            }
            else {
                if ([System.String]::IsNullOrEmpty($cmdOutput) -eq $false) {
                    Write-Output -InputObject $cmdOutput
                }
            }
        }
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore
    }
}
#endregion


# Publish the new version back to main on GitHub
Try {
    Push-Location -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY

    # Set up a path to the git.exe cmd, import posh-git to give us control over git
    $env:Path += ";$env:ProgramFiles\Git\cmd"
    Import-Module -Name "posh-git" -ErrorAction "Stop"

    # Branch to use
    $branch = "main"

    # Configure the git environment
    git config --global credential.helper store
    Add-Content -Path (Join-Path -Path $env:USERPROFILE -ChildPath ".git-credentials") -Value "https://$($GitHubKey):x-oauth-basic@github.com`n"
    git config --global user.email "$($env:GitHubUserEmail)"
    git config --global user.name "$($env:GitHubUserName)"
    git config --global core.autocrlf true
    git config --global core.safecrlf false

    # Update the local repo in case anything has changed on the remote during the build
    git fetch origin

    # Push changes to GitHub
    Invoke-Process -FilePath "git" -ArgumentList "checkout $branch"
    git add --all
    git status
    git commit -s -m "Docs update: $($env:CREATED_DATE)"
    Invoke-Process -FilePath "git" -ArgumentList "push origin $branch"
    Write-Host "== Updates pushed to GitHub." -ForegroundColor Cyan
}
Catch {
    # Sad panda; it broke
    Write-Warning -Message "== Push to GitHub failed."
    Throw $_
}
finally {
    Pop-Location
}
