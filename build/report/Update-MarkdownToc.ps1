<#
    .SYNOPSIS
        Updates the doc/index.md table of contents
        Uses environment variables created inside the Azure DevOps environment
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "", Justification="Outputs progress to the pipeline log")]
[CmdletBinding()]
param (
    [Parameter()]
    [System.String] $Path = [System.IO.Path]::Combine($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "docs"),

    [Parameter()]
    [System.String] $Index = "index.md",

    [Parameter()]
    [System.String] $OutFile = [System.IO.Path]::Combine($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "docs", $Index)
)

# Local testing
#$Path = [System.IO.Path]::Combine("C:\Projects\packer", "docs")
#$OutFile = [System.IO.Path]::Combine("C:\Projects\packer", "docs", "index.md")
#$Path = [System.IO.Path]::Combine("/Users/aaron/Projects/packer/docs", "docs")
#$OutFile = [System.IO.Path]::Combine("/Users/aaron/Projects/packer/docs", "docs", "index.md")

Write-Host "Input: $Path."
Write-Host "Output: $OutFile."

# Start with a blank markdown variable
Remove-Variable -Name "markdown" -ErrorAction "SilentlyContinue"
[System.String] $markdown

# Get a listing of files in the /docs folder
$params = @{
    Path      = $Path
    Directory = $true
    Recurse   = $false
}
Write-Host "Get directory: $($Path)."
$Level1Directories = Get-ChildItem @params

# There's a better way to do this, but this works for now
foreach ($Level1Dir in $Level1Directories) {
    Write-Host "Add header: $($Level1Dir.FullName)."
    $markdown += New-MDHeader -Text $Level1Dir.BaseName -Level 1
    $markdown += "`n"

    $params = @{
        Path      = $Level1Dir.FullName
        Directory = $true
        Recurse   = $false
    }
    Write-Host "Get directory: $($Level1Dir.FullName)."
    $Level2Directories = Get-ChildItem @params

    foreach ($Level2Dir in $Level2Directories) {
        Write-Host "Add header: $($Level2Dir.FullName)."
        $markdown += New-MDHeader -Text $Level2Dir.BaseName -Level 2
        $markdown += "`n"

        $params = @{
            Path      = $Level2Dir.FullName
            Directory = $true
            Recurse   = $false
        }
        Write-Host "Get directory: $($Level2Dir.FullName)."
        $Level3Directories = Get-ChildItem @params

        foreach ($Level3Dir in $Level3Directories) {
            Write-Host "Add header: $($Level3Dir.FullName)."
            $markdown += New-MDHeader -Text $Level3Dir.BaseName -Level 3
            $markdown += "`n"

            $params = @{
                Path   = $Level3Dir.FullName
                Filter = "*.md"
            }
            Write-Host "Get reports: $($Level3Dir.FullName)."
            $Reports = Get-ChildItem @params

            foreach ($report in $Reports) {

                # Create a link to the report, replacing \ if we're running on Windows
                Write-Host "Add report: $($report.FullName)."
                $params = @{
                    Text      = $report.BaseName
                    Link      = ($report.FullName -replace [Regex]::Escape($Path), "") -replace "\\", "/"
                }
                $Link = New-MDLink @params
                $markdown += New-MDList -Lines $Link -Style "Unordered" -NoNewLine
            }
            $markdown += "`n"
        }
    }
}

# Write the markdown to a file
try {
    Write-Host "Writing markdown to: $OutFile."
    ($markdown.TrimEnd("`n")) | Out-File -FilePath $OutFile -Encoding "Utf8" -NoNewLine -Force
}
catch {
    Throw $_
}
