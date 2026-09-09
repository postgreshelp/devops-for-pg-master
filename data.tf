# BLOCK: data {}
# A data source — reads information that already exists in AWS, creates nothing.
# Safe to run at any time; it never changes or destroys anything.
#
# data "aws_vpc" "default" { default = true }
#  │       │         │
#  │       │         └── filter: find the VPC flagged as the account's default
#  │       └── data source type  (provided by the AWS provider)
#  └── keyword: this is a read-only lookup, NOT a managed resource
#
# How to reference it elsewhere:
#
# data.aws_vpc.default.id
#  │    │       │      │
#  │    │       │      └── attribute  (the actual VPC ID string, e.g. "vpc-0abc123")
#  │    │       └── data source name  (the local alias you gave it)
#  │    └── data source type
#  └── keyword: signals this is a data lookup, not a resource
data "aws_vpc" "default" {
  default = true
}
