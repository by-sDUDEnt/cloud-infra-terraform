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