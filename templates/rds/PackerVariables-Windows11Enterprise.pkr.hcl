
variable "apps_url" {
  type    = string
  default = "$(apps_url)"
}

variable "build_key_vault" {
  type    = string
  default = "$(build_key_vault)"
}

variable "build_resource_group" {
  type    = string
  default = "$(build_resource_group)"
}

variable "build_subnet" {
  type    = string
  default = "$(build_subnet)"
}

variable "build_vnet" {
  type    = string
  default = "$(build_vnet)"
}

variable "destination_gallery_name" {
  type    = string
  default = "$(destination_gallery_name)"
}

variable "destination_gallery_resource_group" {
  type    = string
  default = "$(destination_gallery_resource_group)"
}

variable "destination_image_version" {
  type    = string
  default = "$(destination_image_version)"
}

variable "destination_replication_regions" {
  type    = string
  default = "$(destination_replication_regions)"
}

variable "image_date" {
  type    = string
  default = "$(Build.BuildNumber)"
}

variable "image_offer" {
  type    = string
  default = "Windows-11"
}

variable "image_publisher" {
  type    = string
  default = "MicrosoftWindowsDesktop"
}

variable "image_sku" {
  type    = string
  default = "win11-21h2-ent"
}

variable "managed_image_resource_group_name" {
  type    = string
  default = "$(managed_image_resource_group_name)"
}

variable "packages_url" {
  type    = string
  default = "$(packages_url)"
}

variable "tag_created_date" {
  type    = string
  default = "$(Date:yyyyMMdd)"
}

variable "tag_owner" {
  type    = string
  default = "$(owner)"
}

variable "vm_size" {
  type    = string
  default = "$(vm_size)"
}
