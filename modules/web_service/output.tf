# EC2 Instance Outputs
output "web_instance_sg_id" {
  value = aws_security_group.web_instance_sg.id
}
output "web_instance_arn" {
  value = aws_instance.web_instance.arn
}

output "web_instance_id" {
  value = aws_instance.web_instance.id
}

# ALB Outputs
output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_id" {
  value = aws_lb.alb.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}

