terraform {
  required_version = ">= 1.3.0" # Ensures Terraform version 1.3.0 or higher is used

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.89.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.53.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "<ORGANIZATION_NAME_HERE>"
    workspaces {
      name = "<WORKSPACE_NAME_HERE>"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"

  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  subscription_id = var.ARM_SUBSCRIPTION_ID
  tenant_id       = var.ARM_TENANT_ID
}

provider "azuread" {
  client_id     = var.ARM_CLIENT_ID
  client_secret = var.ARM_CLIENT_SECRET
  tenant_id     = var.ARM_TENANT_ID
}