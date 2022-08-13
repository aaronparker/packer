## Pre-install
Remove-MSIApplications -Name "Remote Desktop Agent Boot Loader"
Remove-MSIApplications -Name "Remote Desktop WebRTC Redirector Service"


## Install
Switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "Microsoft Windows Server*" {
        $FileName = "VDAServerSetup_2103.exe"
        break
    }
    "Microsoft Windows 1* Enterprise for Virtual Desktops" {
        $FileName = "VDAServerSetup_2103.exe"
        break
    }
    "Microsoft Windows 1* Enterprise" {
        $FileName = "VDAWorkstationSetup_2103.exe"
        break
    }
    "Microsoft Windows 1*" {
        $FileName = "VDAWorkstationSetup_2103.exe"
        break
    }
    Default {
        $FileName = "VDAWorkstationSetup_2103.exe"
    }
}

# Parameters
$params = '/noreboot /quiet /enable_remote_assistance /masterimage /disableexperiencemetrics /virtualmachine /noresume' +
' /logpath "C:\Windows\Logs" /enable_real_time_transport /enable_hdx_ports /enable_hdx_udp_ports /components vda /mastermcsimage' +
' /exclude "Workspace Environment Management","Citrix Files for Outlook","Citrix Files for Windows"'

# Install
Execute-Process -Path $FileName -Parameters $params
