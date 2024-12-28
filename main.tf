data "azurerm_client_config" "current" {}

data "azuread_group" "main" {
  count        = var.active_directory_auth_enabled != null && var.principal_name != null ? 1 : 0
  display_name = var.principal_name
}

locals {
  resource_group_name = var.resource_group_name
  location            = var.location
  tier_map = {
    # "Burstable"  = "GP"
    "Burstable" = "B"
    # "MemoryOptimized" = "MO"
  }
}

locals {
  tags = {
    Name        = var.name
    Environment = var.environment
  }
}

##----------------------------------------------------------------------------- 
## Below resource will create postgresql flexible server.    
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server" "main" {
  count                             = var.enabled ? 1 : 0
  name                              = var.server_custom_name != null ? var.server_custom_name : format("%s-pgsql-flexible-server", var.name)
  resource_group_name               = local.resource_group_name
  location                          = local.location
  administrator_login               = var.admin_username
  administrator_password            = var.admin_password
  backup_retention_days             = var.backup_retention_days
  delegated_subnet_id               = var.delegated_subnet_id
  sku_name                          = join("_", [lookup(local.tier_map, var.tier, "Burstable"), "Standard", var.size])
  create_mode                       = var.create_mode
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  point_in_time_restore_time_in_utc = var.create_mode == "PointInTimeRestore" ? var.point_in_time_restore_time_in_utc : null
  public_network_access_enabled     = var.public_network_access_enabled
  source_server_id                  = var.create_mode == "PointInTimeRestore" ? var.source_server_id : null
  storage_mb                        = var.storage_mb
  version                           = var.postgresql_version
  zone                              = var.zone
  tags                              = local.tags
  dynamic "high_availability" {
    for_each = toset(var.high_availability != null && var.tier != "Burstable" ? [var.high_availability] : [])

    content {
      mode                      = "ZoneRedundant"
      standby_availability_zone = lookup(high_availability.value, "standby_availability_zone", 1)
    }
  }

  dynamic "maintenance_window" {
    for_each = toset(var.maintenance_window != null ? [var.maintenance_window] : [])
    content {
      day_of_week  = lookup(maintenance_window.value, "day_of_week", 0)
      start_hour   = lookup(maintenance_window.value, "start_hour", 0)
      start_minute = lookup(maintenance_window.value, "start_minute", 0)
    }
  }

  dynamic "authentication" {
    for_each = var.enabled && var.active_directory_auth_enabled ? [1] : [0]

    content {
      active_directory_auth_enabled = var.active_directory_auth_enabled
      tenant_id                     = data.azurerm_client_config.current.tenant_id
    }
  }

  dynamic "identity" {
    for_each = var.cmk_encryption_enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.identity[0].id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.cmk_encryption_enabled ? [1] : []
    content {
      key_vault_key_id                     = azurerm_key_vault_key.kvkey[0].id
      primary_user_assigned_identity_id    = azurerm_user_assigned_identity.identity[0].id
      geo_backup_key_vault_key_id          = var.geo_redundant_backup_enabled ? var.geo_backup_key_vault_key_id : null
      geo_backup_user_assigned_identity_id = var.geo_redundant_backup_enabled ? var.geo_backup_user_assigned_identity_id : null

    }
  }

  lifecycle {
    ignore_changes = [high_availability[0].standby_availability_zone]
  }
}

##----------------------------------------------------------------------------- 
## Below resource will create Firewall rules for Public server.
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_firewall_rule" "firewall_rules" {
  for_each = var.enabled && !var.private_dns ? var.allowed_cidrs : {}

  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.main[0].id
  start_ip_address = cidrhost(each.value, 0)
  end_ip_address   = cidrhost(each.value, -1)
}

##-----------------------------------------------------------------------------
## Below resource will create postgresql flexible database.
##-----------------------------------------------------------------------------
resource "azurerm_postgresql_flexible_server_database" "main" {
  for_each   = var.enabled ? toset(var.database_names) : []
  name       = each.value
  server_id  = azurerm_postgresql_flexible_server.main[0].id
  charset    = var.charset
  collation  = var.collation
  depends_on = [azurerm_postgresql_flexible_server.main]
}

resource "azurerm_postgresql_flexible_server_configuration" "main" {
  for_each   = var.enabled ? var.server_configurations : {}
  name       = each.key
  server_id  = azurerm_postgresql_flexible_server.main[0].id
  value      = each.value
  depends_on = [azurerm_postgresql_flexible_server.main]
}

