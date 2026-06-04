variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "Anthony-Lab-RG"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US2"
}

variable "vnet_address_space" {
  description = "The address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "A map of subnet names and their prefixes"
  type        = map(string)
  default     = {
    "management"  = "10.0.1.0/24"
    "services"  = "10.0.2.0/24"
  }
}
variable "vm_password" {
  type        = string
  sensitive   = true # This hides the password from your terminal logs
}
variable "admin_username" {
  type        = string
  sensitive   = true # This hides the password from your terminal logs
}

variable "myip" {
  type = string
}
variable "CICD_RG_Name" {
  type = string
  default = "rg-terraform-mgmt"
}