variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID to use for deployments."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "managed_identity_name" {
  description = "The name of the User-Assigned Managed Identity"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account for the function app"
  type        = string
  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "application_insights_name" {
  description = "The name of the Application Insights instance"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  type        = string
}

variable "app_service_plan_name" {
  description = "The name of the App Service Plan"
  type        = string
}

variable "function_app_name" {
  description = "The name of the Function App"
  type        = string
  validation {
    condition     = length(var.function_app_name) >= 2 && length(var.function_app_name) <= 60 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.function_app_name))
    error_message = "Function app name must be between 2 and 60 characters long, start and end with alphanumeric characters, and can contain hyphens."
  }
}

variable "subnet_resource_group_name" {
  description = "The name of the resource group containing the private endpoints subnet"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network containing the subnets"
  type        = string
}

variable "pep_subnet_name" {
  description = "The name of the subnet for private endpoints"
  type        = string
}

variable "function_app_injection_subnet_name" {
  description = "The name of the subnet for function app VNet integration (injection)"
  type        = string
}

variable "devops_agent_subnet_name" {
  description = "The name of the subnet for DevOps hosted agents/runners"
  type        = string
}