output "jenkins_public_ip" {
  description = "Public IP of Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "sonarqube_url" {
  description = "SonarQube URL"
  value       = "http://${aws_instance.sonar.public_ip}:9000"
}

output "nexus_url" {
  description = "Nexus URL"
  value       = "http://${aws_instance.nexus.public_ip}:8081"
}

output "ansible_master_ip" {
  description = "Public IP of Ansible master"
  value       = aws_instance.ansible_master.public_ip
}

output "ansible_slave_ip" {
  description = "Public IP of Ansible slave"
  value       = aws_instance.ansible_slave.public_ip
}

output "app_server_ip" {
  description = "Public IP of application server"
  value       = aws_instance.app_server.public_ip
}

output "ansible_inventory" {
  description = "Generated Ansible inventory file path (local machine)"
  value       = abspath(local_file.ansible_inventory.filename)
}
