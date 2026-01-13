terraform {
  backend "s3"{}
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  } 
}
provider "aws" {
  region  = var.region
}

//Changed this file to use an S3 implementation instead of local storage
