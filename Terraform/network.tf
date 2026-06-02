# ========================================
# Public IP Addresses
# ========================================
# Static public IPs for VMs to ensure consistent external connectivity

# Public IP for Linux VM (Services)
resource "azurerm_public_ip" "linux_pip" {
  name                = "linux-srv-01-pip"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  allocation_method   = "Static"  # Static ensures IP doesn't change on deallocate
  sku                 = "Standard" # Standard SKU is sufficient for lab use
}

# Public IP for Windows Management VM
resource "azurerm_public_ip" "win_pip" {
  name                = "win-mgmt-01-pip"
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}



# ========================================
# Network Security Configuration (using locals for DRY)
# ========================================
# Using locals and for_each to eliminate repetitive NSG and rule definitions

locals {
  # Network Security Groups mapped by environment
  nsgs = {
    linux = {
      name      = "linux-subnet-nsg"
      subnet_id = azurerm_subnet.services_snet.id  # Services/Linux subnet
    }
    windows = {
      name      = "windows-subnet-nsg"
      subnet_id = azurerm_subnet.management_snet.id  # Management/AD subnet
    }
  }

  # Security rules: Maps rule names to configurations
  # Adding new rules is as simple as adding an entry here
  # Multiple rules can point to the same NSG (nsg_key)
  nsg_rules = {
    linux_ssh = {
      nsg_key             = "linux"  # Associates rule with Linux NSG
      name                = "allow-ssh"
      priority            = 100  # Lower number = higher priority
      destination_port    = "22"  # SSH port
    }
    windows_rdp = {
      nsg_key             = "windows"  # Associates rule with Windows NSG
      name                = "allow-rdp"
      priority            = 100
      destination_port    = "3389"  # RDP port
    }
    windows_ssh = {
      nsg_key             = "windows"  # Same Windows NSG, different rule
      name                = "allow-ssh-windows"
      priority            = 101  # Secondary rule (evaluated after RDP)
      destination_port    = "22"  # SSH port 
    }
  }
}

# Create NSGs for each environment (linux and windows)
# for_each creates separate NSG for each key in local.nsgs
resource "azurerm_network_security_group" "nsg" {
  for_each = local.nsgs

  name                = each.value.name
  location            = azurerm_resource_group.lab_rg.location
  resource_group_name = azurerm_resource_group.lab_rg.name
}

# Create inbound security rules (SSH for Linux, RDP for Windows)
# for_each creates separate rule for each entry in local.nsg_rules
# All rules allow traffic only from var.myip (your IP)
resource "azurerm_network_security_rule" "rules" {
  for_each = local.nsg_rules

  name                        = each.value.name
  priority                    = each.value.priority  # Lower number = evaluated first
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"  # Accept from any source port
  destination_port_range      = each.value.destination_port  # SSH (22) or RDP (3389)
  source_address_prefix       = var.myip  # Restrict to your IP only
  destination_address_prefix  = "*"  # Allow to any destination
  resource_group_name         = azurerm_resource_group.lab_rg.name
  network_security_group_name = azurerm_network_security_group.nsg[each.value.nsg_key].name
}

# Associate each NSG with its corresponding subnet
# for_each links each NSG to its subnet defined in local.nsgs
resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each = local.nsgs

  subnet_id                 = each.value.subnet_id  # Target subnet
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id  # Source NSG
}
