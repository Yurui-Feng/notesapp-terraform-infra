variable "client_secret" {
  description = "Client secret for backend"
  type        = string
}

variable "port" {
  description = "Port for the backend service"
  type        = string
}

variable "client_id" {
  description = "Client ID for backend"
  type        = string
}

variable "google_callback_url" {
  description = "Google callback URL for backend"
  type        = string
}

variable "mongodb_uri" {
  description = "MongoDB URI for backend"
  type        = string
}

variable "secret" {
  description = "Secret for backend"
  type        = string
}

variable "frontend_url" {
  description = "Frontend URL for backend to connect"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the backend service"
  type        = string
}

variable "subnets" {
  description = "Subnet IDs for the backend service"
  type        = list(string)
}
