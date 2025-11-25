variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Instance type for all servers"
  type        = string
  default     = "t3.medium"
}

variable "key_pair_name" {
  description = "Existing AWS key pair name for EC2 login (for break-glass access)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH to instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "repo_url" {
  description = "Git URL of this repository for cloning on instances"
  type        = string
  default     = "https://github.com/your-user/devops-complete-setup.git"
}

variable "jenkins_admin_user" {
  description = "Jenkins admin username (also used for Sonar/Nexus admin defaults)"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins/Sonar/Nexus admin password"
  type        = string
  default     = "Admin123!"
}

variable "nexus_repo_name" {
  description = "Hosted Maven repository name for artifacts"
  type        = string
  default     = "maven-releases"
}
