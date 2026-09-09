# BLOCK: resource {}
# A managed resource — Terraform creates this, tracks it in state, and owns it from here on.
# Unlike a data source, Terraform will create / update / destroy this as your config changes.
#
# resource "aws_vpc" "bt01_vpc"
#     │        │         │
#     │        │         └── resource name  (your local alias, used to reference it elsewhere)
#     │        └── resource type  (maps to an AWS VPC via the AWS provider)
#     └── keyword: this is a managed resource, not a read-only lookup
#
# How to reference it elsewhere:
#
# aws_vpc.bt01_vpc          ← the resource address (type + name)
#  │       │
#  │       └── resource name
#  └── resource type
#
# aws_vpc.bt01_vpc.id       ← the resource address + an attribute
#  │       │        │
#  │       │        └── attribute  (the VPC ID assigned by AWS after creation)
#  │       └── resource name
#  └── resource type
resource "aws_vpc" "bt01_vpc" {
  cidr_block           = "10.0.0.0/16" # IP range for the VPC — /16 gives ~65,536 addresses
  enable_dns_support   = true           # required for RDS/Aurora endpoints to resolve by name
  enable_dns_hostnames = true           # assigns DNS hostnames to instances inside the VPC

  tags = {
    Name = "bt01-vpc" # AWS console label — hyphens are fine here, this is not a Terraform identifier
  }
}
