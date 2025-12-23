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

resource "ssh_resource" "git_server_deploy" {
  host     = "192.168.1.170"
  user     = var.ssh_user
  password = var.ssh_password

  # This is a placeholder for the actual deployment logic
  # We will use this to run docker-compose up -d on the target machine
  commands = [
    "mkdir -p ~/autogit",
    "cd ~/autogit && docker-compose up -d"
  ]
}

variable "ssh_user" {
  type      = string
  sensitive = true
}

variable "ssh_password" {
  type      = string
  sensitive = true
}
