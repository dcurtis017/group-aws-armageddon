variable "ssm_and_secret_prefix" {
  type    = string
  default = "lab"
}

variable "logs_bucket" {
  type = string
}

variable "name_prefix" {
  description = "Prefix for naming resources."
  type        = string
  default     = "myapp"
}

variable "allowed_sg_ids" {
  description = "IDs of Security Groups that Can Send Traffic to RDS on 3306"
  type        = list(string)
}

variable "rds_db_subnet_ids" {
  type = list(string)
}

variable "db_engine" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_is_publicly_accessible" {
  type    = bool
  default = false
}

variable "skip_db_snapshot_on_delete" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type = string
}
