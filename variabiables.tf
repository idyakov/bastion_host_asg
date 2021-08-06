
variable "region" {
  description = "Please enter AWS Region to deploy Server"
  type        = string
  default     = "us-east-2"
}


variable "instance_type" {
  description = "Which type of EC2 you want to use"
  type        = string
  default     = "t3.micro"
}

variable "allow_ports" {
  description = "List of Ports to open for server EC2"
  type        = list(any)
  default     = ["80", "443", "22", "8080"]
}

#boolian value
variable "enable_detailed_monitoring" {
  type    = bool
  default = "true"
}
