terraform {
  required_version = ">= 1.6.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

variable "docker_network_name" {
  description = "Имя docker-сети для локального запуска compose"
  type        = string
  default     = "devops-final-net"
}

variable "docker_volume_name" {
  description = "Имя docker volume для кэша/моделей"
  type        = string
  default     = "devops-final-models"
}

resource "docker_network" "devops_net" {
  name = var.docker_network_name
}

resource "docker_volume" "model_cache" {
  name = var.docker_volume_name
}

output "network_name" {
  value = docker_network.devops_net.name
}

output "volume_name" {
  value = docker_volume.model_cache.name
}
