resource "aws_instance" "Ec2" {
  ami           = "ami-03d1820163e6b9f5d" # ap-northeast-1
  instance_type = var.instance_type

  security_groups = [aws_security_group.ec2-sg.id, aws_security_group.rds_sg.id]
  subnet_id = aws_subnet.public_a.id
  associate_public_ip_address = true
  #public_dns = true
  

  #user_data = file("user_data.sh")

   tags = {
     Name = "${local.name_prefix}-ec2"
   }
  
}