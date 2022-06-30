resource "aws_db_subnet_group" "test_db_subnet_group" {
  name       = "test_db_subnet_group"
  subnet_ids = [aws_subnet.test_subnet_private_1.id, aws_subnet.test_subnet_private_2.id]
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage          = 10
  engine                     = "mysql"
  engine_version             = "5.7"
  instance_class             = "db.t3.micro"
  name                       = "wordpress" 
  username                   = local.db_cred.db_username
  password                   = local.db_cred.db_password
  parameter_group_name       = "default.mysql5.7"
  skip_final_snapshot        = true
  backup_retention_period    = 3
  vpc_security_group_ids     = [aws_security_group.sg_rds.id]
  db_subnet_group_name       = aws_db_subnet_group.test_db_subnet_group.name

  tags = {
    Name = "wordpress_db"
  }
}