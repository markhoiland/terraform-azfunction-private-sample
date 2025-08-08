# Gather client configuration
data "azurerm_client_config" "current" {}

# Reference existing subnet for private endpoints
data "azurerm_subnet" "private_endpoints_subnet" {
  name                 = var.pep_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.subnet_resource_group_name
}

# Reference existing subnet for function app VNet integration (injection)
data "azurerm_subnet" "function_app_injection_subnet" {
  name                 = var.function_app_injection_subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.subnet_resource_group_name
}

# Reference existing private DNS zone for blob storage
data "azurerm_private_dns_zone" "blob_storage_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.subnet_resource_group_name
}

# Reference existing private DNS zone for function app
data "azurerm_private_dns_zone" "function_app_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.subnet_resource_group_name
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create User-Assigned Managed Identity for Function App to use to access Storage
resource "azurerm_user_assigned_identity" "uami" {
  location            = var.location
  name                = var.managed_identity_name
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Assign required RBAC permissions
# Assign the "Storage Account Contributor" role to the current user for the Storage Account
resource "azurerm_role_assignment" "current_user_storage_account_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign the "Storage Blob Data Owner" role to the current user for the Storage Account
resource "azurerm_role_assignment" "current_user_storage_blob_data_owner" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign the "Storage Account Contributor" role to the Managed Identity for the Storage Account
resource "azurerm_role_assignment" "uami_storage_account_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

# Assign the "Storage Blob Data Owner" role to the Managed Identity for the Storage Account
resource "azurerm_role_assignment" "uami_storage_blob_data_owner" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.uami.principal_id
}

# Create a storage account for the function app
resource "azurerm_storage_account" "function_storage" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  sftp_enabled             = false
  # Disable public access for security
  allow_nested_items_to_be_public = false
  cross_tenant_replication_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  network_rules {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_private_endpoint" "storage_blob_pep" {
  name                = "${var.storage_account_name}-blob-pep"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.function_storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob_storage_dns_zone.id]
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create Log Analytics Workspace for Application Insights
resource "azurerm_log_analytics_workspace" "function_workspace" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create Application Insights for monitoring
resource "azurerm_application_insights" "function_insights" {
  name                = var.application_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.function_workspace.id

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create an App Service Plan (B1 SKU)
resource "azurerm_service_plan" "function_plan" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = "B1"

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

# Create the Windows Function App
resource "azurerm_windows_function_app" "function_app" {
  name                          = var.function_app_name
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  storage_account_name          = azurerm_storage_account.function_storage.name
  storage_uses_managed_identity = true
  service_plan_id               = azurerm_service_plan.function_plan.id
  enabled                       = true
  virtual_network_subnet_id     = data.azurerm_subnet.function_app_injection_subnet.id
  functions_extension_version   = "~4"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uami.id]
  }

  site_config {
    minimum_tls_version                    = "1.2"
    ftps_state                             = "FtpsOnly"
    scm_minimum_tls_version                = "1.2"
    always_on                              = true
    http2_enabled                          = true
    application_insights_key               = azurerm_application_insights.function_insights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.function_insights.connection_string

    application_stack {
      dotnet_version = "v8.0"
    }
    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
    vnet_route_all_enabled = true
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "AzureWebJobs__disableAnonymousAuth"  = "true"
    "AzureWebJobsStorage__blobServiceUri" = "https://${azurerm_storage_account.function_storage.name}.blob.core.windows.net"
    "AzureWebJobsStorage__credential" = "ManagedIdentity"
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "azurerm_private_endpoint" "function_app_pep" {
  name                = "${var.function_app_name}-pep"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "${var.function_app_name}-psc"
    private_connection_resource_id = azurerm_windows_function_app.function_app.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "functionapp-dns-zone-group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.function_app_dns_zone.id]
  }

  tags = {
    environment = var.environment
    project     = var.project_name
  }
}

resource "null_resource" "deploy_sample_zip_windows_fnapp" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<EOT
      # Set error action preference to stop on errors
      $ErrorActionPreference = "Stop"

      Write-Output "Starting Function App deployment process..."

      # Set the Azure subscription context
      Write-Output "Setting Azure subscription context..."
      az account set --subscription "${var.subscription_id}"
      if ($LASTEXITCODE -ne 0) { 
        Write-Error "Failed to set Azure subscription context"
        exit 1 
      }

      # Build the .NET Function App
      Write-Output "Building .NET Function App..."
      Set-Location ".\FunctionApp"

      # Verify the function files exist
      Write-Output "Checking function files..."
      if (-not (Test-Path "HelloWorldFunction.cs")) {
        Write-Error "HelloWorldFunction.cs not found in FunctionApp directory"
        exit 1
      }
      if (-not (Test-Path "FunctionApp.csproj")) {
        Write-Error "FunctionApp.csproj not found in FunctionApp directory"
        exit 1
      }

      dotnet restore
      if ($LASTEXITCODE -ne 0) { 
        Write-Error "dotnet restore failed"
        exit 1 
      }

      dotnet publish -c Release -o ..\publish
      if ($LASTEXITCODE -ne 0) { 
        Write-Error "dotnet publish failed"
        exit 1 
      }

      # Verify publish output
      Set-Location ".."
      Write-Output "Checking publish directory contents..."
      Get-ChildItem -Path ".\publish" -Recurse | Format-Table Name, Length, LastWriteTime

      # Create deployment package using .NET compression (more reliable)
      Write-Output "Creating deployment package using .NET compression..."
      try {
        # Load the compression assembly
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        # Remove existing zip if it exists
        if (Test-Path ".\functionapp.zip") { 
          Remove-Item ".\functionapp.zip" -Force 
        }

        # Create the zip file
        $publishPath = Join-Path (Get-Location) "publish"
        $zipPath = Join-Path (Get-Location) "functionapp.zip"

        if (-not (Test-Path $publishPath)) {
          Write-Error "Publish directory not found: $publishPath"
          exit 1
        }

        [System.IO.Compression.ZipFile]::CreateFromDirectory($publishPath, $zipPath)

        Write-Output "Deployment package created successfully: $zipPath"
      } catch {
        Write-Error "Failed to create deployment package: $($_.Exception.Message)"
        exit 1
      }

      # Verify the zip file was created
      if (-not (Test-Path ".\functionapp.zip")) {
        Write-Error "Deployment package was not created successfully"
        exit 1
      }

      # Deploy to Azure Function App
      Write-Output "Deploying to Azure Function App..."
      az functionapp deployment source config-zip --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --src ".\functionapp.zip"

      if ($LASTEXITCODE -ne 0) { 
        Write-Error "Function App deployment failed"
        exit 1 
      }

      # Verify deployment succeeded using alternative methods
      Write-Output "Verifying deployment..."

      # Check if the function app is running
      $appStatus = az functionapp show --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --query "state" --output tsv
      Write-Output "Function App state: $appStatus"

      # Get function app configuration to verify runtime settings
      $runtimeVersion = az functionapp config show --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --query "netFrameworkVersion" --output tsv
      Write-Output "Runtime version: $runtimeVersion"

      # Wait for deployment to complete
      Write-Output "Waiting for deployment to complete..."
      Start-Sleep -Seconds 60

      # Check deployment status and list functions
      Write-Output "Checking function app status and listing functions..."

      # List all functions in the function app
      Write-Output "Listing functions..."
      az functionapp function list --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --output table

      # Check if HelloWorld function specifically exists
      $functionExists = az functionapp function show --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --function-name "HelloWorld" --query "name" --output tsv 2>$null
      if ($functionExists) {
        Write-Output "HelloWorld function found: $functionExists"
      } else {
        Write-Warning "HelloWorld function not found in function app"
      }

      # Check the function app's default document and site status
      $siteStatus = az functionapp show --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --query "{state:state, availabilityState:availabilityState, defaultHostName:defaultHostName}" --output json | ConvertFrom-Json
      Write-Output "Site Status: $($siteStatus.state), Availability: $($siteStatus.availabilityState)"
      Write-Output "Default Host Name: $($siteStatus.defaultHostName)"

      # Test the function (this may fail if behind private endpoints)
      Write-Output "Testing deployed function..."
      try {
        # Since we set AuthorizationLevel.Anonymous, test without function key first
        $functionUrl = "https://${azurerm_windows_function_app.function_app.default_hostname}/api/HelloWorld"
        Write-Output "Testing anonymous function at: $functionUrl"
        $response = Invoke-RestMethod -Uri $functionUrl -UseBasicParsing -TimeoutSec 60
        Write-Output "Function test successful: $response"
      } catch {
        Write-Warning "Anonymous function test failed: $($_.Exception.Message)"

        # Try to get more detailed error information
        Write-Output "Attempting to get detailed error information..."
        try {
          $detailedResponse = Invoke-WebRequest -Uri $functionUrl -UseBasicParsing -TimeoutSec 60
          Write-Output "HTTP Status Code: $($detailedResponse.StatusCode)"
          Write-Output "Response Content: $($detailedResponse.Content)"
        } catch {
          Write-Output "Detailed error: $($_.Exception.Message)"
        }

        # Check function app logs
        Write-Output "Checking recent function app logs..."
        az functionapp logs tail --name ${azurerm_windows_function_app.function_app.name} --resource-group ${azurerm_resource_group.main.name} --timeout 10

        Write-Output "Manual testing URLs:"
        Write-Output "- Anonymous: https://${azurerm_windows_function_app.function_app.default_hostname}/api/HelloWorld"
        Write-Output "- Admin: https://${azurerm_windows_function_app.function_app.name}.scm.azurewebsites.net/"
      }

      # Cleanup
      Write-Output "Cleaning up temporary files..."
      Remove-Item -Path ".\publish" -Recurse -Force -ErrorAction SilentlyContinue
      Remove-Item -Path ".\functionapp.zip" -Force -ErrorAction SilentlyContinue

      Write-Output "Deployment completed successfully!"
    EOT
  }
  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    azurerm_windows_function_app.function_app,
    azurerm_storage_account.function_storage,
    azurerm_private_endpoint.function_app_pep,
    azurerm_private_endpoint.storage_blob_pep
  ]
}