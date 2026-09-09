# ── Internet Gateway ──────────────────────────────────────────────────────────
# Attaches an internet gateway to the VPC.
# Without this, nothing inside the VPC can reach the public internet.
#
# aws_internet_gateway.bt01_igw.id
#  │                    │       │
#  │                    │       └── attribute  (gateway ID)
#  │                    └── resource name
#  └── resource type
resource "aws_internet_gateway" "bt01_igw" {
  vpc_id = aws_vpc.bt01_vpc.id # attach to the VPC created in aws-create-vpc.tf

  tags = {
    Name = "bt01-igw"
  }
}

# ── Public Subnet ─────────────────────────────────────────────────────────────
# Carves 256 addresses out of the VPC CIDR, tied to one Availability Zone.
# map_public_ip_on_launch = true is what makes this subnet "public" —
# any resource launched here automatically gets a public IP.
resource "aws_subnet" "bt01_public_subnet" {
  vpc_id                  = aws_vpc.bt01_vpc.id
  cidr_block              = "10.0.1.0/24"  # 256 addresses (10.0.1.0 – 10.0.1.255)
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true            # auto-assign public IP to resources in this subnet

  tags = {
    Name = "bt01-public-subnet"
  }
}

# ── Private Subnet ────────────────────────────────────────────────────────────
# No map_public_ip_on_launch — resources here get only private IPs.
# Aurora will sit here in production; public subnet is used for the lab only.
resource "aws_subnet" "bt01_private_subnet" {
  vpc_id            = aws_vpc.bt01_vpc.id
  availability_zone = "us-east-1b"         # different AZ from the public subnet (Aurora requires 2 AZs)
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "bt01-private-subnet"
  }
}

# ── Route Table ───────────────────────────────────────────────────────────────
# Defines how traffic leaves the VPC.
# The single route "0.0.0.0/0 → bt01_igw" sends ALL outbound traffic through
# the internet gateway — making any associated subnet internet-routable.
resource "aws_route_table" "bt01_route_table" {
  vpc_id = aws_vpc.bt01_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                       # match all destinations
    gateway_id = aws_internet_gateway.bt01_igw.id  # send them through the internet gateway
  }

  tags = {
    Name = "bt01-route-table"
  }
}

# ── Route Table Associations ──────────────────────────────────────────────────
# Binds a subnet to a route table.
# IMPORTANT: a subnet with no association uses the VPC's default route table,
# which has no internet route — the subnet stays sealed even if the gateway exists.
resource "aws_route_table_association" "bt01_public_subnet_association" {
  subnet_id      = aws_subnet.bt01_public_subnet.id
  route_table_id = aws_route_table.bt01_route_table.id
}

resource "aws_route_table_association" "bt01_private_subnet_association" {
  subnet_id      = aws_subnet.bt01_private_subnet.id
  route_table_id = aws_route_table.bt01_route_table.id
}
