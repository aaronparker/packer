<#
    .SYNOPSIS
        Downloads packages from blob storage and applies to the local machine.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter(Mandatory = $False)]
    [System.String] $Path = "$env:SystemDrive\Apps\Packages"
)

#region Functions
function Get-AzureBlobItem {
    <#
        .SYNOPSIS
            Returns an array of items and properties from an Azure blog storage URL.

        .DESCRIPTION
            Queries an Azure blog storage URL and returns an array with properties of files in a Container.
            Requires Public access level of anonymous read access to the blob storage container.
            Works with PowerShell Core.

        .NOTES
            Author: Aaron Parker
            Twitter: @stealthpuppy

        .PARAMETER Url
            The Azure blob storage container URL. The container must be enabled for anonymous read access.
            The URL must include the List Container request URI. See https://docs.microsoft.com/en-us/rest/api/storageservices/list-containers2 for more information.

        .EXAMPLE
            Get-AzureBlobItems -Uri "https://aaronparker.blob.core.windows.net/folder/?comp=list"

            Description:
            Returns the list of files from the supplied URL, with Name, URL, Size and Last Modified properties for each item.
    #>
    [CmdletBinding(SupportsShouldProcess = $False)]
    [OutputType([System.Management.Automation.PSObject])]
    param (
        [Parameter(ValueFromPipeline = $True, Mandatory = $True, HelpMessage = "Azure blob storage URL with List Containers request URI '?comp=list'.")]
        [ValidatePattern("^(http|https)://")]
        [System.String] $Uri
    )

    begin {}
    process {

        # Get response from Azure blog storage; Convert contents into usable XML, removing extraneous leading characters
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            $iwrParams = @{
                Uri             = $Uri
                UseBasicParsing = $True
                ContentType     = "application/xml"
                ErrorAction     = "Stop"
            }
            $list = Invoke-WebRequest @iwrParams
        }
        catch [System.Exception] {
            Write-Warning -Message "$($MyInvocation.MyCommand): failed to download: $Uri."
            Throw $_.Exception.Message
        }
        if ($Null -ne $list) {
            [System.Xml.XmlDocument] $xml = $list.Content.Substring($list.Content.IndexOf("<?xml", 0))

            # Build an object with file properties to return on the pipeline
            $fileList = New-Object -TypeName System.Collections.ArrayList
            foreach ($node in (Select-Xml -XPath "//Blobs/Blob" -Xml $xml).Node) {
                $PSObject = [PSCustomObject] @{
                    Name         = ($node | Select-Object -ExpandProperty Name)
                    Url          = ($node | Select-Object -ExpandProperty Url)
                    Size         = ($node | Select-Object -ExpandProperty Size)
                    LastModified = ($node | Select-Object -ExpandProperty LastModified)
                }
                $fileList.Add($PSObject) > $Null
            }
            if ($Null -ne $fileList) {
                Write-Output -InputObject $fileList
            }
        }
    }
    end {}
}

function Install-LanguageCapability ($Locale) {
    switch ($Locale) {
        "en-US" {
            # United States
            $Language = "en-US"
        }
        "en-GB" {
            # Great Britain
            $Language = "en-GB"
        }
        "en-AU" {
            # Australia
            $Language = "en-AU", "en-GB"
        }
        Default {
            # Australia
            $Language = "en-AU", "en-GB"
        }
    }

    # Install Windows capability packages using Windows Update
    foreach ($lang in $Language) {
        Write-Verbose -Message "$($MyInvocation.MyCommand): Adding packages for [$lang]."
        $Capabilities = Get-WindowsCapability -Online | Where-Object { $_.Name -like "Language*$lang*" }
        foreach ($Capability in $Capabilities) {
            try {
                Add-WindowsCapability -Online -Name $Capability.Name -LogLevel 2
            }
            catch {
                Write-Warning -Message " ERR: Failed to add capability: $($Capability.Name)."
            }
        }
    }
}

function Install-ImagePackage ($Path, $PackagesUrl) {

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Get the list of items from blob storage
    try {
        $Items = Get-AzureBlobItem -Uri "$($PackagesUrl)?comp=list" | Where-Object { $_.Name -match "zip?" }
    }
    catch {
        Write-Warning -Message " ERR: Failed to retrieve items from: [$PackagesUrl]."
    }

    foreach ($item in $Items) {
        $AppName = $item.Name -replace ".zip"
        $AppPath = Join-Path -Path $Path -ChildPath $AppName
        if (!(Test-Path $AppPath)) { New-Item -Path $AppPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null }

        Write-Host "Downloading item: [$($item.Url)]."
        $OutFile = Join-Path -Path $Path -ChildPath (Split-Path -Path $item.Url -Leaf)
        try {
            Invoke-WebRequest -Uri $item.Url -OutFile $OutFile -UseBasicParsing
        }
        catch {
            Write-Host "Failed to download: $($item.Url)."
            break
        }
        Expand-Archive -Path $OutFile -DestinationPath $AppPath -Force
        Remove-Item -Path $OutFile -Force -ErrorAction SilentlyContinue

        Write-Host "Installing item: $($AppName)."
        Push-Location $AppPath
        Get-ChildItem -Path $AppPath -Recurse | Unblock-File
        . .\Install.ps1
        Pop-Location
    }
}
#endregion


#region Script logic
# Make Invoke-WebRequest faster
$ProgressPreference = "SilentlyContinue"

# Create target folder
New-Item -Path $Path -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null

# Run tasks
Install-ImagePackage -Path $Path -PackagesUrl $Env:PackagesUrl
Write-Host "Complete: Packages."
