output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "nexus_public_ip" {
  value = aws_instance.nexus.public_ip
}