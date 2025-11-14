variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "database_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Secret key base for Phoenix"
  type        = string
  sensitive   = true
}

variable "sentry_dsn" {
  description = "Sentry DSN for error tracking"
  type        = string
  sensitive   = true
  default     = ""
}

variable "server_replicas" {
  description = "Number of server replicas"
  type        = number
  default     = 3
}

variable "server_cpu" {
  description = "CPU units for server (256, 512, 1024, etc.)"
  type        = number
  default     = 512
}

variable "server_memory" {
  description = "Memory for server in MB"
  type        = number
  default     = 1024
}

