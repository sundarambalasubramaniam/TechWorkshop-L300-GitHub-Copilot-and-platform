# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava's transition to Azure is robust, secure, and future-ready.

## ZavaStorefront Application

The ZavaStorefront is a sample e-commerce web application built with ASP.NET Core MVC (.NET 6) that demonstrates modern cloud deployment practices on Azure.

### Application Features

- Product catalog with 8 sample products
- Shopping cart functionality
- Session-based state management
- Responsive Bootstrap UI
- Application Insights integration for monitoring

### Deployment to Azure

The application is fully containerized and can be deployed to Azure using Infrastructure as Code (Bicep) with the Azure Developer CLI (AZD).

#### Quick Start

1. **Prerequisites**:
   - [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
   - [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
   - An Azure subscription

2. **Deploy to Azure**:
   ```bash
   # Clone the repository
   git clone <repository-url>
   cd TechWorkshop-L300-GitHub-Copilot-and-platform
   
   # Login to Azure
   az login
   azd auth login
   
   # Initialize and deploy
   azd init
   azd up
   ```

3. **Access the application**:
   After deployment, AZD will display the Web App URL. Visit the URL in your browser.

#### Infrastructure Details

The deployment provisions the following Azure resources in **westus3**:

- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan**: Linux-based B1 SKU for cost optimization
- **Web App**: Linux App Service configured as Web App for Containers
- **Application Insights**: Application monitoring and diagnostics
- **AI Hub**: Microsoft Foundry for GPT-4 and Phi model access
- **Managed Identity**: System-assigned identity for secure ACR access (no passwords)
- **Role Assignment**: AcrPull role for container image retrieval

All resources are deployed to a single resource group (e.g., `rg-zavastore-dev-westus3`).

For detailed infrastructure documentation, deployment options, troubleshooting, and cost estimates, see [infra/README.md](infra/README.md).

#### Continuous Deployment

The repository includes a GitHub Actions workflow (`.github/workflows/deploy-azure.yml`) that automates:
- Building Docker images in Azure Container Registry (cloud-based build)
- Deploying new images to Azure App Service
- No local Docker installation required

### Local Development

To run the application locally:

```bash
cd src
dotnet restore
dotnet run
```

Then open `https://localhost:5001` in your browser.

For more details about the application, see [src/README.md](src/README.md).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
