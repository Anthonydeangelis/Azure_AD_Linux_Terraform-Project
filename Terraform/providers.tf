terraform {
  required_providers {
    azurerm ={
        source = "hashicorp/azurerm"
        version = "~> 4.0"
    }
  }
  # Configure the backend to store state in Azure Blob Storage
  ##backend "azurerm" {
    #resource_group_name  = var.CICD-RG-Name  # Resource group for the storage account
   # storage_account_name = "yourunique-tfstate-storage"
    #container_name       = "tfstate"
    #key                  = "netops-hub-spoke.tfstate"
  }

provider "azurerm" {
  features {
    
  }

  }
