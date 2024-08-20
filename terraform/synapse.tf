resource "random_password" "azure_spark_pool_admin_password" {
  length      = 15
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

# store the admin password in Azure Key Vault
resource "azurerm_key_vault_secret" "azure_sql_admin_password" {
  name         = "azure-spark-pool-admin-password"
  key_vault_id = azurerm_key_vault.rabobank.id
  value        = resource.random_password.azure_spark_pool_admin_password.result
}

resource "azurerm_synapse_workspace" "rabobank" {
  name                                 = "rabobankasws"
  resource_group_name                  = azurerm_resource_group.rabobank.name
  location                             = azurerm_resource_group.rabobank.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.rabobank.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = resource.random_password.azure_spark_pool_admin_password.result

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_spark_pool" "example" {
  name                 = "rabobankspark"
  synapse_workspace_id = azurerm_synapse_workspace.rabobank.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  node_count           = 3
  cache_size           = 100

  auto_pause {
    delay_in_minutes = 15
  }
}