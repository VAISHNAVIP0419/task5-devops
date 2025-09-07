resource "aws_instance" "server" {
  ami           = "ami-0f58b397bc5c1f2e8" # Ubuntu 22.04 LTS (ap-south-1)
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name      = "lab-key"

  user_data = file("${path.module}/user_data.sh")

  tags = { Name = "task5-server" }
}