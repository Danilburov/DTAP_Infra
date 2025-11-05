// Input variables for DTAP dev

// Project name prefix
variable "project" {
  type        = string
  description = "Project name prefix"
  default     = "DTAP"
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

variable "project" {
  description = "Naam voor tags en resources"
  type        = string
  default     = "innovatech"
}

variable "region" {
  description = "AWS-regio"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

# Private DNS (alleen binnen de VPC)
variable "private_zone_name" {
  description = "Private Hosted Zone naam"
  type        = string
  default     = "intra.local"
}

# EC2 instance type
variable "app_instance_type" {
  description = "Instance type voor app-EC2"
  type        = string
  default     = "t3.micro"
}

# RDS basis
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "tags" {
  description = "Standaard tags"
  type        = map(string)
  default = {
    Project = "Innovatech"
    Env     = "dev"
  }
}



# Jouw publieke IP in CIDR (voor SSH naar de VPN box). Voor testen kun je "0.0.0.0/0" gebruiken,
# maar beter: alleen jouw IP, zoals "1.2.3.4/32".
variable "my_ip_cidr" {
  description = "Toegestane bron voor SSH naar de VPN host"
  type        = string
  default     = "0.0.0.0/0"
}

# Key pair naam zoals die in AWS bestaat (voor SCP/SSH om .ovpn te pakken)
variable "key_name" {
  description = "Bestaande AWS key pair name voor SSH"
  type        = string
  default     = "alpvpnpair"
}

# Instance type voor de VPN-server
variable "vpn_instance_type" {
  description = "EC2 instance type voor OpenVPN"
  type        = string
  default     = "t3.micro"
}


variable "soar_email" {
  type        = string
  description = "Recipient for SOAR email notifications (SNS)"
  default     = "554688@student.fontys.nl" 
}