provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "aws_caller_identity" "current" {
}

data "aws_ami" "img" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "manifest-location"
    values = ["099720109477/ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "vpc01"
    Project = "DevOpsASGtest"
  }
}

resource "aws_subnet" "pub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnet_cidr_1
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  tags = {
    Name    = "subpub01"
    Project = "DevOpsASGtest"
  }
}

resource "aws_subnet" "pub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnet_cidr_2
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  tags = {
    Name    = "subpub02"
    Project = "DevOpsASGtest"
  }
}

resource "aws_internet_gateway" "igw01" {
  vpc_id = aws_vpc.main.id
  tags = {
    Project = "DevOpsASGtest"
  }
}

resource "aws_security_group" "primary" {
  name_prefix = "allow-ssh-sg-"
  description = "Allow inbound SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "DevOpsASGtest"
  }
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw01.id
  }

  tags = {
    Name    = "devops-asg-tst-main-rt"
    Project = "DevOpsASGtest"
  }
}

resource "aws_route_table_association" "pub1_rta" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_route_table_association" "pub2_rta" {
  subnet_id      = aws_subnet.pub2.id
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_key_pair" "pri_key" {
  key_name_prefix = "devops-asg-tst-key-"
  public_key      = var.ssh_pubkey
}

resource "aws_launch_template" "main_lt" {
  name_prefix = "devops-asg-tst-"
  description = "for testing porpoises only"
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 10
      volume_type = "gp2"
    }
  }
  key_name               = aws_key_pair.pri_key.key_name
  image_id               = data.aws_ami.img.id
  instance_type          = var.inst_type
  vpc_security_group_ids = [aws_security_group.primary.id]
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "devops-asg-tst"
      Project = "DevOpsASGtest"
    }
  }
  tags = {
    Project = "DevOpsASGtest"
  }
}

resource "aws_autoscaling_group" "devops_asg_grp" {
  name_prefix         = "devops-asg-tst-"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  target_group_arns   = [aws_lb_target_group.pri_tg.arn]
  vpc_zone_identifier = [aws_subnet.pub1.id, aws_subnet.pub2.id]
  launch_template {
    id      = aws_launch_template.main_lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "devops-asg-test-inst"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = "DevOpsASGtest"
    propagate_at_launch = true
  }
}

resource "aws_lb" "main_lb" {
  name_prefix                      = "asgtst"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = [aws_subnet.pub1.id, aws_subnet.pub2.id]
  enable_cross_zone_load_balancing = true

  tags = {
    Project = "DevOpsASGtest"
  }
}

resource "aws_lb_target_group" "pri_tg" {
  name_prefix = "asgtst"
  port        = 22
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "main_lb_listen" {
  load_balancer_arn = aws_lb.main_lb.arn
  port              = 22
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pri_tg.arn
  }
}

