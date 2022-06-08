# ----------- variables ----------------

variable "aws_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "ami" {
  type    = string
  default = "ami-0aeb7c931a5a61206"
}

variable "aws_key" {
  type      = string
  default   = "aws-key-ohio-wep"
  sensitive = true
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "volume_size" {
  type    = number
  default = 2
}

variable "max_ec2" {
  type    = number
  default = 3
}

variable "min_ec2" {
  type    = number
  default = 1
}

variable "desired_ec2" {
  type    = number
  default = 2
}

variable "volume_type" {
  type    = string
  default = "gp3"
}

variable "name_ec2" {
  type    = string
  default = "test_ec2"
}

variable "vpc_id_" {
  type    = string
  default = "vpc-0902418d2d7f18950"
}

variable "subnet_2a" {
  type    = string
  default = "subnet-0ee47e0644e3a7653"
}

variable "subnet_2b" {
  type    = string
  default = "subnet-0054b227f53439aa2"
}

variable "subnet_2c" {
  type    = string
  default = "subnet-0c25f9313e45cb595"
}

variable "dns_name" {
  type    = string
  default = "smallcase"
}

