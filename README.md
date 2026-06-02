# Azure AD Linux Terraform Project

This repository contains Terraform code to provision a lab environment in Azure.

Safe publishing instructions:
- Do NOT commit real secret values. Create terraform.tfvars from Terraform/terraform.tfvars.example and fill values locally.
- The repository includes Terraform/*.example files showing required variables and structure.
- .gitignore excludes .terraform/, *.tfvars, *.tfstate, and .terraform.lock.hcl.

Usage:
1. Copy example variables: cp Terraform/terraform.tfvars.example Terraform/terraform.tfvars
2. Edit Terraform/terraform.tfvars with secure values (do not commit).
3. Run: terraform init && terraform plan && terraform apply

CI/Secrets:
- Use GitHub Actions secrets or Azure Key Vault for CI runs.

Project summary added by assistant:
- This repository provisions an Azure lab environment with networking, Linux and Windows VMs, and Active Directory components.
- Sensitive values (passwords, private keys) are not committed. Redacted .example files were created for files that contained potential secrets; non-sensitive files were added directly.
- Terraform examples live under Terraform/*.example. Create Terraform/terraform.tfvars locally from the example and do NOT commit it.

Security notes:
- Rotate any credentials if they were previously committed.
- Use GitHub Actions secrets or Azure Key Vault for CI and remote state for Terraform.
