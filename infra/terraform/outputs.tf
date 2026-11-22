output "app_url" {
  value = "http://${aws_eip.web.public_ip}"
}

output "instance_id" {
  value = aws_instance.web.id
}

output "release_bucket" {
  value = local.release_bucket
}

output "codedeploy_app" {
  value = aws_codedeploy_app.main.name
}

output "deployment_group" {
  value = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
