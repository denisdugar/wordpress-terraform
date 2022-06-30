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

data "aws_acm_certificate" "issued" {
  domain   = "wordpressdenisdugar.click"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "myZone" {
  name         = "wordpressdenisdugar.click"
}