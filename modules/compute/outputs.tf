output "compute_sg_id" {
  description = "ID del security group de compute"
  value       = aws_security_group.compute.id
}
