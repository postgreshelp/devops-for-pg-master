# BLOCK: terraform {}
# Tells Terraform which providers this project needs and what versions to download.
# Without this, `terraform init` would not know what to install.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # who publishes the plugin (registry.terraform.io/hashicorp/aws)
      version = "6.63.0"        # pin exact version so every team member gets identical behaviour
    }
  }
}

# BLOCK: provider "aws" {}
# Configures the AWS plugin that was declared above.
# Terraform uses this to know which region to make API calls in.
#
# provider "aws"
#     │         │
#     │         └── provider local name (must match the key in required_providers)
#     └── keyword: configures a provider, not a resource
provider "aws" {
  region = "us-east-1"
}
