variable "aws_region" {
  default = "ap-south-1"
}

variable "your_ip" {
  description = "Your local IP for SSH access"
  default     = "0.0.0.0/0"  # replace with your actual IP
}
