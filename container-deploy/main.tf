terraform {
  required_providers {
    zeet = {
      source  = "zeet-dev/zeet"
      version = "0.0.5"
    }
  }
}

variable "team_id" {
  type = string
}

variable "cluster_id" {
  type = string
}

resource "zeet_group" "group" {
  team_id = var.team_id
  name    = "my-group"
}

resource "zeet_group_subgroup" "subgroup" {
  team_id  = var.team_id
  group_id = zeet_group.group.id
  name     = "my-subgroup"
}

data "zeet_blueprint" "service_container" {
  slug = "zeet-kubernetes-container-app"
}

resource "zeet_project" "container" {
  team_id     = var.team_id
  group_id    = zeet_group.group.id
  subgroup_id = zeet_group_subgroup.subgroup.id

  name         = "my-container"
  blueprint_id = data.zeet_blueprint.service_container.id
  enabled      = false // draft mode

  container = {
    source = {
      container_registry = jsonencode({
        repository = "docker.io/library/nginx",
        tag        = "latest"
      })
    }
    workflow = {
      deploy_timeout_seconds = 300
    }
    kubernetes = jsonencode({
      deployTarget = {
        deployTarget = "KUBERNETES"
        clusterID    = var.cluster_id
      }
      namespace = var.team_id
      app = {
        deployService = true
        ports = [
          {
            port     = "80"
            protocol = "tcp"
            public   = true
            https    = true
          }
        ]
      }
    })
  }
}

