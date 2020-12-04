
output "consul_uri" {
  value = "http://${aws_instance.consul.public_ip}:8500"
}
