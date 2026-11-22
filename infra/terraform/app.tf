data "aws_ssm_parameter" "al2023_arm" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_instance" "web" {
  ami                    = data.aws_ssm_parameter.al2023_arm.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = var.instance_profile
  # The Elastic IP is attached separately, but the agent needs a route out
  # while the instance first boots.
  associate_public_ip_address = true
  user_data                   = file("${path.module}/../../scripts/ec2-bootstrap.sh")

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
  }

  # A newer AMI must not replace the running server on every apply.
  lifecycle {
    ignore_changes = [ami, user_data]
  }

  # CodeDeploy finds the deployment target by this tag.
  tags = { Name = "surplus-food-web", DeployGroup = "surplus-food" }
}

# Stable public address kept for the whole assessment period.
resource "aws_eip" "web" {
  domain = "vpc"
  tags   = { Name = "surplus-food-web" }
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}
