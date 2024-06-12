
variable "region" {
  description = "Please Enter the region where you want to deploy your infrastructure"
}
variable "instance_type" {
  description = "Choose your instance type"
}
variable "tagOwner" {}
variable "tagProject" {}
variable "awsAccessKey" {}
variable "awsSecretKey" {}
variable "roleName" {
  default = "bastion-role"
<<<<<<< HEAD
}
#
=======
}
>>>>>>> 7bb0fa90f143468dac30e57a6b9b1dab38cfd38c
