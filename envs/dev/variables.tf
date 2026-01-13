// Input variables for DTAP dev

// Project name prefix
variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "dtap"
}

// AWS region to deploy into
variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-central-1"
}

// VPC CIDR
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

// Private hosted zone name
variable "private_zone_name" {
  type        = string
  description = "Private Route53 zone name"
  default     = "intra.local"
}

// App EC2 instance type
variable "app_instance_type" {
  type        = string
  description = "Application instance type"
  default     = "t3.micro"
}

// RDS instance class
variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

// Common tags
variable "tags" {
  type        = map(string)
  description = "Common resource tags"
  default = {
    Project = "DTAP"
    Env     = "dev"
  }
}

// Your IP/CIDR to allow SSH to VPN
variable "my_ip_cidr" {
  type        = string
  description = "Your IP/CIDR for SSH to VPN"
  default     = "0.0.0.0/0"
}

// EC2 key pair name
variable "key_name" {
  type        = string
  description = "EC2 key pair name"
  default     = "alpvpnpair"
}

// VPN instance type
variable "vpn_instance_type" {
  type        = string
  description = "VPN instance type"
  default     = "t3.micro"
}

// Example SOAR notification email (placeholder)
variable "soar_email" {
  type        = string
  description = "Notification email placeholder"
  default     = "example@dtap.local"
}

variable "backend_dev_image_tag" {
  type = string
  default = "latest"
}
variable "frontend_dev_image_tag" {
  type = string
  default = "latest"
}