data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "surplus-food" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# No NAT gateway: only the web server needs outbound access and it has a public
# address; a NAT gateway would cost more per hour than the server itself.
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.30.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags              = { Name = "surplus-food-public" }
}

# RDS needs a subnet group in two zones even for a single-AZ instance.
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.30.${count.index + 21}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "surplus-food-private-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Rejected connections only, batched every 10 minutes into the release bucket:
# enough to see probing of closed ports without logging every accepted request.
resource "aws_flow_log" "main" {
  vpc_id                   = aws_vpc.main.id
  traffic_type             = "REJECT"
  log_destination_type     = "s3"
  log_destination          = "arn:aws:s3:::${local.release_bucket}/flow-logs/"
  max_aggregation_interval = 600
}

resource "aws_security_group" "web" {
  name        = "surplus-food-web"
  description = "Public HTTP to Nginx; no SSH, shell access is through SSM"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "db" {
  name        = "surplus-food-db"
  description = "PostgreSQL from the web server only"
  vpc_id      = aws_vpc.main.id
}

# Open HTTP is the purpose of this server: examiners reach the app by URL with
# no account. There is no domain in the lab account, so no certificate for 443.
# kics-scan ignore-block
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "Public HTTP for the web application"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# HTTPS out is needed by the CodeDeploy agent, SSM, CloudWatch and the Amazon
# Linux package mirrors. Plain HTTP and every other port stay closed.
resource "aws_vpc_security_group_egress_rule" "web_https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS to AWS service endpoints and package mirrors"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_to_db" {
  security_group_id            = aws_security_group.web.id
  description                  = "PostgreSQL to RDS"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from the web server"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.web.id
}
