resource "aws_rds_cluster_instance" "reader" {
  identifier         = "bt01-aurora-reader-1"
  cluster_identifier = "bt01-aurora"  # ties the instance to the cluster
  instance_class = "db.t4g.medium"                     # compute size — smallest that supports Aurora
  engine         = "aurora-postgresql"  # inherit engine from cluster
}