output "compute_sg_id" {
  description = "ID del security group de compute"
  value       = aws_security_group.compute.id
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group de compute"
  value       = aws_autoscaling_group.compute.name
}