# This is IaC Terrafrom for the Bastion AWS and configuration of ASG with EIP assigning
![](Basion_host_ASG.JPG)

The system has set up an auto-scaling group. If the Bastion host will be terminated or stopped, after 1 min ASG starts the Bastion again with the same elastic IP automatically.<br /> 
Because the Infrastructure has a high level of availability, and every region has at least two AZ, deploying uses two subnets (by default)  into 2 AZ each.<br />

The system allows you to choose the following various:<br />
1) Region<br />
2) Type of EC2<br />
3) Tags<br />
4) Your own awsAccessKey<br />
5) Your own awsSecretKey<br />

Note: if the user will choose to create his own ssh-keygen, he needs to upload the ssh-public key in the folder of this project />

Creating an AWS IAM role using Terraform<br />
Creating an IAM policy using Terraform<br />
Attaching the policy to the role using Terraform<br />
Creating the IAM instance profile using Terraform<br />
Assigning the IAM role to an EC2 instance on the fly using Terraform<br /> 
SSH - Please choose your own keys or create via ssh-keygen, in the code, you can find the name of the key and modify it<br />
