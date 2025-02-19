
variable "subnet_1_cidr" {
  description = "CIDR block for subnet 1"
  default     = "10.0.1.0/24"  # Adjust the CIDR block as per your requirement
}

variable "subnet_2_cidr" {
  description = "CIDR block for subnet 2"
  default     = "10.0.2.0/24"  # Adjust the CIDR block as per your requirement
}

variable "subnet_3_cidr" {
  description = "CIDR block for subnet 3"
  default     = "10.0.3.0/24"  # Adjust the CIDR block as per your requirement
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  default     = "t3.large"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  default     = 10
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 24 LTS"
}

variable "region" {
  description = "AWS Region"
  default     = "us-west-2"
}

variable "security_group" {
  description = "Security Group ID for allowing open TCP/UDP"
  default     = "sg-0bb4c2c2e0a30de09" # Modify if needed
}

variable "vpc_cidr" {}
variable "public_subnet_1_cidr" {}
variable "public_subnet_2_cidr" {}
variable "public_subnet_3_cidr" {}

variable "private_subnet_1_cidr" {}
variable "private_subnet_2_cidr" {}
variable "private_subnet_3_cidr" {}

variable "key_name" {}