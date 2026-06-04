# ========================================
# Core Network Infrastructure
# ========================================

# 1. Resource Group - Container for all resources
# All resources must belong to a resource group for organization and billing
resource "azurerm_resource_group" "lab_rg" {
    name     = var.resource_group_name  # Name from terraform.tfvars
    location = var.location  # Azure region (e.g., eastus, westus2)
}

# 2. Virtual Network - Private network space
# 10.0.0.0/16 provides 65,536 IP addresses for the entire lab
resource "azurerm_virtual_network" "main_vnet" {
  name                = "lab-vnet"
  address_space       = ["10.0.0.0/16"]  # Private IP range for all subnets
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  dns_servers = ["10.0.1.4"] # Point to AD server for DNS resolution
}

# 3. Subnets - Logical partitions within the VNet
# Each subnet is isolated and can have different security rules

# Management Subnet: Hosts Active Directory Domain Controller
# 10.0.1.0/24 provides 256 IP addresses
resource "azurerm_subnet" "management_snet" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Services Subnet: Hosts application and web servers
# 10.0.2.0/24 provides 256 IP addresses
resource "azurerm_subnet" "services_snet" {
  name                 = "snet-services"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. Network Interfaces (NICs) - Virtual network adapters for VMs
# Each NIC connects a VM to a subnet and optionally to a public IP

# NIC for Linux Services VM
# Connects to Services Subnet with dynamic private IP allocation
resource "azurerm_network_interface" "services_server_nic" {
  name                = "services-server-nic"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "servicesipconfig"
    subnet_id                     = azurerm_subnet.services_snet.id  # Attach to services subnet
    private_ip_address_allocation = "Dynamic"  # Private IP assigned by Azure DHCP
    public_ip_address_id          = azurerm_public_ip.linux_pip.id  # Attach public IP for external access
  }
}

# NIC for Windows Management VM (Active Directory)
# Connects to Management Subnet with static private IP for DNS consistency
resource "azurerm_network_interface" "management_server_nic" {
  name                = "management-server-nic"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "managementipconfig"
    subnet_id                     = azurerm_subnet.management_snet.id  # Attach to management subnet
    private_ip_address_allocation = "Static"  # Static IP required for AD/DNS consistency
    private_ip_address            = "10.0.1.4"  # Fixed IP for reliable DNS configuration
    public_ip_address_id          = azurerm_public_ip.win_pip.id  # Attach public IP for RDP access
  }
  }
  #Adding a new RG for Storage Account for CI
  resource "azurerm_resource_group" "ci_cd_rg" {
    name    = var.CICD_RG_Name  # New resource group for CI/CD storage account
    location = var.location  # Azure region (e.g., eastus, westus2)
  }
  resource "azurerm_storage_account" "state_sa" {

  name                     = "adrstorage27272"  # Storage account name must be globally unique

  resource_group_name      = azurerm_resource_group.ci_cd_rg.name  # Place storage account in CI/CD resource group

  location                 = azurerm_resource_group.ci_cd_rg.location  # Same location as resource group

  account_tier             = "Standard"

  account_replication_type = "LRS"

}


