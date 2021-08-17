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
  vpc = true
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

  #Connection with privat ssh key
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id.rsa")
    host        = self.public_ip
  }
  depends_on = [aws_eip.bastion-host] #we have to allocate the eip first, and then create the launch configuration

}

# 1.Creating an AWS IAM role
resource "aws_iam_role" "test_role" {
  name               = "EIP-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
# 2.Creating an IAM policy
resource "aws_iam_policy" "test_policy" {
  name   = "test_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "ec2:AssociateAddress", "ec2:DescribeAddresses", "ec2:DescribeTags", "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# 3.Attaching the policy to the role
# The value for the roles parameter has been accessed from the resource block, which we created in step 1.
#     Explanation:
#     aws_iam_role is the type of the resource block which we created in step 1.
#     aws_iam_role.test_role is the name of the variable which we defined.
#     name is a property of that resource block.
resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.test_role.name}"]
  policy_arn = aws_iam_policy.test_policy.arn #                policy_arn = "${aws_iam_policy.policy.arn}"
}

# 4.Creating the IAM instance profile
# The value for the roles parameter has been accessed from the resource block, which we created in step 1.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "bastion_profile"
  role = aws_iam_role.test_role.name
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
resource "aws_security_group" "my_Bastion_host" {
  name        = "Dynamic_security_group"
  description = "Bastion_host_SG"

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
