resource "aws_instance" "bastion" {
  ami           = data.aws_ami.latest_ubuntu_linux.id
  instance_type = "t2.micro"
  key_name      = "bastion"
  subnet_id = aws_subnet.test_subnet_public_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "bastion"
  }
}