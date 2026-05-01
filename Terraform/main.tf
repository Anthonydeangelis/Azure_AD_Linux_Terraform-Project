# 1. The Resource Group (The container for everything)
resource "azurerm_resource_group" "lab_rg" {
    name     = var.resource_group_name
    location = var.location
}

# 2. The Virtual Network (The private cloud space)
resource "azurerm_virtual_network" "main_vnet" {
  name                = "lab-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
}

# 3. The Subnets (Partitioning the network)
resource "azurerm_subnet" "management_snet" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "services_snet" {
  name                 = "snet-services"
  resource_group_name  = azurerm_resource_group.lab_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 4. The Network Interface (The 'NIC' for Services VM)
# This links the VM to the Services Subnet automatically.
resource "azurerm_network_interface" "services_server_nic" {
  name                = "services-server-nic"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "servicesipconfig"
    # Here is the 'PowerShell-style' variable reference:
    subnet_id                     = azurerm_subnet.services_snet.id
    private_ip_address_allocation = "Dynamic"
  }
}
## Nic for Premade AD instance (Management Server)
resource "azurerm_network_interface" "management_server_nic" {
  name                = "management-server-nic"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name

  ip_configuration {
    name                          = "managementipconfig"
    # Here is the 'PowerShell-style' variable reference:
    subnet_id                     = azurerm_subnet.management_snet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.1.4"
  }
}