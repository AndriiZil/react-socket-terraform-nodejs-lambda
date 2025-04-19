variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "websocket-chat"
}

variable "environment" {
  description = "Environment (dev, prod, etc.)"
  type        = string
  default     = "dev"
} 