terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_ami" "latest_ubuntu_linux" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

data "template_file" "user_data" {
  template = "${file("user_data.sh")}"
  vars = {
    db_endpoint = "${aws_db_instance.wordpress_db.address}"
    efs_endpoint = "${aws_efs_file_system.wordpress_efs.dns_name}"
    db_username = "${local.db_cred.db_username}"
    db_password = "${local.db_cred.db_password}"
  }
}

data "aws_secretsmanager_secret_version" "db_cred" {
  secret_id = "db_cred"
}

locals {
  db_cred = jsondecode(data.aws_secretsmanager_secret_version.db_cred.secret_string)
}

resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "test_vpc"
  }
}

resource "aws_subnet" "test_subnet_public_1" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "test_subnet_public_1"
  }
}

resource "aws_subnet" "test_subnet_public_2" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.20.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "test_subnet_public_2"
  }
}

resource "aws_subnet" "test_subnet_private_1" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "test_subnet_private_1"
  }
}

resource "aws_subnet" "test_subnet_private_2" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "10.0.21.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "test_subnet_private_2"
  }
}

resource "aws_internet_gateway" "test_ig" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test_ig"
  }
}

resource "aws_eip" "test_eip" {
  network_border_group = "us-east-1"
}

resource "aws_nat_gateway" "test_nat" {
  allocation_id = aws_eip.test_eip.id
  subnet_id     = aws_subnet.test_subnet_public_1.id

  tags = {
    Name = "test_nat"
  }
}

resource "aws_route_table" "test_rt_public" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_ig.id
  }

  tags = {
    Name = "test_rt_public"
  }
}

resource "aws_route_table" "test_rt_private_1" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test_nat.id
  }

  tags = {
    Name = "test_rt_private_1"
  }
}

resource "aws_route_table" "test_rt_private_2" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test_nat.id
  }

  tags = {
    Name = "test_rt_private_2"
  }
}

resource "aws_route_table_association" "test_public_association_1" {
  subnet_id      = aws_subnet.test_subnet_public_1.id
  route_table_id = aws_route_table.test_rt_public.id
}

resource "aws_route_table_association" "test_public_association_2" {
  subnet_id      = aws_subnet.test_subnet_public_2.id
  route_table_id = aws_route_table.test_rt_public.id
}

resource "aws_route_table_association" "test_private_association_1" {
  subnet_id      = aws_subnet.test_subnet_private_1.id
  route_table_id = aws_route_table.test_rt_private_1.id
}

resource "aws_route_table_association" "test_private_association_2" {
  subnet_id      = aws_subnet.test_subnet_private_2.id
  route_table_id = aws_route_table.test_rt_private_2.id
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "sg for bastion"
  vpc_id      = aws_vpc.test_vpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["46.98.107.16/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion_sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "sg for wordpress_alb"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "sg for wordpress"
  vpc_id      = aws_vpc.test_vpc.id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress_sg"
  }
}

resource "aws_security_group" "sg_rds" {
  name        = "sg_rds"
  description = "sg for rds"
  vpc_id      = aws_vpc.test_vpc.id
  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.wordpress_sg.id]
  }
}

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

resource "aws_launch_configuration" "wordpress_conf" {
  image_id        = data.aws_ami.latest_ubuntu_linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.wordpress_sg.id]
  key_name        = "wordpress-key"
  user_data       = data.template_file.user_data.rendered
}

resource "aws_autoscaling_group" "wordpress_autoscaling" {
  launch_configuration = aws_launch_configuration.wordpress_conf.name
  min_size             = 2
  max_size             = 3
  min_elb_capacity     = 2
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_subnet.test_subnet_private_1.id, aws_subnet.test_subnet_private_2.id]
}

resource "aws_instance" "test_wordpress" {
  ami           = data.aws_ami.latest_ubuntu_linux.id
  instance_type = "t2.micro"
  key_name      = "bastion"
  subnet_id = aws_subnet.test_subnet_public_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "test_wordpress"
  }
}

resource "aws_lb" "wordpress_alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.test_subnet_public_1.id, aws_subnet.test_subnet_public_2.id]
}

resource "aws_lb_target_group" "wordpress_alb_target_group" {
  name     = "wordpress-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
}

resource "aws_lb_listener" "wordpres_alb_listener_http" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

data "aws_acm_certificate" "issued" {
  domain   = "wordpressdenisdugar.click"
  statuses = ["ISSUED"]
}

resource "aws_alb_listener" "lordpres_alb_listener_https" {
  load_balancer_arn = aws_lb.wordpress_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn
  default_action {
    target_group_arn = aws_lb_target_group.wordpress_alb_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "lordpres_alb_listener_httpscert" {
  listener_arn    = aws_alb_listener.lordpres_alb_listener_https.arn
  certificate_arn = data.aws_acm_certificate.issued.arn
}

data "aws_route53_zone" "myZone" {
  name         = "wordpressdenisdugar.click"
}

resource "aws_route53_record" "myRecord" {
  zone_id = data.aws_route53_zone.myZone.zone_id
  name    = "www"
  type    = "A"

  alias {
      name                   = aws_lb.wordpress_alb.dns_name
      zone_id                = aws_lb.wordpress_alb.zone_id
      evaluate_target_health = true
  }
}
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.wordpress_autoscaling.id
  alb_target_group_arn   = aws_lb_target_group.wordpress_alb_target_group.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.wordpress_alb.dns_name
}

resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "wordpress"

  tags = {
    Name = "wordpress_efs"
  }
}