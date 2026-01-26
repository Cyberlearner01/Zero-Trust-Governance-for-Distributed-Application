# Resource Group
resource "azurerm_resource_group" "security" {
  name     = "security-rg"
  location = "canadacentral"
}

# App Service Plan for Workload A (Internal)
resource "azurerm_service_plan" "workload_a" {
  name                = "asp-internal-workload"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  
   os_type             = "Linux"
  sku_name            = "F1"

}

# Linux Web App for Workload A
resource "azurerm_linux_web_app" "workload_a" {
  name                = "app-internal-workload"
  resource_group_name = azurerm_resource_group.security.name
  location            = azurerm_resource_group.security.location
  service_plan_id     = azurerm_service_plan.workload_a.id

  site_config {
    always_on = false
  }

  identity {
    type = "SystemAssigned"
  }

   app_settings = {
      DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.id})"
    }

}

# App Service Plan for Workload B (Customer Portal)
resource "azurerm_service_plan" "workload_b" {
  name                = "asp-customer-portal"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
 
  os_type             = "Linux"
  sku_name            = "F1"

}

# Linux Web App for Workload B
resource "azurerm_linux_web_app" "workload_b" {
  name                = "app-customer-portal-seclab1"
  resource_group_name = azurerm_resource_group.security.name
  location            = azurerm_resource_group.security.location
  service_plan_id     = azurerm_service_plan.workload_b.id

  site_config {
    always_on = false
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
      DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_password.id})"
    }
    
}

# Key Vault
resource "azurerm_key_vault" "security_kv" {
  name                        = "security-key-lab1"
  location                    = azurerm_resource_group.security.location
  resource_group_name         = azurerm_resource_group.security.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                     = "standard"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
}

# Access Policy for Workload A
resource "azurerm_key_vault_access_policy" "workload_a" {
  key_vault_id = azurerm_key_vault.security_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.workload_a.identity[0].principal_id

  key_permissions    = ["Get"]
  secret_permissions = ["Get", "Set", "List"]
  storage_permissions = ["Get"]
}

# Access Policy for Terraform (your user or SP)
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.security_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "Set", "List"]
}


# Access Policy for Workload B
resource "azurerm_key_vault_access_policy" "workload_b" {
  key_vault_id = azurerm_key_vault.security_kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.workload_b.identity[0].principal_id

  key_permissions    = ["Get"]
  secret_permissions = ["Get", "Set", "List"]
  storage_permissions = ["Get"]
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "DbPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.security_kv.id
}
