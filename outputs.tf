output "postgresql_flexible_server_id" {
  value       = try(azurerm_postgresql_flexible_server.main[0].id, null)
  description = "The ID of the PostgreSQL Flexible Server."
}

output "postgresql_server_name" {
  value       = azurerm_postgresql_flexible_server.main[0].name
  description = "The name of the PostgreSQL server."
}

output "postgresql_server_resource_group_name" {
  value       = azurerm_postgresql_flexible_server.main[0].resource_group_name
  description = "The name of the PostgreSQL server."
}

output "postgresql_server_location" {
  value       = azurerm_postgresql_flexible_server.main[0].location
  description = "The name of the PostgreSQL server."
}

output "postgresql_server_public_network_access" {
  value       = azurerm_postgresql_flexible_server.main[0].public_network_access_enabled
  description = "Indicates if public network access is enabled for the PostgreSQL server."
}

output "network_firewall_rules" {
  value = [for rule in azurerm_postgresql_flexible_server_firewall_rule.firewall_rules : {
    name     = rule.name
    start_ip = rule.start_ip_address
    end_ip   = rule.end_ip_address
  }]
  description = "List of firewall rules configured for the PostgreSQL server."
}

output "database_names" {
  value       = [for db in azurerm_postgresql_flexible_server_database.main : db.name]
  description = "List of databases created on the PostgreSQL server."
}