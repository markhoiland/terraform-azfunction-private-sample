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
