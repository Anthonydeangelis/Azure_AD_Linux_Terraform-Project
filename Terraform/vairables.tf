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
    "web"  = "10.0.1.0/24"
    "app"  = "10.0.2.0/24"
    "data" = "10.0.3.0/24"
  }
}