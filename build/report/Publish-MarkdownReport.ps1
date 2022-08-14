<#
    .SYNOPSIS
        Creates markdown from JSON output generated from Azure DevOps builds
        Uses environment variables created inside the Azure DevOps environment
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter()]
    [System.String] $Path = ([System.IO.Path]::Combine($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "reports")),

    [Parameter()]
    [System.String] $ImagePublisher = $env:IMAGE_PUBLISHER,

    [Parameter()]
    [System.String] $ImageOffer = $env:IMAGE_OFFER,

    [Parameter()]
    [System.String] $ImageSku = $env:IMAGE_SKU,

    [Parameter()]
    [System.String] $Version = $env:CREATED_DATE,

    [Parameter()]
    [System.String] $DestinationPath = ([System.IO.Path]::Combine($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "docs"))
)

# Local testing
#$Path = [System.IO.Path]::Combine("C:\Projects\packer", "docs")
#$OutFile = [System.IO.Path]::Combine("C:\Projects\packer", "docs", "index.md")
#$Path = [System.IO.Path]::Combine("/Users/aaron/Projects/packer/docs", "docs")
#$OutFile = [System.IO.Path]::Combine("/Users/aaron/Projects/packer/docs", "docs", "index.md")

# Output variable values
Write-Host "Path:              $Path."
Write-Host "ImagePublisher:    $ImagePublisher."
Write-Host "ImageOffer:        $ImageOffer."
Write-Host "ImageSku:          $ImageSku."
Write-Host "DestinationPath:   $ImagePublisher."

# Start with a markdown variable
[System.String] $markdown += New-MDHeader -Text $version -Level 1 -NoNewLine
$markdown += "`n`n"

# Read the contents of the output files, convert to markdown
[System.Array] $InputFile = Get-ChildItem -Path $Path -Filter "*.json" | Sort-Object -Descending
foreach ($file in $InputFile) {
    try {
        Write-Host "Reading: $($file.FullName)."
        $table = Get-Content -Path $file.FullName | ConvertFrom-Json
    }
    catch {
        Write-Warning -Message $_.Exception.Message
    }

    if ($table) {
        $markdown += New-MDHeader -Text ($file.Name -replace ".json", "") -Level 2 -NoNewLine
        $markdown += "`n`n"
        $markdown += $table | Sort-Object -Property "Publisher", "Name", "Version" | New-MDTable
        $markdown += "`n"
        Remove-Variable -Name "table" -ErrorAction "SilentlyContinue"
    }
}

# Create the target folder
try {
    $TargetPath = [System.IO.Path]::Combine($DestinationPath, $ImagePublisher, $ImageOffer, $ImageSku)
    New-Item -Path $TargetPath -ItemType "Directory" -Force -ErrorAction "SilentlyContinue" > $Null
}
catch {
    Throw $_
}

# Write the markdown to a file
try {
    $OutFile = Join-Path -Path $TargetPath -ChildPath "$Version.md"
    Write-Host "Writing markdown to: $OutFile."
    ($markdown.TrimEnd("`n")) | Out-File -FilePath $OutFile -Encoding "Utf8" -NoNewline -Force
}
catch {
    Throw $_
}
