# Hybrid Zero Trust Governance Lab

This project showcases a secure Azure environment built entirely with Terraform, demonstrating hybrid zero-trust principles and identity-driven access governance.

### Project Overview

The goal of this lab is to separate internal and external workloads while enforcing strong security controls. It combines infrastructure as code, managed identities, and Azure Key Vault to ensure sensitive data is protected and access is controlled.

### Key Components

- **Resource Group**: Contains all lab resources for better organization and management.  
- **App Service Plans and Linux Web Apps**: Two web apps, one for internal users and one for external users, each with a system-assigned managed identity.  
- **Azure Key Vault and Secrets**: Securely stores sensitive information like database passwords.  
- **Key Vault Access Policies**: Configured to allow apps and Terraform itself to access secrets in a controlled way.  
- **Terraform Variables**: Used for sensitive values such as `db_password`, keeping secrets out of code.  

### Skills Demonstrated

- Designing a hybrid zero-trust architecture in Azure.  
- Implementing identity and access governance with managed identities and Key Vault.  
- Automating resource provisioning and configuration with Terraform.  
- Separating workloads based on user type and enforcing security policies.  

### How to Deploy

1. Clone the repository and navigate to the project folder.  
2. Initialize Terraform:
```
terraform init
```
3. Plan the deployment:
```
terraform plan -var "db_password=<your-db-password>"
```
4. Apply the deployment:
```
terraform apply -var "db_password=<your-db-password>"
```
5. Verify the deployed resources in the Azure portal.