variable "project" {
  description = "Project name for tags and resources"
  type        = string
  default     = "innovatech"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Standard tags"
  type        = map(string)
  default = {
    Project = "Innovatech"
    Env     = "dev"
  }
}