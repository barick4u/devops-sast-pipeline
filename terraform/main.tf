provider "aws" {
    region = "ap-south-1"
}

resource "aws_security_group" "sast-sg" {
  dynamic "ingress" {
    for_each = toset([22, 8000, 8080, 80, 3000])
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress  {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "sast" {
    ami = var.ami
    instance_type = "t2.micro"
    count = 1
    tags = {
      Name = "Jenkins-server"
    }
    vpc_security_group_ids = [aws_security_group.sast-sg.id]
    key_name = "jenkins-server"
    root_block_device {
      volume_size = 30
      volume_type = "gp3"
    }
    user_data = file("install.sh")
}
