# EBS for Jenkins
resource "aws_ebs_volume" "jenkins_data" {
  availability_zone = "ap-south-1a"
  size              = 10
  tags = {
    Name = "task5-ebs-jenkins"
    Role = "jenkins"
  }
}

resource "aws_volume_attachment" "jenkins_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins_data.id
  instance_id = aws_instance.jenkins.id
  force_detach = true
  # attach after instance is created
  depends_on = [aws_instance.jenkins]
}

# EBS for Nexus
resource "aws_ebs_volume" "nexus_data" {
  availability_zone = "ap-south-1a"
  size              = 10
  tags = {
    Name = "task5-ebs-nexus"
    Role = "nexus"
  }
}

resource "aws_volume_attachment" "nexus_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.nexus_data.id
  instance_id = aws_instance.nexus.id
  force_detach = true
  depends_on = [aws_instance.nexus]
}