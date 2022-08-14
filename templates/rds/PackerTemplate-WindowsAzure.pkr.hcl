packer {
  required_plugins {
    windows-update = {
      version = "0.14.0"
      source = "github.com/rgl/windows-update"
    }
  }
}

variable "apps_directory" {
  type    = string
  default = "C:\\Apps"
}

variable "apps_url" {
  type    = string
  default = ""
}

variable "azure_client_id" {
  type    = string
  default = ""
}

variable "azure_client_secret" {
  type    = string
  default = ""
}

variable "azure_subscription_id" {
  type    = string
  default = "{00000000-0000-0000-0000-00000000000}"
}

variable "azure_tenant_id" {
  type    = string
  default = ""
}

variable "build_key_vault" {
  type    = string
  default = "stpyimageaustraliaeast"
}

variable "build_resource_group" {
  type    = string
  default = "rg-ImageBuild-AustraliaEast"
}

variable "build_subnet" {
  type    = string
  default = "subnet-Packer"
}

variable "build_vnet" {
  type    = string
  default = "vnet-ImageBuild-AustraliaEast"
}

variable "destination_gallery_name" {
  type    = string
  default = "sigWindowsVirtualDesktop"
}

variable "destination_resource_group_name" {
  type    = string
  default = "rg-Images-AustraliaEast"
}

variable "destination_image_version" {
  type    = string
  default = "1.0.1"
}

variable "destination_replication_regions" {
  type    = string
  default = "australiaeast"
}

variable "image_date" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = "AustraliaEast"
}

variable "locale" {
  type    = string
  default = "en-AU"
}

variable "managed_image_resource_group_name" {
  type    = string
  default = ""
}

variable "packages_url" {
  type    = string
  default = ""
}

variable "source_image_offer" {
  type    = string
  default = "Windows-10"
}

variable "source_image_publisher" {
  type    = string
  default = "MicrosoftWindowsDesktop"
}

variable "source_image_sku" {
  type    = string
  default = "20h2-ent"
}

variable "tag_created_date" {
  type    = string
  default = ""
}

variable "tag_function" {
  type    = string
  default = "Gold image"
}

variable "tag_owner" {
  type    = string
  default = "GitHub"
}

variable "tag_type" {
  type    = string
  default = "WindowsVirtualDesktop"
}

variable "tag_build_source_repo" {
  type    = string
  default = ""
}

variable "vm_size" {
  type    = string
  default = "Standard_D2as_v4"
}

variable "winrmuser" {
  type    = string
  default = "packer"
}

variable "working_directory" {
  type    = string
  default = "${env("System_DefaultWorkingDirectory")}"
}

locals {
  destination_image_name = "${var.source_image_publisher}-${var.source_image_offer}-${var.source_image_sku}"
  managed_image_name     = "${var.source_image_offer}-${var.source_image_sku}-${var.image_date}"
}

source "azure-arm" "microsoft-windows" {
  azure_tags = {
    Billing         = "Packer"
    CreatedDate     = "${var.tag_created_date}"
    Function        = "${var.tag_function}"
    OperatingSystem = "${local.managed_image_name}"
    Owner           = "${var.tag_owner}"
    Source          = "${var.tag_build_source_repo}"
    Type            = "${var.tag_function}"
  }
  build_key_vault_name                   = "${var.build_key_vault}"
  build_resource_group_name              = "${var.build_resource_group}"
  client_id                              = "${var.azure_client_id}"
  client_secret                          = "${var.azure_client_secret}"
  communicator                           = "winrm"
  shared_image_gallery_destination {
      subscription = "${var.azure_subscription_id}"
      resource_group = "${var.destination_resource_group_name}"
      gallery_name = "${var.destination_gallery_name}"
      image_name = "${local.destination_image_name}"
      image_version = "${var.destination_image_version}"
      replication_regions = [ "${var.location}" ]
  }
  image_offer                            = "${var.source_image_offer}"
  image_publisher                        = "${var.source_image_publisher}"
  image_sku                              = "${var.source_image_sku}"
  image_version                          = "latest"
  managed_image_name                     = "${local.managed_image_name}"
  managed_image_resource_group_name      = "${var.managed_image_resource_group_name}"
  os_type                                = "Windows"
  private_virtual_network_with_public_ip = true
  subscription_id                        = "${var.azure_subscription_id}"
  tenant_id                              = "${var.azure_tenant_id}"
  virtual_network_name                   = "${var.build_vnet}"
  virtual_network_resource_group_name    = "${var.build_resource_group}"
  virtual_network_subnet_name            = "${var.build_subnet}"
  vm_size                                = "${var.vm_size}"
  winrm_insecure                         = true
  winrm_timeout                          = "5m"
  winrm_use_ssl                          = true
  winrm_username                         = "${var.winrmuser}"
}

build {
  sources = ["source.azure-arm.microsoft-windows"]

  provisioner "powershell" {
    environment_vars = ["Locale=${var.locale}",
                        "PackagesUrl=${var.packages_url}"]
    scripts          = ["build/rds/00_SupportFunctions.ps1",
                        "build/rds/01_Rds-PrepImage.ps1",
                        "build/rds/02_Packages.ps1",
                        "build/rds/03_RegionLanguage.ps1",
                        "build/rds/04_Rds-Roles.ps1",
                        "build/rds/05_Customise.ps1",]
  }

  provisioner "windows-restart" {}

  provisioner "windows-update" {
    filters         = ["exclude:$_.Title -like '*Silverlight*'", "exclude:$_.Title -like '*Preview*'", "include:$true"]
    search_criteria = "IsInstalled=0"
    update_limit    = 25
  }

  provisioner "powershell" {
    scripts = ["build/rds/07_MicrosoftVcRedists.ps1",
                "build/rds/08_MicrosoftFSLogixApps.ps1",
                "build/rds/09_MicrosoftEdge.ps1",
                "build/rds/10_Microsoft365Apps.ps1",
                "build/rds/11_MicrosoftTeams.ps1",
                "build/rds/12_MicrosoftOneDrive.ps1",
                "build/rds/14_Wvd-Agents.ps1"]
  }

  provisioner "windows-restart" {}

  provisioner "powershell" {
    environment_vars = ["AppsUrl=${var.apps_url}"]
    scripts          = ["build/rds/39_AdobeAcrobatReaderDC.ps1",
                        "build/rds/40_Rds-LobApps.ps1"]
  }

  provisioner "windows-restart" {}

  provisioner "windows-update" {
    filters         = ["exclude:$_.Title -like '*Silverlight*'", "exclude:$_.Title -like '*Preview*'", "include:$true"]
    search_criteria = "IsInstalled=0"
    update_limit    = 25
  }

  provisioner "powershell" {
    inline = ["New-Item -Path \"C:\\Apps\\Tools\" -ItemType \"Directory\" -Force -ErrorAction \"SilentlyContinue\" > $Null"]
  }

  provisioner "file" {
    source      = "${var.working_directory}/build/tools"
    destination = "C:\\Apps\\Tools"
    direction   = "upload"
    max_retries = "2"
  }

  provisioner "powershell" {
    scripts = ["build/rds/98_CitrixOptimizer.ps1",
                "build/rds/99_Bisf.ps1",
                "build/rds/Get-Installed.ps1"]
  }

  provisioner "file" {
    source      = "C:\\Windows\\Temp\\Reports\\Installed.zip"
    destination = "${var.working_directory}/reports/Installed.zip"
    direction   = "download"
    max_retries = "1"
  }

  provisioner "windows-restart" {}

  provisioner "powershell" {
    scripts = ["build/rds/Sysprep-Image.ps1"]
  }

  post-processor "manifest" {
    output = "packer-manifest-${var.image_publisher}-${var.image_offer}-${var.image_sku}-${var.image_date}.json"
  }
}
