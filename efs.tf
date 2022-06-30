resource "aws_efs_file_system" "wordpress_efs" {
  creation_token = "wordpress"

  tags = {
    Name = "wordpress_efs"
  }
}
