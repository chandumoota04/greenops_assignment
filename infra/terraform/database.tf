resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "surplus-food"
  subnet_ids = aws_subnet.private[*].id
}

# Single-AZ: a small register for one food bank does not justify a standby
# instance that doubles the always-on database compute.
resource "aws_db_instance" "main" {
  identifier                 = "surplus-food"
  engine                     = "postgres"
  engine_version             = "16"
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true
  db_name                    = "surplus"
  username                   = "surplus_app"
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.db.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 7
  deletion_protection        = true
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "surplus-food-final"
  apply_immediately          = true
  # Connection and error logs go to CloudWatch for a short, fixed period.
  enabled_cloudwatch_logs_exports = ["postgresql"]
  depends_on                      = [aws_cloudwatch_log_group.rds]
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/surplus-food/postgresql"
  retention_in_days = 7
}

# Read by the CodeDeploy AfterInstall hook on EC2, so the password never passes
# through GitHub, the release bundle or the browser.
resource "aws_ssm_parameter" "db_host" {
  name  = "/surplus-food/db/host"
  type  = "String"
  value = aws_db_instance.main.address
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/surplus-food/db/password"
  type  = "SecureString"
  value = random_password.db.result
}
