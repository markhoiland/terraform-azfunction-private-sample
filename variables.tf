variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-function-app-01"
}

variable "subscription_id" {
  description = "The Azure subscription ID to use for deployments."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "Central US"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "azure-function"
}

variable "managed_identity_name" {
  description = "The name of the User-Assigned Managed Identity"
  type        = string
  default     = "uami-function-app"
}

variable "storage_account_name" {
  description = "The name of the storage account for the function app"
  type        = string
  default     = "safunctionapp001"

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must be between 3 and 24 characters long and contain only lowercase letters and numbers."
  }
}

variable "application_insights_name" {
  description = "The name of the Application Insights instance"
  type        = string
  default     = "appi-function-app"
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  type        = string
  default     = "law-function-app"
}

variable "app_service_plan_name" {
  description = "The name of the App Service Plan"
  type        = string
  default     = "asp-function-app"
}

variable "function_app_name" {
  description = "The name of the Function App"
  type        = string
  default     = "func-app-001"

  validation {
    condition     = length(var.function_app_name) >= 2 && length(var.function_app_name) <= 60 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.function_app_name))
    error_message = "Function app name must be between 2 and 60 characters long, start and end with alphanumeric characters, and can contain hyphens."
  }
}
