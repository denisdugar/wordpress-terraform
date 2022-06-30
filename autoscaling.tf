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