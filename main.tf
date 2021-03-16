provider "aws" {
  region     = "eu-west-2"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_route_table" "route-table-1" {
  vpc_id = aws_vpc.my-vpc.id


    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
    }
}
resource "aws_subnet" "subnet-a" {

  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
}

resource "aws_route_table_association" "route-table-assoc" {

  subnet_id      = aws_subnet.subnet-a.id
  route_table_id = aws_route_table.route-table-1.id
}

resource "aws_security_group" "allow_access" {

  vpc_id = aws_vpc.my-vpc.id


  ingress {
    description = "SHH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_network_interface" "net-int" {

  subnet_id       = aws_subnet.subnet-a.id
  private_ips      = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_access.id]

}

resource "aws_eip" "hello" {

  vpc                       = true
  network_interface         = aws_network_interface.net-int.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gateway]

}

resource "aws_instance" "myinstance" {

  ami               = "ami-096cb92bb3580c759"
  instance_type              = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name          = "aws"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.net-int.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                EOF
}