terraform {
  required_providers {
    azurerm ={
        source = "hashicorp/azurerm"
        version = "~> 4.0"
    }
  }

  # Configure the backend to store state in Azure Blob Storage
backend "azurerm" {} 
}
provider "azurerm" {
  features {
    
  }

  }
