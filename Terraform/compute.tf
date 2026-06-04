# ========================================
# Virtual Machines
# ========================================

# Linux VM for Services (Web, DNS, etc.)
# Uses budget-friendly B1s size for lab environment
resource "azurerm_linux_virtual_machine" "lab_linux_vm" {
  name                = "linux-srv-01"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  size                = "Standard_B1s"  # 1 vCPU, 1GB RAM - cost-effective for lab
  admin_username      = var.admin_username

  # Connect to services subnet via NIC
  network_interface_ids = [
    azurerm_network_interface.services_server_nic.id
  ]

  # Password authentication enabled for simplicity in lab (use SSH keys in production)
  disable_password_authentication = false
  admin_password                  = var.vm_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Standard storage for cost efficiency
  }

  source_image_reference {
    publisher = "Canonical"  # Ubuntu official publisher
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"  # Ubuntu 22.04 LTS (long-term support)
    version   = "latest"  # Always use latest patch version
  }
}

# Windows VM for Active Directory Management
# Uses B2s size (2 vCPUs, 4GB RAM) as Windows requires more resources than Linux
resource "azurerm_windows_virtual_machine" "mgmt_win_srv" {
  name                = "win-mgmt-01"
  resource_group_name = azurerm_resource_group.lab_rg.name
  location            = azurerm_resource_group.lab_rg.location
  
  size                = "Standard_B2s"  # 2 vCPUs, 4GB RAM - minimum for Windows Server
  admin_username      = "anthonyadmin"
  
  # Password loaded from terraform.tfvars (keep secure, never commit to git)
  admin_password      = var.vm_password

  # Connect to management subnet via NIC
  network_interface_ids = [
    azurerm_network_interface.management_server_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Standard storage for cost efficiency
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"  # Official Microsoft publisher
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"  # Windows Server 2022 Azure Edition
    version   = "latest"  # Always use latest patch version
  }
}
