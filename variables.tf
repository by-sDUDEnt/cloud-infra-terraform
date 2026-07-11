variable "instance_type" {
  description = "EC2`s server type alegable with free tier"
  type        = string
  default     = "t3.micro"
}

variable "instance_name" {
  description = "Name for the instance"
  type        = string
  default     = "learn-terraform"
}

variable "vpc_cidr" {
  description = "VPC base CIDR"
  type        = string
  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "The mask should be numericly <= 20"
  }

}


variable "my_ip" {
  description = "My IP for ssh SG ingress rule"
  type        = string
}


