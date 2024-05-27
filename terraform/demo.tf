
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.100.0"
    }
  }
}

provider "azurerm" {
  features {}

}

resource "azurerm_resource_group" "rg" {
  name     = "demo-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "sa" {
  name                     = "sahidde123456"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv2" {
  name                        = "kvhidde1234567"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"


}

resource "azurerm_key_vault" "kv1" {
  name                        = "kvhidde12345678"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  sku_name = "standard"


}

resource "azurerm_role_assignment" "ra" {
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.kv1.id
}

resource "azurerm_role_assignment" "keyvaultreader" {
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_app_service.as.identity[0].principal_id
  scope                = azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "secret" {
  name         = "secret-hidde"
  key_vault_id = azurerm_key_vault.kv1.id
  value        = "Password1234"
}

resource "azurerm_key_vault_secret" "connectionstring" {
  name         = "connection-string"
  key_vault_id = azurerm_key_vault.kv1.id
  value        = "Server=tcp:sql-hidde1234567.database.windows.net,1433;Initial Catalog=hidde-db;Persist Security Info=False;User ID=hidde;Password=Password1234;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "hidde-appserviceplan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name


  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "as" {
  name                = "as-hidde123456"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id
  app_settings = {
    "sql-connectionstring" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.connectionstring.versionless_id})"
    "KeyVaultName"         = azurerm_key_vault.kv1.name
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.ai.instrumentation_key
  }

  identity {
    type = "SystemAssigned"

  }
}

resource "azurerm_mssql_server" "sql" {
  name                         = "sql-hidde1234567"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "North Europe"
  version                      = "12.0"
  administrator_login          = "hidde"
  administrator_login_password = "Password1234"
  minimum_tls_version          = "1.2"

  tags = {
    environment = "development"
  }
}

resource "azurerm_mssql_database" "db" {
  name         = "hidde-db"
  server_id    = azurerm_mssql_server.sql.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  sample_name  = "AdventureWorksLT"
  max_size_gb  = 5
  sku_name     = "S1"
  enclave_type = "VBS"

  # prevent the possibility of accidental data loss
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_firewall_rule" "sqlserver_allow_azureservices" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-hidde123456"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "ai" {
  name                = "ai-hidde123456"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}




