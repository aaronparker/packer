[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding()]
param()

# irm -Uri "https://api.uupdump.net/listlangs.php"
# irm -Uri "https://api.uupdump.net/listeditions.php"
# "https://api.uupdump.net/listid.php?sortByDate=true"

$Build = "19044"
$Architecture = "amd64"
$TitleString = "Feature update"
$r = Invoke-RestMethod -Uri "https://api.uupdump.net/listid.php"
$Uuid = $r.response.builds | Where-Object { $_.build -match $Build -and $_.arch -eq $Architecture <#-and $_.title -match $TitleString#> } | `
    Sort-Object -Property @{ Expression = { [System.Version]$_.build }; Descending = $true } | `
    Select-Object -First 1 -ExpandProperty "uuid"

$language = "en-gb"
$edition = "professional"
$r = Invoke-RestMethod -Uri "https://api.uupdump.net/get.php?id=$uuid&lang=$language&edition=$edition"

$LanguageFiles = $r.response.files[0].PsObject.properties | Where-Object { $_.Name -match "Language" } | Select-Object -ExpandProperty "Name"

$ProgressPreference = "SilentlyContinue"
foreach ($File in $LanguageFiles) {
    $params = @{
        Uri             = $r.response.files[0].$File.url
        OutFile         = "./$File"
        UseBasicParsing = $True
    }
    Invoke-WebRequest @params
}


Get-ChildItem -Path . -Filter *.cab | ForEach-Object { Add-WindowsPackage -Online -PackagePath $_.FullName }

$LanguageList = Get-WinUserLanguageList
$LanguageList.Add("en-GB")
Set-WinUserLanguageList $LanguageList -Force

# English (United Kingdom) Local Experience Pack
# https://www.microsoft.com/en-au/p/english-united-kingdom-local-experience-pack/9nt52vq39bvn
# http://tlu.dl.delivery.mp.microsoft.com/filestreamingservice/files/41681637-f0cd-4e95-8a79-b626c45d14a5?P1=1634431641&P2=404&P3=2&P4=a1jzG0dPForEach-Object2bVDwriduZevqoeGNXxV43POxrForEach-Object2bfyForEach-Object2fVForEach-Object2fForEach-Object2fSzGj18WCtxx4Vkh8Go7fq9rVdnNwqdxhmGVznvYeUfBtvAForEach-Object3dForEach-Object3d
