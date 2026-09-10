# BLOCK: output {}
# Prints a value to the terminal after `terraform apply` completes.
# Useful for grabbing IDs (VPC, RDS endpoint) without opening the AWS console.
#
# output "default_vpc_id"
#     │         │
#     │         └── output name  (what you see in the terminal)
#     └── keyword: declares a value to expose after apply
#
# value = data.aws_vpc.default.id
#          │    │       │      │
#          │    │       │      └── attribute  (the VPC ID)
#          │    │       └── data source name  (local alias in data.tf)
#          │    └── data source type
#          └── keyword: this is a data lookup, not a managed resource
output "default_vpc_id" {
  description = "ID of the existing default VPC"
  value       = data.aws_vpc.default.id
}

# value = aws_vpc.bt01_vpc.id
#          │       │        │
#          │       │        └── attribute  (the VPC ID Terraform just created)
#          │       └── resource name  (local alias in aws-create-vpc.tf)
#          └── resource type
#output "aws_vpc" {
#  description = "ID of the newly created VPC"
#  value       = aws_vpc.bt01_vpc.id
#}
