variable "aws_region" {
    type = string
    default = "eu-central-1"
}
variable "project_name" {
    type = string
    default = "DTAP_group_project"
}
variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
    type = string
    default = "10.0.0.0/24"
}

#2 AZs
variable "private_subnet_cidrs"{
    type = list(string)
    default = ["10.0.2.0/24", "10.0.3.0/24"]
}

#DB config
variable "db_name" {
    type = string
    default = "DTAP_DB"
}
variable "db_password" {
    type = string
    sensitive = true
}
variable "db_username" {
    type = string
    default = "postgres"
}
variable "db_instance_class" {
    type = string
    default = "db.t3.micro" //Free tier I think
}

#VPN config
variable "client_cidr_block" {
    type = string
    default = "10.8.0.0/22"
}
variable "server_cert_arn" {
    type = string
    default = ""
    description = "" //This needs to be filled after importing
}
