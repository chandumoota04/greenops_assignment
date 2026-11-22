# Alarm notifications. The e-mail subscription is added once with the CLI so
# no personal address is kept in the repository. Not encrypted: CloudWatch
# cannot publish to a topic using the AWS managed SNS key, and the messages
# carry only alarm names and states.
# kics-scan ignore-block
resource "aws_sns_topic" "alerts" {
  name = "surplus-food-alerts"
}

# Route 53 checks /api/health from several AWS locations outside the VPC, so
# it sees what a visitor sees and needs no agent or timer on the server.
resource "aws_route53_health_check" "app" {
  ip_address        = aws_eip.web.public_ip
  port              = 80
  type              = "HTTP_STR_MATCH"
  resource_path     = "/api/health"
  search_string     = "\"status\":\"ok\""
  request_interval  = 30
  failure_threshold = 3
  tags              = { Name = "surplus-food-health" }
}

# Route 53 health-check metrics are only published in us-east-1.
resource "aws_cloudwatch_metric_alarm" "app_unhealthy" {
  alarm_name          = "surplus-food-app-unhealthy"
  alarm_description   = "Public health check failing for 2 consecutive minutes"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions          = { HealthCheckId = aws_route53_health_check.app.id }
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  comparison_operator = "LessThanThreshold"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "surplus-food-web-cpu-high"
  alarm_description   = "CPU above 70% for 10 minutes suggests the instance is undersized"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = aws_instance.web.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 70
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Created here, not by the agent, so the retention is fixed in code.
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/surplus-food/nginx-access"
  retention_in_days = 7
}

# Request and error counts come from the Nginx access log, so the API needs no
# metrics library. Fields follow the default "combined" log format.
resource "aws_cloudwatch_log_metric_filter" "requests" {
  name           = "surplus-food-requests"
  log_group_name = aws_cloudwatch_log_group.nginx.name
  pattern        = "[ip, ident, user, time, request, status, bytes, referrer, agent]"

  metric_transformation {
    name          = "Requests"
    namespace     = "SurplusFood"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_log_metric_filter" "server_errors" {
  name           = "surplus-food-5xx"
  log_group_name = aws_cloudwatch_log_group.nginx.name
  pattern        = "[ip, ident, user, time, request, status=5*, bytes, referrer, agent]"

  metric_transformation {
    name          = "ServerErrors"
    namespace     = "SurplusFood"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "surplus-food-web-memory-high"
  alarm_description   = "Memory above 85% for 10 minutes; the JVM heap or instance size needs review"
  namespace           = "SurplusFood"
  metric_name         = "mem_used_percent"
  dimensions          = { InstanceId = aws_instance.web.id }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 85
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

locals {
  web_id = aws_instance.web.id
  db_id  = aws_db_instance.main.identifier
  hc_id  = aws_route53_health_check.app.id
  graphs = [
    ["Public health check (1 = healthy)", "Minimum", 60, [["AWS/Route53", "HealthCheckStatus", "HealthCheckId", local.hc_id]]],
    ["Requests and 5xx errors per minute", "Sum", 60, [["SurplusFood", "Requests"], ["SurplusFood", "ServerErrors"]]],
    ["CPU utilisation (%)", "Average", 60, [["AWS/EC2", "CPUUtilization", "InstanceId", local.web_id, { label = "EC2 web" }], ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", local.db_id, { label = "RDS" }]]],
    ["EC2 memory, disk and swap used (%)", "Average", 60, [["SurplusFood", "mem_used_percent", "InstanceId", local.web_id], ["SurplusFood", "used_percent", "InstanceId", local.web_id], ["SurplusFood", "swap_used_percent", "InstanceId", local.web_id]]],
    ["Route 53 checkers reporting healthy (%)", "Average", 60, [["AWS/Route53", "HealthCheckPercentageHealthy", "HealthCheckId", local.hc_id]]],
    ["EC2 network in / out (bytes)", "Sum", 300, [["AWS/EC2", "NetworkIn", "InstanceId", local.web_id], ["AWS/EC2", "NetworkOut", "InstanceId", local.web_id]]],
    ["RDS read / write IOPS", "Average", 60, [["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", local.db_id], ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", local.db_id]]],
    ["RDS connections and EC2 CPU credits", "Average", 300, [["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", local.db_id], ["AWS/EC2", "CPUCreditBalance", "InstanceId", local.web_id, { yAxis = "right" }]]],
  ]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "surplus-food"
  dashboard_body = jsonencode({
    widgets = [for i, g in local.graphs : {
      type   = "metric"
      x      = (i % 2) * 12
      y      = floor(i / 2) * 6
      width  = 12
      height = 6
      properties = {
        title   = g[0]
        stat    = g[1]
        period  = g[2]
        metrics = g[3]
        region  = var.region
        view    = "timeSeries"
      }
    }]
  })
}
