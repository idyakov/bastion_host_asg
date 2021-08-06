

provider "aws" {
  region = var.region # you can change the Region and start deply

}
data "aws_availability_zones" "available" {}
#If we need an ssh connection to EC2, we have to generate it  an ssh-keygen -t rsa and then add by the  following option bellow
# Key-pair ssh_key public_key
resource "aws_key_pair" "amazon_linux" {
  key_name   = "amazon_linux"
  public_key = file("id_rsa.pub")
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
/*
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_launch_configuration.web.id
  allocation_id = aws_eip.eip_example.id
}

resource "aws_eip" "eip_example" {
  vpc = true
}
*/
resource "aws_launch_configuration" "web" {
  #  name            = "WebServer-Highly-Available-LC"
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.my_webserver.id]
  #user_data       = file("eip.sh")
  key_name = aws_key_pair.amazon_linux.key_name
  lifecycle {
    create_before_destroy = true
  }
  #Connection with privat ssh key
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id.rsa")
    host        = self.public_ip
  }
}

# Auto Scaling Group using 2 Availability zones

resource "aws_autoscaling_group" "web" {
  #  name                 = aws_launch_configuration.web.name #>>> dependens name of the Lunch configuration
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 1
  max_size             = 1
  min_elb_capacity     = 1
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]


  dynamic "tag" {
    for_each = {
      Name   = "Bastion_Server"
      Owner  = "Ilya Dyakov"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

#Creating of Security group
resource "aws_security_group" "my_webserver" {
  name        = "Dynamic_security_group_windows"
  description = "My_first_SG"

  dynamic "ingress" {
    for_each = ["22"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0 //
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name  = "SG_webServer_AWS"
    Owner = "idyakov"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}
