# VM related variable
variable "virtual_machine_name" {
  description = "Value of the Name for the virtual machine"
  type        = string
  default     = "CSGSecAgentUbuntu20"
}

variable "virtual_machine_username" {
  description = "value of the username for the virtual machine"
  type        = string
  default     = "CSGSecAgentUser"
}

# Resoruce group related variable
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "CSGSecAgent"
}

variable "resource_group_location" {
  type        = string
  default     = "westus2"
  description = "Location of the resource group."
}

# Network Related variable
variable "public_ip_type" {
  type        = string
  default     = "Dynamic"
  description = "Type of public IP address"
}

# OS Related variable
variable "os_offer" {
  type        = string
  default     = "0001-com-ubuntu-server-focal"
  description = "Offer of the OS"
}

variable "os_sku" {
  type        = string
  default     = "20_04-lts"
  description = "SKU of the OS"
}

variable "os_version" {
  type        = string
  default     = "20.04.202303280"
  description = "Version of the OS"
}