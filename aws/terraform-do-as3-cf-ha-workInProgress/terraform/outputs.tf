output "f5-1_ip" {
  value = "${aws_eip.f5-1.public_ip}"
}

output "f5-2_ip" {
  value = "${aws_eip.f5-2.public_ip}"
}

output "f5_password" {
  value = "${random_string.password.result}"
}

output "f5_username" {
  value = "${var.username}"
}

output "f5-1_ui" {
  value = "https://${aws_eip.f5-1.public_ip}:${var.port}"
}

output "f5-2_ui" {
  value = "https://${aws_eip.f5-2.public_ip}:${var.port}"
}

output "f5-1_ssh" {
  value = "ssh admin@${aws_eip.f5-1.public_ip} -i ssh-key.pem"
}

output "f5-2_ssh" {
  value = "ssh admin@${aws_eip.f5-2.public_ip} -i ssh-key.pem"
} 