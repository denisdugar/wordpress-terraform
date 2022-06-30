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