//S3 BUCKET AND DYNAMODB TABLE VARIABLES (SAVING THE STATE OF TERRAFORM)
variable "bucket_name"{
  type = string
  default = "dtap-terraform-state-bucket"
}
variable "dynamodb_table_name" {
  type = string
  default = "dtap-terraform-state-lock"
}