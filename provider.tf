provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

 subscription_id = "a2418553-1102-46df-a7af-cf62ce4940c1"  # your subscription ID
 tenant_id       = "b18659dc-6f28-4b5d-82c2-b81a3336b8c1"  # your tenant ID

}


 data "azurerm_client_config" "current" {}
