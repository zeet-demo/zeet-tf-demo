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

data "zeet_blueprint" "helm" {
  slug = "helm-chart"
}

resource "zeet_project" "terraform" {
  team_id     = var.team_id
  group_id    = zeet_group.group.id
  subgroup_id = zeet_group_subgroup.subgroup.id

  name         = "my-terraform"
  blueprint_id = data.zeet_blueprint.helm.id
  enabled      = false // draft mode

  deploys = [{
    default_workflow_steps = ["DRIVER_PLAN", "DRIVER_APPROVE", "DRIVER_APPLY"]
    helm = jsonencode({
      blueprint = {
        source = {
          helmRepository = {
            repositoryUrl = "https://grafana.github.io/helm-charts",
            chart         = "grafana"
          }
        }
      },
      target = {
        clusterId   = var.cluster_id,
        namespace   = "grafana",
        releaseName = "grafana"
      }
    })
  }]

  workflow = {
    steps = jsonencode([{ action = "ORCHESTRATION_DEPLOY" }])
  }
}

