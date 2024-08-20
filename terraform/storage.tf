# Storage Account
resource "azurerm_virtual_network" "rabobank_vnet" {
  name                = "rabobank-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rabobank.location
  resource_group_name = azurerm_resource_group.rabobank.name
}

resource "azurerm_subnet" "rabobank_subnet" {
  name                 = "rabobank-subnet"
  resource_group_name  = azurerm_resource_group.rabobank.name
  virtual_network_name = azurerm_virtual_network.rabobank_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_storage_account" "rabobank" {
  name                = "rabobanksa"
  resource_group_name = azurerm_resource_group.rabobank.name

  location                 = azurerm_resource_group.rabobank.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["100.0.0.1"]
    virtual_network_subnet_ids = [azurerm_subnet.rabobank_subnet.id]
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "rabobank" {
  name               = "rabobank"
  storage_account_id = azurerm_storage_account.rabobank.id
}

resource "azurerm_storage_container" "records" {
  name                  = "records"
  storage_account_name  = azurerm_storage_account.rabobank.name
  container_access_type = "private"
}

# Azure SQL Database
resource "random_password" "azure_sql_admin_password" {
  length      = 20
  special     = true
  min_numeric = 1
  min_upper   = 1
  min_lower   = 1
  min_special = 1
}

# store the admin password in Azure Key Vault
resource "azurerm_key_vault_secret" "azure_sql_admin_password" {
  name         = "azure-sql-admin-password"
  key_vault_id = azurerm_key_vault.rabobank.id
  value        = resource.random_password.azure_sql_admin_password.result
}

resource "azurerm_mssql_server" "rabobank" {
  name                         = "rabobanksql"
  resource_group_name          = azurerm_resource_group.rabobank.name
  location                     = azurerm_resource_group.rabobank.location
  administrator_login          = "admin"
  administrator_login_password = resource.random_password.azure_sql_admin_password.result
  version                      = "12.0"
}

resource "azurerm_mssql_database" "rabobank" {
  name      = "rabobanksqldb"
  server_id = azurerm_mssql_server.rabobank.id

  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 5
  read_scale     = true
  sku_name       = "Basic"

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}