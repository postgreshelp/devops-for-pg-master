# ── DB Subnet Group ───────────────────────────────────────────────────────────
# Tells Aurora which subnets it is allowed to place its nodes in.
# RDS requires at least two subnets in different Availability Zones —
# that is why we created subnets in us-east-1a AND us-east-1b.
resource "aws_db_subnet_group" "bt01_aurora" {
  name = "bt01-aurora-subnet-group"

  subnet_ids = [
    aws_subnet.bt01_public_subnet.id,  # us-east-1a  (defined in aws-networking.tf)
    aws_subnet.bt01_private_subnet.id  # us-east-1b
  ]

  tags = {
    Name = "bt01-aurora-subnet-group"
  }
}

# ── Security Group ────────────────────────────────────────────────────────────
# Controls which traffic can reach Aurora (ingress) and leave it (egress).
#
# LAB SETTING — protocol = "-1" with cidr_blocks = ["0.0.0.0/0"] means
# ALL ports, ALL protocols, from ANYWHERE. Fine for a throwaway lab.
# In production: restrict ingress to port 5432 from your app's security group only.
resource "aws_security_group" "bt01_aurora" {
  name        = "bt01-aurora-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = aws_vpc.bt01_vpc.id # must live in the same VPC as the cluster

  ingress {
    description = "PostgreSQL"
    from_port   = 0             # 0 + protocol "-1" = all ports
    to_port     = 0
    protocol    = "-1"          # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"] # allow from anywhere — lab only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bt01-aurora-sg"
  }
}

# ── Aurora Cluster ────────────────────────────────────────────────────────────
# The cluster is the logical container — it holds the shared storage volume
# and the cluster endpoint. It has NO compute until an instance is added below.
#
# aws_rds_cluster.bt01_aurora
#  │               │
#  │               └── resource name
#  └── resource type
#
# skip_final_snapshot = true means Terraform will destroy the cluster without
# taking a backup snapshot first. Correct for a lab; never for production.
resource "aws_rds_cluster" "bt01_aurora" {
  cluster_identifier = "bt01-aurora"
  engine             = "aurora-postgresql"

  master_username = "postgres"   # LAB ONLY — use AWS Secrets Manager in production
  master_password = "postgres"   # LAB ONLY — never hardcode passwords in real configs

  db_subnet_group_name   = aws_db_subnet_group.bt01_aurora.name
  vpc_security_group_ids = [aws_security_group.bt01_aurora.id]

  database_name = "paylite"      # initial database created inside the cluster

  skip_final_snapshot = true     # no backup on destroy — safe for labs, dangerous in prod

  tags = {
    Name = "bt01-aurora"
  }
}

# ── Aurora Cluster Instance ───────────────────────────────────────────────────
# The actual compute node. The cluster and its instance are separate objects:
# a cluster with zero instances is valid (just unreachable) — this matters when
# you add read replicas later (each replica is another cluster instance).
#
# cluster_identifier links this instance to the cluster above.
# engine is inherited from the cluster so both always stay in sync.
resource "aws_rds_cluster_instance" "bt01_aurora" {
  identifier         = "bt01-aurora-instance-1"
  cluster_identifier = aws_rds_cluster.bt01_aurora.id # ties the instance to the cluster

  instance_class = "db.t3.medium"                     # compute size — smallest that supports Aurora
  engine         = aws_rds_cluster.bt01_aurora.engine  # inherit engine from cluster

  tags = {
    Name = "bt01-aurora-instance-1"
  }
}
