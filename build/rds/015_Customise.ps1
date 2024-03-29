#description: Installs Windows Customised Defaults to customise the image and the default profile
#execution mode: Combined
#tags: Evergreen, Customisation, Language, Image
#Requires -Modules Evergreen
[System.String] $Path = "$env:SystemDrive\Apps\image-customise"

#region Use Secure variables in Nerdio Manager to pass variables
if ($null -eq $SecureVars.OSLanguage) {
    [System.String] $Language = "en-AU"
}
else {
    [System.String] $Language = $SecureVars.OSLanguage
}

if ($null -eq $SecureVars.AppxMode) {
    $AppxMode = "Block"
}
else {
    $AppxMode = $SecureVars.AppxMode
}
#endregion

#region Script logic
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" | Out-Null

try {
    $Installer = Invoke-EvergreenApp -Name "stealthpuppyWindowsCustomisedDefaults" | Where-Object { $_.Type -eq "zip" } | `
        Select-Object -First 1 | `
        Save-EvergreenApp -CustomPath $Path
    Expand-Archive -Path $Installer.FullName -DestinationPath $Path -Force
    Push-Location -Path $Path
    . .\Install-Defaults.ps1 -Language $Language -AppxMode $AppxMode
    Pop-Location
}
catch {
    throw $_.Exception.Message
}
finally {
    Pop-Location
}
#endregion
