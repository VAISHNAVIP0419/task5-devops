resource "aws_instance" "jenkins" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = "lab-key"

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "task5-jenkins"
    Role = "jenkins"
  }
}

resource "aws_instance" "nexus" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = "lab-key"

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "task5-nexus"
    Role = "nexus"
  }
}