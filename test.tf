provider "aws" {
  region     = var.region # you can change the Region and start deploy
  access_key = var.awsAccessKey
  secret_key = var.awsSecretKey
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

# Allocation of EIP
resource "aws_eip" "bastion-host" {
  domain = "vpc"
}

resource "aws_launch_configuration" "bastion" {
  image_id        = data.aws_ami.latest_amazon_linux.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.my_Bastion_host.id]
  key_name        = aws_key_pair.amazon_linux.key_name
  user_data       = templatefile("auto-assign-elastic-ip.sh", { allocation_id = aws_eip.bastion-host.id })
  # Here we are attaching the IAM instance profile, which we created in the step 4.
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name #Assigning the IAM role, to an EC2 instance on the fly
  #  tags {
  #    Name = var.tagProject
  #  }
#
  #Connection with private ssh key
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id.rsa")
    host        = self.public_ip
  }
  depends_on = [aws_eip.bastion-host] #we have to allocate the eip first, and then create the launch configuration
#
}

# 1.Creating an AWS IAM role
# Define assume-role policy
data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Define role
# aassume role policy and permissions policy can be done together
resource "aws_iam_role" "bastion_instance_role" {
  name               = var.roleName
  assume_role_policy = data.aws_iam_policy_document.assume_role_ec2.json
  inline_policy {
    name = "bastion_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Action": [
              "ec2:AssociateAddress",
              "ec2:DisassociateAddress",
              "ec2:DescribeAddresses",
              "ec2:DescribeTags",
              "ec2:DescribeInstances"
          ],
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
  path = "/"
}

# Instance profile to associate above role with bastion
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "bastion_instance_profile"
  path = "/"
  role = aws_iam_role.bastion_instance_role.id
}

# Auto Scaling Group using 2 Availability zones

resource "aws_autoscaling_group" "bastion" {
  #  name                 = aws_launch_configuration.web.name #>>> dependens name of the Lunch configuration
  launch_configuration = aws_launch_configuration.bastion.name
  min_size             = 1
  max_size             = 1
  min_elb_capacity     = 1
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  dynamic "tag" {
    for_each = {
      Name  = "Bastion_Server"
      Owner = "Ilya Dyakov"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

#Creating of Security group

# Gets public IP address of your broadband so the security group can be locked down.
data "http" "my_ip_address" {
  url = "http://checkip.amazonaws.com"
  request_headers = {
    Accept = "text/plain"
  }
}

# Only you have access to the bastion
resource "aws_security_group" "my_Bastion_host" {
  name        = "Dynamic_security_group"
  description = "Bastion_host_SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip_address.response_body)}/32"]
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

output "eip-address" {
    description = "Public IP address of bastion (EIP)"
    value = aws_eip.bastion-host.address
}