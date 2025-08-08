output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = azurerm_windows_function_app.function_app.name
}

output "function_app_url" {
  description = "The URL of the Function App"
  value       = "https://${azurerm_windows_function_app.function_app.name}.azurewebsites.net"
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.function_storage.name
}

output "application_insights_name" {
  description = "The name of the Application Insights instance"
  value       = azurerm_application_insights.function_insights.name
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.function_workspace.name
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.function_workspace.id
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key for Application Insights"
  value       = azurerm_application_insights.function_insights.instrumentation_key
  sensitive   = true
}

output "app_service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.function_plan.name
}

output "app_service_plan_sku" {
  description = "The SKU of the App Service Plan"
  value       = azurerm_service_plan.function_plan.sku_name
}

output "private_endpoints_subnet_id" {
  description = "The ID of the private endpoints subnet"
  value       = data.azurerm_subnet.private_endpoints_subnet.id
}

output "private_endpoints_subnet_name" {
  description = "The name of the private endpoints subnet"
  value       = data.azurerm_subnet.private_endpoints_subnet.name
}

output "private_endpoints_subnet_address_prefixes" {
  description = "The address prefixes of the private endpoints subnet"
  value       = data.azurerm_subnet.private_endpoints_subnet.address_prefixes
}

output "function_app_injection_subnet_id" {
  description = "The ID of the function app injection subnet"
  value       = data.azurerm_subnet.function_app_injection_subnet.id
}

output "function_app_injection_subnet_name" {
  description = "The name of the function app injection subnet"
  value       = data.azurerm_subnet.function_app_injection_subnet.name
}

output "function_app_injection_subnet_address_prefixes" {
  description = "The address prefixes of the function app injection subnet"
  value       = data.azurerm_subnet.function_app_injection_subnet.address_prefixes
}

output "blob_storage_dns_zone_id" {
  description = "The ID of the blob storage private DNS zone"
  value       = data.azurerm_private_dns_zone.blob_storage_dns_zone.id
}

output "blob_storage_dns_zone_name" {
  description = "The name of the blob storage private DNS zone"
  value       = data.azurerm_private_dns_zone.blob_storage_dns_zone.name
}

output "function_app_dns_zone_id" {
  description = "The ID of the function app private DNS zone"
  value       = data.azurerm_private_dns_zone.function_app_dns_zone.id
}

output "function_app_dns_zone_name" {
  description = "The name of the function app private DNS zone"
  value       = data.azurerm_private_dns_zone.function_app_dns_zone.name
}
