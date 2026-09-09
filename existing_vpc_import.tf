# ── Import Exercise ───────────────────────────────────────────────────────────
# This block brings a VPC that ALREADY EXISTS in AWS under Terraform management.
# You do not create it here — the VPC was created manually in the AWS console.
#
# The three-step import process:
#   Step 1 - Create VPC manually
#   Step 1 — write this resource block with arguments that MATCH the real VPC
#   Step 2 — run: terraform import aws_vpc.default_import <vpc-id>
#
# terraform import aws_vpc.existing_vpc_import vpc-02f476ec787e998c6
#                   │       │              │
#                   │       │              └── real AWS resource ID (from aws ec2 describe-vpcs)
#                   │       └── resource name in this file (must exist before you import)
#                   └── resource type
#
# ⚠️  IMPORTANT: import only writes to the state file — it does NOT read your
# .tf arguments and check they match. Always run `terraform plan` right after
# import. If it proposes changes, fix this file's values to match reality
# (copy them from `terraform show` or the AWS console) before applying.
resource "aws_vpc" "existing_vpc_import" {
  cidr_block           = "172.31.0.0/16" # must match the real VPC's CIDR exactly
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "B02_VPC"
  }
}
