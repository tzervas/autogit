terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "2.7.0"
    }
  }
}

provider "ssh" {
  # Configuration for the homelab server
}

variable "ssh_user" {
  type      = string
  sensitive = true
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519"
}

variable "target_host" {
  type    = string
  default = "192.168.1.170"
}

variable "deploy_path" {
  type    = string
  default = ""
}

locals {
  # Dynamically set the deploy path based on the user if not explicitly provided
  actual_deploy_path = var.deploy_path != "" ? var.deploy_path : "/home/${var.ssh_user}/autogit"
}

resource "ssh_resource" "git_server_deploy" {
  host     = var.target_host
  user     = var.ssh_user
  # Use private key for authentication
  private_key = file(var.ssh_key_path)
  timeout     = "15m" # Increase timeout for image pulls

  # Sync project files and start services
  # We combine commands with && because each list item runs in a new shell
  # We also set DOCKER_HOST for rootless Docker and redirect logs
  # Added --build to ensure changes in Dockerfiles are applied
  commands = [
    "export DOCKER_HOST=unix:///run/user/1000/docker.sock && mkdir -p ${local.actual_deploy_path} && cd ${local.actual_deploy_path} && echo \"[$(date)] Starting deployment...\" >> deploy.log && docker compose down --remove-orphans >> deploy.log 2>&1 || true && docker compose up -d --build >> deploy.log 2>&1 && docker ps >> deploy.log 2>&1 && echo \"[$(date)] Deployment complete.\" >> deploy.log"
  ]
}

output "deployment_status" {
  value       = ssh_resource.git_server_deploy.result
  description = "The output of the deployment commands."
}

output "target_host" {
  value       = var.target_host
  description = "The homelab server IP address."
}

output "deploy_path" {
  value       = local.actual_deploy_path
  description = "The path where the project was deployed."
  sensitive   = true
}

output "ssh_user" {
  value       = var.ssh_user
  description = "The SSH user used for deployment."
  sensitive   = true
}

output "docker_host" {
  value       = "unix:///run/user/1000/docker.sock"
  description = "The Docker host used for rootless Docker."
}
