
terraform {
  backend "s3" {
    bucket         = "homebound-terraform-state"        # Your S3 bucket name
    key            = "terraform.tfstate"    # Path within the bucket to store the state file
    region         = "us-west-2"                          # Region where the bucket is located
    #dynamodb_table = "homebound-lock-table"               # (Optional) DynamoDB table for state locking
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "homebound_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "homebound-vpc"
  }
}

# Internet Gateway for Public Subnets
resource "aws_internet_gateway" "homebound_igw" {
  vpc_id = aws_vpc.homebound_vpc.id
  tags = {
    Name = "homebound-igw"
  }
}

# Public Subnets
resource "aws_subnet" "homebound_public_subnet_1" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "homebound-public-subnet-1"
  }
}

resource "aws_subnet" "homebound_public_subnet_2" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "homebound-public-subnet-2"
  }
}

resource "aws_subnet" "homebound_public_subnet_3" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.public_subnet_3_cidr
  availability_zone       = "us-west-2c"
  map_public_ip_on_launch = true
  tags = {
    Name = "homebound-public-subnet-3"
  }
}

# Private Subnets
resource "aws_subnet" "homebound_private_subnet_1" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = "us-west-2a"
  tags = {
    Name = "homebound-private-subnet-1"
  }
}

resource "aws_subnet" "homebound_private_subnet_2" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = "us-west-2b"
  tags = {
    Name = "homebound-private-subnet-2"
  }
}

resource "aws_subnet" "homebound_private_subnet_3" {
  vpc_id                  = aws_vpc.homebound_vpc.id
  cidr_block              = var.private_subnet_3_cidr
  availability_zone       = "us-west-2c"
  tags = {
    Name = "homebound-private-subnet-3"
  }
}

# Route Tables
resource "aws_route_table" "homebound_public_rt" {
  vpc_id = aws_vpc.homebound_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.homebound_igw.id
  }
  tags = {
    Name = "homebound-public-rt"
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "homebound_public_rt_association_1" {
  subnet_id      = aws_subnet.homebound_public_subnet_1.id
  route_table_id = aws_route_table.homebound_public_rt.id
}

resource "aws_route_table_association" "homebound_public_rt_association_2" {
  subnet_id      = aws_subnet.homebound_public_subnet_2.id
  route_table_id = aws_route_table.homebound_public_rt.id
}

resource "aws_route_table_association" "homebound_public_rt_association_3" {
  subnet_id      = aws_subnet.homebound_public_subnet_3.id
  route_table_id = aws_route_table.homebound_public_rt.id
}

# Security Group with ingress for port 8080
resource "aws_security_group" "homebound_sg" {
  name        = "homebound-security-group"
  description = "Allow all TCP, UDP, and port 8080 traffic"
  vpc_id      = aws_vpc.homebound_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmpv6"
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "homebound_asg" {
  desired_capacity          = 3
  max_size                  = 10
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = [
    aws_subnet.homebound_public_subnet_1.id,
    aws_subnet.homebound_public_subnet_2.id,
    aws_subnet.homebound_public_subnet_3.id
  ]

  launch_template {
    name      = aws_launch_template.homebound_launch_template.name
    version   = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "homebound-instance"
    propagate_at_launch = true
  }
}


# Launch Template
resource "aws_launch_template" "homebound_launch_template" {
  name_prefix   = "homebound-"
  image_id      =  var.ami_id
  instance_type = "t3.large"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.homebound_sg.id]
  }

  # User data script (encoded in base64)
  user_data = base64encode("echo Hello, World!")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "homebound-instance"
    }
  }
}