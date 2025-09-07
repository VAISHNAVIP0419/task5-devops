resource "aws_ebs_volume" "docker_data" {
  availability_zone = "ap-south-1a"
  size              = 20
  tags = { Name = "task5-ebs" }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.docker_data.id
  instance_id = aws_instance.server.id
  force_detach = true
}