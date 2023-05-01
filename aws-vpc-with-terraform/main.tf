##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "nor-nv-vpc" {
  cidr_block           = "10.20.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy = "default"
    
  tags = {
    Name = "nor-nv-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nor-nv-vpc.id

}

resource "aws_subnet" "public-subnet-az-a" {
  cidr_block              = "10.20.0.0/24"
  vpc_id                  = aws_vpc.nor-nv-vpc.id
  map_public_ip_on_launch = false

  tags = {
    Name = "public-subnet-az-a"
  }
}

resource "aws_subnet" "private-subnet-az-a" {
  cidr_block              = "10.20.1.0/24"
  vpc_id                  = aws_vpc.nor-nv-vpc.id
  map_public_ip_on_launch = true

    tags = {
    Name = "private-subnet-az-a"
  }
}

# ROUTING #
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.nor-nv-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.nor-nv-vpc.id

}

resource "aws_route_table_association" "rta-public-sub" {
  subnet_id      = aws_subnet.public-subnet-az-a.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "rta-private-sub" {
  subnet_id      = aws_subnet.private-subnet-az-a.id
  route_table_id = aws_route_table.private-rtb.id
}

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "nginx_sg"
  vpc_id = aws_vpc.nor-nv-vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# INSTANCES #
resource "aws_instance" "nginx1" {
  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public-subnet-az-a.id
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  user_data = <<EOF
#! /bin/bash
sudo amazon-linux-extras install -y nginx1
sudo service nginx start
sudo rm /usr/share/nginx/html/index.html
echo '<html><head><title>Taco Team Server</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">You did it! Have a &#127790;</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
EOF

}


