# terraform-azfunction-private-sample

This project uses Terraform to deploy a secure, private Azure Function App environment with supporting infrastructure.

## What is Deployed

The following Azure resources are created:

- **Resource Group**: Container for all resources.
- **User-Assigned Managed Identity**: For secure access to storage from the Function App.
- **Storage Account**: For Azure Functions runtime and triggers, with private endpoint.
- **Private Endpoint (Storage)**: Private access to the storage account (blob service).
- **Log Analytics Workspace**: For Application Insights monitoring.
- **Application Insights**: For monitoring and logging the Function App.
- **App Service Plan**: Windows plan for hosting the Function App.
- **Windows Function App**: .NET 8 isolated process, VNet integrated, with private endpoint.
- **Private Endpoint (Function App)**: Private access to the Function App.
- **Role Assignments**: RBAC for storage access (both for current user and managed identity).
- **VNet/Subnet References**: Uses existing subnets for private endpoints and VNet integration.
- **Private DNS Zone References**: Uses existing DNS zones for blob and function app endpoints.

## Prerequisites

- **Azure Subscription**: You must have access to an Azure subscription.
- **Existing Virtual Network and Subnets**:
	- Subnet for private endpoints
	- Subnet for Function App VNet integration
	- Resource group for subnets and DNS zones
- **Existing Private DNS Zones**:
	- `privatelink.blob.core.windows.net`
	- `privatelink.azurewebsites.net`
- **Terraform**: v1.3 or later
- **Azure CLI**: Logged in and set to the correct subscription
- **.NET 8 SDK**: For building and publishing the Function App code

## Required Variables for `terraform.tfvars`

Copy and fill in these variables in your `terraform.tfvars` file:

```hcl
resource_group_name              = "<your-resource-group-name>"
subscription_id                  = "<your-subscription-id>"
location                         = "<azure-region>"
environment                      = "<environment-name>"
project_name                     = "<project-name>"
managed_identity_name            = "<managed-identity-name>"
storage_account_name             = "<storage-account-name>" # 3-24 lowercase letters/numbers
application_insights_name        = "<app-insights-name>"
log_analytics_workspace_name     = "<log-analytics-workspace-name>"
app_service_plan_name            = "<app-service-plan-name>"
function_app_name                = "<function-app-name>" # 2-60 chars, alphanumeric or hyphens, start/end with alphanumeric
subnet_resource_group_name       = "<subnet-resource-group-name>"
virtual_network_name             = "<vnet-name>"
pep_subnet_name                  = "<private-endpoint-subnet-name>"
function_app_injection_subnet_name = "<function-app-injection-subnet-name>"
```

All variables are required and must be set for a successful deployment.

## Usage

1. Clone this repository.
2. Update `terraform.tfvars` with your environment-specific values.
3. Run `terraform init` to initialize the workspace.
4. Run `terraform plan` to review changes.
5. Run `terraform apply` to deploy resources.

## Deploying the HelloWorld Function

This project includes a sample .NET isolated Azure Function called **HelloWorld** (see `FunctionApp/HelloWorldFunction.cs`).

After the infrastructure is deployed, the function is published and deployed to the Function App using a zip deploy process. The included (commented) `null_resource` in `main.tf` demonstrates how to build, package, and deploy the function using PowerShell and the Azure CLI:

- Builds the .NET function app
- Packages the output as a zip file
- Deploys the zip to Azure using `az functionapp deployment source config-zip`

You can adapt or uncomment this resource to automate deployment, or run the steps manually as described in the script.

## Notes

- The Function App is deployed with private endpoints and VNet integration for secure, internal-only access.
- You must have Owner or Contributor rights in the target subscription/resource group.
- The HelloWorld function will be available at `/api/HelloWorld` (private endpoint only).

---
For more details, see the comments in the Terraform files and the deployment script.