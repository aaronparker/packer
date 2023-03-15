#description: Installs the supported Microsoft Visual C++ Redistributables
#execution mode: Combined
#tags: VcRedist, Microsoft
#Requires -Modules VcRedist
[System.String] $Path = "$env:SystemDrive\Apps\Microsoft\VcRedist"

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

# Run tasks/install apps
try {
    Write-Information -MessageData ":: Install Microsoft Visual C++ Redistributables" -InformationAction "Continue"
    Import-Module -Name "VcRedist" -Force
    Get-VcList | Save-VcRedist -Path $Path | Install-VcRedist -Silent | Out-Null
}
catch {
    throw $_.Exception.Message
}
#endregion
