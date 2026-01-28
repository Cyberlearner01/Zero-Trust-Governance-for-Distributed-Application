# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "security" {
  name     = "rg-zero-trust-governance"
  location = "canadacentral"
}

# -----------------------------
# App Service Plan - Internal LOB App
# -----------------------------
resource "azurerm_service_plan" "internal_lob" {
  name                = "asp-internal-lob-f1"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  os_type  = "Linux"
  sku_name = "F1"
}

# -----------------------------
# Internal LOB Web App
# -----------------------------
resource "azurerm_linux_web_app" "internal_lob" {
  name                = "app-internal-lob-seclab"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  service_plan_id     = azurerm_service_plan.internal_lob.id

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

# -----------------------------
# App Service Plan - Customer Portal
# -----------------------------
resource "azurerm_service_plan" "customer_portal" {
  name                = "asp-customer-portal-f1"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name

  os_type  = "Linux"
  sku_name = "F1"
}

# -----------------------------
# Customer Portal Web App
# -----------------------------
resource "azurerm_linux_web_app" "customer_portal" {
  name                = "app-customer-portal-seclab"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  service_plan_id     = azurerm_service_plan.customer_portal.id

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

# -----------------------------
# Key Vault (RBAC ENABLED)
# -----------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "security_kv" {
  name                = "kv-ztg-seclab"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
}

# -----------------------------
# Key Vault Secret (Terraform writes)
# -----------------------------
variable "db_password" {
  type      = string
  sensitive = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "DbPassword"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.security_kv.id

  depends_on = [
    azurerm_role_assignment.terraform_kv_secrets_officer
  ]
}

# -----------------------------
# RBAC: Terraform Identity - Secrets Officer
# -----------------------------
resource "azurerm_role_assignment" "terraform_kv_secrets_officer" {
  scope                = azurerm_key_vault.security_kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# -----------------------------
# RBAC: Internal App - Read Secrets Only
# -----------------------------
resource "azurerm_role_assignment" "internal_lob_kv_reader" {
  scope                = azurerm_key_vault.security_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.internal_lob.identity[0].principal_id
}

# -----------------------------
# RBAC: Customer Portal - Read Secrets Only
# -----------------------------
resource "azurerm_role_assignment" "customer_portal_kv_reader" {
  scope                = azurerm_key_vault.security_kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.customer_portal.identity[0].principal_id
}
