variable "region" {
  description = "AWS region for every resource"
  type        = string
  default     = "us-east-1"
}

# Graviton (Arm) sizes: the JVM runs unchanged on Arm, and AWS rates Graviton
# at up to 60% less energy than comparable x86 instances for the same work.
variable "instance_type" {
  description = "EC2 size for Nginx and the Spring Boot API"
  type        = string
  default     = "t4g.small"
}

variable "db_instance_class" {
  description = "RDS size"
  type        = string
  default     = "db.t4g.micro"
}

variable "instance_profile" {
  description = "Existing instance profile (AWS Academy accounts cannot create IAM roles)"
  type        = string
  default     = "LabInstanceProfile"
}

variable "service_role" {
  description = "Existing role CodeDeploy acts as (LabRole trusts codedeploy.amazonaws.com)"
  type        = string
  default     = "LabRole"
}
