variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
}